
include "shared.lua"

--Custom functions executed before weapon model is drawn.
--  model | Weapon model(Clientside Entity)
--  bone_ent | Owner entity
--  pos, ang | Position and angle of weapon model
--  v | Viewmodel/Worldmodel element table
--  matrix | VMatrix for scaling
--When the weapon is fired, it slightly expands.  This is maximum time to get back to normal size.
local FireWeaponCooldown = 0.1
local FireWeaponMultiplier = 1
local function ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
	if v.inktank then return end
	local fraction = (FireWeaponCooldown - CurTime() + self.WeaponSize) * FireWeaponMultiplier
	matrix:Scale(SplatoonSWEPs.vector_one * math.max(1, fraction + 1))
end
SWEP.PreDrawWorldModel, SWEP.PreViewModelDrawn = ExpandModel, ExpandModel

function SWEP:ClientInit()
	self.WeaponSize = 0
end

function SWEP:ClientPrimaryAttack(canattack)
	if not (canattack and self:IsFirstTimePredicted()) then return end
	self.WeaponSize = CurTime() --Expand weapon model
end
