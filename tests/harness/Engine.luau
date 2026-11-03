--[[
	Simulated Roblox engine for running MysLib's real source files under Lune.

	Models only what MysLib touches and steps virtual time, so specs are deterministic.
	It is not the real engine: anything that depends on actual physics, replication or
	rendering still has to be checked in Studio.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum
local Ray = roblox.Ray
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3

local nativeType = type
local nativeTypeof = typeof

local FRAME_TIME = 1 / 60

-- Marks a declared property whose default value is nil.
local NIL = table.freeze({})

local function mockTypeof(value)
	if nativeType(value) == "table" then
		local meta = getmetatable(value)
		if nativeType(meta) == "table" and rawget(meta, "__type") then
			return rawget(meta, "__type")
		end
		return "table"
	end
	return nativeTypeof(value)
end

-- Instances and signals are userdata in the real engine, so library code must not see tables.
local function mockType(value)
	if nativeType(value) == "table" and mockTypeof(value) ~= "table" then
		return "userdata"
	end
	return nativeType(value)
end

-- BindableEvent arguments cross a copy boundary: tables are duplicated and lose their metatables.
local function copyAcrossBindable(value)
	if mockTypeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, nested in value do
		copy[key] = copyAcrossBindable(nested)
	end
	return copy
end

local Engine = {}

-- Reads every .luau file under root up front. Lune's fs calls yield to its own scheduler,
-- so they cannot run inside the coroutines that specs execute in.
function Engine.snapshot(root)
	local function read(path)
		local node = { entries = {} }
		for _, entry in fs.readDir(path) do
			local entryPath = path .. "/" .. entry
			if fs.isDir(entryPath) then
				node.entries[entry] = read(entryPath)
			elseif string.sub(entry, -5) == ".luau" then
				node.entries[entry] = { source = fs.readFile(entryPath) }
			end
		end
		return node
	end
	return read(root)
end

function Engine.new(options)
	options = options or {}

	local isClient = options.isClient ~= false

	local sandbox = {
		Enum = Enum,
		CFrame = CFrame,
		Color3 = Color3,
		Vector2 = Vector2,
		Vector3 = Vector3,

		errors = {},
		warnings = {},
		prints = {},

		-- Added to the clock on every os.clock() read, to model time passing mid-function.
		clockDriftPerCall = 0,
		serverTimeOffset = 0,
		qualityLevel = Enum.SavedQualitySetting.Automatic,

		touchEnabled = false,
		mouseEnabled = true,
		tenFootInterface = false,

		physics = {
			raycast = function() return nil end,
			spherecast = function() return nil end,
			box = function() return {} end,
			radius = function() return {} end,
			part = function() return {} end,
		},
		calls = { raycast = {}, spherecast = {}, box = {}, radius = {}, part = {}, debris = {} },

		api = {
			getName = function(userId) return "User" .. userId end,
			getThumbnail = function(userId) return "rbxthumb://" .. userId end,
		},
		apiCalls = { getName = 0, getThumbnail = 0 },
	}

	local clock = 1000
	local timers = {}

	----------------------------------------------------------------------------------------
	-- task library
	----------------------------------------------------------------------------------------
	local function spawnThread(target, ...)
		local thread = target
		if nativeType(target) == "function" then
			thread = coroutine.create(target)
		elseif coroutine.status(thread) ~= "suspended" then
			error("cannot spawn non-suspended coroutine with arguments", 2)
		end

		local success, err = coroutine.resume(thread, ...)
		if not success then
			table.insert(sandbox.errors, debug.traceback(thread, tostring(err)))
		end
		return thread
	end

	local function schedule(seconds, target, ...)
		table.insert(timers, { at = clock + (seconds or 0), target = target, args = table.pack(...) })
	end

	local mockTask = {
		spawn = spawnThread,
		defer = function(target, ...)
			schedule(0, target, ...)
		end,
		delay = function(seconds, target, ...)
			schedule(seconds, target, ...)
		end,
		wait = function(seconds)
			local start = clock
			schedule(seconds, coroutine.running())
			coroutine.yield()
			return clock - start
		end,
		cancel = function(thread)
			coroutine.close(thread)
		end,
	}

	local function runDueTimers()
		local due = {}
		for index = #timers, 1, -1 do
			if timers[index].at <= clock then
				table.insert(due, 1, table.remove(timers, index))
			end
		end
		for _, timer in due do
			local isDeadThread = nativeType(timer.target) == "thread" and coroutine.status(timer.target) ~= "suspended"
			if not isDeadThread then
				spawnThread(timer.target, table.unpack(timer.args, 1, timer.args.n))
			end
		end
	end

	----------------------------------------------------------------------------------------
	-- RBXScriptSignal / RBXScriptConnection
	----------------------------------------------------------------------------------------
	local connectionMeta = {
		__type = "RBXScriptConnection",
		__index = {
			Disconnect = function(self)
				self.Connected = false
				local connections = self._signal._connections
				local index = table.find(connections, self)
				if index then
					table.remove(connections, index)
				end
			end,
		},
	}

	local signalMeta = {
		__type = "RBXScriptSignal",
		__index = {
			Connect = function(self, callback)
				assert(nativeType(callback) == "function", "Attempt to connect failed: Passed value is not a function")
				local connection = setmetatable({ Connected = true, _signal = self, _callback = callback }, connectionMeta)
				table.insert(self._connections, connection)
				return connection
			end,
			Once = function(self, callback)
				local connection
				connection = self:Connect(function(...)
					connection:Disconnect()
					callback(...)
				end)
				return connection
			end,
			Wait = function(self)
				table.insert(self._waiters, coroutine.running())
				return coroutine.yield()
			end,
			_fire = function(self, ...)
				for _, connection in table.clone(self._connections) do
					if connection.Connected then
						spawnThread(connection._callback, ...)
					end
				end
				local waiters = self._waiters
				self._waiters = {}
				for _, thread in waiters do
					if coroutine.status(thread) == "suspended" then
						spawnThread(thread, ...)
					end
				end
			end,
			_disconnectAll = function(self)
				for _, connection in table.clone(self._connections) do
					connection:Disconnect()
				end
				self._waiters = {}
			end,
			_connectionCount = function(self)
				return #self._connections
			end,
		},
	}

	local function newSignal()
		return setmetatable({ _connections = {}, _waiters = {} }, signalMeta)
	end

	----------------------------------------------------------------------------------------
	-- Instances
	----------------------------------------------------------------------------------------
	local states = {}
	local classInfoCache = {}
	local moduleSources = {}
	local loadedModules = {}
	local mockRequire

	local CLASSES
	CLASSES = {
		Instance = {
			events = { "AncestryChanged", "ChildAdded", "ChildRemoved", "Destroying" },
			methods = {
				IsA = function(self, className)
					local current = self.ClassName
					while current do
						if current == className then
							return true
						end
						current = CLASSES[current].super
					end
					return false
				end,
				GetChildren = function(self)
					return table.clone(states[self].children)
				end,
				GetDescendants = function(self)
					local descendants = {}
					local function collect(instance)
						for _, child in states[instance].children do
							table.insert(descendants, child)
							collect(child)
						end
					end
					collect(self)
					return descendants
				end,
				FindFirstChild = function(self, name)
					for _, child in states[self].children do
						if child.Name == name then
							return child
						end
					end
					return nil
				end,
				FindFirstChildOfClass = function(self, className)
					for _, child in states[self].children do
						if child.ClassName == className then
							return child
						end
					end
					return nil
				end,
				IsDescendantOf = function(self, ancestor)
					local current = states[self].parent
					while current do
						if current == ancestor then
							return true
						end
						current = states[current].parent
					end
					return false
				end,
				GetFullName = function(self)
					local parts = { self.Name }
					local current = states[self].parent
					while current and current.ClassName ~= "DataModel" do
						table.insert(parts, 1, current.Name)
						current = states[current].parent
					end
					return table.concat(parts, ".")
				end,
				GetAttribute = function(self, name)
					return states[self].attributes[name]
				end,
				SetAttribute = function(self, name, value)
					states[self].attributes[name] = value
				end,
				Destroy = function(self)
					local state = states[self]
					if state.destroyed then
						return
					end
					if state.events.Destroying then
						state.events.Destroying:_fire()
					end
					for _, child in table.clone(state.children) do
						child:Destroy()
					end
					self.Parent = nil
					state.destroyed = true
					for _, signal in state.events do
						signal:_disconnectAll()
					end
				end,
			},
		},
		DataModel = { super = "Instance", methods = {} },
		Folder = { super = "Instance" },
		ModuleScript = { super = "Instance" },
		Model = { super = "Instance", props = { PrimaryPart = NIL } },
		Workspace = {
			super = "Model",
			props = { CurrentCamera = NIL },
			methods = {
				Raycast = function(_, origin, direction, params)
					assert(origin and direction, "Argument missing or nil")
					table.insert(sandbox.calls.raycast, { origin = origin, direction = direction, params = params })
					return sandbox.physics.raycast(origin, direction, params)
				end,
				Spherecast = function(_, position, radius, direction, params)
					table.insert(sandbox.calls.spherecast, { position = position, radius = radius, direction = direction, params = params })
					return sandbox.physics.spherecast(position, radius, direction, params)
				end,
				GetPartBoundsInBox = function(_, cframe, size, params)
					assert(cframe and size, "Argument missing or nil")
					table.insert(sandbox.calls.box, { cframe = cframe, size = size, params = params })
					return sandbox.physics.box(cframe, size, params)
				end,
				GetPartBoundsInRadius = function(_, position, radius, params)
					assert(position and radius, "Argument missing or nil")
					table.insert(sandbox.calls.radius, { position = position, radius = radius, params = params })
					return sandbox.physics.radius(position, radius, params)
				end,
				GetPartsInPart = function(_, part, params)
					assert(part, "Argument missing or nil")
					table.insert(sandbox.calls.part, { part = part, params = params })
					return sandbox.physics.part(part, params)
				end,
				GetServerTimeNow = function()
					return clock + sandbox.serverTimeOffset
				end,
			},
		},
		BasePart = {
			super = "Instance",
			props = {
				Anchored = false,
				CanCollide = true,
				CanQuery = true,
				CanTouch = true,
				Massless = false,
				Transparency = 0,
				Color = Color3.new(0.6, 0.6, 0.6),
				Size = Vector3.new(4, 1, 2),
				CFrame = CFrame.new(),
			},
			getters = {
				Position = function(self)
					return self.CFrame.Position
				end,
				AssemblyCenterOfMass = function(self)
					return self.CFrame.Position
				end,
			},
		},
		Part = { super = "BasePart", props = { Shape = Enum.PartType.Block } },
		MeshPart = { super = "BasePart" },
		Attachment = { super = "Instance", props = { Position = Vector3.new() } },
		WeldConstraint = { super = "Instance", props = { Part0 = NIL, Part1 = NIL } },
		LinearVelocity = {
			super = "Instance",
			props = {
				ForceLimitMode = NIL,
				MaxAxesForce = Vector3.new(),
				VectorVelocity = Vector3.new(),
				Attachment0 = NIL,
			},
		},
		AlignOrientation = {
			super = "Instance",
			props = {
				MaxTorque = 10000,
				Mode = NIL,
				CFrame = CFrame.new(),
				Responsiveness = 10,
				RigidityEnabled = false,
				Attachment0 = NIL,
			},
		},
		ParticleEmitter = {
			super = "Instance",
			props = { Enabled = true, Rate = 5, __EmitLog = NIL, __Cleared = 0, __FailEmit = false },
			methods = {
				Emit = function(self, count)
					if self.__FailEmit then
						error("simulated engine failure")
					end
					if count ~= nil and nativeType(tonumber(count)) ~= "number" then
						error("Unable to cast " .. nativeType(count) .. " to int")
					end
					local log = self.__EmitLog or {}
					table.insert(log, count == nil and "default" or count)
					self.__EmitLog = log
				end,
				Clear = function(self)
					self.__Cleared += 1
				end,
			},
		},
		Beam = { super = "Instance", props = { Enabled = true } },
		Humanoid = {
			super = "Instance",
			props = { Health = 100, MaxHealth = 100, WalkSpeed = 16, __State = NIL },
			setters = {
				Health = function(props, value)
					props.Health = math.clamp(value, 0, props.MaxHealth)
				end,
				WalkSpeed = function(props, value)
					props.WalkSpeed = math.max(value, 0)
				end,
			},
			methods = {
				GetState = function(self)
					return self.__State or Enum.HumanoidStateType.Running
				end,
			},
		},
		BindableEvent = {
			super = "Instance",
			events = { "Event" },
			methods = {
				Fire = function(self, ...)
					local args = table.pack(...)
					for index = 1, args.n do
						args[index] = copyAcrossBindable(args[index])
					end
					self.Event:_fire(table.unpack(args, 1, args.n))
				end,
			},
		},
		Camera = {
			super = "Instance",
			props = { CFrame = CFrame.new(), ViewportSize = Vector2.new(1920, 1080) },
			methods = {
				ScreenPointToRay = function(self)
					return Ray.new(self.CFrame.Position, self.CFrame.LookVector)
				end,
			},
		},
		Player = {
			super = "Instance",
			props = { Character = NIL, __Mouse = NIL },
			methods = {
				GetMouse = function(self)
					return self.__Mouse
				end,
			},
		},
		RunService = {
			super = "Instance",
			events = { "Heartbeat", "Stepped" },
			methods = {
				IsClient = function()
					return isClient
				end,
				IsServer = function()
					return not isClient
				end,
			},
		},
		Players = {
			super = "Instance",
			props = { LocalPlayer = NIL },
			methods = {
				GetNameFromUserIdAsync = function(_, userId)
					sandbox.apiCalls.getName += 1
					return sandbox.api.getName(userId)
				end,
				GetUserThumbnailAsync = function(_, userId, thumbnailType, thumbnailSize)
					sandbox.apiCalls.getThumbnail += 1
					return sandbox.api.getThumbnail(userId, thumbnailType, thumbnailSize)
				end,
			},
		},
		GuiService = {
			super = "Instance",
			methods = {
				IsTenFootInterface = function()
					return sandbox.tenFootInterface
				end,
				GetGuiInset = function()
					return Vector2.new(0, 36), Vector2.new()
				end,
			},
		},
		UserInputService = {
			super = "Instance",
			getters = {
				TouchEnabled = function()
					return sandbox.touchEnabled
				end,
				MouseEnabled = function()
					return sandbox.mouseEnabled
				end,
			},
		},
		Debris = {
			super = "Instance",
			methods = {
				-- The real service treats a missing lifetime as 10 seconds.
				AddItem = function(_, item, lifetime)
					table.insert(sandbox.calls.debris, { item = item, lifetime = lifetime or 10 })
				end,
			},
		},
	}

	local function getClassInfo(className)
		local cached = classInfoCache[className]
		if cached then
			return cached
		end

		local definition = CLASSES[className]
		if not definition then
			error(string.format("Unable to create an Instance of type \"%s\"", tostring(className)), 3)
		end

		local info = { props = {}, methods = {}, events = {}, getters = {}, setters = {} }
		if definition.super then
			local inherited = getClassInfo(definition.super)
			for section, values in inherited do
				for key, value in values do
					info[section][key] = value
				end
			end
		end
		for key, value in definition.props or {} do
			info.props[key] = value
		end
		for key, value in definition.methods or {} do
			info.methods[key] = value
		end
		for key, value in definition.getters or {} do
			info.getters[key] = value
		end
		for key, value in definition.setters or {} do
			info.setters[key] = value
		end
		for _, name in definition.events or {} do
			info.events[name] = true
		end

		classInfoCache[className] = info
		return info
	end

	local function memberError(self, key)
		local state = states[self]
		error(string.format('%s is not a valid member of %s "%s"', tostring(key), state.className, state.props.Name), 3)
	end

	local function fireAncestryChanged(instance, child, parent)
		local state = states[instance]
		if state.events.AncestryChanged then
			state.events.AncestryChanged:_fire(child, parent)
		end
		for _, descendant in table.clone(state.children) do
			fireAncestryChanged(descendant, child, parent)
		end
	end

	local function setParent(self, newParent)
		local state = states[self]
		if state.destroyed then
			error(string.format("The Parent property of %s is locked", state.props.Name), 3)
		end

		local oldParent = state.parent
		if oldParent == newParent then
			return
		end

		if oldParent then
			local siblings = states[oldParent].children
			table.remove(siblings, table.find(siblings, self))
			if states[oldParent].events.ChildRemoved then
				states[oldParent].events.ChildRemoved:_fire(self)
			end
		end

		state.parent = newParent
		if newParent then
			table.insert(states[newParent].children, self)
		end

		fireAncestryChanged(self, self, newParent)

		if newParent and states[newParent].events.ChildAdded then
			states[newParent].events.ChildAdded:_fire(self)
		end
	end

	local instanceMeta = { __type = "Instance" }

	instanceMeta.__index = function(self, key)
		local state = states[self]
		local info = state.info

		if key == "Parent" then
			return state.parent
		elseif key == "ClassName" then
			return state.className
		elseif key == "Name" then
			return state.props.Name
		elseif info.getters[key] then
			return info.getters[key](self)
		elseif info.props[key] ~= nil then
			return state.props[key]
		elseif info.methods[key] then
			return info.methods[key]
		elseif info.events[key] then
			if not state.events[key] then
				state.events[key] = newSignal()
			end
			return state.events[key]
		end

		for _, child in state.children do
			if child.Name == key then
				return child
			end
		end

		return memberError(self, key)
	end

	instanceMeta.__newindex = function(self, key, value)
		local state = states[self]
		local info = state.info

		if key == "Parent" then
			setParent(self, value)
		elseif key == "Name" then
			state.props.Name = value
		elseif info.setters[key] then
			info.setters[key](state.props, value)
		elseif info.props[key] ~= nil then
			state.props[key] = value
		else
			memberError(self, key)
		end
	end

	instanceMeta.__tostring = function(self)
		return states[self].props.Name
	end

	local function newInstance(className)
		local info = getClassInfo(className)
		local instance = setmetatable({}, instanceMeta)

		local props = { Name = className }
		for key, default in info.props do
			if default ~= NIL then
				props[key] = default
			end
		end

		states[instance] = {
			className = className,
			info = info,
			props = props,
			parent = nil,
			children = {},
			attributes = {},
			events = {},
			destroyed = false,
		}
		return instance
	end

	----------------------------------------------------------------------------------------
	-- DataModel
	----------------------------------------------------------------------------------------
	local game = newInstance("DataModel")
	game.Name = "game"

	local services = {}
	local function addService(className, name)
		local service = newInstance(className)
		service.Name = name or className
		service.Parent = game
		services[service.Name] = service
		return service
	end

	local workspace = addService("Workspace")
	local runService = addService("RunService")
	local players = addService("Players")
	addService("GuiService")
	addService("UserInputService")
	addService("Debris")
	local replicatedStorage = newInstance("Folder")
	replicatedStorage.Name = "ReplicatedStorage"
	replicatedStorage.Parent = game

	CLASSES.DataModel.methods.GetService = function(_, name)
		return services[name] or error(string.format("'%s' is not a valid Service name", tostring(name)))
	end
	classInfoCache.DataModel = nil
	states[game].info = getClassInfo("DataModel")

	local camera = newInstance("Camera")
	camera.Parent = workspace
	workspace.CurrentCamera = camera

	if isClient then
		local localPlayer = newInstance("Player")
		localPlayer.Name = "LocalPlayer"
		localPlayer.__Mouse = { X = 100, Y = 200 }
		localPlayer.Parent = players
		players.LocalPlayer = localPlayer
		sandbox.localPlayer = localPlayer
	end

	----------------------------------------------------------------------------------------
	-- Module loading
	----------------------------------------------------------------------------------------
	local function newParamsClass(typeName, defaults)
		return {
			new = function()
				return setmetatable(table.clone(defaults), { __type = typeName })
			end,
		}
	end

	local OverlapParams = newParamsClass("OverlapParams", { FilterDescendantsInstances = {} })
	local RaycastParams = newParamsClass("RaycastParams", { FilterDescendantsInstances = {} })

	local mockOs = {
		clock = function()
			local now = clock
			clock += sandbox.clockDriftPerCall
			return now
		end,
		time = os.time,
		date = os.date,
	}

	local function format(...)
		local args = table.pack(...)
		for index = 1, args.n do
			args[index] = tostring(args[index])
		end
		return table.concat(args, " ")
	end

	-- Live like the real UserGameSettings object, so code may cache it.
	local gameSettings = setmetatable({}, {
		__index = function(_, key)
			if key == "SavedQualityLevel" then
				return sandbox.qualityLevel
			end
			return nil
		end,
	})

	local function makeEnvironment(moduleScript)
		return {
			script = moduleScript,
			require = mockRequire,
			game = game,
			workspace = workspace,
			Instance = { new = newInstance },
			Enum = Enum,
			CFrame = CFrame,
			Color3 = Color3,
			Vector2 = Vector2,
			Vector3 = Vector3,
			Ray = Ray,
			OverlapParams = OverlapParams,
			RaycastParams = RaycastParams,
			UserSettings = function()
				return { GameSettings = gameSettings }
			end,
			typeof = mockTypeof,
			type = mockType,
			task = mockTask,
			os = mockOs,
			warn = function(...)
				table.insert(sandbox.warnings, format(...))
			end,
			print = function(...)
				table.insert(sandbox.prints, format(...))
			end,
		}
	end

	mockRequire = function(moduleScript)
		if mockTypeof(moduleScript) ~= "Instance" or moduleScript.ClassName ~= "ModuleScript" then
			error("Attempted to call require with invalid argument(s).", 2)
		end

		local record = loadedModules[moduleScript]
		if record then
			return record.value
		end

		local source = moduleSources[moduleScript]
		local value
		if source.factory then
			value = source.factory()
		else
			local chunk = luau.load(source.source, {
				debugName = source.path,
				environment = makeEnvironment(moduleScript),
			})
			value = chunk()
		end

		loadedModules[moduleScript] = { value = value }
		return value
	end

	-- Mirrors how Rojo maps a directory: init.luau makes it a ModuleScript, otherwise a Folder.
	local function mountDirectory(node, path, name, parent)
		local init = node.entries["init.luau"]
		local container = newInstance(if init then "ModuleScript" else "Folder")
		container.Name = name
		if init then
			moduleSources[container] = { path = path .. "/init.luau", source = init.source }
		end

		local entryNames = {}
		for entry in node.entries do
			table.insert(entryNames, entry)
		end
		table.sort(entryNames)

		for _, entry in entryNames do
			local child = node.entries[entry]
			local entryPath = path .. "/" .. entry
			if child.entries then
				mountDirectory(child, entryPath, entry, container)
			elseif entry ~= "init.luau" then
				local moduleScript = newInstance("ModuleScript")
				moduleScript.Name = string.sub(entry, 1, -6)
				moduleSources[moduleScript] = { path = entryPath, source = child.source }
				moduleScript.Parent = container
			end
		end

		container.Parent = parent
		return container
	end

	local srcDir = options.srcDir or "src"
	local libraryRoot = mountDirectory(options.tree or Engine.snapshot(srcDir), srcDir, "MysLib", replicatedStorage)

	----------------------------------------------------------------------------------------
	-- Sandbox API for specs
	----------------------------------------------------------------------------------------
	sandbox.game = game
	sandbox.workspace = workspace
	sandbox.runService = runService
	sandbox.players = players
	sandbox.libraryRoot = libraryRoot
	sandbox.spawn = spawnThread
	sandbox.OverlapParams = OverlapParams
	sandbox.RaycastParams = RaycastParams

	-- require("Util.GeneralUtil.Stepped") style lookup; no path means the library root.
	function sandbox.require(path)
		local current = libraryRoot
		for segment in string.gmatch(path or "", "[^%.]+") do
			current = current[segment]
		end
		return mockRequire(current)
	end

	function sandbox.new(className, props)
		local instance = newInstance(className)
		local parent = nil
		for key, value in props or {} do
			if key == "Parent" then
				parent = value
			else
				instance[key] = value
			end
		end
		instance.Parent = parent
		return instance
	end

	-- Registers a ModuleScript whose return value comes from a function.
	function sandbox.moduleScript(name, factory)
		local moduleScript = newInstance("ModuleScript")
		moduleScript.Name = name
		moduleSources[moduleScript] = { factory = factory }
		moduleScript.Parent = replicatedStorage
		return moduleScript
	end

	function sandbox.now()
		return clock
	end

	function sandbox.step(deltaTime)
		deltaTime = deltaTime or FRAME_TIME
		clock += deltaTime
		runDueTimers()
		runService.Stepped:_fire(clock, deltaTime)
		runService.Heartbeat:_fire(deltaTime)
	end

	function sandbox.advance(seconds)
		for _ = 1, math.ceil(seconds / FRAME_TIME) do
			sandbox.step(FRAME_TIME)
		end
	end

	-- Moves the clock without firing frame events, as a long frame or clock correction would.
	function sandbox.skipTime(seconds)
		clock += seconds
	end

	function sandbox.takeErrors()
		local errors = sandbox.errors
		sandbox.errors = {}
		return errors
	end

	function sandbox.hasWarning(pattern)
		for _, message in sandbox.warnings do
			if string.find(message, pattern, 1, true) then
				return true
			end
		end
		return false
	end

	return sandbox
end

return Engine
