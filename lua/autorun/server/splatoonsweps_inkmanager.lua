
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")
local PaintQueue = {}
local SendQueue = {}
local InkGroup = {}
function ClearInk()
	PaintQueue = {}
	InkGroup = {}
	InkIDCounter = -1
end

require "SZL"
SZL.namespace "SZL"
include "includes/modules/polybool.lua"

local InkIDCounter = InkIDCounter or -1
local function AddMeshID()
	InkIDCounter = InkIDCounter + 1
	return InkIDCounter
end

local INK_SURFACE_DELTA_NORMAL = 0.5 --Distance between map surface and ink mesh
local MAX_SIZE = 200 --Maximum radius of ink.  If radius is greater than this, texture glitches will happen.
local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local SIN_MAX_DEG_DIFF = math.sin(math.rad(MAX_DEGREES_DIFFERENCE))
local MAX_PROCESS_QUEUE_AT_ONCE = 1 --Running QueueCoroutine() at once
local MAX_MESSAGE_SENT = 100
local MAX_ADD_INK_AT_ONCE = 10
local MAX_OVERWRITE_AT_ONCE = 20
local MAX_POLYS_OVERWRITE_AT_ONCE = 10
local MAX_NET_SEND_SIZE = 64 * 1024 - 3 - 20 --Maximum size of sending data in net library
local MAX_COROUTINES_AT_ONCE = 10 --Maximum amount of coroutines that run at once

local IsCCW = SplatoonSWEPs.IsCCW
local GetPlaneProjection = SplatoonSWEPs.GetPlaneProjection
local GetSharedLine = SplatoonSWEPs.GetSharedLine
local RotateAroundAxis = SplatoonSWEPs.RotateAroundAxis
local BuildOverlap = SplatoonSWEPs.BuildOverlap
local Faces
local function ToLocal(pos, localorg, localang, planepos, planenormal, direction)
	return Vector3DTo2D(WorldToLocal(GetPlaneProjection(pos, planepos, planenormal, direction), angle_zero, localorg, localang), nil)
end

local function ToWorld(pos, localorg, localang, planepos, planenormal)
	pos = Vector2DTo3D(pos)
	return GetPlaneProjection(LocalToWorld(pos, angle_zero, localorg, localang), planepos, planenormal, planenormal)
end

local function BuildMeshVertex(worldpos, localpos)
	localpos = Vector2DTo3D(localpos)
	return {
		pos = worldpos,
		u = (localpos.x + MAX_SIZE / 2) / MAX_SIZE,
		v = (localpos.y + MAX_SIZE / 2) / MAX_SIZE,
	}
end

local function AddInkData(poly3D, pos, ang, normal, radius, inkid, planeid, color, center)
	table.insert(InkGroup[planeid], {
		poly3D = poly3D,
		pos = pos,
		ang = ang,
		normal = normal,
		radius = radius,
		inkid = inkid,
		color = color,
		center = center,
	})
end

local function QueueCoroutine(pos, normal, radius, color, polys)
	local wholetime = CurTime()
	local delta = 1
	local ang, radiusSqr = normal:Angle(), (radius * delta)^2
	local surf, reference_polys, vertexlist, meshinfo = {}, {}, {}, {}
	local polygonregistered, polysprocessed, message_sent = 0, 0, 0
	local refmin, refmax = Vector(math.huge, math.huge, math.huge), -Vector(math.huge, math.huge, math.huge)
	Faces = Faces or SplatoonSWEPs.BSP:GetLump(SplatoonSWEPs.LUMP.FACES)
	for i, v in ipairs(polys) do --Scaling
		reference_polys[i] = ToWorld(v * radius, pos, ang, pos, normal)
	end
	
	local loop = 0
	local mins, maxs = pos - Vector(radius, radius, radius), pos + Vector(radius, radius, radius)
	local function process(f)
		local fmin, fmax = f.mins, f.maxs
		if f.DispInfoTable then fmin, fmax = f.DispInfoTable.mins, f.DispInfoTable.maxs end
		if  mins.x > fmax.x or maxs.x < fmin.x or
			mins.y > fmax.y or maxs.y < fmin.y or
			mins.z > fmax.z or maxs.z < fmin.z then
			return
		end
		
		f.InkBuffer = f.InkBuffer or {}
		-- DebugLine(f.Vertices[0], pos)
		local reference_region = {}
		for i, v in ipairs(reference_polys) do --Change origin
			reference_region[i] = ToLocal(v, f.Vertices[0], f.normal:Angle(), f.Vertices[0], f.normal, normal)
		end
		
		local tri3D = {}
		local inkid = AddMeshID()
		local AND = f.Polygon * Polygon("REF", reference_region)
		for k, t in ipairs(AND.triangles) do
			for _, v in ipairs(t) do
				local vertex = BuildMeshVertex(ToWorld(v, f.Vertices[0], f.normal:Angle(), f.Vertices[0], f.normal), v)
				vertex.pos = vertex.pos + f.normal * INK_SURFACE_DELTA_NORMAL
				table.insert(tri3D, vertex)
			end
		end
		
		if loop == 1 then
		-- DebugLine(f.Vertices[0], f.Vertices[0] + f.normal * 100)
		-- for i = 0, 2 do
			-- DebugLine(f.Vertices[i], f.Vertices[(i + 1) % (#f.Vertices + 1)], true)
		-- end
		-- for i, v in ipairs(reference_region) do
			-- DebugLine(Vector2DTo3D(v), Vector2DTo3D(reference_region[i % #reference_region + 1]), true)
		-- end
		-- for i, v in ipairs(f.Polygon[1]) do
			-- DebugLine(Vector2DTo3D(v), Vector2DTo3D(f.Polygon[1][i % #f.Polygon[1] + 1]), true)
		-- end
		-- for i, v in ipairs(AND[1] or {}) do
			-- DebugLine(Vector2DTo3D(v), Vector2DTo3D(AND[1][i % #AND[1] + 1]), true)
		-- end
		-- for i, v in ipairs(tri3D) do
			-- DebugLine(v.pos, tri3D[i % #tri3D + 1].pos, true)
		-- end
		end
		table.insert(meshinfo, {
			normal = f.normal,
			color = color,
			id = f.index,
			inkid = inkid,
			triangles = tri3D,
		})
		
		for id, poly in ipairs(f.InkBuffer) do
			f.InkBuffer[id] = poly - AND
			tri3D = {}
			for k, t in ipairs(f.InkBuffer[id].triangles) do
				for _, v in ipairs(t) do
					local vertex = BuildMeshVertex(ToWorld(v, pos, ang, f.Vertices[0], f.normal), v)
					vertex.pos = vertex.pos + f.normal * INK_SURFACE_DELTA_NORMAL
					table.insert(tri3D, vertex)
				end
			end
			table.insert(meshinfo, {
				normal = f.normal,
				color = color,
				id = f.index,
				inkid = inkid,
				triangles = tri3D,
			})
		end
		
		-- table.insert(f.InkBuffer, AND)
		loop = loop + 1
		assert(loop < 10000)
	end
	
	for i, f in ipairs(Faces.data) do
		if f.normal:Dot(normal) > COS_MAX_DEG_DIFF then
			if f.DispInfoTable then
				for i, t in ipairs(f.DispInfoTable.Triangles) do
					process(t)
				end
			else
				process(f)
			end
		end
	end
	
	for i, v in ipairs(meshinfo) do
		local numvertices = #v.triangles
		if numvertices > 0 and numvertices < 3 then continue end
		net.Start("SplatoonSWEPs: Broadcast ink vertices", false)
		for k, vertex in ipairs(v.triangles) do
			net.WriteVector(vertex.pos)
			net.WriteFloat(vertex.u)
			net.WriteFloat(vertex.v)
			if net.BytesWritten() - 3 >= MAX_NET_SEND_SIZE then
				net.Broadcast()
				net.Start("SplatoonSWEPs: Broadcast ink vertices", false)
			end
		end
		net.Broadcast()
		
		net.Start("SplatoonSWEPs: Finalize ink refreshment", false)
		net.WriteVector(v.normal)
		net.WriteUInt(v.color - 1, SplatoonSWEPs.COLOR_BITS)
		net.WriteUInt(v.id, 32)
		net.WriteInt(v.inkid, 32)
		net.Broadcast()
		
		message_sent = message_sent + 1
		if message_sent % MAX_MESSAGE_SENT == 0 then coroutine.yield() end
	end
	
	-- print("wholetime: ", CurTime() - wholetime)
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
