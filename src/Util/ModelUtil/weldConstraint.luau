--[=[
	Creates a WeldConstraint connecting two parts together.

	@param part0 BasePart -- The primary part (anchor)
	@param part1 BasePart -- The part to weld to part0
	@return WeldConstraint -- The created constraint

	
	```lua
	ModelUtil.weldConstraint(part1, part2)
	```
]=]
return function(part0 : BasePart, part1 : BasePart)
	local wc = Instance.new("WeldConstraint");
	wc.Part0 = part0;
	wc.Part1 = part1;
	wc.Name = part1.Name;
	wc.Parent = part1;
	return wc;
end
