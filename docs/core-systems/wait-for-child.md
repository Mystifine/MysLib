# waitForChild

Enhanced child waiting with timeout and warnings. Safer alternative to `Instance:WaitForChild()`.

## Function

```lua
local child = MysLib.waitForChild(parent, "ChildName", timeOut)
```

**Parameters:**
- `parent` — The instance to search in
- `childName` — Name of the child to find
- `timeOut` — Maximum time to wait (optional, default: infinity)

**Returns:** The child instance, or `nil` if timeout or parent destroyed

## Features

- Automatically warns if waiting exceeds 30 seconds
- Supports timeout (unlike built-in `WaitForChild`)
- Returns `nil` if parent is destroyed while waiting
- More reliable than built-in version

## Examples

### Simple Wait

```lua
local child = MysLib.waitForChild(workspace, "MyPart")
if child then
    print("Found:", child.Name)
end
```

### With Timeout

```lua
local child = MysLib.waitForChild(script.Parent, "Config", 5)

if child then
    print("Found config")
else
    print("Config not found within 5 seconds")
end
```

### Wait with Safety

```lua
local humanoidRootPart = MysLib.waitForChild(character, "HumanoidRootPart", 10)

if humanoidRootPart then
    print("Character loaded")
else
    print("Character failed to load - may have been destroyed")
end
```

### Check Before Timeout

```lua
-- Wait 30 seconds, will warn if exceeds 30 seconds
local sound = MysLib.waitForChild(script, "SoundEffect", 60)
```
