

return function(instance : Instance)
	local children = instance:GetDescendants();
	for i = 1, #children do 
		local child : ParticleEmitter = children[i];
		if child:IsA("ParticleEmitter") then
			child:Clear()
		end
	end
end
