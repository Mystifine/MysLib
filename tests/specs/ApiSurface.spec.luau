--[[
	Backwards compatibility guard: every name consumers could already reach must keep existing.
	Add to this list when the public API grows, never remove from it without a major version.
]]

local TestKit = require("../harness/TestKit")
local describe, it, sandbox, ok = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.ok

local function assertMembers(owner, ownerName, members)
	for _, member in members do
		ok(owner[member] ~= nil, ownerName .. "." .. member)
	end
end

describe("public API surface", function()
	it("keeps every module on the root table", function()
		assertMembers(sandbox().require(), "MysLib", {
			"Version", "StringUtil", "MathUtil", "PhysicsUtil", "ParticleUtil", "TableUtil", "PlayerUtil",
			"ModelUtil", "GeneralUtil", "Bootstrapper", "AttributeModifier", "Maid", "Hitbox", "Debris",
			"Signal", "waitForChild",
		})
	end)

	it("keeps Signal members", function()
		local Signal = sandbox().require("Signal")
		assertMembers(Signal, "Signal", { "new", "ClassName" })
		local signal = Signal.new()
		assertMembers(signal, "signal", { "Connect", "Once", "Wait", "Fire", "ClassName" })
		assertMembers(signal:Connect(function() end), "connection", { "Disconnect" })
		assertMembers(signal:Once(function() end), "connection", { "Disconnect" })
	end)

	it("keeps Maid members", function()
		local Maid = sandbox().require("Maid")
		assertMembers(Maid, "Maid", { "new", "isValidTask", "ClassName" })
		assertMembers(Maid.new(), "maid", { "GiveTask", "AddTask", "RemoveTask", "Destroy", "DoCleaning", "ClassName" })
	end)

	it("keeps Debris, Bootstrapper and waitForChild members", function()
		local sb = sandbox()
		assertMembers(sb.require("Debris"), "Debris", { "AddItem", "RemoveItem" })
		assertMembers(sb.require("Bootstrapper"), "Bootstrapper", { "errorHandler", "loadModule" })
		ok(type(sb.require("waitForChild")) == "function", "waitForChild")
	end)

	it("keeps Hitbox members and public hitbox fields", function()
		local sb = sandbox()
		local Hitbox = sb.require("Hitbox")
		assertMembers(Hitbox, "Hitbox", {
			"square", "sphere", "basePart", "projectile", "raycast", "spherecast",
			"getPartBoundsInRadius", "getPartBoundsInBox", "getPartsInPart", "getClosestTarget",
		})

		local function onHit() end
		local hitbox = Hitbox.square({ cframe = sb.CFrame.new(), size = sb.Vector3.new(1, 1, 1), onHit = onHit })
		assertMembers(hitbox, "hitbox", { "Cast", "Start", "Stop", "Destroy", "cframe", "size", "ignoreList", "onHit", "visualize" })
	end)

	it("keeps AttributeModifier members", function()
		local sb = sandbox()
		local AttributeModifier = sb.require("AttributeModifier")
		assertMembers(AttributeModifier, "AttributeModifier", { "new" })
		local modifier = AttributeModifier.new(sb.new("Humanoid"), "WalkSpeed")
		assertMembers(modifier, "modifier", { "IncrementValue", "SetValue", "Destroy" })
	end)

	it("keeps utility members", function()
		local MysLib = sandbox().require()
		assertMembers(MysLib.StringUtil, "StringUtil", { "abbrev", "addCommas", "formatTime", "RichText" })
		assertMembers(MysLib.StringUtil.RichText, "RichText", {
			"bold", "strikethrough", "underline", "italic", "size", "stroke", "color", "transparency",
		})
		assertMembers(MysLib.MathUtil, "MathUtil", { "truncate", "randomNumber", "rng", "lerp", "quadBezier", "cubicBezier" })
		assertMembers(MysLib.PhysicsUtil, "PhysicsUtil", {
			"Orientation", "Velocity", "getHorizontalNormalizedVector", "getHorizontalDistance",
		})
		assertMembers(MysLib.PhysicsUtil.Velocity, "Velocity", { "new", "ClassName", "SetVelocity", "SetMaxForce", "Destroy" })
		assertMembers(MysLib.PhysicsUtil.Orientation, "Orientation", { "new", "SetCFrame", "SetMaxTorque", "Destroy" })
		assertMembers(MysLib.ParticleUtil, "ParticleUtil", {
			"emitParticle", "playParticleEffects", "setParticlesEnabled", "setBeamsEnabled", "clearAllParticles",
		})
		assertMembers(MysLib.TableUtil, "TableUtil", { "deepCopy" })
		assertMembers(MysLib.PlayerUtil, "PlayerUtil", {
			"isCharacterAlive", "getMouseHit", "getPlayerPlatform", "getPlayerThumbnailFromUserId", "getPlayerNameFromUserId",
		})
		assertMembers(MysLib.ModelUtil, "ModelUtil", { "getModelLargestPart", "weldConstraint", "weldModel" })
		assertMembers(MysLib.GeneralUtil, "GeneralUtil", { "yieldWhileCondition", "Heartbeat", "Stepped", "warn" })
		assertMembers(MysLib.GeneralUtil.Heartbeat, "Heartbeat", { "new", "Disconnect", "Destroy" })
		assertMembers(MysLib.GeneralUtil.Stepped, "Stepped", { "new", "Disconnect", "Destroy" })
	end)
end)
