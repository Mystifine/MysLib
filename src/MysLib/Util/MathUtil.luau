local MathUtil = {}

function MathUtil.truncate(value : number, decimal_places : number)
	if decimal_places < 0 then 
		decimal_places = 0;
	end
	local multiplier = 1 * math.pow(10, decimal_places);
	return math.floor(value * multiplier) / multiplier
end

function MathUtil.randomNumber(min : number, max : number)
	return min + (max - min) * math.random();
end
MathUtil.rng = MathUtil.randomNumber;

function MathUtil.lerp(a, b, c) : number
	return a + (b - a) * c
end

function MathUtil.quadBezier(t, p0, p1, p2) : number
	local l1 = MathUtil.lerp(p0, p1, t)
	local l2 = MathUtil.lerp(p1, p2, t)
	local quad = MathUtil.lerp(l1, l2, t)
	return quad
end

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
