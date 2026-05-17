--[[
  Maid

	Written by Mystifine
	
	Last Updated: 2026-05-16
]]

export type Maid = {
	ClassName : string,
	
	GiveTask : (self : Maid, taskInstance : any?) -> nil,
	AddTask : (self : Maid, taskInstance : any?) -> nil,
	Destroy : (self : Maid) -> nil;
	DoCleaning : (self : Maid) -> nil;
}

export type MaidLib = {
	new : () -> Maid 
}

local Maid = {}
Maid.__index = Maid;
Maid.ClassName = "Maid";

local function isValidTask(taskInstance)
	local taskType = typeof(taskInstance);
	if taskInstance ~= nil and (taskType == "function" or taskType == "RBXScriptConnection" or taskInstance.Destroy or taskInstance.Disconnect) then
		return true;
	end
  return false;
end

function Maid:GiveTask(taskInstance)
	
	if not isValidTask(taskInstance) then
		error(string.format("Maid:GiveTask => Invalid task received by maid.\n%s", debug.traceback()), 2);
	end
	
	table.insert(self._tasks, taskInstance);
end

function Maid:Destroy()
	for i = 1, #self._tasks do 
		local taskInstance = self._tasks[i];
		local taskType = typeof(taskInstance);
		
		if taskType == "RBXScriptConnection" then
			taskInstance:Disconnect();
		elseif taskType == "function" then
			taskInstance();
		elseif taskType == "table" and taskInstance.Disconnect then
			taskInstance:Disconnect()
		elseif taskInstance.Destroy then
			taskInstance:Destroy()
		end
	end
	
	self._tasks = {};
end

Maid.AddTask = Maid.GiveTask;
Maid.DoCleaning = Maid.Destroy

function Maid.new()
	local maid = setmetatable({}, Maid);
	
	maid._tasks = {};
	
	return maid;
end

return Maid :: MaidLib
