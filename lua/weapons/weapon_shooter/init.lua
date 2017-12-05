
-- AddCSLuaFile "../inklingbase/baseinfo.lua"
AddCSLuaFile "shared.lua"
-- include "../inklingbase/baseinfo.lua"
include "shared.lua"

function SWEP:ServerInit()
	self:SetModifyWeaponSize(CurTime() - 1)
	self.AimTimer = self:AddSchedule(100000, 0, function(self, schedule)
		if schedule.disabled then return end
		schedule.disabled = true
		self:SetHoldType "passive"
	end)
end

--Serverside: create ink projectile.
local function paint(self)
	local p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
	local aim = IsValid(self.Owner) and self.Owner:GetAimVector() or self:GetForward()
	local ang = aim:Angle()
	local delta_position = Vector(self.FirePosition)
	delta_position:Rotate(self.Owner:EyeAngles())
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	p:SetOwner(self.Owner)
	p:SetPhysicsAttacker(self.Owner)
	p:SetAngles(ang)
	p:SetPos(self.Owner:GetShootPos() + delta_position)
	p:SetColorCode(self.ColorCode or 1)
	p.InkColor = self:GetInkColorProxy()
	p.Damage = self.Damage
	p:Spawn()
	
	local vel = self.Owner:GetAimVector() * 1000
	local ph = p:GetPhysicsObject()
	if not IsValid(ph) then p:Remove() return end
	ph:SetVelocityInstantaneous(vel)
end

function SWEP:ServerPrimaryAttack(canattack)
	if not canattack then return end
	self:SetHoldType(self.HoldType)
	paint(self)
	if self.Owner:IsPlayer() then
		self.AimTimer:SetDelay(self.Primary.Delay * 5)
		self.AimTimer.disabled = false
		self:SetModifyWeaponSize(CurTime()) --Expand weapon model
		self:SetInk(self:GetInk() - self.Primary.TakeAmmo)
	end
end
