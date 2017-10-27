
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

local NodeFuncs = {}
local NodeMeta = {__index = NodeFuncs}
function NodeFuncs.GetChildren(self, pos)
	local planenormal = self.Separator.normal
	local planeorg = self.Separator.Origin
	local childindex = planenormal:Dot(pos - planeorg) > 0 and 1 or 2
	-- print(planenormal, planeorg, self.Separator.distance, childindex, pos)
	return self.ChildNodes[childindex], self.ChildNodes[3 - childindex]
end

function NodeFuncs.Across(self, mins, maxs, org)
	if org then mins, maxs = mins + org, maxs + org end
	local planenormal = self.Separator.normal
	local planeorg = self.Separator.Origin
	return planenormal:Dot(mins - planeorg) * planenormal:Dot(maxs - planeorg) < 0
end

local texture_structure = texture_structure or {}
local bsp = SplatoonSWEPs.BSP
local LUMP = SplatoonSWEPs.LUMP
function bsp.__index(self, i)
	return getmetatable(self)[i]
end

function texture_structure.__index(self, i)
	return getmetatable(self)[i]
end

function texture_structure:GetMaterial(scale)
	return self.Material or self:MakeMaterial()
end

function texture_structure:MakeMaterial()
	self.w = self.texdata.w
	self.h = self.texdata.h
	self.Material = CreateMaterial(tostring(self) .. "_texinfo", "UnlitGeneric", {
		["$basetexture"] = Material(self.texdata.name):GetTexture("$basetexture"):GetName(),
		["$detailscale"] = 1,
		["$reflectivity"] = self.texdata.reflectivity,
		["$model"] = 1,
	})
	return self.Material
end

function texture_structure:GenerateUV(x, y, z)
	return (self.vecs[0][3] + self.vecs[0][2] * z + self.vecs[0][1] * y + self.vecs[0][0] * x) / self.texdata.w,
		(self.vecs[1][3] + self.vecs[1][2] * z + self.vecs[1][1] * y + self.vecs[1][0] * x) / self.texdata.h
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
	assert(file.Exists(self.bspname, "GAME"), "SplatoonSWEPs: " .. tostring(self.bspname) .. " was not found!")
	self.bsp = file.Open(self.bspname, "rb", "GAME")
	
	self:ReadHeader()
	-- self:Parse(LUMP.ENTITIES)
	self:Parse(LUMP.PLANES)
	self:Parse(LUMP.VERTEXES)
	self:Parse(LUMP.EDGES)
	self:Parse(LUMP.SURFEDGES)
	self:Parse(LUMP.FACES)
	local lump = self:GetLump(LUMP.ORIGINALFACES)
	if lump.length > 0 then
		self.bsp:Seek(lump.offset)
		self.ParseFunction[LUMP.FACES](lump)
		lump.parsed = true
	end
	
	lump = self:GetLump(LUMP.FACES_HDR)
	if lump.length > 0 then
		self.bsp:Seek(lump.offset)
		self.ParseFunction[LUMP.FACES](lump)
		lump.parsed = true
	end
	-- self:Parse(LUMP.TEXDATA)
	-- self:Parse(LUMP.TEXINFO)
	self:Parse(LUMP.MODELS)
	-- self:Parse(LUMP.BRUSHES)
	-- self:Parse(LUMP.BRUSHSIDES)
	self:Parse(LUMP.DISPINFO)
	self:Parse(LUMP.DISP_VERTS)
	self:Parse(LUMP.DISP_TRIS)
	self:Parse(LUMP.NODES)
	self:Parse(LUMP.LEAFS)
	self:Parse(LUMP.LEAFFACES)
	-- self:Parse(LUMP.LEAFBRUSHES)
	self:BuildStructures()
	self:BuildDisplacements()
	
	self.Ready = true
end

function bsp:GetLump(i)
	return self.header.lumps[i]
end

function bsp:ReadHeader()
	self.header = {lumps = {}}
	self.bsp:Seek(0)
	self.header.identifier = read(4)
	self.header.version = read("Long")
	assert(self.header.identifier == "VBSP", "BSP Identifier is incorrect! (" .. self.bspname .. ")")
	
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

	[LUMP.TEXDATA] = function(lump)
		local size = 32
		local strdata = bsp:GetLump(LUMP.TEXDATA_STRING_DATA)
		local strtable = bsp:GetLump(LUMP.TEXDATA_STRING_TABLE)
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			local r = {}
			r.refrectivity = read("Vector")
			r.stringtableid = read("Long")
			r.w = read("Long")
			r.h = read("Long")
			r.vw = read("Long")
			r.vh = read("Long")
			
			local backup = bsp.bsp:Tell()
			bsp.bsp:Seek(strtable.offset + 4 * r.stringtableid)
			r.stringtableindex = read("Long")
			
			bsp.bsp:Seek(strdata.offset + r.stringtableindex)
			r.name = ""
			for i = 1, 260 do
				local chr = string.char(read("Byte"))
				if chr == '\x00' then break end
				r.name = r.name .. chr
			end
			
			lump.data[i] = r
			bsp.bsp:Seek(backup)
		end
	end,

	[LUMP.VERTEXES] = function(lump)
		local size = 12
		lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
		for i = 0, lump.num do
			lump.data[i] = read("Vector")
		end
	end,

	[LUMP.TEXINFO] = function(lump)
		local size = 72
		local texdata = bsp:GetLump(LUMP.TEXDATA).data
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			local t = {}
			t.vecs = {[0] = {}, [1] = {}}
			t.light = {[0] = {}, [1] = {}}
			
			t.vecs[0][0] = read("Float")
			t.vecs[0][1] = read("Float")
			t.vecs[0][2] = read("Float")
			t.vecs[0][3] = read("Float")
			
			t.vecs[1][0] = read("Float")
			t.vecs[1][1] = read("Float")
			t.vecs[1][2] = read("Float")
			t.vecs[1][3] = read("Float")
			
			t.light[0][0] = read("Float")
			t.light[0][1] = read("Float")
			t.light[0][2] = read("Float")
			t.light[0][3] = read("Float")
			
			t.light[1][0] = read("Float")
			t.light[1][1] = read("Float")
			t.light[1][2] = read("Float")
			t.light[1][3] = read("Float")
			
			t.flags = read("Long")
			t.texdataid = read("Long")
			t.texdata = texdata[t.texdataid]
			if not t.texdata then continue end
			lump.data[i] = setmetatable(t, texture_structure)
		end
	end,

	[LUMP.FACES] = function(lump)
		local size = 56
		lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
		for i = 0, lump.num do
			local f = {}
			f.PlaneTable = nil
			f.DispInfoTable = nil
			f.TexInfoTable = nil
			f.OriginalFace = nil
			f.Vertices = {}
			f.plane = read("UShort")
			f.side = read("Byte")
			f.onNode = read("Byte") == 1
			f.firstedge = read("Long")
			f.numedges = read("Short")
			f.textureinfo = read("Short")
			f.dispinfo = read("Short")
			f.surfaceFogVolumeID = read("Short")
			f.styles = read(4)
			f.lightmapid = read("Long")
			f.area = read("Float")
			f.LightmapTextureMinsInLuxels = {}
			f.LightmapTextureMinsInLuxels[1] = read("Long")
			f.LightmapTextureMinsInLuxels[2] = read("Long")
			f.LightmapTextureSizeInLuxels = {}
			f.LightmapTextureSizeInLuxels[1] = read("Long")
			f.LightmapTextureSizeInLuxels[2] = read("Long")
			f.origFace = read("Long")
			f.numPrims = read("UShort")
			f.firstPrimID = read("UShort")
			f.smoothingGroups = read("ULong")
			lump.data[i] = f
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
		lump.num = math.min(math.floor(lump.length / size) - 1, 512000 - 1)
		for i = 0, lump.num do
			local n = read("Long")
			lump.data[i] = {
				index = math.abs(n),
				isbackward = n < 0,
			}
		end
	end,

	[LUMP.MODELS] = function(lump)
		local size = 4 * 12
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].RootNode = nil
			lump.data[i].FaceTable = {}
			lump.data[i].mins = read("Vector")
			lump.data[i].maxs = read("Vector")
			lump.data[i].origin = read("Vector")
			lump.data[i].headnode = read("Long")
			lump.data[i].firstface = read("Long")
			lump.data[i].numfaces = read("Long")
		end
	end,

	[LUMP.BRUSHES] = function(lump)
		local size = 4 * 3
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].Brushsides = {}
			lump.data[i].firstside = read("Long")
			lump.data[i].numsides = read("Long")
			lump.data[i].contents = read("Long")
		end
	end,

	[LUMP.BRUSHSIDES] = function(lump)
		local size = 2 * 4
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].PlaneTable = nil
			lump.data[i].TexInfoTable = nil
			lump.data[i].DispInfoTable = nil
			lump.data[i].planenum = read("UShort")
			lump.data[i].textureinfo = read("Short")
			lump.data[i].dispinfo = read("Short")
			lump.data[i].bevel = read("Short")
		end
	end,

	[LUMP.DISPINFO] = function(lump)
		local size = 176
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			local t = {}
			bsp.bsp:Seek(lump.offset + i * size)
			t.startPosition = read("Vector")
			t.DispVerts = {}
			t.DispTris = {}
			t.Face = nil
			t.DispVertStart = read("Long")
			t.DispTriStart = read("Long")
			t.power = read("Long")
			t.minTess = read("Long")
			t.smoothingAngle = read("Float")
			t.contents = read("Long")
			t.MapFace = read("UShort")
			t.LightmapAlphaStart = read("Long")
			t.lightmapSamplePositionStart = read("Long")
			t.CDispNeightbor = {}
			for i = 0, 4 - 1 do
				t.CDispNeightbor[i] = {}
			end
			t.CDispCornerNeighbors = {}
			for i = 0, 4 - 1 do
				t.CDispCornerNeighbors[i] = {}
			end
			
			bsp.bsp:Seek(lump.offset + i * (size + 1) - 4 * 10)
			t.AllowedVerts = {}
			for i = 0, 10 - 1 do
				t.AllowedVerts[i] = read("ULong")
			end
			lump.data[i] = t
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

	[LUMP.DISP_TRIS] = function(lump)
		local size = 2
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].Tags = read("UShort")
		end
	end,
	
	[LUMP.NODES] = function(lump)
		local size = 32
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			local x, y, z
			lump.data[i] = setmetatable({}, NodeMeta)
			lump.data[i].FaceTable = {}
			lump.data[i].ChildNodes = {}
			lump.data[i].Separator = nil
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
		end
	end,
	
	[LUMP.LEAFS] = function(lump)
		local size = 32
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
		end
	end,
	
	[LUMP.LEAFFACES] = function(lump)
		local size = 2
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = read("UShort")
		end
	end,
	
	[LUMP.LEAFBRUSHES] = function(lump)
		local size = 2
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = read("UShort")
		end
	end,
}

function bsp:BuildStructures()
	local planes = self:GetLump(LUMP.PLANES)
	local vertexes = self:GetLump(LUMP.VERTEXES)
	local edges = self:GetLump(LUMP.EDGES)
	local surfedges = self:GetLump(LUMP.SURFEDGES)
	local face = self:GetLump(LUMP.FACES)
	local facehdr = self:GetLump(LUMP.FACES_HDR)
	local origface = self:GetLump(LUMP.ORIGINALFACES)
	local texinfo = self:GetLump(LUMP.TEXINFO)
	local models = self:GetLump(LUMP.MODELS)
	local brushes = self:GetLump(LUMP.BRUSHES)
	local brushsides = self:GetLump(LUMP.BRUSHSIDES)
	local dispinfo = self:GetLump(LUMP.DISPINFO)
	local dispverts = self:GetLump(LUMP.DISP_VERTS)
	local disptris = self:GetLump(LUMP.DISP_TRIS)
	local nodes = self:GetLump(LUMP.NODES)
	local leafs = self:GetLump(LUMP.LEAFS)
	local leaffaces = self:GetLump(LUMP.LEAFFACES)
	local leafbrushes = self:GetLump(LUMP.LEAFBRUSHES)
	
	if surfedges.parsed then
		for i = 0, surfedges.num do
			local edge = edges.data[surfedges.data[i].index]
			local v1, v2 = edge[1], edge[2]
			if surfedges.data[i].isbackward then v1, v2 = v2, v1 end
			surfedges.data[i].start, surfedges.data[i].endpos = vertexes.data[v1], vertexes.data[v2]
			assert(vertexes.data[v1] and vertexes.data[v2],
				"SplatoonSWEPs(Parsing current map): vertex not found!")
		end
	end
	
	for _, f in ipairs {origface, face, facehdr} do
		if f.parsed then
			for i = 0, f.num do
				f.data[i].PlaneTable = planes.data[f.data[i].plane]
				f.data[i].DispInfoTable = dispinfo.data[f.data[i].dispinfo]
				f.data[i].TexInfoTable = texinfo.data[f.data[i].textureinfo]
				f.data[i].OriginalFace = origface.data[f.data[i].origFace]
				for k = 0, f.data[i].numedges - 1 do
					f.data[i].Vertices[k] = surfedges.data[f.data[i].firstedge + k].start
				end
			end
		end
	end
	
	if dispinfo.parsed then
		for i = 0, dispinfo.num do
			for k = 0, (2^dispinfo.data[i].power + 1)^2 - 1 do
				dispinfo.data[i].DispVerts[k] = dispverts.data[dispinfo.data[i].DispVertStart + k]
			end
			-- for k = 0, 2 * (2^dispinfo.data[i].power)^2 - 1 do
				-- dispinfo.data[i].DispTris[k] = disptris.data[dispinfo.data[i].DispTriStart + k]
			-- end
			dispinfo.data[i].Face = face.data[dispinfo.data[i].MapFace]
		end
	end
	
	if brushsides.parsed then
		for i = 0, brushsides.num do
			brushsides.data[i].PlaneTable = planes.data[brushsides.data[i].planenum]
			brushsides.data[i].TexInfoTable = texinfo.data[brushsides.data[i].textureinfo]
			brushsides.data[i].DispInfoTable = dispinfo.data[brushsides.data[i].dispinfo]
		end
	end
	
	if brushes.parsed then
		for i = 0, brushes.num do
			for k = 0, brushes.data[i].numsides - 1 do
				brushes.data[i].Brushsides[k] = brushsides.data[brushes.data[i].firstside + k]
			end
		end
	end
	
	if nodes.parsed then
		for i = 0, nodes.num do
			nodes.data[i].Separator = planes.data[nodes.data[i].planenum]
			for k = 1, 2 do
				local child = nodes.data[i].children[k]
				if child < 0 then
					nodes.data[i].ChildNodes[k] = leafs.data[-child - 1]
				else
					nodes.data[i].ChildNodes[k] = nodes.data[child]
				end
			end
			
			for k = 0, nodes.data[i].numfaces - 1 do
				local f = face.data[nodes.data[i].firstface + k]
				if f then
					nodes.data[i].FaceTable[k] = f
				end
			end
		end
	end
	
	if leafs.parsed then
		for i = 0, leafs.num do
			for k = 0, leafs.data[i].numleaffaces - 1 do
				local f = face.data[leaffaces.data[leafs.data[i].firstleafface + k]]
				if f then
					leafs.data[i].FaceTable[k] = f
				end
			end
			
			-- for k = 0, leafs.data[i].numleafbrushes - 1 do
				-- leafs.data[i].BrushTable[k] = brushes.data[leafbrushes.data[leafs.data[i].firstleafbrush + k]]
			-- end
		end
	end
	
	if models.parsed then
		for i = 0, models.num do
			for k = 0, models.data[i].numfaces - 1 do
				models.data[i].RootNode = nodes.data[models.data[i].headnode]
				models.data[i].FaceTable[k] = face.data[models.data[i].firstface + k]
			end
		end
	end
	
	-- edges.data = {}
	-- surfedges.data = {}
	-- face.data = {}
	-- facehdr.data = {}
	-- origface.data = {}
	-- planes.data = {}
	-- vertexes.data = {}
	-- nodes.data = {}
	-- leaffaces.data = {}
	-- dispverts.data = {}
	-- disptris.data = {}
end

function bsp:BuildDisplacements()
	local dispinfo = self:GetLump(LUMP.DISPINFO)
	if not dispinfo.parsed then return end
	
	for i = 0, dispinfo.num do
		--DispInfo.startPosition isn't always equal to first edge so let's find the correct one
		local disp = dispinfo.data[i]
		local dispverts = disp.DispVerts
		local verts = table.Copy(disp.Face.Vertices)
		local numverts = table.Count(verts)
		if numverts ~= 4 then continue end
		
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
		local div1, div2 = vector_origin, vector_origin
		for k, w in pairs(dispverts) do --Get the world positions of the displacements
			x = k % power --0 <= x <= power
			y = math.floor(k / power) --0 <= y <= power
			div1, div2 = v1 * y / (power - 1), u1 + v2 * y / (power - 1)
			div2 = div2 - div1
			w.origin = div1 + div2 * x / (power - 1)
			w.pos = disp.startPosition + w.origin + w.vec * w.dist
		end
	end
end

function bsp:GetWorldRoot()
	assert(self.Ready, "BSP parsing system is not ready!")
	local lump = self:GetLump(LUMP.MODELS)
	return lump.data[0].RootNode
end

function bsp:GetNodeBound(mins, maxs)
	local node = self:GetWorldRoot()
	while not (node.IsLeaf or node:Across(mins, maxs)) do
		node = node:GetChild(mins)
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
