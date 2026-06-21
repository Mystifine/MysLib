local Players = game:GetService("Players");

local userThumbnailCache = {};

--[=[
	Grabs the player thumbnail based on type and size from the user ID (yields while fetching from API).

	@param userId number -- The user ID to get thumbnail for
	@param thumbnailType Enum.ThumbnailType? -- Type of thumbnail (default: HeadShot)
	@param thumbnailSize Enum.ThumbnailSize? -- Size of thumbnail (default: 420x420)
	@return string -- Thumbnail image ID (or empty string on failure)

	
	```lua
	local thumbId = PlayerUtil.getPlayerThumbnailFromUserId(1, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	```
]=]
return function(userId : number, thumbnailType : Enum.ThumbnailType, thumbnailSize : Enum.ThumbnailSize)
	thumbnailType = thumbnailType or Enum.ThumbnailType.HeadShot;
	thumbnailSize = thumbnailSize or Enum.ThumbnailSize.Size420x420;

	local thumbnailImageId = "";

	local cacheKey = string.format("%d_%s_%s", userId, thumbnailType.Name, thumbnailSize.Name);

	if userThumbnailCache[cacheKey] then
		thumbnailImageId = userThumbnailCache[cacheKey];
	else
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(userId, thumbnailType, thumbnailSize);
		end)

		if not success then
			warn(string.format("MysLib.PlayerUtil.getPlayerThumbnailFromUserId => Failed to retrieve thumbnailId from userId '%d'\nthumbnailType: %s\nthumbnailSize: %s\nResult: %s", userId, thumbnailType.Name, thumbnailSize.Name, tostring(result)));
		else
			thumbnailImageId = result;
			userThumbnailCache[cacheKey] = result;
		end
	end

	return thumbnailImageId;
end
