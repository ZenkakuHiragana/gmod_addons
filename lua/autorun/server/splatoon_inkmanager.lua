
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local inkdegrees = 45
local PaintQueue = {}
local SendQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")

local INK_SURFACE_DELTA_NORMAL = 0.5
local MAX_SIZE = 300
local MAX_PROCESS_QUEUE_AT_ONCE = 3
local MAX_MESSAGE_SENT = 20
local MAX_POLYS_OVERWRITE_AT_ONCE = 10
local MAX_OVERWRITE_AT_ONCE = 10
local MAX_NET_SEND_SIZE = 64 * 1024 - 3 - 20
local function GetMeshTriangle(triangles, orgpos, orgnormal, organg, planepos, planenormal, planedot, planecolor)
	local vertices, result = {}, {}
	for _, poly in ipairs(triangles) do
		for _, tri in ipairs(poly) do
			if #tri < 3 then continue end
			for i = 1, 3 do
				vertices[i] = LocalToWorld(tri[i], angle_zero, orgpos, organg)
				vertices[i] = vertices[i] - (planenormal:Dot(vertices[i] - planepos) / planedot) * orgnormal
				table.insert(result, {
					pos = vertices[i],
					u = (tri[i].y + MAX_SIZE / 2) / MAX_SIZE,
					v = (tri[i].z + MAX_SIZE / 2) / MAX_SIZE,
				--	color = Color(planecolor.x, planecolor.y, planecolor.z),
				})
			end
		end
	end
	return result
end

local function QueueCoroutine(pos, normal, ang, radius, color, polys)
	local wholetime = CurTime()
	local radiusSqr = radius^2
	local targetsurf = SplatoonSWEPs.Check(pos)
	local surf = {} --Surfaces that are affected by painting
	for s in pairs(targetsurf) do --This section searches surfaces in chunk.
		if not istable(s) then continue end
		if not (s.normal and s.vertices) then continue end
		--Surfaces that have almost same normal as the given data.
		local normal_cos = s.normal:Dot(normal)
		if normal_cos > math.cos(math.rad(inkdegrees)) then
			--Surface.Z is near HitPos
			local dot1 = s.normal:Dot(pos - s.center)
			-- debugoverlay.Text(s.center, dot1, 5, true)
			-- debugoverlay.Text(s.center + s.normal * 10, radius * (1.1 - normal_cos) + 0.5, 5, true)
			if math.abs(dot1) < radius * (1.1 - normal_cos) then
							for i, v in ipairs(s.vertices) do
								debugoverlay.Line(v, s.vertices[i % #s.vertices + 1], 5, Color(255, 255, 0), true)
								debugoverlay.Text(v, i, 5, Color(255, 255, 0), true)
							end
				for k = 1, #s.vertices do
					--Vertices is within InkRadius
					local v1 = s.vertices[k]
					local rel1 = v1 - pos
					local v2 = s.vertices[k % #s.vertices + 1]
					local rel2 = v2 - pos
					local line = v2 - v1 --now v1 and v2 are relative vector
					v1, v2 = rel1 + normal * normal:Dot(rel1), rel2 + normal * normal:Dot(rel2)
					if line:GetNormalized():Cross(v1):Dot(normal) < radius then
						if (v1:Dot(line) < 0 and v2:Dot(line) > 0) or
							math.min(v2:LengthSqr(), v1:LengthSqr()) < radiusSqr then
							local surfadd = {
								normal = s.normal,
								center = s.center,
								id = s.id,
							}
							for i, v in ipairs(s.vertices) do
								table.insert(surfadd, v)
								debugoverlay.Line(v, s.vertices[i % #s.vertices + 1], 5, Color(255, 255, 0), true)
								debugoverlay.Text(v, i, 5, Color(255, 255, 0), true)
							end
							surf[surfadd] = true
							break
						end
					end
				end --for k = 1, 3
			end --if dot1 > 0
		end --if s.normal:Dot
	end --for #SplatoonSWEPs.Surface
	
	for i, v in ipairs(polys) do
		polys[i] = v * radius
	end
	
	local vertexlist = {} --Vertices for polygon that we attempt to draw
	local planarsurf, intersection = {}, {Poly = {}, Tri = {}, Plane = {}}
	for drawable in pairs(surf) do
		for i = 1, #drawable do
			planarsurf[i] = WorldToLocal(drawable[i], angle_zero, pos, ang)
			planarsurf[i].x = 0
		end
		
		intersection.Poly, intersection.Tri = SplatoonSWEPs.BuildOverlap(planarsurf, polys, false)
		if table.Count(intersection.Poly) > 0 then
			intersection.Plane = {
				pos = drawable.center + drawable.normal * INK_SURFACE_DELTA_NORMAL,
				normal = drawable.normal,
				id = drawable.id,
				color = color,
			}
			vertexlist[intersection] = true
			intersection = {Poly = {}, Tri = {}, Plane = {}}
		end
	end
	
	local dd = false
	local polysprocessed = 0
	--PolygonData.Poly -> Ink buffer, PolygonData.Tri -> MeshVertex structure
	local meshinfo, existVertices, existTriangles = {}, {}, {}
	local planepos, planenormal, planecolor, planedot, planeid = vector_origin, vector_origin, color_white, 0, 0
	for PolygonData in pairs(vertexlist) do --Polygon per plane
		planepos, planenormal = PolygonData.Plane.pos, PolygonData.Plane.normal
		planecolor, planeid = PolygonData.Plane.color, PolygonData.Plane.id
		planedot = planenormal:Dot(normal)
		local inklist = InkGroup[planeid]
		local inkid = CurTime()
		table.insert(meshinfo, {
			pos = pos,
			normal = planenormal,
			color = planecolor,
			id = planeid,
			inkid = inkid,
			triangles = GetMeshTriangle(PolygonData.Tri, pos, normal, ang, planepos, planenormal, planedot, planecolor),
		})
		for _, poly2D in ipairs(PolygonData.Poly) do
			if #poly2D < 3 then continue end
			
			--Overwrite existing ink
			InkGroup[planeid] = {}
			if inklist then
				local overwrite_at_once = 0
				for times, exist in ipairs(inklist) do
					-- if pos:DistToSqr(exist.origin) > (radius + exist.radius)^2 then
						-- table.insert(InkGroup[planeid], exist)
						-- continue
					-- end
					
					if not dd then
						for k, v in ipairs(exist.poly3D) do
							debugoverlay.Line(v.pos + exist.normal * 50,
								exist.poly3D[k % #exist.poly3D + 1].pos + exist.normal * 50, 2, Color(0, 255, 0), false)
							debugoverlay.Text(v.pos + exist.normal * 50, "A" .. k, 2)
						end
					end
					
					local subtrahend = {}
					for i, v in ipairs(poly2D) do
						subtrahend[i] = LocalToWorld(v, angle_zero, pos, ang)
						subtrahend[i] = WorldToLocal(subtrahend[i], angle_zero, exist.origin, exist.angle)
						subtrahend[i].x = 0
					end
					
					existVertices, existTriangles = SplatoonSWEPs.BuildOverlap(exist.poly2D, subtrahend, true) --Existing polygon -= New polygon
					table.insert(meshinfo, {
						pos = exist.origin,
						normal = planenormal,
						color = exist.color,
						id = planeid,
						inkid = exist.inkid,
						triangles = GetMeshTriangle(existTriangles, exist.origin, exist.normal, exist.angle, planepos, planenormal, exist.planedot, exist.color),
					})
					
					for _, existpoly2D in ipairs(existVertices) do
						if #existpoly2D > 0 and #existpoly2D < 3 then continue end
						local existpoly3D = {}
						for i, v in ipairs(existpoly2D) do
							existpoly3D[i] = LocalToWorld(v, angle_zero, exist.origin, exist.angle)
							existpoly3D[i] = {
								pos = existpoly3D[i] - (planenormal:Dot(existpoly3D[i] - planepos) / planedot) * exist.normal,
								u = (v.y + MAX_SIZE / 2) / MAX_SIZE,
								v = (v.z + MAX_SIZE / 2) / MAX_SIZE,
							}
						end
						
						table.insert(InkGroup[planeid], {
							poly2D = existpoly2D,
							poly3D = existpoly3D,
							origin = exist.origin,
							normal = exist.normal,
							color = exist.color,
							inkid = exist.inkid,
							angle = exist.angle,
							radius = exist.radius,
							planedot = exist.planedot,
							triangles = existmesh,
						})
						
						if not dd then
							for k, v in ipairs(existpoly3D) do
								debugoverlay.Line(v.pos + exist.normal * 100,
									existpoly3D[k % #existpoly3D + 1].pos + exist.normal * 100, 2, Color(exist.color.x, exist.color.y, exist.color.z), false)
								debugoverlay.Text(v.pos + exist.normal * 100, "C" .. k, 2)
							end
						end
					end
					
					overwrite_at_once = overwrite_at_once + 1
					if overwrite_at_once % MAX_OVERWRITE_AT_ONCE == 0 then coroutine.yield() end
				end
			end
			local poly3D = {}
			for i, v in ipairs(poly2D) do
				poly3D[i] = LocalToWorld(v, angle_zero, pos, ang)
				poly3D[i] = {
					pos = poly3D[i] - (planenormal:Dot(poly3D[i] - planepos) / planedot) * normal,
					u = (v.y + MAX_SIZE / 2) / MAX_SIZE,
					v = (v.z + MAX_SIZE / 2) / MAX_SIZE,
				}
			end
			if not dd then
				for k, v in ipairs(poly3D) do
					debugoverlay.Line(v.pos + normal * 50, poly3D[k % #poly3D + 1].pos + normal * 50, 2, Color(255, 255, 0), false)
					debugoverlay.Text(v.pos + normal * 50, "B" .. k, 2)
				end
				-- dd = true
			end
			
			table.insert(InkGroup[planeid], {
				poly2D = poly2D,
				poly3D = poly3D,
				origin = pos,
				normal = normal,
				color = planecolor,
				inkid = inkid,
				angle = ang,
				radius = radius,
				planedot = planedot,
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
		net.WriteVector(v.pos)
		net.WriteVector(v.normal)
		net.WriteColor(Color(v.color.x, v.color.y, v.color.z))
		net.WriteInt(v.id, 32)
		net.WriteDouble(v.inkid)
		net.Broadcast()
		
		message_sent = message_sent + 1
		if message_sent % MAX_MESSAGE_SENT == 0 then coroutine.yield() end
	end
	
--	print("wholetime: ", CurTime() - wholetime)
	coroutine.yield(true)
end

local function ProcessQueue()
	local done = 0
	while true do
		local queue = table.Copy(PaintQueue)
		for i, v in ipairs(queue) do
			if coroutine.status(v.co) == "dead" then
				queue[i] = nil
				continue
			end
			
			local ok, message = coroutine.resume(
				v.co, v.pos, v.normal, v.ang, v.radius, v.color, v.polys)
			if not ok then print("coroutine end: ", message) end
			if ok and message then
				queue[i] = nil				
				coroutine.yield()
			elseif not ok then
				queue[i] = nil
			end
			
			done = done + 1
			if done > 20 then
				coroutine.yield()
				done = 0
			end
		end
		done = 0
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
				Msg(self, "\tSplatoonSWEPs Warning: Coroutine " .. i .. " has finished executing\n")
				threads[i] = nil
				continue
			end
			--Continue Think's execution
			local ok, message = coroutine.resume(co)
			if not ok then
				ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n")
			end
			
			done = done + 1
			if done > MAX_PROCESS_QUEUE_AT_ONCE then
				coroutine.yield()
				done = 0
			end
		end
		done = 0
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
	AddQueue = function(pos, normal, ang, radius, color, polys)
		table.insert(PaintQueue, {
			pos = pos,
			normal = normal,
			ang = ang,
			radius = radius,
			color = color,
			polys = polys,
			co = coroutine.create(QueueCoroutine),
		})
	end,
}
hook.Add("Tick", "SplatoonSWEPsDoInkCoroutines", SplatoonSWEPsInkManager.Think)

function ClearInk()
	PaintQueue = {}
	InkGroup = {}
end

include "splatoon_geometry.lua"
