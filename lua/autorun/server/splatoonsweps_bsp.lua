require "SZL"
include "includes/modules/polybool.lua"

--This lua parses the bsp file of current map.
if not SplatoonSWEPs then return end
SplatoonSWEPs.BSP = SplatoonSWEPs.BSP or {}
SplatoonSWEPs.LUMP = {
	ENTITIES						=  0,
	PLANES							=  1,
	TEXDATA							=  2,
	VERTEXES						=  3,
	VISIBLITY						=  4,
	NODES							=  5,
	TEXINFO							=  6,
	FACES							=  7,
	LIGHTING						=  8,
	OCCLUSION						=  9,
	LEAFS							= 10,
	FACEIDS							= 11,
	EDGES							= 12,
	SURFEDGES						= 13,
	MODELS							= 14,
	WORLDLIGHTS						= 15,
	LEAFFACES						= 16,
	LEAFBRUSHES						= 17,
	BRUSHES							= 18,
	BRUSHSIDES						= 19,
	AREAS							= 20,
	AREAPORTALS						= 21,
	PORTALS							= 22, --unused in version 20
	CLUSTERS						= 23, --
	PORTALVERTS						= 24, --
	CLUSTERPORTALS					= 25, --unused in version 20
	DISPINFO						= 26,
	ORIGINALFACES					= 27,
	PHYSDISP						= 28,
	PHYSCOLLIDE						= 29,
	VERTNORMALS						= 30,
	VERTNORMALINDICES				= 31,
	DISP_LIGHTMAP_ALPHAS			= 32,
	DISP_VERTS						= 33,
	DISP_LIGHMAP_SAMPLE_POSITIONS	= 34,
	GAME_LUMP						= 35,
	LEAFWATERDATA					= 36,
	PRIMITIVES						= 37,
	PRIMVERTS						= 38,
	PRIMINDICES						= 39,
	PAKFILE							= 40,
	CLIPPORTALVERTS					= 41,
	CUBEMAPS						= 42,
	TEXDATA_STRING_DATA				= 43,
	TEXDATA_STRING_TABLE			= 44,
	OVERLAYS						= 45,
	LEAFMINDISTTOWATER				= 46,
	FACE_MACRO_TEXTURE_INFO			= 47,
	DISP_TRIS						= 48,
	PHYSCOLLIDESURFACE				= 49,
	WATEROVERLAYS					= 50,
	LIGHTMAPEDGES					= 51,
	LIGHTMAPPAGEINFOS				= 52,
	LIGHTING_HDR					= 53, --only used in version 20+ BSP files
	WORLDLIGHTS_HDR					= 54, --
	LEAF_AMBIENT_LIGHTING_HDR		= 55, --
	LEAF_AMBIENT_LIGHTING			= 56, --only used in version 20+ BSP files
	XZIPPAKFILE						= 57,
	FACES_HDR						= 58,
	MAP_FLAGS						= 59,
	OVERLAY_FADES					= 60,
	OVERLAY_SYSTEM_LEVELS			= 61,
	PHYSLEVEL						= 62,
	DISP_MULTIBLEND					= 63,
}

require "SZL"
local NodeFuncs = {}
local NodeMeta = {__index = NodeFuncs}
function NodeFuncs.GetChildren(self, pos)
	local planenormal = self.Separator.normal
	local planeorg = self.Separator.Origin
	local childindex = planenormal:Dot(pos - planeorg) > 0 and 1 or 2
	return self.ChildNodes[childindex], self.ChildNodes[3 - childindex]
end

function NodeFuncs.Across(self, mins, maxs, org)
	org = org or vector_origin
	local planenormal = self.Separator.normal
	local planeorg = self.Separator.Origin
	local mindot, maxdot = math.huge, -math.huge
	for _, v in ipairs {
		mins, maxs,
		Vector(maxs.x, mins.y, mins.z),
		Vector(mins.x, maxs.y, mins.z),
		Vector(mins.x, mins.y, maxs.z),
		Vector(mins.x, maxs.y, maxs.z),
		Vector(maxs.x, mins.y, maxs.z),
		Vector(maxs.x, maxs.y, mins.z),
	} do
		local dot = planenormal:Dot(v + org - planeorg)
		mindot = math.min(mindot, dot)
		maxdot = math.max(maxdot, dot)
	end
	
	return mindot * maxdot < 0
end

local TextureMeta = {}
local bsp = SplatoonSWEPs.BSP
local LUMP = SplatoonSWEPs.LUMP
function bsp.__index(self, k)
	return getmetatable(self)[k]
end

function TextureMeta.__index(self, k)
	return getmetatable(self)[k]
end

function TextureMeta:GetMaterial(scale)
	return self.Material or self:MakeMaterial()
end

function TextureMeta:MakeMaterial()
	self.width = self.TexData.width
	self.height = self.TexData.height
	self.Material = CreateMaterial(tostring(self) .. "_texinfo", "UnlitGeneric", {
		["$basetexture"] = Material(self.TexData.name):GetTexture("$basetexture"):GetName(),
		["$detailscale"] = 1,
		["$reflectivity"] = self.TexData.reflectivity,
		["$model"] = 1,
	})
	return self.Material
end

function TextureMeta:GenerateUV(x, y, z)
	local s, t = 0, 1
	return
		(self.textureVecs[s][0] * x
		+ self.textureVecs[s][1] * y
		+ self.textureVecs[s][2] * z
		+ self.textureVecs[s][3])
		/ self.TexData.width,
		(self.textureVecs[t][0] * x
		+ self.textureVecs[t][1] * y
		+ self.textureVecs[t][2] * z
		+ self.textureVecs[t][3])
		/ self.TexData.height
end

local function read(arg)
	if isstring(arg) then
		if arg == "UShort" then
			local n = bsp.bsp:ReadShort()
			return n + (n < 0 and 65536 or 0)
		elseif arg == "ULong" then
			local n = bsp.bsp:ReadLong()
			return n + (n < 0 and 4294967296 or 0)
		elseif arg == "Vector" then
			local x = bsp.bsp:ReadFloat()
			local y = bsp.bsp:ReadFloat()
			local z = bsp.bsp:ReadFloat()
			return Vector(x, y, z)
		else
			return bsp.bsp["Read" .. arg](bsp.bsp)
		end
	else
		return bsp.bsp:Read(arg)
	end
end

function bsp:Init()
	self.bspname = "maps/" .. game.GetMap() .. ".bsp"
	assert(file.Exists(self.bspname, "GAME"), "SplatoonSWEPs: " .. tostring(self.bspname) .. " was not found!")
	self.bsp = file.Open(self.bspname, "rb", "GAME")
	
	self:ReadHeader()
	-- self:Parse(LUMP.ENTITIES)
	self:Parse(LUMP.PLANES)
	self:Parse(LUMP.VERTEXES)
	self:Parse(LUMP.EDGES)
	self:Parse(LUMP.SURFEDGES)
	
	self:Parse(LUMP.TEXDATA)
	self:Parse(LUMP.TEXINFO)
	
	self:Parse(LUMP.FACES)
	self:Parse(LUMP.FACES_HDR)
	
	self:Parse(LUMP.DISP_VERTS)
	self:Parse(LUMP.DISPINFO)
	
	self:Parse(LUMP.LEAFS)
	self:Parse(LUMP.NODES)
	self:Parse(LUMP.MODELS)
	self:BuildDisplacements()
	
	self.Ready = true
	self.bsp = nil
end

function bsp:GetLump(i)
	return self.header.lumps[i]
end

function bsp:ReadHeader()
	self.header = {lumps = {}}
	self.bsp:Seek(0)
	self.header.identifier = read(4)
	self.header.version = read("Long")
	assert(self.header.identifier == "VBSP", "SplatoonSWEPs(Parsing map): BSP Identifier is incorrect! (" .. self.bspname .. ")")
	
	for i = 0, 63 do
		self.header.lumps[i] = {}
		self.header.lumps[i].data = {}
		self.header.lumps[i].parsed = false
		self.header.lumps[i].offset = read("Long")
		self.header.lumps[i].length = read("Long")
		self.header.lumps[i].version = read("Long")
		self.header.lumps[i].fourCC = read(4)
	end
	self.header.revision = read("Long")
end

function bsp:Parse(parse_type)
	local lump = self:GetLump(parse_type or "nil")
	if parse_type and lump and isfunction(self.ParseFunction[parse_type]) then
		self.bsp:Seek(lump.offset)
		self.ParseFunction[parse_type](lump)
		lump.parsed = true
	end
end

bsp.ParseFunction = {
	[LUMP.ENTITIES] = function(lump)
		lump.data.str = read(lump.length)
		for s in lump.data.str:gmatch("%{.-%}") do
			table.insert(lump.data, util.KeyValuesToTable('"xd"\r\n' .. s))
		end
	end,

	[LUMP.PLANES] = function(lump)
		local size = 20
		lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].normal = read("Vector")
			lump.data[i].distance = read("Float")
			lump.data[i].Origin = lump.data[i].normal * lump.data[i].distance
			lump.data[i].type = read("Long")
		end
	end,

	[LUMP.VERTEXES] = function(lump)
		local size = 12
		lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
		for i = 0, lump.num do
			lump.data[i] = read("Vector")
		end
	end,

	[LUMP.EDGES] = function(lump)
		local size = 4
		lump.num = math.min(math.floor(lump.length / size) - 1, 256000 - 1)
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i][1] = read("UShort")
			lump.data[i][2] = read("UShort")
		end
	end,

	[LUMP.SURFEDGES] = function(lump)
		local size = 4
		local vertexes = bsp:GetLump(LUMP.VERTEXES)
		local edges = bsp:GetLump(LUMP.EDGES)
		lump.num = math.min(math.floor(lump.length / size) - 1, 512000 - 1)
		for i = 0, lump.num do
			local n = read("Long")
			local an = math.abs(n)
			local edge = edges.data[an]
			local v1, v2 = edge[1], edge[2]
			if n < 0 then v1, v2 = v2, v1 end
			lump.data[i] = {start = vertexes.data[v1], endpos = vertexes.data[v2]}
		end
	end,

	[LUMP.TEXDATA] = function(lump)
		local size = 32
		local strdata = bsp:GetLump(LUMP.TEXDATA_STRING_DATA)
		local strtable = bsp:GetLump(LUMP.TEXDATA_STRING_TABLE)
		lump.num = math.min(math.floor(lump.length / size) - 1, 2048 - 1)
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].refrectivity = read("Vector")
			local strID = read("Long") * 4
			lump.data[i].width = read("Long")
			lump.data[i].height = read("Long")
			lump.data[i].view_width = read("Long")
			lump.data[i].view_height = read("Long")
			lump.data[i].name = ""
			
			local here = bsp.bsp:Tell()
			bsp.bsp:Seek(strtable.offset + strID)
			local stroffset = read("Long")
			bsp.bsp:Seek(strdata.offset + stroffset)
			for _ = 1, 128 do
				local chr = read(1)
				if chr == '\x00' then break end
				lump.data[i].name = lump.data[i].name .. chr
			end
			
			bsp.bsp:Seek(here)
		end
	end,

	[LUMP.TEXINFO] = function(lump)
		local size = 72
		local TexData = bsp:GetLump(LUMP.TEXDATA)
		local s, t = 0, 1
		lump.num = math.min(math.floor(lump.length / size) - 1, 12288 - 1)
		for i = 0, lump.num do
			local here = bsp.bsp:Tell()
			bsp.bsp:Seek(here + size - 4)
			lump.data[i] = setmetatable({}, texture_structure)
			lump.data[i].textureVecs = {[0] = {}, [1] = {}}
			lump.data[i].lightmapVecs = {[0] = {}, [1] = {}}
			lump.data[i].texdataID = read("Long")
			if lump.data[i].texdataID >= 0 then
				bsp.bsp:Seek(here)
				lump.data[i].textureVecs[s][0] = read("Float")
				lump.data[i].textureVecs[s][1] = read("Float")
				lump.data[i].textureVecs[s][2] = read("Float")
				lump.data[i].textureVecs[s][3] = read("Float")
				lump.data[i].textureVecs[t][0] = read("Float")
				lump.data[i].textureVecs[t][1] = read("Float")
				lump.data[i].textureVecs[t][2] = read("Float")
				lump.data[i].textureVecs[t][3] = read("Float")
				
				lump.data[i].lightmapVecs[s][0] = read("Float")
				lump.data[i].lightmapVecs[s][1] = read("Float")
				lump.data[i].lightmapVecs[s][2] = read("Float")
				lump.data[i].lightmapVecs[s][3] = read("Float")
				lump.data[i].lightmapVecs[t][0] = read("Float")
				lump.data[i].lightmapVecs[t][1] = read("Float")
				lump.data[i].lightmapVecs[t][2] = read("Float")
				lump.data[i].lightmapVecs[t][3] = read("Float")
			
				lump.data[i].flags = read("Long")
				lump.data[i].TexData = TexData.data[t.texdataID]
				bsp.bsp:Skip(4) --texdataID
			end
		end
	end,

	[LUMP.FACES] = function(lump)
		local size = 56
		local planes = bsp:GetLump(LUMP.PLANES)
		local surfedges = bsp:GetLump(LUMP.SURFEDGES)
		local texinfo = bsp:GetLump(LUMP.TEXINFO)
		lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].OriginalFace = nil
			lump.data[i].plane = read("UShort")
			lump.data[i].side = read("Byte")
			lump.data[i].onNode = read("Byte") == 1
			lump.data[i].firstedge = read("Long")
			lump.data[i].numedges = read("Short")
			lump.data[i].textureinfo = read("Short")
			lump.data[i].dispinfo = read("Short")
			lump.data[i].surfaceFogVolumeID = read("Short")
			lump.data[i].styles = read(4)
			lump.data[i].lightmapid = read("Long")
			lump.data[i].area = read("Float")
			lump.data[i].LightmapTextureMinsInLuxels = {}
			lump.data[i].LightmapTextureMinsInLuxels[1] = read("Long")
			lump.data[i].LightmapTextureMinsInLuxels[2] = read("Long")
			lump.data[i].LightmapTextureSizeInLuxels = {}
			lump.data[i].LightmapTextureSizeInLuxels[1] = read("Long")
			lump.data[i].LightmapTextureSizeInLuxels[2] = read("Long")
			lump.data[i].origFace = read("Long")
			lump.data[i].numPrims = read("UShort")
			lump.data[i].firstPrimID = read("UShort")
			lump.data[i].smoothingGroups = read("ULong")
			
			lump.data[i].index = i
			lump.data[i].TexInfoTable = texinfo.data[lump.data[i].textureinfo]
			lump.data[i].PlaneTable = planes.data[lump.data[i].plane]
			lump.data[i].PlaneOrigin = lump.data[i].PlaneTable.Origin
			lump.data[i].normal = lump.data[i].PlaneTable.normal
			lump.data[i].angle = lump.data[i].normal:Angle()
			
			local v2d = {}
			lump.data[i].mins = Vector(math.huge, math.huge, math.huge)
			lump.data[i].maxs = -mins
			lump.data[i].Vertices = {}
			for k = 0, lump.data[i].numedges - 1 do
				local v = surfedges.data[lump.data[i].firstedge + k].start
				lump.data[i].maxs.x = math.max(maxs.x, v.x) --Calculate bounding box
				lump.data[i].maxs.y = math.max(maxs.y, v.y)
				lump.data[i].maxs.z = math.max(maxs.z, v.z)
				lump.data[i].mins.x = math.min(mins.x, v.x)
				lump.data[i].mins.y = math.min(mins.y, v.y)
				lump.data[i].mins.z = math.min(mins.z, v.z)
				
				lump.data[i].Vertices[k] = v
				table.insert(v2d, SZL.Vector3DTo2D(WorldToLocal(v, angle_zero,
					lump.data[i].PlaneOrigin, lump.data[i].angle), nil))
			end
			
			lump.data[i].Polygon = SZL.Polygon(i, v2d)
			if lump.data[i].TexInfoTable.flags and bit.band(lump.data[i].TexInfoTable.flags,
				bit.bor(SURF_SKY, SURF_WARP, SURF_NOPORTAL, SURF_TRIGGER, SURF_NODRAW, SURF_HINT, SURF_SKIP)) == 0 then
				if lump.data[i].dispinfo < 0 then
					if SplatoonSWEPs.Surfaces[lump.data[i].plane] then
						local m = SplatoonSWEPs.Surfaces[lump.data[i].plane]
						m.Polygon = m.Polygon + lump.data[i].Polygon
						m.mins, m.maxs = SplatoonSWEPs:GetBoundingBox(0, {m.mins, m.maxs, lump.data[i].mins, lump.data[i].maxs})
					else
						SplatoonSWEPs.Surfaces[lump.data[i].plane] = {
							mins = lump.data[i].mins,
							maxs = lump.data[i].maxs,
							normal = lump.data[i].normal,
							angle = lump.data[i].angle,
							origin = lump.data[i].Vertices[0],
							Vertices = lump.data[i].Vertices,
							Polygon = lump.data[i].Polygon,
						}
					end
				end
			end
		end
	end,

	[LUMP.DISP_VERTS] = function(lump)
		local size = 4 * 5
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].vec = read("Vector")
			lump.data[i].dist = read("Float")
			lump.data[i].alpha = read("Float")
		end
	end,

	[LUMP.DISPINFO] = function(lump)
		local size = 176
		local faces = bsp:GetLump(LUMP.FACES)
		local dispverts = bsp:GetLump(LUMP.DISP_VERTS)
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			bsp.bsp:Seek(lump.offset + i * size)
			lump.data[i] = {}
			lump.data[i].startPosition = read("Vector")
			lump.data[i].DispVertStart = read("Long")
			lump.data[i].DispTriStart = read("Long")
			lump.data[i].power = read("Long")
			lump.data[i].minTess = read("Long")
			lump.data[i].smoothingAngle = read("Float")
			lump.data[i].contents = read("Long")
			lump.data[i].MapFace = read("UShort")
			
			lump.data[i].Face = faces.data[disp.MapFace]
			lump.data[i].Face.DispInfoTable = lump.data[i]
			lump.data[i].DispVerts = {}
			for k = 0, (2^lump.data[i].power + 1)^2 - 1 do
				lump.data[i].DispVerts[k] = dispverts.data[lump.data[i].DispVertStart + k]
			end
			
			--Listing up each displacement's vertex
			local DISP_MIN_BOUND = 10
			local disp = lump.data[i]
			local dispface = disp.Face
			local dispverts = disp.DispVerts
			local verts = table.Copy(dispface.Vertices)
			local numverts = table.Count(verts)
			if numverts ~= 4 then continue end
			
			--DispInfo.startPosition isn't always equal to the first edge so let's find correct one
			local indices, mindist, dist, startedge = {}, math.huge, 0, 0
			for k = 0, numverts - 1 do
				dist = disp.startPosition:DistToSqr(verts[k])
				if dist < mindist then
					startedge = k
					mindist = dist
				end
			end
			
			for k = 0, numverts - 1 do
				indices[k] = (k + startedge) % numverts
			end
			
			verts[0],
			verts[1],
			verts[2],
			verts[3]
			=	verts[indices[0]],
				verts[indices[1]],
				verts[indices[2]],
				verts[indices[3]]
			
			local power = 2^disp.power + 1
			local u1 = verts[3] - verts[0]
			local u2 = verts[2] - verts[1]
			local v1 = verts[1] - verts[0]
			local v2 = verts[2] - verts[3]
			local div1, div2 -- vector_origin, vector_origin
			disp.mins = Vector(math.huge, math.huge, math.huge)
			disp.maxs = -disp.mins
			for k, w in pairs(dispverts) do --Get the world positions of the displacements
				x = k % power --0 <= x <= power
				y = math.floor(k / power) --0 <= y <= power
				div1, div2 = v1 * y / (power - 1), u1 + v2 * y / (power - 1)
				div2 = div2 - div1
				w.origin = div1 + div2 * x / (power - 1)
				w.pos = disp.startPosition + w.origin + w.vec * w.dist
				disp.maxs.x = math.max(disp.maxs.x, w.pos.x) --Calculate bounding box
				disp.maxs.y = math.max(disp.maxs.y, w.pos.y)
				disp.maxs.z = math.max(disp.maxs.z, w.pos.z)
				disp.mins.x = math.min(disp.mins.x, w.pos.x)
				disp.mins.y = math.min(disp.mins.y, w.pos.y)
				disp.mins.z = math.min(disp.mins.z, w.pos.z)
			end
			
			--Generate triangles from displacement mesh.
			disp.Triangles = {}
			local surf = {}
			for k = 0, #dispverts do
				local row = math.floor(k / power)
				local tri_inv = k % 2 == 0
				if k % power < power - 1 and row < power - 1 then
					local x, y, z = k, k + 1, k + power
					if tri_inv then z = z + 1 end
					local vert = {dispverts[x].pos, dispverts[y].pos, dispverts[z].pos}
					local normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
					if normal:Dot(dispface.normal) < 0 then
						normal = -normal
						vert[2], vert[3] = vert[3], vert[2]
					end
					local v2d, mins = {}, Vector(math.huge, math.huge, math.huge)
					local maxs = -mins
					for vi, v in ipairs(vert) do
						v2d[vi] = SZL.Vector3DTo2D(WorldToLocal(v, angle_zero, vert[1], normal:Angle()), nil)
						maxs.x = math.max(maxs.x, v.x - DISP_MIN_BOUND) --Calculate bounding box
						maxs.y = math.max(maxs.y, v.y - DISP_MIN_BOUND)
						maxs.z = math.max(maxs.z, v.z - DISP_MIN_BOUND)
						mins.x = math.min(mins.x, v.x + DISP_MIN_BOUND)
						mins.y = math.min(mins.y, v.y + DISP_MIN_BOUND)
						mins.z = math.min(mins.z, v.z + DISP_MIN_BOUND)
					end
					table.insert(disp.Triangles, {
						Vertices = {[0] = vert[1], [1] = vert[2], [2] = vert[3]},
						normal = normal,
						angle = normal:Angle(),
						Polygon = SZL.Polygon(facenum, v2d),
						mins = mins,
						maxs = maxs,
						index = facenum,
					})
					
					x, y, z = k + power + 1, k + power, k
					if not tri_inv then z = z + 1 end
					vert = {dispverts[x].pos, dispverts[y].pos, dispverts[z].pos}
					normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
					if normal:Dot(dispface.normal) < 0 then
						normal = -normal
						vert[2], vert[3] = vert[3], vert[2]
					end
					mins = Vector(math.huge, math.huge, math.huge)
					maxs = -mins
					for vi, v in ipairs(vert) do
						v2d[vi] = SZL.Vector3DTo2D(WorldToLocal(v, angle_zero, vert[1], normal:Angle()), nil)
						maxs.x = math.max(maxs.x, v.x - DISP_MIN_BOUND) --Calculate bounding box
						maxs.y = math.max(maxs.y, v.y - DISP_MIN_BOUND)
						maxs.z = math.max(maxs.z, v.z - DISP_MIN_BOUND)
						mins.x = math.min(mins.x, v.x + DISP_MIN_BOUND)
						mins.y = math.min(mins.y, v.y + DISP_MIN_BOUND)
						mins.z = math.min(mins.z, v.z + DISP_MIN_BOUND)
					end
					table.insert(disp.Triangles, {
						Vertices = {[0] = vert[1], [1] = vert[2], [2] = vert[3]},
						normal = normal,
						angle = normal:Angle(),
						Polygon = SZL.Polygon(facenum + 1, v2d),
						mins = mins,
						maxs = maxs,
						index = facenum + 1,
					})
					
					facenum = facenum + 2
				end
			end
			
			for _, t in ipairs(disp.Triangles) do
				local existing
				for k, m in pairs(SplatoonSWEPs.Surfaces) do
					if not isnumber(k) and m.normal:IsEqualTol(t.normal, 0.1) and
						math.abs(m.normal:Dot(t.Vertices[0] - m.origin)) < 1e-10 then	
						existing = m
						break
					end
				end
				
				if existing then
					local newverts = {}
					for k, v in ipairs(t.Vertices) do
						newverts[k] = SZL.Vector3DTo2D(WorldToLocal(v, angle_zero, existing.origin, existing.angle), nil)
					end
					existing.Polygon = existing.Polygon + SZL.Polygon(t.Polygon.tag, newverts)
					existing.mins, existing.maxs = SplatoonSWEPs:GetBoundingBox(0, {existing.mins, existing.maxs, t.mins, t.maxs})
				else
					SplatoonSWEPs.Surfaces[tostring(t.normal)] = {
						mins = t.mins,
						maxs = t.maxs,
						normal = t.normal,
						angle = t.angle,
						origin = t.Vertices[0],
						Vertices = t.Vertices,
						Polygon = t.Polygon,
					}
				end
			end
		end
	end,
	
	[LUMP.NODES] = function(lump)
		local size = 32
		local faces = bsp:GetLump(LUMP.FACES)
		local leafs = bsp:GetLump(LUMP.LEAFS)
		lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
		for i = 0, lump.num do
			local x, y, z
			lump.data[i] = setmetatable({}, NodeMeta)
			lump.data[i].FaceTable = {}
			lump.data[i].ChildNodes = {}
			lump.data[i].IsLeaf = false
			lump.data[i].planenum = read("Long")
			lump.data[i].children = {}
			lump.data[i].children[1] = read("Long")
			lump.data[i].children[2] = read("Long")
			x = read("Short")
			y = read("Short")
			z = read("Short")
			lump.data[i].mins = Vector(x, y, z)
			x = read("Short")
			y = read("Short")
			z = read("Short")
			lump.data[i].maxs = Vector(x, y, z)
			lump.data[i].firstface = read("UShort")
			lump.data[i].numfaces = read("UShort")
			lump.data[i].area = read("Short")
			lump.data[i].padding = read("Short")
			
			lump.data[i].Separator = planes.data[lump.data[i].planenum]
			for k = 0, lump.data[i].numfaces - 1 do
				lump.data[i].FaceTable[k] = faces.data[lump.data[i].firstface + k]
			end
		end
		
		for i = 0, lump.num do
			for k = 1, 2 do
				local child = lump.data[i].children[k]
				if child < 0 then
					lump.data[i].ChildNodes[k] = leafs.data[-child - 1]
				else
					lump.data[i].ChildNodes[k] = lump.data[child]
				end
			end
		end
	end,
	
	[LUMP.LEAFS] = function(lump)
		local size = 32
		local faces = bsp:GetLump(LUMP.FACES)
		local leaffaces = bsp:GetLump(LUMP.LEAFFACES)
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			local x, y, z
			lump.data[i] = {}
			lump.data[i].FaceTable = {}
			lump.data[i].BrushTable = {}
			lump.data[i].IsLeaf = true
			lump.data[i].index = i
			lump.data[i].contents = read("Long")
			lump.data[i].cluster = read("Short")
			local areaflags = read("Short")
			lump.data[i].area = bit.band(areaflags, 0x01FF)
			lump.data[i].flags = bit.band(bit.rshift(areaflags, 9), 0x007F)
			x = read("Short")
			y = read("Short")
			z = read("Short")
			lump.data[i].mins = Vector(x, y, z)
			x = read("Short")
			y = read("Short")
			z = read("Short")
			lump.data[i].maxs = Vector(x, y, z)
			lump.data[i].firstleafface = read("UShort")
			lump.data[i].numleaffaces = read("UShort")
			lump.data[i].firstleafbrush = read("UShort")
			lump.data[i].numleafbrushes = read("UShort")
			lump.data[i].leafWaterDataID = read("Short")
			lump.data[i].padding = read("Short")
			
			local here = bsp.bsp:Tell()
			for k = 0, lump.data[i].numleaffaces - 1 do
				bsp.bsp:Seek(leaffaces.offset + 2 * (lump.data[i].firstleafface + k]))
				lump.data[i].FaceTable[k] = faces.data[read("UShort")]
			end
			bsp.bsp:Seek(here)
		end
	end,

	[LUMP.MODELS] = function(lump)
		local size = 4 * 12
		local nodes = bsp:GetLump(LUMP.NODES)
		local faces = bsp:GetLump(LUMP.FACES)
		lump.num = math.min(math.floor(lump.length / size) - 1, 1024 - 1)
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].mins = read("Vector")
			lump.data[i].maxs = read("Vector")
			lump.data[i].origin = read("Vector")
			lump.data[i].headnode = read("Long")
			lump.data[i].firstface = read("Long")
			lump.data[i].numfaces = read("Long")
			
			lump.data[i].FaceTable = {}
			lump.data[i].RootNode = nodes.data[lump.data[i].headnode]
			for k = 0, lump.data[i].numfaces - 1 do
				lump.data[i].FaceTable[k] = faces.data[lump.data[i].firstface + k]
			end
		end
	end,
}
bsp.ParseFunction[LUMP.FACES_HDR] = bsp.ParseFunction[LUMP.FACES]

function bsp:GetWorldRoot()
	local lump = self:GetLump(LUMP.MODELS)
	return lump.data[0].RootNode
end

function bsp:GetNodeBound(mins, maxs)
	local node = self:GetWorldRoot()
	while not (node.IsLeaf or node:Across(mins, maxs)) do
		node = node:GetChildren(mins)
	end
	return node
end

function bsp:GetOriginalFaces(mins, maxs)
	local faces = {}
	local node = self:GetNodeBound(mins, maxs)
	for i, f in ipairs(node.FaceTable) do
		faces[f.OriginalFace] = true
	end
	return faces
end

function SplatoonSWEPs.ShowDisplacement()
	local dd = 101
	for d = dd, dd do
		local disp = bsp:GetLump(LUMP.DISPINFO).data[d]
		for i = 0, #disp.DispVerts do
			local v = disp.DispVerts[i]
			debugoverlay.Line(v.pos, v.pos + v.vec * 100, 5, Color(0, 255, 0), true)
			debugoverlay.Text(v.pos, i, 5)
		end
	end
end

function SplatoonSWEPs.ShowFace()
	local dd = 3000
	local lump = bsp:GetLump(LUMP.FACES).data
	for d = dd, dd + 3000 do
		local face = lump[d]
		local v, n = face.Vertices, face.PlaneTable.normal
		for i = 0, face.numedges - 1 do
			debugoverlay.Line(v[i], v[i] + n * 50, 5, Color(0, 255, 0), false)
			debugoverlay.Line(v[i] + n, v[i % (face.numedges - 1) + 1] + n, 5, Color(0, 255, 0), false)
			-- debugoverlay.Text(v[i], i, 5)
		end
	end
end
