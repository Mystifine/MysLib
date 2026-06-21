local Players = game.Players;

local usernameCache = {};

--[=[
	Retrieves the username from a user ID (yields while fetching from API).

	@param userId number -- The user ID to look up
	@return string -- The player's username (or "Player" on failure)

	
	```lua
	local name = PlayerUtil.getPlayerNameFromUserId(1)
	print(name) -- "Roblox"
	```
]=]
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
