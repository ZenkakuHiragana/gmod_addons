
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local inkdegrees = 45
local PaintQueue = {}
local SendQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")

local INK_SURFACE_DELTA_NORMAL = 1
local MAX_SIZE = 300
local MAX_COROUTINES_AT_ONCE = 10
local MAX_PROCESS_QUEUE_AT_ONCE = 1
local MAX_MESSAGE_SENT = 10
local MAX_POLYS_OVERWRITE_AT_ONCE = 10
local MAX_POLYSURFACE_AT_ONCE = 50
local MAX_OVERWRITE_AT_ONCE = 20
local MAX_NET_SEND_SIZE = 64 * 1024 - 3 - 20

local function GetPlaneProjection(pos, planeorigin, planenormal)
	return pos - planenormal * planenormal:Dot(pos - planeorigin)
end

--Returns shared line and the angle between two planes.
local function GetSharedLine(n1, n2, p1, p2)
	local normal_dot = n1:Dot(n2)
	if normal_dot > math.cos(math.rad(10)) then return end
	local d1, d2 = p1:Dot(n1), p2:Dot(n2)
	return n1:Cross(n2):GetNormalized(), ((d1 - d2 * normal_dot) * n1 + (d2 - d1 * normal_dot) * n2) / (1 - normal_dot^2), math.acos(normal_dot)
end

--Rotates the given vector around specified normalized axis.
local function RotateAroundAxis(source, axis, rotation)
	local rotation = rotation / 2
	local sin, cos = math.sin(rotation), math.cos(rotation)
	local sinaxis = sin * axis
	local cossource_sourcesinaxis = cos * source + source:Cross(sinaxis)
	return source:Dot(sinaxis) * sinaxis + cos * cossource_sourcesinaxis + cossource_sourcesinaxis:Cross(sinaxis)
end

local function ToLocal(worldpos, localorg, localang, rotateorg, rotateaxis, rotateang)
	return WorldToLocal((rotateang and rotateang > math.rad(10)) and (RotateAroundAxis(worldpos - rotateorg, rotateaxis, rotateang) + rotateorg) or worldpos, angle_zero, localorg, localang)
end

local function ToWorld(localpos, localorg, localang, rotateorg, rotateaxis, rotateang)
	local worldpos = LocalToWorld(localpos, angle_zero, localorg, localang)
	return (rotateang and rotateang > math.rad(10)) and (RotateAroundAxis(worldpos - rotateorg, rotateaxis, -rotateang) + rotateorg) or worldpos
end

local function BuildMeshVertex(worldpos, localpos)
	return {
		pos = worldpos,
		u = (localpos.y + MAX_SIZE / 2) / MAX_SIZE,
		v = (localpos.z + MAX_SIZE / 2) / MAX_SIZE,
	}
end

local function GetMeshTriangle(polygons, localorg, localang, rotateorg, rotateaxis, rotateang, planenormal)
	local result, vertex = {}, vector_origin
	for _, triangles in ipairs(polygons) do
		for _, tri in ipairs(triangles) do
			if #tri < 3 then continue end
			for i = 1, 3 do
				table.insert(result, BuildMeshVertex(ToWorld(tri[i], localorg, localang, rotateorg, rotateaxis, rotateang) + planenormal * INK_SURFACE_DELTA_NORMAL, tri[i]))
			end
		end
	end
	return result
end

local function QueueCoroutine(pos, normal, radius, color, polys)
	local wholetime = CurTime()
	local ang = normal:Angle()
	local radiusSqr = radius^2
	local surf = {} --Surfaces that are affected by painting
	for s in pairs(SplatoonSWEPs:Check(pos)) do --This section searches surfaces in chunk
		if not (istable(s) and s.normal and s.vertices) then continue end
		local normal_cos = s.normal:Dot(normal) --Filter by normal vector
		if normal_cos > math.cos(math.rad(inkdegrees)) then
							for i, v in ipairs(s.vertices) do
								debugoverlay.Line(v, s.vertices[i % #s.vertices + 1], 5, Color(255, 255, 0), false)
								debugoverlay.Line(v, v + s.normal * 50, 5, Color(255, 255, 0), false)
								-- debugoverlay.Text(v, i, 5, Color(255, 255, 0), true)
							end
			local surface_distance = s.normal:Dot(pos - s.center) --Filter by surface distance
			if surface_distance^2 < radiusSqr * (1 - normal_cos^2) + 1 then
				for k = 1, #s.vertices do
					--Vertices is within InkRadius
					local v1, v2 = s.vertices[k], s.vertices[k % #s.vertices + 1]
					local rel1, rel2 = v1 - pos, v2 - pos
					local line = v2 - v1
					rel1, rel2 = rel1 + normal * normal:Dot(rel1), rel2 + normal * normal:Dot(rel2)
					-- if line:GetNormalized():Cross(rel1):Dot(normal) < radius then
						-- if (rel1:Dot(line) < 0 and rel2:Dot(line) > 0) or
							-- math.min(rel1:LengthSqr(), rel2:LengthSqr()) < radiusSqr then
							local surfadd = {
								normal = s.normal,
								center = s.center,
								id = s.id,
							}
							for i, v in ipairs(s.vertices) do
								table.insert(surfadd, v)
							end
							surf[surfadd] = true
							break
						-- end
					-- end
				end --for k
			end --if surface_distance^2
		end --if normal_cos
	end --for s in pairs
	
	local reference_polys, vertexlist, polygonregistered = {}, {}, 0 
	for i, v in ipairs(polys) do
		reference_polys[i] = v * radius
	end
	for drawable in pairs(surf) do --New ink = surface AND reference
		local surface_polys, intersection = {}, {Poly = {}, Tri = {}, Plane = {}}
		local shared_direction, shared_vector, normal_rad = GetSharedLine(normal, drawable.normal, pos, drawable.center)
		for i = 1, #drawable do
			surface_polys[i] = ToLocal(drawable[i], pos, ang, shared_vector, shared_direction, normal_rad)
			-- surface_polys[i].x = 0
		end
		
		intersection.Poly, intersection.Tri = SplatoonSWEPs.BuildOverlap(surface_polys, reference_polys, false)
		if table.Count(intersection.Poly) > 0 then
			intersection.Plane = {
				pos = drawable.center,
				normal = drawable.normal,
				shared_dir = shared_direction,
				shared_pos = shared_vector,
				normal_rad = normal_rad,
				id = drawable.id,
				color = color,
			}
			vertexlist[intersection] = true
		end
		
		polygonregistered = polygonregistered + 1
		if polygonregistered % MAX_POLYSURFACE_AT_ONCE == 0 then coroutine.yield() end
	end
	
	local dd = false
	local polysprocessed = 0
	--PolygonData.Poly -> Ink buffer, PolygonData.Tri -> MeshVertex structure
	local meshinfo, existVertices, existTriangles = {}, {}, {}
	for PolygonData in pairs(vertexlist) do --Polygon per plane
		local plane = PolygonData.Plane
		local inklist = InkGroup[plane.id]
		local inkid = CurTime()
		table.insert(meshinfo, {
			normal = plane.normal,
			color = plane.color,
			id = plane.id,
			inkid = inkid,
			triangles = GetMeshTriangle(PolygonData.Tri, pos, ang, plane.shared_pos, plane.shared_dir, plane.normal_rad, plane.normal),
		})
		for _, poly2D in ipairs(PolygonData.Poly) do
			if #poly2D < 3 then continue end
			InkGroup[plane.id] = {}
			if inklist then --Overwrite existing ink
				local overwrite_at_once = 0
				for times, exist in ipairs(inklist) do
					if pos:DistToSqr(exist.pos) > (radius + exist.radius)^2 then
						table.insert(InkGroup[plane.id], exist)
						continue
					end
					
					-- if not dd then
						-- for k, v in ipairs(exist.poly3D) do
							-- debugoverlay.Line(v.pos + exist.plane.normal * 3,
								-- exist.poly3D[k % #exist.poly3D + 1].pos + exist.plane.normal * 3, 2, Color(0, 255, 0), false)
							-- debugoverlay.Text(v.pos + exist.plane.normal * 3, "A" .. k, 2)
						-- end
					-- end
					
					local subtrahend = {}
					for i, v in ipairs(poly2D) do
						-- print(pos, exist.pos, ang, exist.ang)
						-- print("poly2D")PrintTable(poly2D)print()
						-- print("exist")PrintTable(exist)print()
						subtrahend[i] = ToWorld(v, pos, ang, plane.shared_pos, plane.shared_dir, plane.normal_rad)
						subtrahend[i] = ToLocal(subtrahend[i], exist.pos, exist.ang, exist.plane.shared_pos, exist.plane.shared_dir, exist.plane.normal_rad)
						-- subtrahend[i].x = 0
					end
					
					existVertices, existTriangles = SplatoonSWEPs.BuildOverlap(exist.poly2D, subtrahend, true) --Existing polygon -= New polygon
					table.insert(meshinfo, {
						normal = exist.plane.normal,
						color = exist.plane.color,
						id = exist.plane.id,
						inkid = exist.inkid,
						triangles = GetMeshTriangle(existTriangles, exist.pos, exist.ang, exist.plane.shared_pos, exist.plane.shared_dir, exist.plane.normal_rad, exist.plane.normal),
					})
					
					for _, existpoly2D in ipairs(existVertices) do
						if #existpoly2D > 0 and #existpoly2D < 3 then continue end
						local existpoly3D = {}
						for i, v in ipairs(existpoly2D) do
							table.insert(existpoly3D, BuildMeshVertex(ToWorld(v, exist.pos, exist.ang, exist.plane.shared_pos, exist.plane.shared_dir, exist.plane.normal_rad), v))
						end
						
						table.insert(InkGroup[plane.id], {
							poly2D = existpoly2D,
							poly3D = existpoly3D,
							pos = exist.pos,
							ang = exist.ang,
							radius = exist.radius,
							inkid = exist.inkid,
							plane = exist.plane,
							triangles = existmesh,
						})
						
						if not dd then
							for k, v in ipairs(existpoly3D) do
								debugoverlay.Line(v.pos + exist.plane.normal * 1,
									existpoly3D[k % #existpoly3D + 1].pos + exist.plane.normal * 1, 2, color_white, true)
								debugoverlay.Text(v.pos + exist.plane.normal * 1, "C" .. k, 2)
							end
						end
					end
					
					overwrite_at_once = overwrite_at_once + 1
					if overwrite_at_once % MAX_OVERWRITE_AT_ONCE == 0 then coroutine.yield() end
				end
			end
			
			local poly3D = {}
			for i, v in ipairs(poly2D) do
				table.insert(poly3D, BuildMeshVertex(ToWorld(v, pos, ang, plane.shared_pos, plane.shared_dir, plane.normal_rad), v))
			end
			if not dd then
				for k, v in ipairs(poly3D) do
					debugoverlay.Line(v.pos + normal * 2, poly3D[k % #poly3D + 1].pos + normal * 2, 2, Color(255, 255, 0), false)
					debugoverlay.Text(v.pos + normal * 2, "B" .. k, 2)
				end
			end
			-- dd = true
			
			table.insert(InkGroup[plane.id], {
				poly2D = poly2D,
				poly3D = poly3D,
				pos = pos,
				ang = ang,
				radius = radius,
				inkid = inkid,
				plane = plane,
				triangles = newtriangles,
			})
			
			polysprocessed = polysprocessed + 1
			if polysprocessed % MAX_POLYS_OVERWRITE_AT_ONCE == 0 then coroutine.yield() end
		end
	end
	
	local refreshedid = {}
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
		net.WriteColor(Color(v.color.x, v.color.y, v.color.z))
		net.WriteInt(v.id, 32)
		net.WriteDouble(v.inkid)
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
end

include "splatoon_geometry.lua"
