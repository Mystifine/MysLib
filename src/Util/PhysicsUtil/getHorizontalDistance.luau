--[=[
	Gets the horizontal distance between two vectors.

	@param a Vector3 -- First vector
  @param b Vector3 -- Second vector
  @return number -- Horizontal distance between the two vectors
]=]
local function getHorizontalDistance(a : Vector3, b : Vector3) : number
  local diff = Vector2.new(a.X - b.X, a.Z - b.Z)
  return diff.Magnitude
end

return getHorizontalDistance