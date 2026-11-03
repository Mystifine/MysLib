--[[
  Maid

	Written by Mystifine

	Last Updated: 2026-11-02
]]

export type Maid = {
	ClassName : string,

	GiveTask : (self : Maid, taskInstance : any?, key : any?) -> nil,
	AddTask : (self : Maid, taskInstance : any?, key : any?) -> nil,
	RemoveTask : (self : Maid, key : any) -> nil,
	Destroy : (self : Maid) -> nil,
	DoCleaning : (self : Maid) -> nil,
}

export type MaidLib = {
	new : () -> Maid,
	isValidTask : (taskInstance : any?) -> boolean,
	cleanupTask : (taskInstance : any) -> nil,
}

local Maid = {}
Maid.__index = Maid;
Maid.ClassName = "Maid";

function Maid.isValidTask(taskInstance)
	local taskType = typeof(taskInstance)
	if taskType == "function" or taskType == "RBXScriptConnection" then
		return true
	end
	if taskType == "Instance" then
		return true -- all Instances support :Destroy()
	end
	if taskType == "table" and (taskInstance.Destroy or taskInstance.Disconnect) then
		return true
	end
	return false
end

-- Cleans up a single task using the same rules as Maid:Destroy(). Errors are not caught.
-- @param taskInstance: A function, RBXScriptConnection, Instance, or object with Destroy/Disconnect.
function Maid.cleanupTask(taskInstance)
	local taskType = typeof(taskInstance)
	if taskType == "RBXScriptConnection" then
		taskInstance:Disconnect()
	elseif taskType == "function" then
		taskInstance()
	elseif taskType == "Instance" then
		taskInstance:Destroy()
	elseif taskType == "table" then
		if taskInstance.Disconnect then
			taskInstance:Disconnect()
		elseif taskInstance.Destroy then
			taskInstance:Destroy()
		end
	end
end

local function errorHandler(err)
	return debug.traceback(tostring(err), 2)
end

-- A failing task is reported and skipped so the remaining tasks still get cleaned.
local function cleanupTaskSafely(taskInstance)
	local success, err = xpcall(Maid.cleanupTask, errorHandler, taskInstance)
	if not success then
		warn(string.format("Maid => A cleanup task errored and was skipped: %s", err))
	end
end

-- Adds a task to the maid for cleanup. Accepts functions, connections, or objects with Destroy/Disconnect.
-- @param taskInstance: A function, RBXScriptConnection, or object with Destroy/Disconnect.
-- @param key: Optional key. Giving a different task under the same key cleans up the previous one.
function Maid:GiveTask(taskInstance, key : any?)

	if not Maid.isValidTask(taskInstance) then
		error(string.format("Maid:GiveTask => Invalid task received by maid.\n%s", debug.traceback()), 2);
	end

	if key then
		if self._keyedTasks[key] == taskInstance then
			return
		end
		self:RemoveTask(key)
		self._keyedTasks[key] = taskInstance
	end
	table.insert(self._tasks, taskInstance)
end

-- Cleans up and forgets the task stored under a key.
-- @param key: The key the task was given with.
function Maid:RemoveTask(key)
	local existing = self._keyedTasks[key]
	if not existing then
		return
	end

	for i = #self._tasks, 1, -1 do
		if self._tasks[i] == existing then
			table.remove(self._tasks, i)
			break
		end
	end

	self._keyedTasks[key] = nil
	cleanupTaskSafely(existing)
end

-- Cleans up all tasks in the maid. Functions called, connections disconnected, instances destroyed.
function Maid:Destroy()
	-- Detach the list before running it, so a task that errors, calls Destroy again,
	-- or adds more tasks cannot cause any task to run twice. Added tasks are cleaned too.
	while #self._tasks > 0 do
		local tasks = self._tasks
		self._tasks = {}
		self._keyedTasks = {}

		for i = 1, #tasks do
			cleanupTaskSafely(tasks[i])
		end
	end
end

Maid.AddTask = Maid.GiveTask;
Maid.DoCleaning = Maid.Destroy

-- Creates a new maid instance for resource management.
-- @return: A new maid object.
function Maid.new()
	local maid = setmetatable({}, Maid);

	maid._tasks = {};
	maid._keyedTasks = {};

	return maid;
end

return Maid :: MaidLib
