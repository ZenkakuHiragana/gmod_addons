
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ServerInit()
	if not self.Primary.TripleShotDelay then return end
	self:SetNPCMinBurst(1)
	self:SetNPCMaxBurst(1)
	self:SetNPCMinRest(self.Primary.TripleShotDelay)
	self:SetNPCMaxRest(self.Primary.TripleShotDelay)
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 1, function(self, schedule)
		self:PrimaryAttack()
	end)
end
