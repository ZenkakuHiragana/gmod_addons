
-- Clientside SplatoonSWEPs structure

SplatoonSWEPs = SplatoonSWEPs or {
	AmbientColor = color_white,
	AreaBound = 0,
	AspectSum = 0,				-- Sum of aspect ratios for each surface
	AspectSumX = 0,				-- Sum of widths for each surface
	AspectSumY = 0,				-- Sum of heights for each surface
	CrosshairColors = {},
	IMesh = {},
	InkColors = {},
	InkShotMaterials = {},
	InkQueue = {},
	LastHitID = {},
	Models = {},
	PaintQueue = {},
	PaintSchedule = {},
	PlayerHullChanged = {},
	PlayerShouldResetCamera = {},
	RenderTarget = {},
	WeaponRecord = {},
}

include "splatoonsweps/const.lua"
include "drawarc.lua"
include "inkmanager.lua"
include "network.lua"
include "splatoonsweps/shared.lua"
include "userinfo.lua"

local ss = SplatoonSWEPs
if not ss.GetOption "enabled" then
	for h, t in pairs(hook.GetTable()) do
		for name, func in pairs(t) do
			if ss.ProtectedCall(name.find, name, "SplatoonSWEPs") then
				hook.Remove(h, name)
			end
		end
	end

	table.Empty(SplatoonSWEPs)
	SplatoonSWEPs = nil
	return
end

local rt = ss.RenderTarget
local crashpath = "splatoonsweps/crashdump.txt" -- Existing this means the client crashed before.
local MAX_TRIANGLES = math.floor(32768 / 3) -- mesh library limitation
local INK_SURFACE_DELTA_NORMAL = .8 -- Distance between map surface and ink mesh
function ss.PrepareInkSurface(data)
	ss.AABBTree = ss.RestoreJSONLimit(data.AABBTree)
	ss.SurfaceArray = ss.RestoreJSONLimit(data.SurfaceArray)
	ss.AreaBound  = data.UVInfo.AreaBound
	ss.AspectSum  = data.UVInfo.AspectSum
	ss.AspectSumX = data.UVInfo.AspectSumX
	ss.AspectSumY = data.UVInfo.AspectSumY

	if ss.SplatoonMapPorts[game.GetMap()] then INK_SURFACE_DELTA_NORMAL = 2 end
	local numsurfs = #ss.SurfaceArray
	local rtsize = rt.BaseTexture:Width()
	local rtarea = rtsize^2
	local rtmargin = 4 / rtsize -- Render Target margin
	local arearatio = 41.3329546960896 / rtsize * -- arearatio[units/pixel], Found by Excel bulldozing
	(ss.AreaBound * ss.AspectSum / numsurfs * ss.AspectSumX / ss.AspectSumY / 2500 + numsurfs)^.523795515713613
	local convertunit = rtsize * arearatio -- convertunit[units/pixel], A[pixel] * units/pixel -> A[units]
	local sortedsurfs, movesurfs = {}, {}
	local NumMeshTriangles, nummeshes, dv, divuv, half = 0, 1, 0, 1
	local u, v, nv, bu, bv, bk = 0, 0, 0 -- cursor(u, v), shelf height, rectangle size(u, v), beginning of k
	for k, s in SortedPairsByMemberValue(ss.SurfaceArray, "Area", true) do -- Placement of map polygons by Next-Fit algorithm.
		sortedsurfs[#sortedsurfs + 1] = s.Index
		NumMeshTriangles = NumMeshTriangles + #s.Vertices - 2

		bu, bv = s.Bound.x / convertunit, s.Bound.y / convertunit
		nv = math.max(nv, bv)
		if u + bu > 1 then -- Creating a new shelf
			if v + nv + rtmargin > 1 then
				movesurfs[#movesurfs + 1] = {id = bk, v = v}
			end

			u, v, nv = 0, v + nv + rtmargin, bv
		end

		if u == 0 then bk = #sortedsurfs end -- Storing the first element of current shelf
		for i, vert in ipairs(s.Vertices) do -- Get UV coordinates
			local meshvert = vert + s.Normal * INK_SURFACE_DELTA_NORMAL
			local UV = ss.To2D(vert, s.Origin, s.Angles) / convertunit
			s.Vertices[i] = {pos = meshvert, u = UV.x + u, v = UV.y + v}
		end

		if s.Displacement then
			NumMeshTriangles = NumMeshTriangles + #s.Displacement.Triangles - 2
			for i, vt in ipairs(s.Displacement.Vertices) do
				local UV = ss.To2D(s.Displacement.VerticesGrid[i], s.Origin, s.Angles) / convertunit
				s.Displacement.Vertices[i] = {pos = vt, u = UV.x + u, v = UV.y + v}
			end
		end

		s.u, s.v = u, v
		u = u + bu + rtmargin -- Advance U-coordinate
	end

	if v + nv > 1 and #movesurfs > 0 then -- RT could not store all polygons
		local min, halfv = math.huge, movesurfs[#movesurfs].v / 2 + .5
		for _, m in ipairs(movesurfs) do -- Then move the remainings to the left
			local v = math.abs(m.v - halfv)
			if v < min then min, half = v, m end
		end

		dv = half.v - 1 - rtmargin
		divuv = math.max(half.v, v + nv - dv) -- Shrink RT
		arearatio = arearatio * divuv
		convertunit = convertunit * divuv
	end

	print("SplatoonSWEPs: Total mesh triangles = ", NumMeshTriangles)

	for i = 1, math.ceil(NumMeshTriangles / MAX_TRIANGLES) do
		ss.IMesh[#ss.IMesh + 1] = Mesh(ss.RenderTarget.Material)
	end

	-- Building MeshVertex
	if #ss.IMesh > 0 then
		mesh.Begin(ss.IMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
		local function ContinueMesh()
			if mesh.VertexCount() < MAX_TRIANGLES * 3 then return end
			mesh.End()
			mesh.Begin(ss.IMesh[nummeshes + 1], MATERIAL_TRIANGLES,
			math.min(NumMeshTriangles - MAX_TRIANGLES * nummeshes, MAX_TRIANGLES))
			nummeshes = nummeshes + 1
		end

		for sortedID, k in ipairs(sortedsurfs) do
			local s = ss.SurfaceArray[k]
			if half and sortedID >= half.id then -- If current polygon is moved
				local bu = s.Bound.x / convertunit * divuv
				s.u, s.v = s.v - dv, 1 - s.u - bu
				s.Moved = true
				for _, vert in ipairs(s.Vertices) do
					vert.u, vert.v = vert.v - dv, 1 - vert.u
				end

				if s.Displacement then
					for i, vert in ipairs(s.Displacement.Vertices) do
						vert.u, vert.v = vert.v - dv, 1 - vert.u
					end
				end
			end

			s.u, s.v = s.u / divuv, s.v / divuv
			if s.Displacement then
				local verts = s.Displacement.Vertices
				for _, v in ipairs(verts) do v.u, v.v = v.u / divuv, v.v / divuv end
				for _, v in ipairs(s.Vertices) do v.u, v.v = v.u / divuv, v.v / divuv end
				for _, t in ipairs(s.Displacement.Triangles) do
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
			else
				for t, v in ipairs(s.Vertices) do
					v.u, v.v = v.u / divuv, v.v / divuv
					if t > 2 then
						for _, i in ipairs {t - 1, t, 1} do
							local v = s.Vertices[i]
							mesh.Normal(s.Normal)
							mesh.Position(v.pos)
							mesh.TexCoord(0, v.u, v.v)
							mesh.TexCoord(1, v.u, v.v)
							mesh.AdvanceVertex()
						end

						ContinueMesh()
					end
				end
			end
		end
		mesh.End()
	end

	ss.ClearAllInk()
	ss.InitializeMoveEmulation(LocalPlayer())
	net.Start "SplatoonSWEPs: Ready to splat"
	net.WriteString(LocalPlayer():SteamID64())
	net.SendToServer()
	ss.WeaponRecord[LocalPlayer()] = util.JSONToTable(
	util.Decompress(file.Read "splatoonsweps/record/stats.txt" or "") or "") or {
		Duration = {},
		Inked = {},
		Recent = {},
	}

	ss.PixelsToUnits = arearatio
	ss.UVToUnits = convertunit
	ss.UVToPixels = rtsize
	ss.UnitsToPixels = 1 / ss.PixelsToUnits
	ss.UnitsToUV = 1 / ss.UVToUnits
	ss.PixelsToUV = 1 / ss.UVToPixels
	ss.RenderTarget.Ready = true
	collectgarbage "collect"
end

local IMAGE_FORMAT_BGRA5551 = 21
local IMAGE_FORMAT_BGRA4444 = 19
hook.Add("InitPostEntity", "SplatoonSWEPs: Clientside initialization", function()
	if not file.Exists("splatoonsweps", "DATA") then file.CreateDir "splatoonsweps" end
	if file.Exists(crashpath, "DATA") then -- If the client has crashed before, RT shrinks.
		local res = ss.GetConVar "rtresolution"
		if res then res:SetInt(rt.RESOLUTION.MINIMUM) end
		notification.AddLegacy(ss.Text.Error.CrashDetected, NOTIFY_GENERIC, 15)
	end

	file.Write(crashpath, "")
	ss.AmbientColor = render.GetAmbientLightColor():ToColor()

	local rtsize = math.min(rt.Size[ss.GetOption "rtresolution"] or 1, render.MaxTextureWidth(), render.MaxTextureHeight())
	rt.BaseTexture = GetRenderTargetEx(
		rt.Name.BaseTexture,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		rt.Flags.BaseTexture,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_BGRA4444 -- 8192x8192, 128MB
	)
	rtsize = math.min(rt.BaseTexture:Width(), rt.BaseTexture:Height())
	rt.Normalmap = GetRenderTargetEx(
		rt.Name.Normalmap,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		rt.Flags.Normalmap,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_BGRA4444 -- 8192x8192, 128MB
	)
	rt.Lightmap = GetRenderTargetEx(
		rt.Name.Lightmap,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		rt.Flags.Lightmap,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_RGBA8888 -- 8192x8192, 256MB
	)
	rt.InkSplash = GetRenderTargetEx( -- For flying ink effect, used by Rollers and Sloshers
		rt.Name.InkSplash,
		128, 128,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		rt.Flags.InkSplash,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_RGBA8888
	)
	rt.Material = CreateMaterial(
		rt.Name.RenderTarget,
		"LightmappedGeneric",
		{
			["$basetexture"] = rt.Name.BaseTexture,
			["$bumpmap"] = rt.Name.Normalmap,
			["$ssbump"] = "1",
			["$nolod"] = "1",
			["$alpha"] = "0.9",
			["$alphatest"] = "1",
			["$alphatestreference"] = "0.0625",
		}
	)
	rt.WaterMaterial = CreateMaterial(
		rt.Name.WaterMaterial,
		"Refract",
		{
			["$normalmap"] = rt.Name.Normalmap,
			["$nolod"] = "1",
			["$bluramount"] = "2",
			["$refractamount"] = ".125",
			["$refracttint"] = "[1 1 1]",
		}
	)
	rt.InkSplashMaterial = CreateMaterial(
		rt.Name.InkSplashMaterial,
		"UnlitGeneric",
		{
			["$basetexture"] = rt.Name.InkSplash,
			["$nolod"] = "1",
			["$alphatest"] = "1",
			["$alphatestreference"] = "0.5",
			["$vertexcolor"] = "1",
		}
	)

	file.Delete(crashpath) -- Succeeded to make RTs and remove crash detection

	-- Checking ink map in data/
	local path = ("splatoonsweps/%s.txt"):format(game.GetMap())
	local pathbsp = ("maps/%s.bsp"):format(game.GetMap())
	local inkCRCServer = GetGlobalString "SplatoonSWEPs: Ink map CRC"
	local dataJSON = file.Read(path) or file.Read("data/" .. path, true) or ""
	local dataTable = util.JSONToTable(util.Decompress(dataJSON))
	local mapCRC = tonumber(util.CRC(file.Read(pathbsp, true)))
	local inkCRC = util.CRC(dataJSON)
	local isvalid = dataTable.MapCRC == mapCRC and (ss.sp or inkCRC == inkCRCServer)
	local UseDownloaded = false
	if ss.mp and not isvalid then -- Local ink cache ~= Ink cache from server
		file.Rename(path, path .. ".txt")
		dataJSON = file.Read("data/" .. path, true) or ""
		dataTable = util.JSONToTable(util.Decompress(dataJSON))
		inkCRC = util.CRC(dataJSON)
		isvalid = dataTable.MapCRC == mapCRC and inkCRC == inkCRCServer
		UseDownloaded = true
		file.Rename(path .. ".txt", path)
	end

	if isvalid then ss.PrepareInkSurface(dataTable) return end
	net.Start "SplatoonSWEPs: Redownload ink data"
	net.SendToServer()
	notification.AddProgress("SplatoonSWEPs: Redownload ink data", "Downloading ink map...")
end)

-- Local player isn't considered by Trace.  This is a poor workaround.
function ss.TraceLocalPlayer(start, dir)
	local lp = LocalPlayer()
	return util.IntersectRayWithOBB(start, dir, lp:GetPos(), lp:GetRenderAngles(), lp:OBBMins(), lp:OBBMaxs())
end

local Water80 = Material "effects/flicker_128"
local Water90 = Material "effects/water_warp01"
function ss.GetWaterMaterial()
	return render.GetDXLevel() < 90 and Water80 or Water90
end

function ss.PostPlayerDraw(w, ply) render.SetBlend(1) end
function ss.PrePlayerDraw(w, ply)
	local ShouldNoDraw = Either(w:GetNWBool "becomesquid" and IsValid(w.Squid), ply:Crouching(), w:GetInInk())
	if ShouldNoDraw then return true end
	if w:IsCarriedByLocalPlayer() then render.SetBlend(w:GetCameraFade() * ply:GetColor().a / 255) end
	return ss.ProtectedCall(w.ManipulatePlayer, w, ply)
end

function ss.RenderScreenspaceEffects(w)
	ss.ProtectedCall(w.RenderScreenspaceEffects, w)
	if not w:GetInInk() or LocalPlayer():ShouldDrawLocalPlayer() or not ss.GetOption "drawinkoverlay" then return end
	local color = w:GetInkColorProxy()
	DrawMaterialOverlay(render.GetDXLevel() < 90 and "effects/flicker_128" or "effects/water_warp01", .1)
	surface.SetDrawColor(ColorAlpha(color:ToColor(),
	48 * (1.1 - math.sqrt(ss.GrayScaleFactor:Dot(color))) / ss.GrayScaleFactor:Dot(render.GetToneMappingScaleLinear())))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end

function ss.PostRender(w)
	if ss.RenderingRTScope then return end
	if not (w.Scoped and w.RTScope) then return end
	local vm = w:GetViewModel()
	if not IsValid(vm) then return end
	if not w:GetNWBool "usertscope" then
		ss.SetSubMaterial_ShouldBeRemoved(vm, w.RTScopeNum - 1)
		return
	end

	w.RTName = w.RTName or vm:GetMaterials()[w.RTScopeNum] .. "rt"
	w.RTMaterial = w.RTMaterial or Material(w.RTName)
	w.RTMaterial:SetTexture("$basetexture", w.RTScope)
	w.RTAttachment = w.RTAttachment or vm:LookupAttachment "scope_end"
	ss.SetSubMaterial_ShouldBeRemoved(vm, w.RTScopeNum - 1, w.RTName)
	ss.RenderingRTScope = ss.sp
	local alpha = 1 - w:GetScopedProgress(true)
	local a = vm:GetAttachment(w.RTAttachment)
	render.PushRenderTarget(w.RTScope)
	render.RenderView {
		origin = w.ScopeOrigin or a.Pos, angle = a.Ang,
		x = 0, y = 0, w = 512, h = 512, aspectratio = 1,
		fov = w.Parameters.mSniperCameraFovy,
		drawviewmodel = false,
	}
	ss.ProtectedCall(w.HideRTScope, w, alpha)
	render.PopRenderTarget()
	ss.RenderingRTScope = nil
end

-- Draws V-shaped crosshair used by Rollers, Sloshers, etc
-- The weapon needs these fields:
-- table self.Crosshair ... a table of CurTime()-based times
-- number self.Parameters.mTargetEffectScale -- a scale for width
-- number self.Parameters.mTargetEffectVelRate -- a scale for depth
local EaseInOut = math.EaseInOut
local delay = 20 * ss.FrameToSec
local duration = 72 * ss.FrameToSec
local max = math.max
local mat = Material "debug/debugtranslucentvertexcolor"
local Remap = math.Remap
local vector_one = ss.vector_one
function ss.DrawVCrosshair(self, dodraw, isfirstperson)
	local aim = self:GetAimVector()
	local ang = aim:Angle()
	local alphastart = 0.8
	local alphaend = 1 - alphastart
	local colorstart = 0.25
	local colorend = 1 - colorstart
	local degstart = isfirstperson and 0 or 0.4
	local degend = 1 - degstart
	local inkcolor = self:GetInkColorProxy()
	local rot = ang:Up()
	local degbase = isfirstperson and 6 or 14
	local deg = degbase * self.Parameters.mTargetEffectScale
	local degmulstart = isfirstperson and 0.6 or 1
	local dz = 8
	local width = isfirstperson and 0.25 or 0.5
	ang:RotateAroundAxis(ang:Right(), 4)
	render.SetMaterial(mat)

	local org = self:GetShootPos() - rot * dz
	for i, v in ipairs(self.Crosshair) do
		local linearfrac = (CurTime() - v) / duration
		local alphafrac = EaseInOut(Remap(max(linearfrac, alphastart), alphastart, 1, 0, 1), 0, 1)
		local colorfrac = EaseInOut(Remap(max(linearfrac, colorstart), colorstart, 1, 0, 1), 0, 1)
		local degfrac = EaseInOut(Remap(max(linearfrac, degstart), degstart, 1, 0, 1), 0, 1)
		local movefrac = EaseInOut(linearfrac, 0, 1)
		local radius = Lerp(movefrac, 40, 100 * self.Parameters.mTargetEffectVelRate)
		local radiusside = radius * 0.85
		local color = ColorAlpha(LerpVector(colorfrac, vector_one, inkcolor):ToColor(), Lerp(alphafrac, 255, 0))
		local angleft = Angle(ang)
		local angright = Angle(ang)
		local degside = deg * Lerp(degfrac, degmulstart, 1.1)
		angleft:RotateAroundAxis(rot, degside)
		angright:RotateAroundAxis(rot, -degside)
		local start = org + ang:Forward() * radius
		local endleft = org + angleft:Forward() * radiusside
		local endright = org + angright:Forward() * radiusside
		if linearfrac > 1 then self.Crosshair[i] = nil end
		if dodraw then
			render.DrawBeam(start, endleft, width, 0, 1, color)
			render.DrawBeam(start, endright, width, 0, 1, color)
		end
	end
end

hook.Add("PostPlayerDraw", "SplatoonSWEPs: Thirdperson player fadeout", ss.hook "PostPlayerDraw")
hook.Add("PrePlayerDraw", "SplatoonSWEPs: Hide players on crouch", ss.hook "PrePlayerDraw")
hook.Add("PostRender", "SplatoonSWEPs: Render a RT scope", ss.hook "PostRender")
hook.Add("RenderScreenspaceEffects", "SplatoonSWEPs: First person ink overlay", ss.hook "RenderScreenspaceEffects")
hook.Add("OnCleanup", "SplatoonSWEPs: Cleanup all ink", function(t)
	if LocalPlayer():IsAdmin() and (t == "all" or t == ss.CleanupTypeInk) then
		net.Start "SplatoonSWEPs: Send ink cleanup"
		net.SendToServer()
	end
end)
