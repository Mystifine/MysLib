--[[
	Written by: Mystifine
	Created: 2025-05-25
	Last Updated: 2026-05-16
	Update Count: 4
]]

local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");

local hitboxId = 0;
local hitboxCache = {};
local steppedConnection = nil;

export type HitboxConfig = {
	ignoreList : {Instance}?,
	visualize : boolean?,
	visualizeDuration : number?,
	visualizeColor : Color3?,
	visualizeTransparency : number?,
	onHit : (HitEvent : BasePart | RaycastResult) -> nil,
};

-- BaseHitbox
export type BaseHitbox = {
	visualize : boolean,
	visualizeDuration : number,
	visualizeTransparency : number,
	visualizeColor : Color3,
	
	ignoreList : {Instance},
	-- Depending on hitboxType it could be a HitEvent or RaycastResult
	onHit : (HitEvent : BasePart | RaycastResult) -> nil,

	_id : string, -- Unique HitboxId
	_active : boolean, -- Determine if the Hitbox is Destroyed or Not
	_hitboxType : string, -- HitboxType Identification

	Cast : (self : BaseHitbox) -> nil,
	Start : (self : BaseHitbox) -> nil, -- Effectively Casting The Hitbox Per Frame until Stopped
	Stop : (self : BaseHitbox) -> nil, -- Stops Casting the Hitbox
	Destroy : (self : BaseHitbox) -> nil, -- Destroys the Hitbox

	-- Projectile properties
	_projectileEntryTime : number?,
	_projectileLastUpdate : number?,
	_projectileVelocity : number?,
	_projectileLifetime : number?,
	_projectileCFrame : CFrame?,
	_projectileHeight : number?,
	_projectileWidth : number?,
	_projectilePoints : {CFrame}?,
	
	-- Collision Properties
	cframe : CFrame?,
	size : Vector3?,
	radius : number?,
	basePart : BasePart?,

	-- Helper Methods
	_performProjectileCheck : (self : BaseHitbox) -> nil,
	_performCollisionCheck : (self : BaseHitbox) -> nil,
	_drawDebug : (self : BaseHitbox) -> nil,
};

local function onStepped()
	-- Cleanup if there is nothing to monitor
	if next(hitboxCache) == nil then
		steppedConnection = steppedConnection:Disconnect();
		steppedConnection = nil;	
	end
	
	for _, hitbox in pairs(hitboxCache) do
		if hitbox._hitboxType == "ProjectileHitbox" then
			-- Different handling of projectile hitboxes
			if os.clock() - hitbox._projectileEntryTime >= hitbox._projectileLifetime then
				hitbox:Stop();
				continue;
			end
		
			hitbox:_performProjectileCollisionCheck();
		else
			hitbox:_performCollisionCheck(); -- Perform Collision Check
		end
	end
end

local DEFAULT_VISUALIZE_COLOR = Color3.fromRGB(255,0,0);
local DEFAULT_VISUALIZE_TRANSPARENCY = 0.8;
local DEFAULT_VISUALIZE_DURATION = 0.5;
local function getDebugPart(visualizeColor : Color3, visualizeTransparency : number)
	local debugPart = Instance.new("Part");
	debugPart.Anchored = true;
	debugPart.CanCollide = false;
	debugPart.CanQuery = false;
	debugPart.Massless = true;
	debugPart.CanTouch = false;
	debugPart.Name = "hitboxVisual";
	debugPart.Transparency = visualizeTransparency or DEFAULT_VISUALIZE_TRANSPARENCY;
	debugPart.Color = visualizeColor or DEFAULT_VISUALIZE_COLOR;
	
	return debugPart;
end

local BaseHitbox = {};

function BaseHitbox.new(HitboxConfig : HitboxConfig)
	assert(HitboxConfig.onHit, "defaultOnHit not provided in HitboxConfig");
	
	local self = setmetatable({}, BaseHitbox);
	hitboxId += 1;

	self._id = tostring(hitboxId);
	self._active = true;
	
	self.visualize = HitboxConfig.visualize or false;
	self.visualizeColor = HitboxConfig.visualizeColor or DEFAULT_VISUALIZE_COLOR;
	self.visualizeDuration = HitboxConfig.visualizeDuration or DEFAULT_VISUALIZE_DURATION;
	self.visualizeTransparency = HitboxConfig.visualizeTransparency or DEFAULT_VISUALIZE_TRANSPARENCY;
	self.ignoreList = HitboxConfig.ignoreList or {};
	self.onHit = HitboxConfig.onHit;
	
	return self;
end

-- Performs a single collision check without continuous monitoring.
function BaseHitbox:Cast()
	-- If the hitbox is dead we do not want to call this method
	if not self._active then
		return;
	end

	self:_performCollisionCheck();
end

-- Starts continuous collision detection every frame.
function BaseHitbox:Start()
	-- If the hitbox is dead we do not want to call this method
	if not self._active then
		return;
	end

	hitboxCache[self._id] = self;
	if not steppedConnection then
		steppedConnection = RunService.Stepped:Connect(onStepped);
	end
end

-- Stops continuous collision detection.
function BaseHitbox:Stop()
	-- Stopping the hitbox removes it from the cache
	hitboxCache[self._id] = nil;
end

-- Destroys the hitbox and cleans up resources.
function BaseHitbox:Destroy()
	self._active = false; -- Mark this hitbox as dead
	
	hitboxCache[self._id] = nil;
	
	self._hitboxType = nil;
	self._projectileEntryTime = nil;
	self._projectileLastUpdate = nil;
	self._projectileVelocity = nil;
	self._projectileLifetime = nil;
	self._projectileCFrame = nil;
	self._projectileHeight = nil;
	self._projectileWidth = nil;
	self._projectilePoints = nil;
	
	self.velocity = nil;
	self.lifetime = nil;
	self.cframe = nil;
	self.width = nil;
	self.height = nil;
	
	self.cframe = nil;
	self.size = nil;
	self.radius = nil;
	self.basePart = nil;
end

-- SquareHitbox
export type SquareHitbox = BaseHitbox & {
	cframe : CFrame,
	size : Vector3,	

	new : (HitboxConfig : HitboxConfig) -> SquareHitbox,
};

export type SquareHitboxConfig = HitboxConfig & {
	cframe : CFrame,
	size : Vector3,
}

local SquareHitbox = setmetatable({}, {__index = BaseHitbox});

-- Creates a square (box) hitbox for collision detection.
-- @param config: Configuration table with cframe, size, onHit, etc.
-- @return: The hitbox object.
function SquareHitbox.new(SquareHitboxConfig : SquareHitboxConfig)
	local super = BaseHitbox.new(SquareHitboxConfig);
	local self = setmetatable(super, {__index = SquareHitbox});

	self.cframe = SquareHitboxConfig.cframe;
	self.size = SquareHitboxConfig.size;
	self._hitboxType = "SquareHitbox";

	return self;
end

function SquareHitbox:_performCollisionCheck()
	local overlapParams = OverlapParams.new();
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude;
	overlapParams.FilterDescendantsInstances = self.ignoreList;

	self:_drawDebug();
	
	local touchingParts = game.Workspace:GetPartBoundsInBox(self.cframe, self.size, overlapParams);

	local hitLog = {};
	for i = 1, #touchingParts do 
		local part = touchingParts[i];

		task.spawn(self.onHit, part);
	end
end

function SquareHitbox:_drawDebug()
	if not self.visualize then return end;
	
	local debugPart = getDebugPart(self.visualizeColor, self.visualizeTransparency);	
	debugPart.CFrame = self.cframe;
	debugPart.Size = self.size;
	debugPart.Parent = workspace:FindFirstChild("VISUALS") or workspace;
	Debris:AddItem(debugPart, self.visualizeDuration);
end


function SquareHitbox:Cast()
	assert(self.cframe, "'cframe' is not defined");
	assert(self.size, "'size' is not defined");

	-- If the hitbox is dead we do not want to call this method
	if not self._active then
		return;
	end

	self:_performCollisionCheck();
end

-- SphereHitbox
export type SphereHitbox = BaseHitbox & {
	cframe : CFrame,
	radius : number,	

	new : (HitboxConfig : HitboxConfig) -> SphereHitbox,
};

export type SphereHitboxConfig = HitboxConfig & {
	cframe : CFrame,
	radius : number,
}

local SphereHitbox = setmetatable({}, {__index = BaseHitbox});

-- Creates a sphere hitbox for collision detection.
-- @param config: Configuration table with cframe, radius, onHit, etc.
-- @return: The hitbox object.
function SphereHitbox.new(SphereHitboxConfig : SphereHitboxConfig)
	local self = setmetatable(BaseHitbox.new(SphereHitboxConfig), {__index = SphereHitbox});

	self.cframe = SphereHitboxConfig.cframe;
	self.radius = SphereHitboxConfig.radius;
	self._hitboxType = "SphereHitbox";

	return self;
end

function SphereHitbox:_performCollisionCheck()
	local overlapParams = OverlapParams.new();
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude;
	overlapParams.FilterDescendantsInstances = self.ignoreList;

	self:_drawDebug();
	
	local touchingParts = game.Workspace:GetPartBoundsInRadius(self.cframe.Position, self.radius, overlapParams);
	for i = 1, #touchingParts do 
		local part = touchingParts[i];
		
		task.spawn(self.onHit, part);
	end

end

function SphereHitbox:_drawDebug()
	if not self.visualize then return end;

	local debugPart = getDebugPart(self.visualizeColor, self.visualizeTransparency);	
	debugPart.Shape = Enum.PartType.Ball;
	debugPart.CFrame = self.cframe;
	debugPart.Size = Vector3.new(self.radius*2,self.radius*2,self.radius*2);
	debugPart.Parent = workspace:FindFirstChild("VISUALS") or workspace;
	Debris:AddItem(debugPart, self.visualizeDuration);

end

function SphereHitbox:Cast()
	assert(self.cframe, "'cframe' is not defined");
	assert(self.radius, "'radius' is not defined");

	-- If the hitbox is dead we do not want to call this method
	if not self._active then
		return;
	end

	self:_performCollisionCheck();
end

-- BasePartHitbox
export type BasePartHitbox = BaseHitbox & {
	basePart : BasePart,

	new : (HitboxConfig : HitboxConfig) -> BasePartHitbox,
};

export type BasePartHitboxConfig = HitboxConfig & {
	basePart : BasePart,
}

local BasePartHitbox = setmetatable({}, {__index = BaseHitbox});

-- Creates a hitbox based on an existing part's shape and size.
-- @param config: Configuration table with basePart, onHit, etc.
-- @return: The hitbox object.
function BasePartHitbox.new(BasePartHitboxConfig : BasePartHitboxConfig)
	assert(BasePartHitboxConfig.basePart, "basepart is not defined");

	local self = setmetatable(BaseHitbox.new(BasePartHitboxConfig), {__index = BasePartHitbox});

	self.basePart = BasePartHitboxConfig.basePart;
	self._hitboxType = "BasePartHitbox";

	return self;
end

function BasePartHitbox:_performCollisionCheck()
	local overlapParams = OverlapParams.new();
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude;
	overlapParams.FilterDescendantsInstances = self.ignoreList;

	self:_drawDebug();
	
	local touchingParts = game.Workspace:GetPartsInPart(self.basePart, overlapParams);
	for i = 1, #touchingParts do 
		local part = touchingParts[i];
		
		task.spawn(self.onHit, part);
	end

end

function BasePartHitbox:_drawDebug()
	if not self.visualize then return end;

	local debugPart = getDebugPart(self.visualizeColor, self.visualizeTransparency);	
	debugPart.CFrame = self.basePart.CFrame;
	debugPart.Size = self.basePart.Size;
	debugPart.Parent = workspace:FindFirstChild("VISUALS") or workspace;
	Debris:AddItem(debugPart, self.visualizeDuration);
end

-- ProjectileHitbox
export type ProjectileHitbox = BaseHitbox & {
	velocity : number,
	lifetime : number,
	cframe : CFrame,
	width : number,
	height : number,

	_performProjectileCollisionCheck : (self : ProjectileHitbox) -> nil,
	new : (HitboxConfig : HitboxConfig) -> BasePartHitbox,
};

export type ProjectileHitboxConfig = HitboxConfig & {
	velocity : number,
	lifetime : number,
	cframe : CFrame,
	width : number,
	height : number,
}

local ProjectileHitbox = setmetatable({}, {__index = BaseHitbox});

-- Creates a projectile hitbox that raycasts along a path with velocity.
-- @param config: Configuration table with cframe, velocity, lifetime, width, height, onHit, etc.
-- @return: The projectile hitbox object.
function ProjectileHitbox.new(ProjectileHitboxConfig : ProjectileHitboxConfig)
	local self = setmetatable(BaseHitbox.new(ProjectileHitboxConfig), {__index = ProjectileHitbox});

	self.velocity = ProjectileHitboxConfig.velocity;
	self.lifetime = ProjectileHitboxConfig.lifetime;
	self.cframe = ProjectileHitboxConfig.cframe;
	self.width = ProjectileHitboxConfig.width;
	self.height = ProjectileHitboxConfig.height;
	self._hitboxType = "ProjectileHitbox";

	return self;
end


function ProjectileHitbox:Start()
	assert(self.velocity, "'velocity' is not defined");
	assert(self.lifetime, "'lifetime' is not defined");
	assert(self.cframe, "'cframe' is not defined");
	assert(self.width, "'width' is not defined");
	assert(self.height, "'height' is not defined");

	-- Projectile properties
	self._projectileEntryTime = os.clock();
	self._projectileLastUpdate = os.clock();
	self._projectileVelocity = self.velocity;
	self._projectileLifetime = self.lifetime;
	self._projectileCFrame = self.cframe;
	self._projectileHeight = self.height;
	self._projectileWidth = self.width;
	self._projectilePoints = {self.cframe};
	
	local STUDS_PADDING = 1;
	local widthPoints = math.ceil(self.width // STUDS_PADDING);
	local heightPoints = math.ceil(self.height // STUDS_PADDING);
	local widthPadding = self.width / widthPoints;
	local heightPadding = self.height / heightPoints;
	local starting_point = self.cframe * CFrame.new(self.width*0.5,self.height*0.5,0);
	for x = 0, widthPoints+1 do 
		for y = 0, heightPoints+1 do 
			local cframe_point = starting_point * CFrame.new(x*widthPadding,-y*heightPadding,0);
			table.insert(self._projectilePoints, cframe_point);
		end
	end
	
	hitboxCache[self._id] = self;
	if not steppedConnection then
		steppedConnection = RunService.Stepped:Connect(onStepped);
	end
end

function ProjectileHitbox:_performProjectileCollisionCheck()
	local velocity = self._projectileVelocity;
	local lifetime = self._projectileLifetime;
	local lastUpdate = self._projectileLastUpdate;
	
	local points = self._projectilePoints;
	
	local raycastParams = RaycastParams.new();
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude;
	raycastParams.FilterDescendantsInstances = self.ignoreList;

	for i = 1, #points do 
		local forwardOffset = velocity * (os.clock() - lastUpdate);
		local endCFrame = points[i] * CFrame.new(0,0,-forwardOffset);
		
		if self.visualize then
			local debugPart = getDebugPart(self.visualizeColor, self.visualizeTransparency);	
			local startPos = points[i].Position;
			local endPos = endCFrame.Position;
			local distance = (endPos-startPos).Magnitude;
			debugPart.CFrame = CFrame.lookAt((startPos + endPos)*0.5, endPos);
			debugPart.Size = Vector3.new(0.05,0.05,distance);
			debugPart.Parent = workspace:FindFirstChild("VISUALS") or workspace;
			Debris:AddItem(debugPart, self.visualizeDuration);
		end
		
		local result = workspace:Raycast(points[i].Position, points[i].LookVector * forwardOffset, raycastParams);
		
		if result then
			task.spawn(self.onHit, result)
			self:Stop();
			break;
		end
		points[i] = endCFrame;
	end
	self._projectileLastUpdate = os.clock();	
end

function ProjectileHitbox:Cast()
	warn("Please do not call :Cast() on ProjectileHitbox. Use :Start() instead.");
end

-- Hitbox Lib
export type HitboxLib = {
	square : (SquareHitboxConfig : SquareHitboxConfig) -> SquareHitbox,
	sphere : (SphereHitboxConfig : SphereHitboxConfig) -> SphereHitbox,
	basePart : (BasePartHitboxConfig : BasePartHitboxConfig) -> BasePartHitbox	,
	projectile : (ProjectileHitboxConfig : ProjectileHitboxConfig) -> ProjectileHitbox,

	raycast : (origin : Vector3, direction : Vector3, raycastParams : RaycastParams, visualize : boolean?, visualizeColor : Color3?, visualizeTransparency : number?, visualizeDuration : number?) -> RaycastResult,	
	spherecast : (position : Vector3, radius : number, direction : Vector3, raycastParams : RaycastParams, visualize : boolean?, visualizeColor : Color3?, visualizeTransparency : number?, visualizeDuration : number?) -> RaycastResult,
	getPlayerCharacterCFramePingAdjusted : (character : Model) -> CFrame?,
	getPartBoundsInRadius : (position : Vector3, radius : number, overlapParams : OverlapParams) -> {Instance},
	getPartBoundsInBox : (cframe : CFrame, size : Vector3, overlapParams : OverlapParams) -> {Instance},
	getPartsInPart : (basepart : BasePart, overlapParams : OverlapParams) -> {Instance},
	getClosestTarget : (position : Vector3, targetList : {[Model] : boolean}) -> Model?,	
}

local HitboxLib = {};

HitboxLib.square = SquareHitbox.new;
HitboxLib.sphere = SphereHitbox.new;
HitboxLib.basePart = BasePartHitbox.new;
HitboxLib.projectile = ProjectileHitbox.new;

-- Performs a raycast with optional debug visualization.
-- @param origin: Starting point of the raycast.
-- @param direction: Direction and length of the raycast.
-- @param raycastParams: Raycast parameters.
-- @param visualize: Show debug visualization (optional).
-- @param visualizeColor: Color of debug visualization (optional).
-- @param visualizeTransparency: Transparency of visualization (optional).
-- @param visualizeDuration: Duration to show visualization (optional).
-- @return: Result of the raycast (or nil if no hit).
function HitboxLib.raycast(origin : Vector3, direction : Vector3, raycastParams : RaycastParams, visualize : boolean?, visualizeColor : Color3?, visualizeTransparency : number?, visualizeDuration : number?)
	local result = workspace:Raycast(origin, direction, raycastParams);

	if visualize then
		local debugPart = getDebugPart(visualizeColor, visualizeTransparency);
		local start_pos = origin;
		local end_pos = start_pos + direction;
		local distance = (end_pos-start_pos).Magnitude;
		debugPart.CFrame = CFrame.lookAt((start_pos + end_pos)*0.5, end_pos);
		debugPart.Size = Vector3.new(0.05,0.05,distance);
		debugPart.Parent = workspace:FindFirstChild("VISUALS") or workspace;
		Debris:AddItem(debugPart, visualizeDuration);
	end

	return result;
end

-- Performs a spherecast with optional debug visualization.
-- @param position: Center position of the sphere.
-- @param radius: Radius of the sphere.
-- @param direction: Direction and length of movement.
-- @param raycastParams: Raycast parameters.
-- @param visualize: Show debug visualization (optional).
-- @param visualizeColor: Color of debug visualization (optional).
-- @param visualizeTransparency: Transparency of visualization (optional).
-- @param visualizeDuration: Duration to show visualization (optional).
-- @return: Result of the spherecast (or nil if no hit).
function HitboxLib.spherecast(position : Vector3, radius : number, direction : Vector3, raycastParams : RaycastParams, visualize : boolean?, visualizeColor : Color3?, visualizeTransparency : number?, visualizeDuration : number?)
	local result = workspace:Spherecast(position, radius, direction,raycastParams)
	
	visualizeColor = visualizeColor or DEFAULT_VISUALIZE_COLOR;
	visualizeTransparency = visualizeTransparency or DEFAULT_VISUALIZE_TRANSPARENCY;
	visualizeDuration = visualizeDuration or DEFAULT_VISUALIZE_DURATION;
	
	if visualize then
		local cylinderPart = getDebugPart(visualizeColor, visualizeTransparency);	
		local start_pos = position;
		local end_pos = start_pos + direction;
		local distance = (end_pos-start_pos).Magnitude;
		cylinderPart.CFrame = CFrame.lookAt((start_pos + end_pos)*0.5, end_pos) * CFrame.Angles(0,math.rad(90),0);
		cylinderPart.Shape = Enum.PartType.Cylinder;
		cylinderPart.Size = Vector3.new(distance,radius*2,radius*2);
		cylinderPart.Parent = workspace:FindFirstChild("VISUALS") or workspace;
		Debris:AddItem(cylinderPart, visualizeDuration);
		
		local startSphere = getDebugPart(visualizeColor, visualizeTransparency);
		startSphere.CFrame = CFrame.new(start_pos);
		startSphere.Shape = Enum.PartType.Ball;
		startSphere.Size = Vector3.new(radius*2,radius*2,radius*2);
		startSphere.Parent = workspace:FindFirstChild("VISUALS") or workspace;
		Debris:AddItem(startSphere, visualizeDuration);
		
		local endSphere = getDebugPart(visualizeColor, visualizeTransparency);
		endSphere.CFrame = CFrame.new(end_pos);
		endSphere.Shape = Enum.PartType.Ball;
		endSphere.Size = Vector3.new(radius*2,radius*2,radius*2);
		endSphere.Parent = workspace:FindFirstChild("VISUALS") or workspace;
		Debris:AddItem(endSphere, visualizeDuration);
	end
	
	return result;
end

-- Gets all parts within a radius.
-- @param position: Center position.
-- @param radius: Radius to search.
-- @param overlapParams: Overlap parameters for filtering.
-- @return: List of parts found.
function HitboxLib.getPartBoundsInRadius(...)
	return game.Workspace:GetPartBoundsInRadius(...);
end

-- Gets all parts within a box.
-- @param cframe: Center position and orientation.
-- @param size: Half-size of the box.
-- @param overlapParams: Overlap parameters for filtering.
-- @return: List of parts found.
function HitboxLib.getPartBoundsInBox(...)
	return game.Workspace:GetPartBoundsInBox(...)
end

-- Gets all parts intersecting with a part.
-- @param basePart: The part to use for overlap detection.
-- @param overlapParams: Overlap parameters for filtering.
-- @return: List of parts found.
function HitboxLib.getPartsInPart(...)
	return game.Workspace:GetPartsInPart(...);
end

-- Finds the closest target from a list of models based on position.
-- @param position: Reference position to measure distance from.
-- @param targetList: Dictionary of models to search.
-- @return: The closest model, or nil if no targets.
function HitboxLib.getClosestTarget(position : Vector3, targetList : {[Model] : boolean})
	local closestDistance
	local closestTarget
	for target, _ in pairs(targetList) do
		local distance = (target.PrimaryPart.Position - position).Magnitude;
		if not closestTarget or distance < closestDistance then
			closestDistance = distance;
			closestTarget = target;
		end
	end
	return closestTarget
end

return HitboxLib :: HitboxLib


