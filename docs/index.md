# MysLib
**Version:** 0.1.9

A comprehensive Roblox utility library providing essential tools for game development, written in Luau.

!!! warning "AI-Assisted Documentation"
    Documentation is AI-Assisted and may contain inaccuracies. Please report any issues or suggestions on the [GitHub Issues Page](https://github.com/Mystifine/MysLib/issues).

## What is MysLib?

MysLib is a collection of battle-tested utilities and systems designed to streamline Roblox game development. Whether you're building combat systems, managing resources, detecting collisions, or manipulating game objects, MysLib provides clean, efficient APIs.

## Core Systems

**[Signal](core-systems/signal.md)** — Custom event/signal system for decoupled communication  
**[Maid](core-systems/maid.md)** — Resource cleanup and connection management  
**[Hitbox](core-systems/hitbox.md)** — Advanced collision detection (square, sphere, part-based, projectile)  
**[Debris](core-systems/debris.md)** — Scheduled object destruction  
**[AttributeModifier](core-systems/attribute-modifier.md)** — Instance attribute manipulation with undo support  
**[Bootstrapper](core-systems/bootstrapper.md)** — Module loading and initialization  
**[waitForChild](core-systems/wait-for-child.md)** — Enhanced child waiting with timeout and warnings  

## Utility Modules

**[StringUtil](utilities/string-util.md)** — String formatting, text abbreviation, time formatting, rich text  
**[MathUtil](utilities/math-util.md)** — Interpolation, Bézier curves, random numbers  
**[PhysicsUtil](utilities/physics-util.md)** — Velocity, orientation, and vector utilities  
**[ParticleUtil](utilities/particle-util.md)** — Particle and beam effect management  
**[TableUtil](utilities/table-util.md)** — Deep table copying and manipulation  
**[ModelUtil](utilities/model-util.md)** — Part selection and welding  
**[PlayerUtil](utilities/player-util.md)** — Player info, platform detection, raycasting  
**[GeneralUtil](utilities/general-util.md)** — Heartbeat/stepped connections, conditional yielding  

## Quick Start

```bash
rojo build -o MysLib.rbxlx
```
Place `MysLib.rbxlx` in your game's `ReplicatedStorage` folder.
```lua
local MysLib = require(path.to.MysLib)

-- Use Signal for events
local signal = MysLib.Signal.new()
signal:Connect(function(value)
    print("Signal fired:", value)
end)
signal:Fire(42)

-- Use Maid for cleanup
local maid = MysLib.Maid.new()
maid:GiveTask(connection)
maid:Destroy() -- Cleans up all tasks
```

See [Getting Started](getting-started.md) for more examples.
