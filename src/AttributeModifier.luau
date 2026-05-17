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

function AttributeModifier:IncrementValue(increment : number)
	if self._destroyed then return end;
	
	self._attributeValue += increment;
	self._instance[self._attribute] = self._attributeValue;
	return {
		Undo = function()
			if self._destroyed then return end;
			self._attributeValue -= increment;
			self._instance[self._attribute] = self._attributeValue;
		end,
	}
end

function AttributeModifier:SetValue(value : any?)
	
	if self._destroyed then return end;	
		
	-- Store current value to be reverted
	local current_value = self._attributeValue;
	self._attributeValue = value;
	self._instance[self._attribute] = self._attributeValue;

	return {
		Undo = function()
			if self._destroyed then return end;
			
			-- Revert value back to original
			self._attributeValue = current_value;
			self._instance[self._attribute] = self._attributeValue;			
		end,
	}
end

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
	self._original_attributeValue = nil;
	self._instance = nil;
	self._ancestryChangedConnection = self._ancestryChangedConnection and self._ancestryChangedConnection:Disconnect();
	self._ancestryChangedConnection = nil;
	self._destroyed = true;
end

function AttributeModifier.new(instance : Instance, attribute_name : string)
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
	modifier._attributeValue = instance[attribute_name];
	
	modifier._ancestryChangedConnection = instance.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			modifier:Destroy();
		end
	end)
	
	-- Cache it to be reused
	attributeCache[instance][attribute_name] = modifier;
	
	return modifier;
end

return AttributeModifier :: AttributeModifier
