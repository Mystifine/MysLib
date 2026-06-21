--[=[
	Enables or disables all ParticleEmitters in an instance and descendants.

	@param instance Instance -- Instance containing particles
	@param enabled boolean -- true to enable, false to disable

	
	```lua
	ParticleUtil.setParticlesEnabled(workspace.Model, false)
	```
]=]
return function(instance : Instance, enabled : boolean)
	local children = instance:GetDescendants();
	for i = 1, #children do
		local child = children[i];
		if child:IsA("ParticleEmitter") then
			child.Enabled = enabled;
		end
	end
end
