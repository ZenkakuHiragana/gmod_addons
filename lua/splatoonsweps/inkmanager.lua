
-- This lua manages whole ink in map.

local ss = SplatoonSWEPs
if not ss then return end
local MIN_BOUND = 20 -- Ink minimum bounding box scale
local POINT_BOUND = ss.vector_one * .1
local reference_polys = {}
local reference_vert = Vector(1)
local rootpi = math.sqrt(math.pi) / 2
local circle_polys = 360 / 12
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
function ss.Paint(pos, normal, radius, color, angle, inktype, ratio, ply, classname)
	inktype = math.floor(inktype)
	angle = math.NormalizeAngle(angle)

	local ang, polys = normal:Angle(), {}
	ang.roll = math.abs(normal.z) > ss.MAX_COS_DEG_DIFF and angle * normal.z or ang.yaw
	for i, v in ipairs(reference_polys) do -- Scaling
		polys[i] = ss.To3D(v * radius, pos, ang)
	end

	if ply:IsPlayer() and ss.mp and SERVER then SuppressHostEvents(ply) end

	local mins, maxs = ss.GetBoundingBox(polys, MIN_BOUND)
	for node in ss.BSPPairs(polys) do
		local surf = SERVER and node.Surfaces or ss.SequentialSurfaces
		for i, index in pairs(SERVER and surf.Indices or node.Surfaces) do
			if surf.Normals[i]:Dot(normal) <= ss.MAX_COS_DEG_DIFF * ((SERVER and index < 0 or CLIENT and ss.Displacements[i]) and .5 or 1) or
			not ss.CollisionAABB(mins, maxs, surf.Mins[i], surf.Maxs[i]) then continue end
			local _, localang = WorldToLocal(vector_origin, ang, vector_origin, surf.Normals[i]:Angle())
			localang = ang.yaw - localang.roll + surf.DefaultAngles[i]

			local e = EffectData()
			e:SetAttachment(color)
			e:SetEntity(ply)
			e:SetFlags(inktype)
			e:SetOrigin(pos)
			e:SetScale(SERVER and index or i * (ss.Displacements[i] and -1 or 1))
			e:SetStart(Vector(radius, localang, ratio))
			util.Effect("SplatoonSWEPsDrawInk", e, true, not ply:IsPlayer() and SERVER and ss.mp or nil)

			ss.AddInkRectangle(color, i, inktype, localang, pos, radius, ratio, surf)
		end
	end

	if ply:IsPlayer() and ss.mp and SERVER then SuppressHostEvents() end
	if not ply:IsPlayer() then return end

	ss.WeaponRecord[ply].Inked[classname]
	= (ss.WeaponRecord[ply].Inked[classname] or 0)
	- radius^2 * math.pi * ratio

	if ss.sp and SERVER then
		net.Start "SplatoonSWEPs: Send turf inked"
		net.WriteDouble(ss.WeaponRecord[ply].Inked[classname])
		net.WriteUInt(table.KeyFromValue(ss.WeaponClassNames, classname), 8)
		net.Send(ply)
	end
end

-- Internal function to record a new ink to ink history.
local MIN_BOUND_AREA = 1 -- minimum ink bounding box area
function ss.AddInkRectangle(color, id, inktype, localang, pos, radius, ratio, surf)
	ratio = math.Clamp(ratio, 0, 1)
	local boundsize = radius * rootpi * ratio / 2
	local axis = Vector(0, 1)
	axis:Rotate(Angle(0, -localang, 0))
	local pos2d = ss.To2D(pos, surf.Origins[id], surf.Angles[id])
	local t, bounds = radius * ratio, {} -- 0 <= t <= 2 * radius, step radius * ratio
	while t <= radius * (2 - ratio) do
		local p = pos2d - axis * (radius - t)
		bounds[{p.x - boundsize, p.y - boundsize, p.x + boundsize, p.y + boundsize}] = true
		t = t + radius * ratio
	end

	if ratio < .75 then
		t = pos2d + axis * radius * (1 - ratio)
		bounds[{t.x - boundsize, t.y - boundsize, t.x + boundsize, t.y + boundsize}] = true
	end

	local newink = {
		angle = localang,
		bounds = bounds,
		color = color,
		pos = pos2d,
		radius = radius,
		ratio = ratio,
		texid = inktype,
	}

	local ink = surf.InkCircles[id]
	for i, r in ipairs(ink) do
		if not next(r.bounds) then
			table.remove(ink, i)
		else
			for nb in pairs(newink.bounds) do
				for b in pairs(r.bounds) do
					local n1, n2, n3, n4 = unpack(nb) -- xmin, ymin, xmax, ymax
					local b1, b2, b3, b4 = unpack(b)
					if (b3 - b1) * (b4 - b2) < MIN_BOUND_AREA then r.bounds[b] = nil continue end
					if n1 > b3 or n3 < b1 or n2 > b4 or n4 < b2 then continue end
					r.bounds[b] = nil
					local x = {n1, n3, b1, b3} table.sort(x)
					local y = {n2, n4, b2, b4} table.sort(y)
					local x1, x2, x3, x4 = unpack(x)
					local y1, y2, y3, y4 = unpack(y)
					local t = {
						{x1, y1, x2, y2}, {x2, y1, x3, y2}, {x3, y1, x4, y2},
						{x1, y2, x2, y3}, {x2, y2, x3, y3}, {x3, y2, x4, y3},
						{x1, y3, x2, y4}, {x2, y3, x3, y4}, {x3, y3, x4, y4},
					}
					for i = 1, 9 do
						local c = t[i]
						local c1, c2, c3, c4 = unpack(c)
						r.bounds[c] = b1 < c3 and b3 > c1 and b2 < c4 and b4 > c2 and
							(n1 >= c3 or n3 <= c1 or n2 >= c4 or n4 <= c2) or nil
					end
				end
			end
		end
	end

	ink[#ink + 1] = newink
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
		local surf = SERVER and node.Surfaces or ss.SequentialSurfaces
		for i, index in pairs(SERVER and surf.Indices or node.Surfaces) do
			if surf.Normals[i]:Dot(tr.HitNormal) <= ss.MAX_COS_DEG_DIFF * ((SERVER and index < 0 or CLIENT and ss.Displacements[i]) and .5 or 1) or not
			ss.CollisionAABB(tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = ss.To2D(tr.HitPos, surf.Origins[i], surf.Angles[i])
			local ink = surf.InkCircles[i]
			for k = #ink, 1, -1 do
				local r = ink[k]
				if not r then continue end
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
				if 0 < p.x and p.x < w and 0 < p.y and p.y < h and t[p.x] and t[p.x][p.y] then
					return r.color
				end
			end
		end
	end
end
