
-- This lua manages whole ink in map.

local ss = SplatoonSWEPs
if not ss then return end
local TimerCycle = util.TimerCycle
local abs = math.abs
local Angle = Angle
local BSPPairs = ss.BSPPairs
local CLIENT = CLIENT
local CollisionAABB = ss.CollisionAABB
local Either = Either
local floor = math.floor
local GetBoundingBox = ss.GetBoundingBox
local ipairs = ipairs
local isnumber = isnumber
local KeyFromValue = table.KeyFromValue
local max = math.max
local min = math.min
local mp = ss.mp
local net_Send = net.Send
local net_Start = net.Start
local net_WriteDouble = net.WriteDouble
local net_WriteUInt = net.WriteUInt
local NormalizeAngle = math.NormalizeAngle
local pairs = pairs
local Round = math.Round
local select = select
local SequentialSurfaces = ss.SequentialSurfaces
local SERVER = SERVER
local sort = table.sort
local sp = ss.sp
local SuppressHostEvents = SuppressHostEvents
local tableremove = ss.tableremove
local To2D = ss.To2D
local To3D = ss.To3D
local unpack = unpack
local util_Effect = util.Effect
local Vector = Vector
local vector_one = ss.vector_one
local vector_origin = vector_origin
local WorldToLocal = WorldToLocal
local function CheckBounds(v) return next(v.bounds) end
local eff = EffectData()
local MAX_COS_DEG_DIFF = ss.MAX_COS_DEG_DIFF
local MIN_BOUND = 20 -- Ink minimum bounding box scale
local POINT_BOUND = ss.vector_one * .1
local reference_polys = {}
local reference_vert = Vector(1)
local boundsizescale = math.sqrt(math.pi) * .375
local circle_polys = 360 / 12
for i = 1, circle_polys do
	reference_polys[#reference_polys + 1] = Vector(reference_vert)
	reference_vert:Rotate(Angle(0, circle_polys))
end

-- Internal function to record a new ink to ink history.
function ss.AddInkRectangle(color, id, inktype, localang, pos, radius, ratio, surf)
	local radius_ratio = radius * ratio
	local boundsize = radius_ratio * boundsizescale
	local axis = Vector(0, 1) axis:Rotate(Angle(0, -localang))
	local radius_axis = radius * axis
	local pos2d = To2D(pos, surf.Origins[id], surf.Angles[id])
	local t, bounds = radius_ratio, {} -- 0 <= t <= 2 * radius, step radius * ratio
	while t <= radius * 2 - radius_ratio do
		local p = pos2d - axis * (radius - t)
		bounds[{p.x - boundsize, p.y - boundsize, p.x + boundsize, p.y + boundsize}] = true
		t = t + radius_ratio
	end

	if ratio < .75 then
		t = pos2d + axis * (radius - radius_ratio)
		bounds[{t.x - boundsize, t.y - boundsize, t.x + boundsize, t.y + boundsize}] = true
	end

	local ink = surf.InkCircles[id]
	local newink = {
		angle = localang,
		bounds = bounds,
		color = color,
		pos = pos2d,
		radius = radius,
		ratio = ratio,
		texid = inktype,
	}

	for nb in pairs(bounds) do
		local n1, n2, n3, n4 = unpack(nb) -- xmin, ymin, xmax, ymax
		for i = 1, #ink do
			local r = ink[i]
			local rb = r.bounds
			for b in pairs(rb) do
				local b1, b2, b3, b4 = unpack(b)
				local w, h = b3 - b1, b4 - b2
				if min(w, h) < 10 or w * h < 100 then
					rb[b] = nil
				elseif not (n1 > b3 or n3 < b1 or n2 > b4 or n4 < b2) then
					local x1, x2 = n1, n3 if x1 > x2 then x1, x2 = x2, x1 end
					local x3, x4 = b1, b3 if x3 > x4 then x3, x4 = x4, x3 end
					local y1, y2 = n2, n4 if y1 > y2 then y1, y2 = y2, y1 end
					local y3, y4 = b2, b4 if y3 > y4 then y3, y4 = y4, y3 end
					if x1 > x3 then x1, x3 = x3, x1 end
					if x2 > x4 then x2, x4 = x4, x2 end
					if x2 > x3 then x2, x3 = x3, x2 end
					if y1 > y3 then y1, y3 = y3, y1 end
					if y2 > y4 then y2, y4 = y4, y2 end
					if y2 > y3 then y2, y3 = y3, y2 end
					rb[b] = nil
					rb[{x1, y1, x2, y2}] = b1 < x2 and b3 > x1 and b2 < y2 and b4 > y1 and (n1 >= x2 or n3 <= x1 or n2 >= y2 or n4 <= y1) or nil
					rb[{x2, y1, x3, y2}] = b1 < x3 and b3 > x2 and b2 < y2 and b4 > y1 and (n1 >= x3 or n3 <= x2 or n2 >= y2 or n4 <= y1) or nil
					rb[{x3, y1, x4, y2}] = b1 < x4 and b3 > x3 and b2 < y2 and b4 > y1 and (n1 >= x4 or n3 <= x3 or n2 >= y2 or n4 <= y1) or nil
					rb[{x1, y2, x2, y3}] = b1 < x2 and b3 > x1 and b2 < y3 and b4 > y2 and (n1 >= x2 or n3 <= x1 or n2 >= y3 or n4 <= y2) or nil
					rb[{x2, y2, x3, y3}] = b1 < x3 and b3 > x2 and b2 < y3 and b4 > y2 and (n1 >= x3 or n3 <= x2 or n2 >= y3 or n4 <= y2) or nil
					rb[{x3, y2, x4, y3}] = b1 < x4 and b3 > x3 and b2 < y3 and b4 > y2 and (n1 >= x4 or n3 <= x3 or n2 >= y3 or n4 <= y2) or nil
					rb[{x1, y3, x2, y4}] = b1 < x2 and b3 > x1 and b2 < y4 and b4 > y3 and (n1 >= x2 or n3 <= x1 or n2 >= y4 or n4 <= y3) or nil
					rb[{x2, y3, x3, y4}] = b1 < x3 and b3 > x2 and b2 < y4 and b4 > y3 and (n1 >= x3 or n3 <= x2 or n2 >= y4 or n4 <= y3) or nil
					rb[{x3, y3, x4, y4}] = b1 < x4 and b3 > x3 and b2 < y4 and b4 > y3 and (n1 >= x4 or n3 <= x3 or n2 >= y4 or n4 <= y3) or nil
				end
			end
		end
	end

	tableremove(ink, CheckBounds)
	ink[#ink + 1] = newink
end

-- Draws ink.
-- Arguments:
--   Vector pos		| Center position.
--   Vector normal	| Normal of the surface to draw.
--   number radius	| Scale of ink in Hammer units.
--   number angle	| Ink rotation in degrees.
--   number inktype | Shape of ink.
--   number ratio	| Aspect ratio.
local AddInkRectangle = ss.AddInkRectangle
function ss.Paint(pos, normal, radius, color, angle, inktype, ratio, ply, classname)
	inktype = floor(inktype)
	angle = NormalizeAngle(angle)
	eff:SetAttachment(color)
	eff:SetEntity(ply)
	eff:SetFlags(inktype)
	eff:SetMagnitude(ratio)
	eff:SetOrigin(pos)

	local ang, polys = normal:Angle(), {}
	local ignoreprediction = not ply:IsPlayer() and SERVER and mp or nil
	ang.roll = abs(normal.z) > MAX_COS_DEG_DIFF and angle * normal.z or ang.yaw
	for i, v in ipairs(reference_polys) do -- Scaling
		polys[i] = To3D(v * radius, pos, ang)
	end

	local mins, maxs = GetBoundingBox(polys, MIN_BOUND)
	if ply:IsPlayer() and mp and SERVER then SuppressHostEvents(ply) end

	for node in BSPPairs(polys) do
		local surf = SERVER and node.Surfaces or SequentialSurfaces
		for i, index in pairs(SERVER and surf.Indices or node.Surfaces) do
			local angdiff = surf.Normals[i]:Dot(normal)
			local div = Either(SERVER, SERVER and index < 0, ss.Displacements[i]) and 2 or 1
			if angdiff > MAX_COS_DEG_DIFF / div and CollisionAABB(mins, maxs, surf.Mins[i], surf.Maxs[i]) then
				local localang = select(2, WorldToLocal(vector_origin, ang, vector_origin, surf.Normals[i]:Angle()))
				localang = ang.yaw - localang.roll + surf.DefaultAngles[i]
				if CLIENT and surf.Moved[i] then localang = localang + 90 end

				eff:SetScale(SERVER and index or i * (ss.Displacements[i] and -1 or 1))
				eff:SetStart(Vector(radius, localang))
				util_Effect("SplatoonSWEPsDrawInk", eff, true, ignoreprediction)
				AddInkRectangle(color, i, inktype, localang, pos, radius, ratio, surf)
			end
		end
	end

	if ply:IsPlayer() and mp and SERVER then SuppressHostEvents() end
	if not ply:IsPlayer() then return end

	ss.WeaponRecord[ply].Inked[classname] = (ss.WeaponRecord[ply].Inked[classname] or 0) - radius^2 * math.pi * ratio
	if sp and SERVER then
		net_Start "SplatoonSWEPs: Send turf inked"
		net_WriteDouble(ss.WeaponRecord[ply].Inked[classname])
		net_WriteUInt(KeyFromValue(ss.WeaponClassNames, classname), 8)
		net_Send(ply)
	end
end

-- Takes a TraceResult and returns ink color of its HitPos.
-- Argument:
--   TraceResult tr	| A TraceResult structure to pick up a position.
-- Returning:
--   number			| The ink color of the specified position.
--   nil			| If there is no ink, returns nil.
local vector_half = vector_one / 2
function ss.GetSurfaceColor(tr)
	if not tr.Hit then return end
	local pos = tr.HitPos
	for node in BSPPairs {pos} do
		local surf = SERVER and node.Surfaces or SequentialSurfaces
		for i, index in pairs(SERVER and surf.Indices or node.Surfaces) do
			local angdiff = surf.Normals[i]:Dot(tr.HitNormal)
			local div = Either(SERVER, isnumber(index) and index < 0, ss.Displacements[i]) and 2 or 1
			if angdiff > MAX_COS_DEG_DIFF / div and CollisionAABB(pos - POINT_BOUND, pos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then
				local p2d = To2D(pos, surf.Origins[i], surf.Angles[i])
				local ink = surf.InkCircles[i]
				for k = #ink, 1, -1 do
					local r = ink[k]
					if r then
						local t = ss.InkShotMaterials[r.texid]
						local w, h = t.width, t.height
						local p = (p2d - r.pos) / r.radius
						p:Rotate(Angle(0, r.angle)) -- (-1, -1) <= (x, y) <= (1, 1)
						if ss.Debug then ss.Debug.ShowInkChecked(r, surf, i) end
						if -1 < p.x and p.x < 1 and -1 < p.y and p.y < 1 then
							p = p / 2 + vector_half -- (0, 0) <= (x, y) <= (1, 1)
							p.y = p.y * h -- 0 <= y <= h
							p.x = p.x + r.ratio / 2 - .5 -- 0 <= x <= r.ratio
							p.x = p.x / r.ratio * w -- 0 <= x <= w
							p.x, p.y = Round(p.x), Round(p.y)
							if 0 < p.x and p.x < w and 0 < p.y and p.y < h and t[p.x] and t[p.x][p.y] then
								return r.color
							end
						end
					end
				end
			end
		end
	end
end
