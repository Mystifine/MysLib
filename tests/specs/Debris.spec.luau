local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok

describe("Debris", function()
	it("destroys an instance after its delay, then releases the heartbeat connection", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		local part = sb.new("Part", { Parent = sb.workspace })

		Debris.AddItem(part, 1)
		sb.advance(0.5)
		eq(part.Parent, sb.workspace)

		sb.advance(0.6)
		eq(part.Parent, nil)

		sb.step()
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)

	it("cleans tables using the Maid rules", function()
		local sb = sandbox()
		local cleaned = 0
		sb.require("Debris").AddItem({
			Destroy = function()
				cleaned += 1
			end,
		}, 0.1)
		sb.advance(0.2)
		eq(cleaned, 1)
	end)

	it("RemoveItem cancels a scheduled item", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		local part = sb.new("Part", { Parent = sb.workspace })
		Debris.AddItem(part, 1)
		Debris.RemoveItem(part)
		sb.advance(1.5)
		eq(part.Parent, sb.workspace)
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)

	it("rejects invalid input", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		TestKit.throws(function()
			Debris.AddItem("nope", 1)
		end, "invalid <object>")
		TestKit.throws(function()
			Debris.AddItem(sb.new("Part"), "soon")
		end, "invalid <destroyTime>")
		TestKit.throws(function()
			Debris.AddItem({}, 1)
		end, "not a valid cleanup task")
	end)

	it("runs a failing item once and still cleans the others", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		local failures, cleaned = 0, 0

		Debris.AddItem({
			Destroy = function()
				failures += 1
				error("boom")
			end,
		}, 0.1)
		for _ = 1, 3 do
			Debris.AddItem({
				Destroy = function()
					cleaned += 1
				end,
			}, 0.1)
		end
		Debris.AddItem({
			Destroy = function()
				cleaned += 1
			end,
		}, 0.5)

		sb.advance(1)

		eq(failures, 1)
		eq(cleaned, 4)
		eq(#sb.takeErrors(), 0)
		ok(sb.hasWarning("boom"))
	end)

	it("survives an item cancelling another item during cleanup", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		local log = {}

		local cancelled = {
			Destroy = function()
				table.insert(log, "cancelled")
			end,
		}
		local survivor = {
			Destroy = function()
				table.insert(log, "survivor")
			end,
		}

		-- Scheduled long enough out that only the canceller has expired on the first pass.
		Debris.AddItem(survivor, 5)
		Debris.AddItem(cancelled, 5)
		Debris.AddItem({
			Destroy = function()
				table.insert(log, "canceller")
				Debris.RemoveItem(cancelled)
			end,
		}, 0.1)

		sb.advance(0.2)
		eq(table.concat(log, ","), "canceller")
		eq(#sb.takeErrors(), 0)

		sb.advance(5)
		eq(table.concat(log, ","), "canceller,survivor")
	end)

	it("cleans the right items when cancellation shifts the list mid-walk", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		local log = {}

		local function item(name, onDestroy)
			return {
				Destroy = function()
					table.insert(log, name)
					if onDestroy then
						onDestroy()
					end
				end,
			}
		end

		local early = item("early")
		local late = item("late")
		Debris.AddItem(early, 5)
		Debris.AddItem(late, 5)
		Debris.AddItem(item("canceller", function()
			Debris.RemoveItem(early)
		end), 0.1)

		sb.advance(0.2)
		sb.advance(5)

		eq(table.concat(log, ","), "canceller,late")
		eq(#sb.takeErrors(), 0)
	end)

	it("lets a cleanup schedule new items", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		local secondCleaned = false
		Debris.AddItem({
			Destroy = function()
				Debris.AddItem({
					Destroy = function()
						secondCleaned = true
					end,
				}, 0.1)
			end,
		}, 0.1)
		sb.advance(0.5)
		eq(secondCleaned, true)
		eq(sb.runService.Heartbeat:_connectionCount(), 0)
	end)

	it("does not re-run an item whose cleanup yields across frames", function()
		local sb = sandbox()
		local Debris = sb.require("Debris")
		local runs = 0
		Debris.AddItem({
			Destroy = function()
				runs += 1
				sb.runService.Heartbeat:Wait()
				sb.runService.Heartbeat:Wait()
			end,
		}, 0.1)
		sb.advance(1)
		eq(runs, 1)
	end)
end)
