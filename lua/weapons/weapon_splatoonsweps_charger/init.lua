
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ShouldChargeWeapon()
    return self:GetChargeProgress() < 1
end
