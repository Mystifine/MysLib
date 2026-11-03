local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok

describe("Bootstrapper.loadModule", function()
	it("runs main with the extra arguments", function()
		local sb = sandbox()
		local received
		local module = sb.moduleScript("Good", function()
			return {
				main = function(...)
					received = table.pack(...)
				end,
			}
		end)
		sb.require("Bootstrapper").loadModule(module, "a", 2)
		eq(received.n, 2)
		eq(received[1], "a")
		eq(received[2], 2)
	end)

	it("still accepts the older loadModule(name, module, ...) call", function()
		local sb = sandbox()
		local received
		local module = sb.moduleScript("Legacy", function()
			return {
				main = function(...)
					received = table.pack(...)
				end,
			}
		end)
		sb.require("Bootstrapper").loadModule("GameServer", module, "arg")
		eq(received.n, 1)
		eq(received[1], "arg")
	end)

	it("warns when require fails", function()
		local sb = sandbox()
		local module = sb.moduleScript("Broken", function()
			error("failed at load")
		end)
		sb.require("Bootstrapper").loadModule(module)
		ok(sb.hasWarning("Failed to REQUIRE"))
		ok(sb.hasWarning("failed at load"))
	end)

	it("warns when main is missing", function()
		local sb = sandbox()
		local module = sb.moduleScript("NoMain", function()
			return {}
		end)
		sb.require("Bootstrapper").loadModule(module)
		ok(sb.hasWarning("no main()"))
	end)

	it("warns instead of throwing when a module returns something other than a table", function()
		local sb = sandbox()
		local Bootstrapper = sb.require("Bootstrapper")
		for name, value in { Func = function() end, Num = 5, Bool = true, Str = "text" } do
			local module = sb.moduleScript(name, function()
				return value
			end)
			Bootstrapper.loadModule(module)
			ok(sb.hasWarning(name .. "' has no main()"), name)
		end
	end)

	it("warns when main throws, and carries on", function()
		local sb = sandbox()
		local module = sb.moduleScript("Crashes", function()
			return {
				main = function()
					error("main exploded")
				end,
			}
		end)
		sb.require("Bootstrapper").loadModule(module)
		ok(sb.hasWarning("Failed to run MAIN()"))
		ok(sb.hasWarning("main exploded"))
	end)

	it("keeps the original error when something non-string is thrown", function()
		local sb = sandbox()
		local Bootstrapper = sb.require("Bootstrapper")
		local module = sb.moduleScript("TableError", function()
			return {
				main = function()
					error(setmetatable({}, {
						__tostring = function()
							return "custom error object"
						end,
					}))
				end,
			}
		end)
		Bootstrapper.loadModule(module)
		ok(sb.hasWarning("custom error object"))
		ok(string.find(Bootstrapper.errorHandler("plain"), "plain", 1, true))
	end)
end)
