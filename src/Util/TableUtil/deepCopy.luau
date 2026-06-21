-- Recursively copies a table and all nested tables.
-- @param tbl: Table to copy.
-- @return: Deep copy of the table.
local function deepCopy(tbl : {}?)

	if typeof(tbl) ~= "table" then
		return tbl
	else
		local copy = {}

		for k, v in pairs(tbl) do
			if type(v) == "table" then
				copy[k] = deepCopy(v)
			else
				copy[k] = v
			end
		end

		return copy
	end
end

return deepCopy