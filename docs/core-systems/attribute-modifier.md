# AttributeModifier

Instance attribute manipulation with undo support. Easily modify and revert attribute changes.

## Creating a Modifier

```lua
local modifier = MysLib.AttributeModifier.new(instance, "Health")
```

The modifier tracks the current value of the attribute.

## Methods

### SetValue

Sets the attribute to a new value and returns an undo function.

```lua
local undo = modifier:SetValue(100)

-- Revert the change
undo.Undo()
```

**Returns:** Table with `Undo()` method

---

### IncrementValue

Increments the attribute value and returns an undo function.

```lua
local undo = modifier:IncrementValue(10)

-- Revert the increment
undo.Undo()
```

**Returns:** Table with `Undo()` method

---

### Destroy

Destroys the modifier and removes it from cache.

```lua
modifier:Destroy()
```

## Examples

### Damage System

```lua
local MysLib = require(MysLib)

local function damagePlayer(character, amount)
    local healthModifier = MysLib.AttributeModifier.new(character, "Health")
    local undo = healthModifier:IncrementValue(-amount)
    
    if character:GetAttribute("Health") <= 0 then
        print("Player defeated")
    end
end

damagePlayer(character, 25)
```

### Reversible Changes

```lua
local modifier = MysLib.AttributeModifier.new(part, "CustomValue")

local undo1 = modifier:SetValue(50)
print(part:GetAttribute("CustomValue"))  -- 50

local undo2 = modifier:SetValue(100)
print(part:GetAttribute("CustomValue"))  -- 100

undo2.Undo()
print(part:GetAttribute("CustomValue"))  -- 50

undo1.Undo()
print(part:GetAttribute("CustomValue"))  -- (original value)
```

### Status Effects

```lua
local speedModifier = MysLib.AttributeModifier.new(character, "Speed")
local slowUndo = speedModifier:SetValue(10)

print("Slowed down")
task.wait(5)

slowUndo.Undo()
print("Speed restored")
```
