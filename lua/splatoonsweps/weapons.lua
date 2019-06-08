
-- Functions for weapon settings.

local ss = SplatoonSWEPs
if not ss then return end

function ss.SetPrimary(weapon, info)
	local p = istable(weapon.Primary) and weapon.Primary or {}
	p.Info = info
	p.ClipSize = ss.GetMaxInkAmount() --Clip size only for displaying.
	p.DefaultClip = ss.GetMaxInkAmount()
	p.Automatic = info.IsAutomatic or false
	p.Ammo = "Ink"
	p.Delay = (info.Delay.Fire or 0) * ss.FrameToSec
	p.FirePosition = info.FirePosition
	p.Recoil = info.Recoil or .2
	p.ReloadDelay = (info.Delay.Reload or 0) * ss.FrameToSec
	p.TakeAmmo = info.TakeAmmo
	p.CrouchDelay = (info.Delay.Crouch or 0) * ss.FrameToSec
	ss.ProtectedCall(ss.CustomPrimary[weapon.Base], p, info)
	weapon.Primary = p
end

function ss.SetSecondary(weapon, info)
	local s = istable(weapon.Secondary) and weapon.Secondary or {}
	s.ClipSize = -1
	s.DefaultClip = -1
	s.Automatic = info.IsAutomatic or false
	s.Ammo = "Ink"
	s.Delay = info.Delay.Fire * ss.FrameToSec
	s.Recoil = info.Recoil or .2
	s.ReloadDelay = info.Delay.Reload * ss.FrameToSec
	s.TakeAmmo = info.TakeAmmo
	s.CrouchDelay = info.Delay.Crouch * ss.FrameToSec
	ss.ProtectedCall(ss.CustomSecondary[weapon.Base], s, info)
	weapon.Secondary = s
end

ss.CustomPrimary = {}
ss.CustomSecondary = {}
function ss.CustomPrimary.weapon_splatoonsweps_shooter(p, info)
	p.Straight = info.Delay.Straight * ss.FrameToSec
	p.Damage = info.Damage
	p.MinDamage = info.MinDamage
	p.InkRadius = info.InkRadius * ss.ToHammerUnits
	p.MinRadius = info.MinRadius * ss.ToHammerUnits
	p.SplashRadius = info.SplashRadius * ss.ToHammerUnits
	p.SplashPatterns = info.SplashPatterns
	p.SplashNum = info.SplashNum
	p.SplashInterval = info.SplashInterval * ss.ToHammerUnits
	p.Spread = info.Spread
	p.SpreadJump = info.SpreadJump
	p.SpreadBias = info.SpreadBias
	p.SpreadBiasStep = info.SpreadBiasStep
	p.SpreadBiasJump = info.SpreadBiasJump
	p.SpreadJumpDelay = info.Delay.SpreadJump * ss.FrameToSec
	p.MoveSpeed = info.MoveSpeed * ss.ToHammerUnitsPerSec
	p.MinDamageTime = info.Delay.MinDamage * ss.FrameToSec
	p.DecreaseDamage = info.Delay.DecreaseDamage * ss.FrameToSec
	p.AimDuration = info.Delay.Aim * ss.FrameToSec
	p.ColRadius = info.ColRadius or ss.mColRadius
	p.InitVelocity = info.InitVelocity * ss.ToHammerUnitsPerSec
	p.Range = p.InitVelocity * (p.Straight + ss.ShooterDecreaseFrame / 2)

	if not info.Delay.TripleShot then return end
	p.TripleShotDelay = info.Delay.TripleShot * ss.FrameToSec
end

function ss.CustomPrimary.weapon_splatoonsweps_charger(p, info)
	p.EmptyChargeMul = info.EmptyChargeMul
	p.MoveSpeed = info.MoveSpeed * ss.ToHammerUnitsPerSec
	p.JumpPower = info.JumpMul * ss.InklingJumpPower
	p.MinRange = info.MinRange * ss.ToHammerUnits
	p.MaxRange = info.MaxRange * ss.ToHammerUnits
	p.Range = (info.FullRange or info.MaxRange) * ss.ToHammerUnits
	p.MinVelocity = info.MinVelocity * ss.ToHammerUnitsPerSec
	p.MaxVelocity = info.MaxVelocity * ss.ToHammerUnitsPerSec
	p.InitVelocity = (info.FullVelocity or info.MaxVelocity) * ss.ToHammerUnitsPerSec
	p.MinDamage = info.MinDamage
	p.MaxDamage = info.MaxDamage
	p.Damage = info.FullDamage or info.MaxDamage
	p.MinChargeTime = info.Delay.MinCharge * ss.FrameToSec
	p.MaxChargeTime = info.Delay.MaxCharge * ss.FrameToSec
	p.MinColRadius = info.MinColRadius or ss.mColRadius
	p.ColRadius = info.MaxColRadius or ss.mColRadius
	p.MinWallPaintNum = info.MinWallPaintNum
	p.MaxWallPaintNum = info.MaxWallPaintNum
	p.WallPaintCharge = info.WallPaintChargeThreshold
	p.FootpaintCharge = info.FootpaintChargeRate
	p.Spread = info.Spread or 0
	p.SpreadJump = info.SpreadJump or 0
	p.SpreadBias = info.SpreadBias or 0
	p.SplashPatterns = info.SplashPatterns or 1
	p.SplashRadiusMul = info.LastSplashRadiusMul
	p.MaxSplashRadius = info.MaxChargeSplashPaintRadius * ss.ToHammerUnits
	p.MinSplashRadius = info.MinChargeSplashPaintRadius * p.MaxSplashRadius
	p.MinSplashRatio = info.MinSplashRatio
	p.MaxSplashRatio = info.MaxSplashRatio
	p.MinSplashInterval = info.MinSplashInterval
	p.MaxSplashInterval = info.MaxSplashInterval
	p.MinFreezeTime = (info.Delay.MinFreeze or 1) * ss.FrameToSec
	p.MaxFreezeTime = (info.Delay.MaxFreeze or 1) * ss.FrameToSec
	p.AimDuration = info.Delay.Aim * ss.FrameToSec
	p.Automatic = true
	p.Scope = {}
	p.Scope.StartMove = info.Scope.StartMove
	p.Scope.EndMove = info.Scope.EndMove
	p.Scope.FOV = info.Scope.CameraFOV
	p.Scope.Alpha = info.Scope.PlayerAlpha
	p.Scope.Invisible = info.Scope.PlayerInvisible
	p.Scope.SwayTime = (info.Scope.EndMove - info.Scope.StartMove) * p.MaxChargeTime
end

function ss.CustomPrimary.weapon_splatoonsweps_splatling(p, info)
	ss.CustomPrimary.weapon_splatoonsweps_shooter(p, info)
	p.Automatic = true
	p.EmptyChargeMul = info.EmptyChargeMul
	p.JumpPower = info.JumpMul * ss.InklingJumpPower
	p.MoveSpeedCharge = info.MoveSpeedCharge * ss.ToHammerUnitsPerSec
	p.SpreadVelocity = info.SpreadVelocity
	p.SpreadBiasVelocity = info.SpreadBiasVelocity
	p.InkRadiusMul = info.InkScale
	p.MinChargeTime = info.Delay.MinCharge * ss.FrameToSec
	p.MaxChargeTime = {info.Delay.MaxCharge[1] * ss.FrameToSec, info.Delay.MaxCharge[2] * ss.FrameToSec}
	p.FireDuration = {info.Delay.FireDuration[1] * ss.FrameToSec, info.Delay.FireDuration[2] * ss.FrameToSec}
	p.MinVelocity = info.MinVelocity * ss.ToHammerUnitsPerSec
	p.MediumVelocity = info.MediumVelocity * ss.ToHammerUnitsPerSec
	p.MaxTakeAmmo = p.TakeAmmo
	p.TakeAmmo = p.TakeAmmo / (info.Delay.FireDuration[2] / info.Delay.Fire)
	if not info.PaintNearDistance then return end
	p.PaintNearDistance = info.PaintNearDistance * ss.ToHammerUnits
end

function ss.CustomPrimary.weapon_splatoonsweps_blaster_base(p, info)
	ss.CustomPrimary.weapon_splatoonsweps_shooter(p, info)
	p.DamageClose = info.DamageClose
	p.DamageMiddle = info.DamageMiddle
	p.DamageFar = info.DamageFar
	p.DamageWallMul = info.DamageWallMul
	p.ColRadiusClose = info.ColRadiusClose * ss.ToHammerUnits
	p.ColRadiusMiddle = info.ColRadiusMiddle * ss.ToHammerUnits
	p.ColRadiusFar = info.ColRadiusFar * ss.ToHammerUnits
	p.ColRadiusWallMul = info.ColRadiusWallMul
	p.InkRadiusGround = info.InkRadiusGround * ss.ToHammerUnits
	p.InkRadiusWall = info.InkRadiusWall * ss.ToHammerUnits
	p.InkRadiusBlastMax = info.InkRadiusBlastMax * ss.ToHammerUnits
	p.InkRadiusBlastMin = info.InkRadiusBlastMin * ss.ToHammerUnits
	p.ExplosionTime = info.Delay.Explosion * ss.FrameToSec
	p.PreFireDelay = info.Delay.PreFire * ss.FrameToSec
	p.PreFireDelaySquid = info.Delay.PreFireSquid * ss.FrameToSec
	p.PostFireDelay = info.Delay.PostFire * ss.FrameToSec
end

function ss.CustomPrimary.weapon_splatoonsweps_roller(p, info)
	p.SwingWaitTime = info.Delay.SwingWait * ss.FrameToSec
	p.Straight = info.Delay.Straight * ss.FrameToSec
	p.StraightSub = info.Delay.StraightSub * ss.FrameToSec
	p.ReloadDelayGround = info.Delay.ReloadGround * ss.FrameToSec
	p.TakeAmmoGround = info.TakeAmmoGround
	p.MoveSpeed = info.MoveSpeed * ss.ToHammerUnitsPerSec

	p.Damage = info.Damage
	p.DamageSub = info.DamageSub
	p.MinDamage = info.MinDamage
	p.MinDamageSub = info.MinDamageSub
	p.DamageGround = info.DamageGround

	p.InitVelocity = info.InitVelocity * ss.ToHammerUnitsPerSec
	p.InitVelocitySub = info.InitVelocitySub * ss.ToHammerUnitsPerSec
	p.SpreadVelocity = info.SpreadVelocity * ss.ToHammerUnitsPerSec
	p.SpreadVelocitySub = info.SpreadVelocitySub * ss.ToHammerUnitsPerSec

	p.Spread = info.Spread
	p.SpreadSub = info.SpreadSub
	p.SplashNum = info.SplashNum
	p.SplashSubNum = info.SplashSubNum
	p.SplashPosWidth = info.SplashPosWidth * ss.ToHammerUnits

	p.MaxWidth = info.MaxWidth * ss.ToHammerUnits
	p.MinWidth = info.MinWidth * ss.ToHammerUnits
	p.CollisionWidth = info.CollisionWidth * ss.ToHammerUnits

	p.EffectScale = info.EffectScale
	p.EffectVelocityRate = info.EffectVelocityRate

	p.MinDamageDist = info.MinDamageDist * ss.ToHammerUnits
	p.MinDamageDistSub = info.MinDamageDistSub * ss.ToHammerUnits
	p.DecreaseDamageDist = info.DecreaseDamageDist * ss.ToHammerUnits
	p.DecreaseDamageDistSub = info.DecDamageDistSub * ss.ToHammerUnits

	p.InkRadius = info.InkRadius * ss.ToHammerUnits
	p.InkRadiusSub = info.InkRadiusSub * ss.ToHammerUnits
	p.MinRadius = info.MinRadius * ss.ToHammerUnits
	p.MinRadiusSub = info.MinRadiusSub * ss.ToHammerUnits

	p.MaxPaintDistance = info.MaxPaintDistance * ss.ToHammerUnits
	p.MaxPaintDistanceSub = info.MaxPaintDistSub * ss.ToHammerUnits
	p.MinPaintDistance = info.MinPaintDistance * ss.ToHammerUnits
	p.MinPaintDistanceSub = info.MinPaintDistSub * ss.ToHammerUnits

	p.CollisionRadiusWorld = info.ColRadiusWorld * ss.ToHammerUnits
	p.CollisionRadiusWorldSub = info.ColRadiusWorldSub * ss.ToHammerUnits
	p.CollisionRadiusPlayer = info.ColRadiusPlayer * ss.ToHammerUnits
	p.CollisionRadiusPlayerSub = info.ColRadiusPlayerSub * ss.ToHammerUnits
	p.ColRadius = p.CollisionRadiusPlayer

	p.Range = p.InitVelocity * (p.Straight + ss.ShooterDecreaseFrame / 2)
	p.SplashInterval = 0
	p.SplashPatterns = 0
end

local SplatoonSWEPsMuzzleSplash = 0
local SplatoonSWEPsMuzzleRing = 1
local SplatoonSWEPsMuzzleMist = 2
local SplatoonSWEPsMuzzleFlash = 3

ss.DispatchEffect = {}
local sd, e = ss.DispatchEffect, EffectData()
sd[SplatoonSWEPsMuzzleSplash] = function(self, options, pos, ang)
	local tpslag = self:IsCarriedByLocalPlayer()
	and self.Owner:ShouldDrawLocalPlayer() and 128 or 0
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
	util.Effect("SplatoonSWEPsMuzzleSplash", e, true,
	not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
end

sd[SplatoonSWEPsMuzzleRing] = function(self, options, pos, ang)
	local numpieces = options[1]
	local da, r1, r2, t1, t2 = math.Rand(0, 360), 40, 30, 6, 13
	local tpslag = self:IsCarriedByLocalPlayer()
	and self.Owner:ShouldDrawLocalPlayer() and 128 or 0
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
		e:SetAttachment(t1)
		e:SetFlags(tpslag + 1) -- 1: Refract effect
		e:SetRadius(r1)
		e:SetScale(i * 72 + da)
		util.Effect("SplatoonSWEPsMuzzleRing", e, true,
		not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
		if i > numpieces then continue end
		e:SetAttachment(t2)
		e:SetFlags(tpslag) -- 0: Splash effect
		e:SetRadius(r2)
		util.Effect("SplatoonSWEPsMuzzleRing", e, true,
		not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
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

	local e = EffectData()
	e:SetAttachment(self:LookupAttachment "muzzle")
	e:SetColor(self:GetNWInt "inkcolor")
	e:SetEntity(mdl)
	e:SetFlags(PATTACH_POINT_FOLLOW)
	e:SetOrigin(vector_origin)
	e:SetScale(self:IsTPS() and 6 or 3)
	e:SetStart(self:TranslateViewmodelPos(pos) + dir * 100)
	util.Effect("SplatoonSWEPsMuzzleMist", e, true,
	not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
end

sd[SplatoonSWEPsMuzzleFlash] = function(self, options, pos, ang)
	local e = EffectData()
	e:SetEntity(self)
	e:SetFlags(1)
	util.Effect("SplatoonSWEPsMuzzleFlash", e, true,
	not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
end
