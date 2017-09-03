
--SplatoonSWEPs structure
--The core of new ink system.

--Fix Angle:Normalize() in SLVBase
--The problem is functions between default Angle:Normalize() and SLVBase's one have different behaviour:
--default one changes the given angle, SLV's one returns normalized angle.
--So I need to branch the normalize function.  I hate SLVBase.
local NormalizeAngle = FindMetaTable("Angle").Normalize
if SLVBase and not SLVBase.IsFixedNormalizeAngle then
	NormalizeAngle = function(ang) ang:Set(ang:Normalize()) return ang end
	SLVBase.IsFixedNormalizeAngle = true
end

local chunksize = 384
local chunkrate = chunksize / 2
local chunkbound = Vector(chunksize, chunksize, chunksize)

local time = SysTime()
local loadtime = 0
local Debug = {
	CornerModulation = false,
	DrawMesh = false,
	TakeTime = true,
	WriteGeometryInfo = false,
}
local function ShowTime(str)
	if not Debug.TakeTime then return end
	loadtime = loadtime + SysTime() - time
	print("SplatoonSWEPs: " .. SysTime() - time .. " seconds.", str)
	time = SysTime()
end

SplatoonSWEPs = SplatoonSWEPs or {}
local Initialize = function()
	
	--Tear into pieces from BSP Snap
	--Map bound
	local min, max = Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)
	for i, p in ipairs(points) do --calculate minimum and maximum vector of map
		for _, d in ipairs({"x", "y", "z"}) do
			if p.pos[d] < min[d] then
				min[d] = p.pos[d]
			elseif p.pos[d] > max[d] then
				max[d] = p.pos[d]
			end
		end
	end

	local grid = {}
	local max_scalar = math.max(math.abs(max.x), math.abs(max.y), math.abs(max.z),
								math.abs(min.x), math.abs(min.y), math.abs(min.z))
	local mapsize = max_scalar - max_scalar % chunksize + chunksize
	for x = -mapsize, mapsize, chunkrate do
		grid[x] = {}
		for y = -mapsize, mapsize, chunkrate do
			grid[x][y] = {}
			for z = -mapsize, mapsize, chunkrate do
				grid[x][y][z] = {}
			end
		end
	end
	
	--Put surfaces into grids
	for _, s in ipairs(surf) do
		for i = 1, #s.vertices do
			local v1 = s.vertices[i]
			local v2 = s.vertices[i % #s.vertices + 1]
			local x1, y1, z1 = v1.x - v1.x % chunksize, v1.y - v1.y % chunksize, v1.z - v1.z % chunksize
			local x2, y2, z2 = v2.x - v2.x % chunksize, v2.y - v2.y % chunksize, v2.z - v2.z % chunksize
			local gx, gy, gz, addlist = {}, {}, {}, {}
			if x1 > x2 then x1, x2 = x2, x1 end
			if y1 > y2 then y1, y2 = y2, y1 end
			if z1 > z2 then z1, z2 = z2, z1 end
			x2, y2, z2 = x2 + chunksize, y2 + chunksize, z2 + chunksize
			x1, y1, z1 = x1 - chunksize, y1 - chunksize, z1 - chunksize
			for x = x1, x2, chunkrate do gx[x] = true end
			for y = y1, y2, chunkrate do gy[y] = true end
			for z = z1, z2, chunkrate do gz[z] = true end
			for x in pairs(gx) do
				for y in pairs(gy) do
					for z in pairs(gz) do
						addlist[Vector(x, y, z)] = true
					end
				end
			end
			gz, gy, gz = {}, {}, {}
			
			--I couldn't handle collision detection between AABB and line segment
			--So I'll just add surfaces to all suggested grids
			for a in pairs(addlist) do
				if grid[a.x] and grid[a.x][a.y] and grid[a.x][a.y][a.z] and not grid[a.x][a.y][a.z][s] then
					grid[a.x][a.y][a.z][s] = true
				end
			end
		end
	end
	
	SplatoonSWEPs.MapSize = mapsize
	SplatoonSWEPs.GridSurf = grid
	if Debug.TakeTime then
		ShowTime("Grid Generated")
		print("SplatoonSWEPs: Finished parsing map vertices, with " .. loadtime .. " seconds!")
	end
end

include "splatoon_inkmanager.lua"
include "splatoon_bsp.lua"

SplatoonSWEPs.Check = function(self, point)
	return self.Surfaces
	-- local x = point.x - point.x % chunkrate
	-- local y = point.y - point.y % chunkrate
	-- local z = point.z - point.z % chunkrate
	-- debugoverlay.Box(Vector(x, y, z), vector_origin,
	-- Vector(chunksize, chunksize, chunksize), 5, Color(0,255,0))
	-- return SplatoonSWEPs.GridSurf[x][y][z]
end

SplatoonSWEPs.Initialize = function()
	time, loadtime = SysTime(), 0
	
	local self = SplatoonSWEPs
	self.BSP.bspname = "maps/" .. game.GetMap() .. ".bsp"
	self.BSP:Init()
	local surfaces, added, LUMP, face = {}, 0, self.LUMP, self.BSP:GetLump(self.LUMP.FACES_HDR)
	if not face.parsed then face = self.BSP:GetLump(LUMP.FACES) end
	for i = 0, face.num do
		local data = face.data[i]
		if data.TexInfoTable.texdata.name:lower():find("tools/") then continue end
		if data.DispInfoTable then
			--Generate triangles from displacement mesh.
			assert(#data.Vertices + 1 == 4, "SplatoonSWEPs: Displacement with " .. #data.Vertices + 1 .. " vertices.")
			local surf, power, dispverts = {}, data.DispInfoTable.power^2, data.DispInfoTable.DispVerts
			for i = 0, #dispverts do
				local row = math.floor(i / power)
				local tri_inv = i % 2 == 0
				if i % power < power - 1 and row < power - 1 then
				--	21, 12, 3 |/\/
				--	20, 11, 2 |\/\
				--	19, 10, 1 |/\/
				--	18,  9, 0 |\/\
					local x, y, z = i, i + 1, i + power
					if tri_inv then z = z + 1 end
					local vert = {dispverts[x].pos, dispverts[y].pos, dispverts[z].pos}
					local normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
					local center = (vert[1] + vert[2] + vert[3]) / 3
					local contents = util.PointContents(center - normal * 1e-4)
					if bit.band(contents, CONTENTS_GRATE) == 0 then
						added = added + 1
						surfaces[{id = added, vertices = vert, normal = normal, center = center}] = true
					end
					
					x, y, z = i + power + 1, i + power, i
					if not tri_inv then z = z + 1 end
					vert = {dispverts[x].pos, dispverts[y].pos, dispverts[z].pos}
					normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
					center = (vert[1] + vert[2] + vert[3]) / 3
					contents = util.PointContents(center - normal * 1e-4)
					if bit.band(contents, CONTENTS_GRATE) == 0 then
						added = added + 1
						surfaces[{id = added, vertices = vert, normal = normal, center = center}] = true
					end
				end
			end
		else
			local surf, center, normal, numverts = {vertices = {}}, vector_origin, vector_origin, #data.Vertices + 1
			for k = numverts - 1, 0, -1 do
				local vnext, vprev = data.Vertices[(k + numverts - 1) % numverts], data.Vertices[(k + 1) % numverts]
				local n = (data.Vertices[k] - vprev):Cross(vnext - data.Vertices[k])
				if n:LengthSqr() > 1e-6 then
					table.insert(surf.vertices, data.Vertices[k])
					center = center + data.Vertices[k]
					normal = n
				end
			end
			center = center / #surf.vertices
			if data.PlaneTable and data.PlaneTable.normal then
				normal = data.PlaneTable.normal
			else
				normal:Normalize()
			end
			
			local contents = util.PointContents(center - normal * 1e-4)
			if bit.band(contents, CONTENTS_GRATE) == 0 and #surf.vertices > 2 then
				added = added + 1
				surf.center = center
				surf.normal = normal
				surf.id = added
				surfaces[surf] = true
				-- timer.Simple(i * 0.1, function()
					-- for i, v in ipairs(surf.vertices) do
						-- debugoverlay.Line(v, surf.vertices[i % #surf.vertices + 1], 5, Color(255, 255, 0), true)
						-- debugoverlay.Line(v, surf.center, 5, Color(255, 255, 0), true)
						-- debugoverlay.Line(v, v + surf.normal * 50, 5, Color(255, 255, 0), true)
					-- end
				-- end)
			end
		end
	end
	self.Surfaces = surfaces
end

hook.Add("InitPostEntity", "SetupSplatoonGeometry", SplatoonSWEPs.Initialize)
