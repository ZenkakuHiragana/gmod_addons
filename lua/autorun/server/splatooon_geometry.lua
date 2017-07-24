
--Code from BSP Snap.
local chunksize = 250
SplatoonSWEPs = {
	Points = {},
	Grid = {},
	Surface = {},
}

hook.Add("InitPostEntity", "SetupSplatoonGeometry", function()
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
	--26, LUMP_DISPINFO Displacement surface array
	--33, LUMP_DISP_VERTS Vertices of displacement surface meshes
	--48, LUMP_DISP_TRIS Displacement surface triangles
	local mapname = "maps/" .. game.GetMap() .. ".bsp"
	local LUMP_DISPINFO, LUMP_DISP_VERTS, LUMP_DISP_TRIS = 26, 33, 48
	if file.Exists(mapname, "GAME") then
		local f = file.Open(mapname, "rb", "GAME")
		if f then
			local ident = f:Read(4)
			local version = f:ReadLong()
			local lumps = {}
			for i = 0, 63 do
				table.insert(lumps, {
					fileofs = f:ReadLong(),
					filelen = f:ReadLong(),
					version = f:ReadLong(),
					fourCC = f:Read(4)
				})
			end
			local revision = f:ReadLong()
			f:Seek(lumps[LUMP_DISPINFO])
			print(f:Tell(), ident, version, revision)
			PrintTable(lumps)
			
			f:Close()
		end
	end
	
	
	
	SplatoonSWEPs.Points = points
	SplatoonSWEPs.Surface = surf
	
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
end)