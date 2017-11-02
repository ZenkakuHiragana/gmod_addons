
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
local MAX_SIZE = 300 --Maximum radius of ink.  If radius is greater than this, texture glitches will happen.
local MAX_DEGREES_DIFFERENCE = 45 --Maximum angle difference between two surfaces
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) --Used by filtering process
local MAX_PROCESS_QUEUE_AT_ONCE = 1 --Running QueueCoroutine() at once
local MAX_MESSAGE_SENT = 10000
local MAX_OVERPAINT_AT_ONCE = 500
local MAX_PROCESS_FACE_AT_ONCE = 800
local MAX_NET_SEND_SIZE = 64 * 1024 - 3 - 20 --Maximum size of sending data in net library
local MAX_COROUTINES_AT_ONCE = 1 --Maximum amount of coroutines running at once
local MIN_BOUND = 10 --Ink minimum bounding box scale

local IsCCW = SplatoonSWEPs.IsCCW
local GetPlaneProjection = SplatoonSWEPs.GetPlaneProjection
local GetSharedLine = SplatoonSWEPs.GetSharedLine
local RotateAroundAxis = SplatoonSWEPs.RotateAroundAxis
local BuildOverlap = SplatoonSWEPs.BuildOverlap
local function ToLocal(pos, localorg, localang, planepos, planenormal, direction)
	return Vector3DTo2D(WorldToLocal(GetPlaneProjection(pos, planepos, planenormal, direction), angle_zero, localorg, localang), nil)
end

local function ToWorld(pos, localorg, localang, planepos, planenormal)
	pos = Vector2DTo3D(pos)
	return GetPlaneProjection(LocalToWorld(pos, angle_zero, localorg, localang), planepos, planenormal, planenormal)
end

local function BuildMeshVertex(worldpos, localpos)
	return {
		pos = worldpos,
		u = (localpos.y + MAX_SIZE / 2) / MAX_SIZE,
		v = (localpos.z + MAX_SIZE / 2) / MAX_SIZE,
	}
end

local function PolyBoundingBox(poly, org, ang)
	local vert = {}
	for _, r in ipairs(poly) do
		for i, v in ipairs(r) do
			v = Vector2DTo3D(v)
			vert[#vert + 1] = LocalToWorld(v, angle_zero, org, ang)
		end
	end
	poly.mins, poly.maxs = SplatoonSWEPs:GetBoundingBox(0, vert)
end

local function MakeTriangles(triangles, org, ang, normal)
	local tri3D = {}
	for _, t in ipairs(triangles) do
		for _, v in ipairs(t) do
			local vertex = BuildMeshVertex(LocalToWorld(Vector2DTo3D(v), angle_zero, org, ang),
				Vector2DTo3D(v - (t[1] + t[2] + t[3]) / 3))
			vertex.pos = vertex.pos + normal * INK_SURFACE_DELTA_NORMAL
			table.insert(tri3D, vertex)
		end
	end
	
	return tri3D
end

local function QueueCoroutine(pos, normal, radius, color, polys)
	local ang = normal:Angle()
	local polyprocess, reference_polys, meshinfo = 0, {}, {}
	for i, v in ipairs(polys) do --Scaling
		reference_polys[i] = LocalToWorld(Vector2DTo3D(v * radius), angle_zero, pos, ang)
	end
	
	local mins, maxs = SplatoonSWEPs:GetBoundingBox(MIN_BOUND, reference_polys)
	for k, f in pairs(SplatoonSWEPs.Surfaces) do
		if f.normal:Dot(normal) < COS_MAX_DEG_DIFF or
			mins.x > f.maxs.x or maxs.x < f.mins.x or
			mins.y > f.maxs.y or maxs.y < f.mins.y or
			mins.z > f.maxs.z or maxs.z < f.mins.z then
			continue
		end
		
		local inkid = AddMeshID()
		local reference = {}
		for i, v in ipairs(reference_polys) do --Change origin
			reference[i] = Vector3DTo2D(WorldToLocal(GetPlaneProjection(
				v, f.origin, f.normal, f.normal), angle_zero, f.origin, f.angle), nil)
		end
		DebugPoly(f.Polygon[1], true)
		DebugPoly(reference, true)
		
		local AND = Polygon(inkid, reference_region) * f.Polygon
		if not AND[1] or #AND[1] < 3 then continue end
		if not InkGroup[k] then InkGroup[k] = {} end
		PolyBoundingBox(AND, f.origin, f.angle) --AND.mins, AND.maxs
		
		local overpaint = 0
		for othercolor, poly in ipairs(InkGroup[k]) do
			if AND.mins.x > poly.maxs.x or AND.maxs.x < poly.mins.x or
				AND.mins.y > poly.maxs.y or AND.maxs.y < poly.mins.y or
				AND.mins.z > poly.maxs.z or AND.maxs.z < poly.mins.z then
				continue
			end
			
			local overpoly = poly - AND
			local overpolyTriangles = MakeTriangles(overpoly:triangulate(), f.origin, f.angle, f.normal)
			if #overpolyTriangles > 2 then
				overpoly.color = poly.color
				overpoly.inkid = poly.inkid
				PolyBoundingBox(overpoly, f.origin, f.angle)
			end
			
			table.insert(meshinfo, {
				normal = f.normal,
				color = poly.color,
				faceid = k,
				inkid = poly.inkid,
				triangles = overpolyTriangles,
			})
			
			overpaint = overpaint + 1
			if overpaint % MAX_OVERPAINT_AT_ONCE == 0 then coroutine.yield() end
		end
		
		if InkGroup[k][color] then
			local union = InkGroup[k][color]
			union.Polygon = union.Polygon + AND
			union.Polygon.color = color
			union.Polygon.inkid = InkGroup[k][color].inkid
			InkGroup[k][color].Polygon = union
			table.insert(meshinfo, {
				normal = f.normal,
				color = color,
				faceid = k,
				inkid = union.Polygon.inkid,
				triangles = MakeTriangles(union:triangulate(), f.origin, f.angle, f.normal),
			})
		else
			AND.color, AND.inkid = color, inkid
			table.insert(meshinfo, {
				normal = f.normal,
				color = color,
				faceid = k,
				inkid = inkid,
				triangles = MakeTriangles(AND:triangulate(), f.origin, f.angle, f.normal),
			})
		end
		
		polyprocess = polyprocess + 1
		if polyprocess % MAX_PROCESS_FACE_AT_ONCE == 0 then coroutine.yield() end
	end
	
	coroutine.yield()
	
	local message_sent = 0
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
		net.WriteUInt(v.faceid, 32)
		net.WriteInt(v.inkid, 32)
		net.Broadcast()
		
		message_sent = message_sent + 1
		if message_sent % MAX_MESSAGE_SENT == 0 then coroutine.yield() end
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