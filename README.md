# MysLib

A comprehensive Roblox utility library providing essential tools and utilities for game development, written in Luau.

**Version:** 0.1.0  
**Author:** Mystifine  
**Last Updated:** 2026-06-20

---

## Table of Contents

1. [Installation & Building](#installation--building)
2. [Core Systems](#core-systems)
3. [Utility Modules](#utility-modules)
4. [Helpers](#helpers)
5. [Usage Examples](#usage-examples)
6. [Project Structure](#project-structure)

---

## Installation & Building

### Prerequisites

- [Rojo](https://rojo.space/) 7.6.1+ for building
- [Wally](https://github.com/UpliftGames/wally) 0.3.2+ (optional, for dependencies)
- Roblox Studio

### Building the Library

To build MysLib into a `.rbxlx` (Roblox place) file:

```bash
rojo build -o MysLib.rbxlx
```

This creates a Roblox place file containing the entire library structure.

### Using in Roblox Studio

1. **Build the project:**
   ```bash
   rojo build -o MysLib.rbxlx
   ```

2. **Open in Studio:**
   - Launch Roblox Studio
   - Open `MysLib.rbxlx` (File → Open)

3. **Use with Rojo Serve (Live Development):**
   ```bash
   rojo serve
   ```
   - Start Rojo server in the project directory
   - In Roblox Studio with the place open, use the Rojo plugin to connect
   - Changes to source files are automatically synced to Studio

4. **Require in your scripts:**
   ```lua
   local MysLib = require(path.to.MysLib)
   
   -- Access modules
   local signal = MysLib.Signal.new()
   local maid = MysLib.Maid.new()
   ```

---

## Core Systems

### Signal

A custom event/signal system for decoupled communication with automatic connection management.

**Methods:**

- `Signal.new() → Signal` - Creates a new signal
- `Signal:Connect(callback: function) → SignalConnection` - Connect a callback to the signal
  - Calls the callback every time the signal fires
  - Returns a connection object with `Disconnect()` method
- `Signal:Once(callback: function) → SignalConnection` - Connect a callback that fires only once
  - Automatically disconnects after first fire
  - Returns a connection object
- `Signal:Wait() → any?` - Yields until signal fires, returns fired arguments
- `Signal:Fire(...) → nil` - Fire the signal with optional arguments
  - Passes arguments to all connected callbacks
  - Spawns callbacks asynchronously to prevent blocking

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local signal = MysLib.Signal.new()

-- Connect a persistent callback
local connection = signal:Connect(function(value)
    print("Signal fired with:", value)
end)

-- Connect a one-time callback
signal:Once(function(value)
    print("Only fires once:", value)
end)

-- Fire the signal
signal:Fire("Hello")
signal:Fire("World")

-- Disconnect
connection:Disconnect()
```

---

### Maid

Resource cleanup utility that automatically manages and destroys tasks (connections, functions, instances) in one call.

**Methods:**

- `Maid.new() → Maid` - Creates a new Maid instance
- `Maid:GiveTask(task: any) → nil` - Add a task to the maid
  - Accepts: functions, RBXScriptConnections, objects with Disconnect/Destroy methods
  - Functions are called on cleanup
  - Connections are disconnected
  - Instances are destroyed
- `Maid:AddTask(task: any) → nil` - Alias for `GiveTask`
- `Maid:Destroy() → nil` - Cleanup all tasks and destroy the maid
- `Maid:DoCleaning() → nil` - Alias for `Destroy`

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local maid = MysLib.Maid.new()

-- Add a connection
local connection = game.Workspace.ChildAdded:Connect(function(child)
    print("Child added:", child.Name)
end)
maid:GiveTask(connection)

-- Add a cleanup function
maid:AddTask(function()
    print("Cleaning up!")
end)

-- Add an instance
local part = Instance.new("Part")
part.Parent = workspace
maid:GiveTask(part)

-- Destroy all at once
maid:Destroy()
```

---

### Hitbox

Advanced hitbox detection system supporting multiple hitbox types (square, sphere, part-based) and projectile raycasting with visualization and collision detection.

**Hitbox Types:**

#### SquareHitbox
Box-shaped hitbox using axis-aligned bounding boxes.

**Constructor:** `Hitbox.square(config: SquareHitboxConfig) → SquareHitbox`

**Config Parameters:**
- `cframe: CFrame` - Position and orientation of the hitbox
- `size: Vector3` - Size of the hitbox
- `onHit: function` - Callback when collision detected (receives BasePart)
- `ignoreList: {Instance}?` - Parts to ignore in collision
- `visualize: boolean?` - Show debug visualization (default: false)
- `visualizeColor: Color3?` - Color of debug visualization (default: red)
- `visualizeTransparency: number?` - Transparency of visualization (default: 0.8)
- `visualizeDuration: number?` - How long to show visualization (default: 0.5s)

**Methods:**
- `SquareHitbox:Cast() → nil` - Perform a single collision check
- `SquareHitbox:Start() → nil` - Begin casting every frame
- `SquareHitbox:Stop() → nil` - Stop casting
- `SquareHitbox:Destroy() → nil` - Cleanup and destroy the hitbox

#### SphereHitbox
Sphere-shaped hitbox using radius-based collision detection.

**Constructor:** `Hitbox.sphere(config: SphereHitboxConfig) → SphereHitbox`

**Config Parameters:**
- `cframe: CFrame` - Center position of the sphere
- `radius: number` - Radius of the sphere
- `onHit: function` - Callback when collision detected
- `ignoreList: {Instance}?` - Parts to ignore
- `visualize: boolean?` - Show debug visualization
- `visualizeColor: Color3?` - Visualization color
- `visualizeTransparency: number?` - Visualization transparency
- `visualizeDuration: number?` - Visualization duration

**Methods:** Same as SquareHitbox

#### BasePartHitbox
Hitbox based on an existing BasePart's shape and size.

**Constructor:** `Hitbox.basePart(config: BasePartHitboxConfig) → BasePartHitbox`

**Config Parameters:**
- `basePart: BasePart` - The part to use as the hitbox shape
- `onHit: function` - Callback when collision detected
- `ignoreList: {Instance}?` - Parts to ignore
- `visualize: boolean?` - Show debug visualization
- Additional visualization options...

#### ProjectileHitbox
Raycast-based hitbox for projectiles with velocity and lifetime.

**Constructor:** `Hitbox.projectile(config: ProjectileHitboxConfig) → ProjectileHitbox`

**Config Parameters:**
- `cframe: CFrame` - Starting position and direction
- `velocity: number` - Travel speed in studs/second
- `lifetime: number` - How long the projectile lives in seconds
- `width: number` - Width of the projectile hitbox
- `height: number` - Height of the projectile hitbox
- `onHit: function` - Callback when collision detected (receives RaycastResult)
- Other options similar to other hitbox types

**Methods:**
- `ProjectileHitbox:Start() → nil` - Begin the projectile
- `ProjectileHitbox:Stop() → nil` - Stop and destroy projectile
- `ProjectileHitbox:Destroy() → nil` - Cleanup

**Utility Functions:**

- `Hitbox.raycast(origin: Vector3, direction: Vector3, raycastParams: RaycastParams, visualize?: boolean, visualizeColor?: Color3, visualizeTransparency?: number, visualizeDuration?: number) → RaycastResult` - Perform a raycast with optional visualization

- `Hitbox.spherecast(position: Vector3, radius: number, direction: Vector3, raycastParams: RaycastParams, visualize?: boolean, visualizeColor?: Color3, visualizeTransparency?: number, visualizeDuration?: number) → RaycastResult` - Perform a spherecast with optional visualization

- `Hitbox.getPartBoundsInRadius(position: Vector3, radius: number, overlapParams: OverlapParams) → {Instance}` - Get all parts within a radius

- `Hitbox.getPartBoundsInBox(cframe: CFrame, size: Vector3, overlapParams: OverlapParams) → {Instance}` - Get all parts within a box

- `Hitbox.getPartsInPart(basePart: BasePart, overlapParams: OverlapParams) → {Instance}` - Get all parts intersecting with a part

- `Hitbox.getClosestTarget(position: Vector3, targetList: {Model: boolean}) → Model?` - Find the closest target from a list

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local Hitbox = MysLib.Hitbox

-- Create a sphere hitbox
local sphereHitbox = Hitbox.sphere({
    cframe = workspace.Part.CFrame,
    radius = 20,
    visualize = true,
    visualizeColor = Color3.fromRGB(255, 0, 0),
    onHit = function(part)
        print("Hit:", part.Name)
    end,
    ignoreList = {workspace.Part} -- Don't hit itself
})

-- Start checking for collisions every frame
sphereHitbox:Start()

-- Later, stop and cleanup
sphereHitbox:Stop()
sphereHitbox:Destroy()
```

---

### Debris

Utility for scheduling temporary object destruction after a specified delay.

**Methods:**

- `Debris.AddItem(object: Instance | table, destroyTime: number) → nil`
  - Schedules an instance or table for destruction/cleanup
  - `destroyTime`: How many seconds until cleanup
  - Automatically cleans up connections for Heartbeat efficiency

- `Debris.RemoveItem(object: Instance | table) → nil`
  - Remove a scheduled item before it's destroyed
  - Useful for canceling pending cleanup

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local Debris = MysLib.Debris

-- Create a temporary part
local part = Instance.new("Part")
part.Parent = workspace

-- Schedule it for deletion in 3 seconds
Debris.AddItem(part, 3)

-- Or remove it before 3 seconds
Debris.RemoveItem(part)
```

---

### Bootstrapper

Module loading system for initializing and managing game modules with error handling.

**Methods:**

- `Bootstrapper.loadModule(name: string, module: ModuleScript) → nil`
  - Load a module script that exports a `main()` function
  - Prints status messages and warns on failure
  - `name`: Identifier for logging
  - `module`: ModuleScript to load
  - Calls the module's `main()` function with error protection

- `Bootstrapper.errorHandler(err: string) → string`
  - Error handler that returns formatted traceback
  - Automatically used internally in `loadModule`

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local Bootstrapper = MysLib.Bootstrapper

-- Assuming MyModule has a main() function
Bootstrapper.loadModule("MyApp", workspace.MyModule)
```

---

### AttributeModifier

Streamlined manipulation of Roblox instance attributes with undo support and caching.

**Constructor:** `AttributeModifier.new(instance: Instance, attributeName: string) → AttributeModifier`

**Methods:**

- `AttributeModifier:SetValue(value: any) → {Undo: function}`
  - Set the attribute to a new value
  - Returns undo object with `Undo()` method to revert
  - Cached per instance/attribute combination

- `AttributeModifier:IncrementValue(increment: number) → {Undo: function}`
  - Add to the current attribute value
  - Returns undo object with `Undo()` method to revert

- `AttributeModifier:Destroy() → nil`
  - Cleanup the modifier and remove from cache
  - Automatically called when instance is destroyed

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local AttributeModifier = MysLib.AttributeModifier

local part = workspace.Part
local modifier = AttributeModifier.new(part, "Health")

-- Set value
local undoInfo = modifier:SetValue(100)

-- Increment value
modifier:IncrementValue(10) -- Value is now 110

-- Undo the increment
local undoInfo2 = modifier:IncrementValue(10)
undoInfo2.Undo() -- Value is back to 100

-- Cleanup
modifier:Destroy()
```

---

### waitForChild

Enhanced alternative to Instance:WaitForChild() with timeout support and warnings.

**Function:** `waitForChild(parent: Instance, childName: string, timeOut?: number) → Instance?`

**Parameters:**
- `parent`: The instance to search in
- `childName`: Name of the child to find
- `timeOut`: Maximum time to wait (default: infinity)

**Returns:**
- The child instance if found
- `nil` if timeout or parent is destroyed

**Behavior:**
- Returns immediately if child already exists
- Listens for ChildAdded event
- Warns after 30 seconds of waiting
- Warns if timeout is exceeded
- Returns nil if parent is destroyed

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local waitForChild = MysLib.waitForChild

-- Wait for a child with 10 second timeout
local child = waitForChild(workspace, "MyChild", 10)
if child then
    print("Found:", child.Name)
else
    print("Timeout or parent destroyed")
end
```

---

## Utility Modules

### StringUtil

String manipulation and formatting utilities.

#### RichText

Create Roblox rich text formatting.

**Methods:**

- `RichText.bold(text: string) → string` - Make text bold
- `RichText.italic(text: string) → string` - Make text italic
- `RichText.underline(text: string) → string` - Underline text
- `RichText.strikethrough(text: string) → string` - Strike through text
- `RichText.size(text: string, size: number) → string` - Set font size
- `RichText.color(text: string, rgb: Color3) → string` - Set text color
- `RichText.stroke(text: string, stroke_color: Color3, thickness: number, transparency: number) → string` - Add stroke effect
- `RichText.transparency(text: string, transparency: number) → string` - Set text transparency

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local RichText = MysLib.StringUtil.RichText

local text = RichText.color("Important!", Color3.fromRGB(255, 0, 0))
text = RichText.bold(text)
print(text) -- Red bold "Important!"
```

#### StringUtil Functions

- `StringUtil.abbrev(num: number) → string` - Abbreviate large numbers (1000 → "1K", 1000000 → "1M")
  - Supports suffixes: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc, Ud, Dd, Td, etc.
  - Returns scientific notation for very large numbers

- `StringUtil.addCommas(number: number) → string` - Format number with comma separators
  - Example: 1000000 → "1,000,000"

- `StringUtil.formatTime(seconds: number) → string` - Convert seconds to readable time format
  - Format: "XdYhZmWs"
  - Example: 90061 → "1d 1h 1m 1s"

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local StringUtil = MysLib.StringUtil

print(StringUtil.abbrev(1500))      -- "1.5K"
print(StringUtil.addCommas(1000000)) -- "1,000,000"
print(StringUtil.formatTime(3661))   -- "1h 1m 1s"
```

---

### MathUtil

Mathematical operations and interpolation utilities.

**Methods:**

- `MathUtil.truncate(value: number, decimalPlaces: number) → number` - Truncate number to decimal places
  - Example: `truncate(3.14159, 2)` → `3.14`

- `MathUtil.randomNumber(min: number, max: number) → number` - Get random number in range
  - Alias: `MathUtil.rng(min, max)`
  - Uses `math.random()` internally

- `MathUtil.lerp(a: number, b: number, t: number) → number` - Linear interpolation
  - `t`: 0 to 1, where 0 = a and 1 = b
  - Example: `lerp(0, 100, 0.5)` → `50`

- `MathUtil.quadBezier(t: number, p0: number, p1: number, p2: number) → number` - Quadratic Bézier curve
  - `t`: 0 to 1 parameter
  - Smooth curve through 3 points

- `MathUtil.cubicBezier(t: number, p0: number, p1: number, p2: number, p3: number) → number` - Cubic Bézier curve
  - `t`: 0 to 1 parameter
  - Smooth curve through 4 points

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local MathUtil = MysLib.MathUtil

print(MathUtil.lerp(0, 100, 0.5))     -- 50
print(MathUtil.randomNumber(1, 10))   -- Random int 1-10
print(MathUtil.truncate(3.14159, 2))  -- 3.14
```

---

### PhysicsUtil

Physics-related utilities for velocity, orientation, and vector calculations.

#### Velocity

Wrapper for LinearVelocity constraints with priority system and auto-cleanup.

**Constructor:** `Velocity.new(basePart: BasePart, maxForce: Vector3, velocity: Vector3, duration: number, priority?: number) → Velocity`

**Parameters:**
- `basePart`: Part to apply velocity to
- `maxForce`: Maximum force per axis (Vector3)
- `velocity`: Initial velocity vector
- `duration`: How long to apply (-1 for infinite)
- `priority`: Higher priority overrides lower priority velocities (default: 0)

**Methods:**

- `Velocity:SetVelocity(velocity: Vector3) → nil` - Update the velocity
- `Velocity:SetMaxForce(maxForce: Vector3) → nil` - Update the max force
- `Velocity:Destroy() → nil` - Stop and cleanup

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local Velocity = MysLib.PhysicsUtil.Velocity

local part = workspace.Part
local vel = Velocity.new(part, Vector3.new(100, 100, 100), Vector3.new(50, 0, 0), 5, 1)

-- Update velocity mid-flight
vel:SetVelocity(Vector3.new(100, 50, 0))

-- Cleanup after 5 seconds or manually
vel:Destroy()
```

#### Orientation

Wrapper for AlignOrientation constraints with priority system.

**Constructor:** `Orientation.new(basePart: BasePart, maxTorque: number, cframe: CFrame, duration: number, priority?: number) → Orientation`

**Methods:**

- `Orientation:SetCFrame(cframe: CFrame) → nil` - Update the target orientation
- `Orientation:SetMaxTorque(maxTorque: number) → nil` - Update the max torque
- `Orientation:Destroy() → nil` - Stop and cleanup

#### getHorizontalNormalizedVector

Extract horizontal component of a vector and normalize it.

**Function:** `getHorizontalNormalizedVector(vector: Vector3) → Vector3`

**Returns:**
- Normalized vector with Y component removed
- Returns zero vector if input magnitude is too small

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local PhysicsUtil = MysLib.PhysicsUtil

local vec = Vector3.new(3, 5, 4)
local horizontal = PhysicsUtil.getHorizontalNormalizedVector(vec)
-- Returns unit vector in XZ plane
```

---

### ParticleUtil

Particle effect management utilities.

**Methods:**

- `ParticleUtil.emitParticle(particleEmitter: ParticleEmitter, emissionAmount: number) → nil`
  - Emit particles from an emitter
  - Scales emission based on graphics quality
  - Only works on client

- `ParticleUtil.setParticlesEnabled(instance: Instance, enabled: boolean) → nil`
  - Enable/disable all ParticleEmitters in an instance and descendants
  
- `ParticleUtil.setBeamsEnabled(instance: Instance, enabled: boolean) → nil`
  - Enable/disable all Beams in an instance and descendants

- `ParticleUtil.clearAllParticles(instance: Instance) → nil`
  - Clear all particles from all ParticleEmitters in an instance

- `ParticleUtil.playParticleEffects(instance: Instance) → nil`
  - Play particle effects with timing control
  - Uses attributes on ParticleEmitters:
    - `EmitCount`: Number of particles to emit
    - `EmitDelay`: Delay before emitting starts
    - `EmitDuration`: How long particles emit

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local ParticleUtil = MysLib.ParticleUtil

local emitter = workspace.Part:FindFirstChild("ParticleEmitter")

-- Emit particles scaled to graphics quality
ParticleUtil.emitParticle(emitter, 50)

-- Disable all particles in a model
ParticleUtil.setParticlesEnabled(workspace.Model, false)

-- Play effect with timing
ParticleUtil.playParticleEffects(workspace.EffectPart)
```

---

### TableUtil

Table operation utilities.

**Methods:**

- `TableUtil.deepCopy(table: table?) → table`
  - Recursively copy a table and all nested tables
  - Non-table values are copied by reference
  - Returns non-table input unchanged

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local TableUtil = MysLib.TableUtil

local original = {a = 1, b = {c = 2}}
local copy = TableUtil.deepCopy(original)

copy.b.c = 99
print(original.b.c) -- Still 2
print(copy.b.c)     -- 99
```

---

### ModelUtil

Model and part utilities for assembly and physics setup.

**Methods:**

- `ModelUtil.getModelLargestPart(model: Model) → (BasePart, number)`
  - Find the part with the largest magnitude in a model
  - Returns: (part, size)
  - Recursively searches nested models

- `ModelUtil.weldConstraint(part0: BasePart, part1: BasePart) → WeldConstraint`
  - Create a WeldConstraint connecting two parts
  - Part1 is welded to Part0

- `ModelUtil.weldModel(model: Model) → nil`
  - Weld all parts in a model to its PrimaryPart
  - Sets parts to: not anchored, not collision, not touch, massless
  - Recursively welds nested models
  - Requires model to have a PrimaryPart set

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local ModelUtil = MysLib.ModelUtil

local model = workspace.MyModel
model.PrimaryPart = model:FindFirstChild("Head")

-- Find largest part
local largest, size = ModelUtil.getModelLargestPart(model)
print("Largest part:", largest.Name, "Size:", size)

-- Weld entire model
ModelUtil.weldModel(model)
```

---

### PlayerUtil

Player-specific utilities and information retrieval.

**Methods:**

- `PlayerUtil.getPlayerNameFromUserId(userId: number) → string`
  - Get a player's username from their user ID
  - **Yields** while fetching from API
  - Returns "Player" on failure
  - Caches results for efficiency

- `PlayerUtil.getPlayerThumbnailFromUserId(userId: number, thumbnailType?: Enum.ThumbnailType, thumbnailSize?: Enum.ThumbnailSize) → string`
  - Get a player's thumbnail image ID
  - **Yields** while fetching from API
  - Default: HeadShot at 420x420
  - Returns empty string on failure
  - Caches results

- `PlayerUtil.isCharacterAlive(character: Model) → boolean`
  - Check if a character model is alive
  - Checks: existence, parent, humanoid presence/health, state, primary part

- `PlayerUtil.getPlayerPlatform() → string`
  - Detect which platform the player is on
  - Returns: "Console", "Mobile", or "Desktop"
  - **Client-only** function

- `PlayerUtil.getMouseHit() → CFrame`
  - Get the CFrame where the mouse is pointing
  - Handles platform differences (mobile, desktop)
  - Uses raycasting for accurate hit positions
  - **Client-only** function

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local PlayerUtil = MysLib.PlayerUtil

-- Get player info
local name = PlayerUtil.getPlayerNameFromUserId(1)
local thumbnail = PlayerUtil.getPlayerThumbnailFromUserId(1, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

-- Check character
if PlayerUtil.isCharacterAlive(game.Players.LocalPlayer.Character) then
    print("Character is alive")
end

-- Get platform (client only)
print(PlayerUtil.getPlayerPlatform())

-- Get mouse position (client only)
local mouseCFrame = PlayerUtil.getMouseHit()
```

---

### GeneralUtil

General-purpose utilities for game development.

**Methods:**

- `GeneralUtil.Heartbeat.new(callback: function, cooldown?: number) → HeartbeatConnection`
  - Create a heartbeat connection with optional cooldown
  - `callback`: Function called with elapsed time as parameter
  - `cooldown`: Minimum time between calls in seconds (default: 0)
  - Returns connection with `Disconnect()` and `Destroy()` methods

- `GeneralUtil.Stepped.new(callback: function, cooldown?: number) → SteppedConnection`
  - Create a stepped (physics) connection with optional cooldown
  - Same parameters and return as Heartbeat

- `GeneralUtil.yieldWhileCondition(config: YieldWhileConditionConfigs) → boolean`
  - Yield while a condition is true or until timeout
  - Config parameters:
    - `duration`: How long to wait
    - `condition`: Function that returns boolean
    - `onSuccess`: Callback if condition becomes false
    - `onFail`: Callback if timeout reached
    - `onTick`: Callback each frame
  - Returns: true if duration met, false if condition became false

- `GeneralUtil.warn(identifier: string, context: string) → nil`
  - Custom warning with formatted traceback
  - `identifier`: Name/location of warning
  - `context`: Warning message

**Example:**
```lua
local MysLib = require(path.to.MysLib)
local GeneralUtil = MysLib.GeneralUtil

-- Heartbeat with 0.5s cooldown
local heartbeat = GeneralUtil.Heartbeat.new(function(elapsed)
    print("Heartbeat:", elapsed)
end, 0.5)

-- Later, stop it
heartbeat:Disconnect()

-- Yield while condition
local result = GeneralUtil.yieldWhileCondition({
    duration = 5,
    condition = function()
        return workspace.Target and workspace.Target.Parent
    end,
    onTick = function(elapsed)
        print("Still waiting:", elapsed)
    end,
    onSuccess = function()
        print("Target disappeared!")
    end,
    onFail = function()
        print("Timed out!")
    end
})

-- Custom warning
GeneralUtil.warn("MyModule", "Something went wrong!")
```

---

## Usage Examples

### Complete Combat System Example

```lua
local MysLib = require(path.to.MysLib)

local Signal = MysLib.Signal
local Maid = MysLib.Maid
local Hitbox = MysLib.Hitbox
local PlayerUtil = MysLib.PlayerUtil

-- Create a weapon
local weapon = {}
weapon.onDamage = Signal.new()
weapon.maid = Maid.new()

function weapon:attack()
    local character = game.Players.LocalPlayer.Character
    if not PlayerUtil.isCharacterAlive(character) then
        return
    end
    
    -- Create attack hitbox
    local hitbox = Hitbox.sphere({
        cframe = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10),
        radius = 15,
        visualize = true,
        onHit = function(part)
            self.onDamage:Fire(part)
        end
    })
    
    self.maid:GiveTask(hitbox)
    hitbox:Cast()
end

function weapon:cleanup()
    self.maid:Destroy()
end

return weapon
```

---

## Project Structure

```
MysLib/
├── src/
│   ├── init.luau                    -- Main library export
│   ├── Signal.luau                  -- Signal/event system
│   ├── Maid.luau                    -- Resource cleanup
│   ├── Hitbox.luau                  -- Hitbox detection
│   ├── Debris.luau                  -- Debris management
│   ├── Bootstrapper.luau            -- Module initialization
│   ├── AttributeModifier.luau       -- Attribute manipulation
│   ├── waitForChild.luau            -- Enhanced child waiting
│   └── Util/
│       ├── StringUtil/
│       │   ├── init.luau
│       │   └── RichText.luau        -- Rich text formatting
│       ├── MathUtil.luau            -- Math operations
│       ├── PhysicsUtil/
│       │   ├── init.luau
│       │   ├── Velocity.luau        -- Linear velocity wrapper
│       │   ├── Orientation.luau     -- Orientation wrapper
│       │   └── getHorizontalNormalizedVector.luau
│       ├── ParticleUtil/
│       │   ├── init.luau
│       │   ├── emitParticle.luau
│       │   ├── playParticleEffects.luau
│       │   ├── setParticlesEnabled.luau
│       │   ├── setBeamsEnabled.luau
│       │   └── clearAllParticles.luau
│       ├── TableUtil/
│       │   ├── init.luau
│       │   └── deepCopy.luau
│       ├── ModelUtil/
│       │   ├── init.luau
│       │   ├── getModelLargestPart.luau
│       │   ├── weldConstraint.luau
│       │   └── weldModel.luau
│       ├── PlayerUtil/
│       │   ├── init.luau
│       │   ├── getPlayerNameFromUserId.luau
│       │   ├── getPlayerThumbnailFromUserId.luau
│       │   ├── getMouseHit.luau
│       │   ├── isCharacterAlive.luau
│       │   └── getPlayerPlatform.luau
│       └── GeneralUtil/
│           ├── init.luau
│           ├── Heartbeat.luau
│           ├── Stepped.luau
│           ├── yieldWhileCondition.luau
│           └── warn.luau
├── rokit.toml                       -- Rokit tool configuration
├── selene.toml                      -- Selene linter configuration
└── README.md                        -- This file
```

---

## Tools & Dependencies

- **Rojo 7.6.1** — Converts Luau files to Roblox place files
- **Wally 0.3.2** — Package manager for Roblox dependencies
- **Selene 0.30.1** — Linter for Luau code quality

---

## Notes

- All modules are designed to be modular and can be used independently
- Memory management is critical — always `Destroy()` hitboxes and maids when done
- Most async functions (API calls) yield — handle appropriately in server context
- Visualizations are disabled by default but helpful for debugging hitboxes
- Use `task.spawn()` or Signals to avoid blocking code

---

For more information about Rojo, visit [rojo.space/docs](https://rojo.space/docs).
