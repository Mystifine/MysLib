--[[
	Signal
	
	By: Mystifine#4924
	
	Last Updated: 2025-12-20
]]

export type SignalConnection = {
	
	_eventId : string,
	_connectionList : {
		[string] : (...any) -> nil,	
	},
	
	Disconnect : () -> nil,
	
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
	Wait : (self : Signal, callback : (...any) -> nil) -> any?,
	Once : (self : Signal, callback : (...any) -> nil) -> SignalConnection,
}

local SignalConnection = {};

function SignalConnection:Disconnect()
	self._connectionList[self._eventId] = nil;
end

function SignalConnection.new(connectionId, connectionList)
	local self = setmetatable({}, {__index = SignalConnection});
	self._eventId = connectionId;
	self._connectionList = connectionList;
	
	return self
end

local Signal = {}
Signal.ClassName = "Signal";

function Signal:Wait()
	local waitSignal = Instance.new("BindableEvent");
	waitSignal.Name = "WaitSignalBindableEvent";
	waitSignal.Parent = script;
	
	-- Create the connection object first
	local connectionId = tostring(self._connectionId + 1);
	local signalConnection = SignalConnection.new(connectionId, self._connections);
	
	-- Create callback
	local function callback(...)
		signalConnection:Disconnect();
		waitSignal:Fire(...);
		waitSignal:Destroy();
	end
	
	-- Register callback
	self._connectionId += 1;
	self._connections[connectionId] = callback;
	
	return waitSignal.Event:Wait();
end

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

function Signal:Fire(...)
	local callbackList = table.clone(self._connections);
	for _, callback in pairs(callbackList) do 
		task.spawn(callback, ...);
	end
end

function Signal.new()
	local signal = setmetatable({}, {__index = Signal});
	signal._connections = {};
	signal._connectionId = 0;
	
	return signal;	
end

return Signal
