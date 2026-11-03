local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, no = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.no

describe("StringUtil.abbrev", function()
	it("leaves numbers below 1000 untouched", function()
		local abbrev = sandbox().require("Util.StringUtil").abbrev
		eq(abbrev(0), "0")
		eq(abbrev(999), "999")
		eq(abbrev(12.5), "12.5")
		eq(abbrev(-999), "-999")
	end)

	it("abbreviates with suffixes", function()
		local abbrev = sandbox().require("Util.StringUtil").abbrev
		eq(abbrev(1000), "1.0K")
		eq(abbrev(1500), "1.5K")
		eq(abbrev(1234567), "1.2M")
		eq(abbrev(1e9), "1.0B")
		eq(abbrev(-1500), "-1.5K")
		eq(abbrev(1e66), "1.0Uvg")
	end)

	it("honours the decimals argument", function()
		local abbrev = sandbox().require("Util.StringUtil").abbrev
		eq(abbrev(1234, 2), "1.23K")
		eq(abbrev(1234, 0), "1K")
	end)

	it("carries into the next suffix when rounding reaches 1000", function()
		local abbrev = sandbox().require("Util.StringUtil").abbrev
		eq(abbrev(999949), "999.9K")
		eq(abbrev(999950), "1.0M")
		eq(abbrev(999999), "1.0M")
		eq(abbrev(-999999), "-1.0M")
		eq(abbrev(999999999), "1.0B")
		eq(abbrev(999500, 0), "1M")
	end)

	it("uses scientific notation past the last suffix", function()
		local abbrev = sandbox().require("Util.StringUtil").abbrev
		eq(abbrev(1e69), "1.0e69")
		eq(abbrev(-2.5e70), "-2.5e70")
		eq(abbrev(9.99e69), "1.0e70")
		eq(abbrev(9.9996e68), "1.0e69")
	end)

	it("handles nil, NaN and infinity", function()
		local abbrev = sandbox().require("Util.StringUtil").abbrev
		eq(abbrev(nil), "0")
		eq(abbrev(0 / 0), "0")
		eq(abbrev(math.huge), "inf")
		eq(abbrev(-math.huge), "-inf")
	end)
end)

describe("StringUtil.addCommas", function()
	it("groups thousands", function()
		local addCommas = sandbox().require("Util.StringUtil").addCommas
		eq(addCommas(0), "0")
		eq(addCommas(999), "999")
		eq(addCommas(1000), "1,000")
		eq(addCommas(50000), "50,000")
		eq(addCommas(100000), "100,000")
		eq(addCommas(1000000), "1,000,000")
		eq(addCommas(1234.5), "1,234.5")
	end)

	it("handles negatives without a stray comma", function()
		local addCommas = sandbox().require("Util.StringUtil").addCommas
		eq(addCommas(-1), "-1")
		eq(addCommas(-100), "-100")
		eq(addCommas(-1000), "-1,000")
		eq(addCommas(-100000), "-100,000")
		eq(addCommas(-1234567.25), "-1,234,567.25")
	end)

	it("groups values tostring renders in scientific notation", function()
		local addCommas = sandbox().require("Util.StringUtil").addCommas
		eq(addCommas(1e21), "1,000,000,000,000,000,000,000")
		eq(addCommas(-1e21), "-1,000,000,000,000,000,000,000")
		eq(addCommas(0.00001), tostring(0.00001))
	end)

	it("leaves infinity and NaN readable", function()
		local addCommas = sandbox().require("Util.StringUtil").addCommas
		eq(addCommas(math.huge), "inf")
		eq(addCommas(-math.huge), "-inf")
	end)

	it("still accepts numeric strings", function()
		local addCommas = sandbox().require("Util.StringUtil").addCommas
		eq(addCommas("1000000"), "1,000,000")
	end)
end)

describe("StringUtil.formatTime", function()
	it("formats days, hours, minutes and seconds", function()
		local formatTime = sandbox().require("Util.StringUtil").formatTime
		eq(formatTime(0), "0d 0h 0m 0s")
		eq(formatTime(3665), "0d 1h 1m 5s")
		eq(formatTime(120), "0d 0h 2m 0s")
		eq(formatTime(86400), "1d 0h 0m 0s")
		eq(formatTime(90.9), "0d 0h 1m 30s")
	end)

	it("keeps negative durations readable", function()
		local formatTime = sandbox().require("Util.StringUtil").formatTime
		eq(formatTime(-5), "-0d 0h 0m 5s")
		eq(formatTime(-3665), "-0d 1h 1m 5s")
	end)
end)

describe("StringUtil.RichText", function()
	it("wraps text in the expected tags", function()
		local RichText = sandbox().require("Util.StringUtil").RichText
		eq(RichText.bold("x"), "<b>x</b>")
		eq(RichText.italic("x"), "<i>x</i>")
		eq(RichText.underline("x"), "<u>x</u>")
		eq(RichText.strikethrough("x"), "<s>x</s>")
		eq(RichText.size("x", 14), '<font size="14">x</font>')
		ok(string.find(RichText.transparency("x", 0.5), 'transparency="0.5', 1, true))
	end)

	it("nests", function()
		local RichText = sandbox().require("Util.StringUtil").RichText
		eq(RichText.bold(RichText.italic("x")), "<b><i>x</i></b>")
	end)

	it("emits exact RGB values for every channel value", function()
		local sb = sandbox()
		local RichText = sb.require("Util.StringUtil").RichText
		for value = 0, 255 do
			local expected = string.format('<font color="rgb(%d,0,0)">x</font>', value)
			eq(RichText.color("x", sb.Color3.fromRGB(value, 0, 0)), expected)
		end
		local stroked = RichText.stroke("x", sb.Color3.fromRGB(128, 64, 200), 2, 0)
		ok(string.find(stroked, 'color="rgb(128,64,200)"', 1, true), stroked)
	end)

	it("escape neutralises markup in untrusted text", function()
		local RichText = sandbox().require("Util.StringUtil").RichText
		eq(RichText.escape([[<b>"Tom" & 'Jerry'</b>]]), "&lt;b&gt;&quot;Tom&quot; &amp; &apos;Jerry&apos;&lt;/b&gt;")
		eq(RichText.escape("plain"), "plain")
		eq(RichText.escape("&amp;"), "&amp;amp;")
		no(string.find(RichText.bold(RichText.escape("<font>")), "<font>", 1, true))
	end)
end)
