# StringUtil

String utilities for text manipulation and formatting.

## Methods

### abbrev

Abbreviates large numbers to a shorter format with suffixes (K, M, B, T, etc.).

```lua
MysLib.StringUtil.abbrev(1500)      -- "1.5K"
MysLib.StringUtil.abbrev(1000000)   -- "1M"
MysLib.StringUtil.abbrev(1234567)   -- "1.2M"
```

---

### addCommas

Formats a number with comma separators for thousands.

```lua
MysLib.StringUtil.addCommas(1000000)   -- "1,000,000"
MysLib.StringUtil.addCommas(50000)     -- "50,000"
```

---

### formatTime

Converts seconds to a human-readable time format.

```lua
MysLib.StringUtil.formatTime(3665)      -- "0d 1h 1m 5s"
MysLib.StringUtil.formatTime(120)       -- "0d 0h 2m 0s"
MysLib.StringUtil.formatTime(86400)     -- "1d 0h 0m 0s"
```

---

### RichText

Sub-module for rich text formatting (color, bold, size, etc.).

## Examples

### Leaderboard Display

```lua
local score = 12345678
local formatted = MysLib.StringUtil.abbrev(score)  -- "12.3M"
print("Score: " .. formatted)
```

### Countdown Timer

```lua
local timeRemaining = 172800  -- 2 days
local display = MysLib.StringUtil.formatTime(timeRemaining)  -- "2d 0h 0m 0s"
print("Time remaining: " .. display)
```

### Currency Display

```lua
local money = 5000000
print("$" .. MysLib.StringUtil.addCommas(money))  -- "$5,000,000"
```
