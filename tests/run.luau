--[[
	Runs every spec against the real source files in a simulated engine.

	Usage: lune run tests/run.luau [srcDir]
	srcDir defaults to "src"; pass another checkout's src to test it with the same specs.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local TestKit = require("./harness/TestKit")

TestKit.preload(process.args[1] or "src")

local specNames = {}
for _, entry in fs.readDir("tests/specs") do
	if string.sub(entry, -10) == ".spec.luau" then
		table.insert(specNames, string.sub(entry, 1, -6))
	end
end
table.sort(specNames)

for _, specName in specNames do
	require("./specs/" .. specName)
end

process.exit(if TestKit.report() then 0 else 1)
