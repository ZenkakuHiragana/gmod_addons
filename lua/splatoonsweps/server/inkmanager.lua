
--This lua manages whole ink in map.
local ss = SplatoonSWEPs
if not ss then return end

local abs, create, insert, ipairs, next, pairs, resume, sort, status, yield
= math.abs, coroutine.create, table.insert, ipairs, next,
	pairs, coroutine.resume, table.sort, coroutine.status, coroutine.yield
local Angle, NormalizeAngle, Round, Send, SortedPairsByValue,
	Start, Vector, WorldToLocal, WriteInt, WriteUInt, WriteVector
= Angle, math.NormalizeAngle, math.Round, net.Send, SortedPairsByValue,
	net.Start, Vector, WorldToLocal, net.WriteInt, net.WriteUInt, net.WriteVector
local BSPPairs, CollisionAABB, GetBoundingBox, To2D, To3D
= ss.BSPPairs, ss.CollisionAABB, ss.GetBoundingBox, ss.To2D, ss.To3D
local PaintQueue = {}
local InkGroup = {}
local rootpi = math.sqrt(math.pi) / 2
local MIN_BOUND = 20 --Ink minimum bounding box scale
local MIN_BOUND_AREA = 64 --minimum ink bounding box area
local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local MAX_PROCESS_QUEUE_AT_ONCE = 4 --Running QueueCoroutine() at once
local MAX_INKQUEUE_AT_ONCE = 500 --Processing new ink request at once
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local reference_polys = {}
local reference_vert = Vector(1)
local circle_polys = 360 / 12
for i = 1, circle_polys do
	insert(reference_polys, Vector(reference_vert))
	reference_vert:Rotate(Angle(0, circle_polys))
end

--[1] = minimum bound, [2] = maximum bound
local function AddInkRectangle(ink, sz, newink)
	local nb, nr = newink.bounds, newink.ratio
	local n1, n2, n3, n4 = nb[1], nb[2], nb[3], nb[4]
	for r, z in pairs(ink) do
		local bounds, lr = r.bounds, r.lastratio
		if not next(bounds) then
			if lr > .6 then
				ink[r] = nil
			else
				r.lastratio = lr + 1e-4
			end
		else
			for b in pairs(bounds) do
				local b1, b2, b3, b4 = b[1], b[2], b[3], b[4]
				if (b3 - b1) * (b4 - b2) < MIN_BOUND_AREA then r.bounds[b] = nil continue end
				if n1 > b3 or n3 < b1 or n2 > b4 or n4 < b2 then continue end
				r.lastratio, r.bounds[b] = nr
				local x, y = {n1, n3, b1, b3}, {n2, n4, b2, b4} sort(x) sort(y)
				local x1, x2, x3, x4, y1, y2, y3, y4
					= x[1], x[2], x[3], x[4], y[1], y[2], y[3], y[4]
				local t = {
					{x1, y1, x2, y2}, {x2, y1, x3, y2}, {x3, y1, x4, y2},
					{x1, y2, x2, y3}, {x2, y2, x3, y3}, {x3, y2, x4, y3},
					{x1, y3, x2, y4}, {x2, y3, x3, y4}, {x3, y3, x4, y4},
				}
				for i = 1, 9 do
					local c = t[i]
					local c1, c2, c3, c4 = c[1], c[2], c[3], c[4]
					r.bounds[c] = b1 < c3 and b3 > c1 and b2 < c4 and b4 > c2 and
						(n1 >= c3 or n3 <= c1 or n2 >= c4 or n4 <= c2) or nil
				end
			end
		end
	end
	
	newink.bounds = {[nb] = true}
	ink[newink] = sz
end

-- SplatoonSWEPs:Paint()
-- Draws a drop of ink.
-- Arguments:
--   Vector pos		| Center position.
--   Vector normal	| Normal of the surface to draw.
--   number radius	| Scale of ink in Hammer units.
--   number angle	| Ink rotation in degrees.
--   number inktype | Shape of ink.
--   number ratio	| Aspect ratio.
function ss:Paint(pos, normal, radius, color, angle, inktype, ratio)
	local ang, polys = normal:Angle(), {}
	ang.roll = abs(normal.z) > COS_MAX_DEG_DIFF and angle * normal.z or ang.yaw
	for i, v in ipairs(reference_polys) do --Scaling
		polys[i] = To3D(ss, v * radius, pos, ang)
	end
	
	local inkqueue = 0
	local rectsize = radius * rootpi
	local sizevec = Vector(rectsize, rectsize)
	local mins, maxs = GetBoundingBox(ss, polys, MIN_BOUND)
	for node in BSPPairs(ss, polys) do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(normal) <= COS_MAX_DEG_DIFF * (index < 0 and .5 or 1) or
			not CollisionAABB(ss, mins, maxs, surf.Mins[i], surf.Maxs[i]) then continue end
			local _, localang = WorldToLocal(vector_origin, ang, vector_origin, surf.Normals[i]:Angle())
			localang = surf.DefaultAngles[i] + ang.yaw - localang.roll
			Start "SplatoonSWEPs: DrawInk"
			WriteInt(index, ss.SURFACE_INDEX_BITS)
			WriteUInt(color, ss.COLOR_BITS)
			WriteUInt(inktype, 4)
			WriteVector(pos)
			WriteVector(Vector(radius, localang, ratio))
			Send(ss.PlayersReady)
			
			local pos2d = To2D(ss, pos, surf.Origins[i], surf.Angles[i])
			local bmins, bmaxs = pos2d - sizevec, pos2d + sizevec
			local inkdata = 
			AddInkRectangle(surf.InkCircles[i], ss.InkCounter, {
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

local MAX_DEG_GETSURF = 30
local MAX_COS_GETSURF = math.cos(math.rad(MAX_DEG_GETSURF))
local POINT_BOUND = ss.vector_one * .1
function ss:GetSurfaceColor(tr)
	if not tr.Hit then return end
	for node in BSPPairs(ss, {tr.HitPos}) do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(tr.HitNormal) <= COS_MAX_DEG_DIFF * (index < 0 and .5 or 1) or not
			CollisionAABB(ss, tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = To2D(ss, tr.HitPos, surf.Origins[i], surf.Angles[i])
			for r in SortedPairsByValue(surf.InkCircles[i], true) do
				local t = self.InkShotMaterials[r.texid]
				local w, h = t.width, t.height
				local p = (p2d - r.pos) / r.radius
				p:Rotate(Angle(0, r.angle)) --(-1, -1) <= (x, y) <= (1, 1)
				if -1 > p.x or p.x > 1 or -1 > p.y or p.y > 1 then continue end
				p = (p + self.vector_one) / 2 --(0, 0) <= (x, y) <= (1, 1)
				p.y = p.y * h --0 <= y <= h
				p.x = p.x - (1 - r.ratio) / 2 --0 <= x <= r.ratio
				p.x = p.x / r.ratio * w --0 <= x <= w
				p.x, p.y = Round(p.x), Round(p.y)
				if 0 < p.x and p.x < w and 0 < p.y and p.y < h and t[(p.y - 1) * w + p.x] then
					return r.color
				end
			end
		end
	end
end
