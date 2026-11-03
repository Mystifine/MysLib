# ModelUtil

Model utilities for part selection, welding, and assembly.

## Methods

### getModelLargestPart

Finds the part with the largest size (`Size.Magnitude`) among a model's descendants. Returns the part and its size, or `nil` if the model has no parts.

```lua
local largest, size = MysLib.ModelUtil.getModelLargestPart(model)
```

---

### weldConstraint

Creates a `WeldConstraint` between two parts, parented to `part1`.

```lua
MysLib.ModelUtil.weldConstraint(part0, part1)
```

---

### weldModel

Welds the model's direct child parts to its `PrimaryPart`, and sets every welded part to unanchored, non-colliding, non-touching and massless.

```lua
model.PrimaryPart = model.Body
MysLib.ModelUtil.weldModel(model)
```

- The model must have a `PrimaryPart`; otherwise a warning is printed and nothing changes.
- Nested models are welded to **their own** `PrimaryPart`, so each stays a separate assembly that you can joint to the main one (for example with a hinge).
- Parts inside folders are not welded.

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
