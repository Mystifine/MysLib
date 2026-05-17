

return function(part0 : BasePart, part1 : BasePart)
	local wc = Instance.new("WeldConstraint");
	wc.Part0 = part0;
	wc.Part1 = part1;
	wc.Name = part1.Name;
	wc.Parent = part1;	
	return wc;
end
