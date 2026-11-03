--[=[
	Finds the part with the largest size magnitude in a model and its descendants.

	@param model Model -- The model to search
	@return (BasePart?, number?) -- The largest part and its size magnitude, or nil if the model has no parts


	```lua
	local largest, size = ModelUtil.getModelLargestPart(workspace.Model)
	print(largest.Name, size)
	```
]=]
local function getModelLargestPart(model : Model) : (BasePart?, number?)
	local largest, size;
	local descendants = model:GetDescendants();
	for i = 1, #descendants do
		local descendant = descendants[i];
		if descendant:IsA("BasePart") and (not largest or descendant.Size.Magnitude > size) then
			largest, size = descendant, descendant.Size.Magnitude;
		end
	end

	return largest, size;
end

return getModelLargestPart;
