
local ss = SplatoonSWEPs
if not ss then return end

SWEP.Base = "inklingbase"
SWEP.PrintName = "Shooter base"
function SWEP:GetFirePosition()
	local pos = Vector(self.Primary.FirePosition)
	if IsValid(self.Owner) then
		pos:Rotate(self.Owner:EyeAngles())
	end
	
	return pos
end

function SWEP:SharedInit()
	self.NextPlayEmpty = CurTime()
	self:SetModifyWeaponSize(CurTime() - 1)
	self:SetAimTimer(CurTime())
	
	if not self.Primary.TripleShotDelay then return end
	self:SetTripleShot(0)
end

--Playing sounds
function SWEP:SharedPrimaryAttack(canattack)
	if not self.CrouchPriority or CLIENT and LocalPlayer() ~= self.Owner then
		self:SetHoldType(self.HoldType)
		self.InklingSpeed = self.Primary.MoveSpeed
		if not self:GetOnEnemyInk() then self:SetPlayerSpeed(self.Primary.MoveSpeed) end
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
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
		self:SetModifyWeaponSize(CurTime())
		if SERVER or IsFirstTimePredicted() then self:EmitSound(self.ShootSound) end
		if CLIENT then self.PreviousInk = true end
		
		if not (self.Primary.TripleShotDelay and (SERVER or IsFirstTimePredicted())) then return end
		if self:GetTripleShot() > 0 then
			if self:GetTripleShot() > 1 then
				local laggedvalue = self.Owner:IsPlayer() and self.Owner:GetLaggedMovementValue() or 1
				self:SetNextPrimaryFire(CurTime() + self.Primary.TripleShotDelay / laggedvalue)
				self:SetNextCrouchTime(CurTime() + self.Primary.TripleShotDelay / laggedvalue)
				if SERVER then self:SetTripleShot(0) end
			elseif SERVER then
				self:SetTripleShot(2)
			end
		else
			if SERVER then self:SetTripleShot(1) end
			self:AddSchedule(self:GetNextPrimaryFire() - CurTime(), 2, function(self, schedule)
				self:PrimaryAttack()
			end)
		end
	end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "ModifyWeaponSize") --Shooter expands its model when firing.
	self:AddNetworkVar("Float", "AimTimer")
	
	if not self.Primary.TripleShotDelay then return end
	self:AddNetworkVar("Int", "TripleShot") --Shooting counter for Nozzlenoses.
end

function SWEP:SharedThink()
	if self.Owner:IsFlagSet(FL_DUCKING) then
		self:SetHoldType(self.HoldType)
	elseif self.Owner:IsPlayer() and self:GetAimTimer() < CurTime() then
		self:SetHoldType "passive"
		self.InklingSpeed = self:GetInklingSpeed()
		if not (self:GetOnEnemyInk() or self:GetInInk()) then
			self:SetPlayerSpeed(self.InklingSpeed)
		end
	end
end
