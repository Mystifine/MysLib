local GuiService = game:GetService("GuiService");
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService");
-- for client only

return function() : string
	assert(RunService:IsClient(), "getPlayerPlatform can only be called on the client.")
	if GuiService:IsTenFootInterface() then
		return "Console"
	elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return "Mobile"
	else
		return "Desktop"
	end
end
