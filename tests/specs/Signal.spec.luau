local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, no = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.no

describe("Signal", function()
	it("passes every argument to connected callbacks", function()
		local signal = sandbox().require("Signal").new()
		local received
		signal:Connect(function(...)
			received = table.pack(...)
		end)
		signal:Fire(1, nil, "three")
		eq(received.n, 3)
		eq(received[1], 1)
		eq(received[3], "three")
	end)

	it("Once fires a single time", function()
		local signal = sandbox().require("Signal").new()
		local count = 0
		signal:Once(function()
			count += 1
		end)
		signal:Fire()
		signal:Fire()
		eq(count, 1)
	end)

	it("Wait resumes with the exact values passed to Fire", function()
		local sb = sandbox()
		local signal = sb.require("Signal").new()
		local payload = setmetatable({ value = 1 }, { __index = { inherited = true } })
		local callback = function() end

		local received
		sb.spawn(function()
			received = table.pack(signal:Wait())
		end)
		signal:Fire(payload, callback, nil, 4)

		eq(received.n, 4)
		eq(received[1], payload, "table identity")
		eq(received[1].inherited, true, "metatable")
		eq(received[2], callback, "function argument")
		eq(received[4], 4)
	end)

	it("Wait leaves no Instances behind while waiting", function()
		local sb = sandbox()
		local signal = sb.require("Signal").new()
		sb.spawn(function()
			signal:Wait()
		end)
		eq(#sb.libraryRoot.Signal:GetChildren(), 0)
	end)

	it("Wait does not throw when the waiting thread was cancelled", function()
		local sb = sandbox()
		local signal = sb.require("Signal").new()
		local thread = sb.spawn(function()
			signal:Wait()
		end)
		coroutine.close(thread)
		signal:Fire()
		eq(#sb.takeErrors(), 0)
	end)

	it("skips a callback that an earlier callback disconnected during the same Fire", function()
		local signal = sandbox().require("Signal").new()
		local fired = 0
		local first, second
		first = signal:Connect(function()
			fired += 1
			second:Disconnect()
		end)
		second = signal:Connect(function()
			fired += 1
			first:Disconnect()
		end)
		signal:Fire()
		eq(fired, 1)
	end)

	it("does not call a callback connected during Fire until the next Fire", function()
		local signal = sandbox().require("Signal").new()
		local lateCalls = 0
		local connected = false
		signal:Connect(function()
			if not connected then
				connected = true
				signal:Connect(function()
					lateCalls += 1
				end)
			end
		end)
		signal:Fire()
		eq(lateCalls, 0)
		signal:Fire()
		eq(lateCalls, 1)
	end)

	it("isolates an erroring callback from the others", function()
		local sb = sandbox()
		local signal = sb.require("Signal").new()
		local fired = 0
		signal:Connect(function()
			error("boom")
		end)
		signal:Connect(function()
			fired += 1
		end)
		signal:Fire()
		eq(fired, 1)
		eq(#sb.takeErrors(), 1)
	end)

	it("exposes Connected like RBXScriptConnection, and Disconnect is repeatable", function()
		local signal = sandbox().require("Signal").new()
		local connection = signal:Connect(function() end)
		eq(connection.Connected, true)
		connection:Disconnect()
		eq(connection.Connected, false)
		connection:Disconnect()

		local once = signal:Once(function() end)
		eq(once.Connected, true)
		signal:Fire()
		eq(once.Connected, false)
	end)

	it("DisconnectAll drops every connection and leaves the signal usable", function()
		local signal = sandbox().require("Signal").new()
		local count = 0
		local connection = signal:Connect(function()
			count += 1
		end)
		signal:DisconnectAll()
		eq(connection.Connected, false)
		signal:Fire()
		eq(count, 0)

		signal:Connect(function()
			count += 1
		end)
		signal:Fire()
		eq(count, 1)
	end)

	it("can be handed to a Maid", function()
		local sb = sandbox()
		local signal = sb.require("Signal").new()
		local count = 0
		signal:Connect(function()
			count += 1
		end)

		local maid = sb.require("Maid").new()
		maid:GiveTask(signal)
		maid:Destroy()
		signal:Fire()
		eq(count, 0)
	end)

	it("rejects non-function callbacks", function()
		local signal = sandbox().require("Signal").new()
		TestKit.throws(function()
			signal:Connect("nope")
		end, "Callback must be a function")
		TestKit.throws(function()
			signal:Once(nil)
		end, "Callback must be a function")
	end)

	it("keeps connections independent across signals", function()
		local Signal = sandbox().require("Signal")
		local a, b = Signal.new(), Signal.new()
		local aCalls, bCalls = 0, 0
		a:Connect(function()
			aCalls += 1
		end)
		b:Connect(function()
			bCalls += 1
		end)
		a:Fire()
		eq(aCalls, 1)
		eq(bCalls, 0)
		ok(a ~= b)
		no(rawequal(a._connections, b._connections))
	end)
end)
