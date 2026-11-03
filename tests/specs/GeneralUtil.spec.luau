local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, near = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.near

for _, case in { { "Heartbeat", "Heartbeat" }, { "Stepped", "Stepped" } } do
	local moduleName, eventName = case[1], case[2]

	describe("GeneralUtil." .. moduleName, function()
		it("calls back every frame with the elapsed time", function()
			local sb = sandbox()
			local elapsed = {}
			local connection = sb.require("Util.GeneralUtil." .. moduleName).new(function(dt)
				table.insert(elapsed, dt)
			end)
			sb.step(0.1)
			sb.step(0.2)
			eq(#elapsed, 2)
			near(elapsed[1], 0.1, 1e-6)
			near(elapsed[2], 0.2, 1e-6)
			connection:Disconnect()
		end)

		it("honours the cooldown and fires on the first frame", function()
			local sb = sandbox()
			local calls = 0
			local connection = sb.require("Util.GeneralUtil." .. moduleName).new(function()
				calls += 1
			end, 0.5)
			sb.step(0.1)
			eq(calls, 1)
			sb.step(0.1)
			eq(calls, 1)
			sb.step(0.5)
			eq(calls, 2)
			connection:Destroy()
		end)

		it("releases the engine connection after the last disconnect", function()
			local sb = sandbox()
			local connection = sb.require("Util.GeneralUtil." .. moduleName).new(function() end)
			eq(sb.runService[eventName]:_connectionCount(), 1)
			connection:Disconnect()
			connection:Disconnect()
			sb.step()
			eq(sb.runService[eventName]:_connectionCount(), 0)
		end)

		it("isolates errors and includes a traceback in the warning", function()
			local sb = sandbox()
			local Module = sb.require("Util.GeneralUtil." .. moduleName)
			local calls = 0
			local bad = Module.new(function()
				error("callback exploded")
			end)
			local good = Module.new(function()
				calls += 1
			end)
			sb.step()
			eq(calls, 1)
			-- debug.traceback appends the stack on the lines after the message.
			ok(sb.hasWarning("callback exploded\n"), "traceback in warning")
			bad:Disconnect()
			good:Disconnect()
		end)

		it("does not call a connection disconnected earlier in the same frame", function()
			local sb = sandbox()
			local Module = sb.require("Util.GeneralUtil." .. moduleName)
			local fired = 0
			local a, b
			a = Module.new(function()
				fired += 1
				b:Disconnect()
			end)
			b = Module.new(function()
				fired += 1
				a:Disconnect()
			end)
			sb.step()
			eq(fired, 1)
		end)

		it("is not thrown off by server clock corrections", function()
			local sb = sandbox()
			local calls = 0
			local connection = sb.require("Util.GeneralUtil." .. moduleName).new(function()
				calls += 1
			end)
			sb.step()
			eq(calls, 1)
			sb.serverTimeOffset = -100
			sb.step()
			sb.step()
			eq(calls, 3)
			connection:Disconnect()
		end)
	end)
end

describe("GeneralUtil.yieldWhileCondition", function()
	local function run(sb, argument)
		local outcome = { finished = false }
		local yieldWhileCondition = sb.require("Util.GeneralUtil.yieldWhileCondition")
		sb.spawn(function()
			outcome.value = yieldWhileCondition(argument)
			outcome.finished = true
		end)
		return outcome
	end

	it("returns true and calls onSuccess when the condition holds for the duration", function()
		local sb = sandbox()
		local succeeded, failed, ticks = false, false, 0
		local outcome = run(sb, {
			duration = 0.5,
			condition = function()
				return true
			end,
			onTick = function()
				ticks += 1
			end,
			onSuccess = function()
				succeeded = true
			end,
			onFail = function()
				failed = true
			end,
		})
		sb.advance(0.6)
		eq(outcome.value, true)
		eq(succeeded, true)
		eq(failed, false)
		ok(ticks > 1)
	end)

	it("returns false and calls onFail when the condition breaks early", function()
		local sb = sandbox()
		local holding = true
		local failed = false
		local outcome = run(sb, {
			duration = 5,
			condition = function()
				return holding
			end,
			onFail = function()
				failed = true
			end,
		})
		sb.step()
		holding = false
		sb.step()
		eq(outcome.finished, true)
		eq(outcome.value, false)
		eq(failed, true)
	end)

	it("accepts a bare condition function and waits until it turns false", function()
		local sb = sandbox()
		local holding = true
		local outcome = run(sb, function()
			return holding
		end)
		sb.advance(10)
		eq(outcome.finished, false)
		holding = false
		sb.step()
		eq(outcome.finished, true)
	end)
end)

describe("GeneralUtil.warn", function()
	it("formats the identifier and context", function()
		local sb = sandbox()
		sb.require("Util.GeneralUtil.warn")("MyModule", "went wrong")
		ok(sb.hasWarning("MyModule => went wrong"))
	end)
end)
