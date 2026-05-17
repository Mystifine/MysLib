--[[
	Written By: Mystifine
	Last Updated: 2025-12-07
]]

local MysLib = {}

MysLib.Version = "0.1.0"

-- Util
MysLib.StringUtil = require(script.Util.StringUtil);
MysLib.MathUtil = require(script.Util.MathUtil);
MysLib.PhysicsUtil = require(script.Util.PhysicsUtil);
MysLib.ParticleUtil = require(script.Util.ParticleUtil);
MysLib.TableUtil = require(script.Util.TableUtil);
MysLib.PlayerUtil = require(script.Util.PlayerUtil);
MysLib.ModelUtil = require(script.Util.ModelUtil);
MysLib.GeneralUtil = require(script.Util.GeneralUtil);

MysLib.Bootstrapper = require(script.Bootstrapper);
MysLib.AttributeModifier = require(script.AttributeModifier);
MysLib.Maid = require(script.Maid);
MysLib.Hitbox = require(script.Hitbox);
MysLib.Debris = require(script.Debris);
MysLib.Signal = require(script.Signal);
MysLib.waitForChild = require(script.waitForChild);

export type Maid = (typeof(MysLib.Maid));
export type Signal = (typeof(MysLib.Signal));
export type Hitbox = (typeof(MysLib.Hitbox));
export type AttributeModifier = (typeof(MysLib.AttributeModifier));

return MysLib
