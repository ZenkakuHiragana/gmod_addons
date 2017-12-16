
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local PaintQueue = {}
local InkGroup = {}
local rootpi = math.sqrt(math.pi) / 2
local MIN_BOUND = 20 --Ink minimum bounding box scale
local MIN_BOUND_AREA = 10 --minimum ink bounding box area
local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local MAX_PROCESS_QUEUE_AT_ONCE = 4 --Running QueueCoroutine() at once
local MAX_INKQUEUE_AT_ONCE = 15 --Processing new ink request at once
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local function MakeRect(tx, ty, x1, x2, y1, y2)
	return {mins = Vector(tx[x1], ty[y1]), maxs = Vector(tx[x2], ty[y2])}
end

local function AddInkRectangle(ink, newink, sz)
	local nb = newink.bounds
	local x11, x12, y11, y12 = nb.mins.x, nb.maxs.x, nb.mins.y, nb.maxs.y
	for r, z in pairs(ink) do
		for b in pairs(r.bounds) do
			local x21, x22, y21, y22 = b.mins.x, b.maxs.x, b.mins.y, b.maxs.y
			if (x22 - x21) * (y22 - y21) < MIN_BOUND_AREA then r.bounds[b] = nil end
			if x11 > x22 or x12 < x21 or y11 > y22 or y12 < y21 then continue end
			
			local sx, sy = {x11, x12, x21, x22}, {y11, y12, y21, y22}
			table.sort(sx) table.sort(sy) --sorted X, sorted Y
			r.bounds[b] = nil
			for _, sub in ipairs {
				MakeRect(sx, sy, 1, 2, 1, 2), MakeRect(sx, sy, 2, 3, 1, 2), MakeRect(sx, sy, 3, 4, 1, 2),
				MakeRect(sx, sy, 1, 2, 2, 3), MakeRect(sx, sy, 2, 3, 2, 3), MakeRect(sx, sy, 3, 4, 2, 3),
				MakeRect(sx, sy, 1, 2, 3, 4), MakeRect(sx, sy, 2, 3, 3, 4), MakeRect(sx, sy, 3, 4, 3, 4),
			} do
				if SplatoonSWEPs:CollisionAABB2D(b.mins, b.maxs, sub.mins, sub.maxs) and
				not SplatoonSWEPs:CollisionAABB2D(nb.mins, nb.maxs, sub.mins, sub.maxs) then
					r.bounds[sub] = true
				end
			end
		end
		if not next(r.bounds) then ink[r] = nil end
	end
	
	newink.bounds = {[newink.bounds] = true}
	ink[newink] = sz
end

local function QueueCoroutine(pos, normal, radius, color, polys)
	local ang = normal:Angle()
	local reference_polys = {}
	for i, v in ipairs(polys) do --Scaling
		reference_polys[i] = SplatoonSWEPs:To3D(v * radius, pos, ang)
	end
	
	local inkqueue = 0
	local rectsize = radius * rootpi
	local sizevec = Vector(rectsize, rectsize)
	local whitealpha, whiterotate = math.Rand(0, 255), math.Rand(0, 255)
	local mins, maxs = SplatoonSWEPs:GetBoundingBox(MIN_BOUND, reference_polys)
	for node in SplatoonSWEPs:BSPPairs(reference_polys) do
		local surf = node.Surfaces
		for i = 1, #surf.Origins do
			if surf.Normals[i]:Dot(normal) <= COS_MAX_DEG_DIFF then continue end
			if not SplatoonSWEPs:CollisionAABB(mins, maxs, surf.Mins[i], surf.Maxs[i]) then continue end
			net.Start "SplatoonSWEPs: DrawInk"
			net.WriteUInt(surf.Indices[i], 20)
			net.WriteUInt(color, SplatoonSWEPs.COLOR_BITS)
			net.WriteVector(pos)
			net.WriteFloat(radius)
			net.WriteUInt(whitealpha, 8)
			net.WriteUInt(whiterotate, 8)
			net.WriteVector(surf.Origins[i])
			net.WriteVector(surf.Normals[i])
			net.WriteAngle(surf.Angles[i])
			net.Broadcast()
			
			local pos2d = SplatoonSWEPs:To2D(pos, surf.Origins[i], surf.Angles[i])
			local inkdata = {
				color = color,
				radiusSqr = radius * radius,
				pos = pos2d,
				bounds = {mins = pos2d - sizevec, maxs = pos2d + sizevec},
			}
			AddInkRectangle(surf.InkCircles[i], inkdata, SplatoonSWEPs.InkCounter)
			SplatoonSWEPs.InkCounter = SplatoonSWEPs.InkCounter + 1
			
			inkqueue = inkqueue + 1
			if inkqueue % MAX_INKQUEUE_AT_ONCE == 0 then coroutine.yield() end
		end
	end
	
	coroutine.yield(true)
end

local function ProcessQueue()
	while true do
		local done = 0
		for i, v in ipairs(PaintQueue) do
			if coroutine.status(v.co) == "dead" then continue end
			local ok, message = coroutine.resume(
				v.co, v.pos, v.normal, v.radius, v.color, v.polys)
			if ok and message then
				v.done = true
			elseif not ok then
				print("coroutine end: ", message)
				ErrorNoHalt(debug.traceback(v.co))
			end

			done = done + 1
			if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then coroutine.yield() end
		end
		
		local newqueue = {}
		for i, v in ipairs(PaintQueue) do
			if not v.done then table.insert(newqueue, v) end
		end
		PaintQueue = newqueue
		coroutine.yield()
	end
end

--Do a list of coroutines.
local function DoCoroutines()
	while true do
		local self = SplatoonSWEPsInkManager
		local threads = self.Threads
		local done = 0
		for i, co in pairs(threads) do
			--Give a silent warning if Think(n) has returned
			if coroutine.status(co)  == "dead" then
				Msg(self, "\tSplatoonSWEPs Warning: Coroutine " .. i .. " has finished executing.\n")
				threads[i] = nil
				continue
			end
			--Continue Think's execution
			local ok, message = coroutine.resume(co)
			if not ok then
				ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n")
			end

			-- done = done + 1
			-- if done % MAX_COROUTINES_AT_ONCE == 0 then coroutine.yield() end
		end
		coroutine.yield()
	end
end

local MAX_DEG_GETSURF = 30
local MAX_COS_GETSURF = math.cos(math.rad(MAX_DEG_GETSURF))
local POINT_BOUND = SplatoonSWEPs.vector_one * .1
function SplatoonSWEPs:GetSurfaceColor(tr)
	if not tr.Hit then return end
	for node in self:BSPPairs {tr.HitPos} do
		local surf = node.Surfaces
		for i = 1, #surf.Origins do
			if surf.Normals[i]:Dot(tr.HitNormal) <= MAX_COS_GETSURF then continue end
			if not self:CollisionAABB(tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = self:To2D(tr.HitPos, surf.Origins[i], surf.Angles[i])
			for r in SortedPairsByValue(surf.InkCircles[i], true) do
				if p2d:DistToSqr(r.pos) < r.radiusSqr then
					return r.color
				end
			end
		end
	end
end

SplatoonSWEPsInkManager = {
	DoCoroutines = coroutine.create(DoCoroutines),
	Threads = {
		ProcessQueue = coroutine.create(ProcessQueue),
		Think2 = nil,
	},
	Think = function()
		local self = SplatoonSWEPsInkManager
		if coroutine.status(self.DoCoroutines) ~= "dead" then
			local ok, message = coroutine.resume(self.DoCoroutines)
			if not ok then
				ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n")
			end
		end
	end,
	AddQueue = function(pos, normal, radius, color, polys)
		-- print(coroutine.status(SplatoonSWEPsInkManager.Threads.ProcessQueue))
		-- if coroutine.status(SplatoonSWEPsInkManager.Threads.ProcessQueue) == "running" then
			-- SplatoonSWEPsInkManager.Threads.ProcessQueue = coroutine.create(ProcessQueue)
		-- end
		table.insert(PaintQueue, {
			pos = pos,
			normal = normal,
			radius = radius,
			color = color,
			polys = polys,
			co = coroutine.create(QueueCoroutine),
		})
	end,
	DrawInkGroup = function()
		for _, g in pairs(InkGroup) do
			for __, s in ipairs(g) do
				for i, v in ipairs(s.poly3D) do
					debugoverlay.Line(v.pos, s.poly3D[i % #s.poly3D + 1].pos, 5, Color(0, 255, 0), true)
				end
			end
		end
	end,
}
hook.Add("Tick", "SplatoonSWEPsDoInkCoroutines", SplatoonSWEPsInkManager.Think)
