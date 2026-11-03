--[[
	Minimal spec runner: describe/it plus the handful of assertions the specs need.
]]

local Engine = require("./Engine")

local TestKit = {
	srcDir = "src",
}

local path = {}
local passed = 0
local failures = {}
local activeSandboxes = {}

function TestKit.describe(name, body)
	table.insert(path, name)
	body()
	table.remove(path)
end

function TestKit.it(name, body)
	local fullName = table.concat(path, " > ") .. " > " .. name
	activeSandboxes = {}

	local thread = coroutine.create(body)
	local success, err = coroutine.resume(thread)

	local failure = nil
	if not success then
		failure = debug.traceback(thread, tostring(err))
	elseif coroutine.status(thread) ~= "dead" then
		failure = "spec yielded without finishing"
	else
		-- Errors in spawned threads never reach the spec, so they are checked explicitly.
		for _, sandbox in activeSandboxes do
			if #sandbox.errors > 0 then
				failure = "uncaught error in spawned thread:\n" .. sandbox.errors[1]
				break
			end
		end
	end

	if failure then
		table.insert(failures, { name = fullName, reason = failure })
	else
		passed += 1
	end
end

local sourceTree = nil

-- Must run outside a spec, because reading files yields to Lune's scheduler.
function TestKit.preload(srcDir)
	TestKit.srcDir = srcDir
	sourceTree = Engine.snapshot(srcDir)
end

function TestKit.sandbox(options)
	options = options or {}
	options.srcDir = TestKit.srcDir
	options.tree = sourceTree
	local sandbox = Engine.new(options)
	table.insert(activeSandboxes, sandbox)
	return sandbox
end

function TestKit.eq(actual, expected, label)
	if actual ~= expected then
		error(string.format("%sexpected %s, got %s", label and (label .. ": ") or "", tostring(expected), tostring(actual)), 2)
	end
end

function TestKit.near(actual, expected, tolerance, label)
	if math.abs(actual - expected) > (tolerance or 1e-6) then
		error(string.format("%sexpected ~%s, got %s", label and (label .. ": ") or "", tostring(expected), tostring(actual)), 2)
	end
end

function TestKit.ok(value, label)
	if not value then
		error(string.format("expected truthy value%s", label and (": " .. label) or ""), 2)
	end
end

function TestKit.no(value, label)
	if value then
		error(string.format("expected falsy value%s, got %s", label and (" for " .. label) or "", tostring(value)), 2)
	end
end

function TestKit.throws(callback, pattern)
	local success, err = pcall(callback)
	if success then
		error("expected an error to be thrown", 2)
	end
	if pattern and not string.find(tostring(err), pattern, 1, true) then
		error(string.format("expected error containing '%s', got: %s", pattern, tostring(err)), 2)
	end
end

function TestKit.report()
	for _, failure in failures do
		print(string.format("\n[FAIL] %s\n  %s", failure.name, (string.gsub(failure.reason, "\n", "\n  "))))
	end
	print(string.format("\n%d passed, %d failed", passed, #failures))
	return #failures == 0
end

function TestKit.failedNames()
	local names = {}
	for _, failure in failures do
		table.insert(names, failure.name)
	end
	return names
end

return TestKit
