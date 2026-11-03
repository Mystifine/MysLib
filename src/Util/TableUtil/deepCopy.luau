-- ancestors maps each table currently being copied to its copy, so a table that contains
-- itself is copied once instead of recursing forever.
local function copyTable(tbl, ancestors)
	local copy = {}
	ancestors[tbl] = copy

	for k, v in pairs(tbl) do
		if type(v) == "table" then
			copy[k] = ancestors[v] or copyTable(v, ancestors)
		else
			copy[k] = v
		end
	end

	-- Only ancestors are tracked, so a table referenced from two places still gets two copies.
	ancestors[tbl] = nil
	return copy
end

-- Recursively copies a table and all nested tables.
-- @param tbl: Table to copy.
-- @return: Deep copy of the table.
local function deepCopy(tbl : {}?)

	if typeof(tbl) ~= "table" then
		return tbl
	else
		return copyTable(tbl, {})
	end
end

return deepCopy
