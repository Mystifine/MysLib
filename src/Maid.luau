--[[
  Maid

	Written by Mystifine
	
	Last Updated: 2026-09-01
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

local function cleanupTask(taskInstance)
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

-- Adds a task to the maid for cleanup. Accepts functions, connections, or objects with Destroy/Disconnect.
-- @param taskInstance: A function, RBXScriptConnection, or object with Destroy/Disconnect.
function Maid:GiveTask(taskInstance, key : any?)

	if not Maid.isValidTask(taskInstance) then
		error(string.format("Maid:GiveTask => Invalid task received by maid.\n%s", debug.traceback()), 2);
	end

	if key then
		self:RemoveTask(key)
		self._keyedTasks[key] = taskInstance
	end
	table.insert(self._tasks, taskInstance)
end

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
	cleanupTask(existing)
end

-- Cleans up all tasks in the maid. Functions called, connections disconnected, instances destroyed.
function Maid:Destroy()
	for i = 1, #self._tasks do
		cleanupTask(self._tasks[i])
	end
	self._tasks = {}
	self._keyedTasks = {}
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
