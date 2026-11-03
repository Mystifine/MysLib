# AttributeModifier

Instance attribute manipulation with undo support. Easily modify and revert attribute changes.

## Creating a Modifier

```lua
local speedModifier = MysLib.AttributeModifier.new(humanoid, "WalkSpeed")  -- a property
local stackModifier = MysLib.AttributeModifier.new(character, "Stacks")    -- an attribute
```

If the name is a property of the instance, the property is modified; any other name is treated as an attribute. Calling `new` again with the same instance and name returns the same modifier.

Changes made by other code are picked up before each modification, and values the engine clamps (such as `WalkSpeed` below 0) still undo correctly when several changes are stacked.

The modifier destroys itself when the instance is destroyed or removed from the game. After that, its methods do nothing.

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

Increments the attribute value and returns an undo function. A missing attribute counts as `0`.

```lua
local undo = modifier:IncrementValue(10)

-- Revert the increment
undo.Undo()
```

**Returns:** Table with `Undo()` method. Each `Undo()` only takes effect once.

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
    healthModifier:IncrementValue(-amount)
    
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
local speedModifier = MysLib.AttributeModifier.new(character.Humanoid, "WalkSpeed")
local slowUndo = speedModifier:IncrementValue(-6)

print("Slowed down")
task.wait(5)

slowUndo.Undo()
print("Speed restored")
```
