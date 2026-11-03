# StringUtil

String utilities for text manipulation and formatting.

## Methods

### abbrev

Abbreviates large numbers to a shorter format with suffixes (K, M, B, T, etc.). Numbers below 1000 are returned unchanged.

```lua
MysLib.StringUtil.abbrev(950)         -- "950"
MysLib.StringUtil.abbrev(1500)        -- "1.5K"
MysLib.StringUtil.abbrev(1000000)     -- "1.0M"
MysLib.StringUtil.abbrev(1234567)     -- "1.2M"
MysLib.StringUtil.abbrev(1234567, 2)  -- "1.23M"
MysLib.StringUtil.abbrev(999999)      -- "1.0M" (rounds into the next suffix)
```

The optional second argument sets the decimal places (default 1). Numbers past the last suffix use scientific notation, such as `"1.0e69"`.

---

### addCommas

Formats a number with comma separators for thousands.

```lua
MysLib.StringUtil.addCommas(1000000)   -- "1,000,000"
MysLib.StringUtil.addCommas(50000)     -- "50,000"
MysLib.StringUtil.addCommas(-1234.5)   -- "-1,234.5"
```

---

### formatTime

Converts seconds to a human-readable time format.

```lua
MysLib.StringUtil.formatTime(3665)      -- "0d 1h 1m 5s"
MysLib.StringUtil.formatTime(120)       -- "0d 0h 2m 0s"
MysLib.StringUtil.formatTime(86400)     -- "1d 0h 0m 0s"
MysLib.StringUtil.formatTime(-5)        -- "-0d 0h 0m 5s"
```

---

### RichText

Sub-module for rich text formatting: `bold`, `italic`, `underline`, `strikethrough`, `size`, `color`, `stroke` and `transparency`.

Use `RichText.escape` on any text you don't control, such as player names or chat, before formatting it. Otherwise characters like `<` can break or inject tags.

```lua
local RichText = MysLib.StringUtil.RichText
label.Text = RichText.bold(RichText.escape(player.DisplayName))
```

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
