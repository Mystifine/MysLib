

return function(instance : Instance, enabled : boolean)
	local children = instance:GetDescendants();
	for i = 1, #children do 
		local child = children[i];
		if child:IsA("ParticleEmitter") then
			child.Enabled = enabled;
		end
	end
end
