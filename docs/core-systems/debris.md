# Debris

Scheduled object destruction. Automatically destroy instances or tables after a delay.

## Methods

### AddItem

Schedules an object for destruction after a specified delay.

```lua
MysLib.Debris.AddItem(instance, 3)  -- Destroy after 3 seconds
```

Accepts:
- **Instance** — Destroyed using `Instance:Destroy()`
- **Table** — Cleaned up using maid cleanup rules

---

### RemoveItem

Removes a scheduled item before it's destroyed.

```lua
MysLib.Debris.RemoveItem(instance)  -- Cancel destruction
```

## Examples

### Temporary Effects

```lua
local MysLib = require(MysLib)

local effect = Instance.new("Part")
effect.Parent = workspace

-- Destroy after 2 seconds
MysLib.Debris.AddItem(effect, 2)
```

### Cleanup

```lua
-- Schedule a sound for cleanup after it finishes
local sound = Instance.new("Sound")
sound.Parent = workspace
sound:Play()

MysLib.Debris.AddItem(sound, sound.TimeLength)
```

### Cancel Destruction

```lua
local item = Instance.new("Part")
MysLib.Debris.AddItem(item, 5)

task.wait(2)

-- Changed mind - keep it
MysLib.Debris.RemoveItem(item)
```
