
SWEP.Base = "inklingbase"
SWEP.PrintName = "Shooter base"
SWEP.Spawnable = true

--Serverside: create ink projectile.
local function paint(self)
	
end

function SWEP:CustomDeploy()
end

function SWEP:CustomHolster()
end

function SWEP:FirstPredictedThink(issquid)
	if CurTime() > self:GetAimingDuration() then
		self:SetHoldType("passive")
	else
		self:SetHoldType(self.HoldType)
	end
end

function SWEP:CustomPrimaryAttack(canattack)
	self:SetAimingDuration(CurTime() + self.Primary.Delay * 5)
	
	if SERVER and canattack then
		self:SetModifyWeaponSize(CurTime()) --Expand weapon model
		self:SetInk(self:GetInk() - self.Primary.TakeAmmo)
		paint(self)
	end
end

function SWEP:CustomSecondaryAttack(canattack)
end

function SWEP:CustomDataTables()
	self:NetworkVar("Float", 4, "AimingDuration") --Passive when owner is not firing wrapon.
	self:NetworkVar("Float", 5, "ModifyWeaponSize") --Shooter expands its model when firing.
	self:SetAimingDuration(CurTime())
	self:SetModifyWeaponSize(CurTime() - 1)
end
