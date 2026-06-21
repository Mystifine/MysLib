# MysLib

A comprehensive Roblox utility library providing essential tools and utilities for game development, written in Luau.

**Version:** 0.1.0

## Features

### Core Systems

- **Signal** — A custom event/signal system for decoupled communication. Connect callbacks to events with automatic cleanup and support for one-time connections.
- **Maid** — Memory management utility that tracks and automatically cleans up tasks (functions, connections, instances) in one call.
- **Hitbox** — Advanced hitbox detection system supporting raycasting and projectile casting with visualization and customizable collision detection.
- **Debris** — Utility for managing temporary object destruction and cleanup.
- **Bootstrapper** — Application initialization and startup orchestration.
- **AttributeModifier** — Streamlined manipulation of Roblox instance attributes.

### Utility Modules

#### StringUtil
String manipulation and formatting utilities, including rich text generation for styled text output.

#### MathUtil
Mathematical operations including vector calculations, interpolation, and common game math functions.

#### PhysicsUtil
Physics-related utilities including:
- Velocity calculations and manipulation
- Orientation handling
- Horizontal normalized vectors for movement calculations

#### ParticleUtil
Particle effect management:
- Play and control particle effects
- Toggle particles and beams on/off
- Clear particles from instances
- Emit individual particles

#### TableUtil
Table operations including:
- Deep copying of nested tables
- Table manipulation and transformation

#### ModelUtil
Model and part utilities:
- Find the largest part in a model
- Weld constraints and models together
- Model assembly and physics setup

#### PlayerUtil
Player-specific utilities:
- Get player info from User IDs (names, thumbnails)
- Mouse interaction (get mouse hit position)
- Character state checking (is alive/dead)
- Platform detection (PC, Mobile, Console)

#### GeneralUtil
General purpose utilities:
- Custom warning system
- Heartbeat and Stepped connections (RenderStepped alternatives)
- Conditional yielding (wait while a condition is true)

### Helpers

- **waitForChild** — Robust alternative to Instance:WaitForChild() with enhanced safety and timeout handling.

---

## Installation & Building with Rojo

### Prerequisites

This project uses [Rojo](https://rojo.space/) to convert the Luau source files into a Roblox model file. You'll also need:

- [Rokit](https://github.com/rojo-rbx/rokit) (optional but recommended for tool management)
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

### Using MysLib in Your Project

Once built, you can require MysLib from your scripts:

```lua
local MysLib = require(path.to.MysLib)

-- Use utilities
local signal = MysLib.Signal.new()
local maid = MysLib.Maid.new()
local mathUtil = MysLib.MathUtil
```

---

## Project Structure

```
MysLib/
├── src/
│   ├── init.luau              -- Main library export
│   ├── Signal.luau            -- Signal/event system
│   ├── Maid.luau              -- Resource cleanup
│   ├── Hitbox.luau            -- Hitbox detection
│   ├── Debris.luau            -- Debris management
│   ├── Bootstrapper.luau      -- Initialization
│   ├── AttributeModifier.luau -- Attribute manipulation
│   ├── waitForChild.luau      -- Enhanced child waiting
│   └── Util/
│       ├── StringUtil/        -- String operations
│       ├── MathUtil.luau      -- Math operations
│       ├── PhysicsUtil/       -- Physics utilities
│       ├── ParticleUtil/      -- Particle effects
│       ├── TableUtil/         -- Table operations
│       ├── PlayerUtil/        -- Player utilities
│       ├── ModelUtil/         -- Model utilities
│       └── GeneralUtil/       -- General utilities
├── rokit.toml                 -- Rokit tool configuration
├── selene.toml                -- Selene linter config
└── README.md                  -- This file
```

---

## Tools Used

- **Rojo 7.6.1** — Converts Luau files to Roblox place files
- **Wally 0.3.2** — Package manager for Roblox
- **Selene 0.30.1** — Linter for Luau code

---

## Documentation

For detailed information about each module, consult the source files in `src/`. Each module includes type exports and usage examples in comments.

## License

Created by Mystifine

---

For more information about Rojo, visit [rojo.space/docs](https://rojo.space/docs).
