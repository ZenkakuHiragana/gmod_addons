
-- Clientside SplatoonSWEPs structure

SplatoonSWEPs = SplatoonSWEPs or {
	AmbientColor = color_white,	--
	AreaBound = 0,				--
	AspectSum = 0,				--
	AspectSumX = 0,				--
	AspectSumY = 0,				--
	CrosshairColors = {},		--
	Displacements = {},			--
	IMesh = {},					--
	InkColors = {},				--
	InkShotMaterials = {},		--
	InkQueue = {},				--
	Models = {},				--
	PaintQueue = {},			--
	PaintSchedule = {},			--
	PlayerHullChanged = {},		--
	RenderTarget = {},			--
	SequentialSurfaces = {		--
		Angles = {},			--
		Areas = {},				--
		Bounds = {},			--
		DefaultAngles = {},		--
		InkCircles = {},		--
		Maxs = {},				--
		Mins = {},				--
		Moved = {},				--
		Normals = {},			--
		Origins = {},			--
		u = {}, v = {},			--
		Vertices = {},			--
	},
	WeaponRecord = {},			--
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

local surf = ss.SequentialSurfaces
local rt = ss.RenderTarget
local crashpath = "splatoonsweps/crashdump.txt" -- Existing this means the client crashed before.
local MAX_TRIANGLES = math.floor(32768 / 3) -- mesh library limitation
local INK_SURFACE_DELTA_NORMAL = .8 -- Distance between map surface and ink mesh
function ss.PrepareInkSurface(write)
	ss.GenerateBSPTree(write)
	if ss.SplatoonMapPorts[game.GetMap()] then INK_SURFACE_DELTA_NORMAL = 2 end
	local numsurfs = #surf.Origins
	local rtsize = rt.BaseTexture:Width()
	local rtarea = rtsize^2
	local rtmargin = 4 / rtsize -- Render Target margin
	local arearatio = 41.3329546960896 / rtsize * -- arearatio[units/pixel], Found by Excel bulldozing
	(ss.AreaBound * ss.AspectSum / numsurfs * ss.AspectSumX / ss.AspectSumY / 2500 + numsurfs)^.523795515713613
	local convertunit = rtsize * arearatio -- convertunit[units/pixel], A[pixel] * units/pixel -> A*[units]
	local sortedsurfs, movesurfs = {}, {}
	local NumMeshTriangles, nummeshes, dv, divuv, half = 0, 1, 0, 1
	local u, v, nv, bu, bv, bk = 0, 0, 0 -- cursor(u, v), shelf height, rectangle size(u, v), beginning of k
	for k in SortedPairsByValue(surf.Areas, true) do -- Placement of map polygons by Next-Fit algorithm.
		sortedsurfs[#sortedsurfs + 1] = k
		NumMeshTriangles = NumMeshTriangles + #surf.Vertices[k] - 2

		bu, bv = surf.Bounds[k].x / convertunit, surf.Bounds[k].y / convertunit
		nv = math.max(nv, bv)
		if u + bu > 1 then -- Creating a new shelf
			if v + nv + rtmargin > 1 then
				movesurfs[#movesurfs + 1] = {id = bk, v = v}
			end

			u, v, nv = 0, v + nv + rtmargin, bv
		end

		if u == 0 then bk = #sortedsurfs end -- Storing the first element of current shelf
		for i, vt in ipairs(surf.Vertices[k]) do -- Get UV coordinates
			local meshvert = vt + surf.Normals[k] * INK_SURFACE_DELTA_NORMAL
			local UV = ss.To2D(vt, surf.Origins[k], surf.Angles[k]) / convertunit
			surf.Vertices[k][i] = {pos = meshvert, u = UV.x + u, v = UV.y + v}
		end

		if ss.Displacements[k] then
			NumMeshTriangles = NumMeshTriangles + #ss.Displacements[k].Triangles - 2
			for i = 0, #ss.Displacements[k].Positions do
				local vt = ss.Displacements[k].Positions[i]
				local meshvert = vt.pos - surf.Normals[k] * surf.Normals[k]:Dot(vt.vec * vt.dist)
				local UV = ss.To2D(meshvert, surf.Origins[k], surf.Angles[k]) / convertunit
				vt.u, vt.v = UV.x + u, UV.y + v
			end
		end

		surf.u[k], surf.v[k] = u, v
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
			if half and sortedID >= half.id then -- If current polygon is moved
				local bu = surf.Bounds[k].x / convertunit * divuv
				surf.Angles[k]:RotateAroundAxis(surf.Normals[k], -90)
				surf.Bounds[k].x, surf.Bounds[k].y = surf.Bounds[k].y, surf.Bounds[k].x
				surf.u[k], surf.v[k] = surf.v[k] - dv, 1 - surf.u[k] - bu
				surf.Moved[k] = true
				for _, vertex in ipairs(surf.Vertices[k]) do
					vertex.u, vertex.v = vertex.v - dv, 1 - vertex.u
				end

				if ss.Displacements[k] then
					for i = 0, #ss.Displacements[k].Positions do
						local vertex = ss.Displacements[k].Positions[i]
						vertex.u, vertex.v = vertex.v - dv, 1 - vertex.u
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

				ss.Displacements[k] = true
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

			if not ss.Debug then
				surf.Areas[k], surf.Vertices[k] = nil
			end
		end
		mesh.End()
	end

	if not ss.Debug then
		surf.Areas, surf.Vertices, surf.AreaBound = nil
	end

	ss.ClearAllInk()
	ss.InitializeMoveEmulation(LocalPlayer())
	net.Start "SplatoonSWEPs: Ready to splat"
	net.WriteString(LocalPlayer():SteamID64())
	net.SendToServer()
	ss.WeaponRecord[LocalPlayer()] = util.JSONToTable(
	util.Decompress(file.Read "splatoonsweps/record/stats.txt"
	or "") or "") or {
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
	rt.Material = CreateMaterial(
		rt.Name.RenderTarget,
		"LightmappedGeneric",
		{
			["$basetexture"] = rt.Name.BaseTexture,
			["$bumpmap"] = rt.Name.Normalmap,
			["$ssbump"] = "1",
			["$nolod"] = "1",
			["$alpha"] = ".975",
			["$translucent"] = "1",
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

	file.Delete(crashpath)

	-- Checking ink map in data/
	local pathbsp = string.format("maps/%s.bsp", game.GetMap())
	local path = string.format("splatoonsweps/%s.txt", game.GetMap())
	local InkCRCServer = GetGlobalString "SplatoonSWEPs: Ink map CRC"
	local data = file.Open(path, "rb", "DATA") or file.Open("data/" .. path, "rb", "GAME")
	local MapCRC = tonumber(util.CRC(file.Read(pathbsp, true) or ""))
	local InkCRC = util.CRC(file.Read("data/" .. path, true) or "")
	local IsValid = data and data:Size() > 4 and data:ReadULong() == MapCRC and (ss.sp or InkCRCServer == InkCRC)
	local UseDownloaded = false
	if data then data:Close() end
	if ss.mp and not IsValid then
		file.Rename(path, path .. ".txt")
		data = file.Open("data/" .. path, "rb", "GAME")
		InkCRC = util.CRC(file.Read("data/" .. path, true) or "")
		IsValid = data and data:Size() > 4 and data:ReadULong() == MapCRC and InkCRCServer == InkCRC
		UseDownloaded = true
		if data then data:Close() end
	end

	if not IsValid then
		if ss.mp then file.Rename(path .. ".txt", path) end
		net.Start "SplatoonSWEPs: Redownload ink data"
		net.SendToServer()
		notification.AddProgress("SplatoonSWEPs: Redownload ink data", "Downloading ink map...")
		return
	end

	if ss.mp and not UseDownloaded then file.Rename(path .. ".txt", path) end
	ss.PrepareInkSurface(file.Read("data/" .. path, true))
	if ss.mp and UseDownloaded then file.Rename(path .. ".txt", path) end
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
		vm:SetSubMaterial(w.RTScopeNum - 1)
		return
	end

	w.RTName = w.RTName or vm:GetMaterials()[w.RTScopeNum] .. "rt"
	w.RTMaterial = w.RTMaterial or Material(w.RTName)
	w.RTMaterial:SetTexture("$basetexture", w.RTScope)
	w.RTAttachment = w.RTAttachment or vm:LookupAttachment "scope_end"
	vm:SetSubMaterial(w.RTScopeNum - 1, w.RTName)
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
