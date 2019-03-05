
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

function SWEP:ServerThink()
	local c = self.HeroColor[self:GetNWInt "level" + 1]
	for _, t in ipairs {self.Trail, self.TrailViewmodel} do
		if IsValid(t) then t:Fire("Color", tostring(c)) end
	end
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 2, function(self, schedule)
		self:PrimaryAttack()
	end)
end
