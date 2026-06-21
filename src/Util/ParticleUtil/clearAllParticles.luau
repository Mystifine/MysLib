--[=[
	Clears all particles from all ParticleEmitters in an instance and descendants.

	@param instance Instance -- Instance to clear particles from

	
	```lua
	ParticleUtil.clearAllParticles(workspace.EffectPart)
	```
]=]
return function(instance : Instance)
	local children = instance:GetDescendants();
	for i = 1, #children do
		local child : ParticleEmitter = children[i];
		if child:IsA("ParticleEmitter") then
			child:Clear()
		end
	end
end
