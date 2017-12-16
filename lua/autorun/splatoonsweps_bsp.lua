
--This lua parses the bsp file of current map.
if not SplatoonSWEPs then return end
SplatoonSWEPs.BSP = SplatoonSWEPs.BSP or {}
local LUMP = {
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

local bsp = SplatoonSWEPs.BSP
local TextureFilterBits = SURF_SKY + SURF_WARP + SURF_NOPORTAL + SURF_TRIGGER + SURF_NODRAW + SURF_HINT + SURF_SKIP
local function read(arg)
	if isstring(arg) then
		if arg == "UShort" then
			local n = bsp.bsp:ReadShort()
			return n + (n < 0 and 65536 or 0)
		elseif arg == "ULong" then
			local n = bsp.bsp:ReadLong()
			return n + (n < 0 and 4294967296 or 0)
		elseif arg == "SignedByte" then
			local n = bsp.bsp:ReadByte()
			return n - (n > 127 and 256 or 0)
		elseif arg == "ShortVector" then
			local x = bsp.bsp:ReadShort()
			local y = bsp.bsp:ReadShort()
			local z = bsp.bsp:ReadShort()
			return Vector(x, y, z)
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
	self.FaceIndex = 0
	
	self:ReadHeader()
	self:Parse(LUMP.PLANES)
	self:Parse(LUMP.VERTEXES)
	self:Parse(LUMP.EDGES)
	self:Parse(LUMP.SURFEDGES)
	
	self:Parse(LUMP.LIGHTING)
	self:Parse(LUMP.TEXDATA)
	self:Parse(LUMP.TEXINFO)
	
	if SERVER then
		self:Parse(LUMP.LEAFS)
		self:Parse(LUMP.NODES)
		self:Parse(LUMP.MODELS)
	end
	
	self:Parse(SplatoonSWEPs.HDR and LUMP_FACES_HDR or LUMP.FACES)
	self:Parse(LUMP.DISPINFO)
	
	self:Parse(LUMP.GAME_LUMP)
	self.bsp:Close()
	self.bsp = nil
end

function bsp:ReadHeader()
	self.header = {lumps = {}}
	self.bsp:Seek(8)
	for i = 0, 63 do
		self.header.lumps[i] = {}
		self.header.lumps[i].data = {}
		self.header.lumps[i].parsed = false
		self.header.lumps[i].offset = read "Long"
		self.header.lumps[i].length = read "Long"
		self.bsp:Skip(8)
	end
end

local function GetRotatedAABB(v2d, angle)
	local mins = Vector(math.huge, math.huge)
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

local function MakeSurface(mins, maxs, normal, angle, origin, v2d, v3d)
	if #v3d < 3 or bsp.FaceIndex > (600000 or 1247232) then return end
	local hitair = false
	for _, v in ipairs(v3d) do
		if bit.band(util.PointContents(v + normal * .01), CONTENTS_WATER) == 0 then
			hitair = true
			break
		end
	end
	if not hitair then return end
	bsp.FaceIndex = bsp.FaceIndex + 1
	
	local area, bound, minangle, minmins = math.huge, nil, nil, nil
	for i, v in ipairs(v2d) do --Get minimum AABB with O(n^2)
		local seg = v2d[i % #v2d + 1] - v
		local ang = Angle(0, 90 - math.deg(math.atan2(seg.y, seg.x)))
		local mins, maxs = GetRotatedAABB(v2d, ang)
		local tmpbound = maxs - mins
		if area > tmpbound.x * tmpbound.y then
			if tmpbound.x < tmpbound.y then
				ang.yaw = ang.yaw - 90
				minmins, maxs = GetRotatedAABB(v2d, ang)
			else
				minmins = mins
			end
			minangle = ang
			bound = maxs - minmins
			area = bound.x * bound.y
		end
	end
	
	for i, v in ipairs(v2d) do
		v:Rotate(minangle)
		v:Sub(minmins)
	end

	minmins:Rotate(-minangle)
	origin = SplatoonSWEPs:To3D(minmins, origin, angle)
	angle:RotateAroundAxis(normal, -minangle.yaw)
	if CLIENT then
		SplatoonSWEPs.AreaBound = SplatoonSWEPs.AreaBound + area
		local surf = SplatoonSWEPs.SequentialSurfaces
		table.insert(surf.Angles, angle)
		table.insert(surf.Areas, area)
		table.insert(surf.Bounds, bound)
		table.insert(surf.Normals, normal)
		table.insert(surf.Origins, origin)
		table.insert(surf.Vertices, v3d)
	else
		local surf = SplatoonSWEPs:FindLeaf(v3d).Surfaces
		table.insert(surf.Angles, angle)
		table.insert(surf.Indices, bsp.FaceIndex)
		table.insert(surf.Maxs, maxs)
		table.insert(surf.Mins, mins)
		table.insert(surf.Normals, normal)
		table.insert(surf.Origins, origin)
		table.insert(surf.InkCircles, {})
	end
end

local function MakeDispTriangle(vert)
	local normal = (vert[1] - vert[2]):Cross(vert[3] - vert[2]):GetNormalized()
	local angle = normal:Angle()
	local origin = (vert[1] + vert[2] + vert[3]) / 3
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	local v2d = {}
	for i, v in ipairs(vert) do
		maxs.x = math.max(maxs.x, v.x) --Calculate bounding box
		maxs.y = math.max(maxs.y, v.y)
		maxs.z = math.max(maxs.z, v.z)
		mins.x = math.min(mins.x, v.x)
		mins.y = math.min(mins.y, v.y)
		mins.z = math.min(mins.z, v.z)
		v2d[i] = SplatoonSWEPs:To2D(v, origin, angle)
	end
	
	return MakeSurface(mins, maxs, normal, angle, origin, v2d, vert)
end

local ParseFunction = {
[LUMP.ENTITIES] = function(lump)
	lump.data.str = read(lump.length)
	for s in lump.data.str:gmatch "%{.-%}" do
		table.insert(lump.data, util.KeyValuesToTable('"xd"\r\n' .. s))
	end
end,

[LUMP.PLANES] = function(lump)
	local size = 20
	lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
	for i = 0, lump.num do
		lump.data[i] = {}
		lump.data[i].normal = read "Vector"
		lump.data[i].distance = read "Float"
		bsp.bsp:Skip(4) --type
	end
end,

[LUMP.VERTEXES] = function(lump)
	local size = 12
	lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
	for i = 0, lump.num do
		lump.data[i] = read "Vector"
	end
end,

[LUMP.EDGES] = function(lump)
	local size = 4
	lump.num = math.min(math.floor(lump.length / size) - 1, 256000 - 1)
	for i = 0, lump.num do
		lump.data[i] = {}
		lump.data[i][1] = read "UShort"
		lump.data[i][2] = read "UShort"
	end
end,

[LUMP.SURFEDGES] = function(lump)
	local size = 4
	local vertexes = bsp:GetLump(LUMP.VERTEXES)
	local edges = bsp:GetLump(LUMP.EDGES)
	lump.num = math.min(math.floor(lump.length / size) - 1, 512000 - 1)
	for i = 0, lump.num do
		local n = read "Long"
		local an = math.abs(n)
		local edge = edges.data[an]
		local v1, v2 = edge[1], edge[2]
		if n < 0 then v1, v2 = v2, v1 end
		lump.data[i] = vertexes.data[v1] --{start = vertexes.data[v1], endpos = vertexes.data[v2]}
	end
	vertexes.data, edges.data = nil
end,

[LUMP.TEXDATA] = function(lump)
	local size = 32
	local strdata = bsp:GetLump(LUMP.TEXDATA_STRING_DATA)
	local strtable = bsp:GetLump(LUMP.TEXDATA_STRING_TABLE)
	lump.num = math.min(math.floor(lump.length / size) - 1, 2048 - 1)
	for i = 0, lump.num do
		lump.data[i] = {}
		bsp.bsp:Skip(12) --reflectivity
		local strID = read "Long" * 4
		lump.data[i].name = ""

		local here = bsp.bsp:Tell() + 8 + 8 --width, height, view_width, view_height
		bsp.bsp:Seek(strtable.offset + strID)
		local stroffset = read "Long"
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
	lump.num = math.min(math.floor(lump.length / size) - 1, 12288 - 1)
	for i = 0, lump.num do
		bsp.bsp:Skip(size - 8)
		lump.data[i] = {}
		lump.data[i].flags = read "Long"
		local texdataID = read "Long"
		if texdataID >= 0 then
			lump.data[i].TexData = TexData.data[texdataID]
		end
	end
end,

[LUMP.LEAFS] = function(lump)
	local size = 32
	lump.num = math.floor(lump.length / size) - 1
	for i = 0, lump.num do
		lump.data[i] = {}
		lump.data[i].Surfaces = {
			Angles = {},
			Indices = {},
			InkCircles = {},
			Maxs = {},
			Mins = {},
			Normals = {},
			Origins = {},
		}
	end
end,

[LUMP.NODES] = function(lump)
	local size = 32
	local planes = bsp:GetLump(LUMP.PLANES)
	local leafs = bsp:GetLump(LUMP.LEAFS)
	lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
	local children = {}
	for i = 0, lump.num do
		lump.data[i] = {}
		lump.data[i].ChildNodes = {}
		lump.data[i].Surfaces = {
			Angles = {},
			Indices = {},
			InkCircles = {},
			Maxs = {},
			Mins = {},
			Normals = {},
			Origins = {},
		}
		lump.data[i].Separator = planes.data[read "Long"]
		children[i] = {}
		children[i][1] = read "Long"
		children[i][2] = read "Long"
		bsp.bsp:Skip(20) --mins, maxs, firstface, numfaces, area, padding
	end
	
	for i = 0, lump.num do
		for k = 1, 2 do
			local child = children[i][k]
			if child < 0 then
				child, leafs.data[-child - 1] = leafs.data[-child - 1]
			else
				child = lump.data[child]
			end
			lump.data[i].ChildNodes[k] = child
		end
	end
end,

[LUMP.MODELS] = function(lump)
	local size = 4 * 12
	local nodes = bsp:GetLump(LUMP.NODES)
	lump.num = math.floor(lump.length / size) - 1
	for i = 0, lump.num do
		bsp.bsp:Skip(12 * 3)
		table.insert(SplatoonSWEPs.Models, nodes.data[read "Long"])
		bsp.bsp:Skip(8)
	end
end,

[LUMP.FACES] = function(lump)
	local size = 56
	local planes = bsp:GetLump(LUMP.PLANES)
	local surfedges = bsp:GetLump(LUMP.SURFEDGES)
	local texinfo = bsp:GetLump(LUMP.TEXINFO)
	local lighting = bsp:GetLump(LUMP.LIGHTING)
	lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
	for i = 0, lump.num do
		local PlaneTable = planes.data[read "UShort"]
		local normal = PlaneTable.normal
		local angle = normal:Angle()
		bsp.bsp:Skip(2)
		local firstedge = read "Long"
		local numedges = read "Short" - 1
		local TexInfoTable = texinfo.data[read "Short"]
		local dispinfo = read "Short"
		bsp.bsp:Skip(42)
		
		local texname = TexInfoTable.TexData.name:lower()
		if texname:find "tools/" or texname:find "water" or texname:find "color" or
			bit.band(TexInfoTable.flags, TextureFilterBits) ~= 0 then
			continue
		end

		local fullverts, full2d, center = {}, {}, vector_origin
		for k = 0, numedges do --Fetch all vertices
			fullverts[k] = surfedges.data[firstedge + k]
			center = center + fullverts[k]
		end
		center = center / (#fullverts + 1)
		
		if bit.band(util.PointContents(center - normal * 0.01), CONTENTS_GRATE) ~= 0 then continue end
		for k, v in pairs(fullverts) do
			full2d[k] = SplatoonSWEPs:To2D(v, center, angle)
		end
		
		local v3d, v2d = {}, {} --Vector3D, 2D
		local nf = #full2d + 1
		local mins = Vector(math.huge, math.huge, math.huge)
		local maxs = -mins
		for k = 0, #full2d do --Remove collinear and concave components
			local v2, v3 = full2d[k], fullverts[k]
			local _next, prev = full2d[(k + 1) % nf], full2d[(k + nf - 1) % nf]
			local sin = (prev - v2):GetNormalized():Cross((_next - v2):GetNormalized()).z
			maxs.x = math.max(maxs.x, v3.x) --Calculate bounding box
			maxs.y = math.max(maxs.y, v3.y)
			maxs.z = math.max(maxs.z, v3.z)
			mins.x = math.min(mins.x, v3.x)
			mins.y = math.min(mins.y, v3.y)
			mins.z = math.min(mins.z, v3.z)
			
			table.insert(v2d, v2)
			table.insert(v3d, v3)
		end
		
		if dispinfo >= 0 then
			lump.data[i] = v3d
			continue
		end
		MakeSurface(mins, maxs, normal, angle, center, v2d, v3d)
	end
end,

[LUMP.DISPINFO] = function(lump)
	local size = 176
	local faces = bsp:GetLump(LUMP.FACES)
	local dispvertsoffset = bsp:GetLump(LUMP.DISP_VERTS).offset
	lump.num = math.floor(lump.length / size) - 1
	for i = 0, lump.num do
		bsp.bsp:Seek(lump.offset + i * size)
		local startPosition = read "Vector"
		local DispVertStart = read "Long"
		bsp.bsp:Skip(4) --DispTriStart
		local power = 2^(read "Long") + 1
		bsp.bsp:Skip(4 * 3) --minTess, smoothingAngle, contents
		local verts = faces.data[read "UShort"]
		if not verts or #verts ~= 4 then continue end
		
		local dispverts = {}
		for k = 0, power^2 - 1 do
			bsp.bsp:Seek(dispvertsoffset + 20 * (DispVertStart + k))
			dispverts[k] = {}
			dispverts[k].vec = read "Vector"
			dispverts[k].dist = read "Float"
		end

		--DispInfo.startPosition isn't always equal to the first edge so let's find correct one
		local indices, mindist, dist, startedge = {}, math.huge, 0, 0
		for k, v in ipairs(verts) do
			dist = startPosition:DistToSqr(v)
			if dist < mindist then
				startedge = k
				mindist = dist
			end
		end

		for k = 1, 4 do
			indices[k] = (k + startedge - 2) % 4 + 1
		end

		verts[1],
		verts[2],
		verts[3],
		verts[4]
		=	verts[indices[1]],
			verts[indices[2]],
			verts[indices[3]],
			verts[indices[4]]

		local u1 = verts[4] - verts[1]
		local u2 = verts[3] - verts[2]
		local v1 = verts[2] - verts[1]
		local v2 = verts[3] - verts[4]
		local div1, div2 -- vector_origin, vector_origin
		for k, w in pairs(dispverts) do --Get the world positions of the displacements
			x = k % power --0 <= x <= power
			y = math.floor(k / power) --0 <= y <= power
			div1, div2 = v1 * y / (power - 1), u1 + v2 * y / (power - 1)
			div2 = div2 - div1
			w.origin = div1 + div2 * x / (power - 1)
			w.pos = startPosition + w.origin + w.vec * w.dist
		end
		
		--Generate triangles from displacement mesh.
		for k = 0, #dispverts do
			local tri_inv = k % 2 == 0
			if k % power < power - 1 and math.floor(k / power) < power - 1 then
				MakeDispTriangle {
					dispverts[tri_inv and k + power + 1 or k + power].pos,
					dispverts[k + 1].pos,
					dispverts[k].pos,
				}

				MakeDispTriangle {
					dispverts[tri_inv and k or k + 1].pos,
					dispverts[k + power].pos,
					dispverts[k + power + 1].pos,
				}
			end
		end
	end
end,

[LUMP.GAME_LUMP] = function(lump)
	print("surfaces: ", bsp.FaceIndex)
	local lumpCount = read "Long"
	local headers = {}
	for i = 1, lumpCount do
		headers[i] = {}
		headers[i].id = read "Long"
		headers[i].flags = read "UShort"
		headers[i].version = read "UShort"
		headers[i].fileofs = read "Long"
		headers[i].filelen = read "Long"
	end
	print("Number of gamelumps: ", #headers)
	
	local props = 0
	for _, l in ipairs(headers) do --id == "scrp", Static Prop Gamelump
		print("Gamelump version: ", l.version)
		if l.id ~= 1936749168 then continue end
		bsp.bsp:Seek(l.fileofs)
		local nextlump = l.fileofs + l.filelen
		local entries = read "Long"
		local modelnames = {} --Model name dictionary
		for e = 1, entries do
			modelnames[e] = ""
			for i = 1, 128 do
				local c = read(1)
				if c ~= '\x00' then
					modelnames[e] = modelnames[e] .. c
				end
			end
		end
		
		bsp.bsp:Skip(read "Long" * 2) --Leaf Indices
		entries = read "Long"
		local here = bsp.bsp:Tell()
		local remaining = nextlump - here
		local entrysize = math.floor(remaining / entries)
		for e = 0, entries - 1 do
			bsp.bsp:Seek(here + entrysize * e)
			local p = {}
			p.Origin = read "Vector"
			p.Angles = read "Vector" --(x, y, z) -> (pitch, yaw, roll)
			p.Angles = Angle(p.Angles.x, p.Angles.y, p.Angles.z)
			p.Angles:Normalize()
			p.PropType = read "UShort"
			bsp.bsp:Skip(4)
			p.Solid = read "Byte"
			p.ModelName = modelnames[p.PropType + 1]
			if p.Solid == SOLID_NONE or not file.Exists(p.ModelName or "/", "GAME") then continue end
			
			local mdl
			if SERVER then
				util.PrecacheModel(p.ModelName)
				mdl = ents.Create "prop_physics"
			else
				mdl = ClientsideModel(p.ModelName)
			end
			mdl:SetModel(p.ModelName)
			mdl:Spawn()
			
			if mdl:PhysicsInit(p.Solid) then
				local ph = mdl:GetPhysicsObject()
				local mat = ph:GetMaterial()
				if not (mat:find "chain" or mat:find "grate") then
					local physmesh = ph:GetMesh()
					props = props + #physmesh / 3
					for i = 1, #physmesh, 3 do
						local t = {physmesh[i].pos, physmesh[i + 1].pos, physmesh[i + 2].pos}
						for _, v in ipairs(t) do
							v:Rotate(p.Angles)
							v:Add(p.Origin)
						end
						MakeDispTriangle(t)
					end
				end
			end
			mdl:PhysicsDestroy()
			mdl:Remove()
		end
		
		break
	end
	print("Number of triangles: ", props)
	print("All: ", bsp.FaceIndex)
end,
}
ParseFunction[LUMP.FACES_HDR] = ParseFunction[FACES]

function bsp:Parse(parse_type)
	local lump = self:GetLump(parse_type or "nil")
	if parse_type and lump and isfunction(ParseFunction[parse_type]) then
		self.bsp:Seek(lump.offset)
		ParseFunction[parse_type](lump)
		lump.parsed = true
	end
end
