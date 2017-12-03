
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local PaintQueue = {}
local InkGroup = {}
local function MakeRect(tx, ty, x1, x2, y1, y2)
	return {
		mins = Vector(tx[x1], ty[y1]),
		maxs = Vector(tx[x2], ty[y2]),
	}
end

local function AddInkRectangle(face, newrects, sz)
	local org = newrects[1]
	local notcollide = true
	local keys = table.GetKeys(face.InkRectangles)
	while #newrects > 0 do
		local s = table.remove(newrects, 1)
		for _, r in ipairs(keys) do
			if r.color == s.color then continue end
			
			local x11, x12, y11, y12 = s.mins.x, s.maxs.x, s.mins.y, s.maxs.y
			local x21, x22, y21, y22 = r.mins.x, r.maxs.x, r.mins.y, r.maxs.y
			if x11 > x22 or x12 < x21 or y11 > y22 or y12 < y21 then continue end
			
			local z = face.InkRectangles[r]
			local sx, sy = {x11, x12, x21, x22}, {y11, y12, y21, y22}
			table.sort(sx) table.sort(sy) --sorted X, sorted Y
			for y, ry in ipairs {
				{MakeRect(sx, sy, 1, 2, 1, 2), MakeRect(sx, sy, 2, 3, 1, 2), MakeRect(sx, sy, 3, 4, 1, 2)},
				{MakeRect(sx, sy, 1, 2, 2, 3), MakeRect(sx, sy, 2, 3, 2, 3), MakeRect(sx, sy, 3, 4, 2, 3)},
				{MakeRect(sx, sy, 1, 2, 3, 4), MakeRect(sx, sy, 2, 3, 3, 4), MakeRect(sx, sy, 3, 4, 3, 4)},
			} do
				for _, ryx in ipairs(ry) do
					if SplatoonSWEPs:CollisionAABB2D(s.mins, s.maxs, ryx.mins, ryx.maxs) then
						ryx.color = s.color
						face.InkRectangles[s] = nil
						face.InkRectangles[ryx] = sz
						table.insert(newrects, ryx)
					elseif SplatoonSWEPs:CollisionAABB2D(r.mins, r.maxs, ryx.mins, ryx.maxs) then
						ryx.color = r.color
						face.InkRectangles[ryx] = z
					end
				end
			end
			
			face.InkRectangles[r] = nil
			notcollide = false
		end
	end
	
	if notcollide then
		face.InkRectangles[org] = sz
	end
end

local rootpi = math.sqrt(math.pi)
local MIN_BOUND = 20 --Ink minimum bounding box scale
local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local MAX_PROCESS_QUEUE_AT_ONCE = 20 --Running QueueCoroutine() at once
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local function QueueCoroutine(pos, normal, radius, color, polys)
	local ang = normal:Angle()
	local reference_polys = {}
	for i, v in ipairs(polys) do --Scaling
		reference_polys[i] = SplatoonSWEPs:To3D(v * radius, pos, ang)
	end
	
	local rectsize = radius * rootpi
	local sizevec = Vector(rectsize, rectsize)
	local whitealpha, whiterotate = math.Rand(0, 255), math.Rand(0, 255)
	local mins, maxs = SplatoonSWEPs:GetBoundingBox(MIN_BOUND, reference_polys)
	for node in SplatoonSWEPs:BSPPairs({Vertices = reference_polys}, i) do
		for k, f in ipairs(node.Surfaces) do
			if f.normal:Dot(normal) <= COS_MAX_DEG_DIFF then continue end
			if not SplatoonSWEPs:CollisionAABB(mins, maxs, f.mins, f.maxs) then continue end
			net.Start "SplatoonSWEPs: DrawInk"
			net.WriteUInt(f.id, 20)
			net.WriteUInt(color, SplatoonSWEPs.COLOR_BITS)
			net.WriteVector(pos)
			net.WriteFloat(radius)
			net.WriteUInt(whitealpha, 8)
			net.WriteUInt(whiterotate, 8)
			net.Broadcast()
			
			f.InkCounter = f.InkCounter + 1
			local rectangle = {color = color}
			local pos2d = SplatoonSWEPs:To2D(pos, f.origin, f.angle)
			rectangle.mins = pos2d - sizevec
			rectangle.maxs = pos2d + sizevec
			-- AddInkRectangle(f, {rectangle}, f.InkCounter)
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
