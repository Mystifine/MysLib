--[[
  Debris Library
  
  By: Mystifine#4924
  
  Last Updated: 2026-05-16
]]

local RunService = game:GetService("RunService")

local Maid = require(script.Parent.Maid);

local trashCollector = Maid.new();

export type DebrisLib = {
	AddItem : (object : Instance | {}, destroyTime : number) -> nil,
	RemoveItem : (object : Instance | {}) -> nil
}

local Debris = {}

local heartbeatEventConnection : RBXScriptConnection? = nil;
local trashSchedule : {
	[number] : {
		timeStamp : number, 
		destroyTime : number, 
		item : Instance | {}
	}
} = {};

local function onHeartbeat()
	local index = #trashSchedule;
	
	while index >= 1 do 
		local trash = trashSchedule[index];
		if os.clock() - trash.timeStamp >= trash.destroyTime then
			trashCollector:GiveTask(trash.item);
			trashCollector:DoCleaning();
			table.remove(trashSchedule, index);
		end
		index -= 1;
	end
	
	if #trashSchedule == 0 then
		heartbeatEventConnection = heartbeatEventConnection and heartbeatEventConnection:Disconnect();
	end
end

-- Schedules an object for destruction after a specified delay.
-- @param object: The Instance or table to be destroyed.
-- @param destroyTime: Time in seconds before destruction.
function Debris.AddItem(object, destroyTime)
	assert( (typeof(object) == "Instance" or typeof(object) == "table"), string.format("Error: invalid <object> type passed: %s, expected instance or list", typeof(object)) );
	assert( typeof(destroyTime) == "number", string.format("Error: invalid <destroyTime> type passed: %s, expected number", typeof(destroyTime)) );

	table.insert(trashSchedule, {
		timeStamp = os.clock(),
		destroyTime = destroyTime,
		item = object,
	});

	if #trashSchedule > 0 and not heartbeatEventConnection then
		heartbeatEventConnection = RunService.Heartbeat:Connect(onHeartbeat)
	end
end

-- Removes a scheduled item before it's destroyed.
-- @param object: The object to remove from destruction schedule.
function Debris.RemoveItem(object)
	local index = #trashSchedule;

	while index >= 1 do
		local trash = trashSchedule[index];
		if trash.item == object then
			table.remove(trashSchedule, index);
		end
		index -= 1;
	end
end

return Debris
