
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"

function SWEP:GetFOV()
	return self.ScopedFOV or self.Owner:GetFOV()
end

function SWEP:TranslateFOV(fov)
	fov = fov or self.Owner:GetFOV()
	self.ScopedFOV = nil
	if not self.Scoped then return end
	local frac = self:GetScopedProgress(CLIENT)
	if frac == 0 then return end
	self.ScopedFOV = Lerp(frac, fov, self.Primary.Scope.FOV)
	return self.ScopedFOV
end

function SWEP:GetLerp(frac, min, max, full)
	return frac < 1 and Lerp(frac, min, max) or full or max
end

function SWEP:GetColRadius()
	return self:GetLerp(self:GetChargeProgress(), self.Primary.MinColRadius, self.Primary.ColRadius)
end

function SWEP:GetRange()
	return self:GetLerp(self:GetChargeProgress(CLIENT), self.Primary.MinRange, self.Primary.MaxRange, self.Primary.Range)
end

function SWEP:GetInkVelocity()
	return self:GetLerp(self:GetChargeProgress(), self.Primary.MinVelocity, self.Primary.MaxVelocity, self.Primary.InitVelocity)
end

function SWEP:GetChargeProgress(ping)
	local frac = CurTime() - self:GetCharge()
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac	/ self.Primary.MaxChargeTime, 0, 1)
end

function SWEP:GetScopedProgress(ping)
	if not self.Scoped then return 0 end
	if CLIENT and GetViewEntity() ~= self.Owner then return 0 end
	local prog = self:GetChargeProgress(ping)
	local scope = self.Primary.Scope
	if prog < scope.StartMove then return 0 end
	return math.Clamp((prog - scope.StartMove)
		/ (scope.EndMove - scope.StartMove), 0, 1)
end

function SWEP:ResetCharge()
	self:SetCharge(math.huge)
	self:SetFullChargeFlag(false)
	self.JumpPower = ss.InklingJumpPower
	if ss.mp and SERVER then return end
	self.AimSound:Stop()
	self.AimSound:ChangePitch(1)
end

SWEP.SharedDeploy = SWEP.ResetCharge
SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p) table.insert(p, self.AimSound) end
function SWEP:PlayChargeSound()
	local prog = self:GetChargeProgress()
	if 0 < prog and prog < 1 then
		self.AimSound:PlayEx(1, math.max(self.AimSound:GetPitch(), prog * 99 + 1))
	else
		self.AimSound:Stop()
		self.AimSound:ChangePitch(1)
		if prog == 1 and not self:GetFullChargeFlag() then
			if ss.mp and CLIENT then
				surface.PlaySound(ss.ChargerBeep)
			else
				self.Owner:SendLua "surface.PlaySound(SplatoonSWEPs.ChargerBeep)"
			end
		end
	end
end

function SWEP:SharedInit()
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.AirTimeFraction = 1 - 1 / self.Primary.EmptyChargeMul
	self:SetAimTimer(CurTime())
	self:ResetCharge()
end

function SWEP:SharedPrimaryAttack()
	if not IsValid(self.Owner) then return end
	if self:GetCharge() < math.huge then
		local prog = self:GetChargeProgress()
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, self.Primary.JumpPower)
		if ss.sp or CLIENT and self:IsFirstTimePredicted() then self:PlayChargeSound() end
		if prog == 0 then return end
		local EnoughInk = self:GetInk() >= prog * self.Primary.TakeAmmo
		if not self.Owner:OnGround() or not EnoughInk then
			self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
			if not (self.NotEnoughInk or EnoughInk) then
				self.NotEnoughInk = true
				if CLIENT then
					if ss.mp then
						if IsFirstTimePredicted() and self:IsCarriedByLocalPlayer() then
							surface.PlaySound(ss.TankEmpty)
						end
					else
						self.Owner:SendLua "surface.PlaySound(SplatoonSWEPs.TankEmpty)"
					end
				end
			end
		end
		
		if prog == 1 and not self:GetFullChargeFlag() then
			self:SetFullChargeFlag(true)
		end
		
		return
	end
	
	if CurTime() > self:GetAimTimer() then
		self:SetSplashInitMul(0)
	end
	
	self.AimSound:PlayEx(0, 1)
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetCharge(CurTime())
	self:SetFullChargeFlag(false)
	
	if not self:IsFirstTimePredicted() then return end
	local e = EffectData() e:SetEntity(self)
	util.Effect("SplatoonSWEPsChargerLaser", e)
	self:EmitSound "SplatoonSWEPs.ChargerPreFire"
end

function SWEP:KeyPress(ply, key)
	if key == IN_ATTACK then return end
	self:ResetCharge()
	self:SetCooldown(CurTime())
end

function SWEP:Move(ply, mv)
	if ply:KeyDown(IN_ATTACK) or self:GetCharge() == math.huge then return end
	if CurTime() - self:GetCharge() < self.Primary.MinChargeTime then return end
	local prog = self:GetChargeProgress()
	local ShootSound = prog > .75 and self.ShootSound2 or self.ShootSound
	local pitch = 100 + (prog > .75 and 15 or 0)
	local pos, dir = self:GetFirePosition()
	self.SplashInit = self:GetSplashInitMul() % self.Primary.SplashPatterns
	self.Range = self:GetRange()
	self.InitVelocity = dir * self:GetInkVelocity()
	self.InitAngle = dir:Angle()
	self.NotEnoughInk = false
	if self:IsFirstTimePredicted() then
		local rnda = self.Primary.Recoil * -1
		local rndb = self.Primary.Recoil * math.Rand(-1, 1)
		self.ViewPunch = Angle(rnda, rndb, rnda)
		self.ModifyWeaponSize = SysTime()
		
		local e = EffectData()
		e:SetAttachment(self.SplashInit)
		e:SetAngles(self.InitAngle)
		e:SetColor(self:GetNWInt "ColorCode")
		e:SetEntity(self)
		e:SetFlags(CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0)
		e:SetOrigin(pos)
		e:SetScale(self.Range)
		e:SetStart(self.InitVelocity)
		e:SetRadius(0)
		e:SetMagnitude(prog)
		util.Effect("SplatoonSWEPsShooterInk", e)
		ss.AddInk(ply, pos, ss.GetDropType())
	end
	
	self:EmitSound(ShootSound, 80, pitch - prog * 20)
	self:SetCooldown(CurTime() + self.Primary.MinChargeTime)
	self:SetFireAt(prog)
	self:SetInk(math.max(0, self:GetInk() - prog * self.Primary.TakeAmmo))
	self:SetSplashInitMul(self:GetSplashInitMul() + 1)
	self:ResetCharge()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:ResetSequence "fire"
	ply:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "FullChargeFlag")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
	self:AddNetworkVar("Int", "SplashInitMul")
end

function SWEP:CustomMoveSpeed()
	return self:GetKey() == IN_ATTACK and Lerp(self:GetChargeProgress(),
	self.InklingSpeed, self.Primary.MoveSpeed) or self.InklingSpeed
end

function SWEP:GetAnimWeight()
	return (self:GetFireAt() + .5) / 1.5
end
