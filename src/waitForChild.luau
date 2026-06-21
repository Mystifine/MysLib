--[[
	waitForChild
	
	By: Mystifine#4924
	
	Last Updated: 2026-05-16
]]

local RunService = game:GetService("RunService")

local WARNING_TIME = 30;

-- Waits for a child to be added to an instance with optional timeout and warnings.
-- @param parent: Parent instance to search in.
-- @param childName: Name of the child to find.
-- @param timeOut: Maximum time to wait (optional).
-- @return: The child instance or nil if timeout/parent destroyed.
return function(objectA: Instance, childName: string, timeOut: number?)
  local actualTimeOut = timeOut or math.huge;
	local start = os.clock()
	local warned = false;

	local found = objectA:FindFirstChild(childName)
	if found then
		return found
	end

	local connection
	connection = objectA.ChildAdded:Connect(function(child)
		if child.Name == childName then
			found = child
			connection:Disconnect()
		end
	end)

	-- Wait until timeout OR found OR object destroyed
	while not found and objectA.Parent and os.clock() - start < actualTimeOut do
		
		if os.clock() - start > WARNING_TIME and not warned then
			warn(string.format("waitForChild => Infinite yield possible for %s, waiting on: %s", objectA:GetFullName(), childName));
			warned = true;
		end
		
		RunService.Heartbeat:Wait()
	end

	if connection and connection.Connected then
		connection:Disconnect()
	end

	if not objectA.Parent then
		return nil -- destroyed
	end
	
	if not found then
		warn(string.format("waitForChild => Timed out after %.2f seconds waiting for %s.%s",actualTimeOut, objectA:GetFullName(), childName))
	end

	return found
end
