local RunService = game:GetService("RunService")

export type HeartbeatConnection = {
	LastCallback : number,
	Cooldown : number,
	HeartbeatId : string,
	Callback : (elapsed : number) -> nil,

	Destroy : (self : HeartbeatConnection) -> nil,
	Disconnect : (self : HeartbeatConnection) -> nil,

	new : (onHeartbeat : (elapsed : number) -> nil, cooldown : number?) -> HeartbeatConnection,
}

local Heartbeat = {}

local heartbeatConnection = nil
local heartbeatId = 0
local activeCallbacks : {[string] : HeartbeatConnection} = {}

local function handleHeartbeatUpdate()
	if next(activeCallbacks) == nil then
		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
		return
	end

	-- Shallow copy to avoid mutation issues
	local tempCallbacks : {[number] : {heartbeat : HeartbeatConnection, elapsed : number}} = {};
	local now = workspace:GetServerTimeNow();
	for _, obj in pairs(activeCallbacks) do
		local elapsed = now - obj.LastCallback;
		if elapsed >= obj.Cooldown then
			obj.LastCallback = now;
			table.insert(tempCallbacks, {heartbeat = obj, elapsed = elapsed});
		end
	end

	for i = 1, #tempCallbacks do
		local heartbeatInfo = tempCallbacks[i];
		local ok ,err = pcall(heartbeatInfo.heartbeat.Callback, heartbeatInfo.elapsed);
		
		if not ok then
			-- Throw warning with traceback
			warn("Heartbeat callback error: " .. tostring(err))
		end
	end
	table.clear(tempCallbacks);
end

--[[ Equivalent to Destroy ]]
function Heartbeat:Disconnect()
	if activeCallbacks[self.HeartbeatId] then
		activeCallbacks[self.HeartbeatId] = nil
	end
end
Heartbeat.Destroy = Heartbeat.Disconnect

function Heartbeat.new(onHeartbeat : (deltaTime : number) -> nil, cooldown : number?)
	assert(onHeartbeat, "Heartbeat callback missing")

	cooldown = cooldown or 0;
	heartbeatId += 1

	local self = setmetatable({}, {__index = Heartbeat})
	self.HeartbeatId = tostring(heartbeatId)
	self.Callback = onHeartbeat
	self.Cooldown = cooldown;
	self.LastCallback = workspace:GetServerTimeNow() - cooldown;

	activeCallbacks[self.HeartbeatId] = self;

	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(handleHeartbeatUpdate)
	end

	return self
end

return Heartbeat
