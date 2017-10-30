require "SZL"
assert(SZL, "SZL is required.")
if getfenv() ~= SZL then setfenv(1, SZL) end
SZL.Triangulation = true
if not SZL.DataStructures then include "datastructures.lua" end
if not SZL.Graph then include "graph.lua" end
if not SZL.Geometry then include "geometry.lua" end
if not SZL.PolyBool then include "polybool.lua" end

--Triangulation(list of segments with annotations)
--Returns a list of triangles from given segments.
----Perform Fortune's algorithm to make voronoi diagram
----And transform it into Delaunay diagram

--(x^2 - 2px1x + px1^2 + py1^2 - l^2) / (py1 - l)
--= (x^2 - 2px2x + px2^2 + py2^2 - l^2) / (py2 - l)

--A1, A2 = (py1 - l), (py2 - l)

--x^2/A1 - (2px1/A1)x + (px1^2 + py1^2 - l^2) / A1
--= x^2/A2 - (2px2/A2)x + (px2^2 + py2^2 - l^2) / A2

--(1/A1 - 1/A2)x^2 - 2 * (px1/A1 - px2/A2)x + ()/A1 - ()/A2 = 0
--*A1A2
--(A2 - A1)x^2 - 2 * (A2px1 - A1px2)x + A2(px1^2 + py1^2 - l^2) - A1() = 0
--a = A2 - A1
---b = 2 * (A2px1 - A1px2)
--b^2 = 4 * (A2px1 - A1px2)^2
---4ac = -4 * (A2 - A1) * (A2() - A1())

--A2 - A1 = py2 - py1
--((A2px1 - A1px2) +/- sqrt()) / (A2 - A1)
--sqrt() = ((A2px1 - A1px2)^2 
--(py1 - py2) * (A2(px1^2 + py1^2 - l^2) - A1(px2^2 + py2^2 - l^2)))

local epsilon = SZL.epsilon or 50
local function EqualEvent(op1, op2) return op1.pos:DistToSqr(op2.pos) < epsilon end
local function LessThanEvent(op1, op2, orequal) --Comparator function
	if orequal and EqualEvent(op1, op2) then return true end
	if math.abs(op1.radius - op2.radius) < epsilon then
		return op1.angle - op2.angle < -epsilon --angular coord. is second factor
	else --Sort by radial coordinate
		return op1.radius - op2.radius < -epsilon
	end
end

--If a vertex with same angle is found, it will be overridden
local function EqualStatus(op1, op2) return math.abs(op1.angle - op2.angle) < epsilon end
local function LessThanStatus(op1, op2, orequal)
	if EqualStatus(op1, op2) then return orequal end
	return op1.angle - op2.angle < -epsilon --Sort by angular coordinate
end

local EventMeta = {
	__eq = function(op1, op2) return EqualEvent(op1, op2) end,
	__lt = function(op1, op2) return LessThanEvent(op1, op2, false) end,
	__le = function(op1, op2) return LessThanEvent(op1, op2, true) end,
	__tostring = function(op)
		return "S" .. tostring(op.pos)
			.. "(" .. tostring(op.radius)
			.. ", " .. tostring(op.angle)
			.. ")"
	end,
}
function EventMeta.__index(tbl, key) --Get angular coordinate from some values
	local ax, ay = tbl.pos.x - tbl.angularorg.x, tbl.pos.y - tbl.angularorg.y
	local angle = (1 - (ax / (math.abs(ax) + math.abs(ay)))) * (ay > 0 and 1 or ay < 0 and -1 or 1)
	if not eq(tbl.angularorg, tbl.radialorg) then tbl.angle = angle end
	return angle --If it's not temporary angular origin, store the result
end

local function Event(site, radorg, angorg) --site: Vector2D()
	return setmetatable({
		pos = site,
		radialorg = radorg,
		angularorg = angorg,
		radius = site:DistToSqr(radorg)
	}, EventMeta)
end

local StatusMeta = {
	__index = EventMeta.__index,
	__eq = function(op1, op2) return EqualStatus(op1, op2) end,
	__lt = function(op1, op2) return LessThanStatus(op1, op2, false) end,
	__le = function(op1, op2) return LessThanStatus(op1, op2, true) end,
	__tostring = function(op)
		return "{" .. tostring(op.pos) .. "}"--"|" .. tostring(op.min) .. "/" .. tostring(op.max) .. "}"
	end,
}
local function Status(e, angorg) --e: Event()
	return setmetatable({ --The frontier of sweep-circle algorithm
		pos = e.pos,
		radius = e.radius,
		radialorg = e.radialorg,
		angularorg = angorg or e.angularorg,
		triangles = {}
	}, StatusMeta)
end

local function CCW(p1, p2, p3) return Segment(p1, p2).isleft(p3) end
local function IsInTriCircle(tri, p) --Returns if point p is in circle made from triangle tri.
	local p1, p2, p3 = tri[1], tri[2], tri[3]
	local a, b, c = p1:DistToSqr(p2), p2:DistToSqr(p3), p3:DistToSqr(p1)
	local c1, c2, c3 = a * (b + c - a), b * (c + a - b), c * (a + b - c)
	local circleOrigin = (c1 * p3 + c2 * p1 + c3 * p2) / (c1 + c2 + c3)
	local radiusSqr = a * b * c / ((p2 - p1):Cross(p3 - p2).z^2 * 4)
	return circleOrigin:DistToSqr(p) - radiusSqr < -epsilon
end

local function CanMakeTriangle(p1, p2, p3, constrains)
	local h1, h2, h3 = VectorHash(p1), VectorHash(p2), VectorHash(p3)
	local seg1, seg2, seg3 = constrains[h1 .. h2], constrains[h2 .. h3], constrains[h3 .. h1]
	if not (seg1 or seg2 or seg3) then
		local center = (p1 + p2 + p3) / 3 * 0.05
		local org = {p1 * 0.95 + center, p2 * 0.95 + center, p3 * 0.95 + center}
		local i = {0, 0, 0}
		local checked = {}
		for _, s in pairs(constrains) do
			if s.start then
				local sh, eh = VectorHash(s.start()), VectorHash(s.endpos())
				if not checked[sh .. eh] and s.start then
					checked[sh ..eh], checked[eh ..sh] = true, true
					for n, o in ipairs(org) do
						if (o.x - s.start().x) * (o.x - s.endpos().x) < 0 then
							if s.start().y + (s.endpos().y - s.start().y) * (o.x - s.start().x) / (s.endpos().x - s.start().x) > o.y then
								i[n] = i[n] + 1
							end
						end
					end
				end
			end
		end
		if i[1] % 2 == 0 or i[2] == 0 or i[3] == 0 then return false end
	elseif not
		((seg1 and (seg1.left and seg1.isleft(p3)
				 or seg1.right and seg1.isright(p3)))
		or (seg2 and (seg2.left and seg2.isleft(p1)
				   or seg2.right and seg2.isright(p1)))
		or (seg3 and (seg3.left and seg3.isleft(p2)
				   or seg3.right and seg3.isright(p2)))) then
		return false
	end
	
	return true
end

local function fliptris(tri, constrains)
	local i = 0
	local stack, checked = {tri}, {}
	while #stack > 0 do
		local pop = table.remove(stack, 1)
		local h1, h2, h3 = VectorHash(pop[1]), VectorHash(pop[2]), VectorHash(pop[3])
		local p1, p2, p3 = pop[h1], pop[h2], pop[h3]
		local flip, brkflag = {}, false
		for _, p in ipairs {p1.triangles, p2.triangles, p3.triangles} do
			for found in pairs(p) do --It's not enough to store line segments
				if flip[found] and found ~= pop then --So search adjacent triangles from vertices
					local v = {} --four vertices. 1: found | 2, 3: shared | 4: pop
					local filter = {p1, p2, p3, [h1] = 1, [h2] = 2, [h3] = 3}
					for _, vert in ipairs(found) do --Finding shared vertices and others
						local vh = VectorHash(vert)
						if vh ~= h1 and vh ~= h2 and vh ~= h3 then
							v[1] = found[vh]
						else
							filter[filter[vh]], filter[vh] = nil
							v[v[3] and 2 or 3] = found[vh]
						end
					end
					
					if v[1] and v[2] and v[3] and
						not constrains[VectorHash(v[2].pos) .. VectorHash(v[3].pos)]
						and IsInTriCircle(pop, v[1].pos) then --Start flipping
						brkflag = true
						checked[pop], checked[found] = (checked[pop] or 0) + 1, (checked[found] or 0) + 1
						if checked[pop] < 4 then stack[#stack + 1] = pop end
						if checked[found] < 4 then stack[#stack + 1] = found end
						v[4] = filter[table.maxn(filter)]
						for i = 1, 4 do v[v[i]] = VectorHash(v[i].pos) end
						
						pop[1], pop[2], pop[3], --Two triangles are already in returning table
						pop[v[v[1]]], pop[v[v[2]]], pop[v[v[3]]], pop[v[v[4]]], --Just 'change' their data
						v[1].triangles[pop], v[2].triangles[pop], v[3].triangles[pop], v[4].triangles[pop]
							= v[1].pos, v[2].pos, v[4].pos,
							  v[1], v[2], nil, v[4],
							  true, true, nil, true
						found[1], found[2], found[3],
						found[v[v[1]]], found[v[v[2]]], found[v[v[3]]], found[v[v[4]]],
						v[1].triangles[found], v[2].triangles[found], v[3].triangles[found], v[4].triangles[found]
							= v[1].pos, v[4].pos, v[3].pos,
							  v[1], nil, v[3], v[4],
							  true, nil, true, true
						if not CCW(pop[1], pop[2], pop[3]) then --Sort them in counter-clockwise
							pop[2], pop[3] = pop[3], pop[2]
							found[2], found[3] = found[3], found[2]
						end
						pop.deprecated = not CanMakeTriangle(pop[1], pop[2], pop[3], constrains)
						found.deprecated = not CanMakeTriangle(found[1], found[2], found[3], constrains)
						break
					end
				end--If a triangle is found twice, then two vertices are part of it
				flip[found] = true 
			end
			if brkflag then break end
			i = assert(i < 10000 and i, "Infinite loop!") + 1
		end --for triangles
	end --while #stack
end

local function sweepline(segments) --Returns a list of triangles, {p1, p2, p3}, ccw
	if #segments < 3 then return {} end
	local event, status = BinaryHeap(), AVLTree()
	local radialorg, angularorg
	local sum, triangles, vertices, constrains = Vector2D(), {}, {}, {}
	local function getnextpos(current) return status.getnext(current) or status.getmin().get() end
	local function getprevpos(current) return status.getprev(current) or status.getmax().get() end
	local function MakeTriangle(s1, s2, s3) --Adds a new triangle and flips some existing triangles
		local p1, p2, p3 = s1.pos, s2.pos, s3.pos
		if not CCW(p1, p2, p3) then s2, s3, p2, p3 = s3, s2, p3, p2 end
		local tri = {
			p1, p2, p3, [VectorHash(p1)] = s1, [VectorHash(p2)] = s2, [VectorHash(p3)] = s3,
			deprecated = not CanMakeTriangle(p1, p2, p3, constrains)
		}
		s1.triangles[tri] = true
		s2.triangles[tri] = true
		s3.triangles[tri] = true
		triangles[#triangles + 1] = tri
		triangles[tri] = #triangles
		fliptris(tri, constrains)
		return true
	end
	local function walkfrontier(tmpprev, current, tmpnext, goback)
		while CCW(tmpprev.pos, current.pos, tmpnext.pos) do --Walks along frontier line
			MakeTriangle(tmpprev, current, tmpnext) --And makes some triangles
			status.remove(goback and tmpnext or tmpprev)
			tmpnext, tmpprev
				= goback and tmpprev or getnextpos(tmpnext),
				  goback and getprevpos(tmpprev) or tmpnext
		end
	end
	
	for _, s in ipairs(segments) do --Get the center of vertices
		local begin, endpos = s.start(), s.endpos()
		local bh, eh = VectorHash(begin), VectorHash(endpos)
		if not constrains[bh] then
			sum = sum + begin
			constrains[bh] = {}
		end
		if not constrains[eh] then
			sum = sum + endpos
			constrains[eh] = {}
		end
		constrains[bh .. eh], constrains[eh .. bh] = s, s
		constrains[bh][s], constrains[eh][s] = true, true
		vertices[bh], vertices[eh] = begin, endpos
	end
	
	radialorg = sum / #segments --Radial center position
	angularorg = radialorg --Angular center position(temporary, used for adding events)
	for _, v in pairs(vertices) do event.add(Event(v, radialorg, angularorg)) end --Set up events
	local s1 = Status(event.remove())
	local s2 = Status(event.remove())
	local s3 = Status(event.remove())
	local collinear = {}
	while Segment(s1.pos, s2.pos).online(s3.pos) and not event.isempty() do
		collinear[#collinear + 1] = s3
		s3 = Status(event.remove())
	end
	if event.isempty() then return {} end
	angularorg = (s1.pos + s2.pos + s3.pos) / 3 --Angular center position
	s1.angularorg, s2.angularorg, s3.angularorg = angularorg, angularorg, angularorg
	for _, e in ipairs(collinear) do event.add(Event(e.pos, radialorg, angularorg)) end
	status.add(s1)
	status.add(s2)
	status.add(s3)
	MakeTriangle(s1, s2, s3) --Make an initial triangle that surrounds angular origin
	
	while not event.isempty() do --Process every event
		local current = Status(event.remove(), angularorg)
		local hitvertex = status.get(current) --Is projection of event on existing vertex? 
		local nextpos, prevpos = status.getadjacent(current)
		if not nextpos then nextpos = status.getmin().get() end --Frontier loops
		if not prevpos then prevpos = status.getmax().get() end --But AVLTree don't
		status.add(current)
		walkfrontier(nextpos, current, getnextpos(nextpos), false)
		walkfrontier(getprevpos(prevpos), current, prevpos, true)
		if hitvertex then MakeTriangle(hitvertex.get(), current, nextpos) end
		MakeTriangle(prevpos, current, hitvertex and hitvertex.get() or nextpos)
	end
	
	local result = {}
	for k, v in pairs(triangles) do --Removing temporary data
		if isnumber(k) and not v.deprecated then
			local t = {}
			for i, n in pairs(v) do
				if isnumber(i) then
					t[#t + 1] = n
				end
			end
			result[#result + 1] = t
		end
	end
	
	return result
end

local function p(...) return Polygon("Active", Region(...)) end
local function q(...) return Polygon("Lazy", Region(...)) end
local function v(v1, v2) return Vector2D(v1, v2) end
local function vr() return v(math.random() * 40 - 20, math.random() * 60 - 30) end
local function s(v1, v2, v3, v4) return Segment(v(v1, v2), v(v3, v4)) end

--p1 = p(v(0, 0), v(15, -10), v(22, 0), v(10, 10))
--p1 = p(v(0, 0), v(15, -10), v(22, -2), v(10, 10))
--p1 = p(v(0, 0), v(15, -10), v(22, 2), v(10, 10))
--p1 = p(v(0, 0), v(15, -10), v(20, 0), v(10, 10))
--p1 = p(v(0, 0), v(15, -10), v(20, -2), v(10, 10))
--p1 = p(v(0, 0), v(15, -10), v(20, 2), v(10, 10))
--p1 = p(v(0, 0), v(15, -10), v(20, 4), v(10, 10))
--p1 = p(v(0, 0), v(15, -10), v(20, 5), v(10, 10))

--p1 = p(v(0, 0), v(15, -15), v(5, -25), v(-15, -10))
--p1 = p(v(0, 0), v(20, -5), v(10, 10), v(15, 12), v(10, 14), v(10, 16), v(8, 18)) --*
--p1 = p(v(0, 0), v(10, -10), v(5, 0), v(5, 5), v(10, 20)) --*

--p1 = p(v(0, -1), v(11, -10), v(20, 1), v(9, 10)) --◇R
--p1 = p(v(0, 1), v(9, -10), v(20, -1), v(11, 10)) --◇L
--p1 = p(v(0, 0), v(10, -10), v(20, 0), v(10, 10)) --◇
--p1 = p(v(1, 0), v(0, -9), v(9, -10), v(10, -1)) --口R
--p1 = p(v(-1, 0), v(0, -11), v(11, -10), v(10, 1)) --口L
--p1 = p(v(0, 0), v(0, -10), v(10, -10), v(10, 0)) --口
--p1 = Polygon(nil, {v(0, 0), v(0, -10), v(10, 0)}, {v(0, -20), v(10, -20), v(0, -10)}) --...
--p1 = p(v(0, 0), v(6, -10), v(17, -15), v(28, -10), v(34, 0), v(28, 10), v(17, 15), v(6, 10))
--p1 = p(v(0, 0), v(5, -10), v(15, -15), v(25, -10), v(30, 0), v(25, 10), v(15, 15), v(5, 10))--)
--p1 = p(v(10, 0), v(0, -15), v(-20, 0), v(0, 25))
--p1 = p(v(0, 0), v(10, -10), v(10, 10), v(4, 6)) --◇
--p1 = p(v(14, -2), v(17, 0), v(19, 4), v(20, 8), v(24, 4), v(20, -20), v(-20, -20), v(-18, 6), v(8, 8), v(9, 4), v(11, 0), v(0, -5), v(-5, -3), v(5, -4))

math.randomseed(os.clock())
local n = 16
local rx, ry = 15, 15
local d = 0
--local d = 90
--local d = 180
local e = 180 / n
--local e = 90 / n
local vec = {}
for i = 1, n do
	local x, y = rx * math.cos(math.rad(360 / n * i)), ry * math.sin(math.rad(360 / n * i))
	x, y = x * math.cos(math.rad(d)) + y * math.sin(math.rad(d)), -x * math.sin(math.rad(d)) + y * math.cos(math.rad(d))
	if math.abs(x) < epsilon then x = 0 end
	if math.abs(y) < epsilon then y = 0 end
	vec[#vec + 1] = v(x, y) * (math.random() + 0.4)
--	vec[#vec + 1] = v(x, y) * (i % 2 == 0 and 1 or 0.4)
--	vec[#vec + 1] = v(x, y) * (math.sin(math.pi * 0.094 * i) / 5 + 0.8)
--	vec[#vec + 1] = vr()
end
--rx, ry = rx * 0.7, ry * 0.7
--rx, ry = rx * 0.5, ry * 0.5
--rx, ry = rx * 0.4, ry * 0.4
local vec2 = {}
for i = n, 1, -1 do
	local x, y = rx * math.cos(math.rad(360 / n * i + e)), ry * math.sin(math.rad(360 / n * i + e))
	x, y = x * math.cos(math.rad(d)) + y * math.sin(math.rad(d)), -x * math.sin(math.rad(d)) + y * math.cos(math.rad(d))
	if math.abs(x) < epsilon then x = 0 end
	if math.abs(y) < epsilon then y = 0 end
	vec2[#vec2 + 1] = v(x, y) * (math.random() + 0.5)
--	vec[#vec + 1] = vr()
end
p1 = p(unpack(vec))
--p1 = Polygon("Test", vec, vec2)
--p1 = p(v(0, 0), v(2.5, 0), v(5, -5), v(6.5, 0), v(10, 0), v(10, 10), v(0, 10))
--p1 = p(v(0, 0), v(10, 0), v(10, 10), v(6.7, 10), v(6.7, 2), v(3.3, 2), v(3.3, 10), v(0, 10))

--p1 = p(v(0, 0), v(10, 0), v(10, 10), v(0, 10))
--p2 = q(v(5, -5), v(2.5, 5), v(7.5, 5))
--p2 = q()
p2 = q(unpack(vec2))
function Triangulate(segments)
--	print "Triangulation"
	return sweepline(segments)
end

if love then return end
--PrintTable(p1 + Polygon())

--local p1, p2 = v(0, 0), v(5, -10)
--local e1, e2 = Event(p1), Event(p2)
--local s1, s2 = Status({left = e1, right = e2}), Status({left = e2, right = e1})
--sweeplinex = 5
--sweepxsqr = sweeplinex^2
--print(s1, s2, s1 < s2)

--local a = AVLTree()
--for _, n in ipairs {1, 2, 3, 3, 3, 5, 8} do
--	a.add(n)
--end
--print(a.getadjacent(3))
