
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

SplatoonSWEPs = SplatoonSWEPs or {}
AddCSLuaFile "../splatoonsweps_const.lua"
include "../splatoonsweps_const.lua"
include "splatoonsweps_geometry.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_bsp.lua"

function SplatoonSWEPs:Check(point)
	return self.Surfaces
	-- local x = point.x - point.x % chunkrate
	-- local y = point.y - point.y % chunkrate
	-- local z = point.z - point.z % chunkrate
	-- debugoverlay.Box(Vector(x, y, z), vector_origin,
	-- Vector(chunksize, chunksize, chunksize), 5, Color(0,255,0))
	-- return SplatoonSWEPs.GridSurf[x][y][z]
end

function SplatoonSWEPs:Initialize()
	time, loadtime = SysTime(), 0
	
	local self = SplatoonSWEPs
	self.BSP.bspname = "maps/" .. game.GetMap() .. ".bsp"
	self.BSP:Init()
	local surfaces, added, LUMP, face = {}, 0, self.LUMP, self.BSP:GetLump(self.LUMP.FACES_HDR)
	if not face.parsed then face = self.BSP:GetLump(LUMP.FACES) end
	for i = 0, face.num do
		local data = face.data[i]
		if data.TexInfoTable.texdata.name:lower():find("tools/") then continue end
		if data.TexInfoTable.texdata.name:lower():find("water") then continue end
		if #data.Vertices + 1 < 3 then continue end
		if data.disabled then continue end
		if data.DispInfoTable and #data.Vertices + 1 == 4 then
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
				-- if not vprev then PrintTable(data) end
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
