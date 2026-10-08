local Bootstrapper = {}

-- Error handler that returns a formatted traceback for error reporting.
-- @param err: The error message.
-- @return: Formatted traceback.
function Bootstrapper.errorHandler(err)
	return debug.traceback(err, 2)
end

-- Loads and executes a module's main() function with error protection.
-- @param module: The ModuleScript to load.
-- @param ...: Arguments to pass to the module's main() function.
function Bootstrapper.loadModule(module : ModuleScript, ...)
	
	local requireSuccess, result = xpcall(require, Bootstrapper.errorHandler, module)

	if not requireSuccess then
		warn(string.format("[loadModule] Failed to REQUIRE module '%s'\nError: %s", module:GetFullName(), tostring(result)))
		return
	end

	local loadedModule = result

	if type(loadedModule.main) ~= "function" then
		warn(string.format("[loadModule] Module '%s' has no main() function", module:GetFullName()))
		return
	end
	
	print(string.format("[loadModule] Loading module '%s'...", module:GetFullName()))

	local mainSuccess, mainResult = xpcall(loadedModule.main, Bootstrapper.errorHandler, ...)

	if not mainSuccess then
		warn(string.format("[loadModule] Failed to run MAIN() for module '%s'\nError: %s", module:GetFullName(), tostring(mainResult)))
	else
		print(string.format("[loadModule] Module '%s' successfully loaded", module:GetFullName()))
	end
end

return Bootstrapper