
--Clientside ink manager
CreateConVar("sv_splatoonsweps_enabled", "1",
{FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE},
"Enables or disables SplatoonSWEPs.")
if not GetConVar "sv_splatoonsweps_enabled":GetBool() then return end
SplatoonSWEPs = SplatoonSWEPs or {
	AmbientColor = color_white,
	AreaBound = 0,
	AspectSum = 0,
	AspectSumX = 0,
	AspectSumY = 0,
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
	SetupProgress = 0,
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

local ss = SplatoonSWEPs
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
	local amb = self.AmbientColor or render.GetAmbientLightColor():ToColor()
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
	render.Clear(amb.r, amb.g, amb.b, 255)
	render.PopRenderTarget()
	game.GetWorld():RemoveAllDecals()
end

hook.Add("InitPostEntity", "SplatoonSWEPs: Clientside initialization", function()
	local rtsize = math.min(ss.RTSize[ss:GetConVarInt "RTResolution"], render.MaxTextureWidth(), render.MaxTextureHeight())
	ss.AmbientColor = render.GetAmbientLightColor():ToColor()
	
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
	
	net.Start "SplatoonSWEPs: Setup ink surface"
	net.WriteUInt(ss.SETUPMODE.BEGIN, ss.SETUP_BITS)
	net.SendToServer()
end)

hook.Add("PrePlayerDraw", "SplatoonSWEPs: Hide players on crouch", function(ply)
	local weapon = ss:IsValidInkling(ply)
	if not weapon then return end
	if weapon:GetPMID() == ss.PLAYER.NOSQUID then
		ply:DrawShadow(not weapon:GetInInk())
		return weapon:GetInInk() or nil
	else
		ply:DrawShadow(not ply:Crouching())
		return ply:Crouching() or nil
	end
end)

hook.Add("RenderScreenspaceEffects", "SplatoonSWEPs: First person ink overlay", function()
	if LocalPlayer():ShouldDrawLocalPlayer() or ss:GetConVarBool "HideInkOverlay" then return end
	local weapon = ss:IsValidInkling(LocalPlayer())
	if not (weapon and weapon:GetInInk()) then return end
	local color = weapon:GetInkColorProxy()
	DrawMaterialOverlay("effects/water_warp01", .1)
	surface.SetDrawColor(ColorAlpha(color:ToColor(),
	48 * (1.1 - math.sqrt(ss.GrayScaleFactor:Dot(color))) / ss.GrayScaleFactor:Dot(render.GetToneMappingScaleLinear())))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end)

hook.Add("HUDPaint", "SplatoonSWEPs: Loading bar", function()
	if rt.Ready then hook.Remove("HUDPaint", "SplatoonSWEPs: Loading bar") return end
	surface.SetFont "ChatFont"
	local tw = surface.GetTextSize "SplatoonSWEPs: Loading..."
	local w = math.min(ScrW() * .99 - tw, ScrW() * 7/8)
	surface.SetTextColor(color_white)
	surface.SetTextPos(w, ScrH() / 40)
	surface.DrawText "SplatoonSWEPs: Loading..."
	surface.SetDrawColor(0, 0, 0, 128)
	surface.DrawRect(w, ScrH() / 20, tw, ScrH() / 60)
	surface.SetDrawColor(0, 255, 0)
	surface.DrawRect(w + ScrW() * 1/400, ScrH() * (1/20 + 1/400),
	(tw - ScrW() * 2/400) * (ss.SetupProgress or 1), ScrH() * (1/60 - 2/400))
	surface.SetDrawColor(192, 255, 192)
	surface.DrawRect(w + ScrW() * 1/400, ScrH() * (1/20 + 1/400),
	(tw - ScrW() * 2/400) * (ss.SetupProgress or 1), ScrH() * (1/60 - 2/400) / 5)
end)
