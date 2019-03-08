
local ss = SplatoonSWEPs
if not ss then return end

local Simulate, HitPaint, HitEntity = {}, {}, {}
local MAX_INK_SIM_AT_ONCE = 60 -- Calculating ink trajectory at once
local SplashDistance = 50 * ss.ToHammerUnits -- Transition between drop and splash
local dropdata = {
	Damage = 0,
	MinDamage = 0,
	MinDamageTime = 0,
	DecreaseDamage = 0,
	InitTime = 0,
	InkRadius = 10,
	MinRadius = 10,
	ColRadius = ss.mColRadius,
	SplashRadius = 0,
	SplashPatterns = 0,
	SplashNum = 0,
	SplashInterval = 0,
	Straight = 0,
	InitVelocity = 0,
}

function ss.GetDropType() -- math.floor(1 <= x < 4) -> 1, 2, 3
	return util.SharedRandom("SplatoonSWEPs: Drop ink type", 1, 4, CurTime())
end

function ss.PlayHitSound(iscritical, owner)
	if ss.sp or CLIENT and IsFirstTimePredicted() then
		local ent = ss.IsValidInkling(e) -- Entity hit effect here
		if not (ent and ss.IsAlly(ent, ink.Color)) then
			if ss.mp then
				surface.PlaySound(iscritical and ss.DealDamageCritical or ss.DealDamage)
			elseif owner:IsPlayer() and SERVER then
				local s = "SplatoonSWEPs.DealDamage"
				if iscritical then s = "SplatoonSWEPs.DealDamageCritical" end
				owner:SendLua(string.format("surface.PlaySound(%s)", s))
			end
		end
	end
end

-- Physics simulation for ink trajectory.
-- The first some frames(1/60 sec.) ink flies without gravity.
-- After that, ink decelerates horizontally and is affected by gravity.
function Simulate.weapon_splatoonsweps_shooter(ink)
	ss.Simulate.Shooter(ink)
	if not IsFirstTimePredicted() then return end
	if ink.SplashCount <= ink.SplashNum then -- Creates ink drops
		dropdata.InkRadius = ink.SplashRadius
		dropdata.MinRadius = ink.SplashRadius
		dropdata.InitTime = CurTime() - ss.ShooterDecreaseFrame
		local Length = (ink.endpos - ink.InitPos):Length2D()
		local NextLength = ink.SplashCount * ink.SplashInterval + ink.SplashInit
		while Length >= NextLength and ink.SplashCount <= ink.SplashNum do
			ss.AddInk(ink.filter, ink.InitPos + ink.InitDirection * NextLength, ss.GetDropType(), {
				Angle = ink.Angle,
				ClassName = ink.ClassName,
				Color = ink.Color,
				SplashInit = ink.WeaponSplashInit,
			})
			local start = ink.InitPos + ink.InitDirection * NextLength
			if util.TraceLine {
				start = start,
				endpos = start + ink.InitDirection * ink.SplashInterval,
				filter = ink.filter,
				mask = ss.SquidSolidMask,
			}.Hit then
				break
			end

			NextLength = NextLength + ink.SplashInterval
			ink.SplashCount = ink.SplashCount + 1
		end
	end
end

function HitPaint.weapon_splatoonsweps_shooter(ink, t)
	local ratio = 1
	local radius = ink.InkRadius
	if not ink.IsDrop and ink.Base ~= "weapon_splatoonsweps_charger" and t.HitNormal.z > ss.MAX_COS_DEG_DIFF then
		local actual = (t.HitPos - ink.InitPos):Length2D()
		local min = SplashDistance + ink.PaintNearDistance
		if actual > min then
			local max = ss.mPaintFarDistance
			local stretch = (actual - min) / max + 0.5
			radius, ratio = radius * (stretch + 0.5), 0.5 / stretch
		else
			ink.InkType = ss.GetDropType()
		end
	else
		ink.InkType = ss.GetDropType()
		ratio = ink.Ratio or ratio
	end

	if (ss.sp or CLIENT and IsFirstTimePredicted()) and t.Hit and (not ink.IsDrop or ink.PlayHitSound) then
		sound.Play("SplatoonSWEPs_Ink.HitWorld", t.HitPos)
	end

	ss.Paint(t.HitPos, t.HitNormal, radius, ink.Color,
	ink.Angle, ink.InkType, ratio, ink.filter, ink.ClassName)
end

function HitEntity.weapon_splatoonsweps_shooter(ink, t, w)
	local d, e, o = DamageInfo(), t.Entity, ink.filter
	local frac = (math.max(0, CurTime() - ink.InitTime)
	- ink.DecreaseDamage) / ink.MinDamageTime
	if ink.IsCarriedByLocalPlayer then
		ss.PlayHitSound(ink.IsCritical, o)
		if ss.mp and CLIENT then return end
	end

	d:SetDamage(Lerp(1 - frac, ink.MinDamage, ink.Damage))
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(ink.Damage)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(ss.IsValidInkling(o) or game.GetWorld())
	ss.ProtectedCall(e.TakeDamageInfo, e, d)
end

function Simulate.weapon_splatoonsweps_charger(ink)
	ss.Simulate.Charger(ink)
	if not IsFirstTimePredicted() then return end
	dropdata.PlayHitSound = true
	dropdata.InitTime = CurTime() - ss.ShooterDecreaseFrame
	local Length = math.Clamp(ink.Speed * math.max(0, CurTime() - ink.InitTime), 0, ink.Range)
	local NextLength = ink.SplashCount * ink.SplashInterval + ink.SplashInit
	while Length >= NextLength do -- Create ink drops
		dropdata.InkRadius = ink.SplashRadius / ink.Ratio
		local droptable = {
			Angle = ink.Angle,
			ClassName = ink.ClassName,
			Color = ink.Color,
			SplashInit = ink.WeaponSplashInit,
		}
		local hull = {
			collisiongroup = ink.collisiongroup,
			endpos = ink.InitPos + ink.InitDirection * NextLength,
			filter = ink.filter,
			mask = ss.SquidSolidMask,
			maxs = ink.maxs,
			mins = ink.mins,
			start = ink.InitPos,
		}
		local t = util.TraceHull(hull)
		t = ss.AddInk(ink.filter, t.HitPos + t.HitNormal, ss.GetDropType(), droptable)
		t.Ratio = ink.Ratio

		hull.start, hull.endpos = hull.endpos, hull.endpos + ink.InitDirection * ink.SplashInterval
		if util.TraceHull(hull).Hit then break end

		NextLength = NextLength + ink.SplashInterval
		ink.SplashCount = ink.SplashCount + 1
		if NextLength >= ink.Range then
			dropdata.InkRadius = dropdata.InkRadius * ink.SplashRadiusMul
			t = nil
			t = ss.AddInk(ink.filter, ink.StraightPos, ss.GetDropType(), droptable)
			t.Ratio = ink.Ratio

			HitPaint.weapon_splatoonsweps_charger(ink, {
				FractionPaintWall = .8,
				HitPos = ink.InitPos + ink.InitDirection * ink.Range,
				HitNormal = -ink.InitDirection,
			})
		elseif ink.SplashCount == 1 and ink.Charge > ink.FootpaintCharge then
			dropdata.InkRadius = ink.FootpaintRadius
			ss.AddInk(ink.filter, ink.InitPos, ss.GetDropType(), droptable)
		end
	end

	dropdata.PlayHitSound = nil
end

local function HitSmoke(ink, t)
	if ink.ClassName:find "bamboozler" then return end
	if t.HitWorld and CurTime() - ink.InitTime <= ink.Straight and CLIENT then
		local c = ss.GetColor(ink.Color)
		local p = CreateParticleSystem(game.GetWorld(), ss.Particles.MuzzleMist, PATTACH_WORLDORIGIN, 0, t.HitPos + t.HitNormal * 10)
		p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, Vector(c.r, c.g, c.b) / 255)
		p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * 6)
		p:AddControlPoint(3, game.GetWorld(), PATTACH_WORLDORIGIN, nil, ink.InitPos)
	end
end

function HitPaint.weapon_splatoonsweps_charger(ink, t)
	local wallfrac = math.Remap(ink.Charge, 0, ink.WallPaintCharge, 0, 1)
	local radius = ink.SplashRadius / ink.SplashRadiusMul
	local SplashNum = math.Round(Lerp(wallfrac, ink.MinWallPaintNum, ink.MaxWallPaintNum))
	ink.InkRadius, ink.Ratio = ink.SplashRadius * ((1 + 1 / ink.Ratio) / 2), 1
	HitPaint.weapon_splatoonsweps_shooter(ink, t)
	HitSmoke(ink, t)
	if t.HitNormal.z > ss.MAX_COS_DEG_DIFF then return end
	for i = 1, SplashNum do
		local pos = t.HitPos - vector_up * i * radius * Lerp(wallfrac, 1, 1.25)
		local tr = util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			endpos = pos - t.HitNormal,
			filter = ink.filter,
			mask = ss.SquidSolidMask,
			start = ink.InitPos,
		}

		if math.abs(tr.HitNormal.z) > ss.MAX_COS_DEG_DIFF then continue end
		if (t.FractionPaintWall or 0) > tr.Fraction then continue end
		if tr.StartSolid or not tr.HitWorld then continue end
		ss.PaintSchedule[{
			pos = tr.HitPos,
			normal = tr.HitNormal,
			radius = radius,
			color = ink.Color,
			angle = ink.Angle,
			inktype = ss.GetDropType(),
			ratio = 1,
			Time = CurTime() + i * radius / ink.Speed,
			filter = ink.filter,
			ClassName = ink.ClassName,
		}] = true
	end
end

function HitEntity.weapon_splatoonsweps_charger(ink, t, w)
	local LifeTime = math.max(0, CurTime() - FrameTime() - ink.InitTime)
	local d, e, o = DamageInfo(), t.Entity, ink.filter

	HitSmoke(ink, t)
	if LifeTime > ink.Straight then return end
	if ink.IsCarriedByLocalPlayer then
		ss.PlayHitSound(ink.Damage >= 100, o)
		if ss.mp and CLIENT then return end
	end

	d:SetDamage(ink.Damage)
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(ink.Damage)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(ss.IsValidInkling(o) or game.GetWorld())
	ss.ProtectedCall(e.TakeDamageInfo, e, d)
end

Simulate.weapon_splatoonsweps_splatling = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_splatling = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_splatling = HitEntity.weapon_splatoonsweps_shooter
function Simulate.weapon_splatoonsweps_blaster_base(ink)
	Simulate.weapon_splatoonsweps_shooter(ink)
	if ink.Time < ink.ExplosionTime then return end
	ss.MakeBlasterExplosion(ink)
	ss.InkQueue[ink] = nil
end

function HitPaint.weapon_splatoonsweps_blaster_base(ink, t)
	HitPaint.weapon_splatoonsweps_shooter(ink, t)
	ink.HitWall = true
	ink.DamageClose = ink.DamageClose * ink.DamageWallMul
	ink.DamageMiddle = ink.DamageMiddle * ink.DamageWallMul
	ink.DamageFar = ink.DamageFar * ink.DamageWallMul
	ink.ColRadiusFar = ink.ColRadiusFar * ink.ColRadiusWallMul
	ink.ColRadiusMiddle = ink.ColRadiusMiddle * ink.ColRadiusWallMul
	ink.ColRadiusClose = ink.ColRadiusClose * ink.ColRadiusWallMul
	ss.MakeBlasterExplosion(ink)
end

function HitEntity.weapon_splatoonsweps_blaster_base(ink, t, w)
	HitEntity.weapon_splatoonsweps_shooter(ink, t, w)
end

local function ProcessInkQueue(ply)
	while true do
		for ink in pairs(ss.InkQueue) do
			if not IsValid(ink.filter) then ss.InkQueue[ink] = nil continue end
			if ink.filter:IsPlayer() and ink.filter ~= ply then continue end

			ss.ProtectedCall(Simulate[ink.Base], ink)
			if not (ink.start and ink.endpos) then
				ss.InkQueue[ink] = nil
				continue
			end

			local t = util.TraceHull(ink)
			ink.start = t.HitPos
			if not (t.Hit or ss.IsInWorld(t.HitPos)) then
				ss.InkQueue[ink] = nil
			elseif t.HitWorld then
				ink.endpos = t.HitPos - t.HitNormal * ink.ColRadius * 2
				t = util.TraceLine(ink)
				ss.ProtectedCall(HitPaint[ink.Base], ink, t)
				ss.InkQueue[ink] = nil
			elseif IsValid(t.Entity) and ink.Damage > 0 then -- If ink hits an NPC or something
				local w = ss.IsValidInkling(t.Entity)
				if not (w and ss.IsAlly(w, ink.Color)) then
					ss.ProtectedCall(HitEntity[ink.Base], ink, t, w)
				end
				ss.InkQueue[ink] = nil
			end
		end

		for ink in pairs(ss.PaintSchedule) do
			if CurTime() > ink.Time then
				ss.Paint(ink.pos, ink.normal, ink.radius, ink.color,
				ink.angle, ink.inktype, ink.ratio, ink.filter, ink.ClassName)
				ss.PaintSchedule[ink] = nil
			end
		end

		repeat
			ply = coroutine.yield()
		until IsFirstTimePredicted()
	end
end

-- Make an ink bullet for shooter.
-- Arguments:
--   Entity owner				| The owner of fired ink.
--   Vector pos					| Initial position of ink.
--   number inktype				| Shape of ink.
function ss.AddInk(ply, pos, inktype, isdrop)
	local w = ss.IsValidInkling(ply)
	if not (isdrop or w) then return {} end
	if isdrop then w = isdrop end
	local info = isdrop and dropdata or w.Primary
	local base = isdrop and "weapon_splatoonsweps_shooter" or w.Base
	local IsLP = Either(isdrop,
		(isdrop or {}).IsCarriedByLocalPlayer,
		SERVER or ss.ProtectedCall(w.IsCarriedByLocalPlayer, w))
	local dt = CLIENT and IsLP and w:Ping() or 0
	local t = {
		Angle = isdrop and isdrop.Angle or w.InitAngle,
		Base = base,
		ClassName = w.ClassName,
		Color = isdrop and isdrop.Color or w:GetNWInt "inkcolor",
		ColRadius = info.ColRadius,
		Damage = info.Damage,
		DecreaseDamage = info.DecreaseDamage,
		InitDirection = isdrop and -vector_up or w.InitVelocity:GetNormalized(),
		InitPos = pos,
		InitTime = info.InitTime or CurTime(),
		InkType = math.floor(inktype),
		IsCarriedByLocalPlayer = IsLP,
		IsDrop = isdrop,
		MinDamage = info.MinDamage,
		MinDamageTime = info.MinDamageTime,
		SplashInterval = info.SplashInterval,
		Straight = info.Straight,
		Time = 0,
		Velocity = isdrop and vector_origin or w.InitVelocity,
		WeaponSplashInit = w.SplashInit,
		-- collisiongroup = COLLISION_GROUP_IN_VEHICLE,
		endpos = Vector(),
		filter = ply,
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * info.ColRadius,
		mins = -ss.vector_one * info.ColRadius,
		start = pos,
	}

	if base == "weapon_splatoonsweps_charger" then
		local prog = w:GetChargeProgress()
		local Speed = w:GetInkVelocity()
		local SplashRadius = Lerp(prog, info.MinSplashRadius, info.MaxSplashRadius)
		local SplashRatio = Lerp(prog, info.MinSplashRatio, info.MaxSplashRatio)
		local SplashInterval = Lerp(prog, info.MinSplashInterval, info.MaxSplashInterval)
		SplashInterval = SplashInterval * SplashRadius * SplashRatio * .85
		table.Merge(t, {
			Charge = prog,
			Damage = w:GetDamage(),
			FootpaintCharge = info.FootpaintCharge,
			FootpaintRadius = SplashRadius / info.SplashRadiusMul,
			MaxWallPaintNum = info.MaxWallPaintNum,
			MinWallPaintNum = info.MinWallPaintNum,
			Range = w.Range,
			Ratio = 1 / SplashRatio,
			Speed = Speed,
			SplashCount = 0,
			SplashInit = SplashInterval / info.SplashPatterns * w.SplashInit + SplashRadius,
			SplashInitMul = w.SplashInit,
			SplashInterval = SplashInterval,
			SplashRadius = SplashRadius,
			SplashRadiusMul = info.SplashRadiusMul,
			Straight = w.Range / Speed,
			StraightPos = pos + t.InitDirection * w.Range,
			WallPaintCharge = info.WallPaintCharge,
		})
	else
		table.Merge(t, {
			InkRadius = info.InkRadius,
			MinRadius = info.MinRadius,
			PaintNearDistance = info.PaintNearDistance or ss.mPaintNearDistance,
			PlayHitSound = isdrop and info.PlayHitSound or nil,
			Range = isdrop and 0 or info.InitVelocity * info.Straight,
			SplashCount = 0,
			SplashInit = info.SplashInterval / info.SplashPatterns * w.SplashInit,
			SplashInitMul = isdrop and 0 or w.SplashInit,
			SplashMinRadius = info.SplashRadius * info.MinRadius / info.InkRadius,
			SplashNum = isdrop and 0 or w.SplashNum,
			SplashRadius = info.SplashRadius,
		})

		if base == "weapon_splatoonsweps_blaster_base" then
			table.Merge(t, {
				ColRadiusClose = info.ColRadiusClose,
				ColRadiusMiddle = info.ColRadiusMiddle,
				ColRadiusFar = info.ColRadiusFar,
				ColRadiusWallMul = info.ColRadiusWallMul,
				DamageClose = info.DamageClose,
				DamageMiddle = info.DamageMiddle,
				DamageFar = info.DamageFar,
				DamageWallMul = info.DamageWallMul,
				ExplosionTime = info.ExplosionTime,
				HitWall = false,
				IsCritical = true,
			})
		end
	end

	ss.InkQueue[t] = true
	return t
end

local process = coroutine.create(ProcessInkQueue)
hook.Add("Move", "SplatoonSWEPs: Simulate ink", function(ply, mv)
	if coroutine.status(process) == "dead" then return end
	ply:LagCompensation(true)
	local ok, msg = coroutine.resume(process, ply)
	ply:LagCompensation(false)
	if not ok then ErrorNoHalt(msg) end
end)
