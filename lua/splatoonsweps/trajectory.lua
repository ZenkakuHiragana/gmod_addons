
local ss = SplatoonSWEPs
if not ss then return end

ss.Simulate = {}
local Simulate, HitPaint, HitEntity = {}, {}, {}
local MAX_INK_SIM_AT_ONCE = 60 -- Calculating ink trajectory at once
local DropGravity = 1 * ss.ToHammerUnitsPerSec2

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

function ss.DoDropSplashes(ink, iseffect)
	local data, parameters, tr = ink.Data, ink.Parameters, ink.Trace
	if not data.DoDamage then return end
	if data.SplashCount >= data.SplashNum then return end
	local IsBamboozler = data.Weapon.IsBamboozler
	local IsBlaster = data.Weapon.IsBlaster
	local IsCharger = data.Weapon.IsCharger
	local DropDir = data.InitDir
	local Length = tr.endpos:Distance(data.InitPos)
	local NextLength = (data.SplashCount + data.SplashInitRate) * data.SplashLength
	local dropdata = ss.MakeProjectileStructure()
	table.Merge(dropdata, {
		Charge = data.Charge,
		Color = data.Color,
		ColRadiusEntity = data.SplashColRadius,
		ColRadiusWorld = data.SplashColRadius,
		DoDamage = false,
		Gravity = DropGravity,
		PaintFarRatio = data.SplashRatio,
		PaintNearRatio = data.SplashRatio,
		Range = 0,
		Weapon = data.Weapon,
		Yaw = data.Yaw,
	})

	if not IsCharger then
		Length = (tr.endpos - data.InitPos):Length2D()
		DropDir = Vector(data.InitDir.x, data.InitDir.y, 0):GetNormalized()
	end
	
	while Length >= NextLength and data.SplashCount < data.SplashNum do -- Creates ink drops
		local droppos = data.InitPos + DropDir * NextLength
		if not IsCharger then
			local frac = NextLength / Length
			if frac ~= frac then frac = 0 end
			droppos.z = Lerp(frac, data.InitPos.z, tr.endpos.z)
		end

		local hull = {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			start = data.InitPos,
			endpos = droppos,
			filter = tr.filter,
			mask = ss.SquidSolidMask,
			maxs = tr.maxs,
			mins = tr.mins,
		}
		local t = util.TraceHull(hull)
		local mul = 1
		dropdata.InitPos = t.HitPos
		
		if iseffect then
			local e = EffectData()
			if IsBlaster then
				e:SetColor(data.Color)
				e:SetNormal(data.InitDir)
				e:SetOrigin(dropdata.InitPos)
				e:SetRadius(parameters.mCollisionRadiusNear / 2)
				ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsBlasterTrail", e)
			end
			
			ss.SetEffectColor(e, data.Color)
			ss.SetEffectColRadius(e, data.SplashColRadius)
			ss.SetEffectDrawRadius(e, data.SplashDrawRadius)
			ss.SetEffectEntity(e, data.Weapon)
			ss.SetEffectFlags(e, 1)
			ss.SetEffectInitPos(e, droppos)
			ss.SetEffectInitVel(e, data.InitVel)
			ss.SetEffectSplash(e, Angle(0, 0, data.SplashLength))
			ss.SetEffectSplashInitRate(e, Vector(0))
			ss.SetEffectSplashNum(e, 0)
			ss.SetEffectStraightFrame(e, 0)
			ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsShooterInk", e)
		else
			if IsCharger and data.SplashCount == 0 then
				local paintlastmul = parameters.mPaintRateLastSplash
				local paintradius = data.PaintNearRadius / paintlastmul
				local footpaintcharge = parameters.mSplashNearFootOccurChargeRate
				local footpaint = IsBamboozler or data.Charge > footpaintcharge
				mul = (footpaint and 1 or 0) / paintlastmul
				dropdata.InitPos = dropdata.InitPos + data.InitDir * (1 - mul) * paintradius
				HitPaint.weapon_splatoonsweps_charger(ink, {
					FractionPaintWall = .8,
					HitPos = data.InitPos + data.InitDir * data.Range,
					HitNormal = -data.InitDir,
				})
			end

			if mul > 0 then
				dropdata.PaintFarRadius = data.SplashPaintRadius * mul
				dropdata.PaintNearRadius = data.SplashPaintRadius * mul
				dropdata.Type = ss.GetDropType()
				ss.AddInk(parameters, dropdata)
			end

			hull.start = droppos
			hull.endpos = droppos + data.InitDir * data.SplashLength
			if util.TraceHull(hull).Hit then break end
		end

		NextLength = NextLength + data.SplashLength
		data.SplashCount = data.SplashCount + 1
	end
end

function Simulate.weapon_splatoonsweps_shooter(ink)
	ss.AdvanceBullet(ink)
	if not IsFirstTimePredicted() then return end
	ss.DoDropSplashes(ink)

	if not ink.Data.Weapon.IsBlaster then return end
	if not ink.Data.DoDamage then return end

	local tr = ink.Trace
	if tr.LifeTime <= ink.Parameters.mExplosionFrame then return end
	if ink.Hit or ink.Exploded then return end
	ink.Exploded = true
	tr.collisiongroup = COLLISION_GROUP_DEBRIS
	ss.MakeBlasterExplosion(ink)
end

local function HitSmoke(ink, t) -- FIXME: Don't emit it twice
	local data, weapon = ink.Data, ink.Data.Weapon
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

function HitPaint.weapon_splatoonsweps_shooter(ink, t)
	local data, parameters, tr, weapon = ink.Data, ink.Parameters, ink.Trace, ink.Data.Weapon
	local hitfloor = t.HitNormal.z > ss.MAX_COS_DEG_DIFF
	local lmin = data.PaintNearDistance
	local lmin_ratio = data.PaintRatioNearDistance
	local lmax = data.PaintFarDistance
	local lmax_ratio = data.PaintRatioFarDistance
	local rmin = data.PaintNearRadius
	local rmax = data.PaintFarRadius
	local radiusmul = parameters.mPaintRateLastSplash
	local ratio_min = data.PaintNearRatio
	local ratio_max = data.PaintFarRatio
	local length = math.Clamp(tr.LengthSum, lmin, lmax)
	local length2d = math.Clamp((t.HitPos - data.InitPos):Length2D(), lmin_ratio, lmax_ratio)
	local radius = math.Remap(length, lmin, lmax, rmin, rmax)
	local ratio = math.Remap(length2d, lmin_ratio, lmax_ratio, ratio_min, ratio_max)
	if length == lmin and lmin == lmax then radius = rmax end -- Avoid NaN
	if length2d == lmin_ratio and lmin_ratio == lmax_ratio then ratio = ratio_max end
	if length2d == lmin_ratio then data.Type = ss.GetDropType() end
	if data.DoDamage then
		if weapon.IsCharger then
			HitSmoke(ink, t)
			if hitfloor then radius = radius * radiusmul end
			if tr.LengthSum < data.Range then
				local cos = math.Clamp(-data.InitDir.z, ss.MAX_COS_DEG_DIFF, 1)
				ratio = math.Remap(cos, ss.MAX_COS_DEG_DIFF, 1, ratio, 1)
			end
		elseif weapon.IsBlaster then
			data.DoDamage = false
			data.Type = ss.GetDropType()
			if not ink.Exploded then
				ink.HitWall = true
				tr.endpos:Set(t.HitPos)
				ss.MakeBlasterExplosion(ink)
			end
		end
	end

	if not hitfloor then ratio = 1 end
	if (ss.sp or CLIENT and IsFirstTimePredicted()) and t.Hit and data.DoDamage then
		sound.Play("SplatoonSWEPs_Ink.HitWorld", t.HitPos)
	end
	
	ss.Paint(t.HitPos, t.HitNormal, radius * ratio, data.Color,
	data.Yaw, data.Type, 1 / ratio, tr.filter, weapon.ClassName)
	
	if not weapon.IsCharger then return end
	if not data.DoDamage then return end
	if hitfloor then return end
	local radiuswall = rmin / radiusmul
	local wallfrac = data.Charge / parameters.mMaxHitSplashNumChargeRate
	local n = math.Round(Lerp(wallfrac, parameters.mMinChargeHitSplashNum, parameters.mMaxChargeHitSplashNum))
	if not t.FractionPaintWall then t.FractionPaintWall = 0 end
	for i = 1, n do
		local pos = t.HitPos - vector_up * i * radiuswall * Lerp(wallfrac, 1, 1.25)
		local tn = util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			endpos = pos - t.HitNormal,
			filter = tr.filter,
			mask = ss.SquidSolidMask,
			start = data.InitPos,
		}

		if math.abs(tn.HitNormal.z) < ss.MAX_COS_DEG_DIFF
		and t.FractionPaintWall < tn.Fraction
		and not tn.StartSolid and tn.HitWorld then
			ss.PaintSchedule[{
				pos = tn.HitPos,
				normal = tn.HitNormal,
				radius = radiuswall,
				color = data.Color,
				angle = data.Yaw,
				inktype = ss.GetDropType(),
				ratio = 1,
				Time = CurTime() + i * radiuswall / data.InitSpeed,
				filter = tr.filter,
				ClassName = data.Weapon.ClassName,
			}] = true
		end
	end
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

Simulate.weapon_splatoonsweps_blaster_base = Simulate.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_blaster_base = HitEntity.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_blaster_base = HitPaint.weapon_splatoonsweps_shooter
Simulate.weapon_splatoonsweps_charger = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_charger = HitPaint.weapon_splatoonsweps_shooter
Simulate.weapon_splatoonsweps_slosher_base = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_slosher_base = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_slosher_base = HitEntity.weapon_splatoonsweps_shooter
Simulate.weapon_splatoonsweps_splatling = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_splatling = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_splatling = HitEntity.weapon_splatoonsweps_shooter
Simulate.weapon_splatoonsweps_roller = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_roller = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_roller = HitEntity.weapon_splatoonsweps_shooter

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
-- Arguments:
--   Vector InitVel       | Initial velocity in Hammer units/s
--   number StraightFrame | Time to go straight in seconds
--   number AirResist     | Air resistance after it goes straight (0-1)
--   number Gravity       | Gravity acceleration in Hammer units/s^2
--   number t             | Time in seconds
function ss.GetBulletPos(InitVel, StraightFrame, AirResist, Gravity, t)
	local tf = math.max(t - StraightFrame, 0) -- Time for being "free state"
	local tg = tf^2 / 2 -- Time for applying gravity
	local g = -vector_up * Gravity -- Gravity accelerator
	local tlim = math.min(t, StraightFrame) -- Time limited to go straight
	local f = tf * ss.SecToFrame -- Frames for air resistance
	local ratio = 1 - AirResist
	local resist = (ratio^f - 1) / math.log(ratio) * ss.FrameToSec
	if resist ~= resist then resist = 0 end

	-- Additional pos = integral[ts -> t] InitVel * AirResist^u du (ts < t)
	return InitVel * (tlim + resist) + g * tg
end

function ss.AdvanceBullet(ink)
	local data, tr = ink.Data, ink.Trace
	local t = math.max(CurTime() - ink.InitTime, 0)
	tr.start:Set(tr.endpos)
	tr.endpos:Set(data.InitPos + ss.GetBulletPos(
		data.InitVel, data.StraightFrame, data.AirResist, data.Gravity, t))
	tr.LengthSum = tr.LengthSum + tr.start:Distance(tr.endpos)
	tr.LifeTime = t
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

	-- Find entities within explosion and deal damage
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

	-- Explosion effect
	local e = EffectData()
	e:SetOrigin(tr.endpos)
	e:SetColor(data.Color)
	e:SetFlags(ink.HitWall and 1 or 0)
	e:SetRadius(rfar)
	ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsBlasterExplosion", e, true, weapon.IgnorePrediction)

	-- Trace around and paint
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

	-- Create a blaster's drop
	local dropdata = ss.MakeProjectileStructure()
	table.Merge(dropdata, {
		Color = data.Color,
		ColRadiusEntity = parameters.mSphereSplashDropCollisionRadius,
		ColRadiusWorld = parameters.mSphereSplashDropCollisionRadius,
		DoDamage = false,
		Gravity = DropGravity,
		InitPos = tr.endpos,
		InitVel = vector_up * parameters.mSphereSplashDropInitSpeed,
		PaintFarDistance = parameters.mPaintFarDistance,
		PaintFarRadius = parameters.mSphereSplashDropPaintRadius,
		PaintNearDistance = parameters.mPaintNearDistance,
		PaintNearRadius = parameters.mSphereSplashDropPaintRadius,
		Weapon = data.Weapon,
		Yaw = data.Yaw,
	})
	
	ss.SetEffectColor(e, dropdata.Color)
	ss.SetEffectColRadius(e, dropdata.ColRadiusWorld)
	ss.SetEffectDrawRadius(e, parameters.mSphereSplashDropDrawRadius)
	ss.SetEffectEntity(e, dropdata.Weapon)
	ss.SetEffectFlags(e, dropdata.Weapon, 3)
	ss.SetEffectInitPos(e, dropdata.InitPos)
	ss.SetEffectInitVel(e, dropdata.InitVel)
	ss.SetEffectSplash(e, Angle(0, 0, 0))
	ss.SetEffectSplashInitRate(e, Vector(0))
	ss.SetEffectSplashNum(e, 0)
	ss.SetEffectStraightFrame(e, 0)
	ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsShooterInk", e, true, weapon.IgnorePrediction)
	ss.AddInk(parameters, dropdata)
end
