
-- Functions for weapon settings.

local ss = SplatoonSWEPs
if not ss then return end

function ss.SetChargingEye(self)
	local ply = self.Owner
	local mdl = ply:GetModel()
	local skin = ss.ChargingEyeSkin[mdl]
	if skin and ply:GetSkin() ~= skin then
		ply:SetSkin(skin)
	elseif ss.TwilightPlayermodels[mdl] then
		-- Eye animation for Twilight's Octoling playermodel
		local l = ply:GetFlexIDByName "Blink_L"
		local r = ply:GetFlexIDByName "Blink_R"
		if l then ply:SetFlexWeight(l, .3) end
		if r then ply:SetFlexWeight(r, 1) end
	end
end

function ss.SetNormalEye(self)
	local ply = self.Owner
	local mdl = ply:GetModel()
	local f = ply:GetFlexIDByName "Blink_R"
	local IsTwilightModel = ss.TwilightPlayermodels[mdl]
	local skin = ss.ChargingEyeSkin[mdl]
	if skin and ply:GetSkin() == skin then
		local s = 0
		if self:GetNWInt "playermodel" == ss.PLAYER.NOCHANGE then
			if CLIENT then
				s = GetConVar "cl_playerskin":GetInt()
			else
				s = self.BackupPlayerInfo.Playermodel.Skin
			end
		end

		if ply:GetSkin() == s then return end
		ply:SetSkin(s)
	elseif IsTwilightModel and f and ply:GetFlexWeight(f) == 1 then
		local l = ply:GetFlexIDByName "Blink_L"
		local r = ply:GetFlexIDByName "Blink_R"
		if l then ply:SetFlexWeight(l, 0) end
		if r then ply:SetFlexWeight(r, 0) end
	end
end

function ss.MakeProjectileStructure()
	return { -- Used in ss.AddInk(), describes how a projectile is.
		Charge = nil,
		Color = 1,
		ColRadiusEntity = 1,
		ColRadiusWorld = 1,
		DoDamage = true,
		DamageMax = nil,
		DamageMaxDistance = nil,
		DamageMin = nil,
		DamageMinDistance = nil,
		InitDir = Vector(),
		InitPos = Vector(),
		InitSpeed = 0,
		InitVel = Vector(),
		IsCharger = nil,
		PaintFarDistance = nil,
		PaintFarRadius = 0,
		PaintNearDistance = nil,
		PaintNearRadius = 0,
		Range = nil,
		SplashCount = 0,
		SplashInit = 0,
		SplashNum = 0,
		StraightFrame = 0,
		Type = 1,
		Weapon = NULL,
		Yaw = 0,
	}
end

function ss.MakeInkQueueTraceStructure()
	return {
		endpos = Vector(),
		filter = NULL,
		LengthSum = 0,
		LifeTime = 0,
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * 1,
		mins = ss.vector_one * -1,
		start = Vector(),
	}
end

function ss.MakeInkQueueStructure()
	return {
		Color = 1,
		Data = {},
		InitTime = CurTime(),
		IsCarriedByLocalPlayer = false,
		Parameters = {},
		Trace = ss.MakeInkQueueTraceStructure(),
	}
end

function ss.SetPrimary(weapon, parameters)
	local maxink = ss.GetMaxInkAmount()
	ss.ProtectedCall(ss.DefaultParams[weapon.Base], weapon)
	weapon.Primary = {
		Ammo = "Ink",
		Automatic = true,
		ClipSize = maxink,
		DefaultClip = maxink,
	}

	table.Merge(weapon.Parameters, parameters or {})
	for name, value in pairs(weapon.Parameters) do
		if isnumber(value) then
			local units = ss.Units[name]
			local converter = units and ss.UnitsConverter[units] or 1
			weapon.Parameters[name] = value * converter
		end
	end

	ss.ProtectedCall(ss.CustomPrimary[weapon.Base], weapon)
end

ss.DefaultParams = {}
ss.CustomPrimary = {}
function ss.DefaultParams.weapon_splatoonsweps_shooter(weapon)
	weapon.Parameters = {
		mRepeatFrame = 6,
		mTripleShotSpan = 0,
		mInitVel = 22,
		mDegRandom = 6,
		mDegJumpRandom = 15,
		mSplashSplitNum = 5,
		mKnockBack = 0,
		mInkConsume = 0.009,
		mInkRecoverStop = 20,
		mMoveSpeed = 0.72,
		mDamageMax = 0.35,
		mDamageMin = 0.175,
		mDamageMinFrame = 15,
		mStraightFrame = 4,
		mGuideCheckCollisionFrame = 8,
		mCreateSplashNum = 2,
		mCreateSplashLength = 75,
		mDrawRadius = 2.5,
		mColRadius = 2,
		mPaintNearDistance = 11,
		mPaintFarDistance = 200,
		mPaintNearRadius = 19.2,
		mPaintFarRadius = 18,
		mSplashDrawRadius = 3,
		mSplashColRadius = 1.5,
		mSplashPaintRadius = 13,
		mArmorTypeGachihokoDamageRate = 1,
		mDegBias = 0.25,
		mDegBiasKf = 0.02,
		mDegJumpBias = 0.4,
		mDegJumpBiasFrame = 60,
	}
end

function ss.CustomPrimary.weapon_splatoonsweps_shooter(weapon)
	local p = weapon.Parameters
	weapon.NPCDelay = p.mRepeatFrame
	weapon.Range = p.mInitVel * (p.mStraightFrame + ss.ShooterDecreaseFrame / 2)
	weapon.Primary.Automatic = p.mTripleShotSpan == 0
end

function ss.DefaultParams.weapon_splatoonsweps_blaster_base(weapon)
	ss.DefaultParams.weapon_splatoonsweps_shooter(weapon)
	table.Merge(weapon.Parameters, {
		mExplosionFrame = 13,
		mExplosionSleep = true,
		mDamageNear = 0.8,
		mCollisionRadiusNear = 10,
		mDamageMiddle = 0.65,
		mCollisionRadiusMiddle = 18,
		mDamageFar = 0.5,
		mCollisionRadiusFar = 37.5,
		mShotCollisionHitDamageRate = 0.5,
		mShotCollisionRadiusRate = 0.5,
		mKnockBackRadius = 37.5,
		mMoveLength = 23.5,
		mSphereSplashDropOn = true,
		mSphereSplashDropInitSpeed = 0,
		mSphereSplashDropCollisionRadius = 4,
		mSphereSplashDropDrawRadius = 6,
		mSphereSplashDropPaintRadius = 34,
		mSphereSplashDropPaintShotCollisionHitRadius = 22,
		mBoundPaintMaxRadius = 25,
		mBoundPaintMinRadius = 20,
		mBoundPaintMinDistanceXZ = 90,
		mWallHitPaintRadius = 20,
		mPreDelayFrm_HumanMain = 10,
		mPreDelayFrm_SquidMain = 15,
		mPostDelayFrm_Main = 30,
	})
end

function ss.CustomPrimary.weapon_splatoonsweps_blaster_base(weapon)
	ss.CustomPrimary.weapon_splatoonsweps_shooter(weapon)
end

function ss.DefaultParams.weapon_splatoonsweps_splatling(weapon)
	ss.DefaultParams.weapon_splatoonsweps_shooter(weapon)
	table.Merge(weapon.Parameters, {
		mMinChargeFrame = 8,
		mFirstPeriodMaxChargeFrame = 108,
		mSecondPeriodMaxChargeFrame = 135,
		mFirstPeriodMaxChargeShootingFrame = 108,
		mSecondPeriodMaxChargeShootingFrame = 216,
		mWaitShootingFrame = 0,
		mEmptyChargeTimes = 3,
		mInitVelMinCharge = 10.5,
		mInitVelFirstPeriodMaxCharge = 24,
		mInitVelSecondPeriodMinCharge = 24,
		mInitVelSecondPeriodMaxCharge = 24,
		mDamageMaxMaxCharge = 0.35,
		mMoveSpeed_Charge = 0.4,
		mVelGnd_DownRt_Charge = 0.05,
		mVelGnd_Bias_Charge = 0.9,
		mJumpGnd_Charge = 0.6,
		mInitVelSpeedRateRandom = 0.14,
		mInitVelSpeedBias = 0.2,
		mInitVelDegRandom = 2,
		mInitVelDegBias = 0.4,
		mPaintDepthScaleBias = 1.2,
	})
end

function ss.CustomPrimary.weapon_splatoonsweps_splatling(weapon)
	local p = weapon.Parameters
	ss.CustomPrimary.weapon_splatoonsweps_shooter(weapon)
	weapon.Range = p.mInitVelSecondPeriodMaxCharge * (p.mStraightFrame + ss.ShooterDecreaseFrame / 2)
end

function ss.DefaultParams.weapon_splatoonsweps_charger(weapon)
	ss.DefaultParams.weapon_splatoonsweps_shooter(weapon)
	table.Merge(weapon.Parameters, {
		mMinDistance = 90,
		mMaxDistance = 200,
		mMaxDistanceScoped = 200,
		mFullChargeDistance = 260,
		mFullChargeDistanceScoped = 286,
		mMinChargeFrame = 8,
		mMaxChargeFrame = 60,
		mEmptyChargeTimes = 3,
		mFreezeFrmL = 1,
		mInitVelL = 12,
		mFreezeFrmH = 1,
		mInitVelH = 35.29,
		mInitVelF = 48,
		mInkConsume = 0.18,
		mMoveSpeed = 0.2,
		mVelGnd_DownRt = 0.2,
		mVelGnd_Bias = 0.5,
		mJumpGnd = 0.7,
		mMaxChargeSplashPaintRadius = 18.5,
		mPaintNearR_WeakRate = 0.45,
		mPaintRateLastSplash = 1.6,
		mMinChargeDamage = 0.4,
		mMaxChargeDamage = 1,
		mFullChargeDamage = 1.6,
		mSplashBetweenMaxSplashPaintRadiusRate = 1.58,
		mSplashBetweenMinSplashPaintRadiusRate = 1.32,
		mSplashDepthMinChargeScaleRateByWidth = 3,
		mSplashDepthMaxChargeScaleRateByWidth = 1,
		mSplashNearFootOccurChargeRate = 0.166,
		mSplashSplitNum = 1,
		mSniperCameraMoveStartChargeRate = 0.5,
		mSniperCameraMoveEndChargeRate = 1,
		mSniperCameraFovy = 28,
		mSniperCameraPlayerAlphaChargeRate = 0.5,
		mSniperCameraPlayerInvisibleChargeRate = 0.85,
		mMinChargeColRadiusForPlayer = 1,
		mMaxChargeColRadiusForPlayer = 1,
		mMinChargeHitSplashNum = 0,
		mMaxChargeHitSplashNum = 8,
		mMaxHitSplashNumChargeRate = 0.54,
	})
end

function ss.CustomPrimary.weapon_splatoonsweps_charger(weapon)
	local p = weapon.Parameters
	ss.CustomPrimary.weapon_splatoonsweps_shooter(weapon)
	weapon.Range = weapon.Scoped and p.mFullChargeDistanceScoped or p.mFullChargeDistance
	weapon.NPCDelay = p.mMinChargeFrame
end

function ss.DefaultParams.weapon_splatoonsweps_roller(weapon)
	weapon.Parameters = {
		mSwingLiftFrame = 20,
		mSplashNum = 12,
		mSplashInitSpeedBase = 8.2,
		mSplashInitSpeedRandomZ = 3,
		mSplashInitSpeedRandomX = 0.4,
		mSplashInitVecYRate = 0,
		mSplashDeg = 2.2,
		mSplashSubNum = 0,
		mSplashSubInitSpeedBase = 17.5,
		mSplashSubInitSpeedRandomZ = 3.5,
		mSplashSubInitSpeedRandomX = 0,
		mSplashSubInitVecYRate = 0,
		mSplashSubDeg = 7,
		mSplashPositionWidth = 8,
		mSplashInsideDamageRate = 0.4,
		mCorePaintWidthHalf = 26,
		mCorePaintSlowMoveWidthHalf = 13,
		mSlowMoveSpeed = 0,
		mCoreColWidthHalf = 10,
		mInkConsumeCore = 0.001,
		mInkConsumeSplash = 0.09,
		mInkRecoverCoreStop = 20,
		mInkRecoverSplashStop = 45,
		mMoveSpeed = 1.2,
		mCoreColRadius = 4,
		mCoreDamage = 1.4,
		mTargetEffectScale = 1.5,
		mTargetEffectVelRate = 1.2,
		mSplashStraightFrame = 4,
		mSplashDamageMaxDist = 65,
		mSplashDamageMinDist = 105,
		mSplashDamageMaxValue = 1.25,
		mSplashDamageMinValue = 0.25,
		mSplashOutsideDamageMaxDist = 95,
		mSplashOutsideDamageMinDist = 105,
		mSplashOutsideDamageMaxValue = 0.5,
		mSplashOutsideDamageMinValue = 0.25,
		mSplashDamageRateBias = 1,
		mSplashDrawRadius = 3,
		mSplashPaintNearD = 10,
		mSplashPaintNearR = 20,
		mSplashPaintFarD = 200,
		mSplashPaintFarR = 17,
		mSplashCollisionRadiusForField = 6,
		mSplashCollisionRadiusForPlayer = 8.5,
		mSplashCoverApertureFreeFrame = -1,
		mSplashSubStraightFrame = 4,
		mSplashSubDamageMaxDist = 35,
		mSplashSubDamageMinDist = 90,
		mSplashSubDamageMaxValue = 1.25,
		mSplashSubDamageMinValue = 0.25,
		mSplashSubDamageRateBias = 1,
		mSplashSubDrawRadius = 3,
		mSplashSubPaintNearD = 10,
		mSplashSubPaintNearR = 18,
		mSplashSubPaintFarD = 200,
		mSplashSubPaintFarR = 15,
		mSplashSubCollisionRadiusForField = 9,
		mSplashSubCollisionRadiusForPlayer = 9,
		mSplashSubCoverApertureFreeFrame = -1,
		mSplashPaintType = 1,
		mArmorTypeObjectDamageRate = 0.4,
		mArmorTypeGachihokoDamageRate = 0.3,
		mPaintBrushType = false,
		mPaintBrushRotYDegree = 0,
		mPaintBrushSwingRepeatFrame = 6,
		mPaintBrushNearestBulletLoopNum = 6,
		mPaintBrushNearestBulletOrderNum = 2,
		mPaintBrushNearestBulletRadius = 20,
		mDropSplashDrawRadius = 0.5,
		mDropSplashPaintRadius = 0,
	}
end

function ss.CustomPrimary.weapon_splatoonsweps_roller(weapon)
	local p = weapon.Parameters
	weapon.Primary.Automatic = false
	weapon.NPCDelay = p.mSwingLiftFrame
	weapon.Range = p.mSplashInitSpeedBase * (p.mSplashStraightFrame + ss.RollerDecreaseFrame / 2)
end

ss.DispatchEffect = {}
local SplatoonSWEPsMuzzleSplash = 0
local SplatoonSWEPsMuzzleRing = 1
local SplatoonSWEPsMuzzleMist = 2
local SplatoonSWEPsMuzzleFlash = 3
local SplatoonSWEPsRollerSplash = 4
local SplatoonSWEPsBrushSwing1 = 5
local SplatoonSWEPsBrushSwing2 = 6
local sd, e = ss.DispatchEffect, EffectData()
sd[SplatoonSWEPsMuzzleSplash] = function(self, options, pos, ang)
	local tpslag = self:IsCarriedByLocalPlayer() and
	self.Owner:ShouldDrawLocalPlayer() and 128 or 0
	local ang, a, s, r = angle_zero, 7, 2, 25
	if options[2] == "CHARGER" then
		r, s = Lerp(self:GetFireAt(), 20, 60) / 2, 6
		if options[1] == 1 then
			if self:GetFireAt() < .3 then return end
			ang = -Angle(150)
		end
	end

	e:SetAngles(ang) -- Angle difference
	e:SetAttachment(a) -- Effect duration
	e:SetColor(self:GetNWInt "inkcolor") -- Splash color
	e:SetEntity(self) -- Enitity attach to
	e:SetFlags(tpslag) -- Splash mode
	e:SetScale(s) -- Splash length
	e:SetRadius(r) -- Splash radius
	util.Effect("SplatoonSWEPsMuzzleSplash", e, true, self.IgnorePrediction)
end

sd[SplatoonSWEPsMuzzleRing] = function(self, options, pos, ang)
	local numpieces = options[1]
	local da, r1, r2, t1, t2 = math.Rand(0, 360), 40, 30, 6, 13
	local tpslag = self:IsCarriedByLocalPlayer() and
	self.Owner:ShouldDrawLocalPlayer() and 128 or 0
	e:SetColor(self:GetNWInt "inkcolor")
	e:SetEntity(self)

	if options[2] == "CHARGER" then
		r2 = Lerp(self:GetFireAt(), 20, 70)
		r1 = r2 * 2
		t2 = Lerp(self:GetFireAt(), 3, 7)
		t1 = t2 * .75
		if self:GetFireAt() < .3 then numpieces = numpieces - 1 end
	end

	for i = 0, 4 do
		e:SetAttachment(t1) -- Effect duration[frames]
		e:SetFlags(tpslag + 1) -- 1: Refract effect
		e:SetRadius(r1) -- Effect scale
		e:SetScale(i * 72 + da) -- Initial rotation
		util.Effect("SplatoonSWEPsMuzzleRing", e, true, self.IgnorePrediction)
		if i <= numpieces then
			e:SetAttachment(t2)
			e:SetFlags(tpslag) -- 0: Splash effect
			e:SetRadius(r2)
			util.Effect("SplatoonSWEPsMuzzleRing", e, true, self.IgnorePrediction)
		end
	end
end

sd[SplatoonSWEPsMuzzleMist] = function(self, options, pos, ang)
	local mdl = self:IsTPS() and self or self:GetViewModel()
	local pos, ang = self:GetMuzzlePosition()
	local dir = ang:Right()
	if not self:IsTPS() then
		if self:GetNWBool "lefthand" then dir = -dir end
		if self:GetADS() then dir = ang:Forward() end
	end

	e:SetAttachment(self:LookupAttachment "muzzle")
	e:SetColor(self:GetNWInt "inkcolor")
	e:SetEntity(mdl)
	e:SetFlags(PATTACH_POINT_FOLLOW)
	e:SetOrigin(vector_origin)
	e:SetScale(self:IsTPS() and 6 or 3)
	e:SetStart(self:TranslateViewmodelPos(pos) + dir * 100)
	util.Effect("SplatoonSWEPsMuzzleMist", e, true, self.IgnorePrediction)
end

sd[SplatoonSWEPsMuzzleFlash] = function(self, options, pos, ang)
	e:SetEntity(self)
	e:SetFlags(1)
	util.Effect("SplatoonSWEPsMuzzleFlash", e, true, self.IgnorePrediction)
end

sd[SplatoonSWEPsRollerSplash] = function(self, options, pos, ang)
	e:SetEntity(self)
	util.Effect("SplatoonSWEPsRollerSplash", e, true, self.IgnorePrediction)
	
	local color = self:GetNWInt "inkcolor"
	e:SetAttachment(4)
	e:SetColor(color)
	e:SetFlags(2) -- 2: Roller's setup, don't follow the muzzle position
	e:SetRadius(50)
	for i = -3, 3 do
		e:SetScale(10 * i) -- Roller's setup, initial position offset
		util.Effect("SplatoonSWEPsMuzzleRing", e, true, self.IgnorePrediction)
	end
end

local function MakeSwingEffect(self, sign)
	local color = self:GetNWInt "inkcolor"
	local sign = self:GetNWInt "lefthand" and -sign or sign
	e:SetEntity(self)
	e:SetAttachment(18)
	e:SetColor(color)
	e:SetFlags(4) -- 4: Brush's setup
	e:SetRadius(75)
	e:SetScale(sign)
	util.Effect("SplatoonSWEPsMuzzleRing", e, true, self.IgnorePrediction)
end

sd[SplatoonSWEPsBrushSwing1] = function(self, options, pos, ang)
	MakeSwingEffect(self, 1)
end

sd[SplatoonSWEPsBrushSwing2] = function(self, options, pos, ang)
	MakeSwingEffect(self, -1)
end
