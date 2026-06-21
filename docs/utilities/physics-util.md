# PhysicsUtil

Physics utilities for velocity, orientation, and vector calculations.

## Velocity

Manages linear velocity constraints with priority system and automatic cleanup.

```lua
local vel = MysLib.PhysicsUtil.Velocity.new(
    part,                           -- BasePart to apply velocity to
    Vector3.new(100, 100, 100),    -- MaxForce per axis
    Vector3.new(50, 0, 0),         -- Initial velocity
    5,                              -- Duration in seconds (-1 for infinite)
    1                               -- Priority (higher overrides lower)
)

vel:SetVelocity(Vector3.new(100, 50, 0))
vel:SetMaxForce(Vector3.new(200, 200, 200))

task.wait(5)
vel:Destroy()
```

### Methods

**SetVelocity** — Update the velocity vector  
**SetMaxForce** — Update the maximum force per axis  
**Destroy** — Stop and clean up

---

## Orientation

Handles angular velocity and rotation constraints.

---

## getHorizontalNormalizedVector

Calculates a normalized 2D vector (ignoring Y axis).

```lua
local direction = MysLib.PhysicsUtil.getHorizontalNormalizedVector(vector)
```

## Examples

### Character Knockback

```lua
local knockbackVelocity = MysLib.PhysicsUtil.Velocity.new(
    character.PrimaryPart,
    Vector3.new(math.huge, 0, math.huge),
    direction * 50,
    0.5  -- Apply for half a second
)
```

### Movement System

```lua
local movementVel = MysLib.PhysicsUtil.Velocity.new(
    humanoidRootPart,
    Vector3.new(100, 0, 100),
    moveDirection * speed,
    -1  -- Infinite duration
)

-- Update movement each frame
RunService.Heartbeat:Connect(function()
    movementVel:SetVelocity(moveDirection * speed)
end)
```
