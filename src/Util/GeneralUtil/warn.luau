return function(identifier : string, context : string)
	warn(string.format("%s => %s\n%s", identifier, context, debug.traceback("", 3)))
end