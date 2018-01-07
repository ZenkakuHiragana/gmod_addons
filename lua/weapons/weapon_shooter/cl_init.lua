
include "shared.lua"
SWEP.PrintName = "Shooter base"
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Finger0"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(7, -27, 0),
	},
	-- ["Base"] = {
		-- scale = Vector(1, 1, 1),
		-- pos = Vector(-30, 30, -30),
		-- angle = Angle(0, 0, 0),
	-- },
	["ValveBiped.Bip01_L_Clavicle"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(2, -2, 2),
		angle = Angle(0, 0, 0),
	},
	-- ["ValveBiped.Bip01_Spine4"] = {
		-- scale = Vector(1, 1, 1),
		-- pos = Vector(-30, 26, 30),
		-- angle = Angle(0, -8, 0),
	-- },
	["ValveBiped.Bip01_L_Hand"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, 23, -12),
	}
}

SWEP.VElements = {
	["weapon"] = {
		type = "Model",
		model = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl",
		bone = "ValveBiped.Bip01_Spine4",
		rel = "",
		pos = Vector(3.5, -24.3, -7.2),
		angle = Angle(12.736, 80, 90),
		size = Vector(0.56, 0.56, 0.56),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {},
	}
}

SWEP.WElements = {
	["weapon"] = {
		type = "Model",
		model = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(4, 0.6, 0.5),
		angle = Angle(0, 1, 180),
		size = Vector(1, 1, 1),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {},
	},
}

--Custom functions executed before weapon model is drawn.
--  model | Weapon model(Clientside Entity)
--  bone_ent | Owner entity
--  pos, ang | Position and angle of weapon model
--  v | Viewmodel/Worldmodel element table
--  matrix | VMatrix for scaling
--When the weapon is fired, it slightly expands.  This is maximum time to get back to normal size.
local FireWeaponCooldown = 0.1
local FireWeaponMultiplier = 1.5
local function ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
	if v.inktank then return end
	local fraction = (self:GetModifyWeaponSize() - CurTime() + FireWeaponCooldown) * FireWeaponMultiplier
	if fraction > 0 then model:SetModelScale(1 + fraction) end
end
SWEP.PreDrawWorldModel, SWEP.PreViewModelDrawn = ExpandModel, ExpandModel
