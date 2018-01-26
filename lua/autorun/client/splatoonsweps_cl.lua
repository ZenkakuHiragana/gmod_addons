
--Clientside ink manager
SplatoonSWEPs = SplatoonSWEPs or {
	Displacements = {},
	IMesh = {},
	RenderTarget = {
		BaseTextureName = "splatoonsweps_basetexture",
		NormalmapName = "splatoonsweps_normalmap",
		LightmapName = "splatoonsweps_lightmap",
		RenderTargetName = "splatoonsweps_rendertarget",
		WaterMaterialName = "splatoonsweps_watermaterial",
	},
	SequentialSurfaces = {
		Angles = {},
		Areas = {},
		Bounds = {},
		Moved = {},
		Normals = {},
		Origins = {},
		u = {}, v = {},
		Vertices = {},
	},
	AreaBound = 0,
}

include "autorun/splatoonsweps_shared.lua"
include "splatoonsweps_userinfo.lua"
include "splatoonsweps_inkmanager_cl.lua"
include "splatoonsweps_network_cl.lua"
SplatoonSWEPs.RenderTarget.BaseTextureFlags = bit.bor(
	SplatoonSWEPs.TEXTUREFLAGS.PROCEDURAL,
	SplatoonSWEPs.TEXTUREFLAGS.RENDERTARGET,
	SplatoonSWEPs.TEXTUREFLAGS.NODEPTHBUFFER
)
SplatoonSWEPs.RenderTarget.NormalmapFlags = bit.bor(
	SplatoonSWEPs.TEXTUREFLAGS.NORMAL,
	SplatoonSWEPs.TEXTUREFLAGS.PROCEDURAL,
	SplatoonSWEPs.TEXTUREFLAGS.RENDERTARGET,
	SplatoonSWEPs.TEXTUREFLAGS.NODEPTHBUFFER,
	SplatoonSWEPs.TEXTUREFLAGS.SSBUMP
)
SplatoonSWEPs.RenderTarget.LightmapFlags = bit.bor(
	SplatoonSWEPs.TEXTUREFLAGS.PROCEDURAL,
	SplatoonSWEPs.TEXTUREFLAGS.RENDERTARGET,
	SplatoonSWEPs.TEXTUREFLAGS.NODEPTHBUFFER
)

function SplatoonSWEPs:ClearAllInk()
	SplatoonSWEPs.InkQueue = {}
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
	local amb = render.GetAmbientLightColor():ToColor()
	render.Clear(amb.r, amb.g, amb.b, 255)
	render.PopRenderTarget()
	game.GetWorld():RemoveAllDecals()
end

--Mesh limitation is
-- 10922 = 32767 / 3 with mesh.Begin(),
-- 21845 = 65535 / 3 with BuildFromTriangles()
local MAX_TRIANGLES = math.floor(32768 / 3)
local INK_SURFACE_DELTA_NORMAL = .8 --Distance between map surface and ink mesh
hook.Add("InitPostEntity", "SplatoonSWEPs: Clientside Initialization", function()
	SplatoonSWEPs.BSP:Init() --Parsing BSP file
	SplatoonSWEPs.BSP = nil
	local self = SplatoonSWEPs
	local surf = self.SequentialSurfaces
	local rtsize = math.min(self.RTSize[self:GetConVarInt "RTResolution"], render.MaxTextureWidth(), render.MaxTextureHeight())
	
	--21: IMAGE_FORMAT_BGRA5551, 19: IMAGE_FORMAT_BGRA4444
	self.RenderTarget.BaseTexture = GetRenderTargetEx(
		self.RenderTarget.BaseTextureName,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.BaseTextureFlags,
		CREATERENDERTARGETFLAGS_HDR,
		19 --IMAGE_FORMAT_BGRA4444, 8192x8192, 128MB
	)
	rtsize = math.min(self.RenderTarget.BaseTexture:Width(), self.RenderTarget.BaseTexture:Height())
	self.RenderTarget.Normalmap = GetRenderTargetEx(
		self.RenderTarget.NormalmapName,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.NormalmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		19 --IMAGE_FORMAT_BGRA4444, 8192x8192, 128MB
	)
	self.RenderTarget.Lightmap = GetRenderTargetEx(
		self.RenderTarget.LightmapName,
		rtsize / 2, rtsize / 2,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.RenderTarget.LightmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_RGBA8888 --4096x4096, 64MB
	)
	self.RenderTarget.Material = CreateMaterial(
		self.RenderTarget.RenderTargetName,
		"LightmappedGeneric",
		{
			["$basetexture"] = self.RenderTarget.BaseTextureName,
			["$bumpmap"] = self.RenderTarget.NormalmapName,
			["$ssbump"] = "1",
			["$alpha"] = ".95",
			["$alphatest"] = "1",
			["$alphatestreference"] = ".5",
			["$allowalphatocoverage"] = "1",
		}
	)
	self.IMesh[1] = Mesh(self.RenderTarget.Material)
	self.RenderTarget.WaterMaterial = CreateMaterial(
		self.RenderTarget.WaterMaterialName,
		"Refract",
		{
			["$normalmap"] = self.RenderTarget.NormalmapName,
			["$bluramount"] = "2",
			["$refractamount"] = "1.1",
			["$refracttint"] = "[.9 .9 .9]",
		}
	)
	
	local rtarea = rtsize^2
	local rtmergin = 4 / rtsize
	local arearatio = math.sqrt(self.AreaBound / rtarea) * 1.18 --arearatio[(units^2 / pixel^2)^1/2 -> units/pixel]
	local convertunit = rtsize * arearatio --convertunit[pixel * units/pixel -> units]
	local sortedsurfs, movesurfs = {}, {}
	local NumMeshTriangles, nummeshes, dv, divuv, half = 0, 1, 0, 1
	local u, v, nv, bu, bv, bk = 0, 0, 0 --cursor(u, v), shelf height, rectangle size(u, v), beginning of k
	function self:PixelsToUnits(pixels) return pixels * arearatio end
	function self:PixelsToUV(pixels) return pixels / rtsize end
	function self:UnitsToPixels(units) return units / arearatio end
	function self:UnitsToUV(units) return units / convertunit end
	function self:UVToPixels(uv) return uv * rtsize end
	function self:UVToUnits(uv) return uv * convertunit end
	for k in SortedPairsByValue(surf.Areas, true) do
		table.insert(sortedsurfs, k)
		NumMeshTriangles = NumMeshTriangles + #surf.Vertices[k] - 2
		
		bu, bv = surf.Bounds[k].x / convertunit, surf.Bounds[k].y / convertunit
		nv = math.max(nv, bv) --UV-coordinate placement, using next-fit approach
		if u + bu > 1 then --Creating a new shelf
			if v + nv + rtmergin > 1 then table.insert(movesurfs, {id = bk, v = v}) end
			u, v, nv = 0, v + nv + rtmergin, bv
		end
		
		if u == 0 then bk = #sortedsurfs end --The first element of the current shelf
		for i, vertex in ipairs(surf.Vertices[k]) do --Get UV coordinates
			local meshvert = vertex + surf.Normals[k] * INK_SURFACE_DELTA_NORMAL
			local UV = self:To2D(vertex, surf.Origins[k], surf.Angles[k]) / convertunit
			surf.Vertices[k][i] = {pos = meshvert, u = UV.x + u, v = UV.y + v}
		end
		
		if self.Displacements[k] then
			NumMeshTriangles = NumMeshTriangles + #self.Displacements[k].Triangles - 2
			for i = 0, #self.Displacements[k].Positions do
				local vertex = self.Displacements[k].Positions[i]
				local meshvert = vertex.pos - surf.Normals[k] * surf.Normals[k]:Dot(vertex.vec * vertex.dist)
				local UV = self:To2D(meshvert, surf.Origins[k], surf.Angles[k]) / convertunit
				vertex.u, vertex.v = UV.x + u, UV.y + v
			end
		end
		
		surf.u[k], surf.v[k] = u, v
		u = u + bu + rtmergin --Advance U-coordinate
	end
	
	if v + nv > 1 and #movesurfs > 0 then
		local min, halfv = math.huge, movesurfs[#movesurfs].v / 2 + .5
		for _, m in ipairs(movesurfs) do
			local v = math.abs(m.v - halfv)
			if v < min then min, half = v, m end
		end
		
		dv = half.v - 1
		divuv = math.max(half.v, v + nv - dv)
		arearatio = arearatio * divuv
		convertunit = convertunit * divuv
	end
	
	--Building MeshVertex
	mesh.Begin(self.IMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
	local function ContinueMesh()
		if mesh.VertexCount() >= MAX_TRIANGLES * 3 then
			mesh.End()
			nummeshes, NumMeshTriangles = nummeshes + 1, NumMeshTriangles - MAX_TRIANGLES
			self.IMesh[nummeshes] = Mesh(self.RenderTarget.Material)
			mesh.Begin(self.IMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
		end
	end
	
	for sortedID, k in ipairs(sortedsurfs) do
		if half and sortedID >= half.id then
			surf.Angles[k]:RotateAroundAxis(surf.Normals[k], -90)
			surf.Bounds[k].x, surf.Bounds[k].y, surf.u[k], surf.v[k], surf.Moved[k]
				= surf.Bounds[k].y, surf.Bounds[k].x, surf.v[k] - dv, surf.u[k], true
			for _, vertex in ipairs(surf.Vertices[k]) do
				vertex.u, vertex.v = vertex.v - dv, vertex.u
			end
			
			if self.Displacements[k] then
				for i = 0, #self.Displacements[k].Positions do
					local vertex = self.Displacements[k].Positions[i]
					vertex.u, vertex.v = vertex.v - dv, vertex.u
				end
			end
		end
		
		surf.u[k], surf.v[k] = surf.u[k] / divuv, surf.v[k] / divuv
		if self.Displacements[k] then
			local verts = self.Displacements[k].Positions
			for _, v in pairs(verts) do v.u, v.v = v.u / divuv, v.v / divuv end
			for _, v in ipairs(surf.Vertices[k]) do v.u, v.v = v.u / divuv, v.v / divuv end
			for _, t in ipairs(self.Displacements[k].Triangles) do
				local tv = {verts[t[1]], verts[t[2]], verts[t[3]]}
				local n = (tv[1].pos - tv[2].pos):Cross(tv[3].pos - tv[2].pos):GetNormalized()
				for _, p in ipairs(tv) do
					mesh.Normal(n)
					mesh.Position(p.pos + n * INK_SURFACE_DELTA_NORMAL)
					mesh.TexCoord(0, p.u, p.v)
					mesh.TexCoord(1, p.u, p.v)
					mesh.AdvanceVertex()
				end
				
				ContinueMesh()
			end
			self.Displacements[k] = nil
		else
			for t, v in ipairs(surf.Vertices[k]) do
				v.u, v.v = v.u / divuv, v.v / divuv
				if t < 3 then continue end
				for _, i in ipairs {t - 1, t, 1} do
					local v = surf.Vertices[k][i]
					mesh.Normal(surf.Normals[k])
					mesh.Position(v.pos)
					mesh.TexCoord(0, v.u, v.v)
					mesh.TexCoord(1, v.u, v.v)
					mesh.AdvanceVertex()
				end
				
				ContinueMesh()
			end
		end
		-- surf.Areas[k], surf.Vertices[k] = nil
	end
	mesh.End()
	
	-- surf.Areas, self.Displacements, surf.Vertices, surf.AreaBound = nil
	self:ClearAllInk()
	collectgarbage "collect"
end)

hook.Add("PlayerPreDraw", "SplatoonSWEPs: Hide players on crouch", function(ply)
	local weapon = SplatoonSWEPs:IsValidInkling(ply)
	return weapon and weapon:GetPMID() ~= SplatoonSWEPs.PLAYER.NOSQUID and ply:Crouching() or nil
end)

hook.Add("RenderScreenspaceEffects", "SplatoonSWEPs: First person ink overlay", function()
	if LocalPlayer():ShouldDrawLocalPlayer()
	or SplatoonSWEPs:GetConVarBool "HideInkOverlay" then return end
	local weapon = SplatoonSWEPs:IsValidInkling(LocalPlayer())
	if not (weapon and weapon:GetInInk()) then return end
	local color = weapon:GetInkColorProxy()
	DrawMaterialOverlay("effects/water_warp01", .1)
	surface.SetDrawColor(ColorAlpha(color:ToColor(),
	48 * (1.1 - math.sqrt(SplatoonSWEPs.GrayScaleFactor:Dot(color)))
	/ SplatoonSWEPs.GrayScaleFactor:Dot(render.GetToneMappingScaleLinear())))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end)
