
--Part of code from BSP Snap.
local LUMP_VERTEXES		=  3 + 1
local LUMP_EDGES		= 12 + 1
local LUMP_SURFEDGES	= 13 + 1
local LUMP_FACES		=  7 + 1
local LUMP_DISPINFO		= 26 + 1
local LUMP_DISP_VERTS	= 33 + 1
local LUMP_DISP_TRIS	= 48 + 1
local Debug = {
	CornerModulation = false,
	DrawMesh = false,
	TakeTime = false,
	WriteGeometryInfo = false,
}

SplatoonSWEPs = {
ChunkSize = 384,
Initialize = function()
	local chunksize = SplatoonSWEPs.ChunkSize
	local taketime = SysTime()
	local points = game.GetWorld():GetPhysicsObject()
	if not IsValid(points) then print("invalid world physics object") return end
	points = points:GetMesh()
	local surf = {} --Get triangles of the map, except displacements
	for i = 1, #points, 3 do
		local vert = {points[i].pos, points[i + 1].pos, points[i + 2].pos}
		local normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
		local center = (vert[1] + vert[2] + vert[3]) / 3
		table.insert(surf, {id = #surf + 1, vertices = vert, normal = normal, center = center})
	end
	
	--Parse bsp and get displacement info
	local lumps, vertexes, edges, surfedges, faces = {}, {}, {}, {}, {}
	local dispinfo = {} --Lump 26 DispInfo structure
	local dispvertices = {} --The actual vertices
	local mapname = "maps/" .. game.GetMap() .. ".bsp"
	local f = file.Open(mapname, "rb", "GAME")
	if f then
		f:Seek(8) --Identifier, Version
		for i = 0, 63 do --Lumps, index of the contents
			local fileofs = f:ReadLong()
			local filelen = f:ReadLong()
			f:Skip(4 + 4) --version, fourCC
			table.insert(lumps, {fileofs = fileofs, filelen = filelen})
		end
		
		--Vertexes, all vertices including displacements
		f:Seek(lumps[LUMP_VERTEXES].fileofs)
		local x, y, z, i = 0, 0, 0, 0
		while 12 * i < lumps[LUMP_VERTEXES].filelen do
			f:Seek(lumps[LUMP_VERTEXES].fileofs + 12 * i)
			x = f:ReadFloat()
			y = f:ReadFloat()
			z = f:ReadFloat()
			i = i + 1
			vertexes[i] = Vector(x, y, z)
		end
		
		i = 0 --Edges, vertex1 to vertex2
		f:Seek(lumps[LUMP_EDGES].fileofs)
		while 4 * i < lumps[LUMP_EDGES].filelen do
			f:Seek(lumps[LUMP_EDGES].fileofs + 4 * i)
			i = i + 1
			edges[i] = {}
			edges[i][1] = f:Read(2) --Reading unsigned short(16-bit integer)
			edges[i][1] = string.byte(edges[i][1][1]) + bit.lshift(string.byte(edges[i][1][2]), 8)
			edges[i][2] = f:Read(2)
			edges[i][2] = string.byte(edges[i][2][1]) + bit.lshift(string.byte(edges[i][2][2]), 8)
		end
		
		i = 0 --Surfedges, indices of edges
		f:Seek(lumps[LUMP_SURFEDGES].fileofs)
		while 4 * i < lumps[LUMP_SURFEDGES].filelen do
			i = i + 1
			surfedges[i] = f:ReadLong() --wiki says this is an array of (signed) integers.
		end
		
		i = 0 --Faces
		f:Seek(lumps[LUMP_FACES].fileofs)
		while 56 * i < lumps[LUMP_FACES].filelen do
			--Skipped: unsigned short planenum, byte side, byte onNode
			f:Seek(lumps[LUMP_FACES].fileofs + 56 * i + 2 + 1 + 1)
			i = i + 1
			faces[i] = {}
			faces[i].firstedge = f:ReadLong()
			faces[i].numedges = f:ReadShort()
		end
		
		i = 0 --DispInfo, information of displacements
		f:Seek(lumps[LUMP_DISPINFO].fileofs)
		while 176 * i < lumps[LUMP_DISPINFO].filelen do
			f:Seek(lumps[LUMP_DISPINFO].fileofs + 176 * i)
			i = i + 1
			x = f:ReadFloat()
			y = f:ReadFloat()
			z = f:ReadFloat()
			dispinfo[i] = {}
			dispinfo[i].startPosition = Vector(x, y, z) --Vector
			dispinfo[i].DispVertStart = f:ReadLong() --int
			dispinfo[i].DispTriStart = f:ReadLong() --int
			dispinfo[i].power = f:ReadLong() --int
			f:Skip(4 + 4 + 4) --int minTess, float smoothingAngle, int contents
			dispinfo[i].MapFace = f:Read(2) --unsigned short
			dispinfo[i].MapFace = string.byte(dispinfo[i].MapFace[1]) + bit.lshift(string.byte(dispinfo[i].MapFace[2]), 8)
			
			--DispVerts, table of distance from original position
			dispinfo[i].dispverts = {}
			for k = 1, (2^dispinfo[i].power + 1)^2 do
				f:Seek(lumps[LUMP_DISP_VERTS].fileofs + (dispinfo[i].DispVertStart + k - 1) * 20)
				x = f:ReadFloat()
				y = f:ReadFloat()
				z = f:ReadFloat()
				dispinfo[i].dispverts[k] = {}
				dispinfo[i].dispverts[k].vec = Vector(x, y, z)
				dispinfo[i].dispverts[k].dist = f:ReadFloat()
			end
		end
		--Finished fetching data
		if Debug.WriteGeometryInfo then
			PrintTable(lumps) print("")
			PrintTable(planes) print("")
			PrintTable(vertexes) print("")
			PrintTable(edges) print("")
			PrintTable(surfedges) print("")
			PrintTable(faces) print("")
		end
		
		--Make DispInfo more convenient
		for k, v in ipairs(dispinfo) do
			v.surf = {}
			v.surf.face = faces[v.MapFace + 1] --planenum, firstedge, numedges
			v.surf.edge = {} --Corner edges of the displacement
			v.vertices = {} --Corner positions of the displacement
			local edgeindex, v1, v2 = 0, 0, 0
			for i = v.surf.face.firstedge, v.surf.face.firstedge + v.surf.face.numedges - 1 do
				edgeindex = math.abs(surfedges[i + 1]) + 1 --wiki says surface number can be negative
				v1, v2 = edges[edgeindex][1] + 1, edges[edgeindex][2] + 1
				if surfedges[i + 1] < 0 then v1, v2 = v2, v1 end --If it is negative, it is inversed
				v1, v2 = vertexes[v1], vertexes[v2] --Get actual vectors from vector indices
				v.vertices[#v.vertices + 1] = v1 --We use the first one
			end
			
			--DispInfo.startPosition isn't always equal to vertices[1] so let's find the correct one
			if #v.vertices == 4 then
				local index, startedge = {}, 0
				for i = 1, 4 do
					if v.startPosition:DistToSqr(v.vertices[i]) < 0.01 then
						startedge = i
						break
					end
				end
				
				if Debug.CornerModulation then
					print(k, startedge, "",
						v.vertices[1]:DistToSqr(v.startPosition),
						v.vertices[2]:DistToSqr(v.startPosition),
						v.vertices[3]:DistToSqr(v.startPosition),
						v.vertices[4]:DistToSqr(v.startPosition))
				end
				
				for i = 0, 3 do
					index[i + 1] = ((i + startedge - 1) % 4) + 1
				end
				
				v.vertices[1],
				v.vertices[2],
				v.vertices[3],
				v.vertices[4]
				=	v.vertices[index[1]],
					v.vertices[index[2]],
					v.vertices[index[3]],
					v.vertices[index[4]]
				
				--Get the original positions of the displacement geometry
				local power, div1, div2 = 2^v.power + 1, vector_origin, vector_origin
				local u1, u2, v1, v2 = vector_origin, vector_origin, vector_origin, vector_origin
				if #v.vertices ~= 4 then
					print("Displacement No." .. k .. ": Displacement with other than 4 corners!")
				else
					u1 = v.vertices[4] - v.vertices[1]
					u2 = v.vertices[3] - v.vertices[2]
					v1 = v.vertices[2] - v.vertices[1]
					v2 = v.vertices[3] - v.vertices[4]
					for i, w in ipairs(v.dispverts) do
						x = (i - 1) % power --0 <= x <= power
						y = math.floor((i - 1) / power) -- 0 <= y <= power
						div1, div2 = v1 * y / (power - 1), u1 + v2 * y / (power - 1)
						div2 = div2 - div1
						w.origin = div1 + div2 * x / (power - 1)
					end
				end
				
				--Get the actual positions of the displacement geometry
				local origin, offsetOrigin, offsetVector, offsetScalar, pos
					= vector_origin, vector_origin, vector_origin, 0, vector_origin
				dispvertices[k] = {}
				for i, w in ipairs(v.dispverts) do
					origin, offsetOrigin, offsetVector, offsetScalar = v.startPosition, w.origin, w.vec, w.dist
					pos = origin + offsetOrigin + offsetVector * offsetScalar
					dispvertices[k][i] = {
						origin = origin,
						offsetVector = offsetVector,
						offsetScalar = offsetScalar,
						pos = pos,
						power = v.power
					}
				end
				
				--Generate triangles from positions
				for i = 1, #dispvertices[k] do
					local row = math.floor((i - 1) / power)
					local tri_inv = i % 2 ~= 0
					if (i - 1) % power < power - 1 and row < power - 1 then
					--	if row % 2 ~= 0 then tri_inv = not tri_inv end
						
						x, y, z = i, i + power, i + 1
						if tri_inv then y = y + 1 end
					--	4, 13, 5 |\
					--	3, 13, 4 |/
					--	2, 11, 3 |\
					--	1, 11, 2 |/
						local vert = {dispvertices[k][x].pos, dispvertices[k][y].pos, dispvertices[k][z].pos}
						local normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
						local center = (vert[1] + vert[2] + vert[3]) / 3
						table.insert(surf, {id = #surf + 1, vertices = vert, normal = normal, center = center})
						table.insert(points, {pos = vert[1]})
						table.insert(points, {pos = vert[2]})
						table.insert(points, {pos = vert[3]})
						if Debug.DrawMesh and k == 1 then
							debugoverlay.Line(vert[1], vert[2], 10, Color(0,255,0), true)
							debugoverlay.Line(vert[2], vert[3], 10, Color(0,255,0), true)
							debugoverlay.Line(vert[3], vert[1], 10, Color(0,255,0), true)
						end
						
						x, y, z = i + power + 1, i, i + power
						if not tri_inv then y = y + 1 end
						vert = {dispvertices[k][x].pos, dispvertices[k][y].pos, dispvertices[k][z].pos}
						normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
						center = (vert[1] + vert[2] + vert[3]) / 3
						table.insert(surf, {id = #surf + 1, vertices = vert, normal = normal, center = center})
						table.insert(points, {pos = vert[1]})
						table.insert(points, {pos = vert[2]})
						table.insert(points, {pos = vert[3]})
						if Debug.DrawMesh and k == 1 then
							debugoverlay.Line(vert[1], vert[2], 10, Color(0,255,0), true)
							debugoverlay.Line(vert[2], vert[3], 10, Color(0,255,0), true)
							debugoverlay.Line(vert[3], vert[1], 10, Color(0,255,0), true)
						end
					end
				end
			end
		end
		
		SplatoonSWEPs.DispInfo = dispinfo
		SplatoonSWEPs.DispVertices = dispvertices
		SplatoonSWEPs.Points = points
		SplatoonSWEPs.Surface = surf
		f:Close()
	end
	
--	print([[SplatoonSWEPs World Geometry:
--		Points: ]] .. #SplatoonSWEPs.Points .. [[
--		Grids: ]] .. #SplatoonSWEPs.Grid .. [[
--		Surface: ]] .. #SplatoonSWEPs.Surface .. [[
--	]])
	
--	Tear into pieces from BSP Snap
	local min = Vector(math.huge, math.huge, math.huge) --Map bound
	local max = -min
	for i, p in ipairs(points) do --calculate minimum and maximum vector of map
		for _, d in pairs({"x", "y", "z"}) do
			if p.pos[d] < min[d] then
				min[d] = p.pos[d]
			elseif p.pos[d] > max[d] then
				max[d] = p.pos[d]
			end
		end
	end

	local max_scalar = math.max(max.x, max.y, max.z, -min.x, -min.y, -min.z)
	local grid = {}
	local mapsize = max_scalar - max_scalar % chunksize + chunksize
	for x = -mapsize, mapsize, chunksize do
		grid[x - x % chunksize] = {} -- = grid[x]
		for y = -mapsize, mapsize, chunksize do
			grid[x - x % chunksize][y - y % chunksize] = {} -- = grid[x][y]
			for z = -mapsize, mapsize, chunksize do
				grid[x - x % chunksize][y - y % chunksize][z - z % chunksize] = {} -- = grid[x][y][z]
			end
		end
	end
	
--	for i, p in ipairs(points) do
--		local g = grid
--			[p.pos.x - p.pos.x % chunksize] --x
--			[p.pos.y - p.pos.y % chunksize] --y
--			[p.pos.z - p.pos.z % chunksize] --z
--		table.insert(g, p.pos)
--	end
	
	--Put surfaces into grids
	local chunkbound = Vector(chunksize, chunksize, chunksize)
--	local AABBPlanes = {
--		Vector(1, 0, 0), Vector(-1, 0, 0),
--		Vector(0, 1, 0), Vector(0, -1, 0),
--		Vector(0, 0, 1), Vector(0, 0, -1),
--	}
	for k, s in ipairs(surf) do
		for i = 1, 3 do
			local v1 = s.vertices[i]
			local v2 = s.vertices[i % 3 + 1]
			local dir = v2 - v1
			local x1, y1, z1 = v1.x - v1.x % chunksize, v1.y - v1.y % chunksize, v1.z - v1.z % chunksize
			local x2, y2, z2 = v2.x - v2.x % chunksize, v2.y - v2.y % chunksize, v2.z - v2.z % chunksize
			local gx, gy, gz = {}, {}, {}
			local addlist = {}
			if x1 > x2 then x1, x2 = x2, x1 end
			if y1 > y2 then y1, y2 = y2, y1 end
			if z1 > z2 then z1, z2 = z2, z1 end
			x2, y2, z2 = x2 + chunksize, y2 + chunksize, z2 + chunksize
			for x = x1, x2, chunksize do gx[x - x % chunksize] = true end
			for y = y1, y2, chunksize do gy[y - y % chunksize] = true end
			for z = z1, z2, chunksize do gz[z - z % chunksize] = true end
			for x in pairs(gx) do
				for y in pairs(gy) do
					for z in pairs(gz) do
						addlist[Vector(x, y, z)] = true
					end
				end
			end
			gz, gy, gz = {}, {}, {}
			
			 --I couldn't handle collision detection between AABB and line segment
			local g --So I'll just add surfaces to all suggested grids
		--	local d1, d2 = 0, 0
			for a in pairs(addlist) do
				g = grid[a.x][a.y][a.z]
			--	if k == 9763 then
			--		debugoverlay.Line(v1 + vector_up, v2 + vector_up, 10, Color(0, 255, 0), true)
			--		debugoverlay.Box(a, vector_origin, chunkbound, 5, Color(0,255,0))
			--	end
				if not g[s] then
				--	local plane = {a + chunkbound, a}
				--	local hit = v1:WithinAABox(a, a + chunkbound)
				--				or v2:WithinAABox(a, a + chunkbound)
				--	if not hit then
				--		--xin, xout, yin, yout, zin, zout
				--		local dimension = {"x", "x", "y", "y", "z", "z"}
				--		local fraction = {-math.huge, math.huge, -math.huge, math.huge, -math.huge, math.huge}
				--		local _in, _out = math.huge, -math.huge
				--		for normal = 1, 6, 2 do
				--			if a.x == 1250 and a.y == -1500 and a.z == 1250 then
				--				print(normal)
				--			end
				--			d1 = AABBPlanes[normal]:Dot(v1 - plane[normal % 2])
				--			d2 = AABBPlanes[normal + 1]:Dot(v1 - plane[normal % 2 + 1])
				--			if d1 >= 0 or d2 >= 0 then
				--				fraction[normal] = (plane[normal % 2][dimension[normal]] - v1[dimension[normal]]) / dir[dimension[normal]]
				--				fraction[normal + 1] = (plane[normal % 2 + 1][dimension[normal]] - v1[dimension[normal]]) / dir[dimension[normal]]
				--				if d1 > d2 then
				--					fraction[normal], fraction[normal + 1] = fraction[normal + 1], fraction[normal]
				--				end
				--			end
				--		end
				--		_in = math.max(fraction[1], fraction[3], fraction[5])
				--		_out = math.min(fraction[2], fraction[4], fraction[6])
				--		hit = _out - _in > 0
				--	end
					
				--	if hit then
						g[s] = true
				--	end
				end
			end
		end
	end
	
--	local empty = 0	-- amount of empty grids
--	local total = 0	-- amount of total grids
--	local full = 0	-- amount of grids that have points -> total = empty + full
--	for x = -mapsize, mapsize, chunksize do
--		for y = -mapsize, mapsize, chunksize do
--			for z = -mapsize, mapsize, chunksize do
--				local g = grid[x - x % chunksize][y - y % chunksize][z - z % chunksize]
--				total = total + 1
--				if #g == 0 then
--					empty = empty + 1
--					--grid[x - x % chunksize][y - y % chunksize][z - z % chunksize] = nil
--				else
--					full = full + 1
--				end
--			end
--		end
--	end
	
--	local a, b, c = true, true, true
--	for x, v in pairs(grid) do
--		if a then
--			a = false
--			for y, w in pairs(v) do
--				if b then
--					b = false
--					for z, u in pairs(w) do
--						PrintTable(u)
--					end
--				end
--			end
--		end
--	end
	
	SplatoonSWEPs.MapSize = mapsize
	SplatoonSWEPs.GridSurf = grid
	if Debug.TakeTime then
		print("SplatoonSWEPs: Finished parsing map vertices, with " .. SysTime() - taketime .. " seconds!")
	end
end,

Check = function(point)
	local x = point.x - point.x % SplatoonSWEPs.ChunkSize
	local y = point.y - point.y % SplatoonSWEPs.ChunkSize
	local z = point.z - point.z % SplatoonSWEPs.ChunkSize
--	debugoverlay.Box(Vector(x, y, z), vector_origin,
--	Vector(SplatoonSWEPs.ChunkSize, SplatoonSWEPs.ChunkSize, SplatoonSWEPs.ChunkSize), 5, Color(0,255,0))
	return SplatoonSWEPs.GridSurf[x][y][z]
end,}
hook.Add("InitPostEntity", "SetupSplatoonGeometry", SplatoonSWEPs.Initialize)

include "splatoon_inkmanager.lua"
