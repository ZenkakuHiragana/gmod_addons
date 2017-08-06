
--This lua manages whole ink in map.
if not SplatoonSWEPs then return end

local MAX_COROUTINES = 10
local inkdegrees = 45
local move_normal_distance = 0.5
local PaintQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")
util.AddNetworkString("SplatoonSWEPs: Reset ink mesh by ID")

local MAX_SIZE = 300
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
					color = planecolor,
				})
			end
		end
	end
	return result
end

local function QueueCoroutine(pos, normal, ang, radius, color, polys)
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
			if math.abs(dot1) < radius * math.sin(math.rad(inkdegrees)) then
				for k = 1, 3 do
					--Vertices is within InkRadius
					local v1 = s.vertices[1]
					local rel1 = v1 - pos
					local v2 = s.vertices[k % 3 + 1]
					local rel2 = v2 - pos
					local line = v2 - v1 --now v1 and v2 are relative vector
					v1, v2 = rel1 - normal * normal:Dot(rel1), rel2 - normal * normal:Dot(rel2)
					if line:GetNormalized():Cross(v1):Dot(normal) < radius then
						if (v1:Dot(line) < 0 and v2:Dot(line) > 0) or
							math.min(v2:LengthSqr(), v1:LengthSqr()) < radiusSqr then
							surf[{
								s.vertices[1] - s.normal * move_normal_distance,
								s.vertices[2] - s.normal * move_normal_distance,
								s.vertices[3] - s.normal * move_normal_distance,
								normal = s.normal,
								center = s.center,
								id = s.id,
							}] = true
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
		for i = 1, 3 do
			planarsurf[i] = WorldToLocal(drawable[i], angle_zero, pos, ang)
			planarsurf[i].x = 0
		end
		
		intersection.Poly, intersection.Tri = SplatoonSWEPs.BuildOverlap(polys, planarsurf, false)
		intersection.Plane = {
			pos = drawable.center - drawable.normal * move_normal_distance,
			normal = drawable.normal,
			id = drawable.id,
			color = color,
		}
		vertexlist[intersection] = true
		intersection = {Poly = {}, Tri = {}, Plane = {}}
	end
	
	coroutine.yield()
	
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
		table.insert(meshvertex, {})
		table.insert(meshinfo, {pos = pos, normal = planenormal, color = planecolor, id = planeid})
		table.Add(meshvertex[#meshvertex], GetMeshTriangle(
			PolygonData.Tri, pos, normal, ang, planepos, planenormal, planedot, planecolor))
		for _, poly in ipairs(PolygonData.Poly) do
			if #poly < 3 then continue end
			poly.color = planecolor --build data structure
			poly.origin = pos
			poly.angle = ang
			poly.radius = radius
			poly.triangles = meshvertex[#meshvertex]
			
			--Overwrite existing ink
			InkGroup[planeid] = {}
			if inklist then
				local processed = 0
				for times, exist in ipairs(inklist) do
					processed = processed + 1
					if processed % MAX_OVERWRITE_AT_TIME == 0 then coroutine.yield() end
					
					if pos:DistToSqr(exist.origin) > (radius + exist.radius)^2 then
						table.insert(InkGroup[planeid], exist)
						table.insert(meshvertex, {})
						table.insert(meshinfo, {pos = exist.origin, normal = planenormal, color = exist.color, id = planeid})
						table.Add(meshvertex[#meshvertex], exist.triangles)
						continue
					end
					local subtrahend = {}
					local existOrigin = WorldToLocal(pos, angle_zero, exist.origin, exist.angle)
					existOrigin.x = 0
					for i, vertex in ipairs(poly) do
						subtrahend[i] = vertex + existOrigin
					end
					
					existVertices, existTriangles = SplatoonSWEPs.BuildOverlap(exist, subtrahend, true)
					table.insert(meshvertex, {})
					table.insert(meshinfo, {pos = exist.origin, normal = planenormal, color = exist.color, id = planeid})
					table.Add(meshvertex[#meshvertex], GetMeshTriangle(
						existTriangles, exist.origin, normal, ang, planepos, planenormal, planedot, exist.color))
					
					for _, existpoly in ipairs(existVertices) do
						if #existpoly < 3 then continue end
						existpoly.color = exist.color
						existpoly.origin = exist.origin
						existpoly.angle = exist.angle
						existpoly.radius = exist.radius
						existpoly.triangles = meshvertex[#meshvertex]
						table.insert(InkGroup[planeid], existpoly)
						
						-- for k, v in ipairs(existpoly) do
							-- v = LocalToWorld(v, angle_zero, exist.origin, ang)
							-- v = v - (planenormal:Dot(v - planepos) / planedot) * normal
							-- local w = LocalToWorld(existpoly[k % #existpoly + 1], angle_zero, exist.origin, ang)
							-- w = w - (planenormal:Dot(w - planepos) / planedot) * normal
							-- debugoverlay.Line(v, w, 5, Color(exist.color.x, exist.color.y, exist.color.z), true)
						-- end
					end
				end
			end
			table.insert(InkGroup[planeid], poly)
			polysprocessed = polysprocessed + 1
			if polysprocessed % MAX_POLYS_OVERWRITE_AT_TIME == 0 then coroutine.yield() end
		end
	end
	
	local sendcolor = vector_origin
	local refreshedid = {}
	local message_sent = 0
	for i, m in ipairs(meshvertex) do
		if #m < 3 then continue end
		if not refreshedid[meshinfo[i].id] then
			net.Start("SplatoonSWEPs: Reset ink mesh by ID")
			net.WriteInt(meshinfo[i].id, 32)
			net.Broadcast()
			refreshedid[meshinfo[i].id] = true
		end
		
		local sentindex = 1
		while sentindex < #m do
			local send = {} --32 bytes per vertex
			for k = 1, (65536 - 3) / 32 / 2 do
				table.insert(send, m[sentindex])
				if sentindex > #m then break end
				sentindex = sentindex + 1
			end
			net.Start("SplatoonSWEPs: Broadcast ink vertices")
			net.WriteTable(send)
			net.Broadcast()
		end
		
		sendcolor = meshinfo[i].color
		net.Start("SplatoonSWEPs: Finalize ink refreshment")
		net.WriteVector(Vector(sendcolor.x / 255, sendcolor.y / 255, sendcolor.z / 255))
		net.WriteVector(meshinfo[i].pos)
		net.WriteVector(meshinfo[i].normal)
		net.WriteInt(meshinfo[i].id, 32)
		net.Broadcast()
		
		message_sent = message_sent + 1
		if message_sent % MAX_MESSAGE_SEND == 0 then coroutine.yield() end
	end
	
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
		--	print("coroutine end: ", ok, message)
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
			if done > MAX_COROUTINES then
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
