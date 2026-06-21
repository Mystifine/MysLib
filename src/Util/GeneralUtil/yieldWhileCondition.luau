local RunService = game:GetService('RunService')

export type YieldWhileConditionConfigs = {
	duration : number,
	condition : () -> boolean?,
	onSuccess : (elapsedTime : number) -> nil,
	onTick : (elapsedTime : number) -> nil,
	onFail : (elapsedTime : number) -> nil
}

--[=[
	Yields while a condition is true or until a timeout is reached.

	@param config YieldWhileConditionConfigs -- Configuration table
	@return boolean -- true if duration met, false if condition became false

	
	```lua
	local result = yieldWhileCondition({
		duration = 5,
		condition = function()
			return workspace.Target and workspace.Target.Parent
		end,
		onTick = function(elapsed)
			print("Waiting:", elapsed)
		end,
		onSuccess = function()
			print("Target disappeared!")
		end,
		onFail = function()
			print("Timed out!")
		end
	})
	```
]=]
return function(YieldWhileConditionConfigs : YieldWhileConditionConfigs)
	local duration = YieldWhileConditionConfigs.duration or 0;
	local startTime = os.clock();

	local conditionCallback = YieldWhileConditionConfigs.condition or function() end
	local onSuccessCallback = YieldWhileConditionConfigs.onSuccess or function() end
	local onFailCallback = YieldWhileConditionConfigs.onFail or function() end
	local onTick = YieldWhileConditionConfigs.onTick or function() end;

	while os.clock() - startTime < duration and conditionCallback() do
		local _elapsedTime = os.clock() - startTime;
		onTick(_elapsedTime);
		RunService.Heartbeat:Wait()
	end

	local _elapsedTime = os.clock() - startTime;
	if (_elapsedTime) >= duration then
		onSuccessCallback(_elapsedTime);
		return true;
	else
		onFailCallback(_elapsedTime);
		return false;
	end
end
