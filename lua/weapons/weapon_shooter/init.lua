
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ServerInit()
	self.SplashInitMul = 0
end

--Serverside: create ink projectile.
function SWEP:ServerPrimaryAttack(canattack)
	if self.CrouchPriority or self:GetInk() <= 0 then return end
	self.SplashInitMul = self.SplashInitMul + 1
	local aim = IsValid(self.Owner) and self.Owner:GetAimVector() or self:GetForward()
	local ang = aim:Angle()
	local angle_initvelocity = Angle(ang)
	local delta_position = Vector(self.Primary.FirePosition)
	local sbias = self.Primary.SpreadBias
	local spreadx = self.Primary[self.Owner:GetVelocity().z > 32 and "SpreadJump" or "Spread"] + math.Rand(-sbias, sbias)
	local spready = self.Primary[self.Owner:GetVelocity().z > 32 and "SpreadJump" or "Spread"] + math.Rand(-sbias, sbias)
	delta_position:Rotate(self.Owner:EyeAngles())
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight():Cross(aim), math.Rand(-spreadx, spreadx))
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight(), math.Rand(-spready, spready))
	local InitVelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	local SplashInitMul = self.SplashInitMul % self.Primary.SplashPatterns
	local SplashNumRounded = math[math.random() < 0.5 and "floor" or "ceil"](self.Primary.SplashNum)
	for i = -1, 1 do
		local p = ents.Create "projectile_ink"
		if not IsValid(p) then continue end
		p:SetPos(self.Owner:GetShootPos() + delta_position)
		p:SetAngles(ang)
		p:SetOwner(self.Owner)
		p:SetInkColorProxy(self:GetInkColorProxy())
		p.ColorCode = self.ColorCode
		if i == 0 then
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
			p.Straight = self.Primary.Straight
			p.InitVelocity = InitVelocity
			p:Spawn()
		else
			p.InkRadius = self.Primary.SplashRadius
			p.MinRadius = p.InkRadius * self.Primary.MinRadius / self.Primary.InkRadius
			p.InitVelocity = InitVelocity
			p.Straight = self.Primary.Straight + self.Primary.InkRadius * i / self.Primary.InitVelocity
			p.TrailWidth = 2
			p.TrailEnd = 0
			p.TrailLife = .05
			p:Spawn()
			p:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			p:SetModelScale(0.25)
		end
	end
	
	if SplashInitMul > 0 then return end
	local p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
	p:SetPos(self.Owner:GetShootPos() + delta_position)
	p:SetAngles(ang)
	p:SetOwner(self.Owner)
	p:SetInkColorProxy(self:GetInkColorProxy())
	p.InkRadius = self.Primary.SplashRadius
	p.MinRadius = p.InkRadius * self.Primary.MinRadius / self.Primary.InkRadius
	p.InitVelocity = -vector_up * 100
	p.ColorCode = self.ColorCode
	p.TrailWidth = 4
	p.TrailEnd = 1
	p.TrailLife = .1
	p:Spawn()
	p:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	p:SetModelScale(0.5)
end
