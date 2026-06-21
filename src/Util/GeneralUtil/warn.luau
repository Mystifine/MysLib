--[=[
	Logs a warning with formatted traceback for debugging.

	@param identifier string -- Name or location identifier for the warning
	@param context string -- Warning message or context

	
	```lua
	GeneralUtil.warn("MyModule", "Something went wrong!")
	```
]=]
return function(identifier : string, context : string)
	warn(string.format("%s => %s\n%s", identifier, context, debug.traceback("", 3)))
end