# MysLib

A comprehensive Roblox utility library for game development, written in Luau.

## Features

**Core Systems:** Signal, Maid, Hitbox, Debris, Bootstrapper, AttributeModifier, waitForChild

**Utilities:** StringUtil, MathUtil, PhysicsUtil, ParticleUtil, TableUtil, ModelUtil, PlayerUtil, GeneralUtil

## Quick Start
```lua
local MysLib = require(path.to.MysLib)

-- Example usage...
local signal = MysLib.Signal.new()
```

## Documentation

See [full documentation](https://mystifine.github.io/MysLib/) for API details, and [CHANGELOG.md](CHANGELOG.md) for what changed between versions.

## Development

Tools are pinned in `rokit.toml`; run `rokit install` once.

```bash
lune run tests/run.luau   # specs, run against src/ in a simulated engine
selene src                # lint
```

The specs run the real source files against a mock of the Roblox APIs the library uses (`tests/harness/Engine.luau`). They catch logic and compatibility regressions, but physics, rendering and replication still need checking in Studio. `tests/specs/ApiSurface.spec.luau` lists every public name. Add to it when the API grows, and treat a failure there as a breaking change.
