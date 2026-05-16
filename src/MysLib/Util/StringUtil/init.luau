local StringUtil = {}

StringUtil.RichText = require(script.RichText);

function StringUtil.abbrev(num : number)
	if num < 1000 then
		return tostring(num)
	end

	local suffixes = { "K", "M", "B", "T" }
	local index = 0

	while num >= 1000 and index < #suffixes do
		num /= 1000
		index += 1
	end

	-- Keep one decimal if needed
	if num < 10 then
		return string.format("%.1f%s", num, suffixes[index])
	else
		return string.format("%.0f%s", num, suffixes[index])
	end
end

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

function StringUtil.formatTime(seconds : number)
	local days = math.floor(seconds / (24 * 60 * 60))
	local hours = math.floor((seconds % (24 * 60 * 60)) / (60 * 60))
	local minutes = math.floor((seconds % (60 * 60)) / 60)
	local secs = seconds % 60

	return string.format("%dd %dh %dm %ds", days, hours, minutes, secs)
end


return StringUtil
