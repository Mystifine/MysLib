--[=[
	Enables or disables all Beams in an instance and descendants.

	@param instance Instance -- Instance containing beams
	@param enabled boolean -- true to enable, false to disable

	
	```lua
	ParticleUtil.setBeamsEnabled(workspace.Model, true)
	```
]=]
return function(instance : Instance, enabled : boolean)
	local children = instance:GetDescendants();
	for i = 1, #children do
		local child = children[i];
		if child:IsA("Beam") then
			child.Enabled = enabled;
		end
	end
end
