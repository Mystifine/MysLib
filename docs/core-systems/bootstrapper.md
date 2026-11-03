# Bootstrapper

Module loading and initialization with error protection. Safely load game modules at startup.

## Methods

### loadModule

Loads and executes a module's `main()` function with error protection.

```lua
MysLib.Bootstrapper.loadModule(module, ...)
```

**Parameters:**
- `module` — The ModuleScript to load
- `...` — Arguments passed through to `main()`

The module must return a table with a `main()` function. Failures to require the module, a missing `main()`, and errors inside `main()` are all logged as warnings without crashing.

!!! note
    The older form `loadModule(name, module, ...)` from versions up to 0.2.6 is still accepted. The name is ignored; logs use the module's full name.

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
Bootstrapper.loadModule(ServerScriptService.GameServer)
Bootstrapper.loadModule(ServerScriptService.PlayerManager, config)  -- config is passed to main()
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
Bootstrapper.loadModule(ServerScriptService.BadModule)
-- Output: [loadModule] Failed to run MAIN() for module 'ServerScriptService.BadModule' ...
-- Game continues running
```
