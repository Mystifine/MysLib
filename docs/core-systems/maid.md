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

---

### Destroy / DoCleaning

Cleans up all tasks in the maid:
- Functions are called
- Connections are disconnected
- Instances are destroyed

```lua
maid:Destroy()

-- DoCleaning is an alias
maid:DoCleaning()
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
