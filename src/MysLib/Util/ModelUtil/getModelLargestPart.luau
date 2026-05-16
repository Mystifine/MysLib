

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
