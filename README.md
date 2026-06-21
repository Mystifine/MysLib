# MysLib

A comprehensive Roblox utility library for game development, written in Luau.

**Version:** 0.1.0

## Features

**Core Systems:** Signal, Maid, Hitbox, Debris, Bootstrapper, AttributeModifier, waitForChild

**Utilities:** StringUtil, MathUtil, PhysicsUtil, ParticleUtil, TableUtil, ModelUtil, PlayerUtil, GeneralUtil

## Quick Start

```bash
rojo build -o MysLib.rbxlx
rojo serve
```

```lua
local MysLib = require(path.to.MysLib)

-- Example usage...
local signal = MysLib.Signal.new()
```

## Documentation

See [full documentation](https://mystifine.github.io/MysLib/) for API details.

## Tools

- **Rojo 7.6.1** — Luau to Roblox place conversion
- **Wally 0.3.2** — Package manager  
- **Selene 0.30.1** — Luau linter
