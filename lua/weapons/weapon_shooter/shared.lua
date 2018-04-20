
local ss = SplatoonSWEPs
if not ss then return end

SWEP.Base = "inklingbase"
SWEP.PrintName = "Shooter base"
function SWEP:SharedInit()
	self.NextPlayEmpty = CurTime()
	self.AimTimer = CurTime()
end

--Playing sounds
function SWEP:SharedPrimaryAttack(canattack)
	if not self.CrouchPriority then
		self:SetHoldType(self.HoldType)
		self.InklingSpeed = self.Primary.MoveSpeed
		if not self:GetOnEnemyInk() then self:SetPlayerSpeed(self.Primary.MoveSpeed) end
		self.AimTimer = CurTime() + self.Primary.AimDuration
		if SERVER then self:SetInk(math.max(0, self:GetInk() - self.Primary.TakeAmmo)) end
	end
	
	if self:GetInk() <= 0 then
		if CLIENT and self.PreviousInk then
			surface.PlaySound(ss.TankEmpty)
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
			self.PreviousInk = false
		elseif CurTime() > self.NextPlayEmpty then
			self:EmitSound "SplatoonSWEPs.EmptyShot"
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
		end
	elseif canattack then
		self:EmitSound(self.ShootSound)
		if CLIENT then self.PreviousInk = true end
	end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "ModifyWeaponSize") --Shooter expands its model when firing.
end

function SWEP:SharedThink()
	if self:GetPMID() == ss.PLAYER.NOSQUID and self.Owner:IsFlagSet(FL_DUCKING) then
		self:SetHoldType(self.HoldType)
	elseif self.AimTimer < CurTime() then
		self:SetHoldType "passive"
		self.InklingSpeed = self:GetInklingSpeed()
		if not (self:GetOnEnemyInk() or self:GetInInk()) then
			self:SetPlayerSpeed(self.InklingSpeed)
		end
	end
end
