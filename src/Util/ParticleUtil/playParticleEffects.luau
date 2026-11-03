--[[
  playParticleEffects

  By: Mystifine#4924

  Last Updated: 2026-11-02
]]

local RunService = game:GetService("RunService");

local emitParticle = require(script.Parent.emitParticle);

local heartbeatConnection;
local emissionDictionary = {};

-- Reads a numeric attribute, falling back to the default when it is unset or holds the wrong type.
local function getNumberAttribute(particleEmitter : ParticleEmitter, attributeName : string, default : number) : number
	local value = particleEmitter:GetAttribute(attributeName);
	if type(value) == "number" then
		return value;
	end
	if value ~= nil then
		warn(string.format("playParticleEffects => %s on '%s' must be a number, got %s. Using %s instead.", attributeName, particleEmitter:GetFullName(), typeof(value), tostring(default)));
	end
	return default;
end

--[=[
	Plays all particle effects in an instance with timing control via attributes.

	Looks for ParticleEmitters in the instance and reads attributes:
	- EmitCount: Number of particles to emit (default: Rate)
	- EmitDelay: Delay before emission starts (default: 0)
	- EmitDuration: How long particles emit (default: 0)

	@param instance Instance -- Instance containing particle emitters


	```lua
	ParticleUtil.playParticleEffects(workspace.EffectPart)
	```
]=]
return function(instance : Instance)

	local children = instance:GetDescendants();
	for i = 1, #children do
		local child = children[i]
		if child:IsA("ParticleEmitter") then
			child.Enabled = false -- reset regardless of prior in-flight state

			local emitCount = getNumberAttribute(child, "EmitCount", child.Rate)
			local emitDelay = getNumberAttribute(child, "EmitDelay", 0)
			local emitDuration = getNumberAttribute(child, "EmitDuration", 0)

			emissionDictionary[child] = {
				entryTime = os.clock(),
				emitTime = nil,
				emitCount = emitCount,
				emitDelay = emitDelay,
				emitDuration = emitDuration,
			}
		end
	end

	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			if next(emissionDictionary) == nil then
				heartbeatConnection = heartbeatConnection and heartbeatConnection:Disconnect();
			end
			for particleEmitter, emissionData in pairs(emissionDictionary) do

				-- Situation 1: Particle Emitter destroyed early
				if not particleEmitter or particleEmitter.Parent == nil then
					emissionDictionary[particleEmitter] = nil;
					continue;
				end

				-- Situation 2: New particle entry
				if not emissionData.emitTime and os.clock() - emissionData.entryTime >= emissionData.emitDelay then
					-- Dropped on failure, so one bad emitter cannot error every frame or stall the others.
					local success, err = pcall(emitParticle, particleEmitter, emissionData.emitCount);
					if not success then
						warn(string.format("playParticleEffects => Failed to emit from '%s': %s", particleEmitter:GetFullName(), tostring(err)));
						emissionDictionary[particleEmitter] = nil;
						continue;
					end

					emissionData.emitTime = os.clock();
					if emissionData.emitDuration > 0 then
						particleEmitter.Enabled = true;
					else
						emissionDictionary[particleEmitter] = nil;
						continue;
					end
				end

				-- Situation 3: Emitting particle with emit duration
				if emissionData.emitTime and os.clock() - emissionData.emitTime >= emissionData.emitDuration then
					particleEmitter.Enabled = false;
					emissionDictionary[particleEmitter] = nil;
					continue;
				end
			end

		end);
	end
end
