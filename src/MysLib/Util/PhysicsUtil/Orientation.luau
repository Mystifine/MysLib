export type Orientation = {
	base_part: BasePart,
	attachment: Attachment,
	align_orientation: AlignOrientation,
	connections : {RBXScriptConnection},

	Destroy: (self: Orientation) -> nil,
	SetCFrame: (self: Orientation, cframe: CFrame) -> nil,
	SetMaxTorque: (self: Orientation, max_torque: number) -> nil,

	new: (base_part: BasePart, max_torque: number, cframe: CFrame, duration: number) -> Orientation,
}

local OrientationClass = {}
OrientationClass.__index = OrientationClass

local ATTACHMENT_NAME = "mysLibAlignOrientationAttachment";
local ALIGN_ORIENTATION_NAME = "mysLibAlignOrientation";

-- Constructor
function OrientationClass.new(base_part: BasePart, max_torque: number, cframe: CFrame, duration: number, priority : number)
	local self = setmetatable({}, OrientationClass)
	self.connections = {};
	
	-- Set a default priority value;
	priority = priority or 0;

	-- Depending on the priority toggle other orientation of same priority or less;
	local children = base_part:GetChildren();
	for i = 1, #children do 
		local child = children[i];
		if not (child:IsA("Attachment") and child.Name == ATTACHMENT_NAME) then continue end;
		local vel_priority = child:GetAttribute("orientationPriority");

		-- Check priority for equal or less than
		if priority >= vel_priority then

			local lin_velocity = child:FindFirstChild(ALIGN_ORIENTATION_NAME);
			if not lin_velocity then continue end;

			-- Delete the lower priority orientation
			child:Destroy();
		end
	end
	
	-- Create attachment
	self.attachment = Instance.new("Attachment")
	self.attachment.Name = ATTACHMENT_NAME;
	self.attachment.Position = base_part.CFrame:PointToObjectSpace(base_part.AssemblyCenterOfMass);
	self.attachment.Parent = base_part
	self.attachment:SetAttribute("orientationPriority", priority);

	-- Create AlignOrientation
	self.align_orientation = Instance.new("AlignOrientation")
	self.align_orientation.MaxTorque = max_torque
	self.align_orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	self.align_orientation.CFrame = cframe
	self.align_orientation.Responsiveness = 1000 -- Default responsiveness, can be adjusted
	self.align_orientation.RigidityEnabled = true;
	self.align_orientation.Attachment0 = self.attachment
	self.align_orientation.Parent = self.attachment;

	-- Store metadata
	self.base_part = base_part

	-- Set connections
	table.insert(self.connections, self.attachment.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:Destroy();
		end
	end))
	
	-- Auto-destroy after the specified duration
	if duration ~= -1 then
		task.delay(duration, function()
			self:Destroy()
		end)
	end

	return self
end

-- Method to update CFrame
function OrientationClass:SetCFrame(cframe: CFrame)
	if self.align_orientation then
		self.align_orientation.CFrame = cframe
	end
end

-- Method to update MaxTorque
function OrientationClass:SetMaxTorque(max_torque: number)
	if self.align_orientation then
		self.align_orientation.MaxTorque = max_torque
	end
end

-- Method to destroy the AlignOrientation instance
function OrientationClass:Destroy()
	if self.base_part == nil then return end;
	
	self.base_part = nil;

	-- Clean up connections
	for _, connection in self.connections do 
		if connection.Connected then
			connection:Disconnect();
		end
	end
	self.connections = nil;

	-- Clean up
	if self.align_orientation then
		self.align_orientation = self.align_orientation:Destroy()
	end

	if self.attachment then
		self.attachment = self.attachment:Destroy()
	end
end

return OrientationClass
