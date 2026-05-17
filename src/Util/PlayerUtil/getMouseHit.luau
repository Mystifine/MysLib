local Players = game.Players;
local RunService = game:GetService("RunService");
local GuiService = game:GetService("GuiService");

local getPlayerPlatform = require(script.Parent.getPlayerPlatform);
local Hitbox = require(script.Parent.Parent.Parent.Hitbox);

local player = Players.LocalPlayer;

local MIN_AIM_DISTANCE = 20;
local LONG_DISTANCE = 2048;

local function getMouseHit()
	if RunService:IsServer() then
		warn(string.format("getMouseHit => getMouseHit is not valid on the server.\nTraceback: %s", debug.traceback()));
		return CFrame.new();	
	end
	
	local mouse = player:GetMouse()
	local camera = workspace.CurrentCamera;
	local mouseScreenPos = Vector2.new(mouse.X, mouse.Y)
	if getPlayerPlatform() == "Mobile" then	
		local guiInset = GuiService:GetGuiInset()
		mouseScreenPos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2 - guiInset.Y)
	end
	
	local mouseUnitRay = camera:ScreenPointToRay(mouseScreenPos.X, mouseScreenPos.Y)
	local mouseUnitRayDirection = mouseUnitRay.Direction

	--local mouseUnitRay = camera:ScreenPointToRay(mousePos.X,mousePos.Y);
	--local mouseUnitRayDirection = mouseUnitRay.Direction;
	
	local raycastParams = RaycastParams.new();
	raycastParams.FilterDescendantsInstances = {workspace:FindFirstChild("VISUALS"), player.Character};
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude;
	raycastParams.RespectCanCollide=true;
	raycastParams.IgnoreWater=true;

	local newMouseHitPosition = nil;
	local result = Hitbox.raycast(camera.CFrame.Position, mouseUnitRayDirection * LONG_DISTANCE, raycastParams, false, Color3.fromRGB(255,0,0), 0.5);
	if result then
		local magnitude = (result.Position - camera.CFrame.Position).Magnitude;
		if magnitude <= MIN_AIM_DISTANCE then
			newMouseHitPosition = camera.CFrame.Position + mouseUnitRayDirection * LONG_DISTANCE;
		else
			newMouseHitPosition = result.Position;
		end
				
		--local part = Instance.new("Part");
		--part.Anchored = true;
		--part.CanCollide = false;
		--part.Position = newMouseHitPosition;
		--part.Color= Color3.fromRGB(255,0,0);
		--part.Size = Vector3.new(10,10,10);
		--part.Material= Enum.Material.Neon;
		--part.Name = "MouseHitVisualization";
		--part.Parent = workspace.VISUALS;
	else
		newMouseHitPosition = camera.CFrame.Position + mouseUnitRayDirection * LONG_DISTANCE;
	end
	return CFrame.lookAt(newMouseHitPosition, newMouseHitPosition + mouseUnitRayDirection);
end

return getMouseHit;
