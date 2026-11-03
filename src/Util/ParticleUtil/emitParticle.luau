local RunService = game:GetService("RunService")

-- Matches ParticleEmitter:Emit()'s own default when no count is given.
local DEFAULT_EMISSION_AMOUNT = 16;

local gameSettings = nil;

--[=[
	Emits particles from a ParticleEmitter, scaling based on graphics quality (client-only).

	Any positive amount emits at least 1 particle, so small bursts stay visible at low
	quality settings instead of being scaled down to nothing. An amount of 0 or less
	emits nothing.

	@param particleEmitter ParticleEmitter -- The emitter to emit from
	@param emissionAmount number? -- Number of particles to emit (default: 16)


	```lua
	ParticleUtil.emitParticle(emitter, 50)
	```
]=]
return function(particleEmitter : ParticleEmitter, emissionAmount : number?)
	assert(RunService:IsClient(), "emitParticle can only be called on the client.");

	local amount = emissionAmount or DEFAULT_EMISSION_AMOUNT;
	if amount <= 0 then
		return;
	end

	gameSettings = gameSettings or UserSettings().GameSettings;
	local qualityLevel = gameSettings.SavedQualityLevel;
	if qualityLevel ~= Enum.SavedQualitySetting.Automatic then
		-- Multiplying before dividing keeps whole-number results exact.
		amount = amount * qualityLevel.Value / 10;
	end

	-- Emit() truncates to a whole number, so a scaled amount below 1 would emit nothing.
	particleEmitter:Emit(math.max(1, math.floor(amount)));
end
