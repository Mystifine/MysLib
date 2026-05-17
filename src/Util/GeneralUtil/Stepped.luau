local RunService = game:GetService("RunService")

export type SteppedConnection = {
	LastCallback : number,
	Cooldown : number,
	SteppedId : string,
	Callback : (elapsed : number) -> nil,

	Destroy : (self : SteppedConnection) -> nil,
	Disconnect : (self : SteppedConnection) -> nil,

	new : (onStepped : (elapsed : number) -> nil, cooldown : number?) -> SteppedConnection,
}

local Stepped = {}

local heartbeatConnection = nil
local heartbeatId = 0
local activeCallbacks : {[string] : SteppedConnection} = {}

local function handleSteppedUpdate()
	if next(activeCallbacks) == nil then
		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
		return
	end

	-- Shallow copy to avoid mutation issues
	local tempCallbacks : {[number] : {stepped : SteppedConnection, elapsed : number}} = {};
	local now = workspace:GetServerTimeNow();
	for _, obj in pairs(activeCallbacks) do
		local elapsed = now - obj.LastCallback;
		if elapsed >= obj.Cooldown then
			obj.LastCallback = now;
			table.insert(tempCallbacks, {
				stepped = obj, 
				elapsed = elapsed
			})
		end
	end

	for i = 1, #tempCallbacks do
		local heartbeatInfo = tempCallbacks[i];
		local ok ,err = pcall(heartbeatInfo.stepped.Callback, heartbeatInfo.elapsed);

		if not ok then
			-- Throw warning with traceback
			warn("Stepped callback error: " .. tostring(err))
		end
	end
	table.clear(tempCallbacks);
end

--[[ Equivalent to Destroy ]]
function Stepped:Disconnect()
	if activeCallbacks[self.SteppedId] then
		activeCallbacks[self.SteppedId] = nil
	end
end
Stepped.Destroy = Stepped.Disconnect

function Stepped.new(onStepped : (deltaTime : number) -> nil, cooldown : number?)
	assert(onStepped, "Stepped callback missing")

	cooldown = cooldown or 0;
	heartbeatId += 1

	local self = setmetatable({}, {__index = Stepped})
	self.SteppedId = tostring(heartbeatId)
	self.Callback = onStepped
	self.Cooldown = cooldown;
	self.LastCallback = workspace:GetServerTimeNow() - cooldown;

	activeCallbacks[self.SteppedId] = self;

	if not heartbeatConnection then
		heartbeatConnection = RunService.Stepped:Connect(handleSteppedUpdate)
	end

	return self
end

return Stepped
