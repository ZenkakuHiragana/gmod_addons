
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_shooter"
SWEP.IsSplatling = true
SWEP.FlashDuration = .25

local rand = "SplatoonSWEPs: Spread"
local randsplash = "SplatoonSWEPs: SplashNum"
function SWEP:GetChargeProgress(ping)
	local p = self.Parameters
	local ts = ss.GetTimeScale(self.Owner)
	local frac = CurTime() - self:GetCharge() - p.mMinChargeFrame / ts
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac / p.mSecondPeriodMaxChargeFrame * ts, 0, 1)
end

function SWEP:GetInitVelocity(nospread)
	local v
	local p = self.Parameters
	local prog = self:GetFireInk() > 0 and self:GetFireAt() or self:GetChargeProgress(CLIENT)
	if prog < self.MediumCharge then
		v = Lerp(prog / self.MediumCharge, p.mInitVelMinCharge, p.mInitVelFirstPeriodMaxCharge)
	else
		v = Lerp(prog - self.MediumCharge, p.mInitVelSecondPeriodMinCharge, p.mInitVelSecondPeriodMaxCharge)
	end

	if nospread then return v end
	local sgnv = math.Round(util.SharedRandom(rand, 0, 1, CurTime() * 7)) * 2 - 1
	local SelectIntervalV = self:GetBiasVelocity() > util.SharedRandom(rand, 0, 1, CurTime() * 8)
	local fracmin = SelectIntervalV and self:GetBias() or 0
	local fracmax = SelectIntervalV and 1 or self:GetBiasVelocity(), CurTime() * 9
	local frac = util.SharedRandom(rand, fracmin, fracmax)

	return v * (1 + sgnv * frac * p.mInitVelSpeedRateRandom)
end

function SWEP:GetRange()
	return self:GetInitVelocity(true) * (self.Parameters.mStraightFrame + ss.ShooterDecreaseFrame / 2)
end

function SWEP:GetSpreadAmount()
	local sx, sy = self:GetBase().GetSpreadAmount(self)
	return sx, (self.Parameters.mDegRandom + sy) / 2
end

function SWEP:ResetCharge()
	self:SetCharge(math.huge)
	self:SetFireInk(0)
	self.FullChargeFlag = false
	self.NotEnoughInk = false
	self.JumpPower = ss.InklingJumpPower
	if ss.mp and CLIENT and not IsFirstTimePredicted() then return end
	for _, s in ipairs(self.SpinupSound) do s:Stop() end
	self.AimSound:Stop()
end

SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p)
	p[#p + 1] = self.AimSound
	if not self.SpinupSound then return end
	for _, s in ipairs(self.SpinupSound) do p[#p + 1] = s end
end

function SWEP:PlayChargeSound()
	if ss.mp and CLIENT and not IsFirstTimePredicted() then return end
	local prog = self:GetChargeProgress(SERVER)
	if prog == 1 then
		self.AimSound:Stop()
		self.SpinupSound[1]:Stop()
		self.SpinupSound[2]:Stop()
		self.SpinupSound[3]:Play()
	elseif prog > 0 then
		self.AimSound:PlayEx(.75, math.max(self.AimSound:GetPitch(), prog * 90 + 1))
		self.SpinupSound[3]:Stop()
		if prog < self.MediumCharge then
			self.SpinupSound[1]:PlayEx(1, math.max(self.SpinupSound[2]:GetPitch(), 100 + prog * 25))
			self.SpinupSound[2]:Stop()
			self.SpinupSound[2]:ChangePitch(1)
		else
			prog = (prog - self.MediumCharge) / (1 - self.MediumCharge)
			self.SpinupSound[2]:PlayEx(1, math.max(self.SpinupSound[2]:GetPitch(), 80 + prog * 20))
			self.SpinupSound[1]:Stop()
			self.SpinupSound[1]:ChangePitch(1)
		end
	end
end

function SWEP:ShouldChargeWeapon()
	if self.Owner:IsPlayer() then
		return self.Owner:KeyDown(IN_ATTACK)
	else
		return CurTime() - self:GetCharge() < self.Parameters.mSecondPeriodMaxChargeFrame + .5
	end
end

function SWEP:SharedDeploy()
	self:SetSplashInitMul(1)
	self:GenerateSplashInitTable()
	self:ResetCharge()
end

function SWEP:SharedInit()
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.SpinupSound = {}
	self.SplashInitTable = {}
	for _, s in ipairs(self.ChargeSound) do
		self.SpinupSound[#self.SpinupSound + 1] = CreateSound(self, s)
	end

	local p = self.Parameters
	self.AirTimeFraction = 1 - 1 / p.mEmptyChargeTimes
	self.MediumCharge = (p.mFirstPeriodMaxChargeFrame - p.mMinChargeFrame) / (p.mSecondPeriodMaxChargeFrame - p.mMinChargeFrame)
	self.SpinupEffectTime = CurTime()
	self:SetAimTimer(CurTime())
	self:SharedDeploy()
	table.Merge(self.Projectile, {
		AirResist = 0.75,
		ColRadiusEntity = p.mColRadius,
		ColRadiusWorld = p.mColRadius,
		DamageMax = p.mDamageMax,
		DamageMaxDistance = p.mDamageMinFrame, -- Swapped from shooters
		DamageMin = p.mDamageMin,
		DamageMinDistance = p.mGuideCheckCollisionFrame, -- Swapped from shooters
		Gravity = 1 * ss.ToHammerUnitsPerSec2,
		PaintFarDistance = p.mPaintFarDistance,
		PaintFarRadius = p.mPaintFarRadius,
		PaintNearDistance = p.mPaintNearDistance,
		PaintNearRadius = p.mPaintNearRadius,
		SplashColRadius = p.mSplashColRadius,
		SplashLength = p.mCreateSplashLength,
		SplashPaintRadius = p.mSplashPaintRadius,
		StraightFrame = p.mStraightFrame,
	})
end

function SWEP:SharedPrimaryAttack()
	if not IsValid(self.Owner) then return end
	if self:GetCharge() < math.huge then -- Hold +attack to charge
		local p = self.Parameters
		local prog = self:GetChargeProgress(CLIENT)
		self:SetAimTimer(CurTime() + ss.AimDuration)
		self:SetReloadDelay(FrameTime())
		self:PlayChargeSound()
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, p.mJumpGnd_Charge)
		if prog == 0 then return end
		local EnoughInk = self:GetInk() >= prog * p.mInkConsume
		if not self.Owner:OnGround() or not EnoughInk then
			if EnoughInk or self:GetNWBool "canreloadstand" then
				self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
			else
				local ts = ss.GetTimeScale(self.Owner)
				local elapsed = prog * p.mSecondPeriodMaxChargeFrame / ts
				local min = p.mMinChargeFrame / ts
				local ping = CLIENT and self:Ping() or 0
				self:SetCharge(CurTime() + FrameTime() - elapsed - min + ping)
			end

			if (ss.sp or CLIENT) and not (self.NotEnoughInk or EnoughInk) then
				self.NotEnoughInk = true
				ss.EmitSound(self.Owner, ss.TankEmpty)
			end
		end
	else -- First attempt
		self.FullChargeFlag = false
		self.AimSound:PlayEx(0, 1)
		self.SpinupSound[1]:Play()
		self:SetAimTimer(CurTime() + ss.AimDuration)
		self:SetCharge(CurTime())
		self:SetWeaponAnim(ACT_VM_IDLE)
		ss.SetChargingEye(self)
	end
end

function SWEP:KeyPress(ply, key)
	if key == IN_JUMP then self:SetJump(CurTime()) end
	if not ss.KeyMaskFind[key] or key == IN_ATTACK then return end
	self:ResetCharge()
	self:SetCooldown(CurTime())
end

function SWEP:Move(ply)
	local p = self.Parameters
	if ply:IsPlayer() then
		if self:GetNWBool "toggleads" then
			if ply:KeyPressed(IN_USE) then
				self:SetADS(not self:GetADS())
			end
		else
			self:SetADS(ply:KeyDown(IN_USE))
		end
	end

	if ply:OnGround() and CurTime() - self:GetJump() < p.mDegJumpBiasFrame then
		self:SetJump(self:GetJump() - FrameTime() / 2)
	end

	if CurTime() > self:GetAimTimer() then
		ss.SetNormalEye(self)
	end

	if self:GetFireInk() > 0 then -- It's firing
		if not self:CheckCanStandup() then return end
		if self:GetThrowing() then return end
		if CLIENT and (ss.sp or not self:IsMine()) then return end
		if self:GetNextPrimaryFire() > CurTime() then return end

		local ts = ss.GetTimeScale(ply)
		local AlreadyAiming = CurTime() < self:GetAimTimer()
		local crouchdelay = math.min(p.mRepeatFrame, ss.CrouchDelay)
		self:CreateInk()
		self:SetNextPrimaryFire(CurTime() + p.mRepeatFrame / ts)
		self:SetAimTimer(CurTime() + ss.AimDuration)
		self:SetFireInk(self:GetFireInk() - 1)
		self:SetInk(math.max(0, self:GetInk() - self.TakeAmmo))
		self:SetReloadDelay(p.mInkRecoverStop)
		self:SetCooldown(math.max(self:GetCooldown(), CurTime() + crouchdelay / ts))

		if CurTime() - self:GetJump() > p.mDegJumpBiasFrame then
			if not AlreadyAiming then self:SetBiasVelocity(0) end
			self:SetBiasVelocity(math.min(self:GetBiasVelocity() + p.mDegBiasKf, p.mInitVelSpeedBias))
		end

		if not self:IsFirstTimePredicted() then return end
		local e = EffectData()
		e:SetEntity(self)
		ss.UtilEffectPredicted(ply, "SplatoonSWEPsSplatlingMuzzleFlash", e, true, self.IgnorePrediction)
	else -- Just released MOUSE1
		if self:GetCharge() == math.huge then return end
		if self:ShouldChargeWeapon() then return end
		if CurTime() - self:GetCharge() < p.mMinChargeFrame then return end
		local duration
		local prog = self:GetChargeProgress()
		local d1 = p.mFirstPeriodMaxChargeShootingFrame
		local d2 = p.mSecondPeriodMaxChargeShootingFrame
		if prog < self.MediumCharge then
			duration = d1 * prog / self.MediumCharge
		else
			local frac = (prog - self.MediumCharge) / (1 - self.MediumCharge)
			duration = Lerp(frac, d1, d2)
		end

		self:SetFireAt(prog)
		self:ResetCharge()
		self:SetFireInk(math.floor(duration / p.mRepeatFrame) + 1)
		self.TakeAmmo = p.mInkConsume * prog / self:GetFireInk()
		self.Projectile.Charge = prog
		self.Projectile.DamageMax = prog == 1 and p.mDamageMaxMaxCharge or p.mDamageMax
	end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Bias")
	self:AddNetworkVar("Float", "BiasVelocity")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
	self:AddNetworkVar("Float", "Jump")
	self:AddNetworkVar("Int", "FireInk")
	self:AddNetworkVar("Int", "SplashInitMul")
end

function SWEP:CustomMoveSpeed()
	if self:GetFireInk() > 0 then return self.Parameters.mMoveSpeed end
	if self:GetCharge() < math.huge then
		return Lerp(self:GetChargeProgress(), self.InklingSpeed, self.Parameters.mMoveSpeed_Charge)
	end
end

function SWEP:CustomActivity()
	local at = self:GetAimTimer()
	if CLIENT and self:IsCarriedByLocalPlayer() then at = at - self:Ping() end
	if CurTime() > at then return "crossbow" end
	local aimpos = select(3, self:GetFirePosition())
	return (aimpos == 3 or aimpos == 4) and "rpg" or "crossbow"
end

function SWEP:UpdateAnimation(ply, vel, max) end
