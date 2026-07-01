local Bootstrapper = {}

-- Error handler that returns a formatted traceback for error reporting.
-- @param err: The error message.
-- @return: Formatted traceback.
function Bootstrapper.errorHandler(err)
	return debug.traceback(err, 2);
end

-- Loads and executes a module's main() function with error protection.
-- @param name: Identifier for the module (used in logging).
-- @param module: The module to load.
function Bootstrapper.loadModule(name : string, module : ModuleScript, ...)
	local loadedModule = require(module);

	if type(loadedModule.main) ~= "function" then
		warn(string.format("%s.loadModule => Module '%s' has no main()", name, module:GetFullName()))
		return
	end
	print(string.format("%s.loadModule => Loading Module '%s'", name, module:GetFullName()));

	local loadSuccess, loadResult = xpcall(loadedModule.main, Bootstrapper.errorHandler, ...)

	if not loadSuccess then
		warn(string.format("%s.loadModule => Failed to load module '%s'\nError Reason: %s", name, module:GetFullName(), tostring(loadResult)));
	else
		print(string.format("%s.loadModule => Module '%s' successfully loaded", name, module:GetFullName()));
	end
end

return Bootstrapper
