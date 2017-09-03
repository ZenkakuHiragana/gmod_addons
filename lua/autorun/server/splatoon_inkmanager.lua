
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local PaintQueue = {}
local SendQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")

local INK_SURFACE_DELTA_NORMAL = 1 --Performance settings
local MAX_SIZE = 300
local MAX_DEGREES_DIFFERENCE = 45
local COS_MAX_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE))
local MAX_COROUTINES_AT_ONCE = 10
local MAX_PROCESS_QUEUE_AT_ONCE = 1
local MAX_MESSAGE_SENT = 10
local MAX_POLYS_OVERWRITE_AT_ONCE = 10
local MAX_POLYSURFACE_AT_ONCE = 50
local MAX_OVERWRITE_AT_ONCE = 20
local MAX_NET_SEND_SIZE = 64 * 1024 - 3 - 20

local IsCCW = SplatoonSWEPs.IsCCW
local GetPlaneProjection = SplatoonSWEPs.GetPlaneProjection
local GetSharedLine = SplatoonSWEPs.GetSharedLine
local RotateAroundAxis = SplatoonSWEPs.RotateAroundAxis
local function ToLocal(worldpos, localorg, localang, rotateorg, rotateaxis, rotateang)
	local wpos = not rotateang and worldpos or RotateAroundAxis(worldpos - rotateorg, rotateaxis, rotateang) + rotateorg
	local tolocalpos, tolocalang = WorldToLocal(wpos, angle_zero, localorg, localang)
	tolocalpos.x = 0
	return tolocalpos, tolocalang
end

local function ToWorld(localpos, localorg, localang, rotateorg, rotateaxis, rotateang)
	local worldpos = LocalToWorld(localpos, angle_zero, localorg, localang)
	return not rotateang and worldpos or RotateAroundAxis(worldpos - rotateorg, rotateaxis, -rotateang) + rotateorg
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
	local aa = false
	local wholetime = CurTime()
	local surf, ang, radiusSqr = {}, normal:Angle(), radius^2
	for s in pairs(SplatoonSWEPs:Check(pos)) do --This section searches surfaces in chunk
		local normal_cos = s.normal:Dot(normal) --Filter by normal vector
		if normal_cos > COS_MAX_DEG_DIFF then
			local surface_distance = s.normal:Dot(pos - s.center) --Filter by surface distance
			if surface_distance^2 < radiusSqr * (1 - normal_cos^2) + 1 then
				local isin, s_ang = true, s.normal:Angle()
				local vpos = WorldToLocal(GetPlaneProjection(pos, s.center, s.normal), angle_zero, s.center, s_ang)
				for i, vert in ipairs(s.vertices) do
					local v1 = WorldToLocal(vert, angle_zero, s.center, s_ang)
					local v2 = WorldToLocal(s.vertices[i % #s.vertices + 1], angle_zero, s.center, s_ang)
					if not IsCCW(v1, v2, vpos) then
						local relative, line = vpos - v1, v2 - v1
						isin = isin and math.abs(line:GetNormalized():Cross(relative).x) <= radius
					end
				end
				
				if isin then
					local surfadd = {normal = s.normal, center = s.center, id = s.id}
					for i, v in ipairs(s.vertices) do
						table.insert(surfadd, v)
					end
					surf[surfadd] = true
				end
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
		for i, v in ipairs(drawable) do
			surface_polys[i] = ToLocal(v, pos, ang, shared_vector, shared_direction, normal_rad)
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
		-- elseif not aa then
			-- for i, v in ipairs(drawable) do
				-- DebugLine(v, drawable[i % #drawable + 1])
				-- DebugVector(v, drawable.normal * 50)
				-- DebugText(v, i)
			-- end
			-- print(drawable.id)
			-- aa = true
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
								DebugLine(v.pos + exist.plane.normal * 1, existpoly3D[k % #existpoly3D + 1].pos + exist.plane.normal * 1, true)
								DebugText(v.pos + exist.plane.normal * 1, "C" .. k)
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
					DebugLine(v.pos + normal * 2, poly3D[k % #poly3D + 1].pos + normal * 2)
					DebugText(v.pos + normal * 2, "B" .. k)
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
