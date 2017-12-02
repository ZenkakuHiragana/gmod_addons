
--Clientside ink manager
local InkAlpha = 255
local MeshColor = ColorAlpha(color_white, InkAlpha)
SplatoonSWEPs = SplatoonSWEPs or {
	IMesh = {},
	Models = {},
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
	
	render.PushRenderTarget(SplatoonSWEPs.RenderTarget.Lightmap)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 255)
	render.PopRenderTarget()
	game.GetWorld():RemoveAllDecals()
end

--Mesh limitation is
-- 10922 = 32767 / 3 with mesh.Begin(),
-- 21845 = 65535 / 3 with BuildFromTriangles()
local MAX_TRIANGLES = math.floor(32768 / 3)
local INK_SURFACE_DELTA_NORMAL = 0.8 --Distance between map surface and ink mesh
local function Initialize()
	local self = SplatoonSWEPs
	self.HDR = GetConVar("mat_hdr_level"):GetInt() == 2
	self.InkLightLevel = self.HDR and 0.4 or 0.6
	self.BSP:Init() --Parsing BSP file
	-- self.BSP = nil
	self:InitSortSurfaces()
	
	local rtsize = math.min(self:GetRTSize(), render.MaxTextureWidth())
	local rtheight = math.min(self:GetRTSize(), render.MaxTextureHeight())
	local rtarea = rtsize^2
	local rtmergin = 2 / rtsize
	local rtmerginSqr = rtmergin^2
	local function GetUV(convertunit)
		local u, v, nextV = 0, 0, 0
		local convSqr = convertunit^2
		for _, face in ipairs(self.SortedSurfaces) do --Using next-fit approach
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
	
	--Ratio[(units^2 / pixel^2)^1/2 -> units/pixel] --, self.Surfaces.LongestEdge / rtsize)
	self.RenderTarget.Ratio = math.max(math.sqrt(self.Surfaces.AreaBound / rtarea))
	
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
	
	--21: IMAGE_FORMAT_BGRA5551, 19: IMAGE_FORMAT_BGRA4444
	self.RenderTarget.Ratio = convertunit / rtsize
	self.RenderTarget.BaseTexture = GetRenderTargetEx(
		self.RenderTarget.BaseTextureName,
		rtsize, rtheight,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.BaseTextureFlags,
		CREATERENDERTARGETFLAGS_HDR,
		19 --IMAGE_FORMAT_BGRA4444, 8192x8192, 128MB
	)
	self.RenderTarget.Normalmap = GetRenderTargetEx(
		self.RenderTarget.NormalmapName,
		rtsize, rtheight,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.NormalmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_BGRA8888 --8192x8192, 256MB
	)
	self.RenderTarget.Lightmap = GetRenderTargetEx(
		self.RenderTarget.LightmapName,
		rtsize / 2, rtheight / 2,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.LightmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_RGBA16161616 -- 4096x4096, 128MB
	)
	self.RenderTarget.Material = CreateMaterial(
		self.RenderTarget.BaseTextureName,
		"LightmappedGeneric",
		{
			["$basetexture"] = self.RenderTarget.BaseTexture:GetName(),
			["$bumpmap"] = self.RenderTarget.Normalmap:GetName(),
			["$ssbump"] = "1",
			["$translucent"] = "1",
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
	self.NumMeshTriangles = 0
	for i, face in ipairs(self.SortedSurfaces) do
		self.NumMeshTriangles = self.NumMeshTriangles + #face.MeshVertex - 2
	end
	
	local build, numtriangles = 1, self.NumMeshTriangles
	self.IMesh[build] = Mesh(self.RenderTarget.Material)
	mesh.Begin(self.IMesh[build], MATERIAL_TRIANGLES, math.min(numtriangles, MAX_TRIANGLES))
	for _, face in ipairs(self.SortedSurfaces) do
		for t = 3, #face.MeshVertex do
			for _, i in ipairs {t - 1, t, 1} do
				mesh.Normal(face.Parent.normal)
				mesh.Color(255, 255, 255, 255)
				mesh.Position(face.MeshVertex[i].pos)
				mesh.TexCoord(0, face.MeshVertex[i].u, face.MeshVertex[i].v)
				mesh.TexCoord(1, face.MeshVertex[i].u, face.MeshVertex[i].v)
				mesh.AdvanceVertex()
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
	
	-- self.IMesh[build + 1] = Mesh(self.RenderTarget.Material)
	-- mesh.Begin(self.IMesh[build + 1], MATERIAL_TRIANGLES, 2)
	-- mesh.Position(Vector(0, 0, 80))
	-- mesh.Normal(vector_up)
	-- mesh.TexCoord(0, 0, 0)
	-- mesh.TexCoord(1, 0, 0)
	-- mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	-- mesh.AdvanceVertex()
	-- mesh.Position(Vector(0, 100, 80))
	-- mesh.Normal(vector_up)
	-- mesh.TexCoord(0, 1, 0)
	-- mesh.TexCoord(1, 1, 0)
	-- mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	-- mesh.AdvanceVertex()
	-- mesh.Position(Vector(100, 0, 80))
	-- mesh.Normal(vector_up)
	-- mesh.TexCoord(0, 0, 1)
	-- mesh.TexCoord(1, 0, 1)
	-- mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	-- mesh.AdvanceVertex()
	
	-- mesh.Position(Vector(100, 0, 80))
	-- mesh.Normal(vector_up)
	-- mesh.TexCoord(0, 0, 1)
	-- mesh.TexCoord(1, 0, 1)
	-- mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	-- mesh.AdvanceVertex()
	-- mesh.Position(Vector(0, 100, 80))
	-- mesh.Normal(vector_up)
	-- mesh.TexCoord(0, 1, 0)
	-- mesh.TexCoord(1, 1, 0)
	-- mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	-- mesh.AdvanceVertex()
	-- mesh.Position(Vector(100, 100, 80))
	-- mesh.Normal(vector_up)
	-- mesh.TexCoord(0, 1, 1)
	-- mesh.TexCoord(1, 1, 1)
	-- mesh.Color(MeshColor.r, MeshColor.g, MeshColor.b, MeshColor.a)
	-- mesh.AdvanceVertex()
	-- mesh.End()
	-- print("number of IMesh", #self.IMesh)
	
	self.RenderTarget.Ready = true
	self:ClearAllInk()
end

hook.Add("InitPostEntity", "SplatoonSWEPs: Clientside Initialization", Initialize)
