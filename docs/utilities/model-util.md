# ModelUtil

Model utilities for part selection, welding, and assembly.

## Methods

### getModelLargestPart

Finds the largest part in a model by volume.

```lua
local largest = MysLib.ModelUtil.getModelLargestPart(model)
```

---

### weldConstraint

Creates a weld constraint between two parts with optional offset.

```lua
MysLib.ModelUtil.weldConstraint(part1, part2)
MysLib.ModelUtil.weldConstraint(part1, part2, offset)
```

---

### weldModel

Welds all parts in a model together to a primary part.

```lua
MysLib.ModelUtil.weldModel(model)
```

Automatically selects the largest part as the primary and welds all others to it.

## Examples

### Ragdoll Assembly

```lua
local ragdoll = workspace:FindFirstChild("Ragdoll")
MysLib.ModelUtil.weldModel(ragdoll)  -- Hold it together
```

### Find Model Anchor

```lua
local model = workspace:FindFirstChild("Building")
local largest = MysLib.ModelUtil.getModelLargestPart(model)
print("Anchor to:", largest.Name)
```

### Custom Assembly

```lua
local wheel = workspace:FindFirstChild("Wheel")
local axle = workspace:FindFirstChild("Axle")
MysLib.ModelUtil.weldConstraint(wheel, axle)
```
