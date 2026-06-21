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

---

## warn

Custom warning function.

```lua
MysLib.GeneralUtil.warn("Something went wrong")
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
        return player.Character ~= nil
    end)
    print("Player respawned")
end)
```
