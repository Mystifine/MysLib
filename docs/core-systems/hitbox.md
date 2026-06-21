# Hitbox

Advanced collision detection system supporting multiple shapes: squares, spheres, parts, and projectiles. Each hitbox can run once or continuously, with optional debug visualization.

## Creating Hitboxes

### Square Hitbox

Detects collisions within a rectangular box.

```lua
local hitbox = MysLib.Hitbox.square({
    cframe = workspace.Part.CFrame,
    size = Vector3.new(10, 10, 10),
    onHit = function(part)
        print("Hit:", part.Name)
    end
})
```

---

### Sphere Hitbox

Detects collisions within a radius.

```lua
local hitbox = MysLib.Hitbox.sphere({
    cframe = workspace.Part.CFrame,
    radius = 20,
    onHit = function(part)
        print("Hit:", part.Name)
    end
})
```

---

### BasePart Hitbox

Uses an existing part's shape and size for collision detection.

```lua
local hitbox = MysLib.Hitbox.basePart({
    basePart = workspace.HitboxPart,
    onHit = function(part)
        print("Hit:", part.Name)
    end
})
```

---

### Projectile Hitbox

Raycasts along a path with velocity for projectile detection.

```lua
local projectile = MysLib.Hitbox.projectile({
    cframe = workspace.Weapon.CFrame,
    velocity = 100,
    lifetime = 5,
    width = 2,
    height = 2,
    onHit = function(result)
        print("Hit:", result.Instance.Name)
    end
})
```

## Methods

All hitbox types support:

### Start

Begins continuous collision detection every frame.

```lua
hitbox:Start()
```

---

### Stop

Stops continuous collision detection.

```lua
hitbox:Stop()
```

---

### Cast

Performs a single collision check without continuous monitoring.

```lua
hitbox:Cast()
```

---

### Destroy

Destroys the hitbox and cleans up resources.

```lua
hitbox:Destroy()
```

## Configuration

### Common Options

All hitbox types accept these configuration options:

```lua
{
    onHit = function(part) end,           -- Callback when collision detected (required)
    ignoreList = {part1, part2},          -- Parts to ignore
    visualize = true,                     -- Show debug visualization
    visualizeColor = Color3.fromRGB(255, 0, 0),
    visualizeTransparency = 0.8,
    visualizeDuration = 0.5
}
```

## Utility Functions

### raycast

Performs a raycast with optional debug visualization.

```lua
local result = MysLib.Hitbox.raycast(
    origin,           -- Vector3
    direction,        -- Vector3
    raycastParams,
    visualize,        -- boolean?
    visualizeColor,   -- Color3?
    visualizeTransparency,  -- number?
    visualizeDuration -- number?
)
```

---

### spherecast

Performs a spherecast with optional debug visualization.

```lua
local result = MysLib.Hitbox.spherecast(
    position,
    radius,
    direction,
    raycastParams,
    visualize,
    visualizeColor,
    visualizeTransparency,
    visualizeDuration
)
```

---

### getClosestTarget

Finds the closest target from a list of models.

```lua
local targets = {enemy1 = true, enemy2 = true}
local closest = MysLib.Hitbox.getClosestTarget(position, targets)
```

## Examples

### Melee Weapon

```lua
local weapon = workspace.Weapon
local hitbox = MysLib.Hitbox.sphere({
    cframe = weapon.CFrame,
    radius = 5,
    onHit = function(part)
        if part.Parent:FindFirstChild("Humanoid") then
            part.Parent.Humanoid:TakeDamage(25)
        end
    end
})

hitbox:Start()
task.wait(1)
hitbox:Stop()
```

### Projectile Attack

```lua
local projectile = MysLib.Hitbox.projectile({
    cframe = weapon.CFrame,
    velocity = 100,
    lifetime = 5,
    width = 1,
    height = 1,
    visualize = true,
    onHit = function(result)
        local part = result.Instance
        local humanoid = part.Parent:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:TakeDamage(50)
        end
    end
})

projectile:Start()
```

### Debug Visualization

```lua
local hitbox = MysLib.Hitbox.sphere({
    cframe = CFrame.new(0, 10, 0),
    radius = 20,
    visualize = true,
    visualizeColor = Color3.fromRGB(0, 255, 0),
    visualizeTransparency = 0.5,
    visualizeDuration = 1,
    onHit = function(part) print("Hit:", part.Name) end
})

hitbox:Cast()  -- Shows visualization for 1 second
```
