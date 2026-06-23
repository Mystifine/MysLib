# Getting Started

## Installation

You may install MysLib in one of two ways:

### Rojo
1. Git clone or download the repository onto your computer
2. Run `rojo build -o MysLib.rbxlx`
3. Copy 'MysLib' in ReplicatedStorage into your desired location

### Wally
1. Edit your `wally.toml` file to include the following:
```toml
[dependencies]
myslib = "mystifine/myslib@0.1.4"
```
2. Run `wally install`

## Importing MysLib

In your scripts, require the library:

```lua
local MysLib = require(game.ServerScriptService.MysLib)
```

All modules are exposed as properties:

```lua
local Signal = MysLib.Signal
local Maid = MysLib.Maid
local Hitbox = MysLib.Hitbox
local StringUtil = MysLib.StringUtil
```

## Common Patterns

### Event System with Signal

```lua
local signal = MysLib.Signal.new()

-- Connect a listener
local connection = signal:Connect(function(player, damage)
    print(player.Name .. " took " .. damage .. " damage")
end)

-- Fire the signal
signal:Fire(player, 50)

-- Disconnect when done
connection:Disconnect()
```

### Resource Cleanup with Maid

```lua
local maid = MysLib.Maid.new()

-- Add various tasks
maid:GiveTask(connection)  -- Disconnect signals
maid:GiveTask(instance)    -- Destroy objects
maid:GiveTask(function()
    print("Cleanup")
end)

-- Clean everything up
maid:Destroy()
```

### Collision Detection with Hitbox

```lua
local hitbox = MysLib.Hitbox.sphere({
    cframe = workspace.Weapon.CFrame,
    radius = 20,
    onHit = function(part)
        print("Hit:", part.Name)
    end
})

hitbox:Start()  -- Begin detection
task.wait(5)
hitbox:Stop()   -- Stop detection
hitbox:Destroy()
```

### Utility Examples

```lua
-- String abbreviation
print(MysLib.StringUtil.abbrev(1500))     -- "1.5K"
print(MysLib.StringUtil.abbrev(1000000))  -- "1M"

-- Format time
print(MysLib.StringUtil.formatTime(3665)) -- "1h 1m 5s"

-- Deep copy
local copy = MysLib.TableUtil.deepCopy(originalTable)

-- Math interpolation
local value = MysLib.MathUtil.lerp(0, 100, 0.5) -- 50
```

For detailed API documentation, see the [Core Systems](core-systems/signal.md) and [Utilities](utilities/string-util.md) sections.
