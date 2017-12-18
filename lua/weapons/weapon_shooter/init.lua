
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ServerInit()
	self.SplashInitMul = 0
	self:SetModifyWeaponSize(CurTime() - 1)
	self.AimTimer = self:AddSchedule(math.huge, 0, function(self, schedule)
		if schedule.disabled then return end
		schedule.disabled = true
		self:SetHoldType "passive"
		self:SetPlayerSpeed(SplatoonSWEPs.InklingBaseSpeed)
	end)
end

--Serverside: create ink projectile.
local function paint(self)
	self.SplashInitMul = self.SplashInitMul + 1
	
	local p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
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
	angle_initvelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	local mpdelta = -angle_initvelocity * SplatoonSWEPs.MPdt * 0
	p:SetPos(self.Owner:GetShootPos() + delta_position + mpdelta)
	p:SetAngles(ang)
	p:SetOwner(self.Owner)
	p:SetInkColorProxy(self:GetInkColorProxy())
	p.Damage = self.Primary.Damage
	p.MinDamage = self.Primary.MinDamage
	p.MinDamageTime = self.Primary.MinDamageTime
	p.DecreaseDamage = self.Primary.DecreaseDamage
	p.InkRadius = self.Primary.InkRadius
	p.MinRadius = self.Primary.MinRadius
	p.SplashRadius = self.Primary.SplashRadius
	p.SplashPatterns = self.Primary.SplashPatterns
	p.SplashNum = math[math.random() < 0.5 and "floor" or "ceil"](self.Primary.SplashNum)
	p.SplashInterval = self.Primary.SplashInterval
	p.SplashInitMul = self.SplashInitMul % self.Primary.SplashPatterns
	p.Straight = self.Primary.Straight
	p.InitVelocity = angle_initvelocity
	p.ColorCode = self.ColorCode
	p:Spawn()
end

function SWEP:ServerPrimaryAttack(canattack)
	if not canattack then return end
	self:SetHoldType(self.HoldType)
	paint(self)
	if self.Owner:IsPlayer() then
		self.AimTimer:SetDelay(self.Primary.CrouchDelay)
		self.AimTimer.disabled = false
		self:SetModifyWeaponSize(CurTime()) --Expand weapon model
		self:SetInk(self:GetInk() - self.Primary.TakeAmmo)
		self:SetPlayerSpeed(self.Primary.MoveSpeed)
	end
end
