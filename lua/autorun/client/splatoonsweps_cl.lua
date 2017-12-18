
--Clientside ink manager
local InkAlpha = 255
local MeshColor = ColorAlpha(color_white, InkAlpha)
SplatoonSWEPs = SplatoonSWEPs or {
	IMesh = {},
	RenderTarget = {
		BaseTextureName = "splatoonsweps_rendertarget",
		NormalmapName = "splatoonsweps_normalmap",
		LightmapName = "splatoonsweps_lightmap",
		WaterMaterialName = "splatoonsweps_watermaterial",
	},
	SequentialSurfaces = {
		Angles = {},
		Areas = {},
		Bounds = {},
		Normals = {},
		Origins = {},
		u = {}, v = {},
		Vertices = {},
	},
	AreaBound = 0,
}
include "autorun/splatoonsweps_shared.lua"
include "autorun/splatoonsweps_bsp.lua"
include "autorun/splatoonsweps_const.lua"
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
	render.OverrideColorWriteEnable(false)
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
local INK_SURFACE_DELTA_NORMAL = .8 --Distance between map surface and ink mesh
local function Initialize()
	local self = SplatoonSWEPs
	local amb = render.GetAmbientLightColor()
	local level = amb:LengthSqr()
	if level > 1 then level = self.GrayScaleFactor:Dot(amb) end
	self.HDR = GetConVar "mat_hdr_level":GetInt() == 2
	self.InkLightLevel = math.Clamp(1 - level, 0.15, 0.55)
	self.BSP:Init() --Parsing BSP file
	self.BSP = nil
	collectgarbage "collect"
	
	local sortedsurfaces = {}
	local surf = self.SequentialSurfaces
	local NumMeshTriangles = 0
	for k in SortedPairsByValue(surf.Areas, true) do
		table.insert(sortedsurfaces, k)
		NumMeshTriangles = NumMeshTriangles + #surf.Vertices[k] - 2
		for i, vertex in ipairs(surf.Vertices[k]) do
			surf.Vertices[k][i] = {pos = vertex + surf.Normals[k] * INK_SURFACE_DELTA_NORMAL}
		end
	end
	
	local rtsize = math.min(self:GetRTSize(), render.MaxTextureWidth())
	local rtheight = math.min(self:GetRTSize(), render.MaxTextureHeight())
	local rtarea = rtsize^2
	local rtmergin = 2 / rtsize
	local rtmerginSqr = rtmergin^2
	local function GetUV(convertunit)
		local u, v, nextV = 0, 0, 0
		local convSqr = convertunit^2
		for _, k in ipairs(sortedsurfaces) do --Using next-fit approach
			local bound = surf.Bounds[k] / convertunit
			nextV = math.max(nextV, bound.y)
			if 1 - u < bound.x then 
				u, v, nextV = 0, v + nextV + rtmergin, bound.y
			end
			
			for i, vertex in ipairs(surf.Vertices[k]) do
				local UV = SplatoonSWEPs:To2D(vertex.pos, surf.Origins[k], surf.Angles[k]) / convertunit --Get UV coordinates
				surf.Vertices[k][i].u = UV.x + u
				surf.Vertices[k][i].v = UV.y + v
			end
			
			surf.u[k] = u
			surf.v[k] = v
			u = u + bound.x + rtmergin --Advance U-coordinate
		end
		
		return v + nextV
	end
	
	--Ratio[(units^2 / pixel^2)^1/2 -> units/pixel]
	self.RenderTarget.Ratio = math.max(math.sqrt(self.AreaBound / rtarea)) * 0.8
	
	--convertunit[pixel * units/pixel -> units]
	local loop = 0
	local convertunit = rtsize * self.RenderTarget.Ratio
	local maxY = GetUV(convertunit) --UV mapping to map geometry
	while maxY > 1 do
		convertunit = convertunit * ((maxY - 1) * 0.415 + 1.0005)
		maxY = GetUV(convertunit)
		loop = loop + 1
	end
	print("loops: ", loop, 100 - maxY * 100)
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
	local build, numtriangles = 1, NumMeshTriangles
	self.IMesh[build] = Mesh(self.RenderTarget.Material)
	mesh.Begin(self.IMesh[build], MATERIAL_TRIANGLES, math.min(numtriangles, MAX_TRIANGLES))
	for _, k in ipairs(sortedsurfaces) do
		for t = 3, #surf.Vertices[k] do
			for _, i in ipairs {t - 1, t, 1} do
				mesh.Normal(surf.Normals[k])
				mesh.Position(surf.Vertices[k][i].pos)
				mesh.TexCoord(0, surf.Vertices[k][i].u, surf.Vertices[k][i].v)
				mesh.TexCoord(1, surf.Vertices[k][i].u, surf.Vertices[k][i].v)
				mesh.AdvanceVertex()
			end
		
			if mesh.VertexCount() >= MAX_TRIANGLES * 3 then
				build = build + 1
				numtriangles = numtriangles - MAX_TRIANGLES
				mesh.End()
				self.IMesh[build] = Mesh(self.RenderTarget.Material)
				mesh.Begin(self.IMesh[build], MATERIAL_TRIANGLES, math.min(numtriangles, MAX_TRIANGLES))
			end
		end
		-- surf.Vertices[k] = nil
	end
	mesh.End()
	
	-- surf.Angles = nil
	surf.Areas = nil
	surf.Normals = nil
	-- surf.Origins = nil
	-- surf.Vertices = nil
	self.AreaBound = nil
	self.RenderTarget.Ready = true
	self:ClearAllInk()
	
	local set = physenv.GetPerformanceSettings()
	set.MaxVelocity = SplatoonSWEPs.MaxVelocity
	physenv.SetPerformanceSettings(set)
	collectgarbage "collect"
end

hook.Add("InitPostEntity", "SplatoonSWEPs: Clientside Initialization", Initialize)
