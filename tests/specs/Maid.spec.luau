local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, no = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.no

describe("Maid", function()
	it("cleans every supported task type in the order given", function()
		local sb = sandbox()
		local maid = sb.require("Maid").new()
		local order = {}

		local part = sb.new("Part", { Parent = sb.workspace })
		local connection = sb.runService.Heartbeat:Connect(function() end)

		maid:GiveTask(function()
			table.insert(order, "function")
		end)
		maid:GiveTask(connection)
		maid:GiveTask(part)
		maid:AddTask({
			Destroy = function()
				table.insert(order, "destroy")
			end,
		})
		maid:GiveTask({
			Disconnect = function()
				table.insert(order, "disconnect")
			end,
		})

		maid:Destroy()

		eq(table.concat(order, ","), "function,destroy,disconnect")
		eq(connection.Connected, false)
		eq(part.Parent, nil)
	end)

	it("prefers Disconnect over Destroy on objects with both", function()
		local maid = sandbox().require("Maid").new()
		local called
		maid:GiveTask({
			Disconnect = function()
				called = "disconnect"
			end,
			Destroy = function()
				called = "destroy"
			end,
		})
		maid:DoCleaning()
		eq(called, "disconnect")
	end)

	it("keeps cleaning after a task throws, and warns about it", function()
		local sb = sandbox()
		local maid = sb.require("Maid").new()
		local cleaned = 0

		maid:GiveTask(function()
			cleaned += 1
		end)
		maid:GiveTask(function()
			error("cleanup exploded")
		end)
		maid:GiveTask(function()
			cleaned += 1
		end)

		maid:Destroy()

		eq(cleaned, 2)
		ok(sb.hasWarning("cleanup exploded"))
	end)

	it("does not run tasks a second time after one of them threw", function()
		local maid = sandbox().require("Maid").new()
		local cleaned = 0
		maid:GiveTask(function()
			cleaned += 1
		end)
		maid:GiveTask(function()
			error("boom")
		end)

		pcall(maid.Destroy, maid)
		pcall(maid.Destroy, maid)

		eq(cleaned, 1)
	end)

	it("runs each task once when a task re-enters Destroy", function()
		local maid = sandbox().require("Maid").new()
		local cleaned = 0
		maid:GiveTask(function()
			cleaned += 1
			maid:Destroy()
		end)
		maid:GiveTask(function()
			cleaned += 1
		end)

		maid:Destroy()

		eq(cleaned, 2)
	end)

	it("cleans tasks added while cleaning", function()
		local maid = sandbox().require("Maid").new()
		local lateCleaned = false
		maid:GiveTask(function()
			maid:GiveTask(function()
				lateCleaned = true
			end)
		end)

		maid:Destroy()

		eq(lateCleaned, true)
	end)

	it("is reusable after cleaning", function()
		local maid = sandbox().require("Maid").new()
		local cleaned = 0
		maid:GiveTask(function()
			cleaned += 1
		end)
		maid:Destroy()
		maid:GiveTask(function()
			cleaned += 1
		end)
		maid:Destroy()
		eq(cleaned, 2)
	end)

	it("cleans the previous task when a key is reused", function()
		local maid = sandbox().require("Maid").new()
		local log = {}
		maid:GiveTask(function()
			table.insert(log, "old")
		end, "slot")
		maid:GiveTask(function()
			table.insert(log, "new")
		end, "slot")
		eq(table.concat(log, ","), "old")

		maid:Destroy()
		eq(table.concat(log, ","), "old,new")
	end)

	it("does not destroy a task given again under its own key", function()
		local maid = sandbox().require("Maid").new()
		local cleaned = 0
		local function cleanup()
			cleaned += 1
		end
		maid:GiveTask(cleanup, "slot")
		maid:GiveTask(cleanup, "slot")
		eq(cleaned, 0)

		maid:Destroy()
		eq(cleaned, 1)
	end)

	it("RemoveTask cleans the task and forgets it", function()
		local maid = sandbox().require("Maid").new()
		local cleaned = 0
		maid:GiveTask(function()
			cleaned += 1
		end, "slot")

		maid:RemoveTask("slot")
		eq(cleaned, 1)
		maid:RemoveTask("slot")
		maid:RemoveTask("missing")
		maid:Destroy()
		eq(cleaned, 1)
	end)

	it("still registers the new keyed task when cleaning the old one throws", function()
		local maid = sandbox().require("Maid").new()
		local newCleaned = false
		maid:GiveTask(function()
			error("boom")
		end, "slot")

		pcall(function()
			maid:GiveTask(function()
				newCleaned = true
			end, "slot")
		end)
		maid:Destroy()

		eq(newCleaned, true)
	end)

	it("rejects invalid tasks", function()
		local Maid = sandbox().require("Maid")
		local maid = Maid.new()
		TestKit.throws(function()
			maid:GiveTask(5)
		end, "Invalid task")
		TestKit.throws(function()
			maid:GiveTask(nil)
		end, "Invalid task")
		TestKit.throws(function()
			maid:GiveTask({})
		end, "Invalid task")
		no(Maid.isValidTask("text"))
		ok(Maid.isValidTask(function() end))
	end)
end)
