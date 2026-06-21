# TableUtil

Table utilities for deep copying and manipulation.

## Methods

### deepCopy

Recursively copies a table and all nested tables. Modifying the copy won't affect the original.

```lua
local original = {a = 1, b = {c = 2}}
local copy = MysLib.TableUtil.deepCopy(original)

copy.b.c = 99
print(original.b.c)  -- Still 2
print(copy.b.c)      -- 99
```

## Examples

### Duplicating Complex Data

```lua
local playerTemplate = {
    health = 100,
    inventory = {
        sword = true,
        shield = true
    },
    stats = {
        attack = 10,
        defense = 5
    }
}

local player1 = MysLib.TableUtil.deepCopy(playerTemplate)
local player2 = MysLib.TableUtil.deepCopy(playerTemplate)

player1.inventory.sword = false
print(player2.inventory.sword)  -- Still true
```

### Configuration Cloning

```lua
local baseConfig = {
    enabled = true,
    settings = {
        volume = 0.8,
        quality = "high"
    }
}

local customConfig = MysLib.TableUtil.deepCopy(baseConfig)
customConfig.settings.volume = 0.5
-- baseConfig remains unchanged
```
