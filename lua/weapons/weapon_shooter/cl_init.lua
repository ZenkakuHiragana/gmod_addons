
include "../inklingbase/baseinfo.lua"
include "shared.lua"

--When the weapon is fired, it slightly expands.  This is maximum time to get back to normal size.
local FireWeaponCooldown = 0.1
local FireWeaponMultiplier = 1.5

function SWEP:ClientInit()
end

function SWEP:ClientThink(issquid)
end

--Custom functions executed before weapon model is drawn.
--model | Weapon model(Clientside Entity)
--bone_ent | Owner entity
--pos, ang | Position and angle of weapon model
--v | Viewmodel/Worldmodel element table
--matrix | VMatrix for scaling
local function ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
	if v.inktank then return end
	local fraction = (self:GetModifyWeaponSize() - CurTime() + FireWeaponCooldown) * FireWeaponMultiplier
	if fraction > 0 then model:SetModelScale(1 + fraction) end
end

function SWEP:PreDrawWorldModel(model, bone_ent, pos, ang, v, matrix)
	ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
end

function SWEP:PreViewModelDrawn(model, bone_ent, pos, ang, v, matrix)
	ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
end