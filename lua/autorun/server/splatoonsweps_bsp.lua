
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

-- local NodeFuncs = {}
-- local NodeMeta = {__index = NodeFuncs}
-- function NodeFuncs.GetChildren(self, pos)
	-- local planenormal = self.Separator.normal
	-- local planeorg = self.Separator.Origin
	-- local childindex = planenormal:Dot(pos - planeorg) > 0 and 1 or 2
	-- return self.ChildNodes[childindex], self.ChildNodes[3 - childindex]
-- end

-- function NodeFuncs.Across(self, mins, maxs, org)
	-- org = org or vector_origin
	-- local planenormal = self.Separator.normal
	-- local planeorg = self.Separator.Origin
	-- local mindot, maxdot = math.huge, -math.huge
	-- for _, v in ipairs {
		-- mins, maxs,
		-- Vector(maxs.x, mins.y, mins.z),
		-- Vector(mins.x, maxs.y, mins.z),
		-- Vector(mins.x, mins.y, maxs.z),
		-- Vector(mins.x, maxs.y, maxs.z),
		-- Vector(maxs.x, mins.y, maxs.z),
		-- Vector(maxs.x, maxs.y, mins.z),
	-- } do
		-- local dot = planenormal:Dot(v + org - planeorg)
		-- mindot = math.min(mindot, dot)
		-- maxdot = math.max(maxdot, dot)
	-- end

	-- return mindot * maxdot < 0
-- end

local TextureMeta = {}
local bsp = SplatoonSWEPs.BSP
local LUMP = SplatoonSWEPs.LUMP
local FACE_MIN_SEGLEN_SQR = 1.5^2 --minimum length of line segment
local FACE_MIN_ANGLE = 0.1 --degrees
local FACE_MIN_SIN = math.sin(math.rad(FACE_MIN_ANGLE))
local DISP_MIN_BOUND = 10
local TextureFilterBits = bit.bor(SURF_SKY, SURF_WARP, SURF_NOPORTAL, SURF_TRIGGER, SURF_NODRAW, SURF_HINT, SURF_SKIP)
TextureMeta.__index = TextureMeta
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

function bsp:GetLump(i)
	return self.header.lumps[i]
end

function bsp:Init()
	self.bspname = "maps/" .. game.GetMap() .. ".bsp"
	self.bsp = file.Open(self.bspname, "rb", "GAME")

	self:ReadHeader()
	self:Parse(LUMP.PLANES)
	self:Parse(LUMP.VERTEXES)
	self:Parse(LUMP.EDGES)
	self:Parse(LUMP.SURFEDGES)

	self:Parse(LUMP.TEXDATA)
	self:Parse(LUMP.TEXINFO)

	self:Parse(LUMP.FACES)
	self:Parse(LUMP.DISPINFO)
	self.bsp = nil
end

function bsp:ReadHeader()
	self.header = {lumps = {}}
	self.bsp:Seek(8)
	for i = 0, 63 do
		self.header.lumps[i] = {}
		self.header.lumps[i].data = {}
		self.header.lumps[i].parsed = false
		self.header.lumps[i].offset = read("Long")
		self.header.lumps[i].length = read("Long")
		self.bsp:Skip(8)
	end
end

local function GetRotatedAABB(v2d, angle)
	local mins = Vector(math.huge, math.huge, 0)
	local maxs = -mins
	for k, v in ipairs(v2d) do
		v = Vector(v)
		v:Rotate(angle)
		mins.x = math.min(mins.x, v.x)
		mins.y = math.min(mins.y, v.y)
		maxs.x = math.max(maxs.x, v.x)
		maxs.y = math.max(maxs.y, v.y)
	end
	
	return mins, maxs
end

local function MakeSurface(key, mins, maxs, normal, angle, origin, v2d, v3d)
	if #v2d < 3 then return end
	local s, facetable = SplatoonSWEPs.Surfaces, {
		mins = mins,
		maxs = maxs,
		origin = origin,
		Vertices2D = v2d,
		Vertices = v3d,
	}
	
	if not s[key] then s[key] = {normal = normal, angle = angle} end
	table.insert(s[key], facetable)
	table.insert(SplatoonSWEPs.SortedSurfaces, facetable)
	
	local area, minangle, minmins = 0, nil, nil
	for i, v in ipairs(v2d) do --Get minimum AABB with O(n^2)
		local seg = v2d[i % #v2d + 1] - v
		local angle = Angle(0, 90 - math.deg(math.atan2(seg.y, seg.x)), 0)
		local mins, maxs = GetRotatedAABB(v2d, angle)
		local bound = maxs - mins
		local area = bound.x * bound.y
		if v2d.Area > area then
			minangle = angle
			if bound.x < bound.y then
				angle.yaw = angle.yaw - 90
				minmins, maxs = GetRotatedAABB(v2d, angle)
				v2d.bound = maxs - minmins
				v2d.Area = bound.x * bound.y
			else
				minangle = angle
				minmins = mins
				v2d.Area = area
				v2d.bound = bound
			end
		end
	end
	
	for i, v in ipairs(v2d) do
		area = area + v:Cross(v2d[i % #v2d + 1]).z
		v:Rotate(minangle)
		v:Sub(minmins)
	end
	
	s.Area = s.Area + math.abs(area) / 2
	s.AreaBound = s.AreaBound + v2d.Area
	s.LongestEdge = math.max(s.LongestEdge, v2d.bound.x, v2d.bound.y)
end

local function MakeDispTriangle(vert, planenormal)
	local normal = (vert[2] - vert[1]):Cross(vert[3] - vert[2]):GetNormalized()
	local angle = normal:Angle()
	local surfkey = tostring(normal)
	local origin = (vert[1] + vert[2] + vert[3]) / 3
	if normal:Dot(planenormal) < 0 then
		normal = -normal
		vert[2], vert[3] = vert[3], vert[2]
	end
	
	vert.mins = Vector(math.huge, math.huge, math.huge)
	vert.maxs = -mins
	local v2d = {Area = math.huge}
	for i, v in ipairs(vert) do
		vert.maxs.x = math.max(vert.maxs.x, v.x + DISP_MIN_BOUND) --Calculate bounding box
		vert.maxs.y = math.max(vert.maxs.y, v.y + DISP_MIN_BOUND)
		vert.maxs.z = math.max(vert.maxs.z, v.z + DISP_MIN_BOUND)
		vert.mins.x = math.min(vert.mins.x, v.x - DISP_MIN_BOUND)
		vert.mins.y = math.min(vert.mins.y, v.y - DISP_MIN_BOUND)
		vert.mins.z = math.min(vert.mins.z, v.z - DISP_MIN_BOUND)
		v2d[i] = WorldToLocal(v, angle_zero, origin, angle)
		v2d[i] = Vector(v2d[i].y, v2d[i].z, 0)
	end
	
	MakeSurface(surfkey, mins, maxs, normal, angle, origin, v2d, vert)
end

local ParseFunction = {
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
			lump.data[i].TexData = TexData.data[lump.data[i].texdataID]
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

		local PlaneTable = planes.data[lump.data[i].plane]
		lump.data[i].index = i
		lump.data[i].Vertices = {}
		lump.data[i].PlaneOrigin = PlaneTable.Origin
		lump.data[i].normal = PlaneTable.normal
		lump.data[i].angle = lump.data[i].normal:Angle()
		lump.data[i].TexInfoTable = texinfo.data[lump.data[i].textureinfo]
		
		local texname = lump.data[i].TexInfoTable.TexData.name:lower()
		if texname:find("tools/") or texname:find("water") or
			bit.band(lump.data[i].TexInfoTable.flags, TextureFilterBits) ~= 0 then
			continue
		end

		local fullverts, full2d, center = {}, {}, vector_origin
		for k = 0, lump.data[i].numedges - 1 do --Fetch all vertices
			fullverts[k] = surfedges.data[lump.data[i].firstedge + k].start
			center = center + fullverts[k]
		end
		center = center / (#fullverts + 1)
		
		for k, v in pairs(fullverts) do
			full2d[k] = WorldToLocal(v, angle_zero, center, lump.data[i].angle)
			full2d[k] = Vector(full2d[k].y, full2d[k].z, 0)
		end
		
		local v2d = {Area = math.huge} --Vector2D
		local nf = #full2d + 1
		local mins = Vector(math.huge, math.huge, math.huge)
		local maxs = -mins
		for k = 0, #full2d do --Remove collinear and concave components
			local v, v3d = full2d[k], fullverts[k]
			local _next, prev = full2d[(k + 1) % nf], full2d[(k + nf - 1) % nf]
			local sin = (prev - v):GetNormalized():Cross((_next - v):GetNormalized()).z
			if v:DistToSqr(_next) > FACE_MIN_SEGLEN_SQR and sin > FACE_MIN_SIN then
				maxs.x = math.max(maxs.x, v3d.x) --Calculate bounding box
				maxs.y = math.max(maxs.y, v3d.y)
				maxs.z = math.max(maxs.z, v3d.z)
				mins.x = math.min(mins.x, v3d.x)
				mins.y = math.min(mins.y, v3d.y)
				mins.z = math.min(mins.z, v3d.z)
				
				table.insert(v2d, v)
				table.insert(lump.data[i].Vertices, v3d)
			end
		end

		lump.data[i].mins, lump.data[i].maxs = mins, maxs
		lump.data[i].Vertices.mins, lump.data[i].Vertices.maxs = mins, maxs
		if lump.data[i].dispinfo > 0 then continue end
		MakeSurface(lump.data[i].plane, mins, maxs, lump.data[i].normal, lump.data[i].angle, center, v2d, lump.data[i].Vertices)
	end
end,

[LUMP.DISPINFO] = function(lump)
	local size = 176
	local faces = bsp:GetLump(LUMP.FACES)
	local dispvertsoffset = bsp:GetLump(LUMP.DISP_VERTS).offset
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

		lump.data[i].Face = faces.data[lump.data[i].MapFace]
		lump.data[i].Face.DispInfoTable = lump.data[i]
		lump.data[i].DispVerts = {}
		for k = 0, (2^lump.data[i].power + 1)^2 - 1 do
			bsp.bsp:Seek(dispvertsoffset + 20 * (lump.data[i].DispVertStart + k))
			lump.data[i].DispVerts[k] = {}
			lump.data[i].DispVerts[k].vec = read("Vector")
			lump.data[i].DispVerts[k].dist = read("Float")
		end

		--Listing up each displacement's vertex
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
		for k, w in pairs(dispverts) do --Get the world positions of the displacements
			x = k % power --0 <= x <= power
			y = math.floor(k / power) --0 <= y <= power
			div1, div2 = v1 * y / (power - 1), u1 + v2 * y / (power - 1)
			div2 = div2 - div1
			w.origin = div1 + div2 * x / (power - 1)
			w.pos = disp.startPosition + w.origin + w.vec * w.dist
		end
		
		--Generate triangles from displacement mesh.
		for k = 0, #dispverts do
			local tri_inv = k % 2 == 0
			if k % power < power - 1 and math.floor(k / power) < power - 1 then
				MakeDispTriangle({
					dispverts[k].pos,
					dispverts[k + 1].pos,
					dispverts[tri_inv and k + power + 1 or k + power].pos,
				}, dispface.normal)

				MakeDispTriangle({
					dispverts[k + power + 1].pos,
					dispverts[k + power].pos,
					dispverts[tri_inv and k or k + 1].pos,
				}, dispface.normal)
			end
		end
	end
end,}

function bsp:Parse(parse_type)
	local lump = self:GetLump(parse_type or "nil")
	if parse_type and lump and isfunction(ParseFunction[parse_type]) then
		self.bsp:Seek(lump.offset)
		ParseFunction[parse_type](lump)
		lump.parsed = true
	end
end
