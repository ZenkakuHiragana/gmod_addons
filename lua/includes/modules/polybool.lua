--assert(SZL, "SZL is required.")
require "SZL"
if getfenv() ~= SZL then setfenv(1, SZL) end
if not SZL.Graph then include "graph.lua" end
if not SZL.Geometry then include "geometry.lua" end
if not SZL.Triangulation then include "triangulation.lua" end
SZL.PolyBool = true

--A Library of boolean operation between two polygons.
--Region(Set of Vector2Ds)
--Polygon(Set of Regions)

local epsilon = SZL.epsilon or 1e-10
local function LessThanPoint(op1, op2, orequal)
	if orequal and op1 == op2 then return true end
	if op1.eqx(op2) then
		return op1.y - op2.y < -epsilon
	else
		return op1.x - op2.x < -epsilon
	end
end

local function LessThanEvent(op1, op2, orequal)
	if orequal and op1 == op2 then return true end
	if op1.point() ~= op2.point() then
		return LessThanPoint(op1.point(), op2.point(), orequal)
	elseif op1.isStart ~= op2.isStart then
		return op2.isStart
	else
		return op2.segment.isright(op1.otherpoint())
	end
end

local function LessThanStatus(op1, op2, orequal)
	if orequal and op1 == op2 then return true end
	local s1, s2 = op1.event.segment, op2.event.segment
	local o11, o12, o21, o22 = s1.start(), s1.endpos(), s2.start(), s2.endpos()
	
	local s1isleft = s1.isleft(o21)
	if s1isleft == s1.isleft(o22) then return s1isleft end
	
	local s2isright = s2.isright(o11)
	if s2isright == s2.isright(o12) then return s2isright end
	if o11 == o21 then return s2.isright(o12) end
	
	local fraction = (o21.x - o11.x) / (o12.x - o11.x)
	local sweep = fraction * (o12 - o11) + o11
	if math.abs(sweep.y - o21.y) < epsilon then
		return ((fraction + epsilon) * (o12 - o11) + o11).y - o21.y < -epsilon
	else
		return sweep.y - o21.y < -epsilon
	end
end

local EventMeta = {
	__eq = function(op1, op2) return op1.segment == op2.segment and op1.isStart == op2.isStart end,
	__lt = function(op1, op2) return LessThanEvent(op1, op2, false) end,
	__le = function(op1, op2) return LessThanEvent(op1, op2, true) end,
	__tostring = function(op)
		return tostring(op.isStart)
		.. ", " .. tostring(op.segment)
		.. (op.disabled and "\t*disabled*" or "")
	end,
}

local StatMeta = {
	__eq = function(op1, op2) return op1.event == op2.event end,
	__tostring = function(op) return "Stat: " .. tostring(op.event) end,
	__lt = function(op1, op2)
		if op1.event < op2.event or op1.event.segment.equalpos(op2.event.segment) then
			return LessThanStatus(op1, op2, false)
		else
			return not LessThanStatus(op2, op1, false)
		end
	end,
	__le = function(op1, op2)
		if op1.event < op2.event or op1.event.segment.equalpos(op2.event.segment) then
			return LessThanStatus(op1, op2, true)
		else
			return not LessThanStatus(op2, op1, true)
		end
	end
}

local function Event(startflag, seg)
	if LessThanPoint(seg.endpos(), seg.start(), false) then seg.negatepos() end
	return setmetatable({
		isStart = startflag,
		segment = seg,
		point = startflag and seg.start or seg.endpos,
		otherpoint = startflag and seg.endpos or seg.start,
	}, EventMeta)
end

local function Status(_event)
	local self = setmetatable({event = _event}, StatMeta)
	_event.status, _event.other.status = self, self
	return self
end

local function EventPair(seg)
	seg = Segment(seg)
	local start, endev = Event(true, seg), Event(false, seg)
	start.other, endev.other = endev, start
	return start, endev
end

local first_match, second_match, next_match
local function Match()
	return {
		index = 0,
		matches_head = false,
		matches_pt1 = false,
	}
end

local function setMatch(index, matches_head, matches_pt1)
	-- return true if we've matched twice
	next_match.index = index
	next_match.matches_head = matches_head
	next_match.matches_pt1 = matches_pt1
	if next_match == first_match then
		next_match = second_match
		return false
	end
	next_match = nil
	return true -- we've matched twice, we're done here
end

local function reverseChain(t)
	for i = 1, #t / 2 do
		local reverse = #t - i + 1
		t[i], t[reverse] = t[reverse], t[i]
	end
end

-- index1 gets index2 appended to it, and index2 is removed
local function appendChain(chains, index1, index2)
	local chain1 = chains[index1]
	local chain2 = chains[index2]
	local tail  = chain1[#chain1]
	local tail2 = chain1[#chain1 - 1]
	local head  = chain2[1]
	local head2 = chain2[2]

	if Segment(tail, head).online(tail2) then
		tail, chain1[#chain1] = tail2
	end

	if Segment(head, head2).online(tail) then
		table.remove(chain2, 1)
	end
	
	for _, v in ipairs(chain2) do chain1[#chain1 + 1] = v end
	table.remove(chains, index2)
end

local function segmentChain(seg, chains, regions)
	local pt1, pt2 = seg.start(), seg.endpos()
	if pt1 == pt2 then return end
	-- search for two chains that this segment matches
	first_match, second_match = Match(), Match()
	next_match = first_match
	for i, chain in ipairs(chains) do
		local head, tail = chain[1], chain[#chain]
		if head == pt1 then if setMatch(i, true, true) then break end
		elseif head == pt2 then if setMatch(i, true, false) then break end
		elseif tail == pt1 then if setMatch(i, false, true) then break end
		elseif tail == pt2 then if setMatch(i, false, false) then break end end
	end
	
	if next_match == first_match then
		chains[#chains + 1] = {pt1, pt2}
	elseif next_match == second_match then
		local index = first_match.index
		local pt = first_match.matches_pt1 and pt2 or pt1 -- if we matched pt1, then we add pt2, etc
		local addToHead = first_match.matches_head -- if we matched at head, then add to the head
		
		local chain = chains[index]
		local grow  = addToHead and chain[1] or chain[#chain];
		local grow2 = addToHead and chain[2] or chain[#chain - 1];
		local oppo  = addToHead and chain[#chain] or chain[1];
		local oppo2 = addToHead and chain[#chain - 1] or chain[2];
		
		if Segment(grow, pt).online(grow2) then
			table.remove(chain, addToHead and 1 or #chain)
			grow = grow2
		end
		
		if oppo == pt then
			table.remove(chains, index)
			if Segment(oppo, grow).online(oppo2) then
				table.remove(chain, addToHead and #chain or 1)
			end
			
			regions[#regions + 1] = chain
		else
			table.insert(chain, addToHead and 1 or #chain + 1, pt)
		end
	else
		local Fh, Sh = first_match.matches_head, second_match.matches_head
		local F, S = first_match.index, second_match.index
		local reverseF = #chains[F] < #chains[S]
		if Fh then
			if Sh then
				if reverseF then
					reverseChain(chains[F])
					appendChain(chains, F, S)
				else
					reverseChain(chains[S])
					appendChain(chains, S, F)
				end
			else
				appendChain(chains, S, F)
			end
		else
			if Sh then
				appendChain(chains, F, S)
			else
				if reverseF then
					reverseChain(chains[F])
					appendChain(chains, S, F)
				else
					reverseChain(chains[S])
					appendChain(chains, F, S)
				end
			end
		end
	end
end

local filter = {
	["OR"] = {nil, false, true, nil, false, false, nil, nil, true, nil, true, nil, nil, nil, nil, nil},
	["AND"] = {nil, nil, nil, nil, nil, false, nil, false, nil, nil, true, true, nil, false, true, nil},
	["DIFFAB"] = {nil, nil, nil, nil, false, nil, false, nil, true, true, nil, nil, nil, true, false, nil},
	["DIFFBA"] = {nil, false, true, nil, nil, nil, true, true, nil, false, nil, false, nil, nil, nil, nil},
	["NOT"] = {nil, false, true, nil, false, nil, nil, true, true, nil, nil, false, nil, true, false, nil},
}

--List of Segment(), true -> merge two groups, operation index(i.e. first + second)
local function sweepline(input, merge, _index, _inverted, out)
	local returning = out or merge and Polygon(_index, input.inverted[1] and true) or {}
	local event, status = BinaryHeap(), AVLTree()
	for _, seg in ipairs(input) do --Setting up event list
		if seg.start() ~= seg.endpos() then --Avoid zero-length segments
			local e1, e2 = EventPair(seg)
			event.add(e1) --Add pair of events
			event.add(e2) --(beginning of the segments, end of the segments)
		end
	end
	
	--subdivide segment by an intersection point
	local function subdivide(dividend, intersection)
		local start, endpos = dividend.point(), dividend.otherpoint()
		if intersection == start or intersection == endpos then return dividend end
		local seg = dividend.segment
		local newstart, newend = EventPair(Segment(intersection, endpos, seg.left, seg.right, seg.getattr(true)))
		status.remove(dividend.status) --In order to refresh AVL Tree
		seg.setend(Vector2D(intersection)) --New endpoint
		status.add(dividend.status) --Refresh AVL Tree's order
		event.refresh(dividend.other) --Refresh Event Queue
		event.add(newstart) --Add new events
		event.add(newend)
		return newstart
	end
	local intersections = 0
	--subdivide and handle coincident segments
	--Segment(), Segment(), intersection point, coincident point
	local function dividesegments(current, other, i1, i2)
		if not i1 then return end
		local throwing = subdivide(current, i1)
		local surviving = subdivide(other, i2 or i1)
		local start, endpos = current.point(), throwing.otherpoint()
		if i1 ~= start and i1 ~= endpos then
			intersections = intersections + 1
		else
			start, endpos = other.point(), surviving.otherpoint()
			if i1 ~= start and i1 ~= endpos then
				intersections = intersections + 1
			end
		end
		if i2 then --(current or throwing) == (other or surviving)
			if not throwing.segment.equalpos(surviving.segment) then
				surviving = not current.segment.equalpos(surviving.segment) and other or surviving
				throwing = not throwing.segment.equalpos(other.segment) and current or throwing
			end
			
			--throwing == surviving
			event.removeif(throwing) --Throwing away one of the coincident edges
			event.removeif(throwing.other)
			status.remove(throwing.status)
			local tseg, seg = throwing.segment, surviving.segment
			if merge then
				seg.other = tseg --{left = tseg.left, right = tseg.right}
			elseif tseg.right == nil or tseg.left ~= tseg.right then
				seg.left = seg.getattr(not seg.left) --Fix annotation
			end
		end
	end
	
	local chainlist, segments = {}, {}
	while not event.isempty() do --Event Loop
		local current = event.remove() --Fetch the left-most(smallest X coord.) event
		local curseg = assert(current).segment
		local curindex = merge and input.tag[curseg.getattr(true)] or _index
		if current.isStart then --current is beginning of the segment
			local curstat = Status(current) --Status bound to current event
			local above, below = status.getadjacent(curstat) --get a segment above current and a segment below
			above, below = above and above.event, below and below.event
			if merge then --is this the third sweep?
				if curseg.other.left == nil and curseg.other.right == nil then --set other annotations
					local inside = below or input.inverted[-curindex]
					if below then
						if curseg.getattr(true) == below.segment.getattr(true) then
							inside = below.segment.other.left
						else
							inside = below.segment.left
						end
					end
					curseg.other.left, curseg.other.right = inside, inside
				end
			else --set annotations
				local toggle = curseg.right == nil or curseg.left ~= curseg.right
				if below then
					curseg.right = below.segment.left
				else
					curseg.right = _inverted
				end
				
				if toggle then
					curseg.left = curseg.getattr(not curseg.right)
				else
					curseg.left = curseg.right
				end
			end
			
			status.add(curstat)
			for _, stat in pairs {above, below} do --get intersection points and subdivide the segment
				dividesegments(current, stat, curseg.intersect(stat.segment))
			end
		else --current is end of the segment
			status.remove(current.status)
			current.status.event = current --point to the end of event correctly
			local above, below = status.getadjacent(current.status)
			if above and below then --calc. between above and below
				above, below = above.event, below.event
				dividesegments(above, below, above.segment.intersect(below.segment))
			end
			
			if merge then --when merging, all segments belong to A
				--If current is second polygon, swap annotations
				local bits = curindex == 1 and {1, 2, 0, 4, 0, 0, 0, 8} or {4, 8, 0, 1, 0, 0, 0, 2}
				local typeof = merge[1 + --Segment selector
					(curseg.left and bits[8] or 0) + --by local filter = { --[[skipped]]-- }
					(curseg.right and bits[4] or 0) +
					(curseg.other.left and bits[2] or 0) +
					(curseg.other.right and bits[1] or 0)
				]
				if typeof ~= nil then
					curseg.left, curseg.right, curseg.other = curseg.getattr(typeof), curseg.getattr(not typeof), {}
					segmentChain(curseg, chainlist, returning)
					segments[#segments + 1] = curseg
				end
			else
				returning[#returning + 1] = curseg
			end
		end
	end
--	print("Intersection points: ", intersections)
	return returning, segments
end

local polyoperate
local PolyMeta = {
	__add = function(op1, op2) return polyoperate(filter.OR, op1, op2) end,
	__sub = function(op1, op2) return polyoperate(filter.DIFFAB, op1, op2) end,
	__mul = function(op1, op2) return polyoperate(filter.AND, op1, op2) end,
	__pow = function(op1, op2) return polyoperate(filter.NOT, op1, op2) end,
	__unm = function(op) op.inverted = not op.inverted return op end,
	__call = function(op, ...)
		if op.segments then return op.segments end
		local segments = {}
		for _, region in ipairs(op) do
			for i, v in ipairs(region) do --Convert polygon into a set of line segments
				segments[#segments + 1] = Segment(v, region[i % #region + 1], op.tag)--, false, op.tag)
			end
		end
		return segments
	end,
}
PolyMeta.__concat = PolyMeta.__add
PolyMeta.__div = PolyMeta.__pow
function Region(...) return {...} end --List of vertices
function Polygon(_tag, ...) --List of Regions
	return setmetatable({
		tag = _tag,
		inverted = (...) == true,
		select(isbool(...) and 2 or 1, ...)
	}, PolyMeta)
end

function polyoperate(op, input1, input2) --16x bool table, Polygon(), Polygon()
	if not input1.tag then input1.tag = "A" end --Annotation fail-safe
	if not input2.tag then input2.tag = "B" end
	
	--Second sweep-line; convert Input2 into annotated line segments
	local sweep = sweepline(input2(), nil, -1, input2.inverted and input2.tag,
		--First sweep-line; convert Input1 into annotated line segments
		sweepline(input1(), nil, 1, input1.inverted and input1.tag, {
		tag = {[input1.tag] = 1, [input2.tag] = -1}, --Preparation for the third sweep-line
		inverted = {input1.inverted and input1.tag, [-1] = input2.inverted and input2.tag}
	}))

	--Third sweep-line; merge Input1 and Input2 and generate a new polygon
	local polydata, combined = sweepline(sweep, op, input1.tag)
	
	--Fourth sweep-line; convert generated polygon into annotated line segments
	polydata.segments = sweepline(polydata(), nil, 1, polydata.inverted and polydata.tag)
	polydata.sweep = combined
	--Fifth sweep-line; make a voronoi diagram and perform a Delaunay Triangulation
	polydata.triangles = Triangulate(polydata.segments)
	return polydata
end
--math.randomseed(os.clock())
--for i = 1, 10 do
--	local s1, s2 = Status(EventPair(
--	Segment(Vector2D(math.random(-100, 100), math.random(-100, 100)),
--			Vector2D(math.random(-100, 100), math.random(-100, 100)))
--	)),
--	Status(EventPair(
--	Segment(Vector2D(math.random(-100, 100), math.random(-100, 100)),
--			Vector2D(math.random(-100, 100), math.random(-100, 100)))
--	))
--	assert(LessThanStatus(s1, s2) ~= LessThanStatus(s2, s1), "\n" .. tostring(s1) .. "\n" .. tostring(s2))
--end
--if p1 then PrintTable(p1 + Polygon()) end