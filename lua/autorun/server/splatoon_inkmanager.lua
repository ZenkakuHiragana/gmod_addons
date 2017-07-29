
--This lua manages whole ink in map.

local MAX_COROUTINES = 10
local PaintQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")

local inkdegrees = 45
local move_normal_distance = 0.5
local function QueueCoroutine(pos, normal, ang, radius, color, polys)
	local tb = {} --Result vertices table
	local surf = {} --Surfaces that are affected by painting
	local radiusSqr = radius^2
	local targetsurf = SplatoonSWEPs.Check(pos)
	for s, _ in pairs(targetsurf) do --This section searches surfaces in chunk.
		if not istable(s) then continue end
		if not (s.normal and s.vertices) then continue end
		--Surfaces that have almost same normal as the given data.
		if s.normal:Dot(normal) > math.cos(math.rad(inkdegrees)) then
			for k = 1, 3 do
				--Surface.Z is near HitPos
				local v1 = s.vertices[k]
				local rel1 = v1 - pos
				local dot1 = s.normal:Dot(rel1)
				if math.abs(dot1) < radius * math.cos(math.rad(inkdegrees)) then
					--Vertices is within InkRadius
					local v2 = s.vertices[i % 3 + 1]
					local rel2 = v2 - pos
					local line = v2 - v1 --now v1 and v2 are relative vector
					v1, v2 = rel1 - normal * dot1, rel2 - normal * normal:Dot(rel2)
					if line:GetNormalized():Cross(v1):Dot(normal) < radius then
						if (v1:Dot(line) < 0 and v2:Dot(line) > 0) or
							math.min(v2:LengthSqr(), v1:LengthSqr()) < radiusSqr then
							table.insert(surf, {
								s.vertices[1] - s.normal * move_normal_distance,
								s.vertices[2] - s.normal * move_normal_distance,
								s.vertices[3] - s.normal * move_normal_distance
							})
							break
						end
					end
				end --if dot1 > 0
			end --for k = 1, 3
		end --if s.normal:Dot
	end --for #SplatoonSWEPs.Surface
	
	coroutine.yield()
	
	local verts = {} --Vertices for polygon that we attempt to draw
	local i1, i2, k1, k2 = vector_origin, vector_origin, vector_origin, vector_origin
	local v1, v2, intersection = vector_origin, vector_origin, vector_origin
	local cross1, cross2 = vector_origin, vector_origin
	local drawable_vertices = {vector_origin, vector_origin, vector_origin}
	local d_in_ref, ref_in_d = {true, true, true}, false
	for _, reference in ipairs(polys) do
		for _, drawable in ipairs(surf) do
			tb = {}
			d_in_ref = {true, true, true}
			for i = 1, 3 do --Look into each line segments
				ref_in_d = true
				i1 = reference[i] * radius
				i2 = reference[i % 3 + 1] * radius
				drawable_vertices = {vector_origin, vector_origin, vector_origin}
				for k = 1, 3 do
					k1 = WorldToLocal(drawable[k], angle_zero, pos, ang)
					k2 = WorldToLocal(drawable[k % 3 + 1], angle_zero, pos, ang)
					k1, k2 = Vector(0, k1.y, k1.z), Vector(0, k2.y, k2.z)
					v1, v2 = i2 - i1, k2 - k1
					drawable_vertices[k] = k1
					--Check crossing each other
					cross1 = v2:Cross(v1).x
					cross1, cross2 = v2:Cross(k1 - i1).x / cross1, v1:Cross(k1 - i1).x / cross1
					if cross1 >= 0 and cross2 >= 0 and cross1 <= 1 and cross2 <= 1 then
						intersection = i1 + cross1 * v1
						table.insert(tb, {pos = intersection, z = intersection.z})
					end
					--is reference vertex in drawable triangle?
					if v2:Cross(i1 - k2).x < 0 then
						ref_in_d = false
					end
					--is drawable vertex in reference triangle?
					if v1:Cross(k1 - i2).x >= 0 then
						d_in_ref[k] = false
					end
				end
				if ref_in_d then
					table.insert(tb, {pos = i1, z = i1.z})
				end
			end
			for k, within in ipairs(d_in_ref) do
				if within then
					table.insert(tb, {pos = drawable_vertices[k], z = drawable_vertices[k].z})
				end
			end
			
			v1 = nil
			local base = Vector(0, 1, 0)
			for k, v in SortedPairsByMemberValue(tb, "z", true) do
				if not v1 then
					v1, tb[k].rad = v.pos, -math.huge
				else
					v2 = (v.pos - v1):GetNormalized()
					tb[k].rad = math.atan2(base:Cross(v2).x, base:Dot(v2))
				end
			end
			table.SortByMember(tb, "rad", true)
			tb.plane = {pos = drawable[1], normal = 
			(drawable[2] - drawable[1]):Cross(drawable[3] - drawable[2]):GetNormalized()}
			table.insert(verts, tb)
		end
	end
	
	coroutine.yield()
	
	--split polygons into triangles
	--get back to world coordinate
	local tris, tri_prev, tri_prev2, trivector, i = {}, {}, {}, vector_origin, 1
	local planepos, planenormal = vector_origin, vector_origin
	for __, poly in ipairs(verts) do
		if #poly == 0 then continue end
		planepos = poly.plane.pos
		planenormal = poly.plane.normal
		i = 1
		while i <= #poly do
			trivector = LocalToWorld(poly[i].pos, angle_zero, pos, ang)
			trivector = trivector - (planenormal:Dot(trivector - planepos) / planenormal:Dot(normal)) * normal
			tb = {pos = trivector,
				u = math.abs(poly[i].pos.y) / radius,
				v = math.abs(poly[i].pos.z) / radius,
				color = color,
			}
			
			if i > 3 then
				i1 = i % 2 == 1 and 1 or 2
				tri_prev = tris[#tris]
				tri_prev2 = tris[#tris - i1]
				v1 = tri_prev2.pos - tri_prev.pos
				v2 = trivector - tri_prev.pos
				cross1 = v1:Cross(v2)
				if cross1:Dot(planenormal) < 0 then
					tri_prev2, tb = tb, tri_prev2
				end
			--	table.insert(tris, tri_prev)
			--	table.insert(tris, tri_prev2)
			--	table.insert(tris, tb)
				table.insert({
					tri_prev.pos, tri_prev2.pos, tb.pos,
					u = {tri_prev.u, tri_prev2.u, tb.u},
					v = {tri_prev.v, tri_prev2.v, tb.v},
					color = color,
					normal = planenormal,
					area = (poly[i + 1].pos - poly[i].pos):Cross(poly[i + 2].pos - poly[i].pos).x / 2,
				})
				i = i + 1
			else
				v1 = LocalToWorld(poly[i + 1].pos, angle_zero, pos, ang)
				v2 = LocalToWorld(poly[i + 2].pos, angle_zero, pos, ang)
				v1 = v1 - (planenormal:Dot(v1 - planepos) / planenormal:Dot(normal)) * normal
				v2 = v2 - (planenormal:Dot(v2 - planepos) / planenormal:Dot(normal)) * normal
				cross1 = (v1 - trivector):Cross(v2 - trivector)
				i1 = {
					pos = v1,
					u = math.abs(poly[i + 1].pos.y) / radius,
					v = math.abs(poly[i + 1].pos.z) / radius,
					color = color,
				}
				i2 = {
					pos = v2,
					u = math.abs(poly[i + 2].pos.y) / radius,
					v = math.abs(poly[i + 2].pos.z) / radius,
					color = color,
				}
				if cross1:Dot(planenormal) < 0 then
					i1, i2 = i2, i1
					v1, v2 = v2, v1
				end
				
			--	table.insert(tris, tb)
			--	table.insert(tris, i1)
			--	table.insert(tris, i2)
				table.insert(tris, {
					trivector, v1, v2,
					u = {tb.u, i1.u, i2.u},
					v = {tb.v, i1.v, i2.v},
					color = color,
					normal = planenormal,
					area = (poly[i + 1].pos - poly[i].pos):Cross(poly[i + 2].pos - poly[i].pos).x / 2,
				})
				i = i + 3
			end
		end
	end
	
	coroutine.yield(tris)
end

local function OverwriteInk(tris)
	local tb = {}
	local chunksize = SplatoonSWEPs.ChunkSize
	for k, s in ipairs(tris) do
		for i = 1, 3 do
			local v1 = s[i]
			local v2 = s[i % 3 + 1]
			local dir = v2 - v1
			local x1, y1, z1 = v1.x - v1.x % chunksize, v1.y - v1.y % chunksize, v1.z - v1.z % chunksize
			local x2, y2, z2 = v2.x - v2.x % chunksize, v2.y - v2.y % chunksize, v2.z - v2.z % chunksize
			local addlist = {x = {}, y = {}, z = {}}
			if x1 > x2 then x1, x2 = x2, x1 end
			if y1 > y2 then y1, y2 = y2, y1 end
			if z1 > z2 then z1, z2 = z2, z1 end
			for x = x1, x2, chunksize do table.insert(addlist.x, x - x % chunksize) end
			for y = y1, y2, chunksize do table.insert(addlist.y, y - y % chunksize) end
			for z = z1, z2, chunksize do table.insert(addlist.z, z - z % chunksize) end
			for _, x in ipairs(addlist.x) do
				for _, y in ipairs(addlist.y) do
					for _, z in ipairs(addlist.z) do
						table.insert(addlist, Vector(x, y, z))
					end
				end
			end
			
			local g
			local d1, d2 = 0, 0
			for _, a in ipairs(addlist) do
				g = InkGroup[a.x][a.y][a.z]
				if not g[s] then
					table.insert(g, tris)
				end
			end
		end
	end
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
			
			local ok, tris = coroutine.resume(
				v.co, v.pos, v.normal, v.ang, v.radius, v.color, v.polys)
			if ok and tris then
				queue[i] = nil
				OverwriteInk(tris)
				net.Start("SplatoonSWEPs: Broadcast ink vertices")
				net.WriteTable(tris)
				net.WriteVector(Vector(v.color.r / 255, v.color.g / 255, v.color.b / 255))
				net.WriteVector(v.pos)
				net.WriteVector(v.normal)
				net.Broadcast()
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
				Msg(self, "SplatoonSWEPs Warning: Coroutine " .. i .. " has finished executing\n")
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
