
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ServerPrimaryAttack() end
function SWEP:SpawnInk()
	local prog = self:GetChargeProgress()
	local pos, dir = self:GetFirePosition()
	
	-- ss.AddInk(self.Owner, pos, dir * self:GetInkVelocity(), self.ColorCode,
	-- self.Owner:EyeAngles().yaw, math.random(1, 3), 0, self.Primary)
end
