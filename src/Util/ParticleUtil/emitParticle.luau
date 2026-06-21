local RunService = game:GetService("RunService")

--[=[
	Emits particles from a ParticleEmitter, scaling based on graphics quality (client-only).

	@param particleEmitter ParticleEmitter -- The emitter to emit from
	@param emissionAmount number -- Number of particles to emit

	
	```lua
	ParticleUtil.emitParticle(emitter, 50)
	```
]=]
return function(particleEmitter : ParticleEmitter, emissionAmount : number)
	assert(RunService:IsClient(), "emitParticle can only be called on the client.");

	local qualityLevel = UserSettings().GameSettings.SavedQualityLevel
	if qualityLevel == Enum.SavedQualitySetting.Automatic then
		particleEmitter:Emit(emissionAmount)
	else
		local scalingFactor = qualityLevel.Value/10
		particleEmitter:Emit(emissionAmount*scalingFactor)
	end
end
