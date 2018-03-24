
--Clientside ink manager
local ss = SplatoonSWEPs
if not ss then return end

local rt = ss.RenderTarget
local MAX_PROCESS_QUEUE_AT_ONCE = 100
local inkmaterial = Material "splatoonsweps/splatoonink"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local LightmapSampleTable = {[7] = 1.2}
local NumPoly, Polysin, Polycos, Lightrad = 16, {}, {}, {}
for i = 0, NumPoly do
	local a = math.rad(i * -360 / NumPoly)
	Polysin[i], Polycos[i] = math.sin(a), math.cos(a)
end

for n in pairs(LightmapSampleTable) do
	Lightrad[n] = {}
	local frac = math.rad(360 / n)
	for i = 1, n do
		Lightrad[n][i] = Vector(math.cos(frac * i), math.sin(frac * i))
	end
end

local amb = render.GetAmbientLightColor() * .3
local amblen = amb:Length() * .3
if amblen > 1 then amb = amb / amblen end
local ambscale = ss.GrayScaleFactor:Dot(amb) / 2
local function DrawMeshes(bDrawingDepth, bDrawingSkybox)
	if (GetConVar "r_3dsky":GetBool() and ss.Has3DSkyBox or false) == bDrawingSkybox
	or bDrawingDepth or not rt.Ready or GetConVar "mat_wireframe":GetBool() then return end
	local hdrscale = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(ss.vector_one * .05) --Set HDR scale for custom lightmap
	render.SetMaterial(rt.Material) --Ink base texture
	render.SetLightmapTexture(rt.Lightmap) --Set custom lightmap
	render.OverrideDepthEnable(true, true) --Write to depth buffer for translucent surface culling
	for i, m in ipairs(ss.IMesh) do m:Draw() end --Draw whole ink surface
	render.OverrideDepthEnable(false) --Back to default
	render.SetToneMappingScaleLinear(hdrscale) --Back to default
	render.UpdateRefractTexture() --Make the ink "watery"
	render.SetMaterial(rt.WaterMaterial) --Set water texture for ink
	for i, m in ipairs(ss.IMesh) do m:Draw() end --Draw ink again
	if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then return end
	render.PushFlashlightMode(true) --Ink lit by player's flashlight or projected texture
	render.SetMaterial(rt.Material) --Ink base texture
	for i, m in ipairs(ss.IMesh) do m:Draw() end --Draw once again
	render.PopFlashlightMode() --Back to default
end

local function GetLight(p, n)
	local lightcolor = render.GetLightColor(p + n)
	local light = render.ComputeLighting(p + n, n)
	if lightcolor:LengthSqr() > 1 then lightcolor:Normalize() end
	if light:LengthSqr() > 1 then light:Normalize() end
	return (light + lightcolor + amb) / 2.3
end

local function ProcessQueue()
	while true do
		local done = 0
		for q in pairs(ss.InkQueue) do
			local c = ss:GetColor(q.c)
			local radius = math.Round(ss:UnitsToPixels(q.r))
			local size, vrad = radius * 2, ss.vector_one * radius
			local surf = ss.SequentialSurfaces
			local bound = ss:UnitsToPixels(surf.Bounds[q.n])
			local uvorg = ss:UVToPixels(Vector(surf.u[q.n], surf.v[q.n]))
			local angle, origin, normal, moved = Angle(surf.Angles[q.n]), surf.Origins[q.n], surf.Normals[q.n], surf.Moved[q.n]
			local pos2d = ss:UnitsToPixels(ss:To2D(q.pos, origin, angle))
			if moved then pos2d.x, q.inkangle = -pos2d.x, -(q.inkangle + 90) end
			local lightorg = q.pos - normal * (normal:Dot(q.pos - origin) - 1) * q.dispflag
			local light = GetLight(lightorg, normal)
			local center = Vector(math.Round(pos2d.x + uvorg.x), math.Round(pos2d.y + uvorg.y))
			local s = Vector(math.floor(uvorg.x) - 1, math.floor(uvorg.y) - 1)
			local b = Vector(math.ceil(uvorg.x + bound.x) + 1, math.ceil(uvorg.y + bound.y) + 1)
			if not ss:CollisionAABB2D(s, b, center - vrad, center + vrad) then q.done = math.huge continue end
			local settexture = "splatoonsweps/inkshot/shot" .. tostring(q.t)
			
			inkmaterial:SetTexture("$basetexture", settexture)
			normalmaterial:SetTexture("$basetexture", settexture .. "n")
			render.PushRenderTarget(rt.BaseTexture)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(c)
			surface.SetMaterial(inkmaterial)
			surface.DrawTexturedRectRotated(center.x, center.y, size * q.ratio, size, q.inkangle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on normal map
			render.PushRenderTarget(rt.Normalmap)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(color_white)
			surface.SetMaterial(normalmaterial)
			surface.DrawTexturedRectRotated(center.x, center.y, size * q.ratio, size, q.inkangle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on lightmap
			radius, size = radius / 2, size / 2
			-- center, uvorg, s, b = center / 2, uvorg / 2, s / 2, b / 2
			-- s.x, s.y, b.x, b.y = math.floor(s.x), math.floor(s.y), math.ceil(b.x), math.ceil(b.y)
			render.PushRenderTarget(rt.Lightmap)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(light:ToColor())
			surface.SetMaterial(lightmapmaterial)
			surface.DrawTexturedRect(center.x - radius, center.y - radius, size, size)
			for n, mul in pairs(LightmapSampleTable) do
				for i = 1, n do
					local r = Lightrad[n][i] * radius * mul
					surface.SetDrawColor(GetLight(ss:To3D(ss:PixelsToUnits(
					surf.Moved[q.n] and Vector(-r.x, r.y) or r), lightorg, angle), normal):ToColor())
					r = r + center - ss.vector_one * radius
					surface.DrawTexturedRect(r.x, r.y, size, size)
				end
			end
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideAlphaWriteEnable(false)
			render.PopRenderTarget()
			
			q.done, done = q.done + 1, done + 1
			if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then coroutine.yield() end
			if q.done > 5 then ss.InkQueue[q] = nil end
		end
		
		coroutine.yield()
	end
end

local DoCoroutine = coroutine.create(ProcessQueue)
local function GMTick()
	if not rt.Ready or coroutine.status(DoCoroutine) == "dead" then return end
	local ok, message = coroutine.resume(DoCoroutine)
	if not ok then ErrorNoHalt(message) end
end

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", GMTick)
hook.Add("PostDrawSkyBox", "SplatoonSWEPs: Test if map has 3D skyBox", function()
	ss.Has3DSkyBox = true
	hook.Remove("PostDrawSkyBox", "SplatoonSWEPs: Test if map has 3D skyBox")
end)
