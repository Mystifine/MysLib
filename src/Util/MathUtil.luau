local MathUtil = {}

-- Truncates a number to a specified number of decimal places.
-- @param value: The number to truncate.
-- @param decimal_places: Number of decimal places to keep.
-- @return: Truncated number.
function MathUtil.truncate(value : number, decimal_places : number)
	if decimal_places < 0 then
		decimal_places = 0;
	end
	local multiplier = 1 * math.pow(10, decimal_places);
	return math.floor(value * multiplier) / multiplier
end

-- Generates a random number between min and max.
-- @param min: Minimum value (inclusive).
-- @param max: Maximum value (inclusive).
-- @return: Random number in range.
function MathUtil.randomNumber(min : number, max : number)
	return min + (max - min) * math.random();
end
MathUtil.rng = MathUtil.randomNumber;

-- Performs linear interpolation between two values.
-- @param a: Start value.
-- @param b: End value.
-- @param c: Interpolation factor (0 to 1).
-- @return: Interpolated value.
function MathUtil.lerp(a, b, c) : number
	return a + (b - a) * c
end

-- Calculates a quadratic Bézier curve value.
-- @param t: Parameter (0 to 1).
-- @param p0: First point.
-- @param p1: Control point.
-- @param p2: Second point.
-- @return: Point on the curve.
function MathUtil.quadBezier(t, p0, p1, p2) : number
	local l1 = MathUtil.lerp(p0, p1, t)
	local l2 = MathUtil.lerp(p1, p2, t)
	local quad = MathUtil.lerp(l1, l2, t)
	return quad
end

-- Calculates a cubic Bézier curve value.
-- @param t: Parameter (0 to 1).
-- @param p0: First point.
-- @param p1: First control point.
-- @param p2: Second control point.
-- @param p3: Second point.
-- @return: Point on the curve.
function MathUtil.cubicBezier(t, p0, p1, p2, p3) : number
	local u = 1 - t
	local tt = t * t
	local uu = u * u
	local uuu = uu * u
	local ttt = tt * t

	local p = uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3

	return p
end

return MathUtil
