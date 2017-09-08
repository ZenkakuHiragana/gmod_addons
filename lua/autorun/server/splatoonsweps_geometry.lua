
if not SplatoonSWEPs then return end

local testbool = true
local pointA = {
	Vector(0, -44.494087, -2.535645),
	Vector(0, 62.956238, -2.535645),
	Vector(0, 59.805328, 5.071350),
	Vector(0, -122.761566, -2.535645),
}
local pointB = {
	Vector(0, -34.577694, -2.535645),
	Vector(0, -42.637573, 0.802857),
	Vector(0, -84.149612, -0.926819),
	Vector(0, -88.033676, -2.535645),
}
local oA, oB = {1, 2, 3}, {1, 2, 3}
pointA[1], pointA[2], pointA[3] = pointA[oA[1]], pointA[oA[2]], pointA[oA[3]]
pointB[1], pointB[2], pointB[3] = pointB[oB[1]], pointB[oB[2]], pointB[oB[3]]

-- pointA = {}
-- pointB = {}
-- local circle_polys = 9
-- local reference_vert = Vector(0, -60, 0)
-- for i = 1, circle_polys + 1 do
	-- table.insert(pointA, Vector(reference_vert))-- * ((i % 2 == 0) and 1.2 or 0.8))
	-- table.insert(pointB, Vector(reference_vert))-- * ((i % 2 == 1) and 1.2 or 0.8))
	-- reference_vert:Rotate(Angle(0, 360 / circle_polys / 2, 0))
-- end
-- for i, v in ipairs(pointA) do
	-- pointA[i] = Vector(0, v.x - 5, v.y)
-- end
-- for i, v in ipairs(pointB) do
	-- pointB[i] = Vector(0, v.x - 5, v.y - 40)
-- end

function SplatoonSWEPs.IsCCW(p1, p2, p3)
	return (p2 - p1):Cross(p3 - p2).x > 0
end
local IsCCW = SplatoonSWEPs.IsCCW

function SplatoonSWEPs.IsInTriangle(p1, p2, p3, p)
	return IsCCW(p1, p2, p) and IsCCW(p2, p3, p) and IsCCW(p3, p1, p)
end
local IsInTriangle = SplatoonSWEPs.IsInTriangle

local function IsAnyPointInTriangle(vertices, p1, p2, p3)
	for v in pairs(vertices) do
		if v ~= p1 and v ~= p2 and v ~= p3 and IsInTriangle(p1, p2, p3, v) then
			return true
		end
	end
	return false
end

local function IsEar(p1, p2, p3, vertices)
	return IsCCW(p1, p2, p3) and not IsAnyPointInTriangle(vertices, p1, p2, p3)
end

function SplatoonSWEPs.GetPlaneProjection(pos, planeorigin, planenormal, direction)
	return pos + direction * planenormal:Dot(planeorigin - pos) / planenormal:Dot(direction)
end

--Returns the shared point, shared line and the angle between two planes.
function SplatoonSWEPs.GetSharedLine(n1, n2, p1, p2)
	local normal_dot = n1:Dot(n2)
	if normal_dot > math.cos(math.rad(10)) then return end
	local d1, d2 = p1:Dot(n1), p2:Dot(n2)
	return n1:Cross(n2):GetNormalized(), ((d1 - d2 * normal_dot) * n1 + (d2 - d1 * normal_dot) * n2) / (1 - normal_dot^2), math.acos(normal_dot)
end

--Rotates the given vector around specified normalized axis.
function SplatoonSWEPs.RotateAroundAxis(source, axis, rotation)
	local rotation = rotation / 2
	local sin, cos = math.sin(rotation), math.cos(rotation)
	local sinaxis = sin * axis
	local cossource_sourcesinaxis = cos * source + source:Cross(sinaxis)
	return source:Dot(sinaxis) * sinaxis + cos * cossource_sourcesinaxis + cossource_sourcesinaxis:Cross(sinaxis)
end

--Polygon triangulation algorithm from HC Library.
--It seems this function is based on ear-clipping algorithm.
local function TriangulatePolygon(source)
	if #source < 3 then return {} end
	if #source == 3 then return {source} end
	
	local n, next_index, prev_index, concave = #source, {}, {}, {}
	for i = 1, n do
		next_index[i], prev_index[i] = i + 1, i - 1
	end
	next_index[#next_index], prev_index[1] = 1, #prev_index

	for i, v in ipairs(source) do
		if not IsCCW(source[prev_index[i]], v, source[next_index[i]]) then
			concave[v] = true
		end
	end

	local triangles = {}
	local n_vert, current, skipped, inext, iprev = n, 1, 0
	while n_vert > 3 do
		inext, iprev = next_index[current], prev_index[current]
		local p, q, r = source[iprev], source[current], source[inext]
		if IsEar(p, q, r, concave) then
			triangles[#triangles + 1] = {p, q, r}
			next_index[iprev], prev_index[inext] = inext, iprev
			concave[q] = nil
			n_vert, skipped = n_vert - 1, 0
		else
			skipped = skipped + 1
			if skipped > n_vert then return end
			assert(skipped <= n_vert, "Cannot triangulate polygon")
		end
		current = inext
	end

	inext, iprev = next_index[current], prev_index[current]
	local p, q, r = source[iprev], source[current], source[inext]
	triangles[#triangles + 1] = {p, q, r}
	
	return triangles
end

--Boolean operation between polyA and polyB.
--If getDifference is true, the result will be polyA - polyB.
--Otherwise, the result will be polyA AND polyB.
local epsilon = 1e-6
function SplatoonSWEPs.BuildOverlap(polyA, polyB, getDifference)
	-- local polyA, polyB, getDifference = pointA, pointB, testbool
	local AinB, BinA = 0, {}
	local A, B, both = {["A"] = true}, {["B"] = true}, {["A"] = true, ["B"] = true}
	local pA, pB, vA, vB, iA, iB, lines = {}, {}, {}, {}, {}, {}, {}
	
	for i, v in ipairs(polyA) do
		table.insert(pA, v)
		table.insert(iA, {})
	end
	
	local center = vector_origin
	for i, v in ipairs(polyB) do
		center = center + v
	end
	center = center / #polyB
	for i, v in ipairs(polyB) do
		local dir = v - center
		table.insert(pB, v + dir * math.Rand(0, epsilon))
		table.insert(iB, {})
		table.insert(BinA, 0)
	end
	for i, v in ipairs(pA) do
		table.insert(vA, pA[i % #pA + 1] - v)
		lines[v] = {pos = pA[i % #pA + 1], left = A, right = {}}
	end
	for i, v in ipairs(pB) do
		table.insert(vB, pB[i % #pB + 1] - v)
		lines[v] = {pos = pB[i % #pB + 1], left = B, right = {}}
	end
	
	local function modifylines(intersection, P, i, isA)
		local istart, iend = P[i], lines[P[i]].pos
		local area = isA and A or B
		local oppositearea = isA and B or A
		while intersection.fraction > (lines[iend].fraction or 1) do
			istart = lines[istart].pos
			iend = lines[istart].pos
		end
		
		lines[istart] = {
			pos = intersection.pos,
			left = intersection.isin and both or area,
			right = intersection.isin and oppositearea or {},
			fraction = lines[istart].fraction,
		}
		lines[intersection.pos] = {
			pos = iend,
			left = intersection.isin and area or both,
			right = intersection.isin and {} or oppositearea,
			fraction = intersection.fraction,
		}
	end
	
	local vrad1, vrad2 = vector_origin, vector_origin
	local cross, crossA, crossB = vector_origin, vector_origin, vector_origin --Temporary variables
	local intersection = vector_origin
	for a = 1, #pA do
		AinB = 0
		for b = 1, #pB do
			cross = vB[b]:Cross(vA[a]).x
			crossA = vB[b]:Cross(pB[b] - pA[a]).x / cross
			crossB = vA[a]:Cross(pB[b] - pA[a]).x / cross
			if crossA > 0 and crossA < 1 and crossB > 0 and crossB < 1 then
				intersection = pB[b] + crossB * vB[b]
				modifylines({
					pos = intersection,
					fraction = crossA,
					isin = vA[a]:Cross(pB[b] - pA[a]).x < 0,
				}, pA, a, true)
				modifylines({
					pos = Vector(intersection),
					fraction = crossB,
					isin = vB[b]:Cross(pA[a] - pB[b]).x < 0,
				}, pB, b, false)
			end
			
			vrad1 = (pB[b] - pA[a]):GetNormalized()
			vrad2 = (pB[b] + vB[b] - pA[a]):GetNormalized()
			AinB = AinB + math.atan2(vrad1:Cross(vrad2).x, vrad1:Dot(vrad2))
			vrad2 = (pA[a] + vA[a] - pB[b]):GetNormalized()
			vrad1 = (pA[a] - pB[b]):GetNormalized()
			BinA[b] = BinA[b] + math.atan2(vrad1:Cross(vrad2).x, vrad1:Dot(vrad2))
		end
		if 2 * math.pi - epsilon < AinB then
			lines[pA[a]].left = both
			lines[pA[a]].right = B
		end
	end
	for b = 1, #pB do
		if 2 * math.pi - epsilon < BinA[b] then
			lines[pB[b]].left = both
			lines[pB[b]].right = A
		end
	end
	
	local sorted, result, orderResult, filter = {}, {}, {}, {}
	for i, v in pairs(lines) do
		if (not getDifference and v.left.A and v.left.B)
			or (getDifference and v.left.A and not v.left.B) then
			filter[i] = v
		elseif getDifference and v.right.A and not v.right.B then
			filter[v.pos] = {
				pos = i,
				left = v.right,
				right = v.left,
			}
		end
	end
	
	local previousVertex = Vector(-1, -1, -1)
	while table.Count(filter) > 0 do
		if not filter[previousVertex] then
			for k, v in pairs(filter) do
				if k == previousVertex then
					previousVertex = k
					break
				end
			end
			
			if not filter[previousVertex] then
				previousVertex = table.GetKeys(filter)[1]
				table.insert(sorted, {})
				table.insert(result, {})
			end
		end
		if filter[previousVertex] then
			table.insert(sorted[#sorted], filter[previousVertex].pos)
			table.insert(result[#result], filter[previousVertex].pos)
			previousVertex, filter[previousVertex] = filter[previousVertex].pos, nil
		end
	end
	
	local area, triangulated = 0, {}
	for k, sortedpolygon in ipairs(sorted) do
		if #sortedpolygon < 3 then
			result[k] = nil
			continue
		end
		area = 0
		for i, vertex in ipairs(sortedpolygon) do
			local vnext, vprev = sortedpolygon[i % #sortedpolygon + 1], sortedpolygon[(i + #sortedpolygon - 2) % #sortedpolygon + 1]
			area = area + vertex:Cross(vnext).x
			if vertex:DistToSqr(vnext) < 2e-2 or not IsCCW(vprev, vertex, vnext) then
				result[k][i] = nil
			end
		end
		
		if math.abs(area) < 2e-2 then
			result[k] = nil
		else
			table.insert(orderResult, {})
			local keys = table.GetKeys(result[k]) --The argument can have non-numetical keys.
			for newindex, oldindex in ipairs(keys) do --(ex. It can be {1, 2, 4, 5})
				orderResult[#orderResult][newindex] = result[k][oldindex] --This sorts it and preserves its original order.
			end
			local trid = TriangulatePolygon(orderResult[#orderResult])
			table.insert(triangulated, trid)
			orderResult[#orderResult].area = area / 2
			
			if not trid then
				for i, v in ipairs(orderResult[#orderResult]) do
					DebugLine(v, orderResult[#orderResult][i % #orderResult[#orderResult] + 1], true)
				end
				for i, v in ipairs(pA) do
					DebugLine(v, pA[i % #pA + 1])
					DebugText(v, "A" .. i, true)
					print(v)
				end
				print("-------------")
				for i, v in ipairs(pB) do
					debugoverlay.Line(v, pB[i % #pB + 1], 10, Color(255, 255, 0), true)
					DebugText(v, "B" .. i, true)
					print(v)
				end
				DebugText(vector_origin, #orderResult[#orderResult])
			end
		end
	end
	
	-- for i, v in ipairs(pA) do
		-- DebugLine(v, pA[i % #pA + 1])
		-- DebugText(v, "A" .. i, true)
	-- end
	-- for i, v in ipairs(pB) do
		-- debugoverlay.Line(v, pB[i % #pB + 1], 10, Color(255, 255, 0), true)
		-- DebugText(v, "B" .. i, true)
	-- end
	-- if #orderResult > 0 then
		-- for i, v in ipairs(polyA) do
			-- DebugLine(v, polyA[i % #polyA + 1], true)
		-- end
		-- for i, v in ipairs(pB) do
			-- debugoverlay.Line(v, pB[i % #pB + 1], 10, Color(255, 255, 0), true)
		-- end
	-- end
	
	-- print("result: ") PrintTable(result) print()
	-- print("orderResult: ") PrintTable(orderResult) print()
	-- print("triangulated: ") PrintTable(triangulated) print()
	local basepos = vector_origin
	-- for _, tri in ipairs(orderResult) do
		-- for i, t in ipairs(tri) do
			-- debugoverlay.Line(basepos + t + Vector(1, 0.1, 0.1),
				-- basepos + tri[i % #tri + 1] + Vector(1, 0.1, 0.1), 2, Color(0, 255, 255), true)
			-- debugoverlay.Text(basepos + t + Vector(1, 0, -3), tostring(i), 2)
		-- end
	-- end
	for _, tri in ipairs(triangulated) do
		for i, t in ipairs(tri) do
			for i = 1, 3 do
				debugoverlay.Line(basepos + t[i] + Vector(1, 0, 0),
					basepos + t[i % 3 + 1] + Vector(1, 0, 0), 2, Color(0, 255, 255), true)
			end
		end
	end
	-- debugoverlay.Axis(vector_origin, angle_zero, 50, 2)
	return orderResult, triangulated
end
