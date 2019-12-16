
local ss = SplatoonSWEPs
if not ss then return end

ss.Simulate = {}
local Simulate, HitPaint, HitEntity = {}, {}, {}
local MAX_INK_SIM_AT_ONCE = 60 -- Calculating ink trajectory at once
local SplashMinDistance = 50 * ss.ToHammerUnits -- Transition between drop and splash
local SplashMaxDistance = 100 * ss.ToHammerUnits

function ss.CreateHitEffect(color, flags, pos, normal)
	if ss.mp and (SERVER or not IsFirstTimePredicted()) then return end
	local e = EffectData()
	e:SetColor(color)
	e:SetFlags(flags)
	e:SetOrigin(pos)
	util.Effect("SplatoonSWEPsOnHit", e)
	e:SetAngles(normal:Angle())
	e:SetAttachment(6)
	e:SetEntity(NULL)
	e:SetFlags(129)
	e:SetOrigin(pos)
	e:SetRadius(50)
	e:SetScale(.4)
	util.Effect("SplatoonSWEPsMuzzleSplash", e)
end

function ss.GetDropType() -- math.floor(1 <= x < 4) -> 1, 2, 3
	return util.SharedRandom("SplatoonSWEPs: Drop ink type", 1, 4, CurTime())
end

function Simulate.weapon_splatoonsweps_shooter(ink)
	local data, parameters, tr = ink.Data, ink.Parameters, ink.Trace

	ss.SimulateBullet(ink)
	if not IsFirstTimePredicted() then return end
	if data.SplashCount >= data.SplashNum then return end

	local DropDir = Vector(data.InitDir.x, data.InitDir.y, 0):GetNormalized()
	local Length = (tr.endpos - data.InitPos):Length2D()
	local NextLength = (data.SplashCount + data.SplashInitRate) * data.SplashLength
	local dropdata = ss.MakeProjectileStructure()
	table.Merge(dropdata, {
		Color = data.Color,
		ColRadiusEntity = data.SplashColRadius,
		ColRadiusWorld = data.SplashColRadius,
		DoDamage = false,
		PaintFarRadius = data.SplashPaintRadius,
		PaintFarRatio = data.SplashRatio,
		PaintNearRadius = data.SplashPaintRadius,
		PaintNearRatio = data.SplashRatio,
		Weapon = data.Weapon,
		Yaw = data.Yaw,
	})
	
	while Length >= NextLength and data.SplashCount < data.SplashNum do -- Creates ink drops
		dropdata.InitPos = data.InitPos + DropDir * NextLength
		dropdata.InitPos.z = Lerp(NextLength / Length, data.InitPos.z, tr.endpos.z)
		ss.AddInk(parameters, dropdata)

		if data.Weapon.IsBlaster then
			local e = EffectData()
			e:SetColor(data.Color)
			e:SetNormal(data.InitDir)
			e:SetOrigin(dropdata.InitPos)
			e:SetRadius(parameters.mCollisionRadiusNear / 2)
			ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsBlasterTrail", e)
		end

		if util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			start = dropdata.InitPos,
			endpos = dropdata.InitPos + data.InitDir * data.SplashLength,
			filter = tr.filter,
			mask = ss.SquidSolidMask,
		} .Hit then
			break
		end

		NextLength = NextLength + data.SplashLength
		data.SplashCount = data.SplashCount + 1
	end
end

function HitPaint.weapon_splatoonsweps_shooter(ink, t)
	local data, parameters, tr, weapon = ink.Data, ink.Parameters, ink.Trace, ink.Data.Weapon
	local lmin = data.PaintNearDistance
	local lmin_ratio = data.PaintRatioNearDistance
	local lmax = data.PaintFarDistance
	local lmax_ratio = data.PaintRatioFarDistance
	local rmin = data.PaintNearRadius
	local rmax = data.PaintFarRadius
	local ratio = data.Ratio or 1
	local ratio_min = data.PaintNearRatio
	local ratio_max = data.PaintFarRatio
	local length = math.Clamp(tr.LengthSum, lmin, lmax)
	local radius = math.Remap(length, lmin, lmax, rmin, rmax)
	if length == lmin and lmin == lmax then radius = rmax end -- Avoid NaN
	if not weapon.IsBlaster and t.HitNormal.z > ss.MAX_COS_DEG_DIFF then
		local l = (t.HitPos - data.InitPos):Length2D()
		if l < lmin_ratio then data.Type = ss.GetDropType() end
		l = math.Clamp(l, lmin_ratio, lmax_ratio)
		ratio = 1 / math.Remap(l, lmin_ratio, lmax_ratio, ratio_min, ratio_max)
	else
		data.Type = ss.GetDropType()
		ratio = data.Ratio or 1
	end

	if (ss.sp or CLIENT and IsFirstTimePredicted()) and t.Hit and data.DoDamage then
		sound.Play("SplatoonSWEPs_Ink.HitWorld", t.HitPos)
	end

	ss.Paint(t.HitPos, t.HitNormal, radius / ratio, data.Color,
	data.Yaw, data.Type, ratio, tr.filter, weapon.ClassName)
end

function HitEntity.weapon_splatoonsweps_shooter(ink, t)
	local data, parameters, tr, weapon = ink.Data, ink.Parameters, ink.Trace, ink.Data.Weapon
	local d, e, o = DamageInfo(), t.Entity, tr.filter
	if ss.LastHitID[e] == data.ID then return end
	ss.LastHitID[e] = data.ID -- Avoid multiple damages at once
	
	local decay_start = data.DamageMaxDistance
	local decay_end = data.DamageMinDistance
	local damage_max = data.DamageMax
	local damage_min = data.DamageMin
	local value = tr.LengthSum
	if weapon.IsShooter then
		value = math.max(CurTime() - ink.InitTime, 0)
	elseif weapon.IsSlosher then
		value = tr.endpos.z - data.InitPos.z
	end

	local frac = math.Remap(value, decay_start, decay_end, 0, 1)
	if ink.IsCarriedByLocalPlayer then
		ss.CreateHitEffect(data.Color, weapon.IsBlaster and 1 or 0, t.HitPos, t.HitNormal)
		if ss.mp and CLIENT then return end
	end

	d:SetDamage(Lerp(frac, damage_max, damage_min))
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(damage_max)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(IsValid(weapon) and weapon or game.GetWorld())
	d:ScaleDamage(ss.ToHammerHealth)
	ss.ProtectedCall(e.TakeDamageInfo, e, d)
end

function Simulate.weapon_splatoonsweps_charger(ink)
	ss.SimulateBullet(ink)
	if not (ink.Data.DoDamage and IsFirstTimePredicted()) then return end
	local data, parameters, tr, weapon = ink.Data, ink.Parameters, ink.Trace, ink.Data.Weapon
	local dropdata = ss.MakeProjectileStructure()
	local footpaintcharge = parameters.mSplashNearFootOccurChargeRate
	local maxrate = parameters.mSplashBetweenMaxSplashPaintRadiusRate
	local minrate = parameters.mSplashBetweenMinSplashPaintRadiusRate
	local paintlastmul = parameters.mPaintRateLastSplash
	local paintradius = data.PaintNearRadius / paintlastmul
	
	local t = math.max(0, CurTime() - ink.InitTime)
	local lengthstep = Lerp(data.Charge, maxrate, minrate) * paintradius
	local length = math.Clamp(data.InitSpeed * t, 0, data.Range)
	local nextlength = (data.SplashCount + data.SplashInitRate) * lengthstep
	table.Merge(dropdata, {
		Charge = data.Charge,
		Color = data.Color,
		ColRadiusEntity = parameters.mSplashColRadius,
		ColRadiusWorld = parameters.mSplashColRadius,
		DoDamage = false,
		Range = 0,
		Ratio = data.Ratio,
		Weapon = weapon,
		Yaw = data.Yaw,
	})

	while length >= nextlength do -- Create ink drops
		local hull = {
			collisiongroup = ink.collisiongroup,
			endpos = data.InitPos + data.InitDir * nextlength,
			filter = tr.filter,
			mask = ss.SquidSolidMask,
			maxs = tr.maxs,
			mins = tr.mins,
			start = Vector(data.InitPos),
		}
		local mul = 1
		local t = util.TraceHull(hull)
		dropdata.InitPos = t.HitPos + t.HitNormal

		if data.SplashCount == 0 then
			local footpaint = weapon.IsBamboozler or data.Charge > footpaintcharge
			mul = (footpaint and 1 or 0) / paintlastmul
			dropdata.InitPos:Add(data.InitDir * (1 - mul) * paintradius)
			HitPaint.weapon_splatoonsweps_charger(ink, {
				FractionPaintWall = .8,
				HitPos = data.InitPos + data.InitDir * data.Range,
				HitNormal = -data.InitDir,
			})
		end
		
		if mul > 0 then
			dropdata.PaintFarRadius = paintradius * mul
			dropdata.PaintNearRadius = paintradius * mul
			dropdata.Type = ss.GetDropType()
			ss.AddInk(parameters, dropdata)
		end

		hull.start:Set(hull.endpos)
		hull.endpos:Add(data.InitDir * lengthstep)
		if util.TraceHull(hull).Hit then break end
		nextlength = nextlength + lengthstep
		data.SplashCount = data.SplashCount + 1
	end
end

local function HitSmoke(ink, t) -- FIXME: Don't emit it twice
	local data, weapon = ink.Data, ink.Data.Weapon
	if not data.DoDamage then return end
	if weapon.IsBamboozler then return end
	if not t.HitWorld or CurTime() - ink.InitTime > data.StraightFrame then return end
	local e = EffectData()
	e:SetAttachment(0)
	e:SetColor(data.Color)
	e:SetEntity(game.GetWorld())
	e:SetFlags(PATTACH_ABSORIGIN)
	e:SetOrigin(t.HitPos + t.HitNormal * 10)
	e:SetScale(6)
	e:SetStart(data.InitPos)
	util.Effect("SplatoonSWEPsMuzzleMist", e, true, weapon.IgnorePrediction)
end

function HitPaint.weapon_splatoonsweps_charger(ink, t)
	local data, parameters, trace, weapon = ink.Data, ink.Parameters, ink.Trace, ink.Data.Weapon
	local hitfloor = t.HitNormal.z > ss.MAX_COS_DEG_DIFF
	local ratio = hitfloor and data.Ratio or 1
	local radius = data.PaintNearRadius * data.Ratio
	local radiusmul = parameters.mPaintRateLastSplash
	if data.DoDamage then
		if not hitfloor then
			radius = radius / radiusmul
		end

		if trace.LengthSum < data.Range then
			local cos = math.Clamp(-data.InitDir.z, ss.MAX_COS_DEG_DIFF, 1)
			ratio = math.Remap(cos, ss.MAX_COS_DEG_DIFF, 1, ratio, 1)
		end
	end

	if (ss.sp or CLIENT and IsFirstTimePredicted()) and t.Hit and data.DoDamage then
		sound.Play("SplatoonSWEPs_Ink.HitWorld", t.HitPos)
	end

	ss.Paint(t.HitPos, t.HitNormal, radius / ratio, data.Color,
	data.Yaw, data.Type, ratio, trace.filter, weapon.ClassName)

	HitSmoke(ink, t)
	if not data.DoDamage then return end
	if hitfloor then return end
	local radiuswall = radius / radiusmul
	local wallfrac = data.Charge / parameters.mMaxHitSplashNumChargeRate
	local n = math.Round(Lerp(wallfrac, parameters.mMinChargeHitSplashNum, parameters.mMaxChargeHitSplashNum))
	if not t.FractionPaintWall then t.FractionPaintWall = 0 end
	for i = 1, n do
		local pos = t.HitPos - vector_up * i * radiuswall * Lerp(wallfrac, 1, 1.25)
		local tr = util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			endpos = pos - t.HitNormal,
			filter = trace.filter,
			mask = ss.SquidSolidMask,
			start = data.InitPos,
		}

		if math.abs(tr.HitNormal.z) < ss.MAX_COS_DEG_DIFF
		and t.FractionPaintWall < tr.Fraction
		and not tr.StartSolid and tr.HitWorld then
			ss.PaintSchedule[{
				pos = tr.HitPos,
				normal = tr.HitNormal,
				radius = radiuswall,
				color = data.Color,
				angle = data.Yaw,
				inktype = ss.GetDropType(),
				ratio = 1,
				Time = CurTime() + i * radiuswall / data.InitSpeed,
				filter = trace.filter,
				ClassName = data.Weapon.ClassName,
			}] = true
		end
	end
end

function HitEntity.weapon_splatoonsweps_charger(ink, t)
	HitSmoke(ink, t)
	local data, parameters = ink.Data, ink.Parameters
	local LifeTime = math.max(0, CurTime() - FrameTime() - ink.InitTime)
	local d, e, o = DamageInfo(), t.Entity, ink.Trace.filter
	local weapon = ss.IsValidInkling(o)
	if LifeTime > data.StraightFrame then return end
	if ss.LastHitID[e] == data.ID then return end
	ss.LastHitID[e] = data.ID -- Avoid multiple damages at once

	local damage_full = parameters.mFullChargeDamage
	local damage_max = parameters.mMaxChargeDamage
	local damage_min = parameters.mMinChargeDamage
	local damage = ss.Lerp3(data.Charge, damage_min, damage_max, damage_full)
	if ink.IsCarriedByLocalPlayer then
		ss.CreateHitEffect(data.Color, damage < 1 and 0 or 1, t.HitPos, t.HitNormal)
		if ss.mp and CLIENT then return end
	end

	d:SetDamage(damage)
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(damage_full)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(IsValid(weapon) and weapon or game.GetWorld())
	d:ScaleDamage(ss.ToHammerHealth)
	ss.ProtectedCall(e.TakeDamageInfo, e, d)
end

function Simulate.weapon_splatoonsweps_blaster_base(ink)
	local tr = ink.Trace
	Simulate.weapon_splatoonsweps_shooter(ink)
	if not ink.Data.DoDamage then return end
	if tr.LifeTime <= ink.Parameters.mExplosionFrame then return end
	if ink.Hit or ink.Exploded then return end
	ink.Exploded = true
	tr.collisiongroup = COLLISION_GROUP_DEBRIS
	ss.MakeBlasterExplosion(ink)
end

function HitPaint.weapon_splatoonsweps_blaster_base(ink, t)
	local data, parameters = ink.Data, ink.Parameters
	if ink.Data.DoDamage and not ink.Exploded then
		ink.HitWall = true
		ink.Trace.endpos:Set(t.HitPos)
		ss.MakeBlasterExplosion(ink)
	end

	ink.Data.DoDamage = false
	HitPaint.weapon_splatoonsweps_shooter(ink, t)
end

HitEntity.weapon_splatoonsweps_blaster_base = HitEntity.weapon_splatoonsweps_shooter
Simulate.weapon_splatoonsweps_splatling = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_splatling = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_splatling = HitEntity.weapon_splatoonsweps_shooter
Simulate.weapon_splatoonsweps_roller = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_roller = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_roller = HitEntity.weapon_splatoonsweps_shooter
Simulate.weapon_splatoonsweps_slosher_base = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_slosher_base = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_slosher_base = HitEntity.weapon_splatoonsweps_shooter

local function ProcessInkQueue(ply)
	local Benchmark = SysTime()
	while true do
		repeat coroutine.yield() until IsFirstTimePredicted()
		Benchmark = SysTime()
		for ink in pairs(ss.InkQueue) do
			local data, tr, weapon = ink.Data, ink.Trace, ink.Data.Weapon
			if IsValid(tr.filter) and IsValid(data.Weapon) then
				if not tr.filter:IsPlayer() or tr.filter == ply then
					ss.ProtectedCall(Simulate[weapon.Base], ink)
					if tr.start and tr.endpos then
						tr.maxs = ss.vector_one * data.ColRadiusWorld
						tr.mins = -tr.maxs
						tr.mask = ss.SquidSolidMaskBrushOnly
						local trworld = util.TraceHull(tr)
						tr.maxs = ss.vector_one * data.ColRadiusEntity
						tr.mins = -tr.maxs
						tr.mask = ss.SquidSolidMask
						local trent = util.TraceHull(tr)
						if not (trworld.Hit or ss.IsInWorld(trworld.HitPos)) then
							ss.InkQueue[ink] = nil
						elseif data.DoDamage and IsValid(trent.Entity) and trent.Entity:Health() > 0 then
							local w = ss.IsValidInkling(trent.Entity)
							if not (w and ss.IsAlly(w, data.Color)) then -- If ink hits someone
								ss.ProtectedCall(HitEntity[weapon.Base], ink, trent)
							end
							ss.InkQueue[ink] = nil
						elseif trworld.Hit then
							tr.endpos = trworld.HitPos - trworld.HitNormal * data.ColRadiusWorld * 2
							ss.ProtectedCall(HitPaint[weapon.Base], ink, util.TraceLine(tr))
							ss.InkQueue[ink] = nil
						end

						if SysTime() - Benchmark > ss.FrameToSec then
							coroutine.yield()
							Benchmark = SysTime()
						end
					else
						ss.InkQueue[ink] = nil
					end
				end
			else
				ss.InkQueue[ink] = nil
			end
		end

		for ink in pairs(ss.PaintSchedule) do
			if CurTime() > ink.Time then
				ss.Paint(ink.pos, ink.normal, ink.radius, ink.color,
				ink.angle, ink.inktype, ink.ratio, ink.filter, ink.ClassName)
				ss.PaintSchedule[ink] = nil

				if SysTime() - Benchmark > ss.FrameToSec then
					coroutine.yield()
					Benchmark = SysTime()
				end
			end
		end
	end
end

-- Make an ink bullet for shooter.
-- Arguments:
--   table parameters	| Table contains weapon parameters
--   table data			| Table contains ink bullet data
function ss.AddInk(parameters, data)
	local w = data.Weapon
	if not IsValid(w) then return {} end
	local ply = w.Owner
	local t = ss.MakeInkQueueStructure()
	t.Data = table.Copy(data)
	t.IsCarriedByLocalPlayer = Either(SERVER, ply:IsPlayer(), ss.ProtectedCall(w.IsCarriedByLocalPlayer, w))
	t.Parameters = parameters
	t.Trace.filter = ply
	t.Trace.endpos:Set(data.InitPos)
	t.Data.InitDir = t.Data.InitVel:GetNormalized()
	t.Data.InitSpeed = t.Data.InitVel:Length()
	if w.IsCharger and data.DoDamage then
		local c = data.Charge
		local fullrange = w.Scoped and parameters.mFullChargeDistanceScoped or parameters.mFullChargeDistance
		local maxrange = w.Scoped and parameters.mMaxDistanceScoped or parameters.mMaxDistance
		local minrange = parameters.mMinDistance
		local maxratio = parameters.mSplashDepthMaxChargeScaleRateByWidth
		local minratio = parameters.mSplashDepthMinChargeScaleRateByWidth
		local paintlastmul = parameters.mPaintRateLastSplash
		local paintmaxradius = parameters.mMaxChargeSplashPaintRadius
		local paintratio = Lerp(c, parameters.mPaintNearR_WeakRate, 1)
		local ratio = Lerp(c, minratio, maxratio)
		local paintradius = paintratio * paintmaxradius * paintlastmul * ratio
		t.Data.PaintFarRadius = paintradius
		t.Data.PaintNearRadius = paintradius
		t.Data.Range = ss.Lerp3(c, minrange, maxrange, fullrange)
		t.Data.Ratio = 1 / ratio
		t.Data.StraightFrame = t.Data.Range / t.Data.InitSpeed
	end

	ss.InkQueue[t] = true
	return t
end

local processes = {}
hook.Add("Move", "SplatoonSWEPs: Simulate ink", function(ply, mv)
	local p = processes[ply]
	if not p or coroutine.status(p) == "dead" then
		processes[ply] = coroutine.create(ProcessInkQueue)
		p = processes[ply]
		table.Empty(ss.InkQueue)
	end

	ply:LagCompensation(true)
	local ok, msg = coroutine.resume(p, ply)
	ply:LagCompensation(false)

	if ok then return end
	ErrorNoHalt(msg)
end)

-- Physics simulation for ink trajectory.
-- The first some frames(1/60 sec.) ink flies without gravity.
-- After that, ink decelerates horizontally and is affected by gravity.
function ss.SimulateBullet(ink)
	local data, tr = ink.Data, ink.Trace
	local gmul = data.IsRoller and ss.RollerGravityMul or ss.ShooterGravityMul
	local g = physenv.GetGravity() * gmul
	local t = math.max(CurTime() - ink.InitTime, 0)
	tr.start:Set(tr.endpos)
	tr.endpos:Set(data.InitPos)
	if data.DoDamage then
		local tmax = data.StraightFrame
		local tg = math.max(t - tmax, 0)^2 / 2
		local mFreeStateAirResist = ink.Parameters.mFreeStateAirResist
		local mFreeStateGravity = ink.Parameters.mFreeStateGravity
		if mFreeStateAirResist then -- For Slosher's projectile
			-- Additional pos = integral from tmax to t of InitVel * mFreeStateAirResist^u du (tmax < t)
			local gf = -vector_up * mFreeStateGravity
			local tlim = math.min(t, tmax) -- Time for straight movement
			local fr = math.max(t - tmax, 0) * ss.SecToFrame
			local ratio = 1 - mFreeStateAirResist
			local resist = (ratio^fr - 1) / math.log(ratio) * ss.FrameToSec
			tr.endpos:Add(data.InitVel * (tlim + resist) + gf * tg)
		else
			local dec = data.IsRoller and ss.RollerDecreaseFrame or ss.ShooterDecreaseFrame
			local a = data.InitVel / dec -- Deceleration
			local tdec = data.IsCharger and 0 or dec -- If it's charger's, then it immediately starts falling
			local tfall = tmax + tdec -- Time to start falling
			local tlim = math.min(t, tfall) -- Time for straight movement
			local t2 = math.max(tlim - tmax, 0)^2 / 2
			tr.endpos:Add(data.InitVel * tlim)
			tr.endpos:Add(g * tg - a * t2)
		end
	else -- It's a drop created by a bullet
		tr.endpos:Add(g * t^2 / 2)
		tr.LengthSum = tr.LengthSum + tr.start:Distance(tr.endpos)
	end

	tr.LifeTime = t
	tr.LengthSum = tr.LengthSum + tr.start:Distance(tr.endpos)
end

local components = {"x", "y", "z"}
local directions = {"GetForward", "GetRight", "GetUp"}
function ss.MakeBlasterExplosion(ink)
	local d = DamageInfo()
	local damagedealt = false
	local data, parameters, tr, weapon = ink.Data, ink.Parameters, ink.Trace, ink.Data.Weapon
	local attacker = IsValid(tr.filter) and tr.filter or game.GetWorld()
	local inflictor = ss.IsValidInkling(tr.filter) or game.GetWorld()
	local hurtowner = ss.GetOption "weapon_splatoonsweps_blaster_base" "hurtowner"
	local dmul = ink.HitWall and parameters.mShotCollisionHitDamageRate or 1
	local dnear = parameters.mDamageNear * dmul
	local dmid = parameters.mDamageMiddle * dmul
	local dfar = parameters.mDamageFar * dmul
	local rmul = ink.HitWall and parameters.mShotCollisionRadiusRate or 1
	local rnear = parameters.mCollisionRadiusNear * rmul
	local rmid = parameters.mCollisionRadiusMiddle * rmul
	local rfar = parameters.mCollisionRadiusFar * rmul
	for _, e in ipairs(ents.FindInSphere(tr.endpos, rfar)) do
		local target_weapon = ss.IsValidInkling(e)
		if IsValid(e) and e:Health() > 0 and ss.LastHitID[e] ~= data.ID
		and (not ss.IsAlly(target_weapon, data.Color) or hurtowner and e == tr.filter) then
			local dist = Vector()
			local maxs, mins = e:OBBMaxs(), e:OBBMins()
			local origin = e:LocalToWorld(e:OBBCenter())
			local size = (maxs - mins) / 2
			for i, dir in pairs {x = e:GetForward(), y = e:GetRight(), z = e:GetUp()} do
				local segment = dir:Dot(tr.endpos - origin)
				local sign = segment == 0 and 0 or segment > 0 and 1 or -1
				segment = math.abs(segment)
				if segment > size[i] then dist = dist + sign * (size[i] - segment) * dir end
			end

			local t = ss.SquidTrace
			t.start = tr.endpos
			t.endpos = tr.endpos + dist
			t.filter = not hurtowner and tr.filter or nil
			t = util.TraceLine(t)
			if not t.Hit or t.Entity == e then
				if ink.IsCarriedByLocalPlayer then
					ss.CreateHitEffect(data.Color, damagedealt and 6 or 2, tr.endpos + dist, -dist)
					if CLIENT and e ~= tr.filter then damagedealt = true break end
				end

				ss.LastHitID[e] = data.ID -- Avoid multiple damages at once
				damagedealt = damagedealt or ss.sp or e == tr.filter
				dist = dist:Length()

				local dmg
				if dist > rmid then
					dmg = math.Remap(dist, rmid, rfar, dmid, dfar)
				elseif dist > rnear then
					dmg = math.Remap(dist, rnear, rmid, dnear, dmid)
				else
					dmg = dnear
				end
				
				d:SetDamage(dmg)
				d:SetDamageForce((e:WorldSpaceCenter() - tr.endpos):GetNormalized() * dmg)
				d:SetDamagePosition(tr.endpos)
				d:SetDamageType(DMG_GENERIC)
				d:SetMaxDamage(dmg)
				d:SetReportedPosition(tr.endpos)
				d:SetAttacker(attacker)
				d:SetInflictor(inflictor)
				d:ScaleDamage(ss.ToHammerHealth)
				ss.ProtectedCall(e.TakeDamageInfo, e, d)
			end
		end
	end
	
	if ss.mp and not IsFirstTimePredicted() then return end

	local e = EffectData()
	e:SetOrigin(tr.endpos)
	e:SetColor(data.Color)
	e:SetFlags(ink.HitWall and 1 or 0)
	e:SetRadius(rfar)
	ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsBlasterExplosion", e, true, weapon.IgnorePrediction)

	local a = data.InitDir:Angle()
	if ink.HitWall then a:RotateAroundAxis(a:Right(), -90) end
	local a2, a3 = Angle(a), Angle(a)
	a2:RotateAroundAxis(a:Right(), 45)
	a2:RotateAroundAxis(a:Up(), 45)
	a3:RotateAroundAxis(a:Right(), 45)
	a3:RotateAroundAxis(a:Up(), -45)
	for _, d in ipairs {
		a:Forward(), -a:Forward(), a:Right(), -a:Right(), a:Up(),
		a2:Forward(), a2:Right(), -a2:Right(), a2:Up(),
		a3:Forward(), a3:Right(), -a3:Right(), a3:Up(),
	} do
		local t = util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			start = tr.endpos,
			endpos = tr.endpos + d * parameters.mMoveLength,
			filter = tr.filter,
			mask = ss.SquidSolidMaskBrushOnly,
		}

		if t.Hit and not t.StartSolid then
			local distance = (t.HitPos - t.StartPos):Length2D()
			local frac = distance / parameters.mBoundPaintMinDistanceXZ
			local radius = Lerp(frac, parameters.mBoundPaintMaxRadius, parameters.mBoundPaintMinRadius)
			ss.Paint(t.HitPos, t.HitNormal, radius, data.Color, data.Yaw, ss.GetDropType(), 1, tr.filter, weapon.ClassName)
		end
	end

	if parameters.mExplosionSleep then ss.InkQueue[ink] = nil end
	if not parameters.mSphereSplashDropOn then return end
	local dropdata = ss.MakeProjectileStructure()
	table.Merge(dropdata, {
		Color = data.Color,
		ColRadiusEntity = parameters.mSphereSplashDropCollisionRadius,
		ColRadiusWorld = parameters.mSphereSplashDropCollisionRadius,
		DoDamage = false,
		InitPos = tr.endpos,
		InitVel = vector_up * parameters.mSphereSplashDropInitSpeed,
		PaintFarDistance = parameters.mPaintFarDistance,
		PaintFarRadius = parameters.mSphereSplashDropPaintRadius,
		PaintNearDistance = parameters.mPaintNearDistance,
		PaintNearRadius = parameters.mSphereSplashDropPaintRadius,
		Weapon = data.Weapon,
		Yaw = data.Yaw,
	})
	
	local IsLP = CLIENT and weapon:IsCarriedByLocalPlayer() and 128 or 0
	e:SetAttachment(0)
	e:SetColor(dropdata.Color)
	e:SetEntity(dropdata.Weapon)
	e:SetFlags(IsLP + 3)
	e:SetMagnitude(dropdata.ColRadiusWorld)
	e:SetOrigin(dropdata.InitPos)
	e:SetScale(0)
	e:SetStart(dropdata.InitVel)
	ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsShooterInk", e, true, weapon.IgnorePrediction)
	ss.AddInk(parameters, dropdata)
end
