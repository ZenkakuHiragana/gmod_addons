
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")
local PaintQueue = {}
local SendQueue = {}
local InkGroup = {}
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
local MAX_MESSAGE_SENT = 10
local MAX_POLYS_OVERWRITE_AT_ONCE = 10
local MAX_ADD_INK_AT_ONCE = 50
local MAX_OVERWRITE_AT_ONCE = 20
local MAX_NET_SEND_SIZE = 64 * 1024 - 3 - 20 --Maximum size of sending data in net library
local MAX_COROUTINES_AT_ONCE = 10 --Maximum amount of coroutines that run at once

local IsCCW = SplatoonSWEPs.IsCCW
local GetPlaneProjection = SplatoonSWEPs.GetPlaneProjection
local GetSharedLine = SplatoonSWEPs.GetSharedLine
local RotateAroundAxis = SplatoonSWEPs.RotateAroundAxis
local BuildOverlap = SplatoonSWEPs.BuildOverlap
local function ToLocal(pos, localorg, localang, planepos, planenormal)
	return WorldToLocal(GetPlaneProjection(pos, planepos, planenormal), angle_zero, localorg, localang)
end

local function ToWorld(pos, localorg, localang, planepos, planenormal)
	return GetPlaneProjection(LocalToWorld(pos, angle_zero, localorg, localang), planepos, planenormal)
end

local function BuildMeshVertex(pos, localorg, localang, planepos, planenormal)
	return {
		pos = ToWorld(pos, localorg, localang, planepos, planenormal),
		u = (pos.y + MAX_SIZE / 2) / MAX_SIZE,
		v = (pos.z + MAX_SIZE / 2) / MAX_SIZE,
	}
end

local function GetMeshTriangle(polygons, localorg, localang, planepos, planenormal)
	local result, vertex = {}, vector_origin
	for _, triangles in ipairs(polygons) do
		for _, tri in ipairs(triangles) do
			if #tri < 3 then continue end
			for i = 1, 3 do
				local vertex = BuildMeshVertex(tri[i], localorg, localang, planepos, planenormal)
				vertex.pos = vertex.pos + planenormal * INK_SURFACE_DELTA_NORMAL
				table.insert(result, vertex)
			end
		end
	end
	return result
end

local function Convert3Dto2D(poly3D, localorg, localang, planepos, planenormal)
	local result = {} --3D coordinate -> Y-Z coordinate
	for i, v in ipairs(poly3D) do
		result[i] = ToLocal(istable(v) and v.pos or v, localorg, localang, planepos, planenormal)
		result[i].x = 0
	end
	return result
end

local function Convert2Dto3D(poly2D, localorg, localang, planepos, planenormal)
	local result = {} --Y-Z coordinate -> 3D coordinate
	for i, v in ipairs(poly2D) do
		table.insert(result, BuildMeshVertex(v, localorg, localang, planepos, planenormal))
	end
	return result
end

local function BuildMeshInfo(plane, inkid, triangles, pos, ang)
	return {
		normal = plane.normal,
		color = plane.color,
		id = plane.id,
		inkid = inkid,
		triangles = GetMeshTriangle(triangles, pos, ang, plane.pos, plane.normal),
	}
end

local function AddInkData(poly2D, poly3D, pos, ang, radius, inkid, plane)
	table.insert(InkGroup[plane.id], {
		poly2D = poly2D,
		poly3D = poly3D,
		pos = pos,
		ang = ang,
		radius = radius,
		inkid = inkid,
		plane = plane,
	})
end

local function QueueCoroutine(pos, normal, radius, color, polys)
	local wholetime = CurTime()
	local ang, radiusSqr = normal:Angle(), radius^2
	local surf, reference_polys, vertexlist, meshinfo = {}, {}, {}, {}
	local polygonregistered, polysprocessed, message_sent = 0, 0, 0
	for i, v in ipairs(polys) do --Scaling
		reference_polys[i] = v * radius
	end
	
	for s in pairs(SplatoonSWEPs:Check(pos)) do --Seaching surfaces used by painting
		local normal_cos = s.normal:Dot(normal)
		if normal_cos >= COS_MAX_DEG_DIFF then --Filter out perpendicular surfaces
			local surface_distance = s.normal:Dot(pos - s.center)
			if surface_distance^2 < radiusSqr * (1 - normal_cos^2) + 1 then --Filter out "far" surfaces
				local isin, s_ang = true, s.normal:Angle()
				local vpos = ToLocal(pos, s.center, s_ang, s.center, s.normal)
				for i, vert in ipairs(s.vertices) do --Checking intersection
					if not isin then break end
					local v1 = WorldToLocal(vert, angle_zero, s.center, s_ang)
					local v2 = WorldToLocal(s.vertices[i % #s.vertices + 1], angle_zero, s.center, s_ang)
					if not IsCCW(v1, v2, vpos) then
						isin = isin and math.abs((v2 - v1):GetNormalized():Cross(vpos - v1).x) <= radius
					end
				end
				
				if isin then --If current surface is in range of painting
					local surfadd = {normal = s.normal, center = s.center, id = s.id}
					for i, v in ipairs(s.vertices) do
						table.insert(surfadd, v)
					end
					surf[surfadd] = true
				end
			end
		end --if normal_cos
	end --for s
	
	for drawable in pairs(surf) do --New ink = surface AND reference
		local intersection = {Poly = {}, Tri = {}, Plane = {}}
		local surface_polys = Convert3Dto2D(drawable, pos, ang, pos, normal)
		intersection.Poly, intersection.Tri = BuildOverlap(surface_polys, reference_polys, false)
		if table.Count(intersection.Poly) > 0 then
			intersection.Plane = {
				pos = drawable.center,
				normal = drawable.normal,
				id = drawable.id,
				color = color,
			}
			vertexlist[intersection] = true
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
		table.insert(meshinfo, BuildMeshInfo(plane, inkid, PolygonData.Tri, pos, ang))
		
		for _, poly2D in ipairs(PolygonData.Poly) do
			if #poly2D < 3 then continue end
			local poly3D = Convert2Dto3D(poly2D, pos, ang, plane.pos, plane.normal)
			InkGroup[plane.id] = {}
			
			if inklist then --Overwrite existing ink
				local overwrite_at_once = 0
				for times, exist in ipairs(inklist) do
					if pos:DistToSqr(exist.pos) > (radius + exist.radius)^2 then
						table.insert(InkGroup[plane.id], exist)
						continue
					end
					
					--Existing polygon -= New polygon
					local minuend = Convert3Dto2D(exist.poly3D, exist.pos, exist.ang, exist.plane.pos, exist.plane.normal)
					local subtrahend = Convert3Dto2D(poly3D, exist.pos, exist.ang, exist.plane.pos, exist.plane.normal)
					local existVertices, existTriangles = BuildOverlap(minuend, subtrahend, true)
					table.insert(meshinfo, BuildMeshInfo(exist.plane, exist.inkid, existTriangles, exist.pos, exist.ang))
					for _, exist2D in ipairs(existVertices) do
						if #exist2D < 3 then continue end
						local exist3D = Convert2Dto3D(exist2D, exist.pos, exist.ang, exist.plane.pos, exist.plane.normal)
						AddInkData(exist2D, exist3D, exist.pos, exist.ang, exist.radius, exist.inkid, exist.plane)
					end
					
					overwrite_at_once = overwrite_at_once + 1
					if overwrite_at_once % MAX_OVERWRITE_AT_ONCE == 0 then coroutine.yield() end
				end
			end
			
			AddInkData(poly2D, poly3D, pos, ang, radius, inkid, plane)
			polysprocessed = polysprocessed + 1
			if polysprocessed % MAX_POLYS_OVERWRITE_AT_ONCE == 0 then coroutine.yield() end
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

function ClearInk()
	PaintQueue = {}
	InkGroup = {}
	InkIDCounter = -1
end
