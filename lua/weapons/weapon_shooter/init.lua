
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
	self.SplashInitRandom = 0
	
	if not self.Primary.TripleShotDelay then return end
	self:SetNPCMinBurst(1)
	self:SetNPCMaxBurst(1)
	self:SetNPCMinRest(self.Primary.TripleShotDelay)
	self:SetNPCMaxRest(self.Primary.TripleShotDelay)
end

--Serverside: create ink projectile.
local jumpvelocity = 32
function SWEP:ServerPrimaryAttack(canattack)
	if self.CrouchPriority or self:GetInk() <= 0 then return end
	local p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
	
	local SplashInitMul = self.SplashInitMul % self.Primary.SplashPatterns
	local SplashNumRounded = math[math.random() < .5 and "floor" or "ceil"](self.Primary.SplashNum)
	local DegRandomX = math.Rand(-self.Primary.SpreadBias, self.Primary.SpreadBias)
	+ math.Remap(math.Clamp(self.Owner:GetVelocity().z * ss.SpreadJumpCoefficient,
	0, ss.SpreadJumpMaxVelocity), 0, ss.SpreadJumpMaxVelocity, self.Primary.Spread, self.Primary.SpreadJump)
	
	local pos, dir, h = self:GetFirePosition()
	local right = self.Owner:GetRight()
	local ang = dir:Angle()
	local angle_initvelocity = Angle(ang)
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	angle_initvelocity:RotateAroundAxis(right:Cross(dir), math.Rand(-DegRandomX, DegRandomX))
	angle_initvelocity:RotateAroundAxis(right, math.Rand(-ss.mDegRandomY, ss.mDegRandomY))
	local InitVelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	p:SetPos(pos)
	p:SetAngles(ang)
	p:SetOwner(self.Owner)
	p:SetInkColorProxy(self:GetInkColorProxy())
	p.ColorCode = self.ColorCode
	p.InkYaw = self.Owner:EyeAngles().yaw
	p.Damage = self.Primary.Damage
	p.MinDamage = self.Primary.MinDamage
	p.MinDamageTime = self.Primary.MinDamageTime
	p.DecreaseDamage = self.Primary.DecreaseDamage
	p.InkRadius = self.Primary.InkRadius
	p.MinRadius = self.Primary.MinRadius
	p.SplashRadius = self.Primary.SplashRadius
	p.SplashPatterns = self.Primary.SplashPatterns
	p.SplashNum = SplashNumRounded
	p.SplashInterval = self.Primary.SplashInterval
	p.SplashInitMul = SplashInitMul
	p.SplashRandom = self.SplashInitRandom
	p.Straight = self.Primary.Straight
	p.InitVelocity = InitVelocity
	p.InitVelocityLength = self.Primary.InitVelocity / ss.ToHammerUnitsPerSec
	p.InkType = math.random(4, 9)
	p.ColRadius = self.Primary.ColRadius
	p:Spawn()
	AddCleanup(p)
	self.SplashInitRandom = self.SplashInitRandom + (SplashInitMul > 0 and 0 or 1)
	self.SplashInitMul = self.SplashInitMul + (self.Primary.TripleShotDelay and 3 or 1)
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 1, function(self, sched)
		self:PrimaryAttack()
	end)
end
