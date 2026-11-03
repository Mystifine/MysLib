export type AttributeModifier = {
	_instance : Instance,
	_destroyed : boolean,
	_attribute : string,
	_attributeValue : any?,
	_ancestryChangedConnection : RBXScriptConnection,

	Destroy : (self : AttributeModifier) -> nil,
	IncrementValue : (self : AttributeModifier, increment : number) -> {Undo : () -> nil};
	SetValue : (self : AttributeModifier, value : any?) -> {Undo : () -> nil};

	new : (instance : Instance, attribute_name : string) -> AttributeModifier,
}

local AttributeModifier = {}
local attributeCache = {};

-- Returned once a modifier is destroyed, so `modifier:SetValue(x).Undo()` never errors.
local NO_OP_UNDO = table.freeze({
	Undo = function() end,
});

-- True when the name refers to a property. Names that only match a method, an event or a child
-- are treated as attributes, since indexing an instance also returns those.
local function isProperty(instance : Instance, name : string) : boolean
	local success, value = pcall(function()
		return (instance :: any)[name];
	end)
	if not success then
		return false;
	end

	local valueType = typeof(value);
	if valueType == "function" or valueType == "RBXScriptSignal" then
		return false;
	end
	if valueType == "Instance" and value.Parent == instance and value.Name == name then
		return false;
	end
	return true;
end

local function readValue(self)
	if self._isProperty then
		return self._instance[self._attribute];
	end
	return self._instance:GetAttribute(self._attribute);
end

-- Adopts the instance's current value if other code changed it since this modifier last wrote.
local function syncValue(self)
	local currentValue = readValue(self);
	if currentValue ~= self._lastWrittenValue then
		self._attributeValue = currentValue;
		self._lastWrittenValue = currentValue;
	end
end

local function applyValue(self, value)
	self._attributeValue = value;
	if self._isProperty then
		self._instance[self._attribute] = value;
	else
		self._instance:SetAttribute(self._attribute, value);
	end
	-- Read back, because the engine may clamp the value (e.g. WalkSpeed cannot go below 0).
	-- _attributeValue keeps the unclamped total so stacked changes still undo correctly.
	self._lastWrittenValue = readValue(self);
end

-- Increments the attribute value and returns an undo function.
-- A missing attribute counts as 0.
-- @param increment: Amount to add to the attribute.
-- @return: Object with Undo() method to revert. Undo only takes effect once.
function AttributeModifier:IncrementValue(increment : number)
	if self._destroyed then return NO_OP_UNDO end;

	syncValue(self);
	applyValue(self, (self._attributeValue or 0) + increment);

	local undone = false;
	return {
		Undo = function()
			if undone or self._destroyed then return end;
			undone = true;

			syncValue(self);
			applyValue(self, (self._attributeValue or 0) - increment);
		end,
	}
end

-- Sets the attribute to a new value and returns an undo function.
-- @param value: The new value for the attribute.
-- @return: Object with Undo() method to revert. Undo only takes effect once.
function AttributeModifier:SetValue(value : any?)

	if self._destroyed then return NO_OP_UNDO end;

	-- Store current value to be reverted
	syncValue(self);
	local current_value = self._attributeValue;
	applyValue(self, value);

	local undone = false;
	return {
		Undo = function()
			if undone or self._destroyed then return end;
			undone = true;

			-- Revert value back to original
			applyValue(self, current_value);
		end,
	}
end

-- Destroys the modifier and removes it from cache.
function AttributeModifier:Destroy()
	if self._destroyed then
		-- instance already destroyed
		return;
	end

	-- Remove attribute from cache
	if attributeCache[self._instance] then
		attributeCache[self._instance][self._attribute] = nil;
	end
	-- If there is no attributes left in the cache then remove the general cache
	if attributeCache[self._instance] and next(attributeCache[self._instance]) == nil then
		attributeCache[self._instance] = nil;
	end
	self._attribute = nil;
	self._instance = nil;
	self._ancestryChangedConnection = self._ancestryChangedConnection and self._ancestryChangedConnection:Disconnect();
	self._ancestryChangedConnection = nil;
	self._destroyingConnection = self._destroyingConnection and self._destroyingConnection:Disconnect();
	self._destroyingConnection = nil;
	self._destroyed = true;
end

-- Creates a new AttributeModifier for a property or attribute of an instance.
-- Property names (e.g. Humanoid "WalkSpeed") modify the property; any other name modifies the attribute.
-- @param instance: The instance with the attribute.
-- @param attribute_name: Name of the property or attribute to modify.
-- @return: The modifier instance.
function AttributeModifier.new(instance : Instance, attribute_name : string)
	assert(typeof(instance) == "Instance", string.format("AttributeModifier.new: expected an Instance, got %s", typeof(instance)));
	assert(type(attribute_name) == "string", string.format("AttributeModifier.new: expected a string name, got %s", typeof(attribute_name)));

	local modifier = setmetatable({}, {__index = AttributeModifier});

	-- Cache the instance if it's not cached;
	if not attributeCache[instance] then
		attributeCache[instance] = {};
	end

	-- Check if the attribute modifier has been cached before
	if attributeCache[instance][attribute_name] then
		return attributeCache[instance][attribute_name];
	end

	modifier._instance = instance;
	modifier._attribute = attribute_name;
	modifier._destroyed = false;
	modifier._isProperty = isProperty(instance, attribute_name);
	modifier._attributeValue = readValue(modifier);
	modifier._lastWrittenValue = modifier._attributeValue;

	modifier._ancestryChangedConnection = instance.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			modifier:Destroy();
		end
	end)
	modifier._destroyingConnection = instance.Destroying:Connect(function()
		modifier:Destroy();
	end)

	-- Cache it to be reused
	attributeCache[instance][attribute_name] = modifier;

	return modifier;
end

return AttributeModifier :: AttributeModifier
