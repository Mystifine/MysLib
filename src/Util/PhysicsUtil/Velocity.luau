export type Velocity = {

	attachment : Attachment,
	linearVelocity : LinearVelocity,
	basePart : BasePart,
	connections : {RBXScriptConnection},
	
	Destroy : (self : Velocity) -> nil,
	SetVelocity : (self : Velocity, velocity : Vector3) -> nil,
	SetMaxForce : (self : Velocity, maxForce : Vector3) -> nil,
	
	new : (basePart : BasePart, maxForce : Vector3, velocity : Vector3, duration : number, priority : number) -> Velocity,
}

local ATTACHMENT_NAME = "MysLibVelocityAttachment";
local LINEAR_VELOCITY_NAME = "MysLibVelocityLinearVelocity";

local Velocity = {}
Velocity.__index = Velocity
Velocity.ClassName = "PriorityVelocity";

-- Constructor
function Velocity.new(basePart : BasePart, maxForce : Vector3, velocity : Vector3, duration : number, priority : number)
	local self = setmetatable({}, Velocity);
	self.connections = {};
	
	-- Set a default priority value;
	priority = priority or 0;

	-- Depending on the priority toggle other velocities of same priority or less;
	local children = basePart:GetChildren();
	for i = 1, #children do 
		local child = children[i];
		-- If it's not a Attachment created by our module then ignore it
		if not (child:IsA("Attachment") and child.Name == ATTACHMENT_NAME) then continue end;

		local bodyVelocityPriority = child:GetAttribute("velocityPriority");
		-- Check priority for equal or less than
		if priority >= bodyVelocityPriority then
			-- Destroy lower priority attachment and linear velocity
			child:Destroy();
		end
	end

	-- Create attachment
	self.attachment = Instance.new("Attachment")
	self.attachment.Name = ATTACHMENT_NAME;
	self.attachment.Position = basePart.CFrame:PointToObjectSpace(basePart.AssemblyCenterOfMass);
	self.attachment.Parent = basePart;
	self.attachment:SetAttribute("velocityPriority", priority);

	-- Create LinearVelocity
	self.linearVelocity = Instance.new("LinearVelocity");
	self.linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis;
	self.linearVelocity.MaxAxesForce = maxForce;
	self.linearVelocity.VectorVelocity = velocity;
	self.linearVelocity.Name = LINEAR_VELOCITY_NAME;
	self.linearVelocity.Attachment0 = self.attachment;
	self.linearVelocity.Parent = self.attachment;

	-- Store metadata
	self.basePart = basePart
	
	-- Set connections
	table.insert(self.connections, self.attachment.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:Destroy();
		end
	end))

	-- Auto destroy if the duration is mentioned
	if duration ~= -1 then
		task.delay(duration, function()
			self:Destroy();
		end)
	end

	return self
end

-- Method to update velocity
function Velocity:SetVelocity(velocity : Vector3)
	if self.linearVelocity then
		self.linearVelocity.VectorVelocity = velocity
	end
end

-- Method to update max force
function Velocity:SetMaxForce(maxForce : Vector3)
	if self.linearVelocity then
		self.linearVelocity.MaxAxesForce = maxForce
	end
end

-- Method to destroy the LinearVelocity instance
function Velocity:Destroy()
	if self.basePart == nil then return end;
	
	self.basePart = nil;
	
	-- Clean up connections
	for _, connection in self.connections do 
		if connection.Connected then
			connection:Disconnect();
		end
	end
	self.connections = nil;
	
	-- Clean up
	if self.linearVelocity then
		self.linearVelocity:Destroy()
		self.linearVelocity = nil;
	end

	if self.attachment then
		self.attachment:Destroy()
		self.attachment = nil;
	end
end

return Velocity 
