
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
local DecreaseFrame = 4 * ss.FrameToSec
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
function ss:Paint(pos, normal, radius, color, angle, inktype, ratio)
	local ang, polys = normal:Angle(), {}
	ang.roll = math.abs(normal.z) > MAX_COS_DEG_DIFF and angle * normal.z or ang.yaw
	for i, v in ipairs(reference_polys) do -- Scaling
		polys[i] = ss:To3D(v * radius, pos, ang)
	end
	
	local inkqueue = 0
	local rectsize = radius * rootpi
	local sizevec = Vector(rectsize, rectsize)
	local mins, maxs = ss:GetBoundingBox(polys, MIN_BOUND)
	for node in ss:BSPPairs(polys) do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(normal) <= MAX_COS_DEG_DIFF * (index < 0 and .5 or 1) or
			not ss:CollisionAABB(mins, maxs, surf.Mins[i], surf.Maxs[i]) then continue end
			local _, localang = WorldToLocal(vector_origin, ang, vector_origin, surf.Normals[i]:Angle())
			localang = surf.DefaultAngles[i] + ang.yaw - localang.roll
			net.Start "SplatoonSWEPs: DrawInk"
			net.WriteInt(index, ss.SURFACE_INDEX_BITS)
			net.WriteUInt(color, ss.COLOR_BITS)
			net.WriteUInt(inktype, 4)
			net.WriteVector(pos)
			net.WriteVector(Vector(radius, localang, ratio))
			net.Send(ss.PlayersReady)
			
			local pos2d = ss:To2D(pos, surf.Origins[i], surf.Angles[i])
			local bmins, bmaxs = pos2d - sizevec, pos2d + sizevec
			ss:AddInkRectangle(surf.InkCircles[i], ss.InkCounter, {
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
function ss:GetSurfaceColor(tr)
	if not tr.Hit then return end
	for node in ss:BSPPairs {tr.HitPos} do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(tr.HitNormal) <= MAX_COS_DEG_DIFF * (index < 0 and .5 or 1) or not
			ss:CollisionAABB(tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = ss:To2D(tr.HitPos, surf.Origins[i], surf.Angles[i])
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

-- Make an ink bullet for shooter.
-- Arguments:
--   Entity owner				| The owner of fired ink.
--   Vector pos					| Initial position of ink.
--   Vector velocity			| Initial velocity of ink.
--   number color				| Color code.
--   number angle				| Yaw component for painting direction.
--   number inktype				| Shape of ink.
--   number splashinit			| Seed for creating drops.
--   table info					| Containing these:
--     number Damage			|   Maximum damage in Hammer health.
--     number MinDamage			|   Minimum damage in Hammer health.
--     number MinDamageTime		|   Time to fly for dealing minimum damage in seconds.
--     number DecreaseDamage	|   Time to fly until starting to decrease damage in seconds.
--     number InitVelocity      |   Initial velocity in Hammer units / sec.
--     number InkRadius			|   Painting radius in Hammer units.
--     number MinRadius			|   Painting minimum radius in Hammer units, for falling from height.
--     number ColRadius			|   Ink collision radius in Hammer units.
--     number SplashRadius		|   Ink drop info.  Painting radius.
--     number SplashPatterns	|   mSplashSplitNum
--     number SplashNum			|   The number of drops.  May not be integer.
--     number SplashInterval	|   The interval between two drops.
--     number Straight			|   Time to start falling in seconds.
function ss:AddInk(owner, pos, velocity, color, angle, inktype, splashinit, info)
	local w = ss:IsValidInkling(owner)
	local ping = w and w:Ping() or 0
	local t = {
		Angle = angle,
		Color = color,
		Info = info,
		InitDirection = velocity:GetNormalized(),
		InitPos = pos,
		InitTime = info.InitTime or CurTime() - ping,
		InkType = inktype,
		InkRadius = info.InkRadius,
		MinRadius = info.MinRadius,
		Ping = ping,
		Range = info.InitVelocity * info.Straight,
		SplashCount = 0,
		SplashInit = info.SplashInterval / info.SplashPatterns * splashinit,
		SplashInitMul = splashinit,
		SplashMinRadius = info.SplashRadius * info.MinRadius / info.InkRadius,
		SplashRadius = info.SplashRadius,
		Velocity = velocity,
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		filter = owner,
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * info.ColRadius,
		mins = -ss.vector_one * info.ColRadius,
		start = pos,
	}
	
	t.SplashNum = math.floor(t.Info.SplashNum)
	t.SplashNum = t.SplashNum + (math.random() < t.Info.SplashNum % 1 and 1 or 0)
	ss.InkQueue[t] = true
end

-- Physics simulation for ink trajectory.
-- The first some frames(1/60 sec.) ink flies without gravity.
-- After that, ink decelerates horizontally and is affected by gravity.
local term = 10 * ss.FrameToSec -- Time to reach terminal velocity
local SplashDistance = 50 * ss.ToHammerUnits -- Transition between drop and splash [Splatoon units]
local PaintDistance = ss.mPaintFarDistance - ss.mPaintNearDistance
local PaintFraction = ss.mPaintNearDistance / PaintDistance
local process = coroutine.create(function()
	while true do
		local done = 0
		local ct = CurTime()
		local g = physenv.GetGravity() * 15
		for ink in pairs(ss.InkQueue) do
			done = done + 1
			if done % MAX_INK_SIM_AT_ONCE == 0 then coroutine.yield() end
			
			local endpos = ink.endpos
			local lifetime = math.max(0, ct - ink.InitTime)
			if lifetime < ink.Info.Straight then -- Goes straight
				ink.endpos = ink.InitPos + ink.Velocity * lifetime
				ink.start = ink.InitPos + ink.Velocity * math.max(0, lifetime - ss.FrameToSec)
			elseif lifetime > ink.Info.Straight + DecreaseFrame then -- Falls straight
				local pos = ink.InitPos + ink.Velocity * (ink.Info.Straight + DecreaseFrame / 2)
				local falltime = math.max(lifetime - ink.Info.Straight - DecreaseFrame, 0)
				if falltime > term then
					local v = g * term
					ink.endpos = pos - v * term / 2 + v * falltime
					falltime = math.max(falltime - ss.FrameToSec, 0)
					ink.start = pos - v * term / 2 + v * falltime
				else
					ink.endpos = pos + g * falltime * falltime / 2
					falltime = math.max(falltime - ss.FrameToSec, 0)
					ink.start = pos + g * falltime * falltime / 2
				end
			else
				local time = lifetime - ink.Info.Straight
				ink.endpos = ink.InitPos + ink.Velocity * (ink.Info.Straight + time / 2)
				time = time - ss.FrameToSec
				ink.start = ink.InitPos + ink.Velocity
				* (ink.Info.Straight + time / (time > 0 and 2 or 1))
			end
			
			if not endpos then ink.start = ink.InitPos end
			
			local t = util.TraceHull(ink)
			if ink.SplashCount <= ink.SplashNum then -- Creates an ink drop
				local len = (ink.endpos - ink.InitPos):Length2D()
				local nextlen = ink.SplashCount * ink.Info.SplashInterval + ink.SplashInit
				while len >= nextlen do -- Create drops
					dropdata.InkRadius = ink.SplashRadius
					dropdata.MinRadius = ink.SplashRadius
					dropdata.InitTime = CurTime() - DecreaseFrame
					ss:AddInk(ink.filter, ink.InitPos + ink.InitDirection
					* (nextlen + math.random(-1, 1) * ss.mSplashDrawRadius),
					Vector(), ink.Color, ink.Angle, 1, 0, dropdata)
					
					len = len - ink.Info.SplashInterval
					nextlen = nextlen + ink.Info.SplashInterval
					ink.SplashCount = ink.SplashCount + 1
				end
			end
			
			if not t.Hit then
				ink.start = t.HitPos
				continue
			elseif t.HitWorld then
				ink.endpos = t.HitPos - t.HitNormal * ink.Info.ColRadius * 2
				t = util.TraceLine(ink)
				
				local ratio = 1
				local radius = ink.InkRadius
				if ink.InkType > 3 and t.HitNormal.z > MAX_COS_DEG_DIFF then
					local actual = t.HitPos - ink.InitPos actual = actual:Length2D()
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
				end
				
				ss:Paint(t.HitPos, t.HitNormal, radius, ink.Color, ink.Angle, ink.InkType, ratio)
			elseif IsValid(t.Entity) and ink.Info.Damage > 0 then -- If ink hits an NPC or something
				local w = ss:IsValidInkling(t.Entity)
				if not (w and ss:IsAlly(w, ink.Color)) then
					local d, o = DamageInfo(), ink.filter
					local frac = (lifetime - ink.Info.DecreaseDamage - ink.Ping) / ink.Info.MinDamageTime
					d:SetDamage(Lerp(1 - frac, ink.Info.MinDamage, ink.Info.Damage))
					d:SetDamageForce(-t.HitNormal)
					d:SetDamagePosition(t.HitPos)
					d:SetDamageType(DMG_GENERIC)
					d:SetMaxDamage(ink.Info.Damage)
					d:SetReportedPosition(t.HitPos)
					d:SetAttacker(IsValid(o) and o or game.GetWorld())
					d:SetInflictor(ss:IsValidInkling(o) or game.GetWorld())
					t.Entity:TakeDamageInfo(d)
				end
			end
			
			ss.InkQueue[ink] = nil
		end
		
		coroutine.yield()
	end
end)

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
	-- ss:Paint(tr.HitPos, tr.HitNormal, radius, ink.Color, ink.Angle, math.random(1, 3), 1)
-- end)
