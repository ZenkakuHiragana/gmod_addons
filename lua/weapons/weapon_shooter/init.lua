
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
function SWEP:ServerPrimaryAttack(hasink)
	if self.CrouchPriority then return end
	local lv = self:GetLaggedMovementValue()
	self.ShotDelay = math.max(self.ShotDelay, CurTime() + self.Primary.CrouchDelay / lv)
	self:MuzzleFlash()
	self.InklingSpeed = self.Primary.MoveSpeed
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetInk(math.max(0, self:GetInk() - self.Primary.TakeAmmo))
	if not self:GetOnEnemyInk() then
		self:SetPlayerSpeed(self.Primary.MoveSpeed)
	end
	
	if not hasink then
		if self.Primary.TripleShotDelay then self.ShotDelay = CurTime() end
		if CurTime() > self.NextPlayEmpty then
			self:EmitSound "SplatoonSWEPs.EmptyShot"
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
		end
		
		return
	end
	
	local pos, dir, armpos = self:GetFirePosition()
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
	ss:AddInk(self.Owner, pos, initvelocity, self:GetColorCode(), self.Owner:EyeAngles().yaw,
	math.random(4, 9), splashinit, self.Primary)
	self.SplashInitMul = self.SplashInitMul + (self.Primary.TripleShotDelay and 3 or 1)
	
	net.Start "SplatoonSWEPs: Shooter Tracer"
	net.WriteEntity(self.Owner)
	net.WriteVector(pos)
	net.WriteVector(angle_initvelocity:Forward())
	net.WriteFloat(self.Primary.InitVelocity)
	net.WriteFloat(self.Primary.Straight)
	net.WriteFloat(self.Primary.Delay / 2)
	net.WriteUInt(self:GetColorCode(), ss.COLOR_BITS)
	net.WriteUInt(splashinit, 4)
	net.Send(ss.PlayersReady)
	
	armpos = armpos == 3 or armpos == 4
	if self.Owner:IsPlayer() then self:SetHoldType(armpos and "rpg" or "crossbow") end
	if not self.Primary.TripleShotDelay or self.TripleSchedule.done < 2 then return end
	self.ShotDelay = CurTime() + (self.Primary.Delay * 2 + self.Primary.TripleShotDelay) / lv
	self.TripleSchedule = self:AddSchedule(self.Primary.Delay, 2, self.PrimaryAttack)
	self.TripleSchedule.time = self.TripleSchedule.time - self:Ping()
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 1, function(self, sched)
		self:PrimaryAttack()
	end)
end

function SWEP:ServerThink()
	if not self.Owner:IsPlayer() then return end
	if self:Crouching() then self:SetHoldType "melee2" end
	if self:GetAimTimer() < CurTime() then
		self.InklingSpeed = self:GetInklingSpeed()
		if not self:GetThrowing() then self:SetHoldType "passive" end
		if self:GetOnEnemyInk() or self:GetInInk() then return end
		self:SetPlayerSpeed(self.InklingSpeed)
	else
		local armpos = select(3, self:GetFirePosition())
		self:SetHoldType((armpos == 3 or armpos == 4) and "rpg" or "crossbow")
	end
end
