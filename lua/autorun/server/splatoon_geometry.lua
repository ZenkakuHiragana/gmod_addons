
--Finds intersection points between segment 1 and segment 2
--seg1 = {start = Vector(0, y1, z1), endpos = Vector(0, y2, z2)}
local function CheckCross(queue, intersections, segs, seg1, seg2)
	local intersection, q = nil, queue[1]
	local s1, s2 = {segs[seg1].start, segs[seg1].endpos}, {segs[seg2].start, segs[seg2].endpos}
	local ds = s2[1] - s1[1]
	local v1, v2 = s1[2] - s1[1], s2[2] - s2[1]
	local cross, cross1, cross2 = v2:Cross(v1).x, 0, 0
	crossA, crossB = v2:Cross(ds).x / cross, v1:Cross(ds).x / cross
	if crossA >= 0 and crossA <= 1 and crossB >= 0 and crossB <= 1 then
		intersection = s2[1] + crossB * v2 --closed line segment so we use >= and <=
	end
	
	--make sure it is new intersection point
	if intersection and (q.y > intersection.y or (q.y == intersection.y and q.z > intersection.z)) then
		if s1[1].y > s2[1].y then --sort to make seg1 be left
			seg1, seg2 = seg2, seg1
		end
		table.insert(queue, {
			pos = intersection,
			y = intersection.y,
			z = intersection.z,
			type = "intersection",
			seg1 = seg1,
			seg2 = seg2,
		})
		table.insert(intersections, intersection) --result table
	end
end

--Using plane sweep algorithm
--Gets intersection points from given segments in YZ plane
--__Segments = {s1, s2, ...} = {Vector(0, s1y, s1z), Vector(0, s2y, s2z), ...}
--Event object = {
--    pos = Event position,
--    y = pos.y,
--    z = pos.z
--    type = "start" / "end" / "intersection",
--    seg1 = i -> segments[i],
--    seg2 = i -> segments[i],
--}
local EventTypePriority = {["start"] = 1, ["intersection"] = 2, ["end"] = 3}
local function GetIntersections(__Segments)
	local intersections = {}
	local eventlist, queue, status = {}, {}, {}
	local segments = {}
	local start, endpos = vector_origin, vector_origin
	for i = 1, #__Segments, 2 do --set up data structures
		if not __Segments[i + 1] then break end
		start, endpos = __Segments[i], __Segments[i + 1]
		if start.y > endpos.y or (start.y == endpos.y and start.z > endpos.z) then
			start, endpos = endpos, start --make sure start.y < end.y and start.z < end.z
		end
		
		table.insert(segments, {
			start = start,
			endpos = endpos,
		})
		table.insert(queue, {
			pos = start,
			y = start.y,
			z = start.z,
			type = "start",
			seg1 = math.floor(i / 2) + 1, --index of segments
		})
		table.insert(queue, {
			pos = endpos,
			y = endpos.y,
			z = endpos.z,
			type = "end",
			seg1 = math.floor(i / 2) + 1,
		})
	end
	
	local preventstuck = 1 --probably this is not needed, but I'm afraid of infinite loop
	local q = nil
	local segmentindex, segleft, segright = -1, -1, -1
	while #queue > 0 do
		table.sort(queue, function(q1, q2)
			return not (q1.y > q2.y or (q1.y == q2.y and (q1.z > q2.z or
				(q1.z == q2.z and EventTypePriority[q1.type] < EventTypePriority[q2.type]))))
		end)
		
		q = queue[1]
		table.remove(queue, 1)
		if q.type == "start" then --sweep line meets the start point of new segment
			table.insert(status, q)
			table.SortByMember(status, "z", true)
			segmentindex = -1
			for index, seg in ipairs(status) do --Using self-balancing binary search tree makes faster
				if seg.seg1 == q.seg1 then
					segmentindex = index
					break
				end
			end
			assert(segmentindex > 0)
			if segmentindex > 1 then
				CheckCross(queue, intersections, segments, status[segmentindex].seg1,	status[segmentindex - 1].seg1)
			end
			if segmentindex < #status then
				CheckCross(queue, intersections, segments, status[segmentindex].seg1,	status[segmentindex + 1].seg1)
			end
		elseif q.type == "end" then --sweep line meets the end point of segment in status
			segmentindex = table.RemoveByValue(status, q)
			if segmentindex and segmentindex > 1 then
				CheckCross(queue, intersections, segments, status[segmentindex - 1].seg1,	status[segmentindex].seg1)
			end
		else --q.type == "intersection" --sweep line meets intersection point
			segleft, segright = -1, -1
			for index, seg in ipairs(status) do
				if segleft < 0 and seg.seg1 == q.seg1 then
					segleft = index
				end
				if segright < 0 and seg.seg1 == q.seg2 then
					segright = index
				end
				if segleft > 0 and segright > 0 then
					break
				end
			end
			assert(segleft > 0 and segright > 0)
			if segleft > 1 then
				CheckCross(queue, intersections, segments, status[segleft - 1].seg1, status[segright].seg1)
			end
			if segright < #status then
				CheckCross(queue, intersections, segments, status[segleft].seg1, status[segright + 1].seg1)
			end
			
			status[segleft], status[segright] = status[segright], status[segleft]
		end
		
		preventstuck = preventstuck + 1
		if preventstuck > #__Segments * 10 then
			print("SplatoonSWEPsGeometry.GetIntersections: Prevented infinite loop! (" .. preventstuck .. ")") return
		end
	end
	
	return intersections
end

SplatoonSWEPsGeometry = {
	GetIntersections = GetIntersections,
}

local pointA = {
	Vector(0, 0, 0),
	Vector(0, 100, 0),
	Vector(0, 70, 70),
}
local pointB = {
	Vector(0, 110, 30),
	Vector(0, 30, 70),
	Vector(0, 10, 70),
	Vector(0, -50, 10),
	Vector(0, 10, -50),
}

-- pointA = {}
-- pointB = {}
-- local circle_polys = 8
-- local reference_vert = Vector(0, -60, 0)
-- for i = 1, circle_polys do
	-- table.insert(pointA, Vector(reference_vert))
	-- table.insert(pointB, Vector(reference_vert))
	-- reference_vert:Rotate(Angle(0, 360 / circle_polys, 0))
-- end
-- for i, v in ipairs(pointA) do
	-- pointA[i] = Vector(0, v.x, v.y)
-- end
-- for i, v in ipairs(pointB) do
	-- pointB[i] = Vector(0, v.x * 2 + 50, v.y / 2 + 10)
-- end

local epsilon = 0.0001
local bool = "AND"
function SplatoonSWEPsGeometry.TestFunction()
	local AinB, BinA = true, {}
	local A, B, both = {["A"] = true}, {["B"] = true}, {["A"] = true, ["B"] = true}
	local pA, pB, vA, vB, iA, iB, lines = {}, {}, {}, {}, {}, {}, {}
	for i, v in ipairs(pointA) do
		debugoverlay.Line(v, pointA[i % #pointA + 1], 2, Color(0, 255, 0), true)
		table.insert(pA, v + Vector(0, math.Rand(-epsilon, epsilon), math.Rand(-epsilon, epsilon)))
		table.insert(vA, pointA[i % #pointA + 1] - v)
		table.insert(iA, {})
	end
	for i, v in ipairs(pointB) do
		debugoverlay.Line(v, pointB[i % #pointB + 1], 2, Color(255, 255, 0), true)
		table.insert(pB, v + Vector(0, math.Rand(-epsilon, epsilon), math.Rand(-epsilon, epsilon)))
		table.insert(vB, pointB[i % #pointB + 1] - v)
		table.insert(iB, {})
		table.insert(BinA, true)
	end
	for i, v in ipairs(pA) do
		lines[v] = {pos = pA[i % #pA + 1], left = A, right = {}}
	end
	for i, v in ipairs(pB) do
		lines[v] = {pos = pB[i % #pB + 1], left = B, right = {}}
	end
	
	local function modifylines(iP, P, i, isA)
		if iP[1] then
			if iP[2] then -- pA[a]->pA[a + 1] => pA[a]->iP[1].pos->iP[2].pos->pA[a + 1]
				if iP[1].fraction > iP[2].fraction then
					iP[1], iP[2] = iP[2], iP[1]
				end
				lines[P[i]] = {
					pos = iP[1].pos,
					left = isA and A or B,
					right = {},
				}
				lines[iP[1].pos] = {
					pos = iP[2].pos,
					left = both,
					right = not isA and A or B,
				}
				lines[iP[2].pos] = {
					pos = P[i % #P + 1],
					left = isA and A or B,
					right = {},
				}
			else -- pA[a]->pA[a + 1] => pA[a]->iP[1].pos->pA[a + 1]
				local newleft = iP[1].isin and both or (isA and A or B)
				local newleft2 = not iP[1].isin and both or (isA and A or B)
				local newright = iP[1].isin and (not isA and A or B) or {}
				local newright2 = not iP[1].isin and (not isA and A or B) or {}
				lines[P[i]] = {
					pos = iP[1].pos,
					left = newleft,
					right = newright,
				}
				lines[iP[1].pos] = {
					pos = P[i % #P + 1],
					left = newleft2,
					right = newright2,
				}
			end
		end
	end
	
	local cross, crossA, crossB = vector_origin, vector_origin, vector_origin --Temporary variables
	local intersection = vector_origin
	for a = 1, #pA do
		AinB = true
		for b = 1, #pB do
			cross = vB[b]:Cross(vA[a]).x
			crossA = vB[b]:Cross(pB[b] - pA[a]).x / cross
			crossB = vA[a]:Cross(pB[b] - pA[a]).x / cross
			if crossA > 0 and crossA < 1 and crossB > 0 and crossB < 1 then
				intersection = pB[b] + crossB * vB[b]
				table.insert(iA[a], {
					pos = intersection,
					fraction = crossA,
					isin = vA[a]:Cross(pB[b] - pA[a]).x < 0,
				})
				table.insert(iB[b], {
					pos = Vector(intersection),
					fraction = crossB,
					isin = vB[b]:Cross(pA[a] - pB[b]).x < 0,
				})
			end
			AinB = AinB and vB[b]:Cross(pA[a] - pB[b]).x > 0
			BinA[b] = BinA[b] and vA[a]:Cross(pB[b] - pA[a]).x > 0
		end
		
		modifylines(iA[a], pA, a, true)
		if AinB then
			lines[pA[a]].left = both
			lines[pA[a]].right = B
		end
	end
	for b = 1, #pB do
		modifylines(iB[b], pB, b, false)
		if BinA[b] then
			lines[pB[b]].left = both
			lines[pB[b]].right = A
		end
	end
	
	local result, filter = {}, {}
	for i, v in pairs(lines) do
		if bool == "AND" and v.left.A and v.left.B
			or bool == "A" and v.left.A and not v.left.B then
			filter[i] = v
		elseif bool == "A" and v.right.A and not v.right.B then
			filter[v.pos] = {
				pos = i,
				left = v.right,
				right = v.left,
			}
		end
	end
	
	local prev = Vector(-1, -1, -1)
	for i = 1, 200 do
		if table.Count(filter) == 0 then break end
		if not filter[prev] then
			for k, v in pairs(filter) do
				if k == prev then
					prev = k
					break
				end
			end
			
			if not filter[prev] then
				for k, v in pairs(filter) do
					prev = k
					break
				end
				table.insert(result, {})
			end
		end
		if filter[prev] then
			table.insert(result[#result], filter[prev].pos)
			prev, filter[prev] = filter[prev].pos, nil
		end
	end
	
	local final = {}
	for k, vv in ipairs(result) do
		local area = 0
		for i, v in ipairs(vv) do
			area = area + v:Cross(vv[i % #vv + 1]).x
		end
		area = math.abs(area) / 2
		print(area)
		if area > 0.01 then table.insert(final, vv) end
	end
	result = final
	
	print("result: ") PrintTable(result) print()
	for k = 1, #result do
		for i = 1, #result[k] do
			debugoverlay.Line(result[k][i] + Vector(1, 0, 0),
				result[k][i % #result[k] + 1] + Vector(1, 0, 0), 2, Color(0, 255, 255), true)
		end
	end
	return result
end
