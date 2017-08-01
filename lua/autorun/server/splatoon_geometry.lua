
--Finds intersection points between segment 1 and segment 2
--seg1 = {start = Vector(0, y1, z1), endpos = Vector(0, y2, z2)}
local function CheckCross(queue, intersections, segs, seg1, seg2)
	local intersection, q = nil, queue[1]
	local s1, s2 = {segs[seg1].start, segs[seg1].endpos}, {segs[seg2].start, segs[seg2].endpos}
	local ds = s2[1] - s1[1]
	local v1, v2 = s1[2] - s1[1], s2[2] - s2[1]
	local cross, cross1, cross2 = v2:Cross(v1).x, 0, 0
	crossA = v2:Cross(ds).x / cross
	crossB = v1:Cross(ds).x / cross
	if crossA >= 0 and crossA <= 1 and crossB >= 0 and crossB <= 1 then
		intersection = s2[1] + crossB * v2
	end
	
	if intersection and (q.y > intersection.y or (q.y == intersection.y and q.z > intersection.z)) then
		if s1[1].y > s2[1].y then
			seg1, seg2 = seg2, seg1
		end
		intersection = {
			pos = intersection,
			y = intersection.y,
			z = intersection.z,
			type = "intersection",
			seg1 = seg1,
			seg2 = seg2,
		}
		table.insert(queue, intersection)
		table.insert(intersections, intersection.pos)
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
	for i = 1, #__Segments, 2 do
		if not __Segments[i + 1] then break end
		start, endpos = __Segments[i], __Segments[i + 1]
		if start.y > endpos.y or (start.y == endpos.y and start.z > endpos.z) then
			start, endpos = endpos, start
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
			seg1 = math.floor(i / 2) + 1,
		})
		table.insert(queue, {
			pos = endpos,
			y = endpos.y,
			z = endpos.z,
			type = "end",
			seg1 = math.floor(i / 2) + 1,
		})
	end
	
	local preventstuck = 1
	local q = nil
	local intersection = nil
	local segmentindex = 1
	local segleft, segright = -1, -1
	while #queue > 0 do
		table.sort(queue, function(q1, q2)
			return not (q1.y > q2.y or (q1.y == q2.y and (q1.z > q2.z or
				(q1.z == q2.z and EventTypePriority[q1.type] < EventTypePriority[q2.type]))))
		end)
		
		q = queue[1]
		table.remove(queue, 1)
		if q.type == "start" then
			table.insert(status, q)
			table.SortByMember(status, "z", true)
			segmentindex = -1
			for index, seg in ipairs(status) do
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
		elseif q.type == "end" then
			segmentindex = table.RemoveByValue(status, q)
			if segmentindex and segmentindex > 1 then
				CheckCross(queue, intersections, segments, status[segmentindex - 1].seg1,	status[segmentindex].seg1)
			end
		else --q.type == "intersection"
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
