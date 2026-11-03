# PlayerUtil

Player-related utilities for character checks, platform detection, and user info.

## Methods

### isCharacterAlive

Checks if a character model is alive and valid.

```lua
if MysLib.PlayerUtil.isCharacterAlive(player.Character) then
    print("Character is alive!")
end
```

Validates:
- Character exists and has a Parent
- A Humanoid exists (found by class, so its name doesn't matter) and health > 0
- Humanoid is not in Dead state
- PrimaryPart exists and is part of character

---

### getPlayerPlatform

Detects which platform the player is using. **Client-only function**.

```lua
local platform = MysLib.PlayerUtil.getPlayerPlatform()
if platform == "Mobile" then
    -- Handle mobile-specific code
elseif platform == "Console" then
    -- Console controls
else
    -- Desktop
end
```

**Returns:** `"Console"`, `"Mobile"`, or `"Desktop"`

---

### getPlayerNameFromUserId

Gets a player's username from their user ID.

```lua
local name = MysLib.PlayerUtil.getPlayerNameFromUserId(123456789)
print(name)  -- "PlayerName"
```

---

### getPlayerThumbnailFromUserId

Gets a player's avatar thumbnail from their user ID. Defaults to a 420x420 headshot; results are cached, and an empty string is returned on failure.

```lua
local thumbnail = MysLib.PlayerUtil.getPlayerThumbnailFromUserId(123456789)
imageLabel.Image = thumbnail

local bust = MysLib.PlayerUtil.getPlayerThumbnailFromUserId(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150)
```

---

### getMouseHit

Gets where the mouse is pointing in 3D space, as a `CFrame` facing along the aim direction. Ignores the local character and a `workspace.VISUALS` folder if present. On mobile the screen centre is used. **Client-only function**.

```lua
local hit = MysLib.PlayerUtil.getMouseHit()
print(hit.Position)
```

## Examples

### Check Before Action

```lua
if MysLib.PlayerUtil.isCharacterAlive(targetCharacter) then
    targetCharacter.Humanoid:TakeDamage(25)
else
    print("Character is not alive")
end
```

### Platform-Specific Input

```lua
local platform = MysLib.PlayerUtil.getPlayerPlatform()
if platform == "Mobile" then
    -- Show touch buttons
else
    -- Show keyboard hints
end
```
