if not SplatoonSWEPs then return end
SplatoonSWEPs.BSP = SplatoonSWEPs.BSP or {}
SplatoonSWEPs.LUMP = SplatoonSWEPs.LUMP or {
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

local function unsigned(value, bits)
	if value < 0 then 
		return math.abs(value) + 2^(bits - 1)
	else
		return value
	end
end

local function read(arg)
	if isstring(arg) then
		if arg == "UShort" then
			return unsigned(bsp.bsp:ReadShort(), 16)
		elseif arg == "ULong" then
			return unsigned(bsp.bsp:ReadLong(), 32)
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
	self:Parse(LUMP.ENTITIES)
	self:Parse(LUMP.PLANES)
	self:Parse(LUMP.VERTEXES)
	self:Parse(LUMP.EDGES)
	self:Parse(LUMP.SURFEDGES)
	self:Parse(LUMP.FACES)
	local lump = self:GetLump(LUMP.FACES_HDR)
	if lump.length > 0 then
		self.bsp:Seek(lump.offset)
		self.ParseFunction[LUMP.FACES](lump)
		lump.parsed = true
	end
	self:Parse(LUMP.TEXDATA)
	self:Parse(LUMP.TEXINFO)
	self:Parse(LUMP.MODELS)
	self:Parse(LUMP.BRUSHES)
	self:Parse(LUMP.BRUSHSIDES)
	self:Parse(LUMP.DISPINFO)
	self:Parse(LUMP.DISP_VERTS)
	self:Parse(LUMP.DISP_TRIS)
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
	assert(self.header.identifier == "VBSP", "BSP Identifier is incorrect! (" .. tostring(self.bspname) .. ")")
	
	for i = 0, 63 do
		local l = {}
		l.offset = read("Long")
		l.length = read("Long")
		l.version = read("Long")
		l.fourCC = read(4)
		l.data = {}
		l.parsed = false
		self.header.lumps[i] = l
	end
	self.header.revision = read("Long")
end

function bsp:Parse(parse_type)
	if not (parse_type and self:GetLump(parse_type) and isfunction(self.ParseFunction[parse_type])) then return end
	local lump = self:GetLump(parse_type)
	self.bsp:Seek(lump.offset)
	self.ParseFunction[parse_type](lump)
	lump.parsed = true
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
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = {}
			lump.data[i].normal = read("Vector")
			lump.data[i].distance = read("Float")
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
		lump.num = math.floor(lump.length / size) - 1
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
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			local f = {}
			f.PlaneTable = nil
			f.DispInfoTable = nil
			f.TexInfoTable = nil
			f.Vertices = {}
			f.plane = read("UShort")
			f.side = read("Byte")
			f.mode = read("Byte")
			f.firstedge = read("Long")
			f.numedges = read("Short")
			f.textureinfo = read("Short")
			f.dispinfo = read("Short")
			f.surfaceFogVolumeID = read("Short")
			f.styles = read(4)
			f.lightmapid = read("Long")
			f.area = read("Float")
			f.LightmapTextureMinsInLuxels = {}
			f.LightmapTextureSizeInLuxels = {}
			table.insert(f.LightmapTextureMinsInLuxels, read("Long"))
			table.insert(f.LightmapTextureMinsInLuxels, read("Long"))
			table.insert(f.LightmapTextureSizeInLuxels, read("Long"))
			table.insert(f.LightmapTextureSizeInLuxels, read("Long"))
			f.origFace = read("Long")
			f.numPrims = read("UShort")
			f.firstPrimID = read("UShort")
			f.smoothingGroups = read("ULong")
			lump.data[i] = f
		end
	end,

	[LUMP.EDGES] = function(lump)
		local size = 4
		lump.num = math.floor(lump.length / size) - 1
		for i = 0, lump.num do
			lump.data[i] = {}
			table.insert(lump.data[i], read("UShort"))
			table.insert(lump.data[i], read("UShort"))
		end
	end,

	[LUMP.SURFEDGES] = function(lump)
		local size = 4
		lump.num = math.floor(lump.length / size) - 1
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
			local r = {}
			r.FaceTable = {}
			r.mins = read("Vector")
			r.maxs = read("Vector")
			r.origin = read("Vector")
			r.headnode = read("Long")
			r.firstface = read("Long")
			r.numfaces = read("Long")
			lump.data[i] = r
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
}

function bsp:GetSortedSurfEdge(i)
	local surfdata = self:GetLump(LUMP.SURFEDGES).data[i]
	local edgedata = self:GetLump(LUMP.EDGES).data[surfdata[1]]
	local v1, v2 = edgedata[1], edgedata[2]
	if not surfdata[2] then v1, v2 = v2, v1 end
	return v1, v2
end

function bsp:BuildStructures()
	local planes = self:GetLump(LUMP.PLANES)
	local vertexes = self:GetLump(LUMP.VERTEXES)
	local edges = self:GetLump(LUMP.EDGES)
	local surfedges = self:GetLump(LUMP.SURFEDGES)
	local face = self:GetLump(LUMP.FACES)
	local facehdr = self:GetLump(LUMP.FACES_HDR)
	local texinfo = self:GetLump(LUMP.TEXINFO)
	local models = self:GetLump(LUMP.MODELS)
	local brushes = self:GetLump(LUMP.BRUSHES)
	local brushsides = self:GetLump(LUMP.BRUSHSIDES)
	local dispinfo = self:GetLump(LUMP.DISPINFO)
	local dispverts = self:GetLump(LUMP.DISP_VERTS)
	local disptris = self:GetLump(LUMP.DISP_TRIS)
	if not (planes.parsed and
			vertexes.parsed and
			edges.parsed and
			surfedges.parsed and
			face.parsed and
			texinfo.parsed and
			models.parsed and
			brushes.parsed and
			brushsides.parsed and
			dispinfo.parsed and
			dispverts.parsed and
			disptris.parsed) then
		return
	end
	
	for i = 0, surfedges.num do
		local edge = edges.data[surfedges.data[i].index]
		local v1, v2 = edge[1], edge[2]
		if surfedges.data[i].isbackward then v1, v2 = v2, v1 end
		surfedges.data[i].start, surfedges.data[i].endpos = vertexes.data[v1], vertexes.data[v2]
	end
	
	for i = 0, face.num do
		face.data[i].PlaneTable = planes.data[face.data[i].plane]
		face.data[i].DispInfoTable = dispinfo.data[face.data[i].dispinfo]
		face.data[i].TexInfoTable = texinfo.data[face.data[i].textureinfo]
		for k = 0, face.data[i].numedges - 1 do
			face.data[i].Vertices[k] = surfedges.data[face.data[i].firstedge + k].start
		end
	end
	
	if facehdr.parsed then
		for i = 0, facehdr.num do
			facehdr.data[i].PlaneTable = planes.data[facehdr.data[i].plane]
			facehdr.data[i].DispInfoTable = dispinfo.data[facehdr.data[i].dispinfo]
			facehdr.data[i].TexInfoTable = texinfo.data[facehdr.data[i].textureinfo]
			for k = 0, facehdr.data[i].numedges - 1 do
				facehdr.data[i].Vertices[k] = surfedges.data[facehdr.data[i].firstedge + k].start
			end
		end
	end
	
	for i = 0, dispinfo.num do
		for k = 0, (2^dispinfo.data[i].power + 1)^2 - 1 do
			dispinfo.data[i].DispVerts[k] = dispverts.data[dispinfo.data[i].DispVertStart + k]
		end
		for k = 0, 2 * (2^dispinfo.data[i].power)^2 - 1 do
			dispinfo.data[i].DispTris[k] = disptris.data[dispinfo.data[i].DispTriStart + k]
		end
		dispinfo.data[i].Face = face.data[dispinfo.data[i].MapFace]
	end
	
	for i = 0, brushsides.num do
		brushsides.data[i].PlaneTable = planes.data[brushsides.data[i].planenum]
		brushsides.data[i].TexInfoTable = texinfo.data[brushsides.data[i].textureinfo]
		brushsides.data[i].DispInfoTable = dispinfo.data[brushsides.data[i].dispinfo]
	end
	
	for i = 0, brushes.num do
		for k = 0, brushes.data[i].numsides - 1 do
			brushes.data[i].Brushsides[k] = brushsides.data[brushes.data[i].firstside + k]
		end
	end
	
	for i = 0, models.num do
		for k = 0, models.data[i].numfaces - 1 do
			models.data[i].FaceTable[k] = face.data[models.data[i].firstface + k]
		end
	end
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
		local indices, startedge, mindist, dist = {}, -1, math.huge, 0
		assert(numverts == 4, "SplatoonSWEPs: Displacement with " .. numverts .. "corners!")
		for k = 0, numverts - 1 do
			dist = disp.startPosition:DistToSqr(verts[k])
			if dist < mindist then
				startedge = k
				mindist = dist
			end
		end
		
		assert(startedge >= 0, "SplatoonSWEPs: Displacement's start position was not found!")
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

function ShowDisplacement()
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

function ShowFace()
	local dd = 3000
	for d = dd, dd + 3000 do
		local face = bsp:GetLump(LUMP.FACES).data[d]
		local v, n = face.Vertices, face.PlaneTable.normal
		for i = 0, face.numedges - 1 do
			debugoverlay.Line(v[i], v[i] + n * 50, 5, Color(0, 255, 0), false)
			debugoverlay.Line(v[i] + n, v[i % (face.numedges - 1) + 1] + n, 5, Color(0, 255, 0), false)
			-- debugoverlay.Text(v[i], i, 5)
		end
	end
end
