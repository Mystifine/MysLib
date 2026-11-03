--[[
	The version lives in several files; this keeps them from drifting apart.
]]

local fs = require("@lune/fs")

local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok

-- Read here rather than inside it(), because fs calls cannot run inside a spec.
local srcDir = TestKit.srcDir
local wallyToml = fs.readFile(srcDir .. "/wally.toml")
local docsIndex = fs.readFile(srcDir .. "/../docs/index.md")
local gettingStarted = fs.readFile(srcDir .. "/../docs/getting-started.md")

describe("version", function()
	it("matches across wally.toml, MysLib.Version and the docs", function()
		local wallyVersion = string.match(wallyToml, 'version%s*=%s*"([^"]+)"')
		ok(wallyVersion, "wally.toml has a version")

		eq(sandbox().require().Version, wallyVersion, "MysLib.Version")
		eq(string.match(docsIndex, "%*%*Version:%*%* (%S+)"), wallyVersion, "docs/index.md")
		eq(string.match(gettingStarted, "mystifine/myslib@([%d%.]+)"), wallyVersion, "docs/getting-started.md")
	end)
end)
