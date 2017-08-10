
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local inkdegrees = 45
local PaintQueue = {}
local SendQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")
util.AddNetworkString("SplatoonSWEPs: Reset ink mesh by ID")

local INK_SURFACE_DELTA_NORMAL = 0.5
local MAX_SIZE = 300
local MAX_PROCESS_QUEUE_AT_TIME = 3
local MAX_MESSAGE_SEND = 20
local MAX_POLYS_OVERWRITE_AT_TIME = 10
local MAX_OVERWRITE_AT_TIME = 10
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
					color = Color(planecolor.x, planecolor.y, planecolor.z),
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
		if s.normal:Dot(normal) > math.cos(math.rad(inkdegrees)) then
			--Surface.Z is near HitPos
			local dot1 = s.normal:Dot(s.vertices[1] - pos)
			if math.abs(dot1) < radius * (1.1 - s.normal:Dot(normal)) then
				for k = 1, #s.vertices do
					--Vertices is within InkRadius
					local v1 = s.vertices[1]
					local rel1 = v1 - pos
					local v2 = s.vertices[k % #s.vertices + 1]
					local rel2 = v2 - pos
					local line = v2 - v1 --now v1 and v2 are relative vector
					v1, v2 = rel1 + normal * normal:Dot(rel1), rel2 + normal * normal:Dot(rel2)
					if line:GetNormalized():Cross(v1):Dot(normal) < radius then
						if (v1:Dot(line) < 0 and v2:Dot(line) > 0) or
							math.min(v2:LengthSqr(), v1:LengthSqr()) < radiusSqr then
							local surfadd = {
								normal = s.normal, center = s.center, id = s.id,
							}
							for i, v in ipairs(s.vertices) do
								table.insert(surfadd, v)
							--	if #s.vertices > 6 then
									debugoverlay.Line(v, s.vertices[i % #s.vertices + 1], 5, Color(255, 255, 0), true)
									debugoverlay.Text(v, i, 5, Color(255, 255, 0), true)
							--	end
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
	--PolygonData.Poly -> Ink buffer, PolygonData.Tri -> MeshVertex structure
	local meshvertex, meshinfo, existVertices, existTriangles = {}, {}, {}, {}
	local planepos, planenormal, planecolor, planedot, planeid
		= vector_origin, vector_origin, color_white, 0, 0
	local polysprocessed = 0
	for PolygonData in pairs(vertexlist) do
		planepos, planenormal = PolygonData.Plane.pos, PolygonData.Plane.normal
		planecolor, planeid = PolygonData.Plane.color, PolygonData.Plane.id
		planedot = planenormal:Dot(normal)
		local inklist = InkGroup[planeid]
		local inkid = CurTime()
		table.insert(meshvertex, planeid)
		-- table.insert(meshinfo, {pos = pos, normal = planenormal, color = planecolor, id = planeid})
		-- table.Add(meshvertex[#meshvertex], GetMeshTriangle(
			-- PolygonData.Tri, pos, normal, ang, planepos, planenormal, planedot, planecolor))
		for _, poly in ipairs(PolygonData.Poly) do
			if #poly < 3 then continue end
			poly.color = planecolor --build data structure
			poly.origin = pos
			poly.normal = normal
			poly.angle = ang
			poly.radius = radius
		--	poly.triangles = meshvertex[#meshvertex]
			
			--Overwrite existing ink
			InkGroup[planeid] = {}
			if inklist then
				local processed = 0
				for times, exist in ipairs(inklist) do
					processed = processed + 1
					if processed % MAX_OVERWRITE_AT_TIME == 0 then coroutine.yield() end
					
					if pos:DistToSqr(exist[1].origin) > (radius + exist[1].radius)^2 then
						table.insert(InkGroup[planeid], exist)
						-- table.insert(meshvertex, {})
						-- table.insert(meshinfo, {pos = exist.origin, normal = planenormal, color = exist.color, id = planeid})
						-- table.Add(meshvertex[#meshvertex], exist.triangles)
						continue
					end
					if not dd then
						for k, v in ipairs(exist[2]) do
							debugoverlay.Line(v.pos + exist[2].normal * 50, exist[2][k % #exist[2] + 1].pos + exist[2].normal * 50, 5, Color(0, 255, 0), false)
							debugoverlay.Text(v.pos + exist[2].normal * 50, "A" .. k, 5)
						end
					end
					exist = exist[1]
					local subtrahend = {}
					local existOrigin = WorldToLocal(pos, angle_zero, exist.origin, exist.angle)
					existOrigin.x = 0
					for i, v in ipairs(poly) do
						subtrahend[i] = v + existOrigin
					end
					
					existVertices, existTriangles = SplatoonSWEPs.BuildOverlap(exist, subtrahend, true)
					-- table.insert(meshvertex, {})
					-- table.insert(meshinfo, {pos = exist.origin, normal = planenormal, color = exist.color, id = planeid})
					-- table.Add(meshvertex[#meshvertex], GetMeshTriangle(
						-- existTriangles, exist.origin, normal, ang, planepos, planenormal, planedot, exist.color))
					
					for _, existpoly in ipairs(existVertices) do
						if #existpoly < 3 then continue end
						local existink = {}
						for i, v in ipairs(existpoly) do
							existink[i] = LocalToWorld(v, angle_zero, exist.origin, exist.angle)
							existink[i] = {
								pos = existink[i] - (planenormal:Dot(existink[i] - planepos) / planedot) * normal,
								u = (v.y + MAX_SIZE / 2) / MAX_SIZE,
								v = (v.z + MAX_SIZE / 2) / MAX_SIZE,
							}
						end
						existpoly.color = exist.color
						existpoly.origin = exist.origin
						existpoly.normal = exist.normal
						existpoly.angle = exist.angle
						existpoly.radius = exist.radius
					--	existpoly.triangles = meshvertex[#meshvertex]
						existink.color = exist.color
						existink.origin = exist.origin
						existink.normal = exist.normal
						existink.angle = exist.angle
						existink.radius = exist.radius
					--	existink.triangles = meshvertex[#meshvertex]
						table.insert(InkGroup[planeid], {existpoly, existink})
						
						if not dd then
							for k, v in ipairs(existink) do
								debugoverlay.Line(v.pos + normal * 100, existink[k % #existink + 1].pos + normal * 100, 5, Color(exist.color.x, exist.color.y, exist.color.z), false)
								debugoverlay.Text(v.pos + normal * 100, "C" .. k, 5)
							end
						end
					end
				end
			end
			local newink = {}
			for i, v in ipairs(poly) do
				newink[i] = LocalToWorld(v, angle_zero, pos, ang)
				newink[i] = {
					pos = newink[i] - (planenormal:Dot(newink[i] - planepos) / planedot) * normal,
					u = (v.y + MAX_SIZE / 2) / MAX_SIZE,
					v = (v.z + MAX_SIZE / 2) / MAX_SIZE,
				}
			end
			if not dd then
				for k, v in ipairs(newink) do
					debugoverlay.Line(v.pos + poly.normal * 50, newink[k % #newink + 1].pos + poly.normal * 50, 5, Color(255, 255, 0), false)
					debugoverlay.Text(v.pos + poly.normal * 50, "B" .. k, 5)
				end
				dd = true
			end
			newink.color = planecolor --build data structure
			newink.origin = pos
			newink.normal = normal
			newink.angle = ang
			newink.radius = radius
		--	newink.triangles = meshvertex[#meshvertex]
			table.insert(InkGroup[planeid], {poly, newink})
			polysprocessed = polysprocessed + 1
			if polysprocessed % MAX_POLYS_OVERWRITE_AT_TIME == 0 then coroutine.yield() end
		end
	end
	
	local sendcolor = vector_origin
	local refreshedid = {}
	local message_sent = 0
	for i, id in ipairs(meshvertex) do
		if not InkGroup[id] then continue end
		for k, m in ipairs(InkGroup[id]) do
			m = m[2]
			if #m < 3 then continue end
			if not refreshedid[id] then
				net.Start("SplatoonSWEPs: Reset ink mesh by ID", true)
				net.WriteInt(id, 32)
				net.Broadcast()
				refreshedid[id] = true
			end
			
			local sentindex = 1
			while sentindex < #m do
				local send = {} --32 bytes per vertex
				for k = 1, (65536 - 3) / 32 / 2 do
					table.insert(send, m[sentindex])
					if sentindex > #m then break end
					sentindex = sentindex + 1
				end
				net.Start("SplatoonSWEPs: Broadcast ink vertices", true)
				net.WriteTable(send)
				net.Broadcast()
			end
			
			sendcolor = m.color
			net.Start("SplatoonSWEPs: Finalize ink refreshment", true)
			net.WriteVector(Vector(sendcolor.x / 255, sendcolor.y / 255, sendcolor.z / 255))
			net.WriteVector(m.origin)
			net.WriteVector(m.normal)
			net.WriteInt(id, 32)
			net.Broadcast()
			
			message_sent = message_sent + 1
			if message_sent % MAX_MESSAGE_SEND == 0 then coroutine.yield() end
		end
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
			if done > MAX_PROCESS_QUEUE_AT_TIME then
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

local function InitTriangles()
	if not SplatoonSWEPs then return end
	local chunksize = SplatoonSWEPs.ChunkSize
	local mapsize = SplatoonSWEPs.MapSize
	local grid = {}
	if not mapsize then timer.Simple(0.2, InitTriangles) return end
	for x = -mapsize, mapsize, chunksize do
		grid[x - x % chunksize] = {} -- = grid[x]
		for y = -mapsize, mapsize, chunksize do
			grid[x - x % chunksize][y - y % chunksize] = {} -- = grid[x][y]
			for z = -mapsize, mapsize, chunksize do
				grid[x - x % chunksize][y - y % chunksize][z - z % chunksize] = {} -- = grid[x][y][z]
			end
		end
	end
	
	InkGroup = grid
end
hook.Add("Tick", "SplatoonSWEPsDoInkCoroutines", SplatoonSWEPsInkManager.Think)
hook.Add("InitPostEntity", "SplatoonSWEPsInitializeInkTable", InitTriangles)

function ClearInk()
	PaintQueue = {}
	InitTriangles()
end

include "splatoon_geometry.lua"
