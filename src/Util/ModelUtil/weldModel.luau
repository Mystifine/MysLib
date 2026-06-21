local weldConstraint = require(script.Parent.weldConstraint);

--[=[
	Welds all parts in a model to its PrimaryPart with physics properties adjusted.

	Sets parts to: not anchored, no collision, no touch, massless
	Recursively welds nested models. Requires the model to have a PrimaryPart set.

	@param model Model -- The model to weld (must have PrimaryPart)

	
	```lua
	model.PrimaryPart = model:FindFirstChild("Head")
	ModelUtil.weldModel(model)
	```
]=]
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