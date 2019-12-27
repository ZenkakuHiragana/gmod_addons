
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_shooter"
SWEP.IsCharger = true
SWEP.FlashDuration = .25

function SWEP:GetColRadius()
	return Lerp(self:GetChargeProgress(CLIENT),
		self.Parameters.mMinChargeColRadiusForPlayer,
		self.Parameters.mMaxChargeColRadiusForPlayer)
end

function SWEP:GetDamage(ping)
	return ss.Lerp3(
		self:GetChargeProgress(ping),
		self.Parameters.mMinChargeDamage,
		self.Parameters.mMaxChargeDamage,
		self.Parameters.mFullChargeDamage)
end

function SWEP:GetRange(ping)
	if self.Scoped then
		return ss.Lerp3(
			self:GetChargeProgress(ping),
			self.Parameters.mMinDistance,
			self.Parameters.mMaxDistanceScoped,
			self.Parameters.mFullChargeDistanceScoped)
	else
		return ss.Lerp3(
			self:GetChargeProgress(ping),
			self.Parameters.mMinDistance,
			self.Parameters.mMaxDistance,
			self.Parameters.mFullChargeDistance)
	end
end

function SWEP:GetInkVelocity()
	return ss.Lerp3(
		self:GetChargeProgress(),
		self.Parameters.mInitVelL,
		self.Parameters.mInitVelH,
		self.Parameters.mInitVelF)
end

function SWEP:GetChargeProgress(ping)
	local ts = ss.GetTimeScale(self.Owner)
	local frac = CurTime() - self:GetCharge() - self.Parameters.mMinChargeFrame / ts
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac / self.Parameters.mMaxChargeFrame * ts, 0, 1)
end

function SWEP:GetScopedProgress(ping)
	if not self.Scoped then return 0 end
	if CLIENT and GetViewEntity() ~= self.Owner then return 0 end
	local prog = self:GetChargeProgress(ping)
	local p = self.Parameters
	local startmove = p.mSniperCameraMoveStartChargeRate
	local endmove = p.mSniperCameraMoveEndChargeRate
	if prog < startmove then return 0 end
	return math.Clamp((prog - startmove) / (endmove - startmove), 0, 1)
end

function SWEP:ResetCharge()
	self:SetCharge(math.huge)
	self.FullChargeFlag = false
	self.NotEnoughInk = false
	self.JumpPower = ss.InklingJumpPower
	if ss.mp and SERVER then return end
	self.AimSound:Stop()
	self.AimSound:ChangePitch(1)
end

SWEP.SharedDeploy = SWEP.ResetCharge
SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p) p[#p + 1] = self.AimSound end
function SWEP:PlayChargeSound()
	if ss.mp and (SERVER or not IsFirstTimePredicted()) then return end
	local prog = self:GetChargeProgress()
	if not (ss.sp and SERVER and not self.Owner:IsPlayer()) and 0 < prog and prog < 1 then
		self.AimSound:PlayEx(1, math.max(self.AimSound:GetPitch(), prog * 99 + 1))
	else
		self.AimSound:Stop()
		self.AimSound:ChangePitch(1)
	end
end

function SWEP:ShouldChargeWeapon()
	if self.Owner:IsPlayer() then
		return self.Owner:KeyDown(IN_ATTACK)
	else
		return CurTime() - self:GetCharge() < self.Parameters.mMaxChargeFrame * 2
	end
end

function SWEP:SharedInit()
	local p = self.Parameters
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.AirTimeFraction = 1 - 1 / p.mEmptyChargeTimes
	self:SetAimTimer(CurTime())
	self:ResetCharge()
	self:AddSchedule(0, function()
		local prog = self:GetChargeProgress()
		if prog == 1 and not self.FullChargeFlag then
			if CLIENT then
				self.CrosshairFlashTime = CurTime() - self:Ping()
				ss.EmitSound(self.Owner, ss.ChargerBeep)
			end

			self.FullChargeFlag = true
			if self.Scoped and self:IsMine() and not (CLIENT and self:IsTPS() and self:GetNWBool "usertscope") then return end
			local e = EffectData()
			e:SetEntity(self)
			e:SetFlags(0)
			ss.UtilEffectPredicted(self.Owner, "SplatoonSWEPsMuzzleFlash", e)
			return
		end

		self.FullChargeFlag = prog == 1
	end)

	table.Merge(self.Projectile, {
		AirResist = 1,
		Gravity = 1 * ss.ToHammerUnitsPerSec2,
		SplashColRadius = p.mSplashColRadius,
	})
end

function SWEP:SharedPrimaryAttack()
	local p = self.Parameters
	if not IsValid(self.Owner) then return end
	
	self:SetReloadDelay(p.mInkRecoverStop)
	if self:GetCharge() < math.huge then -- Hold +attack to charge
		local prog = self:GetChargeProgress()
		self:SetAimTimer(CurTime() + ss.AimDuration)
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, p.mJumpGnd)
		if prog > 0 then
			local EnoughInk = self:GetInk() >= prog * p.mInkConsume
			if not self.Owner:OnGround() or not EnoughInk then
				if EnoughInk or self:GetNWBool "canreloadstand" then
					self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
				else
					local ts = ss.GetTimeScale(self.Owner)
					local elapsed = prog * p.mMaxChargeFrame / ts
					local min = p.mMinChargeFrame / ts
					local ping = CLIENT and self:Ping() or 0
					self:SetCharge(CurTime() + FrameTime() - elapsed - min)
				end

				if (ss.sp or CLIENT) and not (self.NotEnoughInk or EnoughInk) then
					self.NotEnoughInk = true
					ss.EmitSound(self.Owner, ss.TankEmpty)
				end
			end
		end

		self:PlayChargeSound()
	else -- First attempt
		if CurTime() > self:GetAimTimer() then
			self:SetSplashInitMul(0)
		end

		self.FullChargeFlag = false
		self.AimSound:PlayEx(0, 1)
		self:SetAimTimer(CurTime() + ss.AimDuration)
		self:SetCharge(CurTime())
		self:SetWeaponAnim(ACT_VM_IDLE)
		ss.SetChargingEye(self)

		if not self:IsFirstTimePredicted() then return end
		local e = EffectData()
		e:SetEntity(self)
		util.Effect("SplatoonSWEPsChargerLaser", e, true, self.IgnorePrediction)
		self:EmitSound "SplatoonSWEPs.ChargerPreFire"
	end
end

function SWEP:KeyPress(ply, key)
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

	if CurTime() > self:GetAimTimer() then -- It's no longer aiming
		ss.SetNormalEye(self)
	end

	if self:GetCharge() == math.huge then return end
	if self:ShouldChargeWeapon() then return end
	if CurTime() - self:GetCharge() < p.mMinChargeFrame then return end

	local prog = self:GetChargeProgress()
	local inkconsume = math.max(p.mMinChargeFrame / p.mMaxChargeFrame, prog) * p.mInkConsume
	local ShootSound = prog > .75 and self.ShootSound2 or self.ShootSound
	local pitch = (prog > .75 and 115 or 100) - prog * 20
	local pos, dir = self:GetFirePosition()
	local ang = dir:Angle()
	local colradius = self:GetColRadius()
	local initspeed = self:GetInkVelocity()
	local maxrate = p.mSplashBetweenMaxSplashPaintRadiusRate
	local minrate = p.mSplashBetweenMinSplashPaintRadiusRate
	local maxratio = p.mSplashDepthMaxChargeScaleRateByWidth
	local minratio = p.mSplashDepthMinChargeScaleRateByWidth
	local maxwallnum = p.mMaxChargeHitSplashNum
	local minwallnum = p.mMinChargeHitSplashNum
	local paintmaxradius = p.mMaxChargeSplashPaintRadius
	local paintratio = Lerp(prog, p.mPaintNearR_WeakRate, 1)
	local paintradius = paintratio * paintmaxradius
	local ratio = Lerp(prog, minratio, maxratio)
	local range = self:GetRange()
	local _, splashrate = math.modf(self:GetSplashInitMul() / p.mSplashSplitNum)
	local wallpaintradius = paintradius / p.mPaintRateLastSplash
	local wallfrac = prog / p.mMaxHitSplashNumChargeRate
	
	table.Merge(self.Projectile, {
		Charge = prog,
		Color = self:GetNWInt "inkcolor",
		ColRadiusEntity = colradius,
		ColRadiusWorld = colradius,
		DamageMax = self:GetDamage(),
		DamageMin = 0,
		ID = CurTime() + self:EntIndex(),
		InitPos = pos,
		InitVel = dir * initspeed,
		IsCritical = not self.IsBamboozler and prog == 1,
		PaintFarRadius = paintradius,
		PaintFarRatio = ratio,
		PaintNearRadius = paintradius,
		PaintNearRatio = ratio,
		Range = range,
		SplashInitRate = splashrate,
		SplashLength = Lerp(prog, maxrate, minrate) * paintradius * ratio,
		SplashNum = math.huge,
		SplashPaintRadius = paintradius,
		SplashRatio = ratio,
		StraightFrame = range / initspeed,
		Type = ss.GetDropType(),
		WallPaintFirstLength = wallpaintradius,
		WallPaintLength = wallpaintradius,
		WallPaintMaxNum = math.Round(Lerp(wallfrac, minwallnum, maxwallnum)),
		WallPaintRadius = wallpaintradius,
		Yaw = self:GetAimVector():Angle().yaw,
	})
	
	if self:IsFirstTimePredicted() then
		local Recoil = 0.2
		local rnda = Recoil * -1
		local rndb = Recoil * math.Rand(-1, 1)
		self.ViewPunch = Angle(rnda, rndb, rnda)
		self.ModifyWeaponSize = SysTime()

		local e = EffectData()
		ss.SetEffectColor(e, self.Projectile.Color)
		ss.SetEffectColRadius(e, self.Projectile.ColRadiusWorld)
		ss.SetEffectDrawRadius(e, p.mDrawRadius) -- Shooter's default value
		ss.SetEffectEntity(e, self)
		ss.SetEffectFlags(e, self)
		ss.SetEffectInitPos(e, self.Projectile.InitPos)
		ss.SetEffectInitVel(e, self.Projectile.InitVel)
		ss.SetEffectSplash(e, Angle(self.Projectile.SplashColRadius, p.mSplashDrawRadius, self.Projectile.SplashLength))
		ss.SetEffectSplashInitRate(e, Vector(self.Projectile.SplashInitRate))
		ss.SetEffectSplashNum(e, self.Projectile.SplashNum)
		ss.SetEffectStraightFrame(e, self.Projectile.StraightFrame)
		ss.UtilEffectPredicted(ply, "SplatoonSWEPsShooterInk", e, true, self.IgnorePrediction)
		ss.AddInk(p, self.Projectile)
	end

	ss.EmitSoundPredicted(ply, self, ShootSound, 80, pitch)
	self:SetCooldown(CurTime())
	self:SetFireAt(prog)
	self:SetInk(math.max(0, self:GetInk() - inkconsume))
	self:SetSplashInitMul(self:GetSplashInitMul() + 1)
	self:ResetCharge()
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)

	ss.SuppressHostEventsMP(ply)
	self:ResetSequence "fire" -- This is needed in multiplayer to prevent delaying muzzle effects.
	ply:SetAnimation(PLAYER_ATTACK1)
	ss.EndSuppressHostEventsMP(ply)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
	self:AddNetworkVar("Int", "SplashInitMul")
	if not self.Scoped then return end

	local getads = self.GetADS
	local startmove = self.Parameters.mSniperCameraMoveStartChargeRate
	function self:GetADS(org)
		if org then return getads(self) end
		return getads(self) or self:GetChargeProgress() > startmove
	end
end

function SWEP:CustomMoveSpeed()
	if self:GetKey() ~= IN_ATTACK then return end
	return Lerp(self:GetChargeProgress(), self.InklingSpeed, self.Parameters.mMoveSpeed)
end

function SWEP:GetAnimWeight()
	return (self:GetFireAt() + .5) / 1.5
end
