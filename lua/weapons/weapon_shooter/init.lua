
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

local function AddCleanup(e)
	for _, p in ipairs(player.GetAll()) do
		cleanup.Add(p, ss.CleanupTypeInk, e)
	end
end

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
function SWEP:ServerPrimaryAttack(hasink, auto)
	if not IsValid(self.Owner) then return end
	local lv = self:GetLaggedMovementValue()
	self.Cooldown = math.max(self.Cooldown, CurTime()
	+ math.min(self.Primary.Delay, self.Primary.CrouchDelay) / lv)
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetInk(math.max(0, self:GetInk() - self.Primary.TakeAmmo))
	
	if not hasink then
		if self.Primary.TripleShotDelay then self.Cooldown = CurTime() end
		if CurTime() > self.NextPlayEmpty then
			ss:ShouldEmitSound(self, "SplatoonSWEPs.EmptyShot")
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
		end
		
		return
	end
	
	local pos, dir = self:GetFirePosition()
	local right = self.Owner:GetRight()
	local ang = dir:Angle()
	local angle_initvelocity = Angle(ang)
	local DegRandomX = util.SharedRandom("SplatoonSWEPs: Spread", -self.Primary.SpreadBias, self.Primary.SpreadBias)
	+ Lerp(self.Owner:GetVelocity().z * ss.SpreadJumpFraction, self.Primary.Spread, self.Primary.SpreadJump)
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	local rx = util.SharedRandom("SplatoonSWEPs: Spread", -DegRandomX, DegRandomX, CurTime() * 1e4)
	local ry = util.SharedRandom("SplatoonSWEPs: Spread", -ss.mDegRandomY, ss.mDegRandomY, CurTime() * 1e3)
	angle_initvelocity:RotateAroundAxis(right:Cross(dir), rx)
	angle_initvelocity:RotateAroundAxis(right, ry)
	local initvelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	local splashinit = self.SplashInitMul % self.Primary.SplashPatterns
	ss:AddInk(self.Owner, pos, initvelocity, self:GetColorCode(),
	self.Owner:EyeAngles().yaw, math.random(4, 9), splashinit, self.Primary)
	self.SplashInitMul = self.SplashInitMul + (self.Primary.TripleShotDelay and 3 or 1)
	ss:ShouldEmitSound(self, self.ShootSound)
	
	net.Start "SplatoonSWEPs: Shooter Tracer"
	net.WriteEntity(self.Owner)
	net.WriteVector(pos)
	net.WriteVector(angle_initvelocity:Forward())
	net.WriteFloat(self.Primary.InitVelocity)
	net.WriteFloat(self.Primary.Straight)
	net.WriteUInt(self:GetColorCode(), ss.COLOR_BITS)
	net.WriteUInt(splashinit, 4)
	net.Send(ss.PlayersReady)
	
	if not self.Primary.TripleShotDelay or self.TripleSchedule.done < 2 then return end
	self.Cooldown = CurTime() + (self.Primary.Delay * 2 + self.Primary.TripleShotDelay) / lv
	self:SetAimTimer(self.Cooldown)
	self.TripleSchedule = self:AddSchedule(self.Primary.Delay, 2, self.PrimaryAttack)
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 1, function(self, sched)
		self:PrimaryAttack()
	end)
end
