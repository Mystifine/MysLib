--[=[
	Finds the part with the largest size magnitude in a model and its descendants.

	@param model Model -- The model to search
	@return (BasePart, number) -- The largest part and its size magnitude

	
	```lua
	local largest, size = ModelUtil.getModelLargestPart(workspace.Model)
	print(largest.Name, size)
	```
]=]
local function getModelLargestPart(model : Model) : (BasePart, number)
	local largest, size;
	local children = model:GetChildren();
	for i = 1, #children do
		local child = children[i];
		if child:IsA("BasePart") then
			if not largest or child.Size.Magnitude > size then
				largest, size = child, child.Size.Magnitude;
			end
		else
			largest, size = getModelLargestPart(child);
		end
	end

	return largest, size;
end

return getModelLargestPart;
