# MathUtil

Mathematical utilities for calculations, interpolation, and Bézier curves.

## Methods

### truncate

Truncates a number to a specified number of decimal places.

```lua
MysLib.MathUtil.truncate(3.14159, 2)   -- 3.14
MysLib.MathUtil.truncate(2.99999, 1)   -- 2.9
```

---

### randomNumber / rng

Generates a random number between min and max (inclusive).

```lua
MysLib.MathUtil.randomNumber(1, 10)    -- Random float between 1 and 10
MysLib.MathUtil.rng(0, 100)            -- Alias for randomNumber
```

---

### lerp

Performs linear interpolation between two values.

```lua
MysLib.MathUtil.lerp(0, 100, 0.5)      -- 50
MysLib.MathUtil.lerp(10, 20, 0.25)     -- 12.5
```

**Parameter:** `c` is the interpolation factor (0 to 1)
- 0 = start value
- 0.5 = midpoint
- 1 = end value

---

### quadBezier

Calculates a quadratic Bézier curve value.

```lua
MysLib.MathUtil.quadBezier(0.5, 0, 50, 100)  -- Midpoint of curve
```

**Parameters:**
- `t` — Curve parameter (0 to 1)
- `p0` — Start point
- `p1` — Control point
- `p2` — End point

---

### cubicBezier

Calculates a cubic Bézier curve value.

```lua
MysLib.MathUtil.cubicBezier(0.5, 0, 25, 75, 100)  -- Midpoint of curve
```

**Parameters:**
- `t` — Curve parameter (0 to 1)
- `p0` — Start point
- `p1` — First control point
- `p2` — Second control point
- `p3` — End point

## Examples

### Smooth Animation

```lua
-- Animate a value from 0 to 100 over time
for t = 0, 1, 0.01 do
    local value = MysLib.MathUtil.lerp(0, 100, t)
    print(value)
end
```

### Random Damage

```lua
local baseDamage = 50
local variance = 20
local actualDamage = baseDamage + MysLib.MathUtil.randomNumber(-variance, variance)
```

### Smooth Curves

```lua
-- Create smooth motion with cubic Bézier
local position = MysLib.MathUtil.cubicBezier(t, startX, cp1X, cp2X, endX)
```
