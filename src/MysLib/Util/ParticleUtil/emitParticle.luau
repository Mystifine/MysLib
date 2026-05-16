local RunService = game:GetService("RunService")

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
