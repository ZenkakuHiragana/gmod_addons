
if not SplatoonSWEPs then return end

local testbool = true
local pointA = {
	Vector(0, 30, 0),
	Vector(0, 60, -40),
	Vector(0, 100, 0),
	Vector(0, 70, 70),
	Vector(0, 10, 70),
}
local pointB = {
	Vector(0, 110, 30),
	Vector(0, 50, 50),
	Vector(0, 30, 20),
	Vector(0, -50, 10),
	Vector(0, 0, -50),
}

pointA = {
	Vector(0, 0, 0),
	Vector(0, 20, 10),
	Vector(0, 50, 10),
	Vector(0, 90, -10),
	Vector(0, 100, 0),
	Vector(0, 100, 100),
	Vector(0, 90, 110),
	Vector(0, 50, 90),
	Vector(0, 20, 90),
	Vector(0, 0, 100),
}

pointB = {
	Vector(0, 10, 50),
	Vector(0, 50, -20),
	Vector(0, 120, 30),
	Vector(0, 60, 30),
	Vector(0, 80, 40),
	Vector(0, 80, 60),
	Vector(0, 60, 70),
	Vector(0, 120, 70),
	Vector(0, 50, 120),
}

pointA = {
	-Vector(0.000000, 34.034424, 90.628113),
	-Vector(0.000000, 39.326607, 91.680756),
	-Vector(0.000000, 38.268238, 92.387955),
	-Vector(0.000000, -0.000046, 99.999985),
	-Vector(0.000000,-38.268318, 92.387878),
	-Vector(0.000000,-70.710701, 70.710678),
	-Vector(0.000000,-92.388092, 38.268215),
	-Vector(0.000000,-99.127029,  4.388807),
	-Vector(0.000000,-99.126938, -4.388760),
	-Vector(0.000000,-92.387825,-38.268459),
	-Vector(0.000000,-70.710640,-70.710800),
	-Vector(0.000000,-38.268242,-92.388023),
	-Vector(0.000000, -0.000062,-100.000023),
	-Vector(0.000000, 32.975941,-93.440582),
	-Vector(0.000000,  1.591969,-72.470604),
	-Vector(0.000000,-20.085163,-40.028286),
	-Vector(0.000000,-27.697329, -1.759913),
	-Vector(0.000000,-20.085226, 36.508305),
	-Vector(0.000000,  1.592013, 68.950859),
}
-- 1	=	0.000000 -41.569206 24.000004
-- 2	=	0.000000 -70.906143 -12.502650
-- 3	=	0.000000 -30.853806 -36.770115
-- 4	=	0.000000 -6.695038 -45.563202
-- 5	=	0.000000 -7.270855 -18.335157
-- 6	=	0.000000 -22.353874 26.000053
-- 7	=	0.000000 23.583138 35.105305
-- 8	=	0.000000 35.057571 41.410439
-- 9	=	0.000000 16.416969 45.105236
-- 10	=	0.000000 -24.625435 67.657860

pointA = {}
pointB = {}
local circle_polys = 9
local reference_vert = Vector(0, -60, 0)
for i = 1, circle_polys + 1 do
	table.insert(pointA, Vector(reference_vert))-- * ((i % 2 == 0) and 1.2 or 0.8))
	table.insert(pointB, Vector(reference_vert))-- * ((i % 2 == 1) and 1.2 or 0.8))
	reference_vert:Rotate(Angle(0, 360 / circle_polys / 2, 0))
end
for i, v in ipairs(pointA) do
	pointA[i] = Vector(0, v.x - 5, v.y)
end
for i, v in ipairs(pointB) do
	pointB[i] = Vector(0, v.x - 5, v.y - 40)
end

local function IsInTriangle(p1, p2, p3, p)
	return (p2 - p1):Cross(p - p1).x > 0 and
			(p3 - p2):Cross(p - p2).x > 0 and
			(p1 - p3):Cross(p - p3).x > 0
end

local function TriangulatePolygon(source)	
	if #source == 3 then return {source} end --We won't triangulate triangles.
	
	local triangulateflag = {}
	local sortedbylength = {}
	local n, concave, concaveflag = #source, {}, {} --We get vertices that make concaves.
	for i = 1, n do
		if (source[i % n + 1] - source[i]):Cross(
			source[(i + 1) % n + 1] - source[i]).x < 0 then
			table.insert(concave, i % n + 1)
			concaveflag[i % n + 1] = true
		end
		triangulateflag[i] = source[i]:LengthSqr()
	end
	if #concave == 0 then concave = {1} end --If no concaves were found, the polygon is convex.
	
	local result, lasttriangle = {}, {}
	local basepos, minus1, plus1, longest, dist, vertexcount = 0, -1, 1, 0, 0, n
	for __ = 1, n * 2 do
		basepos, longest = nil, 0
		for i = 1, n do
			if triangulateflag[i] then
				dist = triangulateflag[i]
				if longest < dist then
					longest = dist
					basepos = i
				end
			end
		end
		
		if basepos then
			for _ = 1, n * 2 do
				minus1 = (basepos + n - 2) % n + 1
				plus1 = basepos % n + 1
				for i = 1, n do
					if not triangulateflag[minus1] then
						minus1 = (minus1 + n - 2) % n + 1
					elseif not triangulateflag[plus1] then
						plus1 = plus1 % n + 1
					else
						break
					end
				end
				
				if (source[plus1] - source[basepos]):Cross(source[minus1] - source[basepos]).x > 0 then
					for i = 1, n do
						if IsInTriangle(source[minus1], source[basepos], source[plus1], source[i]) then
							basepos = plus1
							break
						end
					end
					if basepos ~= plus1 then
						vertexcount = vertexcount - 1
						table.insert(result, {source[minus1], source[basepos], source[plus1]})
						triangulateflag[basepos] = nil
					end
				else
					basepos = plus1
				end
				if basepos ~= plus1 then break end
				if _ == n * 2 then print("infinite, 2") end
			end
		end
		if vertexcount < 4 then break end
		if __ == n * 2 then print("infinite, 1") end
	end
	
	if vertexcount == 3 then
		for i = 1, n do
			if triangulateflag[i] then
				table.insert(lasttriangle, source[i])
			end
		end
		table.insert(result, lasttriangle)
	end
	return result
end

--Boolean operation between polyA and polyB.
--If getDifference is true, the result will be polyA - polyB.
--Otherwise, the result will be polyA AND polyB.
local epsilon = 0.0001
function SplatoonSWEPs.BuildOverlap(polyA, polyB, getDifference)
	-- polyA, polyB, getDifference = pointA, pointB, testbool
	local AinB, BinA = 0, {}
	local A, B, both = {["A"] = true}, {["B"] = true}, {["A"] = true, ["B"] = true}
	local pA, pB, vA, vB, iA, iB, lines = {}, {}, {}, {}, {}, {}, {}
	
	for i, v in ipairs(polyA) do
		if getDifference then
		-- debugoverlay.Line(v, polyA[i % #polyA + 1], 2, Color(0, 255, 0), true)
		-- debugoverlay.Text(v, "A" .. i, 2, Color(0, 255, 0), true)
		end
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
		if getDifference then
		-- debugoverlay.Line(v, pB[i % #pB + 1], 2, Color(255, 255, 0), true)
		-- debugoverlay.Text(v, "B" .. i, 2, Color(255, 255, 0), true)
		end
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
			area = area + vertex:Cross(sortedpolygon[i % #sortedpolygon + 1]).x
			if vertex:DistToSqr(sortedpolygon[i % #sortedpolygon + 1]) < epsilon * 10 then
				result[k][i] = nil
			end
		end
		if math.abs(area) < 0.02 then
			result[k] = nil
		else
			table.insert(orderResult, {})
			local keys = table.GetKeys(result[k]) --The argument can have non-numetical keys.
			for newindex, oldindex in ipairs(keys) do --(ex. It can be {1, 2, 4, 5})
				orderResult[#orderResult][newindex] = result[k][oldindex] --This sorts it and preserves its original order.
			end
			table.insert(triangulated, TriangulatePolygon(orderResult[#orderResult]))
			orderResult[#orderResult].area = area / 2
		end
	end
	
	-- print("result: ") PrintTable(result) print()
	-- print("orderResult: ") PrintTable(orderResult) print()
	-- print("triangulated: ") PrintTable(triangulated) print()
	-- for _, tri in ipairs(orderResult) do
		-- for i, t in ipairs(tri) do
			-- debugoverlay.Line(t + Vector(1, 0.1, 0.1),
				-- tri[i % #tri + 1] + Vector(1, 0.1, 0.1), 2, Color(0, 255, 255), true)
			-- debugoverlay.Text(t + Vector(1, 0, -3), tostring(i), 2)
		-- end
	-- end
	-- for _, tri in ipairs(triangulated) do
		-- for i, t in ipairs(tri) do
			-- for i = 1, 3 do
				-- debugoverlay.Line(t[i] + Vector(1, 0, 0),
					-- t[i % 3 + 1] + Vector(1, 0, 0), 2, Color(0, 255, 255), true)
			-- end
		-- end
	-- end
	-- debugoverlay.Axis(vector_origin, angle_zero, 50, 2)
	return orderResult, triangulated
end
