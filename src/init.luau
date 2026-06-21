--[[
	Written By: Mystifine
	Last Updated: 2025-12-07

	MysLib is a comprehensive utility library for Roblox game development.
	It provides a collection of modules to simplify common tasks and improve code organization.
]]

local MysLib = {}

MysLib.Version = "0.1.4"

--[[
	Utility modules for various common tasks.
]]
-- Util
--[[
	String utilities for text manipulation.
]]
MysLib.StringUtil = require(script.Util.StringUtil);
--[[
	Mathematical utilities for calculations.
]]
MysLib.MathUtil = require(script.Util.MathUtil);
--[[
	Physics utilities for handling physics-related tasks.
]]
MysLib.PhysicsUtil = require(script.Util.PhysicsUtil);
--[[
	Particle utilities for managing particle effects.
]]
MysLib.ParticleUtil = require(script.Util.ParticleUtil);
--[[
	Table utilities for working with tables.
]]
MysLib.TableUtil = require(script.Util.TableUtil);
--[[
	Player utilities for player-related functions.
]]
MysLib.PlayerUtil = require(script.Util.PlayerUtil);
--[[
	Model utilities for handling models.
]]
MysLib.ModelUtil = require(script.Util.ModelUtil);
--[[
	General utilities for common tasks.
]]
MysLib.GeneralUtil = require(script.Util.GeneralUtil);

--[[
	Bootstrapper module for initializing the library.
]]
MysLib.Bootstrapper = require(script.Bootstrapper);
--[[
	AttributeModifier module for modifying attributes.
]]
MysLib.AttributeModifier = require(script.AttributeModifier);
--[[
	Maid module for managing objects and their cleanup.
]]
MysLib.Maid = require(script.Maid);
--[[
	Hitbox module for creating and managing hitboxes.
]]
MysLib.Hitbox = require(script.Hitbox);
--[[
	Debris module for managing temporary objects.
]]
MysLib.Debris = require(script.Debris);
--[[
	Signal module for event handling.
]]
MysLib.Signal = require(script.Signal);
--[[
	waitForChild module for waiting for child objects.
]]
MysLib.waitForChild = require(script.waitForChild);

--[[
	Type exports for the library.
]]
export type Maid = (typeof(MysLib.Maid));
export type Signal = (typeof(MysLib.Signal));
export type Hitbox = (typeof(MysLib.Hitbox));
export type AttributeModifier = (typeof(MysLib.AttributeModifier));

return MysLib
