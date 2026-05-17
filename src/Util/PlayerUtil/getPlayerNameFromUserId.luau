local Players = game.Players;

local usernameCache = {};

--[[
	Retrives the username from the userId. This function yields.
	@param userId number
	@return playerName string
]]
return function(userId : number)
	local playerName = "";

	if usernameCache[userId] then
		playerName = usernameCache[userId];
	else
		local success, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId);
		end)

		if not success then
			warn(string.format("MysLib.getPlayerNameFromUserId => Failed to retrieve name from userId '%d': %s", userId, tostring(result)));
			playerName = "Player";
		else
			playerName = result;
			usernameCache[userId] = result;
		end
	end
	return playerName;
end
