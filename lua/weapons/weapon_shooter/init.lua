
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ServerInit()
	self.SplashInitMul = 0
	if not self.Primary.TripleShotDelay then return end
	self:SetNPCMinBurst(1)
	self:SetNPCMaxBurst(1)
	self:SetNPCMinRest(self.Primary.TripleShotDelay)
	self:SetNPCMaxRest(self.Primary.TripleShotDelay)
end

-- Serverside: create ink projectile.
local jumpvelocity = 32
function SWEP:ServerPrimaryAttack(able, auto)
	if not (IsValid(self.Owner) and able) then return end
	local p = self.Primary
	local pos = self:GetFirePosition()
	local splashinit = self.SplashInitMul % p.SplashPatterns
	self.SplashInitMul = self.SplashInitMul + (p.TripleShotDelay and 3 or 1)
	ss.AddInk(self.Owner, pos, self.InitVelocity, self.ColorCode,
	self.Owner:EyeAngles().yaw, math.random(4, 9), splashinit, p)
	
	net.Start "SplatoonSWEPs: Shooter Tracer"
	net.WriteEntity(self.Owner)
	net.WriteVector(pos)
	net.WriteVector(self.InitAngle:Forward())
	net.WriteFloat(p.InitVelocity)
	net.WriteFloat(p.Straight)
	net.WriteUInt(self.ColorCode, ss.COLOR_BITS)
	net.WriteUInt(splashinit, 4)
	net.Send(ss.PlayersReady)
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 1, function(self, schedule)
		self:PrimaryAttack()
	end)
end
