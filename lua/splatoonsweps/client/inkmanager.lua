
--Clientside ink manager
local ss = SplatoonSWEPs
if not ss then return end

local Angle, GetConVar, ipairs, LocalPlayer, pairs, tostring, Vector
 =	Angle, GetConVar, ipairs, LocalPlayer, pairs, tostring, Vector
local End2D, FindByClass, Start2D = cam.End2D, ents.FindByClass, cam.Start2D
local create, resume, status, yield
 =	coroutine.create, coroutine.resume, coroutine.status, coroutine.yield
local ceil, Clamp, cos, floor, huge, rad, Round, sin
 =	math.ceil, math.Clamp, math.cos, math.floor, math.huge, math.rad, math.Round, math.sin
local CL, GLC, GTMSL, ODE, PopFM, PopRT, PushFM, PushRT, rSM, SLT, SSR, STMSL, URT
 =	render.ComputeLighting, render.GetLightColor,
	render.GetToneMappingScaleLinear, render.OverrideDepthEnable,
	render.PopFlashlightMode, render.PopRenderTarget,
	render.PushFlashlightMode, render.PushRenderTarget,
	render.SetMaterial, render.SetLightmapTexture,
	render.SetScissorRect, render.SetToneMappingScaleLinear,
	render.UpdateRefractTexture
local DTR, DTRR, SDC, sSM
 =	surface.DrawTexturedRect, surface.DrawTexturedRectRotated,
	surface.SetDrawColor, surface.SetMaterial
local CAABB2D, GetColor, To2D, To3D, vector_one
 =	ss.CollisionAABB2D, ss.GetColor, ss.To2D, ss.To3D, ss.vector_one
local amb = render.GetAmbientLightColor() * .3
local amblen = amb:Length() * .3
if amblen > 1 then amb = amb / amblen end
local ambscale = ss.GrayScaleFactor:Dot(amb) / 2
local imesh = ss.IMesh
local inkqueue = ss.InkQueue
local rt = ss.RenderTarget
local surf = ss.SequentialSurfaces

local MAX_PROCESS_QUEUE_AT_ONCE = 300
local inkmaterial = Material "splatoonsweps/splatoonink"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local Lightrad = {}
do
	local n = 3
	local frac = math.rad(360 / n)
	for i = 1, n do
		Lightrad[i] = Vector(math.cos(frac * i), math.sin(frac * i))
	end
end

local function DrawMeshes(bDrawingDepth, bDrawingSkybox)
	if not rt.Ready or bDrawingSkybox or
	GetConVar "mat_wireframe":GetBool() or
	GetConVar "mat_showlowresimage":GetBool() then return end
	local hdrscale = GTMSL()
	STMSL(vector_one * .05) --Set HDR scale for custom lightmap
	rSM(rt.Material) --Ink base texture
	SLT(rt.Lightmap) --Set custom lightmap
	ODE(true, true) --Write to depth buffer for translucent surface culling
	for i, m in ipairs(imesh) do m:Draw() end --Draw whole ink surface
	ODE(false) --Back to default
	STMSL(hdrscale) --Back to default
	
	URT() --Make the ink "watery"
	rSM(rt.WaterMaterial) --Set water texture for ink
	for i, m in ipairs(imesh) do m:Draw() end --Draw ink again
	
	if not LocalPlayer():FlashlightIsOn() and #FindByClass "*projectedtexture*" == 0 then return end
	PushFM(true) --Ink lit by player's flashlight or projected texture
	rSM(rt.Material) --Ink base texture
	for i, m in ipairs(imesh) do m:Draw() end --Draw once again
	PopFM() --Back to default
end

local function GetLight(p, n)
	local lightcolor = GLC(p + n)
	local light = CL(p + n, n)
	if lightcolor:LengthSqr() > 1 then lightcolor:Normalize() end
	if light:LengthSqr() > 1 then light:Normalize() end
	return (light + lightcolor + amb) / 2.3
end

local function ProcessQueue()
	while true do
		local done = 0
		for q in pairs(inkqueue) do
			-- q.done = q.done + 1
			q.done, done = q.done + 1, done + 1
			-- if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then yield() end
			if q.done > 5 then inkqueue[q] = nil end
			local c = GetColor(ss, q.c)
			local radius = Round(q.r * ss.UnitsToPixels)
			local size = radius * 2
			local bound = surf.Bounds[q.n] * ss.UnitsToPixels
			local uvorg = Vector(surf.u[q.n], surf.v[q.n]) * ss.UVToPixels
			local angle, origin, normal, moved = surf.Angles[q.n], surf.Origins[q.n], surf.Normals[q.n], surf.Moved[q.n]
			local pos2d = To2D(ss, q.pos, origin, angle) * ss.UnitsToPixels
			if moved then pos2d.x, q.inkangle = -pos2d.x, -q.inkangle - 90 end
			local lightorg = q.pos - normal * (normal:Dot(q.pos - origin) - 1) * q.dispflag
			local light = GetLight(lightorg, normal)
			local center = Vector(Round(pos2d.x + uvorg.x), Round(pos2d.y + uvorg.y))
			local s = Vector(floor(uvorg.x) - 1, floor(uvorg.y) - 1)
			local b = Vector(ceil(uvorg.x + bound.x) + 1, ceil(uvorg.y + bound.y) + 1)
			if not CAABB2D(ss, s, b, center - vector_one * radius,
			center + vector_one * radius) then q.done = huge continue end
			local settexture = "splatoonsweps/inkshot/shot" .. tostring(q.t)
			
			inkmaterial:SetTexture("$basetexture", settexture)
			normalmaterial:SetTexture("$basetexture", settexture .. "n")
			PushRT(rt.BaseTexture)
			SSR(s.x, s.y, b.x, b.y, true)
			Start2D()
			SDC(c) sSM(inkmaterial)
			DTRR(center.x, center.y, size * q.ratio, size, q.inkangle)
			End2D() SSR(0, 0, 0, 0, false) PopRT()
			
			--Draw on normal map
			PushRT(rt.Normalmap)
			SSR(s.x, s.y, b.x, b.y, true)
			Start2D()
			SDC(color_white) sSM(normalmaterial)
			DTRR(center.x, center.y, size * q.ratio, size, q.inkangle)
			End2D() SSR(0, 0, 0, 0, false) PopRT()
			
			--Draw on lightmap
			local num = floor(Clamp(40 - done, 0, 14) / 2)
			local fr = num / 7
			radius, size = radius / 2, size / 2
			PushRT(rt.Lightmap)
			SSR(s.x, s.y, b.x, b.y, true)
			Start2D()
			SDC(light:ToColor()) sSM(lightmapmaterial)
			DTR(center.x - radius * fr, center.y - radius * fr, size * fr, size * fr)
			local frac = rad(360 / num)
			for i = 1, num do
				local rx = cos(frac * i) * radius
				local ry = sin(frac * i) * radius
				if moved then rx = -rx end
				local r = Vector(rx, ry) * ss.PixelsToUnits
				SDC(GetLight(To3D(ss, r, lightorg, angle), normal):ToColor())
				DTR(floor(rx + center.x - radius), floor(ry + center.y - radius), size, size)
			end
			End2D() SSR(0, 0, 0, 0, false) PopRT()
		end
		
		yield()
	end
end

-- local function PrepareLightmap()
	-- PushRT(rt.Lightmap) Start2D() sSM(lightmapmaterial)
	-- local maxsize = 24 * ss.UnitsToPixels
	-- local done = 0
	-- local MAX = 65536
	-- for i, bound in ipairs(surf.Bounds) do
		-- local ub = bound * ss.UnitsToPixels
		-- local uvorg = Vector(surf.u[i], surf.v[i]) * ss.UVToPixels
		-- local angle, origin, normal, moved = surf.Angles[i], surf.Origins[i], surf.Normals[i], surf.Moved[i]
		-- local s = Vector(floor(uvorg.x) - 1, floor(uvorg.y) - 1)
		-- local b = Vector(ceil(uvorg.x + ub.x) + 1, ceil(uvorg.y + ub.y) + 1)
		-- local r = math.min(maxsize, ub.x / 8, ub.y / 8)
		-- local r2 = r * 2
		-- SSR(s.x, s.y, b.x, b.y, true)
		-- for x = r / 2, ub.x + r, r / 2 do
			-- for y = r / 2, ub.y + r, r / 2 do
				-- done = done + 1
				-- if done % MAX == 0 then
					-- End2D() SSR(0, 0, 0, 0, false) PopRT()
					-- print("Lightmap yield", done / MAX) yield()
					-- PushRT(rt.Lightmap) SSR(s.x, s.y, b.x, b.y, true) Start2D()
					-- sSM(lightmapmaterial)
				-- end
				-- local pos = Vector(x, y)
				-- local lightorg = To3D(ss, pos * ss.PixelsToUnits, origin, angle)
				-- SDC(GetLight(lightorg, normal):ToColor())
				-- DTR(x + s.x - r, y + s.y - r, r2, r2)
			-- end
		-- end
	-- end
	
	-- End2D() SSR(0, 0, 0, 0, false) PopRT()
	-- print "SplatoonSWEPs: Lightmap is ready!"
-- end

local Coroutines = {create(ProcessQueue)}--, create(PrepareLightmap)}
local function GMTick()
	if not rt.Ready then return end
	for _, c in ipairs(Coroutines) do
		if status(c) == "dead" then continue end
		local ok, message = resume(c)
		if not ok then ErrorNoHalt(message, "\n") end
	end
end

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", GMTick)
