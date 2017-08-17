
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local inkdegrees = 45
local PaintQueue = {}
local SendQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")

local INK_SURFACE_DELTA_NORMAL = 1
local MAX_COROUTINES_AT_ONCE = 10
local MAX_PROCESS_QUEUE_AT_ONCE = 5
local MAX_MESSAGE_SENT = 10
local MAX_POLYS_OVERWRITE_AT_ONCE = 10
local MAX_OVERWRITE_AT_ONCE = 20
local MAX_NET_SEND_SIZE = 64 * 1024 - 3 - 20

local function QueueCoroutine(pos, normal, radius, color, polys)
	local wholetime = CurTime()
	local ang = normal:Angle()
	local d1 = pos:Dot(normal)
	local radiusSqr = radius^2
	local surf = {} --Surfaces that are affected by painting
	for s in pairs(SplatoonSWEPs.Check(pos)) do --This section searches surfaces in chunk
		if not (istable(s) and s.normal and s.vertices) then continue end
		local normal_cos = s.normal:Dot(normal) --Filter by normal vector
		if normal_cos > math.cos(math.rad(inkdegrees)) then
			local surface_distance = s.normal:Dot(pos - s.center) --Filter by surface distance
			if surface_distance^2 < radiusSqr * (1.21 - normal_cos^2) then
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
							-- for i, v in ipairs(s.vertices) do
								-- debugoverlay.Line(v, s.vertices[i % #s.vertices + 1], 5, Color(255, 255, 0), true)
								-- debugoverlay.Text(v, i, 5, Color(255, 255, 0), true)
							-- end
							surf[surfadd] = true
							break
						-- end
					-- end
				end --for k
			end --if surface_distance^2
		end --if normal_cos
	end --for s in pairs
	
	local reference_polys, vertexlist = {}, {} --Vertices for polygon that we attempt to draw
	for i, v in ipairs(polys) do
		reference_polys[i] = v * radius
	end
	for drawable in pairs(surf) do --New ink = surface AND reference
		local surface_polys, intersection = {}, {Poly = {}, Tri = {}, Plane = {}}
		local surface_pos = drawable.center + drawable.normal * INK_SURFACE_DELTA_NORMAL
		local d2 = surface_pos:Dot(drawable.normal)
		for i = 1, #drawable do
			surface_polys[i] = drawable[i] + drawable.normal * INK_SURFACE_DELTA_NORMAL
			local normal_dot = drawable.normal:Dot(normal)
			if normal_dot < math.cos(math.rad(10)) then
				local shared_direction = (drawable.normal):Cross(normal):GetNormalized()
				local rot = -math.acos(normal_dot) / 2
				local shared_vector = ((d1 - d2 * normal_dot) * normal + (d2 - d1 * normal_dot) * drawable.normal) / (1 - normal_dot^2)
				local qs = {0, surface_polys[i] - shared_vector}
				local q1 = {math.cos(rot), -math.sin(rot) * shared_direction}
				local q2 = {math.cos(rot), math.sin(rot) * shared_direction}
				local q1qs = {
					q1[1] * qs[1] - q1[2]:Dot(qs[2]),
					q1[1] * qs[2] + qs[1] * q1[2] + q1[2]:Cross(qs[2])
				}
				local q1qsq2 = {
					q1qs[1] * q2[1] - q1qs[2]:Dot(q2[2]),
					q1qs[1] * q2[2] + q2[1] * q1qs[2] + q1qs[2]:Cross(q2[2])
				}
				surface_polys[i] = q1qsq2[2] + shared_vector
			end
			surface_polys[i] = WorldToLocal(surface_polys[i], angle_zero, pos, ang)
			surface_polys[i].x = 0
		end
		
		intersection.Poly, intersection.Tri = SplatoonSWEPs.BuildOverlap(surface_polys, reference_polys, false)
		if table.Count(intersection.Poly) > 0 then
			intersection.Plane = {
				pos = surface_pos,
				normal = drawable.normal,
				id = drawable.id,
				color = color,
			}
			vertexlist[intersection] = true
		end
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
			triangles = SplatoonSWEPs.GetMeshTriangle(PolygonData.Tri, pos, ang, plane.pos, plane.normal),
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
						subtrahend[i] = LocalToWorld(v, angle_zero, pos, ang)
						subtrahend[i] = WorldToLocal(subtrahend[i], angle_zero, exist.pos, exist.ang)
						subtrahend[i].x = 0
					end
					
					existVertices, existTriangles = SplatoonSWEPs.BuildOverlap(exist.poly2D, subtrahend, true) --Existing polygon -= New polygon
					table.insert(meshinfo, {
						normal = exist.plane.normal,
						color = exist.plane.color,
						id = exist.plane.id,
						inkid = exist.inkid,
						triangles = SplatoonSWEPs.GetMeshTriangle(existTriangles, exist.pos, exist.ang, exist.plane.pos, exist.plane.normal),
					})
					
					for _, existpoly2D in ipairs(existVertices) do
						if #existpoly2D > 0 and #existpoly2D < 3 then continue end
						local existpoly3D = {}
						for i, v in ipairs(existpoly2D) do
							table.insert(existpoly3D, SplatoonSWEPs.BuildMeshVertex(v, exist.pos, exist.ang, exist.plane.pos, exist.plane.normal))
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
				table.insert(poly3D, SplatoonSWEPs.BuildMeshVertex(v, pos, ang, plane.pos, plane.normal))
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
		net.Start("SplatoonSWEPs: Broadcast ink vertices", true)
		for k, vertex in ipairs(v.triangles) do
			net.WriteVector(vertex.pos)
			net.WriteFloat(vertex.u)
			net.WriteFloat(vertex.v)
			if net.BytesWritten() - 3 >= MAX_NET_SEND_SIZE then
				net.Broadcast()
				net.Start("SplatoonSWEPs: Broadcast ink vertices", true)
			end
		end
		net.Broadcast()
		
		net.Start("SplatoonSWEPs: Finalize ink refreshment", true)
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
