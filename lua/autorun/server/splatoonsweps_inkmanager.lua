
--This lua manages whole ink in map.
local ss = SplatoonSWEPs
if not ss then return end

local PaintQueue = {}
local InkGroup = {}
local rootpi = math.sqrt(math.pi) / 2
local MIN_BOUND = 20 --Ink minimum bounding box scale
local MIN_BOUND_AREA = 6 --minimum ink bounding box area
local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local MAX_PROCESS_QUEUE_AT_ONCE = 4 --Running QueueCoroutine() at once
local MAX_INKQUEUE_AT_ONCE = 50 --Processing new ink request at once
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local reference_polys = {}
local reference_vert = Vector(1)
local circle_polys = 360 / 12
for i = 1, circle_polys do
	table.insert(reference_polys, Vector(reference_vert))
	reference_vert:Rotate(Angle(0, circle_polys))
end

--[1] = minimum bound, [2] = maximum bound
local function AddInkRectangle(ink, newink, sz)
	local nb = newink.bounds
	local n1, n2, n3, n4 = nb[1], nb[2], nb[3], nb[4]
	for r, z in pairs(ink) do
		if not next(r.bounds) then ink[r] = nil continue end
		for b in pairs(r.bounds) do
			local b1, b2, b3, b4 = b[1], b[2], b[3], b[4]
			if (b3 - b1) * (b4 - b2) < MIN_BOUND_AREA then r.bounds[b] = nil continue end
			if n1 > b3 or n3 < b1 or n2 > b4 or n4 < b2 then continue end
			
			r.bounds[b] = nil
			local x, y = {n1, n3, b1, b3}, {n2, n4, b2, b4} table.sort(x) table.sort(y)
			local x1, x2, x3, x4, y1, y2, y3, y4 = x[1], x[2], x[3], x[4], y[1], y[2], y[3], y[4]
			for _, c in ipairs {
				{x1, y1, x2, y2}, {x2, y1, x3, y2}, {x3, y1, x4, y2},
				{x1, y2, x2, y3}, {x2, y2, x3, y3}, {x3, y2, x4, y3},
				{x1, y3, x2, y4}, {x2, y3, x3, y4}, {x3, y3, x4, y4},
			} do
				local c1, c2, c3, c4 = c[1], c[2], c[3], c[4]
				r.bounds[c] = b1 < c3 and b3 > c1 and b2 < c4 and b4 > c2 and (n1 >= c3 or n3 <= c1 or n2 >= c4 or n4 <= c2) or nil
			end
		end
	end
	
	newink.bounds = {[nb] = true}
	ink[newink] = sz
end

local function QueueCoroutine(pos, normal, radius, color, angle, inktype, ratio)
	local ang, polys = normal:Angle(), {}
	ang.roll = math.abs(normal.z) > COS_MAX_DEG_DIFF and angle * normal.z or ang.yaw
	for i, v in ipairs(reference_polys) do --Scaling
		polys[i] = ss:To3D(v * radius, pos, ang)
	end
	
	local inkqueue = 0
	local rectsize = radius * rootpi
	local sizevec = Vector(rectsize, rectsize)
	local mins, maxs = ss:GetBoundingBox(polys, MIN_BOUND)
	for node in ss:BSPPairs(polys) do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(normal) <= COS_MAX_DEG_DIFF * (index < 0 and .5 or 1) or
			not ss:CollisionAABB(mins, maxs, surf.Mins[i], surf.Maxs[i]) then continue end
			local _, localang = WorldToLocal(vector_origin, ang, vector_origin, surf.Normals[i]:Angle())
			localang = surf.DefaultAngles[i] + ang.yaw - localang.roll
			net.Start "SplatoonSWEPs: DrawInk"
			net.WriteInt(index, ss.SURFACE_INDEX_BITS)
			net.WriteUInt(color, ss.COLOR_BITS)
			net.WriteVector(pos)
			net.WriteFloat(radius)
			net.WriteFloat(localang)
			net.WriteUInt(inktype, 4)
			net.WriteFloat(ratio)
			local omit = {}
			for _, ply in pairs(player.GetAll()) do
				if not ply.Ready then table.insert(omit, ply) end
			end
			net.SendOmit(omit)
			
			local pos2d = ss:To2D(pos, surf.Origins[i], surf.Angles[i])
			local bmins, bmaxs = pos2d - sizevec, pos2d + sizevec
			local inkdata = {
				angle = localang,
				bounds = {bmins.x, bmins.y, bmaxs.x, bmaxs.y},
				color = color,
				pos = pos2d,
				radius = radius,
				ratio = ratio,
				texid = inktype,
			}
			AddInkRectangle(surf.InkCircles[i], inkdata, ss.InkCounter)
			ss.InkCounter = ss.InkCounter + 1
			
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
			local ok, msg = coroutine.resume(v.co, v.pos, v.normal, v.radius, v.color, v.angle, v.inktype, v.ratio)
			if not ok then
				print("coroutine end: ", msg)
				ErrorNoHalt(debug.traceback(v.co))
			end

			v.done = ok and msg
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
		local self = ss.InkManager
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
local POINT_BOUND = ss.vector_one * .1
function ss:GetSurfaceColor(tr)
	if not tr.Hit then return end
	for node in self:BSPPairs {tr.HitPos} do
		local surf = node.Surfaces
		for i, index in ipairs(surf.Indices) do
			if surf.Normals[i]:Dot(tr.HitNormal) <= COS_MAX_DEG_DIFF * (index < 0 and .5 or 1) or not
			self:CollisionAABB(tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = self:To2D(tr.HitPos, surf.Origins[i], surf.Angles[i])
			for r in SortedPairsByValue(surf.InkCircles[i], true) do
				local t = self.InkShotMaterials[r.texid]
				local w, h = t.width, t.height
				local p = (p2d - r.pos) / r.radius
				p:Rotate(Angle(0, r.angle)) --(-1, -1) <= (x, y) <= (1, 1)
				if -1 > p.x or p.x > 1 or -1 > p.y or p.y > 1 then continue end
				p = (p + self.vector_one) / 2 --(0, 0) <= (x, y) <= (1, 1)
				p.y = p.y * h --0 <= y <= h
				p.x = p.x - (1 - r.ratio) / 2 --0 <= x <= r.ratio
				p.x = p.x / r.ratio * w --0 <= x <= w
				p.x, p.y = math.Round(p.x), math.Round(p.y)
				-- print(p.x, p.y, r.texid, (p.y - 1) * w + p.x, t[(p.y - 1) * w + p.x])
				if 0 < p.x and p.x < w and 0 < p.y and p.y < h and t[(p.y - 1) * w + p.x] then
					return r.color
				end
			end
		end
	end
end

ss.InkManager = {
	DoCoroutines = coroutine.create(DoCoroutines),
	Threads = {ProcessQueue = coroutine.create(ProcessQueue)},
	AddQueue = function(pos, normal, radius, color, angle, inktype, ratio)
		table.insert(PaintQueue, {
			angle = math.NormalizeAngle(angle), --Rotation
			co = coroutine.create(QueueCoroutine), --Coroutine
			color = color, --Ink color
			normal = normal, --Normal vector
			pos = pos, --Origin
			radius = radius, --Size
			ratio = ratio, --Stretch ink, x/y
			inktype = inktype, --Texture type
		})
	end,
}
