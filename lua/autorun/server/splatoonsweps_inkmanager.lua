
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local PaintQueue = {}
local InkGroup = {}

local InkIDCounter = InkIDCounter or -1
local function AddMeshID()
	InkIDCounter = InkIDCounter + 1
	return InkIDCounter
end

local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local MAX_PROCESS_QUEUE_AT_ONCE = 1 --Running QueueCoroutine() at once
local MAX_COROUTINES_AT_ONCE = 1 --Maximum amount of coroutines running at once
local MAX_INK_QUEUE_AT_ONCE = 18000
local MIN_BOUND = 10 --Ink minimum bounding box scale

local function QueueCoroutine(pos, normal, radius, color, polys)
	local ang = normal:Angle()
	local reference_polys = {}
	for i, v in ipairs(polys) do --Scaling
		reference_polys[i] = SplatoonSWEPs:To3D(v * radius, pos, ang)
	end
	
	local inkqueue = 0
	local mins, maxs = SplatoonSWEPs:GetBoundingBox(MIN_BOUND, reference_polys)
	for i, face_array in pairs(SplatoonSWEPs.Surfaces) do
		if not istable(face_array) or face_array.normal:Dot(normal) < COS_MAX_DEG_DIFF then continue end
		if inkqueue > radius / 4 then break end
		for k, f in ipairs(face_array) do
			if not SplatoonSWEPs:CollisionAABB(mins, maxs, f.mins, f.maxs) then continue end
			if inkqueue > radius / 4 then break end
			inkqueue = inkqueue + 1
			net.Start "SplatoonSWEPs: DrawInk"
			net.WriteString(tostring(i))
			net.WriteUInt(k, 16)
			net.WriteUInt(color, SplatoonSWEPs.COLOR_BITS)
			net.WriteVector(pos)
			net.WriteFloat(radius)
			net.Broadcast()
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
				coroutine.yield()
			elseif not ok then
				print("coroutine end: ", message)
				print(debug.traceback(v.co))
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
			--Give a silent warning to developers if Think(n) has returned
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

			done = done + 1
			if done % MAX_COROUTINES_AT_ONCE == 0 then coroutine.yield() end
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
