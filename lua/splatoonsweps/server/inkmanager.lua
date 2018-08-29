
-- This lua manages whole ink in map.

local ss = SplatoonSWEPs
if not ss then return end
local MAX_DEG_GETSURF = 30
local MAX_COS_GETSURF = math.cos(math.rad(MAX_DEG_GETSURF))
local MAX_DEGREES_DIFFERENCE = 45 -- Maximum angle difference between two surfaces
local MAX_COS_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) -- Used by filtering process
local MAX_INK_SIM_AT_ONCE = 60 -- Calculating ink trajectory at once
local MIN_BOUND = 20 -- Ink minimum bounding box scale
local POINT_BOUND = ss.vector_one * .1
local reference_polys = {}
local reference_vert = Vector(1)
local rootpi = math.sqrt(math.pi) / 2
local circle_polys = 360 / 12
local DecreaseFrame = 4 * ss.FrameToSec -- Decelerate frame
local TermTime = 10 * ss.FrameToSec -- Time to reach TermTimeinal velocity
local SplashDistance = 50 * ss.ToHammerUnits -- Transition between drop and splash
local PaintDistance = ss.mPaintFarDistance - ss.mPaintNearDistance
local PaintFraction = ss.mPaintNearDistance / PaintDistance
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
	RangeSqr = 0,
}
for i = 1, circle_polys do
	table.insert(reference_polys, Vector(reference_vert))
	reference_vert:Rotate(Angle(0, circle_polys))
end

-- Draws ink.
-- Arguments:
--   Vector pos		| Center position.
--   Vector normal	| Normal of the surface to draw.
--   number radius	| Scale of ink in Hammer units.
--   number angle	| Ink rotation in degrees.
--   number inktype | Shape of ink.
--   number ratio	| Aspect ratio.
function ss.Paint(pos, normal, radius, color, angle, inktype, ratio)
	local ang, polys = normal:Angle(), {}
	ang.roll = math.abs(normal.z) > MAX_COS_DEG_DIFF and angle * normal.z or ang.yaw
	for i, v in ipairs(reference_polys) do -- Scaling
		polys[i] = ss.To3D(v * radius, pos, ang)
	end
	
	local inkqueue = 0
	local rectsize = radius * rootpi
	local sizevec = Vector(rectsize, rectsize)
	local mins, maxs = ss.GetBoundingBox(polys, MIN_BOUND)
	for node in ss.BSPPairs(polys) do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(normal) <= MAX_COS_DEG_DIFF * (index < 0 and .5 or 1) or
			not ss.CollisionAABB(mins, maxs, surf.Mins[i], surf.Maxs[i]) then continue end
			local _, localang = WorldToLocal(vector_origin, ang, vector_origin, surf.Normals[i]:Angle())
			localang = surf.DefaultAngles[i] + ang.yaw - localang.roll
			net.Start "SplatoonSWEPs: DrawInk"
			net.WriteInt(index, ss.SURFACE_INDEX_BITS)
			net.WriteUInt(color, ss.COLOR_BITS)
			net.WriteUInt(inktype, 4)
			net.WriteVector(pos)
			net.WriteVector(Vector(radius, localang, ratio))
			net.Send(ss.PlayersReady)
			
			local pos2d = ss.To2D(pos, surf.Origins[i], surf.Angles[i])
			local bmins, bmaxs = pos2d - sizevec, pos2d + sizevec
			ss.AddInkRectangle(surf.InkCircles[i], ss.InkCounter, {
				angle = localang,
				bounds = {bmins.x, bmins.y, bmaxs.x, bmaxs.y},
				color = color,
				pos = pos2d,
				radius = radius,
				ratio = ratio,
				texid = inktype,
			})
			ss.InkCounter = ss.InkCounter + 1
		end
	end
end

-- Takes a TraceResult and returns ink color of its HitPos.
-- Argument:
--   TraceResult tr	| A TraceResult structure to pick up a position.
-- Returning:
--   number			| The ink color of the specified position.
--   nil			| If there is no ink, returns nil.
function ss.GetSurfaceColor(tr)
	if not tr.Hit then return end
	for node in ss.BSPPairs {tr.HitPos} do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(tr.HitNormal) <= MAX_COS_DEG_DIFF * (index < 0 and .5 or 1) or not
			ss.CollisionAABB(tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = ss.To2D(tr.HitPos, surf.Origins[i], surf.Angles[i])
			for r in SortedPairsByValue(surf.InkCircles[i], true) do
				local t = ss.InkShotMaterials[r.texid]
				local w, h = t.width, t.height
				local p = (p2d - r.pos) / r.radius
				p:Rotate(Angle(0, r.angle)) -- (-1, -1) <= (x, y) <= (1, 1)
				if -1 > p.x or p.x > 1 or -1 > p.y or p.y > 1 then continue end
				p = (p + ss.vector_one) / 2 -- (0, 0) <= (x, y) <= (1, 1)
				p.y = p.y * h -- 0 <= y <= h
				p.x = p.x - (1 - r.ratio) / 2 -- 0 <= x <= r.ratio
				p.x = p.x / r.ratio * w -- 0 <= x <= w
				p.x, p.y = math.Round(p.x), math.Round(p.y)
				if 0 < p.x and p.x < w and 0 < p.y and p.y < h and t[(p.y - 1) * w + p.x] then
					return r.color
				end
			end
		end
	end
end

-- Physics simulation for ink trajectory.
-- The first some frames(1/60 sec.) ink flies without gravity.
-- After that, ink decelerates horizontally and is affected by gravity.
local Simulate, HitPaint, HitEntity = {}, {}, {}
function Simulate.weapon_shooter(ink)
	local endpos = ink.endpos
	local g = physenv.GetGravity() * 15
	local LifeTime = math.max(0, CurTime() - ink.InitTime)
	local Straight = ink.IsDrop and 0 or ink.Info.Straight
	if not ink.IsDrop and LifeTime < Straight then -- Goes Straight
		ink.endpos = ink.InitPos + ink.Velocity * LifeTime
		ink.start = ink.InitPos + ink.Velocity * math.max(0, LifeTime - ss.FrameToSec)
	elseif LifeTime > Straight + DecreaseFrame then -- Falls Straight
		local p = ink.InitPos + ink.Velocity * (Straight + DecreaseFrame / 2)
		local FallTime = math.max(LifeTime - Straight - DecreaseFrame, 0)
		if FallTime > TermTime then
			local v = g * TermTime
			ink.endpos = p - v * TermTime / 2 + v * FallTime
			FallTime = math.max(FallTime - ss.FrameToSec, 0)
			ink.start = p - v * TermTime / 2 + v * FallTime
		else
			ink.endpos = p + g * FallTime * FallTime / 2
			FallTime = math.max(FallTime - ss.FrameToSec, 0)
			ink.start = p + g * FallTime * FallTime / 2
		end
	else
		local t = LifeTime - Straight
		ink.endpos = ink.InitPos + ink.Velocity * (Straight + t / 2)
		t = t - ss.FrameToSec
		ink.start = ink.InitPos + ink.Velocity
		* (Straight + t / (t > 0 and 2 or 1))
	end
	
	if not endpos then ink.start = ink.InitPos end
	if ink.SplashCount <= ink.SplashNum then -- Creates ink drops
		dropdata.InkRadius = ink.SplashRadius
		dropdata.MinRadius = ink.SplashRadius
		dropdata.InitTime = CurTime() - DecreaseFrame
		local Length = (ink.endpos - ink.InitPos):Length2D()
		local NextLength = ink.SplashCount * ink.Info.SplashInterval + ink.SplashInit
		while Length >= NextLength and ink.SplashCount <= ink.SplashNum do
			ss.AddInk(ink.filter, ink.InitPos + ink.InitDirection * NextLength, math.random(3), true)
			if util.QuickTrace(ink.InitPos + ink.InitDirection * NextLength,
			ink.InitDirection * ink.Info.SplashInterval, ink.filter).Hit then
				break
			end
			
			NextLength = NextLength + ink.Info.SplashInterval
			ink.SplashCount = ink.SplashCount + 1
		end
	end
end

function Simulate.weapon_charger(ink)
	local endpos = ink.endpos
	local g = physenv.GetGravity() * 15
	local LifeTime = math.max(0, CurTime() - ink.InitTime)
	local Length = math.Clamp(ink.Speed * LifeTime, 0, ink.Range)
	ink.endpos = ink.InitPos + ink.InitDirection * Length
	if ink.Speed * LifeTime <= ink.Range then -- Goes Straight
		ink.start = ink.InitPos + ink.Velocity * math.max(0, LifeTime - ss.FrameToSec)
	else -- Falls Straight
		local p = ink.StraightPos
		local FallTime = math.max(LifeTime - ink.Straight, 0)
		if FallTime > TermTime then
			local v = g * TermTime
			ink.endpos = p - v * TermTime / 2 + v * FallTime
			FallTime = math.max(FallTime - ss.FrameToSec, 0)
			ink.start = p - v * TermTime / 2 + v * FallTime
		else
			ink.endpos = p + g * FallTime * FallTime / 2
			FallTime = math.max(FallTime - ss.FrameToSec, 0)
			ink.start = p + g * FallTime * FallTime / 2
		end
	end
	
	if not endpos then ink.start = ink.InitPos end
	dropdata.InkRadius = ink.SplashRadius / ink.SplashRatio
	dropdata.InitTime = CurTime() - DecreaseFrame
	local NextLength = ink.SplashCount * ink.SplashInterval + ink.SplashInit
	while Length >= NextLength do -- Create ink drops
		local t = ss.AddInk(ink.filter, ink.InitPos + ink.InitDirection * NextLength, math.random(3), true)
		t.Ratio = ink.SplashRatio
		if util.QuickTrace(ink.InitPos + ink.InitDirection * NextLength,
		ink.InitDirection * ink.SplashInterval, ink.filter).Hit then
			break
		end
		
		NextLength = NextLength + ink.SplashInterval
		ink.SplashCount = ink.SplashCount + 1
		if NextLength >= ink.Range then
			dropdata.InkRadius = dropdata.InkRadius * ink.Info.SplashRadiusMul
			t = ss.AddInk(ink.filter, ink.StraightPos, math.random(3), true)
			t.Ratio = ink.SplashRatio
			
			HitPaint.weapon_charger(ink, {
				FractionPaintWall = .8,
				HitPos = ink.InitPos + ink.InitDirection * ink.Range,
				HitNormal = -ink.InitDirection,
			})
		elseif ink.SplashCount == 1 and ink.Charge > ink.FootpaintCharge then
			dropdata.InkRadius = ink.FootpaintRadius
			ss.AddInk(ink.filter, ink.InitPos, math.random(3), true)
		end
	end
end

function HitPaint.weapon_shooter(ink, t)
	local ratio = 1
	local radius = ink.InkRadius
	if not ink.IsDrop and t.HitNormal.z > MAX_COS_DEG_DIFF then
		local actual = (t.HitPos - ink.InitPos):Length2D()
		local min = SplashDistance + ss.mPaintNearDistance
		if actual > min then
			local max = ss.mPaintFarDistance
			local stretch = (actual - min) / max + 0.5
			radius, ratio = radius * (stretch + 0.5), 0.5 / stretch
		else
			ink.InkType = math.random(3)
		end
	else
		ink.InkType = math.random(3)
		ratio = ink.Ratio or ratio
	end
	
	ss.Paint(t.HitPos, t.HitNormal, radius, ink.Color, ink.Angle, ink.InkType, ratio)
end

function HitPaint.weapon_charger(ink, t)
	ink.InkRadius = ink.SplashRadius
	HitPaint.weapon_shooter(ink, t)
	if ink.Charge < ink.Info.WallPaintCharge then return end
	if math.abs(t.HitNormal.z) > MAX_COS_DEG_DIFF then return end
	local radius = ink.Info.MinSplashRadius
	local SplashNum = math.Round(Lerp(ink.Charge,
	ink.Info.MinWallPaintNum, ink.Info.MaxWallPaintNum))
	for i = 0, SplashNum do
		local pos = t.HitPos - vector_up * i * radius
		local tr = util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			endpos = pos - t.HitNormal,
			filter = ink.filter,
			mask = ss.SquidSolidMask,
			start = ink.InitPos,
		}
		
		if math.abs(tr.HitNormal.z) > MAX_COS_DEG_DIFF then continue end
		if (t.FractionPaintWall or 0) > tr.Fraction then continue end
		if tr.StartSolid or not tr.HitWorld then continue end
		ss.Paint(tr.HitPos, tr.HitNormal, radius, ink.Color, ink.Angle, math.random(3), 1)
	end
end

function HitEntity.weapon_shooter(ink, t, w)
	local d, o = DamageInfo(), ink.filter
	local frac = (math.max(0, CurTime() - ink.InitTime)
	- ink.Info.DecreaseDamage) / ink.Info.MinDamageTime
	d:SetDamage(Lerp(1 - frac, ink.Info.MinDamage, ink.Info.Damage))
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(ink.Info.Damage)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(ss.IsValidInkling(o) or game.GetWorld())
	t.Entity:TakeDamageInfo(d)
end

function HitEntity.weapon_charger(ink, t, w)
	if ink.Speed * math.max(0, CurTime() - FrameTime() - ink.InitTime) > ink.Range then return end
	local d, o = DamageInfo(), ink.filter
	d:SetDamage(ink.Damage)
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(ink.Damage)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(ss.IsValidInkling(o) or game.GetWorld())
	t.Entity:TakeDamageInfo(d)
end

local process = coroutine.create(function()
	ss.InkQueue = {}
	while true do
		local done = 0
		for ink in pairs(ss.InkQueue) do
			done = done + 1
			if done % MAX_INK_SIM_AT_ONCE == 0 then coroutine.yield() end
			
			ss.ProtectedCall(Simulate[ink.Base], ink)
			if not (ink.start and ink.endpos) then
				ss.InkQueue[ink] = nil
				continue
			end
			
			local t = util.TraceHull(ink)
			if not t.Hit then
				if not util.IsInWorld(t.HitPos) then
					ss.InkQueue[ink] = nil
				end
				
				ink.start = t.HitPos
				continue
			elseif t.HitWorld then
				ink.endpos = t.HitPos - t.HitNormal * ink.Info.ColRadius * 2
				t = util.TraceLine(ink)
				ss.ProtectedCall(HitPaint[ink.Base], ink, t)
			elseif IsValid(t.Entity) and ink.Info.Damage > 0 then -- If ink hits an NPC or something
				local w = ss.IsValidInkling(t.Entity)
				if not (w and ss.IsAlly(w, ink.Color)) then
					ss.ProtectedCall(HitEntity[ink.Base], ink, t, w)
				end
			end
			
			ss.InkQueue[ink] = nil
		end
		
		coroutine.yield()
	end
end)

-- Make an ink bullet for shooter.
-- Arguments:
--   Entity owner				| The owner of fired ink.
--   Vector pos					| Initial position of ink.
--   number inktype				| Shape of ink.
function ss.AddInk(ply, pos, inktype, isdrop)
	local w = ss.IsValidInkling(ply)
	if not w then return end
	local info = isdrop and dropdata or w.Primary
	local base = not isdrop and w.Base or "weapon_shooter"
	local t = {
		Angle = w.InitAngle.yaw,
		Base = base,
		Color = w.ColorCode,
		Info = info,
		InitDirection = isdrop and -vector_up or w.InitVelocity:GetNormalized(),
		InitPos = pos,
		InitTime = info.InitTime or CurTime(),
		InkType = inktype,
		IsDrop = isdrop,
		Velocity = isdrop and vector_origin or w.InitVelocity,
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
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
			Damage = w:GetLerp(prog, info.MinDamage, info.MaxDamage, Damage),
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

hook.Add("Tick", "SplatoonSWEPs: Simulate ink", function()
	if coroutine.status(process) == "dead" then return end
	local ok, msg = coroutine.resume(process)
	if not ok then ErrorNoHalt(msg) end
end)

-- Using timer to coroutine.create drops
-- local gravityscale = 2 / physenv.GetGravity():Length()
-- local droppos = ink.InitPos + ink.InitDirection * nextlen - vector_up * 6
-- ink.start, ink.endpos = droppos, droppos - vector_up * 32768
-- local tr = util.TraceHull(ink)
-- local radius = Lerp((ink.InitPos.z - tr.HitPos.z) / PaintDistance - PaintFraction, ink.SplashMinRadius, ink.SplashRadius)
-- timer.Simple(math.sqrt(math.abs(t.HitPos.z - tr.HitPos.z) * gravityscale), function()
	-- ss.Paint(tr.HitPos, tr.HitNormal, radius, ink.Color, ink.Angle, math.random(1, 3), 1)
-- end)
