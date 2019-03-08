
-- Functions for weapon settings.

local ss = SplatoonSWEPs
if not ss then return end

function ss.SetPrimary(weapon, info)
	local p = istable(weapon.Primary) and weapon.Primary or {}
	p.Info = info
	p.ClipSize = ss.MaxInkAmount --Clip size only for displaying.
	p.DefaultClip = ss.MaxInkAmount
	p.Automatic = info.IsAutomatic or false
	p.Ammo = "Ink"
	p.Delay = (info.Delay.Fire or 0) * ss.FrameToSec
	p.FirePosition = info.FirePosition
	p.Recoil = info.Recoil or .2
	p.ReloadDelay = info.Delay.Reload * ss.FrameToSec
	p.TakeAmmo = info.TakeAmmo * ss.MaxInkAmount
	p.CrouchDelay = info.Delay.Crouch * ss.FrameToSec
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
	s.TakeAmmo = info.TakeAmmo * ss.MaxInkAmount
	s.CrouchDelay = info.Delay.Crouch * ss.FrameToSec
	ss.ProtectedCall(ss.CustomSecondary[weapon.Base], s, info)
	weapon.Secondary = s
end

ss.CustomPrimary = {}
ss.CustomSecondary = {}
function ss.CustomPrimary.weapon_splatoonsweps_shooter(p, info)
	p.Straight = info.Delay.Straight * ss.FrameToSec
	p.Damage = info.Damage * ss.ToHammerHealth
	p.MinDamage = info.MinDamage * ss.ToHammerHealth
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
	p.MinDamage = info.MinDamage * ss.ToHammerHealth
	p.MaxDamage = info.MaxDamage * ss.ToHammerHealth
	p.Damage = (info.FullDamage or info.MaxDamage) * ss.ToHammerHealth
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
	p.DamageClose = info.DamageClose * ss.ToHammerHealth
	p.DamageMiddle = info.DamageMiddle * ss.ToHammerHealth
	p.DamageFar = info.DamageFar * ss.ToHammerHealth
	p.DamageWallMul = info.DamageWallMul
	p.ColRadiusClose = info.ColRadiusClose * ss.ToHammerUnits
	p.ColRadiusMiddle = info.ColRadiusMiddle * ss.ToHammerUnits
	p.ColRadiusFar = info.ColRadiusFar * ss.ToHammerUnits
	p.ColRadiusWallMul = info.ColRadiusWallMul
	p.InkRadiusWall = info.InkRadiusWall * ss.ToHammerUnits
	p.ExplosionTime = info.Delay.Explosion * ss.FrameToSec
	p.PreFireDelay = info.Delay.PreFire * ss.FrameToSec
	p.PreFireDelaySquid = info.Delay.PreFireSquid * ss.FrameToSec
	p.PostFireDelay = info.Delay.PostFire * ss.FrameToSec
end

function ss.SetViewModelMods(weapon, mods)
	weapon.ViewModelBoneMods = weapon.ViewModelBoneMods or {}
	for bone, mod in pairs(mods) do
		weapon.ViewModelBoneMods[bone] = mod
		mod.scale = mod.scale or ss.vector_one
		mod.pos = mod.pos or vector_origin
		mod.angle = mod.angle or angle_zero
	end
end

function ss.SetViewModel(weapon, view)
	weapon.VElements = weapon.VElements or {}
	weapon.VElements.weapon = {
		type = "Model",
		model = Model(view.model or weapon.WeaponModelName),
		bone = view.bone or "ValveBiped.Bip01_Spine4",
		rel = view.rel or "",
		pos = view.pos,
		angle = view.angle,
		size = view.size or ss.vector_one,
		color = view.color or color_white,
		surpresslightning = view.surpresslightning or false,
		material = view.material or "",
		skin = view.skin or 0,
		bodygroup = view.bodygroup or {},
	}
end

function ss.SetWorldModel(weapon, world)
	weapon.WElements = weapon.WElements or {}
	weapon.WElements.weapon = {
		type = "Model",
		model = Model(world.model or weapon.WeaponModelName),
		bone = world.bone or "ValveBiped.Bip01_R_Hand",
		rel = world.rel or "",
		pos = world.pos,
		angle = world.angle,
		size = world.size or ss.vector_one,
		color = world.color or color_white,
		surpresslightning = world.surpresslightning or false,
		material = world.material or "",
		skin = world.skin or 0,
		bodygroup = world.bodygroup or {},
	}
end

local SplatoonSWEPsMuzzleSplash = 0
local SplatoonSWEPsMuzzleRing = 1
local SplatoonSWEPsMuzzleMist = 2
local SplatoonSWEPsMuzzleFlash = 3

local function GenerateParticleEffect(self, name, offset)
	local mdl = self:IsTPS() and self or self.Owner:GetViewModel()
	local pos, ang = self:GetMuzzlePosition()
	pos = self:TranslateViewmodelPos(pos)
	self.MuzzleAttachment = self.MuzzleAttachment or self:LookupAttachment "muzzle"
	return CreateParticleSystem(mdl, name, PATTACH_POINT_FOLLOW, self.MuzzleAttachment, offset or vector_origin)
end

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
	util.Effect("SplatoonSWEPsMuzzleSplash", e, true, not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
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
		util.Effect("SplatoonSWEPsMuzzleRing", e, true, not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
		if i > numpieces then continue end
		e:SetAttachment(t2)
		e:SetFlags(tpslag) -- 0: Splash effect
		e:SetRadius(r2)
		util.Effect("SplatoonSWEPsMuzzleRing", e, true, not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
	end
end

sd[SplatoonSWEPsMuzzleMist] = function(self, options, pos, ang)
	local p = GenerateParticleEffect(self, ss.Particles.MuzzleMist)
	local dir = ang:Right()
	if self:GetNWBool "lefthand" then dir = -dir end
	if self:GetADS() then dir = ang:Forward() end
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, self:GetInkColorProxy())
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * (self:IsTPS() and 6 or 3))
	p:AddControlPoint(3, game.GetWorld(), PATTACH_WORLDORIGIN, nil, pos + dir * 100)
end

sd[SplatoonSWEPsMuzzleFlash] = function(self, options, pos, ang)
	local e = EffectData()
	e:SetEntity(self)
	e:SetFlags(1)
	util.Effect("SplatoonSWEPsMuzzleFlash", e, true, not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
end
