local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, no = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.no

local function makeCharacter(sb, humanoidName)
	local character = sb.new("Model", { Parent = sb.workspace })
	local root = sb.new("Part", { Parent = character })
	character.PrimaryPart = root
	sb.new("Humanoid", { Name = humanoidName or "Humanoid", Parent = character })
	return character
end

describe("PlayerUtil.isCharacterAlive", function()
	it("accepts a healthy character", function()
		local sb = sandbox()
		ok(sb.require("Util.PlayerUtil").isCharacterAlive(makeCharacter(sb)))
	end)

	it("accepts a character whose Humanoid has another name", function()
		local sb = sandbox()
		ok(sb.require("Util.PlayerUtil").isCharacterAlive(makeCharacter(sb, "EnemyHumanoid")))
	end)

	it("rejects missing, unparented, dead and incomplete characters", function()
		local sb = sandbox()
		local isCharacterAlive = sb.require("Util.PlayerUtil").isCharacterAlive

		no(isCharacterAlive(nil), "nil")

		local unparented = makeCharacter(sb)
		unparented.Parent = nil
		no(isCharacterAlive(unparented), "unparented")

		local noHumanoid = makeCharacter(sb)
		noHumanoid:FindFirstChildOfClass("Humanoid"):Destroy()
		no(isCharacterAlive(noHumanoid), "no humanoid")

		local zeroHealth = makeCharacter(sb)
		zeroHealth:FindFirstChildOfClass("Humanoid").Health = 0
		no(isCharacterAlive(zeroHealth), "zero health")

		local deadState = makeCharacter(sb)
		deadState:FindFirstChildOfClass("Humanoid").__State = sb.Enum.HumanoidStateType.Dead
		no(isCharacterAlive(deadState), "dead state")

		local noPrimary = makeCharacter(sb)
		noPrimary.PrimaryPart = nil
		no(isCharacterAlive(noPrimary), "no primary part")
	end)

	it("does not mistake a non-Humanoid child called Humanoid for one", function()
		local sb = sandbox()
		local character = sb.new("Model", { Parent = sb.workspace })
		sb.new("Folder", { Name = "Humanoid", Parent = character })
		no(sb.require("Util.PlayerUtil").isCharacterAlive(character))
	end)
end)

describe("PlayerUtil.getMouseHit", function()
	it("excludes the character even when no VISUALS folder exists", function()
		local sb = sandbox()
		local character = makeCharacter(sb)
		sb.localPlayer.Character = character

		sb.require("Util.PlayerUtil").getMouseHit()

		local filter = sb.calls.raycast[1].params.FilterDescendantsInstances
		ok(table.find(filter, character), "character is in the filter")
		eq(#filter, 1)
	end)

	it("excludes both the VISUALS folder and the character when present", function()
		local sb = sandbox()
		local character = makeCharacter(sb)
		sb.localPlayer.Character = character
		local visuals = sb.new("Folder", { Name = "VISUALS", Parent = sb.workspace })

		sb.require("Util.PlayerUtil").getMouseHit()

		local filter = sb.calls.raycast[1].params.FilterDescendantsInstances
		ok(table.find(filter, character))
		ok(table.find(filter, visuals))
	end)

	it("works with no character or VISUALS folder", function()
		local sb = sandbox()
		sb.require("Util.PlayerUtil").getMouseHit()
		eq(#sb.calls.raycast[1].params.FilterDescendantsInstances, 0)
	end)

	it("returns a CFrame at the ray hit", function()
		local sb = sandbox()
		local position = sb.Vector3.new(0, 0, -100)
		sb.physics.raycast = function()
			return { Position = position }
		end
		local hit = sb.require("Util.PlayerUtil").getMouseHit()
		eq(typeof(hit), "CFrame")
		TestKit.near((hit.Position - position).Magnitude, 0, 1e-3)
	end)

	it("ignores hits closer than the minimum aim distance", function()
		local sb = sandbox()
		sb.physics.raycast = function()
			return { Position = sb.Vector3.new(0, 0, -5) }
		end
		local hit = sb.require("Util.PlayerUtil").getMouseHit()
		ok(hit.Position.Magnitude > 100)
	end)

	it("warns and returns identity on the server", function()
		local sb = sandbox({ isClient = false })
		local hit = sb.require("Util.PlayerUtil").getMouseHit()
		eq(hit, sb.CFrame.new())
		ok(sb.hasWarning("not valid on the server"))
	end)
end)

describe("PlayerUtil lookups", function()
	it("caches names and falls back to Player on failure", function()
		local sb = sandbox()
		local getName = sb.require("Util.PlayerUtil").getPlayerNameFromUserId
		eq(getName(1), "User1")
		eq(getName(1), "User1")
		eq(sb.apiCalls.getName, 1)

		sb.api.getName = function()
			error("HTTP 500")
		end
		eq(getName(2), "Player")
		ok(sb.hasWarning("HTTP 500"))
	end)

	it("does not cache a failed name lookup", function()
		local sb = sandbox()
		local getName = sb.require("Util.PlayerUtil").getPlayerNameFromUserId
		local working = sb.api.getName
		sb.api.getName = function()
			error("HTTP 500")
		end
		eq(getName(3), "Player")
		sb.api.getName = working
		eq(getName(3), "User3")
	end)

	it("caches thumbnails per type and size, defaulting both", function()
		local sb = sandbox()
		local getThumbnail = sb.require("Util.PlayerUtil").getPlayerThumbnailFromUserId
		local received
		sb.api.getThumbnail = function(userId, thumbnailType, thumbnailSize)
			received = { thumbnailType, thumbnailSize }
			return "rbxthumb://" .. userId
		end

		eq(getThumbnail(1), "rbxthumb://1")
		eq(received[1], sb.Enum.ThumbnailType.HeadShot)
		eq(received[2], sb.Enum.ThumbnailSize.Size420x420)

		getThumbnail(1)
		eq(sb.apiCalls.getThumbnail, 1)
		getThumbnail(1, sb.Enum.ThumbnailType.AvatarBust)
		eq(sb.apiCalls.getThumbnail, 2)
	end)

	it("returns an empty thumbnail on failure", function()
		local sb = sandbox()
		sb.api.getThumbnail = function()
			error("HTTP 500")
		end
		eq(sb.require("Util.PlayerUtil").getPlayerThumbnailFromUserId(1), "")
		ok(sb.hasWarning("HTTP 500"))
	end)

	it("detects the platform", function()
		local sb = sandbox()
		local getPlatform = sb.require("Util.PlayerUtil").getPlayerPlatform
		eq(getPlatform(), "Desktop")

		sb.touchEnabled, sb.mouseEnabled = true, false
		eq(getPlatform(), "Mobile")

		sb.tenFootInterface = true
		eq(getPlatform(), "Console")
	end)

	it("getPlayerPlatform refuses to run on the server", function()
		local sb = sandbox({ isClient = false })
		TestKit.throws(function()
			sb.require("Util.PlayerUtil").getPlayerPlatform()
		end, "only be called on the client")
	end)
end)
