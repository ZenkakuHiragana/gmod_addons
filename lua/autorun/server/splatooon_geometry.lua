
--Code from BSP Snap.
local chunksize = 250

SplatoonSWEPs = { Initialize = function()
--	print("bspSnap loading, " .. #points .. " points collected.\nPartitioning points into chunks...")
	local points = Entity(0):GetPhysicsObject():GetMesh()
	local min = Vector(math.huge, math.huge, math.huge) --Map bound
	local max = -min
	for i = 1, #points do --calculate minimum and maximum vector of map
		local point = points[i].pos
		for _, d in pairs({"x", "y", "z"}) do
			if point[d] < min[d] then
				min[d] = point[d]
			elseif point[d] > max[d] then
				max[d] = point[d]
			end
		end
	end
	
	local surf = {} --Get triangles of map, except displacements
	for i = 1, #points, 3 do
		local vert = {points[i].pos, points[i + 1].pos, points[i + 2].pos}
		local normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
		local center = (vert[1] + vert[2] + vert[3]) / 3
		surf[#surf + 1] = {vertices = vert, normal = normal, center = center}
	end
	
	--Parse bsp and get displacement info
	local lumps = {}
	local planes, vertexes, edges, surfedges, faces = {}, {}, {}, {}, {}
	local dispinfo = {} --Lump 26 DispInfo structure
	local dispvertices = {} --The actual vertices vector
	local mapname = "maps/" .. game.GetMap() .. ".bsp"
	local LUMP_PLANES, LUMP_VERTEXES, LUMP_EDGES, LUMP_SURFEDGES, LUMP_FACES, LUMP_DISPINFO, LUMP_DISP_VERTS, LUMP_DISP_TRIS
			= 1 + 1, 3 + 1, 12 + 1, 13 + 1, 7 + 1, 26 + 1, 33 + 1, 48 + 1
	local f = file.Open(mapname, "rb", "GAME")
	if f then
		local ident = f:Read(4)
		local version = f:ReadLong()
		local fileofs, filelen, version, fourCC = 0, 0, 0, ""
		for i = 0, 63 do
			fileofs = f:ReadLong()
			filelen = f:ReadLong()
			version = f:ReadLong()
			fourCC = f:Read(4)
			lumps[#lumps + 1] = {fileofs = fileofs, filelen = filelen, version = version, fourCC = fourCC}
		end
		
		f:Seek(lumps[LUMP_PLANES].fileofs)
		local x, y, z, i = 0, 0, 0, 0
		while 20 * i < lumps[LUMP_PLANES].filelen do
			f:Seek(lumps[LUMP_PLANES].fileofs + 20 * i)
			x = f:ReadFloat()
			y = f:ReadFloat()
			z = f:ReadFloat()
			i = i + 1
			planes[i] = {}
			planes[i].normal = Vector(x, y, z)
			planes[i].dist = f:ReadFloat()
		end
		
		i = 0
		f:Seek(lumps[LUMP_VERTEXES].fileofs)
		while 12 * i < lumps[LUMP_VERTEXES].filelen do
			f:Seek(lumps[LUMP_VERTEXES].fileofs + 12 * i)
			x = f:ReadFloat()
			y = f:ReadFloat()
			z = f:ReadFloat()
			i = i + 1
			vertexes[i] = Vector(x, y, z)
		end
		
		i = 0
		f:Seek(lumps[LUMP_EDGES].fileofs)
		while 4 * i < lumps[LUMP_EDGES].filelen do
			f:Seek(lumps[LUMP_EDGES].fileofs + 4 * i)
			i = i + 1
			edges[i] = {}
			edges[i][1] = f:Read(2)
			edges[i][1] = string.byte(edges[i][1][1]) + bit.lshift(string.byte(edges[i][1][2]), 8)
			edges[i][2] = f:Read(2)
			edges[i][2] = string.byte(edges[i][2][1]) + bit.lshift(string.byte(edges[i][2][2]), 8)
		end
		
		i = 0
		f:Seek(lumps[LUMP_SURFEDGES].fileofs)
		while 4 * i < lumps[LUMP_SURFEDGES].filelen do
			i = i + 1
			surfedges[i] = f:ReadLong() --wiki says this is an array of (signed) integers.
		end
		PrintTable(lumps) print("")
		PrintTable(planes) print("")
		PrintTable(vertexes) print("")
		PrintTable(edges) print("")
		PrintTable(surfedges) print("")
		
		i = 0
		f:Seek(lumps[LUMP_FACES].fileofs)
		while 56 * i < lumps[LUMP_FACES].filelen do
			f:Seek(lumps[LUMP_FACES].fileofs + 56 * i)
			i = i + 1
			faces[i] = {}
			faces[i].planenum = f:Read(2)
			faces[i].planenum = string.byte(faces[i].planenum[1]) + bit.lshift(string.byte(faces[i].planenum[2]), 8)
			f:Skip(1 + 1) --byte side, byte onNode
			faces[i].firstedge = f:ReadLong()
			faces[i].numedges = f:ReadShort()
			f:Skip(2) --texture info
			faces[i].dispinfo = f:ReadShort()
		end
		PrintTable(faces) print("")
		
		i = 0
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
			f:Skip(4 + 4) --int LightmapAlphaStart, int LightmapSamplePositionStart
			dispinfo[i].CDispNeighbor = {}
			for k = 1, 4 do --4x (2 + 4)*2 bytes
				dispinfo[i].CDispNeighbor[k] = {}
				dispinfo[i].CDispNeighbor[k].neighbor = f:ReadShort() --neighbor displacement index
				dispinfo[i].CDispNeighbor[k].unknown = f:ReadLong() --unknown int; k = left, top, right, bottom
				f:ReadShort() --???
				f:ReadLong() --???
			end
			dispinfo[i].CDispCornerNeighbors = {} --4x 10 bytes
			for k = 1, 4 do
				dispinfo[i].CDispCornerNeighbors[k] = {}
				for m = 1, 5 do
					dispinfo[i].CDispCornerNeighbors[k][m] = f:ReadShort()
				end
			end
		end
		--Finished fetching data
		
		for k, v in ipairs(dispinfo) do
			v.dispverts = {}
			for i = 1, (2^v.power + 1)^2 do
				f:Seek(lumps[LUMP_DISP_VERTS].fileofs + (v.DispVertStart + i - 1) * 20)
				x = f:ReadFloat()
				y = f:ReadFloat()
				z = f:ReadFloat()
				v.dispverts[i] = {}
				v.dispverts[i].vec = Vector(x, y, z)
				v.dispverts[i].dist = f:ReadFloat()
			end
			
			v.surf = {}
			v.surf.face = faces[v.MapFace + 1] --planenum, firstedge, numedges
			v.surf.plane = planes[v.surf.face.planenum + 1] --normal, dist
			v.surf.edge = {}
			v.vertices = {}
			local edgeindex, v1, v2 = 0, 0, 0
			for i = v.surf.face.firstedge, v.surf.face.firstedge + v.surf.face.numedges - 1 do
				edgeindex = math.abs(surfedges[i + 1]) + 1
				v1 = edges[edgeindex][1] + 1
				v2 = edges[edgeindex][2] + 1
				if surfedges[i + 1] < 0 then
					v1, v2 = v2, v1
				end
				v1, v2 = vertexes[v1], vertexes[v2]
				v.surf.edge[#v.surf.edge + 1] = {v1, v2}
				v.vertices[#v.vertices + 1] = v1
			end --Get corner positions of displacements
			
			if #v.vertices == 4 then
				local startedge = 1
				for i = 1, 4 do
					if v.startPosition:DistToSqr(v.vertices[i]) < 0.01 then
						startedge = i
						break
					end
				end
				
				if startedge == 4 then
					v.vertices[1],
					v.vertices[2],
					v.vertices[3],
					v.vertices[4]
					=	v.vertices[4],
						v.vertices[1],
						v.vertices[2],
						v.vertices[3]
				elseif startedge == 2 then
					v.vertices[1],
					v.vertices[2],
					v.vertices[3],
					v.vertices[4]
					=	v.vertices[2],
						v.vertices[3],
						v.vertices[4],
						v.vertices[1]
				elseif startedge == 3 then
					v.vertices[1],
					v.vertices[2],
					v.vertices[3],
					v.vertices[4]
					=	v.vertices[3],
						v.vertices[4],
						v.vertices[1],
						v.vertices[2]
				elseif startedge == 1 then
				
				print(k, startedge, "",
					v.vertices[1]:DistToSqr(v.startPosition),
					v.vertices[2]:DistToSqr(v.startPosition),
					v.vertices[3]:DistToSqr(v.startPosition),
					v.vertices[4]:DistToSqr(v.startPosition))
				end
			end
		end
		
		local power, div1, div2 = 0, vector_origin, vector_origin
		local u1, u2, v1, v2 = vector_origin, vector_origin, vector_origin, vector_origin
		for k, disp in ipairs(dispinfo) do
			if #disp.vertices ~= 4 then
				print("Displacement with other than 4 corners!")
				PrintTable(v)
			else
				power = 2^disp.power + 1
				u1 = disp.vertices[4] - disp.vertices[1]
				u2 = disp.vertices[3] - disp.vertices[2]
				v1 = disp.vertices[2] - disp.vertices[1]
				v2 = disp.vertices[3] - disp.vertices[4]
				for i, w in ipairs(disp.dispverts) do
					x = (i - 1) % power --0~power
					y = math.floor((i - 1) / power) -- 0~power
					div1, div2 = v1 * y / (power - 1), u1 + v2 * y / (power - 1)
					div2 = div2 - div1
					w.origin = div1 + div2 * x / (power - 1)
				end
			end
		end
		
		local origin, offsetOrigin, offsetVector, offsetScalar, pos, vertindex
		= vector_origin, vector_origin, vector_origin, 0, vector_origin, 1
		for i = 1, #dispinfo do
			dispvertices[i] = {}
			for k = 1, #dispinfo[i].dispverts do
				vertindex = (i - 1) * #dispinfo[i].dispverts + k
				origin = dispinfo[i].startPosition
				offsetOrigin = dispinfo[i].dispverts[k].origin
				offsetVector = dispinfo[i].dispverts[k].vec
				offsetScalar = dispinfo[i].dispverts[k].dist
				pos = origin + offsetOrigin + offsetVector * offsetScalar
				dispvertices[i][k]
				= {origin = origin, offsetVector = offsetVector, offsetScalar = offsetScalar, pos = pos, power = dispinfo[i].power}
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
	
	
--	Tear into pieces
--	local max_scalar = math.max(max.x, max.y, max.z, -min.x, -min.y, -min.z)
--	local grid = {}
--	local mapsize = max_scalar - max_scalar % chunksize + chunksize

--	for x = -mapsize, mapsize, chunksize do
--		grid[x - x % chunksize] = {} -- = grid[x]
--		for y = -mapsize, mapsize, chunksize do
--			grid[x - x % chunksize][y - y % chunksize] = {} -- = grid[x][y]
--			for z = -mapsize, mapsize, chunksize do
--				grid[x - x % chunksize][y - y % chunksize][z - z % chunksize] = {} -- = grid[x][y][z]
--			end
--		end
--	end
	
--	local t = SysTime()
--	for i = 1, #points do
--		local point = points[i].pos
--		local x = point.x - point.x % chunksize
--		local y = point.y - point.y % chunksize
--		local z = point.z - point.z % chunksize
--		local g = grid[x][y][z]
--		g[#g + 1] = point -- = table.insert(g, point)
--	end
--	print("Done!", SysTime() - t)
	
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

--	SplatoonSWEPs.Grid = grid

--	print("Finished partitioning, " .. empty .. " empty and " .. full .. " full out of " .. total .. " total (" .. empty/total .. ")")
end,}
hook.Add("InitPostEntity", "SetupSplatoonGeometry", SplatoonSWEPs.Initialize)
SplatoonSWEPs.Initialize()