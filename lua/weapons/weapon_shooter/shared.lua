
SWEP.Base = "inklingbase"
SWEP.PrintName = "Shooter base"
SWEP.Spawnable = true
SWEP.FirePosition = Vector(6, -8, -8)

--Serverside: create ink projectile.
local function paint(self)
	local p = ents.Create("projectile_ink")
	if not IsValid(p) then return end
	local ang = self.Owner:GetAimVector():Angle()
	local delta_position = Vector(self.FirePosition)
	delta_position:Rotate(self.Owner:EyeAngles())
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	p:SetOwner(self.Owner)
	p:SetPhysicsAttacker(self.Owner)
	p:SetAngles(ang)
	p:SetPos(self.Owner:GetShootPos() + delta_position)
	p.InkColor = self:GetInkColorProxy()
	p:SetCurrentInkColor(self:GetCurrentInkColor())
	p.Damage = self.Damage
	p:Spawn()
	
	local ph = p:GetPhysicsObject()
	if not IsValid(ph) then p:Remove() return end
	ph:ApplyForceCenter(self.Owner:GetAimVector() * 100000)
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
