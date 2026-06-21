--[=[
	Extracts the horizontal (XZ) component of a vector and normalizes it.

	@param input_vector Vector3 -- Vector to extract horizontal component from
	@return Vector3 -- Normalized horizontal vector (Y = 0)

	
	```lua
	local horizontal = getHorizontalNormalizedVector(Vector3.new(3, 5, 4))
	-- Returns approximately (0.6, 0, 0.8) - normalized XZ plane
	```
]=]
return function(input_vector : Vector3)
	local horizontal_vector = Vector3.new(input_vector.X, 0, input_vector.Z);

	if horizontal_vector.Magnitude > 1e-4 then
		return horizontal_vector.Unit;
	else
		return Vector3.new(0,0,0)
	end
end