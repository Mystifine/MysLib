# Bootstrapper

Module loading and initialization with error protection. Safely load game modules at startup.

## Methods

### loadModule

Loads and executes a module's `main()` function with error protection.

```lua
MysLib.Bootstrapper.loadModule(name, module)
```

**Parameters:**
- `name` — Identifier for logging (e.g., "GameServer")
- `module` — The ModuleScript to load

The module must export a `main()` function. Any errors are caught and logged without crashing.

---

### errorHandler

Formats error messages with traceback for debugging.

```lua
local traceback = MysLib.Bootstrapper.errorHandler(error)
```

## Examples

### Basic Setup

```lua
local MysLib = require(MysLib)
local Bootstrapper = MysLib.Bootstrapper

-- Load game modules
Bootstrapper.loadModule("GameServer", workspace.GameModule)
Bootstrapper.loadModule("PlayerManager", workspace.PlayerModule)
```

### Module with main()

Create a module that exports a `main()` function:

```lua
-- MyModule.lua
local MyModule = {}

function MyModule.main()
    print("Module initialized")
    -- Setup code here
end

return MyModule
```

### Error Handling

If a module crashes, it logs the error without stopping the game:

```lua
Bootstrapper.loadModule("CrashingModule", workspace.BadModule)
-- Output: [warning] CrashingModule.loadModule => Failed to load module...
-- Game continues running
```
