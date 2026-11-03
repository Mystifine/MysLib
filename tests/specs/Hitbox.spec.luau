local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, near = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.near

local function noop() end

describe("Hitbox shapes", function()
	it("square Cast queries the box and fires onHit per part", function()
		local sb = sandbox()
		local Hitbox = sb.require("Hitbox")
		local partA, partB = sb.new("Part"), sb.new("Part")
		sb.physics.box = function()
			return { partA, partB }
		end

		local hits = {}
		local cframe, size = sb.CFrame.new(1, 2, 3), sb.Vector3.new(4, 5, 6)
		local ignored = sb.new("Part")
		local hitbox = Hitbox.square({
			cframe = cframe,
			size = size,
			ignoreList = { ignored },
			onHit = function(part)
				table.insert(hits, part)
			end,
		})
		hitbox:Cast()

		eq(sb.calls.box[1].cframe, cframe)
		eq(sb.calls.box[1].size, size)
		eq(sb.calls.box[1].params.FilterDescendantsInstances[1], ignored)
		eq(hits[1], partA)
		eq(hits[2], partB)
	end)

	it("sphere Cast queries the radius", function()
		local sb = sandbox()
		local hit
		local part = sb.new("Part")
		sb.physics.radius = function()
			return { part }
		end
		sb.require("Hitbox").sphere({
			cframe = sb.CFrame.new(1, 0, 0),
			radius = 5,
			onHit = function(p)
				hit = p
			end,
		}):Cast()
		eq(sb.calls.radius[1].radius, 5)
		eq(hit, part)
	end)

	it("basePart Cast queries the part while it is in the workspace", function()
		local sb = sandbox()
		local volume = sb.new("Part", { Parent = sb.workspace })
		local other = sb.new("Part")
		sb.physics.part = function()
			return { other }
		end
		local hit
		sb.require("Hitbox").basePart({
			basePart = volume,
			onHit = function(p)
				hit = p
			end,
		}):Cast()
		eq(sb.calls.part[1].part, volume)
		eq(hit, other)
	end)

	it("reads public fields fresh on every check", function()
		local sb = sandbox()
		local hitbox = sb.require("Hitbox").square({
			cframe = sb.CFrame.new(),
			size = sb.Vector3.new(1, 1, 1),
			onHit = noop,
		})
		hitbox:Cast()
		local moved = sb.CFrame.new(9, 9, 9)
		local ignored = sb.new("Part")
		hitbox.cframe = moved
		table.insert(hitbox.ignoreList, ignored)
		hitbox:Cast()
		eq(sb.calls.box[2].cframe, moved)
		eq(sb.calls.box[2].params.FilterDescendantsInstances[1], ignored)
	end)

	it("requires onHit", function()
		local sb = sandbox()
		TestKit.throws(function()
			sb.require("Hitbox").square({ cframe = sb.CFrame.new(), size = sb.Vector3.new(1, 1, 1) })
		end)
	end)
end)

describe("Hitbox lifecycle", function()
	local function makeAll(sb, onHit)
		local Hitbox = sb.require("Hitbox")
		return {
			square = Hitbox.square({ cframe = sb.CFrame.new(), size = sb.Vector3.new(1, 1, 1), onHit = onHit }),
			sphere = Hitbox.sphere({ cframe = sb.CFrame.new(), radius = 1, onHit = onHit }),
			basePart = Hitbox.basePart({ basePart = sb.new("Part", { Parent = sb.workspace }), onHit = onHit }),
			projectile = Hitbox.projectile({ cframe = sb.CFrame.new(), velocity = 10, lifetime = 1, width = 1, height = 1, onHit = onHit }),
		}
	end

	it("Start checks every frame, Stop halts it and releases the connection", function()
		local sb = sandbox()
		local hitbox = sb.require("Hitbox").sphere({ cframe = sb.CFrame.new(), radius = 1, onHit = noop })
		hitbox:Start()
		sb.step()
		sb.step()
		eq(#sb.calls.radius, 2)

		hitbox:Stop()
		sb.step()
		eq(#sb.calls.radius, 2)
		sb.step()
		eq(sb.runService.Stepped:_connectionCount(), 0)
	end)

	it("a destroyed hitbox of any type ignores Cast and Start", function()
		local sb = sandbox()
		for name, hitbox in makeAll(sb, noop) do
			hitbox:Destroy()
			hitbox:Destroy()
			if name ~= "projectile" then
				hitbox:Cast()
			end
			hitbox:Start()
			hitbox:Stop()
		end
		sb.step()
		eq(#sb.calls.box + #sb.calls.radius + #sb.calls.part + #sb.calls.raycast, 0)
	end)

	it("Cast on a projectile warns instead of throwing", function()
		local sb = sandbox()
		makeAll(sb, noop).projectile:Cast()
		ok(sb.hasWarning("Use :Start()"))
	end)

	it("does not break other hitboxes when one is misconfigured", function()
		local sb = sandbox()
		local Hitbox = sb.require("Hitbox")

		local broken = Hitbox.square({ onHit = noop })
		local checks = 0
		sb.physics.radius = function()
			checks += 1
			return {}
		end
		local healthy = Hitbox.sphere({ cframe = sb.CFrame.new(), radius = 1, onHit = noop })

		broken:Start()
		healthy:Start()
		sb.step()
		sb.step()
		sb.step()

		eq(checks, 3)
		eq(#sb.takeErrors(), 0)
		ok(sb.hasWarning("not defined") or sb.hasWarning("missing"))
	end)

	it("stops a hitbox that keeps erroring instead of warning every frame", function()
		local sb = sandbox()
		local broken = sb.require("Hitbox").square({ onHit = noop })
		broken:Start()
		sb.step()
		local warningsAfterFirstFrame = #sb.warnings
		sb.step()
		sb.step()
		eq(#sb.warnings, warningsAfterFirstFrame)
		eq(#sb.takeErrors(), 0)
	end)

	it("does not run a hitbox that an earlier onHit destroyed this frame", function()
		local sb = sandbox()
		local Hitbox = sb.require("Hitbox")
		local hitboxes = {}
		local firedAfterDestroy = 0
		local firstDone = false

		sb.physics.radius = function()
			return { sb.new("Part") }
		end

		for index = 1, 4 do
			hitboxes[index] = Hitbox.sphere({
				cframe = sb.CFrame.new(),
				radius = 1,
				onHit = function()
					if firstDone then
						firedAfterDestroy += 1
						return
					end
					firstDone = true
					for other = 1, 4 do
						if other ~= index then
							hitboxes[other]:Destroy()
						end
					end
				end,
			})
			hitboxes[index]:Start()
		end

		sb.step()
		eq(firedAfterDestroy, 0)
		eq(#sb.takeErrors(), 0)
	end)

	it("handles onHit starting new hitboxes while stepping", function()
		local sb = sandbox()
		local Hitbox = sb.require("Hitbox")
		local hitOnce = false
		sb.physics.radius = function()
			return { sb.new("Part") }
		end

		local trigger = Hitbox.sphere({
			cframe = sb.CFrame.new(),
			radius = 1,
			onHit = function()
				if hitOnce then
					return
				end
				hitOnce = true
				for _ = 1, 64 do
					Hitbox.square({ cframe = sb.CFrame.new(), size = sb.Vector3.new(1, 1, 1), onHit = noop }):Start()
				end
			end,
		})
		trigger:Start()

		sb.step()
		eq(#sb.takeErrors(), 0)
		sb.step()
		eq(#sb.calls.box, 64)
	end)

	it("stops delivering hits from a check once onHit destroys the hitbox", function()
		local sb = sandbox()
		sb.physics.radius = function()
			return { sb.new("Part"), sb.new("Part"), sb.new("Part") }
		end
		local hits = 0
		local hitbox
		hitbox = sb.require("Hitbox").sphere({
			cframe = sb.CFrame.new(),
			radius = 1,
			onHit = function()
				hits += 1
				hitbox:Destroy()
			end,
		})
		hitbox:Cast()
		eq(hits, 1)
	end)

	it("stops a hitbox whose spatial query throws, without affecting the others", function()
		local sb = sandbox()
		local Hitbox = sb.require("Hitbox")
		sb.physics.part = function()
			error("query failed")
		end
		local radiusChecks = 0
		sb.physics.radius = function()
			radiusChecks += 1
			return {}
		end

		Hitbox.basePart({ basePart = sb.new("Part", { Parent = sb.workspace }), onHit = noop }):Start()
		Hitbox.sphere({ cframe = sb.CFrame.new(), radius = 1, onHit = noop }):Start()
		sb.step()
		sb.step()

		eq(#sb.calls.part, 1)
		eq(radiusChecks, 2)
		ok(sb.hasWarning("query failed"))
		eq(#sb.takeErrors(), 0)
	end)
end)

describe("Hitbox projectile", function()
	local function firstFrameOrigins(sb, cframe)
		local origins = {}
		for _, call in sb.calls.raycast do
			table.insert(origins, cframe:PointToObjectSpace(call.origin))
		end
		return origins
	end

	local function bounds(origins)
		local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
		for _, origin in origins do
			minX, maxX = math.min(minX, origin.X), math.max(maxX, origin.X)
			minY, maxY = math.min(minY, origin.Y), math.max(maxY, origin.Y)
		end
		return minX, maxX, minY, maxY
	end

	it("covers exactly width by height, centred on the cframe, in object space", function()
		local sb = sandbox()
		local cframe = sb.CFrame.new(10, 20, 30) * sb.CFrame.Angles(0, math.rad(90), 0)
		sb.require("Hitbox").projectile({ cframe = cframe, velocity = 10, lifetime = 1, width = 4, height = 2, onHit = noop }):Start()
		sb.step()

		local minX, maxX, minY, maxY = bounds(firstFrameOrigins(sb, cframe))
		near(minX, -2, 1e-3, "left edge")
		near(maxX, 2, 1e-3, "right edge")
		near(minY, -1, 1e-3, "bottom edge")
		near(maxY, 1, 1e-3, "top edge")
	end)

	it("keeps gaps between rays to at most 1 stud", function()
		local sb = sandbox()
		local cframe = sb.CFrame.new()
		sb.require("Hitbox").projectile({ cframe = cframe, velocity = 10, lifetime = 1, width = 2.5, height = 1, onHit = noop }):Start()
		sb.step()

		local xs = {}
		for _, origin in firstFrameOrigins(sb, cframe) do
			xs[math.round(origin.X * 1000)] = true
		end
		local sorted = {}
		for x in xs do
			table.insert(sorted, x)
		end
		table.sort(sorted)
		for index = 2, #sorted do
			ok(sorted[index] - sorted[index - 1] <= 1000, "gap wider than a stud")
		end
	end)

	it("casts no duplicate rays", function()
		local sb = sandbox()
		local cframe = sb.CFrame.new()
		sb.require("Hitbox").projectile({ cframe = cframe, velocity = 10, lifetime = 1, width = 2, height = 2, onHit = noop }):Start()
		sb.step()

		local seen = {}
		for _, origin in firstFrameOrigins(sb, cframe) do
			local key = string.format("%.3f,%.3f", origin.X, origin.Y)
			eq(seen[key], nil, "duplicate ray at " .. key)
			seen[key] = true
		end
		eq(#sb.calls.raycast, 9)
	end)

	it("handles sub-stud and zero sizes without producing NaN positions", function()
		for _, size in { { 0.5, 0.5 }, { 0, 0 }, { 0.2, 3 }, { 0, 1 } } do
			local sb = sandbox()
			local cframe = sb.CFrame.new()
			sb.require("Hitbox").projectile({
				cframe = cframe,
				velocity = 10,
				lifetime = 1,
				width = size[1],
				height = size[2],
				onHit = noop,
			}):Start()
			sb.step()

			ok(#sb.calls.raycast >= 1, "casts at least one ray")
			local minX, maxX, minY, maxY = bounds(firstFrameOrigins(sb, cframe))
			for _, value in { minX, maxX, minY, maxY } do
				ok(value == value and math.abs(value) < 1e6, string.format("finite offset for %s x %s", size[1], size[2]))
			end
			near(maxX, size[1] / 2, 1e-3)
			near(minX, -size[1] / 2, 1e-3)
		end
	end)

	it("travels at the configured velocity", function()
		local sb = sandbox()
		sb.require("Hitbox").projectile({ cframe = sb.CFrame.new(), velocity = 60, lifetime = 10, width = 0, height = 0, onHit = noop }):Start()

		sb.step(0.1)
		sb.step(0.1)
		sb.step(0.1)

		-- The centre point is the first ray of each frame, and -Z is forward.
		local rays = sb.calls.raycast
		local perFrame = #rays / 3
		near(rays[1].direction.Magnitude, 6, 1e-3)
		near(rays[1 + perFrame].origin.Z, -6, 1e-3)
		near(rays[1 + perFrame * 2].origin.Z, -12, 1e-3)
	end)

	it("moves every ray the same distance in a frame", function()
		local sb = sandbox()
		sb.clockDriftPerCall = 0.0001
		sb.require("Hitbox").projectile({ cframe = sb.CFrame.new(), velocity = 100, lifetime = 10, width = 4, height = 4, onHit = noop }):Start()
		sb.step(0.1)

		local rays = sb.calls.raycast
		ok(#rays > 1)
		for index = 2, #rays do
			near(rays[index].direction.Magnitude, rays[1].direction.Magnitude, 1e-6, "ray " .. index)
		end
	end)

	it("reports the nearest hit when several rays connect in one frame", function()
		local sb = sandbox()
		local nearPart, farPart = sb.new("Part"), sb.new("Part")
		sb.physics.raycast = function(origin)
			if math.abs(origin.X) < 0.01 then
				return { Instance = farPart, Distance = 5, Position = origin }
			elseif math.abs(origin.X - 1) < 0.01 then
				return { Instance = nearPart, Distance = 0.5, Position = origin }
			end
			return nil
		end

		local hit
		sb.require("Hitbox").projectile({
			cframe = sb.CFrame.new(),
			velocity = 100,
			lifetime = 1,
			width = 2,
			height = 2,
			onHit = function(result)
				hit = result.Instance
			end,
		}):Start()
		sb.step()
		eq(hit, nearPart)
	end)

	it("stops after the first hit", function()
		local sb = sandbox()
		sb.physics.raycast = function(origin)
			return { Instance = sb.new("Part"), Distance = 1, Position = origin }
		end
		local hits = 0
		sb.require("Hitbox").projectile({
			cframe = sb.CFrame.new(),
			velocity = 10,
			lifetime = 1,
			width = 1,
			height = 1,
			onHit = function()
				hits += 1
			end,
		}):Start()
		sb.step()
		sb.step()
		eq(hits, 1)
	end)

	it("lets onHit restart the projectile", function()
		local sb = sandbox()
		sb.physics.raycast = function(origin)
			return { Instance = sb.new("Part"), Distance = 1, Position = origin }
		end
		local hits = 0
		local projectile
		projectile = sb.require("Hitbox").projectile({
			cframe = sb.CFrame.new(),
			velocity = 10,
			lifetime = 5,
			width = 1,
			height = 1,
			onHit = function()
				hits += 1
				if hits == 1 then
					projectile:Start()
				end
			end,
		})
		projectile:Start()
		sb.step()
		sb.step()
		eq(hits, 2)
	end)

	it("lets onHit destroy the projectile", function()
		local sb = sandbox()
		sb.physics.raycast = function(origin)
			return { Instance = sb.new("Part"), Distance = 1, Position = origin }
		end
		local projectile
		projectile = sb.require("Hitbox").projectile({
			cframe = sb.CFrame.new(),
			velocity = 10,
			lifetime = 5,
			width = 1,
			height = 1,
			onHit = function()
				projectile:Destroy()
			end,
		})
		projectile:Start()
		sb.step()
		sb.step()
		eq(#sb.takeErrors(), 0)
	end)

	it("expires at its lifetime and releases the connection", function()
		local sb = sandbox()
		sb.require("Hitbox").projectile({ cframe = sb.CFrame.new(), velocity = 10, lifetime = 0.5, width = 1, height = 1, onHit = noop }):Start()
		sb.advance(0.6)
		local casts = #sb.calls.raycast
		sb.advance(0.1)
		eq(#sb.calls.raycast, casts)
		eq(sb.runService.Stepped:_connectionCount(), 0)
	end)

	it("still asserts missing fields on Start", function()
		local sb = sandbox()
		TestKit.throws(function()
			sb.require("Hitbox").projectile({ cframe = sb.CFrame.new(), onHit = noop }):Start()
		end, "'velocity' is not defined")
	end)
end)

describe("Hitbox helpers", function()
	it("raycast returns the engine result and defaults the visual lifetime", function()
		local sb = sandbox()
		local expected = { Distance = 1 }
		sb.physics.raycast = function()
			return expected
		end
		local Hitbox = sb.require("Hitbox")
		eq(Hitbox.raycast(sb.Vector3.new(), sb.Vector3.new(0, 0, -5), sb.RaycastParams.new()), expected)
		eq(#sb.calls.debris, 0)

		Hitbox.raycast(sb.Vector3.new(), sb.Vector3.new(0, 0, -5), sb.RaycastParams.new(), true)
		eq(#sb.calls.debris, 1)
		eq(sb.calls.debris[1].lifetime, 0.5)
	end)

	it("spherecast returns the engine result and draws three debug parts", function()
		local sb = sandbox()
		local expected = { Distance = 2 }
		sb.physics.spherecast = function()
			return expected
		end
		local result = sb.require("Hitbox").spherecast(sb.Vector3.new(), 2, sb.Vector3.new(0, 0, -5), sb.RaycastParams.new(), true)
		eq(result, expected)
		eq(#sb.calls.debris, 3)
		eq(sb.calls.debris[1].lifetime, 0.5)
	end)

	it("overlap helpers forward to the workspace", function()
		local sb = sandbox()
		local Hitbox = sb.require("Hitbox")
		local part = sb.new("Part")
		Hitbox.getPartBoundsInRadius(sb.Vector3.new(), 3)
		Hitbox.getPartBoundsInBox(sb.CFrame.new(), sb.Vector3.new(1, 1, 1))
		Hitbox.getPartsInPart(part)
		eq(sb.calls.radius[1].radius, 3)
		eq(#sb.calls.box, 1)
		eq(sb.calls.part[1].part, part)
	end)

	it("getClosestTarget picks the nearest model", function()
		local sb = sandbox()
		local function model(x)
			local primary = sb.new("Part", { CFrame = sb.CFrame.new(x, 0, 0) })
			local instance = sb.new("Model")
			primary.Parent = instance
			instance.PrimaryPart = primary
			return instance
		end
		local near1, far = model(1), model(50)
		eq(sb.require("Hitbox").getClosestTarget(sb.Vector3.new(), { [near1] = true, [far] = true }), near1)
	end)

	it("getClosestTarget skips models without a PrimaryPart", function()
		local sb = sandbox()
		local primary = sb.new("Part", { CFrame = sb.CFrame.new(5, 0, 0) })
		local valid = sb.new("Model")
		primary.Parent = valid
		valid.PrimaryPart = primary
		local noPrimary = sb.new("Model")

		eq(sb.require("Hitbox").getClosestTarget(sb.Vector3.new(), { [valid] = true, [noPrimary] = true }), valid)
		eq(sb.require("Hitbox").getClosestTarget(sb.Vector3.new(), { [noPrimary] = true }), nil)
	end)
end)
