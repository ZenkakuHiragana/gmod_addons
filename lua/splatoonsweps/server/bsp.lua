
-- This lua parses current map.

local ss = SplatoonSWEPs
if not (ss and ss.BSP) then return end
local LUMP = { -- Lump names. most of these are unused in SplatoonSWEPs.
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
	PORTALS							= 22, -- unused in version 20
	CLUSTERS						= 23, --
	PORTALVERTS						= 24, --
	CLUSTERPORTALS					= 25, -- unused in version 20
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
	LIGHTING_HDR					= 53, -- only used in version 20+ BSP files
	WORLDLIGHTS_HDR					= 54, --
	LEAF_AMBIENT_LIGHTING_HDR		= 55, --
	LEAF_AMBIENT_LIGHTING			= 56, -- only used in version 20+ BSP files
	XZIPPAKFILE						= 57,
	FACES_HDR						= 58,
	MAP_FLAGS						= 59,
	OVERLAY_FADES					= 60,
	OVERLAY_SYSTEM_LEVELS			= 61,
	PHYSLEVEL						= 62,
	DISP_MULTIBLEND					= 63,
}

local bsp = ss.BSP
local TextureFilterBits = bit.bor(SURF_SKY, SURF_WARP, SURF_NOPORTAL, SURF_TRIGGER, SURF_NODRAW, SURF_HINT, SURF_SKIP)
local function read(arg)
	if isstring(arg) then
		if arg == "SignedByte" then
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
			return ss.ProtectedCall(bsp.bsp["Read" .. arg], bsp.bsp)
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
	assert(file.Exists(self.bspname, "GAME"), "SplatoonSWEPs: Attempt to load a non-existent map!")
	self.bsp = file.Open(self.bspname, "rb", "GAME")
	self.FaceIndex = 0 -- Every face has an individual number.

	self:ReadHeader()
	self:Parse(LUMP.PLANES)
	self:Parse(LUMP.VERTEXES)
	self:Parse(LUMP.EDGES)
	self:Parse(LUMP.SURFEDGES)

	self:Parse(LUMP.LIGHTING)
	self:Parse(LUMP.TEXDATA)
	self:Parse(LUMP.TEXINFO)

	self:Parse(LUMP.LEAFS)
	self:Parse(LUMP.NODES)

	self:Parse(LUMP.MODELS)
	self:Parse(LUMP.FACES)
	self:Parse(LUMP.DISPINFO)
	self:Parse(LUMP.GAME_LUMP)

	self.bsp:Close()
	self.bsp = nil
	ss.NumSurfaces = self.FaceIndex
end

function bsp:ReadHeader()
	self.header = {lumps = {}}
	self.bsp:Seek(8)
	for i = 0, 63 do
		self.header.lumps[i] = {}
		self.header.lumps[i].data = {}
		self.header.lumps[i].offset = read "Long"
		self.header.lumps[i].length = read "Long"
		self.bsp:Skip(8)
	end
end

local function GetRotatedAABB(v2d, angle, disp)
	angle = -angle
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

	if disp then
		for k, v in ipairs(disp.Positions2D) do
			v = Vector(v)
			v:Rotate(angle)
			mins.x = math.min(mins.x, v.x)
			mins.y = math.min(mins.y, v.y)
			maxs.x = math.max(maxs.x, v.x)
			maxs.y = math.max(maxs.y, v.y)
		end
	end

	return mins, maxs
end

-- TODO: if the face is underwater then return end
local function MakeSurface(mins, maxs, normal, angle, origin, v2d, v3d, disp)
	if #v3d < 3 or bsp.FaceIndex > 1247232 then return end

	local surf = ss.FindLeaf(disp or v3d).Surfaces
	local area, bound, minangle, minmins = math.huge, nil, nil, nil
	for i, v in ipairs(v2d) do -- Get minimum AABB with O(n^2)
		local seg = v2d[i % #v2d + 1] - v
		local ang = Angle(0, math.deg(math.atan2(seg.y, seg.x)) - 90)
		local mins, maxs = GetRotatedAABB(v2d, ang, disp)
		local tb = maxs - mins
		if area > tb.x * tb.y then
			if tb.x < tb.y then
				ang.yaw = ang.yaw + 90
				minmins, maxs = GetRotatedAABB(v2d, ang, disp)
			else
				minmins = mins
			end

			minangle = ang
			bound = maxs - minmins
			area = bound.x * bound.y
		end
	end

	minmins:Rotate(minangle)
	origin = ss.To3D(minmins, origin, angle)
	angle:RotateAroundAxis(normal, minangle.yaw)
	bound.z = minangle.yaw
	bsp.FaceIndex = bsp.FaceIndex + 1
	ss.AreaBound = ss.AreaBound + area
	ss.AspectSum = ss.AspectSum + bound.y / bound.x
	ss.AspectSumX = ss.AspectSumX + bound.x
	ss.AspectSumY = ss.AspectSumY + bound.y
	surf.Angles[#surf.Angles + 1] = angle
	surf.Areas[#surf.Areas + 1] = area
	surf.Bounds[#surf.Bounds + 1] = bound
	surf.DefaultAngles[#surf.DefaultAngles + 1] = minangle.yaw
	surf.Indices[#surf.Indices + 1] = bsp.FaceIndex * (disp and -1 or 1)
	surf.InkCircles[#surf.InkCircles + 1] = {}
	surf.Maxs[#surf.Maxs + 1] = maxs
	surf.Mins[#surf.Mins + 1] = mins
	surf.Normals[#surf.Normals + 1] = normal
	surf.Origins[#surf.Origins + 1] = origin
	surf.Vertices[#surf.Vertices + 1] = v3d
end

local function MakeTriangle(vert)
	local normal = (vert[1] - vert[2]):Cross(vert[3] - vert[2]):GetNormalized()
	local angle = normal:Angle()
	local origin = (vert[1] + vert[2] + vert[3]) / 3
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	local v2d = {}
	for i, v in ipairs(vert) do
		mins = ss.MinVector(mins, v) -- Calculate bounding box
		maxs = ss.MaxVector(maxs, v)
		v2d[i] = ss.To2D(v, origin, angle)
	end

	return MakeSurface(mins, maxs, normal, angle, origin, v2d, vert)
end

local ParseFunction = {
[LUMP.ENTITIES] = function(lump)
	lump.data.str = read(lump.length)
	for s in lump.data.str:gmatch "%{.-%}" do
		lump.data[#lump.data + 1] = util.KeyValuesToTable('"xd"\r\n' .. s)
	end
end,

[LUMP.PLANES] = function(lump)
	local size = 20
	lump.num = math.min(math.floor(lump.length / size) - 1, 65536 - 1)
	for i = 0, lump.num do
		lump.data[i] = {}
		lump.data[i].normal = read "Vector"
		lump.data[i].distance = read "Float"
		bsp.bsp:Skip(4) -- type
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
		lump.data[i] = vertexes.data[n < 0 and v2 or v1]
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
		bsp.bsp:Skip(12) -- reflectivity
		local strID = read "Long" * 4
		lump.data[i].name = ""

		local here = bsp.bsp:Tell() + 8 + 8 -- width, height, view_width, view_height
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
		lump.data[i].Surfaces = ss.CreateSurfaceStructure()
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
		lump.data[i].Surfaces = ss.CreateSurfaceStructure()
		lump.data[i].Separator = planes.data[read "Long"]
		children[i] = {}
		children[i][1] = read "Long"
		children[i][2] = read "Long"
		bsp.bsp:Skip(20) -- mins, maxs, firstface, numfaces, area, padding
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
		ss.Models[#ss.Models + 1] = nodes.data[read "Long"]
		if i == 0 then
			bsp.FirstFace = read "Long"
			bsp.NumFaces = read "Long"
		else
			bsp.bsp:Skip(8)
		end
	end
end,

[LUMP.FACES] = function(lump)
	local size = 56 -- Structure size
	local planes = bsp:GetLump(LUMP.PLANES)
	local surfedges = bsp:GetLump(LUMP.SURFEDGES)
	local texinfo = bsp:GetLump(LUMP.TEXINFO)
	local lighting = bsp:GetLump(LUMP.LIGHTING)
	local dispinfooffset = bsp:GetLump(LUMP.DISPINFO).offset
	local dispvertsoffset = bsp:GetLump(LUMP.DISP_VERTS).offset
	local materials = {}
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

		if not (bsp.FirstFace <= i and i < bsp.NumFaces) then continue end

		local texname = TexInfoTable.TexData.name
		local texlow = texname:lower()
		if texlow:find "tools/" or texlow:find "water" or
			bit.band(TexInfoTable.flags, TextureFilterBits) ~= 0 then
			continue
		end

		materials[texname] = materials[texname] or Material(texname)
		if materials[texname]:GetString "$surfaceprop" == "metalgrate" then continue end

		local fullverts, full2d, center = {}, {}, vector_origin
		for k = 0, numedges do -- Fetch all vertices
			fullverts[k] = surfedges.data[firstedge + k]
			center = center + fullverts[k]
		end
		center = center / (#fullverts + 1)

		for k, v in pairs(fullverts) do
			full2d[k] = ss.To2D(v, center, angle)
		end

		local v3d, v2d = {}, {} -- Vector3D, 2D
		local nf = #full2d + 1
		local mins = Vector(math.huge, math.huge, math.huge)
		local maxs = -mins
		for k = 0, #full2d do -- Remove collinear and concave components
			local v2, v3 = full2d[k], fullverts[k]
			mins = ss.MinVector(mins, v3) -- Calculate bounding box
			maxs = ss.MaxVector(maxs, v3)
			v2d[#v2d + 1] = v2
			v3d[#v3d + 1] = v3
		end

		local isdisp = dispinfo >= 0
		if isdisp then
			local here = bsp.bsp:Tell()
			bsp.bsp:Seek(dispinfooffset + dispinfo * 176)
			local startPosition = read "Vector"
			local DispVertStart = read "Long"
			bsp.bsp:Skip(4) -- DispTriStart
			local power = 2^read "Long" + 1
			local numdists = power^2
			local dispverts = {}
			for k = 0, numdists - 1 do
				bsp.bsp:Seek(dispvertsoffset + 20 * (DispVertStart + k))
				dispverts[k] = {}
				dispverts[k].vec = read "Vector"
				dispverts[k].dist = read "Float"
			end
			bsp.bsp:Seek(here)

			-- DispInfo.startPosition isn't always equal to v3d[1] so find correct one
			do local i, min, start = {}, math.huge, 0
				for k, v in ipairs(v3d) do
					mins = ss.MinVector(mins, v) -- Calculate bounding box
					maxs = ss.MaxVector(maxs, v)
					local dist = startPosition:DistToSqr(v)
					if dist > min then continue end
					start, min = k, dist
				end

				for k = 1, 4 do i[k] = (k + start - 2) % 4 + 1 end
				v3d[1], v3d[2], v3d[3], v3d[4] = v3d[i[1]], v3d[i[2]], v3d[i[3]], v3d[i[4]]
			end

			isdisp = {Positions2D = {}}
			ss.Displacements[bsp.FaceIndex + 1] = dispverts
			local div1, div2 -- vector_origin, vector_origin
			local u1, u2 = v3d[4] - v3d[1], v3d[3] - v3d[2]
			local v1, v2 = v3d[2] - v3d[1], v3d[3] - v3d[4]
			for k, v in pairs(dispverts) do -- Get the world positions of the displacements
				x = k % power -- 0 <= x <= power
				y = math.floor(k / power) -- 0 <= y <= power
				div1, div2 = v1 * y / (power - 1), u1 + v2 * y / (power - 1)
				div2 = div2 - div1
				v.origin = div1 + div2 * x / (power - 1)
				v.pos = startPosition + v.origin + v.vec * v.dist
				v.pos2d = ss.To2D(v.pos - normal * normal:Dot(v.vec * v.dist), center, angle)
				mins = ss.MinVector(mins, v.pos) -- Calculate bounding box
				maxs = ss.MaxVector(maxs, v.pos)
				isdisp[#isdisp + 1] = v.pos
				isdisp.Positions2D[#isdisp.Positions2D + 1] = v.pos2d
			end
		end

		MakeSurface(mins, maxs, normal, angle, center, v2d, v3d, isdisp)
	end
end,

[LUMP.GAME_LUMP] = function(lump)
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

	local props = 0
	for _, l in ipairs(headers) do -- id == "scrp", Static Prop Gamelump
		if l.id ~= 1936749168 then continue end
		bsp.bsp:Seek(l.fileofs)
		local nextlump = l.fileofs + l.filelen
		local entries = read "Long"
		local modelnames = {} -- Model name dictionary
		for e = 1, entries do
			modelnames[e] = ""
			for i = 1, 128 do
				local c = read(1)
				modelnames[e] = modelnames[e] .. (c ~= "\x00" and c or "")
			end
		end

		bsp.bsp:Skip(read "Long" * 2) -- Leaf Indices
		entries = read "Long"
		local here = bsp.bsp:Tell()
		local remaining = nextlump - here
		local entrysize = math.floor(remaining / entries)
		for e = 0, entries - 1 do
			bsp.bsp:Seek(here + entrysize * e)
			local p = {}
			p.Origin = read "Vector"
			p.Angles = read "Vector" -- (x, y, z) -> (pitch, yaw, roll)
			p.Angles = Angle(p.Angles.x, p.Angles.y, p.Angles.z)
			p.Angles:Normalize()
			p.PropType = read "UShort"
			bsp.bsp:Skip(4)
			p.Solid = read "Byte"
			p.ModelName = Model(modelnames[p.PropType + 1])
			if p.Solid ~= SOLID_VPHYSICS or not file.Exists(p.ModelName or "/", "GAME") then continue end

			local mdl = ents.Create "prop_physics"
			if not (mdl and IsValid(mdl)) then continue end
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
						if (t[2] - t[1]):Cross(t[3] - t[1]):LengthSqr() > 4000 then
							for _, v in ipairs(t) do
								v:Rotate(p.Angles)
								v:Add(p.Origin)
							end
							MakeTriangle(t)
						end
					end
				end
			end

			mdl:PhysicsDestroy()
			mdl:Remove()
		end

		break
	end
end,
}
ParseFunction[LUMP.FACES_HDR] = ParseFunction[FACES]

function bsp:Parse(parse_type)
	local lump = self:GetLump(parse_type or "nil")
	if parse_type and lump then
		self.bsp:Seek(lump.offset)
		ss.ProtectedCall(ParseFunction[parse_type], lump)
	end
end

-- do return end
hook.Remove("Think", "Test", function()
	if CLIENT then return end
	if not ss.AABBTree then return end
	if player.GetCount() == 0 then return end
	local t = player.GetByID(1):GetEyeTrace()
	local p = t.HitPos
	local normal = t.HitNormal
	local size = .1
	local mins, maxs = p - ss.vector_one * size, p + ss.vector_one * size
	greatzenkakuman.debug.DShort()
	if player.GetByID(1):KeyDown(IN_ATTACK) then
		local function traverse(a)
			local t = {}
			if a.SurfIndices then
				for _, i in ipairs(a.SurfIndices) do
					local a = ss.SurfaceArray[i]
					if a.Normal:Dot(normal) > ss.MAX_COS_DEG_DIFF then
						if ss.CollisionAABB(a.AABB.mins, a.AABB.maxs, mins, maxs) then
							t[#t + 1] = a
						end
					end
				end

				return t
			end

			local l = ss.AABBTree[a.Children[1]]
			local r = ss.AABBTree[a.Children[2]]
			if ss.CollisionAABB(l.AABB.mins, l.AABB.maxs, mins, maxs) then
				table.Add(t, traverse(l))
			end

			if ss.CollisionAABB(r.AABB.mins, r.AABB.maxs, mins, maxs) then
				table.Add(t, traverse(r))
			end

			return t
		end

		greatzenkakuman.debug.DColor(0, 255, 255, 4)
		greatzenkakuman.debug.DBox(mins, maxs)
		util.TimerCycle()
		for i, a in ipairs(traverse(ss.AABBTree[1])) do
			greatzenkakuman.debug.DColor(0, 255, 0, 4)
			greatzenkakuman.debug.DBox(a.AABB.mins, a.AABB.maxs)
			greatzenkakuman.debug.DColor(255, 255, 0, 4)
			greatzenkakuman.debug.DPoly(a.Vertices)
		end
		print("NEW", util.TimerCycle())
	elseif player.GetByID(1):KeyDown(IN_ATTACK2) then
		util.TimerCycle()
		for _, a in ss.SearchAABB({mins = mins, maxs = maxs}, normal) do
			greatzenkakuman.debug.DColor(0, 255, 0, 4)
			greatzenkakuman.debug.DBox(a.AABB.mins, a.AABB.maxs)
			greatzenkakuman.debug.DColor(255, 255, 0, 4)
			greatzenkakuman.debug.DPoly(a.Vertices)
		end
		print("OLD", util.TimerCycle())
	end
end)
