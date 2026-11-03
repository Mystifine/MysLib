local StringUtil = {}

StringUtil.RichText = require(script.RichText);

local SUFFIXES = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
  "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod",
  "Vg", "Uvg"
}

-- Abbreviates large numbers to a shorter format with suffixes (K, M, B, etc.).
-- Below 1000, the raw number is returned untouched. At 1000+, decimal
-- formatting kicks in once a suffix applies.
-- @param num: The number to abbreviate.
-- @param decimals: Number of decimal places to show once abbreviated (default 1).
-- @return: Abbreviated number string.
function StringUtil.abbrev(num : number, decimals : number?)
	local decimalPlaces : number = decimals or 1;

	if not num or num ~= num then return "0" end;

	local isNegative = num < 0;
	local sign = isNegative and "-" or "";
	num = math.abs(num);

	if num < 1000 then
		return sign .. tostring(num);
	end

	if num == math.huge then
		return sign .. "inf";
	end

	local numberFormat = string.format("%%.%df", decimalPlaces);
	-- True when the value would print as `limit` or more once rounded, e.g. 999.95 -> "1000.0".
	local function roundsUpTo(value : number, limit : number) : boolean
		return (tonumber(string.format(numberFormat, value)) :: number) >= limit;
	end

	local power = math.floor(math.log10(num));
	local suffixIndex = math.floor(power / 3);
	local displayNum = num / (10 ^ (suffixIndex * 3));

	-- Carry into the next suffix instead of showing "1000.0K".
	if roundsUpTo(displayNum, 1000) then
		suffixIndex += 1;
		displayNum /= 1000;
	end

	if suffixIndex > #SUFFIXES then
		local mantissa = num / (10 ^ power);
		if roundsUpTo(mantissa, 10) then
			power += 1;
			mantissa /= 10;
		end
		return string.format("%s" .. numberFormat .. "e%d", sign, mantissa, power);
	end

	return sign .. string.format(numberFormat .. "%s", displayNum, SUFFIXES[suffixIndex]);
end

-- Formats a number with comma separators for thousands.
-- @param number: The number to format.
-- @return: Formatted number with commas.
function StringUtil.addCommas(number : number)
	local formattedNumber = tostring(number)

	-- tostring switches to scientific notation for large numbers (1e+21), so write those out in full.
	local numericValue = tonumber(number)
	if numericValue and math.abs(numericValue) >= 1 and math.abs(numericValue) ~= math.huge and formattedNumber:find("e") then
		formattedNumber = string.format("%.0f", numericValue)
	end

	-- Split the number into sign, integer and decimal parts
	local sign, integerPart, decimalPart = formattedNumber:match("^([+-]?)(%d*)(.*)$")
	if not sign then
		return formattedNumber
	end

	-- Add commas to the integer part
	local reverseInteger = string.reverse(integerPart)
	local formattedInteger = string.gsub(reverseInteger, "(%d%d%d)", "%1,")
	formattedInteger = string.reverse(formattedInteger)
	formattedInteger = string.gsub(formattedInteger, "^,", "") -- Remove leading comma, if any

	-- Combine the sign, formatted integer and decimal parts
	local result = sign .. formattedInteger .. (decimalPart or "")

	return result
end

-- Converts seconds to a human-readable time format.
-- @param seconds: Number of seconds. Negative durations are prefixed with "-".
-- @return: Formatted time string (e.g., "1d 2h 30m 45s").
function StringUtil.formatTime(seconds : number)
	if seconds < 0 then
		return "-" .. StringUtil.formatTime(-seconds)
	end

	local days = math.floor(seconds / (24 * 60 * 60))
	local hours = math.floor((seconds % (24 * 60 * 60)) / (60 * 60))
	local minutes = math.floor((seconds % (60 * 60)) / 60)
	local secs = seconds % 60

	return string.format("%dd %dh %dm %ds", days, hours, minutes, secs)
end


return StringUtil
