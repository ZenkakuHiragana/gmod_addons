
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
	for i, v in ipairs(polys[1]) do --Scaling
		reference_polys[i] = v * radius
	end
	reference_polys = Polygon("REF", reference_polys)
	
	for s in pairs(SplatoonSWEPs:Check(pos)) do --Seaching surfaces used by painting
		local normal_cos = s.normal:Dot(normal)
		if normal_cos >= COS_MAX_DEG_DIFF then --Filter out perpendicular surfaces
			if math.abs(s.normal:Dot(pos - s.center)) < radius * SIN_MAX_DEG_DIFF then --Filter out "far" surfaces
				local isin, touch, s_ang = true, false, s.normal:Angle()
				local vpos = WorldToLocal(GetPlaneProjection(pos, s.center, s.normal, s.normal), angle_zero, s.center, s_ang)
				for i, v in ipairs(s.vertices) do --Checking intersection
					if touch then break end
					local v1 = WorldToLocal(v, angle_zero, s.center, s_ang) v1.x = 0
					local v2 = WorldToLocal(s.vertices[i % #s.vertices + 1], angle_zero, s.center, s_ang) v2.x = 0
					if not IsCCW(v1, v2, vpos) then
						isin = false
						touch = touch or math.abs((v2 - v1):GetNormalized():Cross(vpos - v1).x) <= radius * delta and
										((v2 - v1):Dot(vpos - v1) * (v2 - v1):Dot(vpos - v2) < 0 or
										math.min(vpos:DistToSqr(v1), vpos:DistToSqr(v2)) <= radiusSqr)
					end
				end
				
				if isin or touch then --If current surface is in range of painting
					local surfadd = {normal = s.normal, center = s.center, id = s.id}
					for i, v in ipairs(s.vertices) do
						table.insert(surfadd, v)
					end
					for i, v in ipairs(s.vertices) do
						DebugLine(v, s.vertices[i % #s.vertices + 1], true)
					end
					surf[surfadd] = true
				end
			end
		end --if normal_cos
	end --for s
	
	coroutine.yield(true)
	do return end
	for drawable in pairs(surf) do --New ink = surface AND reference
		local surface_polys, intersection = {}, {} --3D coordinate -> Y-Z coordinate
		for i, v in ipairs(drawable) do
			surface_polys[i] = ToLocal(v, pos, ang, pos, normal, drawable.normal)
		end
		
		surface_polys = Polygon("SURF", surface_polys) * reference_polys
		if #surface_polys > 0 then
			surface_polys.Plane = {
				pos = drawable.center,
				normal = drawable.normal,
				ang = drawable.normal:Angle(),
				id = drawable.id,
				color = color,
			}
			vertexlist[surface_polys] = true
		end
		
		polygonregistered = polygonregistered + 1
		if polygonregistered % MAX_ADD_INK_AT_ONCE == 0 then coroutine.yield() end
	end
	
	--PolygonData.Poly -> Ink buffer
	--PolygonData.Tri -> MeshVertex structure
	for PolygonData in pairs(vertexlist) do --Polygon per plane
		local plane = PolygonData.Plane
		local inklist = InkGroup[plane.id]
		local inkid = AddMeshID()
		local tri3D = {}
		InkGroup[plane.id] = {}
		for _, triangles in ipairs(PolygonData.triangles) do
			for _, tri in ipairs(triangles) do
				if #tri < 3 then continue end
				for _, v in ipairs(tri) do
					local vertex = BuildMeshVertex(ToWorld(v, pos, ang, plane.pos, plane.normal), v)
					vertex.pos = vertex.pos + plane.normal * INK_SURFACE_DELTA_NORMAL
					table.insert(tri3D, vertex)
				end
			end
		end
		table.insert(meshinfo, {
			normal = plane.normal,
			color = plane.color,
			id = plane.id,
			inkid = inkid,
			triangles = tri3D,
		})
		
--		if inklist then
--			local overwrite_at_once = 0
--			for _, exist in ipairs(inklist) do
--				if pos:DistToSqr(exist.pos) > (radius + exist.radius)^2 then
--					table.insert(InkGroup[plane.id], exist)
--					continue
--				end
--				--Existing polygon -= New polygon
--				local minuend, subtrahend = {}, {}
--				for i, v in ipairs(exist.poly3D) do
--					minuend[i] = Vector3DTo2D(WorldToLocal(v.pos, angle_zero, pos, ang))
--				end
				
--				exist = exist - PolygonData
--				local tri3D = {}
--				for _, triangles in ipairs(PolygonData.triangles) do
--					for _, tri in ipairs(triangles) do
--						if #tri < 3 then continue end
--						for _, v in ipairs(tri) do
--							local vertex = BuildMeshVertex(ToWorld(v, pos, ang, plane.pos, plane.normal), v)
--							vertex.pos = vertex.pos + plane.normal * INK_SURFACE_DELTA_NORMAL
--							table.insert(tri3D, vertex)
--						end
--					end
--				end
--				table.insert(meshinfo, {
--					normal = plane.normal,
--					color = exist.color,
--					id = plane.id,
--					inkid = exist.inkid,
--					triangles = tri3D,
--				})
				
--				for _, exist2D in ipairs(exist) do
--					if #exist2D < 3 then continue end
--					local exist3D = {}
--					for i, v in ipairs(exist2D) do
--						table.insert(exist3D, BuildMeshVertex(LocalToWorld(v, angle_zero, exist.center, plane.ang), v))
--					end
--					AddInkData(exist3D, exist.pos, exist.ang, exist.normal, exist.radius, exist.inkid, plane.id, exist.color, exist.center)
--				end
				
--				overwrite_at_once = overwrite_at_once + 1
--				if overwrite_at_once % MAX_OVERWRITE_AT_ONCE == 0 then coroutine.yield() end
--			end
--		end
		
		for _, poly2D in ipairs(PolygonData) do
			if #poly2D < 3 then continue end
			local poly3D, center = {}, Vector2D() --Y-Z coordinate -> 3D coordinate
			for i, v in ipairs(poly2D) do
				table.insert(poly3D, BuildMeshVertex(ToWorld(v, pos, ang, plane.pos, plane.normal), v))
				center = center + v
			end
			center = ToWorld(center / #poly2D, pos, ang, plane.pos, plane.normal)
			AddInkData(poly3D, pos, ang, normal, radius, inkid, plane.id, plane.color, center)
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
