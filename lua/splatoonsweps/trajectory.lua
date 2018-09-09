
local ss = SplatoonSWEPs
if not ss then return end

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

function ss.GetDropType()
	return util.SharedRandom("SplatoonSWEPs: Drop ink type", 1, 3)
end

-- Physics simulation for ink trajectory.
-- The first some frames(1/60 sec.) ink flies without gravity.
-- After that, ink decelerates horizontally and is affected by gravity.
local Simulate, HitPaint, HitEntity = {}, {}, {}
function Simulate.weapon_shooter(ink)
	local g = physenv.GetGravity() * ss.InkGravityMul
	local LifeTime = math.max(0, CurTime() - ink.InitTime)
	local PrevTime = ink.Time
	if PrevTime > LifeTime then return end
	
	local Straight = ink.IsDrop and 0 or ink.Info.Straight
	local MaxFrame = Straight + ss.ShooterDecreaseFrame
	local MaxPos = ink.InitPos + ink.Velocity * (MaxFrame - ss.ShooterDecreaseFrame / 2)
	for Pos, Time in pairs {[ink.endpos] = LifeTime, [ink.start] = PrevTime} do
		if not ink.IsDrop and Time < Straight then -- Goes Straight
			Pos:Set(ink.InitPos + ink.Velocity * math.Clamp(Time, 0, Straight))
		elseif Time > Straight + ss.ShooterDecreaseFrame then -- Falls Straight
			local FallTime = math.max(Time - Straight - ss.ShooterDecreaseFrame, 0)
			if FallTime > ss.ShooterTermTime then
				local v = g * ss.ShooterTermTime
				Pos:Set(MaxPos - v * ss.ShooterTermTime / 2 + v * FallTime)
			else
				Pos:Set(MaxPos + g * FallTime * FallTime / 2)
			end
		else
			Pos:Set(ink.InitPos + ink.Velocity * (Straight + Time) / 2)
		end
	end
	
	ink.Time = LifeTime
	if PrevTime < MaxFrame and MaxFrame < LifeTime then
		ink.endpos = MaxPos
		ink.Time = MaxFrame + ss.FrameToSec
	end
	
	if not IsFirstTimePredicted() then return end
	if ink.SplashCount <= ink.SplashNum then -- Creates ink drops
		dropdata.InkRadius = ink.SplashRadius
		dropdata.MinRadius = ink.SplashRadius
		dropdata.InitTime = CurTime() - ss.ShooterDecreaseFrame
		local Length = (ink.endpos - ink.InitPos):Length2D()
		local NextLength = ink.SplashCount * ink.Info.SplashInterval + ink.SplashInit
		while Length >= NextLength and ink.SplashCount <= ink.SplashNum do
			ss.AddInk(ink.filter, ink.InitPos + ink.InitDirection * NextLength, ss.GetDropType(), true)
			if util.QuickTrace(ink.InitPos + ink.InitDirection * NextLength,
			ink.InitDirection * ink.Info.SplashInterval, ink.filter).Hit then
				break
			end
			
			NextLength = NextLength + ink.Info.SplashInterval
			ink.SplashCount = ink.SplashCount + 1
		end
	end
end

function HitPaint.weapon_shooter(ink, t)
	local ratio = 1
	local radius = ink.InkRadius
	if not ink.IsDrop and t.HitNormal.z > ss.MAX_COS_DEG_DIFF then
		local actual = (t.HitPos - ink.InitPos):Length2D()
		local min = SplashDistance + ss.mPaintNearDistance
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
	
	if (ss.sp or CLIENT and IsFirstTimePredicted())
	and t.Hit and (not ink.IsDrop or ink.PlayHitSound) then
		sound.Play("SplatoonSWEPs_Ink.HitWorld", t.HitPos)
	end
	
	ss.Paint(t.HitPos, t.HitNormal, radius, ink.Color, ink.Angle, ink.InkType, ratio)
end

function HitEntity.weapon_shooter(ink, t, w)
	local d, e, o = DamageInfo(), t.Entity, ink.filter
	local frac = (math.max(0, CurTime() - ink.InitTime)
	- ink.Info.DecreaseDamage) / ink.Info.MinDamageTime
	if (ss.sp or CLIENT and IsFirstTimePredicted())
	and not ink.IsDrop and ink.IsCarriedByLocalPlayer and e:Health() > 0 then
		local ent = ss.IsValidInkling(e) -- Entity hit effect here
		if not (ent and ss.IsAlly(ent, ink.Color)) then
			if ss.mp then
				surface.PlaySound(ink.IsCritical and ss.DealDamageCritical or ss.DealDamage)
			elseif SERVER then
				ink.filter:SendLua("surface.PlaySound(SplatoonSWEPs.DealDamage"
				.. (ink.IsCritical and "Critical" or "") .. ")")
			end
		end
		
		if ss.mp then return end
	end
	
	d:SetDamage(Lerp(1 - frac, ink.Info.MinDamage, ink.Info.Damage))
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(ink.Info.Damage)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(ss.IsValidInkling(o) or game.GetWorld())
	e:TakeDamageInfo(d)
end

function Simulate.weapon_charger(ink)
	local g = physenv.GetGravity() * ss.InkGravityMul
	local dir = ink.InitDirection
	local LifeTime = math.max(0, CurTime() - ink.InitTime)
	local PrevTime = ink.Time
	if PrevTime > LifeTime then return end
	
	local Length = math.Clamp(ink.Speed * LifeTime, 0, ink.Range)
	for Pos, Time in pairs {[ink.endpos] = LifeTime, [ink.start] = PrevTime} do
		if Time <= ink.Straight then -- Goes Straight
			Pos:Set(ink.InitPos + dir * math.Clamp(ink.Speed * Time, 0, ink.Range))
		else -- Falls Straight
			local FallTime = math.max(Time - ink.Straight, 0)
			if FallTime > ss.ShooterTermTime then
				local v = g * ss.ShooterTermTime
				Pos:Set(ink.StraightPos - v * ss.ShooterTermTime / 2 + v * FallTime)
			else
				Pos:Set(ink.StraightPos + g * FallTime * FallTime / 2)
			end
		end
	end
	
	if not IsFirstTimePredicted() then return end
	ink.Time = LifeTime
	dropdata.PlayHitSound = true
	dropdata.InitTime = CurTime() - ss.ShooterDecreaseFrame
	local NextLength = ink.SplashCount * ink.SplashInterval + ink.SplashInit
	while Length >= NextLength do -- Create ink drops
		dropdata.InkRadius = ink.SplashRadius / ink.SplashRatio
		local t = ss.AddInk(ink.filter, ink.InitPos + dir * NextLength, ss.GetDropType(), true)
		t.Ratio = ink.SplashRatio
		if util.QuickTrace(ink.InitPos + dir * NextLength, dir * ink.SplashInterval, ink.filter).Hit then
			break
		end
		
		NextLength = NextLength + ink.SplashInterval
		ink.SplashCount = ink.SplashCount + 1
		if NextLength >= ink.Range then
			dropdata.InkRadius = dropdata.InkRadius * ink.Info.SplashRadiusMul
			t = ss.AddInk(ink.filter, ink.StraightPos, ss.GetDropType(), true)
			t.Ratio = ink.SplashRatio
			
			HitPaint.weapon_charger(ink, {
				FractionPaintWall = .8,
				HitPos = ink.InitPos + dir * ink.Range,
				HitNormal = -dir,
			})
		elseif ink.SplashCount == 1 and ink.Charge > ink.FootpaintCharge then
			dropdata.InkRadius = ink.FootpaintRadius
			ss.AddInk(ink.filter, ink.InitPos, ss.GetDropType(), true)
		end
	end
	
	dropdata.PlayHitSound = nil
end

function HitPaint.weapon_charger(ink, t)
	ink.InkRadius = ink.SplashRadius
	HitPaint.weapon_shooter(ink, t)
	if ink.Charge < ink.Info.WallPaintCharge then return end
	if math.abs(t.HitNormal.z) > ss.MAX_COS_DEG_DIFF then return end
	
	local radius = ink.Info.MinSplashRadius
	local SplashNum = math.Round(Lerp(ink.Charge,
	ink.Info.MinWallPaintNum, ink.Info.MaxWallPaintNum))
	for i = 0, SplashNum do
		local pos = t.HitPos - vector_up * i * radius * Lerp(ink.Charge, 1, 1.25)
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
		}] = true
	end
end

function HitEntity.weapon_charger(ink, t, w)
	local LifeTime = math.max(0, CurTime() - FrameTime() - ink.InitTime)
	if LifeTime > ink.Straight then return end
	local d, e, o = DamageInfo(), t.Entity, ink.filter
	if (ss.sp or CLIENT and IsFirstTimePredicted())
	and ink.IsCarriedByLocalPlayer and e:Health() > 0 then
		local ent = ss.IsValidInkling(e) -- Entity hit effect here
		if not (ent and ss.IsAlly(ent, ink.Color)) then
			if ss.mp then
				surface.PlaySound(ink.Damage >= 100 and ss.DealDamageCritical or ss.DealDamage)
			elseif SERVER then
				ink.filter:SendLua("surface.PlaySound(SplatoonSWEPs.DealDamage"
				.. (ink.Damage >= 100 and "Critical" or "") .. ")")
			end
		end
		
		if ss.mp then return end
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

local function ProcessInkQueue(ply)
	while true do
		for ink in pairs(ss.InkQueue) do
			if not IsValid(ink.filter) then ss.InkQueue[ink] = nil continue end
			if ink.filter ~= ply then continue end
			
			ss.ProtectedCall(Simulate[ink.Base], ink)
			if not (ink.start and ink.endpos) then
				ss.InkQueue[ink] = nil
				continue
			end
			
			local t = util.TraceHull(ink)
			if not t.Hit then
				if not ss.IsInWorld(t.HitPos) then
					ss.InkQueue[ink] = nil
				end
				
				ink.start = t.HitPos
			elseif t.HitWorld then
				ink.endpos = t.HitPos - t.HitNormal * ink.Info.ColRadius * 2
				t = util.TraceLine(ink)
				ss.ProtectedCall(HitPaint[ink.Base], ink, t)
				ss.InkQueue[ink] = nil
			elseif IsValid(t.Entity) and ink.Info.Damage > 0 then -- If ink hits an NPC or something
				local w = ss.IsValidInkling(t.Entity)
				if not (w and ss.IsAlly(w, ink.Color)) then
					ss.ProtectedCall(HitEntity[ink.Base], ink, t, w)
				end
				ss.InkQueue[ink] = nil
			end
		end
		
		for ink in pairs(ss.PaintSchedule) do
			if CurTime() > ink.Time then
				ss.Paint(ink.pos, ink.normal, ink.radius, ink.color, ink.angle, ink.inktype, ink.ratio)
				ss.PaintSchedule[ink] = nil
			end
		end
		
		ply = coroutine.yield()
	end
end

-- Make an ink bullet for shooter.
-- Arguments:
--   Entity owner				| The owner of fired ink.
--   Vector pos					| Initial position of ink.
--   number inktype				| Shape of ink.
function ss.AddInk(ply, pos, inktype, isdrop)
	local w = ss.IsValidInkling(ply)
	if not w then return {} end
	local info = isdrop and dropdata or w.Primary
	local base = not isdrop and w.Base or "weapon_shooter"
	local dt = CLIENT and w:IsCarriedByLocalPlayer() and w:Ping() or 0
	local t = {
		Angle = w.InitAngle.yaw,
		Base = base,
		Color = w:GetNWInt "ColorCode",
		Info = info,
		InitDirection = isdrop and -vector_up or w.InitVelocity:GetNormalized(),
		InitPos = pos,
		InitTime = info.InitTime or CurTime(),
		InkType = math.floor(inktype),
		IsCarriedByLocalPlayer = SERVER or w:IsCarriedByLocalPlayer(),
		IsDrop = isdrop,
		Time = 0,
		Velocity = isdrop and vector_origin or w.InitVelocity,
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		endpos = Vector(),
		filter = ply,
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * info.ColRadius,
		mins = -ss.vector_one * info.ColRadius,
		start = pos,
	}
	
	if base == "weapon_shooter" then
		table.Merge(t, {
			InkRadius = info.InkRadius,
			MinRadius = info.MinRadius,
			PlayHitSound = isdrop and info.PlayHitSound or nil,
			Range = isdrop and 0 or info.InitVelocity * info.Straight,
			SplashCount = 0,
			SplashInit = info.SplashInterval / info.SplashPatterns * w.SplashInit,
			SplashInitMul = isdrop and 0 or w.SplashInit,
			SplashMinRadius = info.SplashRadius * info.MinRadius / info.InkRadius,
			SplashNum = isdrop and 0 or w.SplashNum,
			SplashRadius = info.SplashRadius,
		})
	elseif base == "weapon_charger" then
		local prog = w:GetChargeProgress()
		local Speed = w:GetInkVelocity()
		local SplashRadius = Lerp(prog, info.MinSplashRadius, info.MaxSplashRadius)
		local SplashRatio = Lerp(prog, info.MinSplashRatio, info.MaxSplashRatio)
		local SplashInterval = Lerp(prog, info.MinSplashInterval, info.MaxSplashInterval)
		SplashInterval = SplashInterval * SplashRadius * SplashRatio * .9
		table.Merge(t, {
			Charge = prog,
			Damage = w:GetDamage(),
			FootpaintCharge = info.FootpaintCharge,
			FootpaintRadius = SplashRadius / info.SplashRadiusMul,
			Range = w.Range,
			Speed = Speed,
			SplashCount = 0,
			SplashInit = SplashInterval / info.SplashPatterns * w.SplashInit + SplashRadius * SplashRatio,
			SplashInitMul = w.SplashInit,
			SplashInterval = SplashInterval,
			SplashRadius = SplashRadius,
			SplashRatio = 1 / SplashRatio,
			Straight = w.Range / Speed,
			StraightPos = pos + t.InitDirection * w.Range,
		})
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
