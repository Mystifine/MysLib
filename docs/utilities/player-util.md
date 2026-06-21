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
- Character exists and is in workspace
- Humanoid exists and health > 0
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

Gets a player's avatar thumbnail URL from their user ID.

```lua
local thumbnail = MysLib.PlayerUtil.getPlayerThumbnailFromUserId(123456789)
-- Use in GUI ImageLabel.Image = thumbnail
```

---

### getMouseHit

Gets the mouse position in 3D space. **Client-only function**.

```lua
local position = MysLib.PlayerUtil.getMouseHit()
print(position)  -- Vector3 position
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
