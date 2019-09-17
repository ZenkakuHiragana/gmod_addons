
-- This lua manages whole ink in map.

local ss = SplatoonSWEPs
if not ss then return end
local TimerCycle = util.TimerCycle
local abs = math.abs
local Angle = Angle
local BSPPairs = ss.BSPPairs
local CLIENT = CLIENT
local CollisionAABB = ss.CollisionAABB
local cos = math.cos
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
local next = next
local pairs = pairs
local rad = math.rad
local Round = math.Round
local select = select
local SequentialSurfaces = ss.SequentialSurfaces
local SERVER = SERVER
local sin = math.sin
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
local vector_half = vector_one / 2
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
local gridsize = 12
local gridarea = gridsize * gridsize
local griddivision = 1 / gridsize
function ss.AddInkRectangle(color, id, inktype, localang, pos, radius, ratio, surf)
	local pos2d = To2D(pos, surf.Origins[id], surf.Angles[id]) * griddivision
	local x0, y0 = pos2d.x, pos2d.y
	local ink = surf.InkCircles[id]
	local t = ss.InkShotMaterials[inktype]
	local w, h = t.width, t.height
	local surfsize = surf.Bounds[id] * griddivision
	local sw, sh = floor(surfsize.x), floor(surfsize.y)
	local dy = radius * griddivision
	local dx = ratio * dy
	local y_const = dy * 2 / h
	local x_const = ratio * dy * 2 / w
	local ang = rad(-localang)
	local sind, cosd = sin(ang), cos(ang)
	local pointcount = {}
	local area = 0
	for x = 0, w - 1, 0.5 do
		local tx = t[floor(x)]
		if tx then
			for y = 0, h - 1, 0.5 do
				if tx[floor(y)] then
					local p = x * x_const - dx
					local q = y * y_const - dy
					local i = floor(p * cosd - q * sind + x0)
					local k = floor(p * sind + q * cosd + y0)
					if 0 <= i and i <= sw and 0 <= k and k <= sh then
						pointcount[i] = pointcount[i] or {}
						pointcount[i][k] = (pointcount[i][k] or 0) + 1
						if pointcount[i][k] > 3 then
							ink[i] = ink[i] or {}
							if ink[i][k] ~= color then area = area + 1 end
							ink[i][k] = color
						end
					end
				end
			end
		end
	end

	return area
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

	local area = 0
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
				eff:SetScale(SERVER and index or i * (ss.Displacements[i] and -1 or 1))
				eff:SetStart(Vector(radius, localang + (CLIENT and surf.Moved[i] and 90 or 0)))
				util_Effect("SplatoonSWEPsDrawInk", eff, true, ignoreprediction)
				area = area + AddInkRectangle(color, i, inktype, localang, pos, radius, ratio, surf)
			end
		end
	end

	if ply:IsPlayer() and mp and SERVER then SuppressHostEvents() end
	if not ply:IsPlayer() then return end

	ss.WeaponRecord[ply].Inked[classname] = (ss.WeaponRecord[ply].Inked[classname] or 0) - area * gridarea
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
function ss.GetSurfaceColor(tr)
	if not tr.Hit then return end
	local pos = tr.HitPos
	local surf_to_check = nil
	local index_to_check = nil
	local maxcos = -1
	for node in BSPPairs {pos - tr.HitNormal} do
		local surf = SERVER and node.Surfaces or SequentialSurfaces
		for i, index in pairs(SERVER and surf.Indices or node.Surfaces) do
			local angdiff = surf.Normals[i]:Dot(tr.HitNormal)
			local div = Either(SERVER, isnumber(index) and index < 0, ss.Displacements[i]) and 2 or 1
			if maxcos < angdiff and angdiff > MAX_COS_DEG_DIFF / div
			and CollisionAABB(pos - POINT_BOUND, pos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then
				surf_to_check = surf
				index_to_check = i
				maxcos = angdiff
			end
		end
	end

	if not surf_to_check then return end
	local p2d = To2D(pos, surf_to_check.Origins[index_to_check], surf_to_check.Angles[index_to_check])
	local ink = surf_to_check.InkCircles[index_to_check]
	local x, y = floor(p2d.x * griddivision), floor(p2d.y * griddivision)
	local colorid = ink[x] and ink[x][y]
	if ss.Debug then ss.Debug.ShowInkStateMesh(Vector(x, y), index_to_check, surf_to_check) end
	return colorid
end
