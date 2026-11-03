local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, no, near = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.no, TestKit.near

describe("MathUtil", function()
	it("truncate drops decimals from positive numbers", function()
		local MathUtil = sandbox().require("Util.MathUtil")
		eq(MathUtil.truncate(3.14159, 2), 3.14)
		eq(MathUtil.truncate(2.99999, 1), 2.9)
		eq(MathUtil.truncate(5.9, 0), 5)
		eq(MathUtil.truncate(5.9, -1), 5)
	end)

	it("truncate is not thrown off by floating point error", function()
		local MathUtil = sandbox().require("Util.MathUtil")
		eq(MathUtil.truncate(0.29, 2), 0.29)
		eq(MathUtil.truncate(1.1, 1), 1.1)
		eq(MathUtil.truncate(-0.29, 2), -0.29)
		eq(MathUtil.truncate(4.35, 2), 4.35)
	end)

	it("truncate rounds negatives toward zero", function()
		local MathUtil = sandbox().require("Util.MathUtil")
		eq(MathUtil.truncate(-3.14159, 2), -3.14)
		eq(MathUtil.truncate(-2.99999, 1), -2.9)
		eq(tostring(MathUtil.truncate(-0.05, 1)), "0")
	end)

	it("randomNumber stays in range and rng is the same function", function()
		local MathUtil = sandbox().require("Util.MathUtil")
		for _ = 1, 200 do
			local value = MathUtil.randomNumber(2, 5)
			ok(value >= 2 and value <= 5)
		end
		eq(MathUtil.rng, MathUtil.randomNumber)
	end)

	it("lerp and the bezier helpers interpolate numbers", function()
		local MathUtil = sandbox().require("Util.MathUtil")
		eq(MathUtil.lerp(0, 100, 0.5), 50)
		eq(MathUtil.lerp(10, 20, 0.25), 12.5)
		near(MathUtil.quadBezier(0.5, 0, 50, 100), 50)
		near(MathUtil.cubicBezier(0.5, 0, 25, 75, 100), 50)
		eq(MathUtil.cubicBezier(0, 1, 2, 3, 4), 1)
		eq(MathUtil.cubicBezier(1, 1, 2, 3, 4), 4)
	end)

	it("lerp and the bezier helpers also interpolate Vector3s", function()
		local sb = sandbox()
		local MathUtil = sb.require("Util.MathUtil")
		local a, b = sb.Vector3.new(0, 0, 0), sb.Vector3.new(10, 0, 0)
		eq(MathUtil.lerp(a, b, 0.5), sb.Vector3.new(5, 0, 0))
		eq(MathUtil.quadBezier(1, a, a, b), b)
		eq(MathUtil.cubicBezier(1, a, a, a, b), b)
	end)
end)

describe("TableUtil.deepCopy", function()
	it("copies nested tables and passes other values through", function()
		local deepCopy = sandbox().require("Util.TableUtil").deepCopy
		local source = { a = 1, nested = { b = 2, deeper = { c = 3 } }, list = { 1, 2 } }
		local copy = deepCopy(source)

		ok(copy ~= source)
		ok(copy.nested ~= source.nested)
		eq(copy.nested.deeper.c, 3)
		eq(copy.list[2], 2)
		copy.nested.b = 99
		eq(source.nested.b, 2)

		eq(deepCopy(5), 5)
		eq(deepCopy(nil), nil)
	end)

	it("copies tables that reference themselves", function()
		local deepCopy = sandbox().require("Util.TableUtil").deepCopy
		local source = { name = "root", child = {} }
		source.self = source
		source.child.parent = source

		local copy = deepCopy(source)
		ok(copy ~= source)
		eq(copy.self, copy)
		eq(copy.child.parent, copy)
		eq(copy.name, "root")
	end)

	it("still gives each reference to a shared table its own copy", function()
		local deepCopy = sandbox().require("Util.TableUtil").deepCopy
		local shared = { hp = 1 }
		local copy = deepCopy({ a = shared, b = shared })

		ok(copy.a ~= copy.b)
		copy.a.hp = 5
		eq(copy.b.hp, 1)
	end)

	it("ignores extra arguments, so it works as a mapper callback", function()
		local deepCopy = sandbox().require("Util.TableUtil").deepCopy
		local copy = deepCopy({ a = {} }, 1)
		ok(copy.a)
		no(getmetatable(copy))
	end)

	it("keeps Instances by reference and does not carry metatables over", function()
		local sb = sandbox()
		local deepCopy = sb.require("Util.TableUtil").deepCopy
		local part = sb.new("Part")
		local copy = deepCopy(setmetatable({ part = part }, { __index = {} }))
		eq(copy.part, part)
		eq(getmetatable(copy), nil)
	end)
end)
