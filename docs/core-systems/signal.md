# Signal

A custom event/signal system for decoupled communication. Similar to Roblox's `BindableEvent`, but with additional features like `Once()` and `Wait()`.

## Creating a Signal

```lua
local signal = MysLib.Signal.new()
```

## Methods

### Connect

Connects a callback function that fires every time the signal fires.

```lua
local connection = signal:Connect(function(value)
    print("Signal fired:", value)
end)

connection:Disconnect()
```

**Returns:** `SignalConnection` — Object with `Disconnect()` method

---

### Fire

Fires the signal, calling all connected callbacks with the provided arguments.

```lua
signal:Fire("hello", 42)
signal:Fire(player, damage)
```

---

### Once

Connects a callback that fires only once, then automatically disconnects.

```lua
signal:Once(function(value)
    print("Only fires once:", value)
end)

signal:Fire(1)  -- Prints
signal:Fire(2)  -- Doesn't print
```

**Returns:** `SignalConnection` — Can be manually disconnected if needed

---

### Wait

Yields the current thread until the signal fires and returns the arguments passed to `Fire()`.

```lua
local value = signal:Wait()
print("Signal fired with:", value)
```

Useful for waiting on one-time events without creating a connection.

## Examples

### Simple Event System

```lua
local MysLib = require(MysLib)
local Signal = MysLib.Signal

local playerDamagedSignal = Signal.new()

-- Listener
playerDamagedSignal:Connect(function(player, damage)
    print(player.Name .. " took " .. damage .. " damage")
end)

-- Trigger
playerDamagedSignal:Fire(player, 50)
```

### Multiple Listeners

```lua
local signal = Signal.new()

signal:Connect(function(x)
    print("Listener 1:", x)
end)

signal:Connect(function(x)
    print("Listener 2:", x)
end)

signal:Fire(42)  -- Both listeners print
```

### Wait for Event

```lua
task.spawn(function()
    local value = signal:Wait()
    print("Signal fired with:", value)
end)

task.wait(1)
signal:Fire("hello")  -- Wakes up the spawn
```
