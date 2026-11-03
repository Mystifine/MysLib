local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, no = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.no

local function qualityLevel(sb, level)
	return sb.Enum.SavedQualitySetting["QualityLevel" .. level]
end

describe("ParticleUtil.emitParticle", function()
	it("emits at least 1 particle at every quality level", function()
		for level = 1, 10 do
			local sb = sandbox()
			sb.qualityLevel = qualityLevel(sb, level)
			local emitter = sb.new("ParticleEmitter")
			sb.require("Util.ParticleUtil.emitParticle")(emitter, 1)
			eq(emitter.__EmitLog[1], 1, "level " .. level)
		end
	end)

	it("scales larger amounts by quality and only ever passes whole numbers", function()
		local sb = sandbox()
		local emit = sb.require("Util.ParticleUtil.emitParticle")

		local expectations = { { 1, 5, 1 }, { 1, 10, 1 }, { 1, 25, 2 }, { 3, 50, 15 }, { 5, 3, 1 }, { 7, 30, 21 }, { 10, 50, 50 } }
		for _, case in expectations do
			sb.qualityLevel = qualityLevel(sb, case[1])
			local emitter = sb.new("ParticleEmitter")
			emit(emitter, case[2])
			eq(emitter.__EmitLog[1], case[3], string.format("level %d amount %d", case[1], case[2]))
		end
	end)

	it("emits the full amount on Automatic quality", function()
		local sb = sandbox()
		local emitter = sb.new("ParticleEmitter")
		sb.require("Util.ParticleUtil.emitParticle")(emitter, 50)
		eq(emitter.__EmitLog[1], 50)
	end)

	it("applies the minimum to fractional amounts on Automatic quality too", function()
		local sb = sandbox()
		local emitter = sb.new("ParticleEmitter")
		sb.require("Util.ParticleUtil.emitParticle")(emitter, 0.5)
		eq(emitter.__EmitLog[1], 1)
	end)

	it("treats an explicit 0 or negative amount as no burst", function()
		local sb = sandbox()
		local emit = sb.require("Util.ParticleUtil.emitParticle")
		for _, amount in { 0, -5 } do
			local emitter = sb.new("ParticleEmitter")
			emit(emitter, amount)
			eq(emitter.__EmitLog, nil, "amount " .. amount)
		end
	end)

	it("falls back to the engine default when no amount is given, at any quality", function()
		local sb = sandbox()
		local emit = sb.require("Util.ParticleUtil.emitParticle")

		local automatic = sb.new("ParticleEmitter")
		emit(automatic)
		eq(automatic.__EmitLog[1], 16)

		sb.qualityLevel = qualityLevel(sb, 5)
		local scaled = sb.new("ParticleEmitter")
		emit(scaled)
		eq(scaled.__EmitLog[1], 8)
	end)

	it("still refuses to run on the server", function()
		local sb = sandbox({ isClient = false })
		TestKit.throws(function()
			sb.require("Util.ParticleUtil.emitParticle")(sb.new("ParticleEmitter"), 5)
		end, "only be called on the client")
	end)
end)

describe("ParticleUtil.playParticleEffects", function()
	local function setup(attributes, props)
		local sb = sandbox()
		local play = sb.require("Util.ParticleUtil.playParticleEffects")
		local holder = sb.new("Part", { Parent = sb.workspace })
		local emitter = sb.new("ParticleEmitter", props)
		emitter.Parent = holder
		for name, value in attributes or {} do
			emitter:SetAttribute(name, value)
		end
		return sb, play, holder, emitter
	end

	it("emits EmitCount immediately, then releases its heartbeat connection", function()
		local sb, play, holder, emitter = setup({ EmitCount = 10 })
		play(holder)
		eq(emitter.Enabled, false)
		sb.step()
		eq(emitter.__EmitLog[1], 10)
		sb.step()
		sb.step()
		eq(#emitter.__EmitLog, 1)
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)

	it("falls back to Rate when EmitCount is not set", function()
		local sb, play, holder, emitter = setup(nil, { Rate = 7 })
		play(holder)
		sb.step()
		eq(emitter.__EmitLog[1], 7)
	end)

	it("keeps at least 1 particle at the lowest quality", function()
		local sb, play, holder, emitter = setup({ EmitCount = 3 })
		sb.qualityLevel = qualityLevel(sb, 1)
		play(holder)
		sb.step()
		eq(emitter.__EmitLog[1], 1)
	end)

	it("honours EmitDelay", function()
		local sb, play, holder, emitter = setup({ EmitCount = 5, EmitDelay = 1 })
		play(holder)
		sb.advance(0.5)
		eq(emitter.__EmitLog, nil)
		sb.advance(0.6)
		eq(emitter.__EmitLog[1], 5)
	end)

	it("enables the emitter for EmitDuration, then disables it", function()
		local sb, play, holder, emitter = setup({ EmitCount = 5, EmitDuration = 1 })
		play(holder)
		sb.step()
		eq(emitter.Enabled, true)
		sb.advance(1.1)
		eq(emitter.Enabled, false)
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)

	it("does not add a stray particle when EmitCount is 0 with an EmitDuration", function()
		local sb, play, holder, emitter = setup({ EmitCount = 0, EmitDuration = 1 })
		play(holder)
		sb.step()
		eq(emitter.__EmitLog, nil)
		eq(emitter.Enabled, true)
	end)

	it("does not wedge the queue when an attribute holds a bad value", function()
		local sb, play, holder, emitter = setup({ EmitCount = "lots", EmitDelay = "soon" }, { Rate = 4 })
		local healthy = sb.new("ParticleEmitter", { Parent = holder })
		healthy:SetAttribute("EmitCount", 9)
		play(holder)
		sb.step()
		sb.step()
		eq(emitter.__EmitLog[1], 4)
		eq(healthy.__EmitLog[1], 9)
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)

	it("keeps other emitters going when one throws while emitting", function()
		local sb, play, holder, broken = setup({ EmitCount = 2 })
		broken.__FailEmit = true
		local healthy = sb.new("ParticleEmitter", { Parent = holder })
		healthy:SetAttribute("EmitCount", 9)

		play(holder)
		sb.step()
		sb.step()

		eq(healthy.__EmitLog[1], 9)
		eq(#sb.errors, 0)
		ok(sb.hasWarning("simulated engine failure"))
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)

	it("warns once on the server instead of erroring every frame", function()
		local sb = sandbox({ isClient = false })
		local play = sb.require("Util.ParticleUtil.playParticleEffects")
		local holder = sb.new("Part", { Parent = sb.workspace })
		sb.new("ParticleEmitter", { Parent = holder })
		play(holder)
		sb.advance(0.2)
		eq(#sb.errors, 0, "errors per frame")
		ok(sb.hasWarning("only be called on the client"))
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)
end)

describe("ParticleUtil toggles", function()
	it("setParticlesEnabled and setBeamsEnabled affect only their own class", function()
		local sb = sandbox()
		local ParticleUtil = sb.require("Util.ParticleUtil")
		local holder = sb.new("Model")
		local emitter = sb.new("ParticleEmitter", { Parent = holder })
		local beam = sb.new("Beam", { Parent = holder })

		ParticleUtil.setParticlesEnabled(holder, false)
		eq(emitter.Enabled, false)
		eq(beam.Enabled, true)

		ParticleUtil.setBeamsEnabled(holder, false)
		eq(beam.Enabled, false)
	end)

	it("clearAllParticles clears nested emitters", function()
		local sb = sandbox()
		local holder = sb.new("Model")
		local folder = sb.new("Folder", { Parent = holder })
		local emitter = sb.new("ParticleEmitter", { Parent = folder })
		sb.require("Util.ParticleUtil").clearAllParticles(holder)
		eq(emitter.__Cleared, 1)
		no(emitter.__EmitLog)
	end)
end)
