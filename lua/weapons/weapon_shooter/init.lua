
AddCSLuaFile "shared.lua"
include "shared.lua"

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
	local delta_position = Vector(self.Primary.FirePosition)
	local spreadx = math.Rand(-self.Primary.SpreadBias, self.Primary.SpreadBias)
	if self.Owner:GetVelocity().z > 32 then
		spreadx = spreadx + self.Primary.SpreadJump
	else
		spreadx = spreadx + self.Primary.Spread
	end
	
	delta_position:Rotate(self.Owner:EyeAngles())
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight():Cross(aim), math.Rand(-spreadx, spreadx))
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight(), math.Rand(-SplatoonSWEPs.mDegRandomY, SplatoonSWEPs.mDegRandomY))
	local InitVelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	local SplashInitMul = self.SplashInitMul % self.Primary.SplashPatterns
	local SplashNumRounded = math[math.random() < .5 and "floor" or "ceil"](self.Primary.SplashNum)
	local p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
	p:SetPos(self.Owner:GetShootPos() + delta_position)
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
	p.InitVelocityLength = self.Primary.InitVelocity / SplatoonSWEPs.ToHammerUnitsPerSec
	p.InkType = math.random(4, 9)
	p:Spawn()
	
	if SplashInitMul > 0 then return end
	self.SplashInitRandom = self.SplashInitRandom + 1
	p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
	p:SetPos(self.Owner:GetShootPos() + delta_position)
	p:SetAngles(ang)
	p:SetOwner(self.Owner)
	p:SetInkColorProxy(self:GetInkColorProxy())
	p.InkRadius = self.Primary.InkRadius
	p.MinRadius = self.Primary.MinRadius
	p.InitVelocity = -vector_up * 100
	p.ColorCode = self.ColorCode
	p.TrailWidth = 4
	p.TrailEnd = 1
	p.TrailLife = .1
	p.InkYaw = self.Owner:EyeAngles().yaw
	p.InkType = math.random(1, 3)
	p.IsDrop = true
	p:Spawn()
	p:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	p:SetModelScale(.5)
end
