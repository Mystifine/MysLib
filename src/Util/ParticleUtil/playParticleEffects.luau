--[[
  Debris Library
  
  By: Mystifine#4924
  
  Last Updated: 2026-09-01
]]

local RunService = game:GetService("RunService");

local emitParticle = require(script.Parent.emitParticle);

local heartbeatConnection;
local emissionDictionary = {};

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
	
			local emitCount = child:GetAttribute("EmitCount") or child.Rate
			local emitDelay = child:GetAttribute("EmitDelay") or 0
			local emitDuration = child:GetAttribute("EmitDuration") or 0
			
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
					emitParticle(particleEmitter, emissionData.emitCount);
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
