local weldConstraint = require(script.Parent.weldConstraint);

local function weldModel(model : Model)
	if not model.PrimaryPart then 
		warn(string.format("[%s]: Attempted to weld model '%s' but model has no PrimaryPart.\nTraceback: %s", script.Name, model.Name, debug.traceback()));
		return;
	end
	
	local children = model:GetChildren();
	for i = 1, #children do 
		local child = children[i];
		if child:IsA("BasePart") then
			-- Update properties for the BasePart
			child.Anchored = false;
			child.CanCollide = false;
			child.CanTouch = false;
			child.Massless = true;
			
			-- Ignore the PrimaryPart
			if child == model.PrimaryPart then continue end;
			weldConstraint(model.PrimaryPart, child);
		elseif child:IsA("Model") then
			weldModel(child);
		end
	end
end

return weldModel;