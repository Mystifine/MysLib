# GeneralUtil

General utilities for heartbeat connections, stepped events, and logging.

## Heartbeat

Manages heartbeat callbacks with cooldown system.

```lua
local heartbeat = MysLib.GeneralUtil.Heartbeat.new(function(elapsed)
    print("Heartbeat elapsed:", elapsed)
end, 0.5)  -- Run every 0.5 seconds

heartbeat:Disconnect()
```

**Parameters:**
- `callback` — Function called each heartbeat, receives elapsed time
- `cooldown` — Minimum time between calls (default: 0)

An error in one callback is printed as a warning with a traceback and does not stop the others.

---

## Stepped

Similar to Heartbeat but runs on Stepped event.

```lua
local stepped = MysLib.GeneralUtil.Stepped.new(function(elapsed)
    print("Stepped")
end, 0.1)

stepped:Disconnect()
```

---

## yieldWhileCondition

Yields the thread until a condition becomes false.

```lua
MysLib.GeneralUtil.yieldWhileCondition(function()
    return character.Humanoid.Health > 0
end)
print("Character died")
```

Pass a config table instead to add a time limit and callbacks. It returns `true` if the condition held for the whole `duration`, or `false` if it became false first:

```lua
local channelled = MysLib.GeneralUtil.yieldWhileCondition({
    duration = 3,
    condition = function() return isChannelling end,
    onTick = function(elapsed) end,
    onSuccess = function(elapsed) end,
    onFail = function(elapsed) end,
})
```

---

## warn

Prints a warning prefixed with an identifier, followed by a traceback.

```lua
MysLib.GeneralUtil.warn("Inventory", "Something went wrong")
-- Inventory => Something went wrong
```

## Examples

### Heartbeat Loop

```lua
local heartbeat = MysLib.GeneralUtil.Heartbeat.new(function(elapsed)
    character.PrimaryPart.Position = character.PrimaryPart.Position + Vector3.new(0, 0, 1)
end)

task.wait(10)
heartbeat:Disconnect()
```

### Wait for Condition

```lua
task.spawn(function()
    MysLib.GeneralUtil.yieldWhileCondition(function()
        return player.Character == nil
    end)
    print("Player respawned")
end)
```
