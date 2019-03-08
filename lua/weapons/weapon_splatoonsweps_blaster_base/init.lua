
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
    self:PrimaryAttack()
end
