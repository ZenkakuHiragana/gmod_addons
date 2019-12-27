
local ss = SplatoonSWEPs
if not ss then return end

local MAX_INK_SIM_AT_ONCE = 60 -- Calculating ink trajectory at once
local DropGravity = 1 * ss.ToHammerUnitsPerSec2
local function Simulate(ink)
	ink.CurrentSpeed = ink.Trace.start:Distance(ink.Trace.endpos) / FrameTime()
	ss.AdvanceBullet(ink)
	if not IsFirstTimePredicted() then return end
	ss.DoDropSplashes(ink)

	if not ink.Data.Weapon.IsBlaster then return end
	if not ink.Data.DoDamage then return end

	local tr, p = ink.Trace, ink.Parameters
	if tr.LifeTime <= p.mExplosionFrame then return end
	if ink.Exploded then return end
	ink.BlasterRemoval = p.mExplosionSleep
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

local function HitPaint(ink, t)
	local data, tr, weapon = ink.Data, ink.Trace, ink.Data.Weapon
	local hitfloor = t.HitNormal.z > ss.MAX_COS_DEG_DIFF
	local lmin = data.PaintNearDistance
	local lmin_ratio = data.PaintRatioNearDistance
	local lmax = data.PaintFarDistance
	local lmax_ratio = data.PaintRatioFarDistance
	local rmin = data.PaintNearRadius
	local rmax = data.PaintFarRadius
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
			local radiusmul = ink.Parameters.mPaintRateLastSplash
			if hitfloor then radius = radius * radiusmul end
			if tr.LengthSum < data.Range then
				local cos = math.Clamp(-data.InitDir.z, ss.MAX_COS_DEG_DIFF, 1)
				ratio = math.Remap(cos, ss.MAX_COS_DEG_DIFF, 1, ratio, 1)
			end
		elseif weapon.IsBlaster then
			data.DoDamage = false
			data.Type = ss.GetDropType()
			if not ink.Exploded then
				ink.BlasterHitWall = true
				tr.endpos:Set(t.HitPos)
				ss.MakeBlasterExplosion(ink)
			end
		end
	end

	if not hitfloor then
		ratio = 1
		data.Type = ss.GetDropType()
	end

	if (ss.sp or CLIENT and IsFirstTimePredicted()) and t.Hit and data.DoDamage then
		sound.Play("SplatoonSWEPs_Ink.HitWorld", t.HitPos)
	end
	
	ss.Paint(t.HitPos, t.HitNormal, radius * ratio, data.Color,
	data.Yaw, data.Type, 1 / ratio, tr.filter, weapon.ClassName)
	
	if not data.DoDamage then return end
	if hitfloor then return end
	
	local n = data.WallPaintMaxNum
	if data.WallPaintUseSplashNum then n = data.SplashNum - data.SplashCount end
	if not t.FractionPaintWall then t.FractionPaintWall = 0 end
	for i = 1, n do
		local pos = t.HitPos - vector_up * data.WallPaintFirstLength
		if i > 1 then pos.z = pos.z - (i - 1) * data.WallPaintLength end
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
				radius = data.WallPaintRadius,
				color = data.Color,
				angle = data.Yaw,
				inktype = ss.GetDropType(),
				ratio = 1,
				Time = CurTime() + i * data.WallPaintRadius / ink.CurrentSpeed,
				filter = tr.filter,
				ClassName = data.Weapon.ClassName,
			}] = true
		end
	end
end

local function HitEntity(ink, t)
	local data, tr, weapon = ink.Data, ink.Trace, ink.Data.Weapon
	local time = math.max(CurTime() - ink.InitTime, 0)
	local d, e, o = DamageInfo(), t.Entity, tr.filter
	if weapon.IsCharger and time > data.StraightFrame then return end
	if ss.LastHitID[e] == data.ID then return end
	ss.LastHitID[e] = data.ID -- Avoid multiple damages at once
	
	local decay_start = data.DamageMaxDistance
	local decay_end = data.DamageMinDistance
	local damage_max = data.DamageMax
	local damage_min = data.DamageMin
	local damage = damage_max
	if not weapon.IsCharger then
		local value = tr.LengthSum
		if weapon.IsShooter then
			value = math.max(CurTime() - ink.InitTime, 0)
		elseif weapon.IsSlosher then
			value = tr.endpos.z - data.InitPos.z
		end

		local frac = math.Remap(value, decay_start, decay_end, 0, 1)
		damage = Lerp(frac, damage_max, damage_min)
	end

	if ink.IsCarriedByLocalPlayer then
		local te = util.TraceLine {start = t.HitPos, endpos = e:WorldSpaceCenter()}
		ss.CreateHitEffect(data.Color, data.IsCritical and 1 or 0, te.HitPos, te.HitNormal)
		if ss.mp and CLIENT then return end
	end

	d:SetDamage(damage)
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

local function ProcessInkQueue(ply)
	local Benchmark = SysTime()
	while true do
		repeat coroutine.yield() until IsFirstTimePredicted()
		Benchmark = SysTime()
		for inittime, inkgroup in SortedPairs(ss.InkQueue) do
			local k = 1
			for i = 1, #inkgroup do
				local ink = inkgroup[i]
				local removal = not ink
				if ink then
					local data, tr, weapon = ink.Data, ink.Trace, ink.Data.Weapon
					removal = removal or not (IsValid(tr.filter) and IsValid(data.Weapon))
					if not removal and (not tr.filter:IsPlayer() or tr.filter == ply) then
						Simulate(ink)
						tr.maxs = ss.vector_one * data.ColRadiusWorld
						tr.mins = -tr.maxs
						tr.mask = ss.SquidSolidMaskBrushOnly
						local trworld = util.TraceHull(tr)
						tr.maxs = ss.vector_one * data.ColRadiusEntity
						tr.mins = -tr.maxs
						tr.mask = ss.SquidSolidMask
						local trent = util.TraceHull(tr)
						if ink.BlasterRemoval or not (trworld.Hit or ss.IsInWorld(trworld.HitPos)) then
							removal = true
						elseif data.DoDamage and IsValid(trent.Entity) and trent.Entity:Health() > 0 then
							local w = ss.IsValidInkling(trent.Entity) -- If ink hits someone
							if not (w and ss.IsAlly(w, data.Color)) then HitEntity(ink, trent) end
							removal = true
						elseif trworld.Hit then
							tr.endpos = trworld.HitPos - trworld.HitNormal * data.ColRadiusWorld * 2
							HitPaint(ink, util.TraceLine(tr))
							removal = true
						end

						if SysTime() - Benchmark > ss.FrameToSec then
							coroutine.yield()
							Benchmark = SysTime()
						end
					end
				end
				
				if removal then
					inkgroup[i] = nil
				else -- Move i's kept value to k's position, if it's not already there.
					if i ~= k then inkgroup[k], inkgroup[i] = ink end
					k = k + 1 -- Increment position of where we'll place the next kept value.
				end

				if #inkgroup == 0 then ss.InkQueue[inittime] = nil end
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
	local data, tr, p = ink.Data, ink.Trace, ink.Parameters
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
				e:SetRadius(p.mCollisionRadiusNear / 2)
				ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsBlasterTrail", e)
			end
			
			ss.SetEffectColor(e, data.Color)
			ss.SetEffectColRadius(e, data.SplashColRadius)
			ss.SetEffectDrawRadius(e, data.SplashDrawRadius)
			ss.SetEffectEntity(e, data.Weapon)
			ss.SetEffectFlags(e, 1)
			ss.SetEffectInitPos(e, droppos - vector_up * data.SplashDrawRadius)
			ss.SetEffectInitVel(e, data.InitVel)
			ss.SetEffectSplash(e, Angle(0, 0, data.SplashLength))
			ss.SetEffectSplashInitRate(e, Vector(0))
			ss.SetEffectSplashNum(e, 0)
			ss.SetEffectStraightFrame(e, 0)
			ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsShooterInk", e)
		else
			if IsCharger and data.SplashCount == 0 then
				local paintlastmul = p.mPaintRateLastSplash
				local paintradius = data.PaintNearRadius / paintlastmul
				local footpaintcharge = p.mSplashNearFootOccurChargeRate
				local footpaint = IsBamboozler or data.Charge > footpaintcharge
				mul = (footpaint and 1 or 0) / paintlastmul
				dropdata.InitPos = dropdata.InitPos + data.InitDir * (1 - mul) * paintradius
				HitPaint(ink, {
					FractionPaintWall = .8,
					HitPos = data.InitPos + data.InitDir * data.Range,
					HitNormal = -data.InitDir,
				})
			end

			if mul > 0 then
				dropdata.PaintFarRadius = data.SplashPaintRadius * mul
				dropdata.PaintNearRadius = data.SplashPaintRadius * mul
				dropdata.Type = ss.GetDropType()
				ss.AddInk(p, dropdata)
			end

			hull.start = droppos
			hull.endpos = droppos + data.InitDir * data.SplashLength
			if util.TraceHull(hull).Hit then break end
		end

		NextLength = NextLength + data.SplashLength
		data.SplashCount = data.SplashCount + 1
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
	t.CurrentSpeed = t.Data.InitSpeed

	local t0 = t.InitTime
	local dest = ss.InkQueue[t0] or {}
	ss.InkQueue[t0], dest[#dest + 1] = dest, t
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
	local data, tr, p, weapon = ink.Data, ink.Trace, ink.Parameters, ink.Data.Weapon
	local attacker = IsValid(tr.filter) and tr.filter or game.GetWorld()
	local inflictor = ss.IsValidInkling(tr.filter) or game.GetWorld()
	local hurtowner = ss.GetOption "weapon_splatoonsweps_blaster_base" "hurtowner"
	local dmul = ink.BlasterHitWall and p.mShotCollisionHitDamageRate or 1
	local dnear = p.mDamageNear * dmul
	local dmid = p.mDamageMiddle * dmul
	local dfar = p.mDamageFar * dmul
	local rmul = ink.BlasterHitWall and p.mShotCollisionRadiusRate or 1
	local rnear = p.mCollisionRadiusNear * rmul
	local rmid = p.mCollisionRadiusMiddle * rmul
	local rfar = p.mCollisionRadiusFar * rmul

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
	e:SetFlags(ink.BlasterHitWall and 1 or 0)
	e:SetRadius(rfar)
	ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsBlasterExplosion", e, true, weapon.IgnorePrediction)

	-- Trace around and paint
	local a = data.InitDir:Angle()
	if ink.BlasterHitWall then a:RotateAroundAxis(a:Right(), -90) end
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
			endpos = tr.endpos + d * p.mMoveLength,
			filter = tr.filter,
			mask = ss.SquidSolidMaskBrushOnly,
		}

		if t.Hit and not t.StartSolid then
			local distance = (t.HitPos - t.StartPos):Length2D()
			local frac = distance / p.mBoundPaintMinDistanceXZ
			local radius = Lerp(frac, p.mBoundPaintMaxRadius, p.mBoundPaintMinRadius)
			ss.Paint(t.HitPos, t.HitNormal, radius, data.Color, data.Yaw, ss.GetDropType(), 1, tr.filter, weapon.ClassName)
		end
	end

	if not p.mSphereSplashDropOn then return end

	-- Create a blaster's drop
	local dropdata = ss.MakeProjectileStructure()
	table.Merge(dropdata, {
		Color = data.Color,
		ColRadiusEntity = p.mSphereSplashDropCollisionRadius,
		ColRadiusWorld = p.mSphereSplashDropCollisionRadius,
		DoDamage = false,
		Gravity = DropGravity,
		InitPos = tr.endpos,
		InitVel = vector_up * p.mSphereSplashDropInitSpeed,
		PaintFarDistance = p.mPaintFarDistance,
		PaintFarRadius = p.mSphereSplashDropPaintRadius,
		PaintNearDistance = p.mPaintNearDistance,
		PaintNearRadius = p.mSphereSplashDropPaintRadius,
		Weapon = data.Weapon,
		Yaw = data.Yaw,
	})
	
	ss.SetEffectColor(e, dropdata.Color)
	ss.SetEffectColRadius(e, dropdata.ColRadiusWorld)
	ss.SetEffectDrawRadius(e, p.mSphereSplashDropDrawRadius)
	ss.SetEffectEntity(e, dropdata.Weapon)
	ss.SetEffectFlags(e, dropdata.Weapon, 3)
	ss.SetEffectInitPos(e, dropdata.InitPos)
	ss.SetEffectInitVel(e, dropdata.InitVel)
	ss.SetEffectSplash(e, Angle(0, 0, 0))
	ss.SetEffectSplashInitRate(e, Vector(0))
	ss.SetEffectSplashNum(e, 0)
	ss.SetEffectStraightFrame(e, 0)
	ss.UtilEffectPredicted(tr.filter, "SplatoonSWEPsShooterInk", e, true, weapon.IgnorePrediction)
	ss.AddInk(p, dropdata)
end
