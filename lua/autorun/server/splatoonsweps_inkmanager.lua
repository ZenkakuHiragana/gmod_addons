
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local PaintQueue = {}
local InkGroup = {}
local rootpi = math.sqrt(math.pi) / 2
local MIN_BOUND = 20 --Ink minimum bounding box scale
local MIN_BOUND_AREA = 10 --minimum ink bounding box area
local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local MAX_PROCESS_QUEUE_AT_ONCE = 4 --Running QueueCoroutine() at once
local MAX_INKQUEUE_AT_ONCE = 50 --Processing new ink request at once
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local function MakeRect(tx, ty, x1, x2, y1, y2)
	return {Vector(tx[x1], ty[y1]), Vector(tx[x2], ty[y2])}
end

--[1] = minimum bound, [2] = maximum bound
local function AddInkRectangle(ink, newink, sz)
	local nb = newink.bounds
	for r, z in pairs(ink) do
		if not next(r.bounds) then ink[r] = nil else
			for b in pairs(r.bounds) do
				if (b[3] - b[1]) * (b[4] - b[2]) < MIN_BOUND_AREA then r.bounds[b] = nil continue end
				if nb[1] > b[3] or nb[3] < b[1] or nb[2] > b[4] or nb[4] < b[2] then continue end
				
				r.bounds[b] = nil
				local x, y = {nb[1], nb[3], b[1], b[3]}, {nb[2], nb[4], b[2], b[4]}
				table.sort(x) table.sort(y) --sorted X, sorted Y
				for _, c in ipairs {
					{x[1], y[1], x[2], y[2]}, {x[2], y[1], x[3], y[2]}, {x[3], y[1], x[4], y[2]},
					{x[1], y[2], x[2], y[3]}, {x[2], y[2], x[3], y[3]}, {x[3], y[2], x[4], y[3]},
					{x[1], y[3], x[2], y[4]}, {x[2], y[3], x[3], y[4]}, {x[3], y[3], x[4], y[4]},
				} do
					if b[1] < c[3] and b[3] > c[1] and b[2] < c[4] and b[4] > c[2] and
						(nb[1] >= c[3] or nb[3] <= c[1] or nb[2] >= c[4] or nb[4] <= c[2]) then
						r.bounds[c] = true
					end
				end
			end
		end
	end
	
	newink.bounds = {[nb] = true}
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
	local whitealpha, whiterotate = math.Rand(0, 63), math.Rand(0, 255)
	local mins, maxs = SplatoonSWEPs:GetBoundingBox(reference_polys, MIN_BOUND)
	for node in SplatoonSWEPs:BSPPairs(reference_polys) do
		local surf = node.Surfaces
		for i = 1, #surf.Origins do
			if surf.Normals[i]:Dot(normal) <= COS_MAX_DEG_DIFF * (surf.Indices[i] < 0 and .5 or 1) or
			not SplatoonSWEPs:CollisionAABB(mins, maxs, surf.Mins[i], surf.Maxs[i]) then continue end
			net.Start "SplatoonSWEPs: DrawInk"
			net.WriteInt(surf.Indices[i], 20)
			net.WriteUInt(color, SplatoonSWEPs.COLOR_BITS)
			net.WriteVector(pos)
			net.WriteFloat(radius)
			net.WriteUInt(whitealpha, 6)
			net.WriteUInt(whiterotate, 8)
			net.WriteVector(surf.Origins[i])
			net.WriteVector(surf.Normals[i])
			net.WriteAngle(surf.Angles[i])
			net.Broadcast()
			
			local pos2d = SplatoonSWEPs:To2D(pos, surf.Origins[i], surf.Angles[i])
			local bmins, bmaxs = pos2d - sizevec, pos2d + sizevec
			local inkdata = {
				color = color,
				radiusSqr = radius * radius,
				pos = pos2d,
				bounds = {bmins.x, bmins.y, bmaxs.x, bmaxs.y},
			}
			AddInkRectangle(surf.InkCircles[i], inkdata, SplatoonSWEPs.InkCounter)
			SplatoonSWEPs.InkCounter = SplatoonSWEPs.InkCounter + 1
			
			inkqueue = inkqueue + 1
			if inkqueue % MAX_INKQUEUE_AT_ONCE == 0 then coroutine.yield() end
		end
	end
	-- print(inkqueue)
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
			-- if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then coroutine.yield() end
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
		local self = SplatoonSWEPs.InkManager
		local threads = self.Threads
		local done = 0
		for i, co in pairs(threads) do
			--Give a silent warning if Think(n) has stopped
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
			if surf.Normals[i]:Dot(tr.HitNormal) <= COS_MAX_DEG_DIFF * (surf.Indices[i] < 0 and .5 or 1) or not
			self:CollisionAABB(tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = self:To2D(tr.HitPos, surf.Origins[i], surf.Angles[i])
			for r in SortedPairsByValue(surf.InkCircles[i], true) do
				if p2d:DistToSqr(r.pos) < r.radiusSqr then
					return r.color
				end
			end
		end
	end
end

SplatoonSWEPs.InkManager = {
	DoCoroutines = coroutine.create(DoCoroutines),
	Threads = {
		ProcessQueue = coroutine.create(ProcessQueue),
	},
	Think = function()
		local self = SplatoonSWEPs.InkManager
		if coroutine.status(self.DoCoroutines) == "dead" then return end
		local ok, message = coroutine.resume(self.DoCoroutines)
		if not ok then ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n") end
	end,
	AddQueue = function(pos, normal, radius, color, polys)
		table.insert(PaintQueue, {
			pos = pos,
			normal = normal,
			radius = radius,
			color = color,
			polys = polys,
			co = coroutine.create(QueueCoroutine),
		})
	end,
}
hook.Add("Tick", "SplatoonSWEPsDoInkCoroutines", SplatoonSWEPs.InkManager.Think)
