
--Clientside ink manager
local ss = SplatoonSWEPs
SplatoonSWEPs = ss or {
	AreaBound = 0,
	BSP = {},
	Displacements = {},
	IMesh = {},
	InkQueue = {},
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
}

ss = SplatoonSWEPs
include "autorun/splatoonsweps_shared.lua"
include "splatoonsweps_userinfo.lua"
include "splatoonsweps_inkmanager_cl.lua"
include "splatoonsweps_network_cl.lua"
local rt = ss.RenderTarget
rt.BaseTextureFlags = bit.bor(
	ss.TEXTUREFLAGS.NOMIP,
	ss.TEXTUREFLAGS.NOLOD,
	ss.TEXTUREFLAGS.PROCEDURAL,
	ss.TEXTUREFLAGS.RENDERTARGET,
	ss.TEXTUREFLAGS.NODEPTHBUFFER
)
rt.NormalmapFlags = bit.bor(
	ss.TEXTUREFLAGS.NORMAL,
	ss.TEXTUREFLAGS.NOMIP,
	ss.TEXTUREFLAGS.NOLOD,
	ss.TEXTUREFLAGS.PROCEDURAL,
	ss.TEXTUREFLAGS.RENDERTARGET,
	ss.TEXTUREFLAGS.NODEPTHBUFFER,
	ss.TEXTUREFLAGS.SSBUMP
)
rt.LightmapFlags = bit.bor(
	ss.TEXTUREFLAGS.NOMIP,
	ss.TEXTUREFLAGS.NOLOD,
	ss.TEXTUREFLAGS.PROCEDURAL,
	ss.TEXTUREFLAGS.RENDERTARGET,
	ss.TEXTUREFLAGS.NODEPTHBUFFER
)

function ss:ClearAllInk()
	self.InkQueue = {}
	render.PushRenderTarget(self.RenderTarget.BaseTexture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideColorWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(self.RenderTarget.Normalmap)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(128, 128, 255, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(self.RenderTarget.Lightmap)
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
	ss.BSP:Init() --Parsing BSP file
	ss.BSP = nil
	local surf = ss.SequentialSurfaces
	local rtsize = math.min(ss.RTSize[ss:GetConVarInt "RTResolution"], render.MaxTextureWidth(), render.MaxTextureHeight())
	
	--21: IMAGE_FORMAT_BGRA5551, 19: IMAGE_FORMAT_BGRA4444
	rt.BaseTexture = GetRenderTargetEx(
		rt.BaseTextureName,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		rt.BaseTextureFlags,
		CREATERENDERTARGETFLAGS_HDR,
		19 --IMAGE_FORMAT_BGRA4444, 8192x8192, 128MB
	)
	rtsize = math.min(rt.BaseTexture:Width(), rt.BaseTexture:Height())
	rt.Normalmap = GetRenderTargetEx(
		rt.NormalmapName,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		rt.NormalmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		19 --IMAGE_FORMAT_BGRA4444, 8192x8192, 128MB
	)
	rt.Lightmap = GetRenderTargetEx(
		rt.LightmapName,
		rtsize / 2, rtsize / 2,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		rt.LightmapFlags,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_RGBA8888 --4096x4096, 64MB
	)
	rt.Material = CreateMaterial(
		rt.RenderTargetName,
		"LightmappedGeneric",
		{
			["$basetexture"] = rt.BaseTextureName,
			["$bumpmap"] = rt.NormalmapName,
			["$ssbump"] = "1",
			["$nolod"] = "1",
			["$alpha"] = ".95",
			["$alphatest"] = "1",
			["$alphatestreference"] = ".5",
			["$allowalphatocoverage"] = "1",
		}
	)
	ss.IMesh[1] = Mesh(rt.Material)
	rt.WaterMaterial = CreateMaterial(
		rt.WaterMaterialName,
		"Refract",
		{
			["$normalmap"] = rt.NormalmapName,
			["$nolod"] = "1",
			["$bluramount"] = "2",
			["$refractamount"] = ".1",
			["$refracttint"] = "[1 1 1]",
		}
	)
	
	local rtarea = rtsize^2
	local rtmergin = 4 / rtsize
	local arearatio = math.sqrt(ss.AreaBound / rtarea) * 1.18 --arearatio[(units^2 / pixel^2)^1/2 -> units/pixel]
	local convertunit = rtsize * arearatio --convertunit[pixel * units/pixel -> units]
	local sortedsurfs, movesurfs = {}, {}
	local NumMeshTriangles, nummeshes, dv, divuv, half = 0, 1, 0, 1
	local u, v, nv, bu, bv, bk = 0, 0, 0 --cursor(u, v), shelf height, rectangle size(u, v), beginning of k
	function ss:PixelsToUnits(pixels) return pixels * arearatio end
	function ss:PixelsToUV(pixels) return pixels / rtsize end
	function ss:UnitsToPixels(units) return units / arearatio end
	function ss:UnitsToUV(units) return units / convertunit end
	function ss:UVToPixels(uv) return uv * rtsize end
	function ss:UVToUnits(uv) return uv * convertunit end
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
			local UV = ss:To2D(vertex, surf.Origins[k], surf.Angles[k]) / convertunit
			surf.Vertices[k][i] = {pos = meshvert, u = UV.x + u, v = UV.y + v}
		end
		
		if ss.Displacements[k] then
			NumMeshTriangles = NumMeshTriangles + #ss.Displacements[k].Triangles - 2
			for i = 0, #ss.Displacements[k].Positions do
				local vertex = ss.Displacements[k].Positions[i]
				local meshvert = vertex.pos - surf.Normals[k] * surf.Normals[k]:Dot(vertex.vec * vertex.dist)
				local UV = ss:To2D(meshvert, surf.Origins[k], surf.Angles[k]) / convertunit
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
	mesh.Begin(ss.IMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
	local function ContinueMesh()
		if mesh.VertexCount() >= MAX_TRIANGLES * 3 then
			mesh.End()
			nummeshes, NumMeshTriangles = nummeshes + 1, NumMeshTriangles - MAX_TRIANGLES
			ss.IMesh[nummeshes] = Mesh(rt.Material)
			mesh.Begin(ss.IMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
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
			
			if ss.Displacements[k] then
				for i = 0, #ss.Displacements[k].Positions do
					local vertex = ss.Displacements[k].Positions[i]
					vertex.u, vertex.v = vertex.v - dv, vertex.u
				end
			end
		end
		
		surf.u[k], surf.v[k] = surf.u[k] / divuv, surf.v[k] / divuv
		if ss.Displacements[k] then
			local verts = ss.Displacements[k].Positions
			for _, v in pairs(verts) do v.u, v.v = v.u / divuv, v.v / divuv end
			for _, v in ipairs(surf.Vertices[k]) do v.u, v.v = v.u / divuv, v.v / divuv end
			for _, t in ipairs(ss.Displacements[k].Triangles) do
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
			ss.Displacements[k] = nil
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
	
	-- surf.Areas, ss.Displacements, surf.Vertices, surf.AreaBound = nil
	ss:ClearAllInk()
	collectgarbage "collect"
end)

hook.Add("PrePlayerDraw", "SplatoonSWEPs: Hide players on crouch", function(ply)
	local weapon = ss:IsValidInkling(ply)
	if not weapon then return end
	if weapon:GetPMID() == ss.PLAYER.NOSQUID then
		return weapon:GetInInk() or nil
	else
		return ply:Crouching() or nil
	end
end)

hook.Add("RenderScreenspaceEffects", "SplatoonSWEPs: First person ink overlay", function()
	if LocalPlayer():ShouldDrawLocalPlayer()
	or ss:GetConVarBool "HideInkOverlay" then return end
	local weapon = ss:IsValidInkling(LocalPlayer())
	if not (weapon and weapon:GetInInk()) then return end
	local color = weapon:GetInkColorProxy()
	DrawMaterialOverlay("effects/water_warp01", .1)
	surface.SetDrawColor(ColorAlpha(color:ToColor(),
	48 * (1.1 - math.sqrt(ss.GrayScaleFactor:Dot(color)))
	/ ss.GrayScaleFactor:Dot(render.GetToneMappingScaleLinear())))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end)
