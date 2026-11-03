# Maid

Resource cleanup and connection management. Simplifies cleanup of multiple connections, instances, or tasks.

## Creating a Maid

```lua
local maid = MysLib.Maid.new()
```

## Methods

### GiveTask / AddTask

Adds a task to the maid for cleanup. Accepts:
- **Functions** — Called when cleaned
- **RBXScriptConnection** — Disconnected when cleaned
- **Objects with Destroy method** — `Destroy()` called when cleaned
- **Objects with Disconnect method** — `Disconnect()` called when cleaned

```lua
local maid = MysLib.Maid.new()

-- Add function
maid:GiveTask(function()
    print("Cleanup!")
end)

-- Add connection
maid:GiveTask(connection)

-- Add instance
maid:GiveTask(instance)

-- AddTask is an alias
maid:AddTask(connection)
```

Pass a key as the second argument to replace a task later. Giving a different task under the same key cleans up the previous one first:

```lua
maid:GiveTask(effectA, "effect")
maid:GiveTask(effectB, "effect")  -- effectA is cleaned up
```

---

### RemoveTask

Cleans up and forgets the task stored under a key.

```lua
maid:RemoveTask("effect")
```

---

### Destroy / DoCleaning

Cleans up all tasks in the maid, in the order they were given:
- Functions are called
- Connections are disconnected
- Instances are destroyed

```lua
maid:Destroy()

-- DoCleaning is an alias
maid:DoCleaning()
```

Each task runs once. If a task errors, a warning with a traceback is printed and the remaining tasks are still cleaned. Tasks added while cleaning are cleaned too, and the maid can be reused afterwards.

---

### Maid.cleanupTask

Cleans up a single task using the same rules, without a maid. Errors are not caught.

```lua
MysLib.Maid.cleanupTask(connection)
```

## Examples

### Managing Connections

```lua
local maid = MysLib.Maid.new()

-- Add multiple connections
maid:GiveTask(RunService.Heartbeat:Connect(function()
    print("Heartbeat")
end))

maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
    print("Input:", input.KeyCode)
end))

-- Clean all at once
maid:Destroy()
```

### Object Lifecycle

```lua
local character = player.Character
local maid = MysLib.Maid.new()

-- Add cleanup callbacks
maid:GiveTask(function()
    print("Character cleanup")
end)

-- Add the character - when Destroy() is called, character is destroyed
maid:GiveTask(character)

-- Later...
maid:Destroy()  -- Prints message and destroys character
```

### Scope-based Cleanup

```lua
local function setupUI()
    local maid = MysLib.Maid.new()
    
    local button = Instance.new("TextButton")
    maid:GiveTask(button)
    
    maid:GiveTask(button.MouseButton1Click:Connect(function()
        print("Clicked")
    end))
    
    return maid
end

local uiMaid = setupUI()
uiMaid:Destroy()  -- All UI cleaned up
```
