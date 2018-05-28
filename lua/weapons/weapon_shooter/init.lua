
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
end

--Serverside: create ink projectile.
function SWEP:ServerPrimaryAttack(canattack)
	if self.CrouchPriority or self:GetInk() <= 0 then return end
	self.SplashInitMul = self.SplashInitMul + 1
	local aim = IsValid(self.Owner) and self.Owner:GetAimVector() or self:GetForward()
	local ang = aim:Angle()
	local angle_initvelocity = Angle(ang)
	local spreadx = math.Rand(-self.Primary.SpreadBias, self.Primary.SpreadBias)
	local jumpfactor = math.Clamp(self.Owner:GetVelocity().z, 0, 32)
	spreadx = spreadx + math.Remap(jumpfactor, 0, 32, self.Primary.Spread, self.Primary.SpreadJump)
	
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight():Cross(aim), math.Rand(-spreadx, spreadx))
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight(), math.Rand(-ss.mDegRandomY, ss.mDegRandomY))
	local InitVelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	local SplashInitMul = self.SplashInitMul % self.Primary.SplashPatterns
	local SplashNumRounded = math[math.random() < .5 and "floor" or "ceil"](self.Primary.SplashNum)
	local p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
	p:SetPos(self.Owner:GetShootPos() + self:GetFirePosition())
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
	
	if not self.Primary.TripleShotDelay then return end
	self.SplashInitMul = self.SplashInitMul + 2
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
end
