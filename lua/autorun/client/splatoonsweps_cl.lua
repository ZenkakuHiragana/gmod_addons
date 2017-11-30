
--Clientside ink manager
local InkAlpha = 255
local MeshColor = ColorAlpha(color_white, InkAlpha)
SplatoonSWEPs = SplatoonSWEPs or {
	IMesh = {},
	MeshTriangles = {{}},
	RenderTarget = {
		BaseTextureName = "splatoonsweps_rendertarget",
		NormalmapName = "splatoonsweps_normalmap",
		LightmapName = "splatoonsweps_lightmap",
		WaterMaterialName = "splatoonsweps_watermaterial",
	},
	SortedSurfaces = {},
	Surfaces = {Area = 0, AreaBound = 0, LongestEdge = 0},
}
include "../splatoonsweps_shared.lua"
include "../splatoonsweps_bsp.lua"
include "../splatoonsweps_const.lua"
include "splatoonsweps_userinfo.lua"
include "splatoonsweps_inkmanager_cl.lua"
include "splatoonsweps_network_cl.lua"

SplatoonSWEPs.RenderTarget.BaseTextureFlags = bit.bor(
	SplatoonSWEPs.TEXTUREFLAGS.PROCEDURAL,
	SplatoonSWEPs.TEXTUREFLAGS.EIGHTBITALPHA,
	SplatoonSWEPs.TEXTUREFLAGS.RENDERTARGET,
	SplatoonSWEPs.TEXTUREFLAGS.NODEPTHBUFFER
)
SplatoonSWEPs.RenderTarget.NormalmapFlags = bit.bor(
	SplatoonSWEPs.TEXTUREFLAGS.NORMAL,
	SplatoonSWEPs.TEXTUREFLAGS.PROCEDURAL,
	SplatoonSWEPs.TEXTUREFLAGS.RENDERTARGET,
	SplatoonSWEPs.TEXTUREFLAGS.NODEPTHBUFFER
)
SplatoonSWEPs.RenderTarget.LightmapFlags = bit.bor(
	SplatoonSWEPs.TEXTUREFLAGS.PROCEDURAL,
	SplatoonSWEPs.TEXTUREFLAGS.RENDERTARGET,
	SplatoonSWEPs.TEXTUREFLAGS.NODEPTHBUFFER
)

function SplatoonSWEPs:GetRTSize()
	return SplatoonSWEPs.RTSize[SplatoonSWEPs:GetConVarInt "RTResolution"]
end

function SplatoonSWEPs:ClearAllInk()
	render.PushRenderTarget(SplatoonSWEPs.RenderTarget.BaseTexture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(SplatoonSWEPs.RenderTarget.Normalmap)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(128, 128, 255, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	
	-- render.PushRenderTarget(SplatoonSWEPs.RenderTarget.Lightmap)
	-- render.ClearDepth()
	-- render.ClearStencil()
	-- render.Clear(0, 0, 0, 255)
	-- render.PopRenderTarget()
	game.GetWorld():RemoveAllDecals()
end

--Mesh limitation is
-- 10922 = 32767 / 3 with mesh.Begin(),
-- 21845 = 65535 / 3 with BuildFromTriangles()
local MAX_TRIANGLES = math.floor(32768 / 3)
local INK_SURFACE_DELTA_NORMAL = 0.8 --Distance between map surface and ink mesh
local function Initialize()
	local self = SplatoonSWEPs
	for i, m in ipairs(self.IMesh) do
		print("Mesh destroy", i)
		m:Destroy()
	end
	
	self.HDR = GetConVar("mat_hdr_level"):GetInt() == 2
	self.BSP:Init() --Parsing BSP file
	self.BSP = nil
	
	local rtsize = math.min(self:GetRTSize(), render.MaxTextureWidth())
	local rtheight = math.min(self:GetRTSize(), render.MaxTextureHeight())
	local rtarea = rtsize^2
	local rtmergin = 2 / rtsize
	local rtmerginSqr = rtmergin^2
	local function GetUV(convertunit)
		local u, v, nextV = 0, 0, 0
		local convSqr = convertunit^2
		for _, face in ipairs(self.SortedSurfaces) do --Using next-fit approach
			-- if face.Vertices2D.Area / convSqr < rtmerginSqr then continue end
			local bound = face.Vertices2D.bound / convertunit
			nextV = math.max(nextV, bound.y)
			if 1 - u < bound.x then 
				u, v, nextV = 0, v + nextV + rtmergin, bound.y
			end
			
			for i, vertex in ipairs(face.Vertices2D) do
				local UV = vertex / convertunit --Get UV coordinates
				face.MeshVertex[i] = {
					pos = face.Vertices[i] + face.Parent.normal * INK_SURFACE_DELTA_NORMAL,
					u = UV.x + u,
					v = UV.y + v,
				}
			end
			
			face.MeshVertex.origin = Vector(u, v)
			u = u + bound.x + rtmergin --Advance U-coordinate
		end
		
		return v + nextV
	end
	
	--Ratio[(units^2 / pixel^2)^1/2 -> units/pixel]
	self.RenderTarget.Ratio = math.max(math.sqrt(self.Surfaces.AreaBound / rtarea), self.Surfaces.LongestEdge / rtsize)
	table.sort(self.SortedSurfaces, function(a, b) return a.Vertices2D.Area > b.Vertices2D.Area end)
	
	--convertunit[pixel * units/pixel -> units]
	local convertunit = rtsize * self.RenderTarget.Ratio
	local maxY = GetUV(convertunit) --UV mapping to map geometry
	while maxY > 1 do
		convertunit = convertunit * ((maxY - 1) * 0.475 + 1.0005)
		maxY = GetUV(convertunit)
	end
	
	function self:PixelsToUnits(pixels) return pixels * self.RenderTarget.Ratio end
	function self:PixelsToUV(pixels) return pixels / rtsize end
	function self:UnitsToPixels(units) return units / self.RenderTarget.Ratio end
	function self:UnitsToUV(units) return units / convertunit end
	function self:UVToPixels(uv) return uv * rtsize end
	function self:UVToUnits(uv) return uv * convertunit end
	
	self.RenderTarget.Ratio = convertunit / rtsize
	self.RenderTarget.BaseTexture = GetRenderTargetEx(
		self.RenderTarget.BaseTextureName,
		rtsize, rtheight,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.BaseTextureFlags,
		CREATERENDERTARGETFLAGS_HDR,
		21 --8192x8192, 256MB
	)
	self.RenderTarget.Normalmap = GetRenderTargetEx(
		self.RenderTarget.NormalmapName,
		rtsize, rtheight,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.NormalmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_BGRA8888 -- BGRA5551, 8192x8192, 128MB
	)
	self.RenderTarget.Lightmap = GetRenderTargetEx(
		self.RenderTarget.LightmapName,
		rtsize / 2, rtheight / 2,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.LightmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		self.HDR and IMAGE_FORMAT_RGBA16161616 or IMAGE_FORMAT_BGRA8888 -- I8, 8192x8192, 256MB
	)
	self.RenderTarget.Material = CreateMaterial(
		self.RenderTarget.BaseTextureName,
		"LightmappedGeneric",
		{
			["$basetexture"] = self.RenderTarget.BaseTexture:GetName(),
			["$bumpmap"] = self.RenderTarget.Normalmap:GetName(),
			["$ssbump"] = "1",
			["$envmap"] = "env_cubemap",
			["$translucent"] = "1",
			["$vertexalpha"] = "1",
			["$vertexcolor"] = "1",
		}
	)
	self.RenderTarget.WaterMaterial = CreateMaterial(
		self.RenderTarget.WaterMaterialName,
		"Refract",
		{
			["$normalmap"] = self.RenderTarget.Normalmap:GetName(),
			["$bluramount"] = "2",
			["$refractamount"] = "3.5",
			["$refracttint"] = "[.9 .9 .9]",
		}
	)
	
	--Building MeshVertex
	local numtriangles = 0
	for _, face in ipairs(self.SortedSurfaces) do
		numtriangles = numtriangles + #face.MeshVertex - 2
	end
	
	local build = 1
	self.IMesh[build] = Mesh(self.RenderTarget.Material)
	mesh.Begin(self.IMesh[build], MATERIAL_TRIANGLES, math.min(numtriangles, MAX_TRIANGLES))
	for _, face in ipairs(self.SortedSurfaces) do
		for t = 3, #face.MeshVertex do
			for j, i in ipairs {t - 1, t, 1} do
				local f = face.MeshVertex[i]
				mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
				mesh.Normal(face.Parent.normal)
				mesh.Position(f.pos)
				mesh.TexCoord(0, f.u, f.v)
				-- if face.Lightmap then
					-- mesh.TexCoord(1, face.Lightmap[i].x, face.Lightmap[i].y)
					-- mesh.TexCoord(2, face.Lightmap[i].x, face.Lightmap[i].y)
					-- if face.Lightmap[i].x < 0 or face.Lightmap[i].y < 0 or
						-- face.Lightmap[i].x > 1 or face.Lightmap[i].y > 1 then
						-- ErrorNoHalt("Light UV coordinates is wrong!")
						-- print(face.Lightmap[i].x, face.Lightmap[i].y)
					-- end
				-- else
					-- mesh.TexCoord(2, f.u, f.v)
				-- end
				mesh.TexCoord(1, f.u, f.v)
				mesh.AdvanceVertex()
				if f.u < 0 or f.u > 1 or f.v < 0 or f.v > 1 then
					ErrorNoHalt("UV coordinates is wrong!")
					print(f.u, f.v)
				end
			end
		
			if mesh.VertexCount() >= MAX_TRIANGLES * 3 then
				build = build + 1
				numtriangles = numtriangles - MAX_TRIANGLES
				self.IMesh[build] = Mesh(self.RenderTarget.Material)
				mesh.End()
				mesh.Begin(self.IMesh[build], MATERIAL_TRIANGLES, math.min(numtriangles, MAX_TRIANGLES))
			end
		end
	end
	mesh.End()
	
	self.IMesh[build + 1] = Mesh(self.RenderTarget.Material)
	mesh.Begin(self.IMesh[build + 1], MATERIAL_TRIANGLES, 2)
	mesh.Position(Vector(0, 0, 80))
	mesh.Normal(vector_up)
	mesh.TexCoord(0, 0, 0)
	mesh.TexCoord(1, 0, 0)
	mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	mesh.AdvanceVertex()
	mesh.Position(Vector(0, 100, 80))
	mesh.Normal(vector_up)
	mesh.TexCoord(0, 1, 0)
	mesh.TexCoord(1, 1, 0)
	mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	mesh.AdvanceVertex()
	mesh.Position(Vector(100, 0, 80))
	mesh.Normal(vector_up)
	mesh.TexCoord(0, 0, 1)
	mesh.TexCoord(1, 0, 1)
	mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	mesh.AdvanceVertex()
	
	mesh.Position(Vector(100, 0, 80))
	mesh.Normal(vector_up)
	mesh.TexCoord(0, 0, 1)
	mesh.TexCoord(1, 0, 1)
	mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	mesh.AdvanceVertex()
	mesh.Position(Vector(0, 100, 80))
	mesh.Normal(vector_up)
	mesh.TexCoord(0, 1, 0)
	mesh.TexCoord(1, 1, 0)
	mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	mesh.AdvanceVertex()
	mesh.Position(Vector(100, 100, 80))
	mesh.Normal(vector_up)
	mesh.TexCoord(0, 1, 1)
	mesh.TexCoord(1, 1, 1)
	mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	mesh.AdvanceVertex()
	mesh.End()
	print(#self.IMesh)
	
	SplatoonSWEPs.RenderTarget.Ready = true
	self:ClearAllInk()
end

hook.Add("InitPostEntity", "SplatoonSWEPs: Clientside Initialization", Initialize)
