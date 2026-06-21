local StringUtil = {}

StringUtil.RichText = require(script.RichText);

local SUFFIXES = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
  "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod",
  "Vg", "Uvg"
}

-- Abbreviates large numbers to a shorter format with suffixes (K, M, B, etc.).
-- @param num: The number to abbreviate.
-- @return: Abbreviated number string.
function StringUtil.abbrev(num : number)
	if not num or num ~= num then return "0" end;

	local isNegative = num < 0;
	num = math.abs(num);

	if num < 1000 then
		return (isNegative and "-" or "") .. tostring(num)
	end

	local power = math.floor(math.log10(num));
	local suffixIndex = math.floor(power / 3);

	if suffixIndex > #SUFFIXES then
		local mantissa = num / (10 ^ power);
		return string.format("%s%.2fe%d",isNegative and "-" or "", mantissa, power);
	end

	local displayNum = num / (10 ^ (suffixIndex * 3));
	local formatString;
	if displayNum < 10 then
		formatString = "%.1f%s"
	else
		formatString = "%.0f%s"
	end

	return (isNegative and "-" or "") .. string.format(formatString, displayNum, SUFFIXES[suffixIndex])
end

-- Formats a number with comma separators for thousands.
-- @param number: The number to format.
-- @return: Formatted number with commas.
function StringUtil.addCommas(number : number)
	local formattedNumber = tostring(number)

	-- Split the number into integer and decimal parts
	local integerPart, decimalPart = formattedNumber:match("([^%.]*)(%.?.*)")

	-- Add commas to the integer part
	local reverseInteger = string.reverse(integerPart)
	local formattedInteger = string.gsub(reverseInteger, "(%d%d%d)", "%1,")
	formattedInteger = string.reverse(formattedInteger)
	formattedInteger = string.gsub(formattedInteger, "^,", "") -- Remove leading comma, if any

	-- Combine the formatted integer and decimal parts
	local result = formattedInteger .. (decimalPart or "")

	return result
end

-- Converts seconds to a human-readable time format.
-- @param seconds: Number of seconds.
-- @return: Formatted time string (e.g., "1d 2h 30m 45s").
function StringUtil.formatTime(seconds : number)
	local days = math.floor(seconds / (24 * 60 * 60))
	local hours = math.floor((seconds % (24 * 60 * 60)) / (60 * 60))
	local minutes = math.floor((seconds % (60 * 60)) / 60)
	local secs = seconds % 60

	return string.format("%dd %dh %dm %ds", days, hours, minutes, secs)
end


return StringUtil
