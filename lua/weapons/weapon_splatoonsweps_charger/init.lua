
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ShouldChargeWeapon()
    return CurTime() - self:GetCharge() < self.Primary.MaxChargeTime * 2
end
