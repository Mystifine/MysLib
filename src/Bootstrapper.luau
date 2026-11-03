local Bootstrapper = {}

-- Error handler that returns a formatted traceback for error reporting.
-- @param err: The error message.
-- @return: Formatted traceback.
function Bootstrapper.errorHandler(err)
	-- tostring, because debug.traceback rejects non-string errors such as error({...}).
	return debug.traceback(tostring(err), 2)
end

-- Loads and executes a module's main() function with error protection.
-- @param module: The ModuleScript to load.
-- @param ...: Arguments to pass to the module's main() function.
function Bootstrapper.loadModule(module : ModuleScript, ...)
	-- Up to 0.2.6 the signature was loadModule(name, module, ...). Keep accepting it.
	if typeof(module) == "string" and typeof((...)) == "Instance" then
		Bootstrapper.loadModule(...)
		return
	end

	local moduleName = if typeof(module) == "Instance" then module:GetFullName() else tostring(module)

	local requireSuccess, result = xpcall(require, Bootstrapper.errorHandler, module)

	if not requireSuccess then
		warn(string.format("[loadModule] Failed to REQUIRE module '%s'\nError: %s", moduleName, tostring(result)))
		return
	end

	local loadedModule = result

	if type(loadedModule) ~= "table" or type(loadedModule.main) ~= "function" then
		warn(string.format("[loadModule] Module '%s' has no main() function", moduleName))
		return
	end

	print(string.format("[loadModule] Loading module '%s'...", moduleName))

	local mainSuccess, mainResult = xpcall(loadedModule.main, Bootstrapper.errorHandler, ...)

	if not mainSuccess then
		warn(string.format("[loadModule] Failed to run MAIN() for module '%s'\nError: %s", moduleName, tostring(mainResult)))
	else
		print(string.format("[loadModule] Module '%s' successfully loaded", moduleName))
	end
end

return Bootstrapper
