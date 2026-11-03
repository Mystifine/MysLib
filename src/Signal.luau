--[[
	Signal

	By: Mystifine#4924

	Last Updated: 2026-11-02
]]

export type SignalConnection = {

	Connected : boolean,

	_eventId : string,
	_connectionList : {
		[string] : (...any) -> nil,
	},

	Disconnect : (self : SignalConnection) -> nil,

	new : (connectionId : string, connectionList : {
		[string] : (...any) -> nil,
	}) -> SignalConnection,
}

export type Signal = {
	ClassName : string,

	_connectionId : number,
	_connections : {
		[string] : (...any) -> nil,
	},

	Connect : (self : Signal, callback : (...any) -> nil) -> SignalConnection,
	Wait : (self : Signal) -> ...any,
	Once : (self : Signal, callback : (...any) -> nil) -> SignalConnection,
	Fire : (self : Signal, ...any) -> nil,
	DisconnectAll : (self : Signal) -> nil,
	Destroy : (self : Signal) -> nil,
}

local SignalConnection = {};

local connectionMetatable = {
	__index = function(self, key)
		-- Computed, so it also reflects Once() firing and Signal:DisconnectAll().
		if key == "Connected" then
			return self._connectionList[self._eventId] ~= nil;
		end
		return SignalConnection[key];
	end,
};

function SignalConnection:Disconnect()
	self._connectionList[self._eventId] = nil;
end

function SignalConnection.new(connectionId, connectionList)
	local self = setmetatable({}, connectionMetatable);
	self._eventId = connectionId;
	self._connectionList = connectionList;

	return self
end

local Signal = {}
Signal.ClassName = "Signal";

-- Yields until the signal fires and returns the arguments passed to Fire().
-- @return: Arguments passed to Fire().
function Signal:Wait()
	local thread = coroutine.running();

	self:Once(function(...)
		-- The waiting thread may have been cancelled before the signal fired.
		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, ...);
		end
	end);

	return coroutine.yield();
end

-- Connects a callback that fires only once, then automatically disconnects.
-- @param callback: Function to call when signal fires.
-- @return: SignalConnection object.
function Signal:Once(callback)
	assert(typeof(callback) == "function", "Signal:Once(): Callback must be a function");

	-- Create the connection object first
	local connectionId = tostring(self._connectionId + 1);
	local signalConnection = SignalConnection.new(connectionId, self._connections);

	-- Create callback
	local function callbackWrapper(...)
		signalConnection:Disconnect();
		callback(...);
	end

	-- Register callback
	self._connectionId += 1;
	self._connections[connectionId] = callbackWrapper;

	return signalConnection
end

-- Connects a callback function to the signal. Called every time the signal fires.
-- @param callback: Function to call when signal fires.
-- @return: SignalConnection object with Disconnect() method.
function Signal:Connect(callback)
	assert(typeof(callback) == "function", "Signal:Connect(): Callback must be a function");

	-- Increment connection id
	self._connectionId += 1;
	-- convert connection id to string
	local connectionId = tostring(self._connectionId);
	-- Add callback to connection list
	self._connections[connectionId] = callback;

	-- return a signal disconnector to disconnect the connection
	local signalConnection = SignalConnection.new(connectionId, self._connections);
	return signalConnection
end

-- Fires the signal, calling all connected callbacks with the provided arguments.
-- @param ...: Arguments to pass to all connected callbacks.
function Signal:Fire(...)
	local connections = self._connections;
	for connectionId, callback in pairs(table.clone(connections)) do
		-- Skip connections that an earlier callback disconnected during this Fire.
		if connections[connectionId] == callback then
			task.spawn(callback, ...);
		end
	end
end

-- Disconnects every connection. The signal can still be connected to and fired afterwards.
function Signal:DisconnectAll()
	table.clear(self._connections);
end

-- Alias of DisconnectAll, so a Signal can be given to a Maid.
Signal.Destroy = Signal.DisconnectAll;

-- Creates a new signal instance.
-- @return: A new signal object.
function Signal.new()
	local signal = setmetatable({}, {__index = Signal});
	signal._connections = {};
	signal._connectionId = 0;

	return signal;
end

return Signal
