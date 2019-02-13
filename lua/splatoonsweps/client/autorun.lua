
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
if not ss.GetOption "Enabled" then
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
local PLANES, NODES, LEAFS, MODELS = 1, 5, 10, 14 -- Lump index
local function GenerateBSPTree()
	local mapfile = string.format("maps/%s.bsp", game.GetMap())
	assert(file.Exists(mapfile, "GAME"), "SplatoonSWEPs: Attempt to load a non-existent map!")
	
	local bsp = file.Open(mapfile, "rb", "GAME")
	local header = {lumps = {}}
	
	local size = 16
	for _, i in ipairs {PLANES, NODES, LEAFS, MODELS} do
		bsp:Seek(i * size + 8) -- Reading header
		header.lumps[i] = {}
		header.lumps[i].data = {}
		header.lumps[i].offset = bsp:ReadLong()
		header.lumps[i].length = bsp:ReadLong()
	end
	
	local planes = header.lumps[PLANES]
	size = 20
	bsp:Seek(planes.offset)
	planes.num = math.min(math.floor(planes.length / size) - 1, 65536 - 1)
	for i = 0, planes.num do
		local x = bsp:ReadFloat()
		local y = bsp:ReadFloat()
		local z = bsp:ReadFloat()
		planes.data[i] = {}
		planes.data[i].normal = Vector(x, y, z)
		planes.data[i].distance = bsp:ReadFloat()
		bsp:Skip(4) -- type
	end
	
	local leafs = header.lumps[LEAFS]
	local size = 32
	bsp:Seek(leafs.offset)
	leafs.num = math.floor(leafs.length / size) - 1
	for i = 0, leafs.num do
		leafs.data[i] = {}
		leafs.data[i].Surfaces = {}
	end
	
	local children = {}
	local nodes = header.lumps[NODES]
	bsp:Seek(nodes.offset)
	nodes.num = math.min(math.floor(nodes.length / size) - 1, 65536 - 1)
	for i = 0, nodes.num do
		nodes.data[i] = {}
		nodes.data[i].ChildNodes = {}
		nodes.data[i].Surfaces = {}
		nodes.data[i].Separator = planes.data[bsp:ReadLong()]
		children[i] = {}
		children[i][1] = bsp:ReadLong()
		children[i][2] = bsp:ReadLong()
		bsp:Skip(20) -- mins, maxs, firstface, numfaces, area, padding
	end
	
	for i = 0, nodes.num do
		for k = 1, 2 do
			local child = children[i][k]
			if child < 0 then
				child, leafs.data[-child - 1] = leafs.data[-child - 1]
			else
				child = nodes.data[child]
			end
			nodes.data[i].ChildNodes[k] = child
		end
	end
	
	local models = header.lumps[MODELS]
	bsp:Seek(models.offset)
	size = 4 * 12
	models.num = math.floor(models.length / size) - 1
	for i = 0, models.num do
		bsp:Skip(12 * 3)
		table.insert(ss.Models, nodes.data[bsp:ReadLong()])
		bsp:Skip(8)
	end
	
	bsp:Close()
end

function ss.PrepareInkSurface(write)
	GenerateBSPTree()
	
	local path = string.format("splatoonsweps/%s_decompress.txt", game.GetMap())
	file.Write(path, util.Decompress(write:sub(5))) -- First 4 bytes are map CRC.  Remove them.
	local data = file.Open("data/" .. path, "rb", "GAME")
	local numsurfs = data:ReadULong()
	local numdisps = data:ReadUShort()
	ss.AreaBound = data:ReadDouble()
	ss.AspectSum = data:ReadDouble()
	ss.AspectSumX = data:ReadDouble()
	ss.AspectSumY = data:ReadDouble()
	for _ = 1, numsurfs do
		local i = data:ReadULong()
		local p = data:ReadFloat()
		local y = data:ReadFloat()
		local r = data:ReadFloat()
		surf.Angles[i] = Angle(p, y, r)
		surf.Areas[i] = data:ReadFloat()
		local x = data:ReadFloat()
		local y = data:ReadFloat()
		local z = data:ReadFloat()
		surf.Bounds[i] = Vector(x, y)
		surf.DefaultAngles[i] = z
		x = data:ReadFloat()
		y = data:ReadFloat()
		z = data:ReadFloat()
		surf.Normals[i] = Vector(x, y, z)
		x = data:ReadFloat()
		y = data:ReadFloat()
		z = data:ReadFloat()
		surf.Origins[i] = Vector(x, y, z)
		surf.Vertices[i] = {}
		surf.InkCircles[i] = {}
		surf.Mins[i] = Vector(math.huge, math.huge, math.huge)
		surf.Maxs[i] = -surf.Mins[i]
		for __ = 1, data:ReadUShort() do
			x = data:ReadFloat()
			y = data:ReadFloat()
			z = data:ReadFloat()
			local v = Vector(x, y, z)
			table.insert(surf.Vertices[i], v)
			surf.Mins[i] = ss.MinVector(surf.Mins[i], v)
			surf.Maxs[i] = ss.MaxVector(surf.Maxs[i], v)
		end
		
		ss.FindLeaf(surf.Vertices[i]).Surfaces[i] = true
	end
	
	for _ = 1, numdisps do
		local i = data:ReadUShort()
		local positions = {}
		local power = 2^(data:ReadByte() + 1) + 1
		local disp = {Positions = {}, Triangles = {}}
		for k = 0, data:ReadUShort() do
			local v = {u = 0, v = 0}
			local x = data:ReadFloat()
			local y = data:ReadFloat()
			local z = data:ReadFloat()
			v.pos = Vector(x, y, z)
			x = data:ReadFloat()
			y = data:ReadFloat()
			z = data:ReadFloat()
			v.vec = Vector(x, y, z)
			v.dist = data:ReadFloat()
			disp.Positions[k] = v
			surf.Mins[i] = ss.MinVector(surf.Mins[i], v.pos)
			surf.Maxs[i] = ss.MaxVector(surf.Maxs[i], v.pos)
			table.insert(positions, v.pos)
			
			local invert = Either(k % 2 == 0, 1, 0) --Generate triangles from displacement mesh.
			if k % power < power - 1 and math.floor(k / power) < power - 1 then
				table.insert(disp.Triangles, {k + power + invert, k + 1, k})
				table.insert(disp.Triangles, {k + 1 - invert, k + power, k + power + 1})
			end
		end
		
		ss.Displacements[i] = disp
		ss.FindLeaf(positions).Surfaces[i] = true
	end
	
	data:Close()
	file.Delete(path)
	
	if ({ -- HACKHACK - These are Splatoon maps made by Lpower531. It has special decals that hides our ink.
		gm_flounder_heights_day = true,
		gm_flounder_heights_night = true,
		gm_kelp_dome = true,
		gm_kelp_dome_fes = true,
		gm_moray_towers = true,
		gm_new_albacore_hotel = true,
	})[game.GetMap()] then INK_SURFACE_DELTA_NORMAL = 2 end

	local rtsize = math.min(rt.Size[ss.GetOption "rtresolution"] or 1, render.MaxTextureWidth(), render.MaxTextureHeight())
	local rtarea = rtsize^2
	local rtmargin = 4 / rtsize -- Render Target margin
	local arearatio = 41.3329546960896 / rtsize * -- arearatio[units/pixel], Found by Excel bulldozing
	(ss.AreaBound * ss.AspectSum / numsurfs * ss.AspectSumX / ss.AspectSumY / 2500 + numsurfs)^.523795515713613
	local convertunit = rtsize * arearatio -- convertunit[units/pixel], A[pixel] * units/pixel -> A*[units]
	local sortedsurfs, movesurfs = {}, {}
	local NumMeshTriangles, nummeshes, dv, divuv, half = 0, 1, 0, 1
	local u, v, nv, bu, bv, bk = 0, 0, 0 -- cursor(u, v), shelf height, rectangle size(u, v), beginning of k
	for k in SortedPairsByValue(surf.Areas, true) do -- Placement of map polygons by Next-Fit algorithm.
		table.insert(sortedsurfs, k)
		NumMeshTriangles = NumMeshTriangles + #surf.Vertices[k] - 2
		
		bu, bv = surf.Bounds[k].x / convertunit, surf.Bounds[k].y / convertunit
		nv = math.max(nv, bv)
		if u + bu > 1 then -- Creating a new shelf
			if v + nv + rtmargin > 1 then table.insert(movesurfs, {id = bk, v = v}) end
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
		
		dv = half.v - 1
		divuv = math.max(half.v, v + nv - dv) -- Shrink RT
		arearatio = arearatio * divuv
		convertunit = convertunit * divuv
	end
	
	print("SplatoonSWEPs: Total mesh triangles = ", NumMeshTriangles)
	
	for i = 1, math.ceil(NumMeshTriangles / MAX_TRIANGLES) do
		table.insert(ss.IMesh, Mesh(ss.RenderTarget.Material))
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
				for _, v in pairs(verts) do
					v.u, v.v = v.u / divuv, v.v / divuv
				end
				
				for _, v in ipairs(surf.Vertices[k]) do
					v.u, v.v = v.u / divuv, v.v / divuv
				end
				
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
			surf.Areas[k], surf.Vertices[k] = nil
		end
		mesh.End()
	end
	
	ss.ClearAllInk()
	ss.InitializeMoveEmulation(LocalPlayer())
	ss.PixelsToUnits = arearatio
	ss.UVToUnits = convertunit
	ss.UVToPixels = rtsize
	ss.UnitsToPixels = 1 / ss.PixelsToUnits
	ss.UnitsToUV = 1 / ss.UVToUnits
	ss.PixelsToUV = 1 / ss.UVToPixels
	surf.Areas, surf.Vertices, surf.AreaBound = nil
	ss.RenderTarget.Ready = true
	collectgarbage "collect"
	net.Start "SplatoonSWEPs: Ready to splat"
	net.WriteString(LocalPlayer():SteamID64())
	net.SendToServer()
	ss.WeaponRecord[LocalPlayer()] = {
		Duration = {},
		Inked = {},
		Recent = {},
	}
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
	local path = string.format("splatoonsweps/%s.txt", game.GetMap())
	local pathbsp = string.format("maps/%s.bsp", game.GetMap())
	local data = file.Open(path, "rb", "DATA") or file.Open("data/" .. path, "rb", "GAME")
	if not data or data:Size() < 4 or data:ReadULong() ~= tonumber(util.CRC(file.Read(pathbsp, true) or "")) then
		if data then data:Close() end
		net.Start "SplatoonSWEPs: Redownload ink data"
		net.SendToServer()
		ss.Data = ""
		return
	end
	
	data:Close()
	ss.PrepareInkSurface(file.Read("data/" .. path, true))
end)

function ss.PostPlayerDraw(w, ply) render.SetBlend(1) end
function ss.PrePlayerDraw(w, ply)
	local ShouldNoDraw = Either(w:GetNWBool "becomesquid" and IsValid(w.Squid), ply:Crouching(), w:GetInInk())
	if ShouldNoDraw then return true end
	if w:IsCarriedByLocalPlayer() then
		render.SetBlend(w:GetCameraFade())
	end
	
	return ss.ProtectedCall(w.ManipulatePlayer, w, ply)
end

function ss.RenderScreenspaceEffects(w)
	ss.ProtectedCall(w.RenderScreenspaceEffects, w)
	if not w:GetInInk() or LocalPlayer():ShouldDrawLocalPlayer() or not ss.GetOption "drawinkoverlay" then return end
	local color = w:GetInkColorProxy()
	DrawMaterialOverlay("effects/water_warp01", .1)
	surface.SetDrawColor(ColorAlpha(color:ToColor(),
	48 * (1.1 - math.sqrt(ss.GrayScaleFactor:Dot(color))) / ss.GrayScaleFactor:Dot(render.GetToneMappingScaleLinear())))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end

hook.Add("PostPlayerDraw", "SplatoonSWEPs: Thirdperson player fadeout", ss.hook "PostPlayerDraw")
hook.Add("PrePlayerDraw", "SplatoonSWEPs: Hide players on crouch", ss.hook "PrePlayerDraw")
hook.Add("RenderScreenspaceEffects", "SplatoonSWEPs: First person ink overlay", ss.hook "RenderScreenspaceEffects")
hook.Add("OnCleanup", "SplatoonSWEPs: Cleanup all ink", function(t)
	if LocalPlayer():IsAdmin() and (t == "all" or t == ss.CleanupTypeInk) then
		net.Start "SplatoonSWEPs: Send ink cleanup"
		net.SendToServer()
	end
end)
