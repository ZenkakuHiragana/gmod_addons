
-- Clientside ink manager

local ss = SplatoonSWEPs
if not ss then return end
local amb = render.GetAmbientLightColor() * .3
local amblen = amb:Length() * .3
if amblen > 1 then amb = amb / amblen end
local ambscale = ss.GrayScaleFactor:Dot(amb) / 2
local CVarWireframe = GetConVar "mat_wireframe"
local CVarMinecraft = GetConVar "mat_showlowresimage"
local inkhdrscale = ss.vector_one * .05
local inkmaterial = Material "splatoonsweps/splatoonink"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
local rt = ss.RenderTarget
local surf = ss.SequentialSurfaces
local world = game.GetWorld()
local function DrawMeshes(bDrawingDepth, bDrawingSkybox)
	if not rt.Ready or bDrawingSkybox or CVarWireframe:GetBool() or CVarMinecraft:GetBool() then return end
	local hdrscale = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(inkhdrscale) -- Set HDR scale for custom lightmap
	render.SetMaterial(rt.Material) -- Ink base texture
	render.SetLightmapTexture(rt.Lightmap) -- Set custom lightmap
	render.OverrideDepthEnable(true, true) -- Write to depth buffer for translucent surface culling
	for i, m in ipairs(ss.IMesh) do m:Draw() end -- Draw ink surface
	render.OverrideDepthEnable(false) -- Back to default
	render.SetToneMappingScaleLinear(hdrscale) -- Back to default
	
	render.UpdateRefractTexture() -- Make the ink watery
	render.SetMaterial(rt.WaterMaterial) -- Set water texture for ink
	for i, m in ipairs(ss.IMesh) do m:Draw() end -- Draw ink again
	
	if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then return end
	render.PushFlashlightMode(true) -- Ink lit by player's flashlight or projected texture
	render.SetMaterial(rt.Material) -- Ink base texture
	for i, m in ipairs(ss.IMesh) do m:Draw() end -- Draw once again
	render.PopFlashlightMode() -- Back to default
end

local function GetLight(p, n)
	local lightcolor = render.GetLightColor(p + n)
	local light = render.ComputeLighting(p + n, n)
	if lightcolor:LengthSqr() > 1 then lightcolor:Normalize() end
	if light:LengthSqr() > 1 then light:Normalize() end
	return (light + lightcolor + amb) / 2.3
end

function ss.ClearAllInk()
	ss.InkCounter, ss.InkQueue, ss.InkTraces = 0, {}, {}
	local amb = ss.AmbientColor
	if not amb then
		amb = render.GetAmbientLightColor():ToColor()
		ss.AmbientColor = amb
	end
	
	for i = 1, #surf.InkCircles do
		surf.InkCircles[i] = {}
	end
	
	render.PushRenderTarget(rt.BaseTexture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideColorWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(rt.Normalmap)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(128, 128, 255, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(rt.Lightmap)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(amb.r, amb.g, amb.b, 255)
	render.PopRenderTarget()
end

-- Takes a TraceResult and returns ink color of its HitPos.
-- Argument:
--   TraceResult tr	| A TraceResult structure to pick up a position.
-- Returning:
--   number			| The ink color of the specified position.
--   nil			| If there is no ink, returns nil.
local MAX_DEGREES_DIFFERENCE = 45 -- Maximum angle difference between two surfaces
local MAX_COS_DEG_DIFF = math.cos(math.rad(MAX_DEGREES_DIFFERENCE)) -- Used by filtering process
local POINT_BOUND = ss.vector_one * .1
local rootpi = math.sqrt(math.pi) / 2
function ss.GetSurfaceColor(tr)
	if not tr.Hit then return end
	for node in ss.BSPPairs {tr.HitPos} do
		for i in pairs(node.Surfaces) do
			if surf.Normals[i]:Dot(tr.HitNormal) <= MAX_COS_DEG_DIFF * (ss.Displacements[i] and .5 or 1) or not
			ss.CollisionAABB(tr.HitPos - POINT_BOUND, tr.HitPos + POINT_BOUND, surf.Mins[i], surf.Maxs[i]) then continue end
			local p2d = ss.To2D(tr.HitPos, surf.Origins[i], surf.Angles[i])
			for r in SortedPairsByValue(surf.InkCircles[i], true) do
				local t = ss.InkShotMaterials[r.texid]
				local w, h = t.width, t.height
				local p = (p2d - r.pos) / r.radius
				p:Rotate(Angle(0, r.angle)) -- (-1, -1) <= (x, y) <= (1, 1)
				if -1 > p.x or p.x > 1 or -1 > p.y or p.y > 1 then continue end
				p = (p + ss.vector_one) / 2 -- (0, 0) <= (x, y) <= (1, 1)
				p.y = p.y * h -- 0 <= y <= h
				p.x = p.x - (1 - r.ratio) / 2 -- 0 <= x <= r.ratio
				p.x = p.x / r.ratio * w -- 0 <= x <= w
				p.x, p.y = math.Round(p.x), math.Round(p.y)
				if 0 < p.x and p.x < w and 0 < p.y and p.y < h and t[(p.y - 1) * w + p.x] then
					return r.color
				end
			end
		end
	end
end

local tick = coroutine.create(function()
	local Angles, Origins, Normals, Moved = surf.Angles, surf.Origins, surf.Normals, surf.Moved
	while not rt.Ready do coroutine.yield() end
	while true do
		local done = 0
		for q in pairs(ss.InkQueue) do
			q.done, done = q.done + 1, done + 1
			local angle, origin, normal, moved = Angles[q.n], Origins[q.n], Normals[q.n], Moved[q.n]
			local pos2d = ss.To2D(q.pos, origin, angle)
			if q.done > 5 then
				local rectsize = q.r * rootpi
				local sizevec = Vector(rectsize, rectsize)
				local bmins, bmaxs = pos2d - sizevec, pos2d + sizevec
				ss.AddInkRectangle(surf.InkCircles[q.n], ss.InkCounter, {
					angle = q.inkangle,
					bounds = {bmins.x, bmins.y, bmaxs.x, bmaxs.y},
					color = q.c,
					pos = pos2d,
					radius = q.r,
					ratio = q.ratio,
					texid = q.t,
				})
				ss.InkCounter = ss.InkCounter + 1
				ss.InkQueue[q] = nil
			end
			
			pos2d = pos2d * ss.UnitsToPixels
			local bound = surf.Bounds[q.n] * ss.UnitsToPixels
			local color = ss.GetColor(q.c)
			local r = math.Round(q.r * ss.UnitsToPixels)
			local uvorg = Vector(surf.u[q.n], surf.v[q.n]) * ss.UVToPixels
			if moved then pos2d.x, q.inkangle = -pos2d.x, -q.inkangle - 90 end
			local lightorg = q.pos - normal * (normal:Dot(q.pos - origin) - 1) * q.dispflag
			local light = GetLight(lightorg, normal)
			local b = Vector(math.ceil(uvorg.x + bound.x) + 1, math.ceil(uvorg.y + bound.y) + 1) -- ScissorRect end
			local c = Vector(math.Round(pos2d.x + uvorg.x), math.Round(pos2d.y + uvorg.y)) -- 2D center position
			local s = Vector(math.floor(uvorg.x) - 1, math.floor(uvorg.y) - 1) -- ScissorRect start
			local settexture = "splatoonsweps/inkshot/shot" .. tostring(q.t)
			local vrad = ss.vector_one * r
			if not ss.CollisionAABB2D(s, b, c - vrad, c + vrad) then q.done = math.huge continue end
			
			inkmaterial:SetTexture("$basetexture", settexture)
			normalmaterial:SetTexture("$basetexture", settexture .. "n")
			render.PushRenderTarget(rt.BaseTexture)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(color)
			surface.SetMaterial(inkmaterial)
			surface.DrawTexturedRectRotated(c.x, c.y, 2 * r * q.ratio, 2 * r, q.inkangle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on normal map
			render.PushRenderTarget(rt.Normalmap)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(color_white)
			surface.SetMaterial(normalmaterial)
			surface.DrawTexturedRectRotated(c.x, c.y, 2 * r * q.ratio, 2 * r, q.inkangle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on lightmap
			r = r / 2
			local num = math.floor(math.Clamp(40 - done, 0, 14) / 2)
			local frac = num / 7
			render.PushRenderTarget(rt.Lightmap)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(light:ToColor())
			surface.SetMaterial(lightmapmaterial)
			surface.DrawTexturedRect(c.x - r * frac, c.y - r * frac, 2 * r * frac, 2 * r * frac)
			frac = math.rad(360 / num)
			for i = 1, num do
				local rx = math.cos(frac * i) * r * (moved and -1 or 1)
				local ry = math.sin(frac * i) * r
				local rv = Vector(rx, ry) * ss.PixelsToUnits
				surface.SetDrawColor(GetLight(ss.To3D(rv, lightorg, angle), normal):ToColor())
				surface.DrawTexturedRect(math.floor(rx + c.x - r), math.floor(ry + c.y - r), 2 * r, 2 * r)
			end
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
		end
		
		coroutine.yield()
	end
end)

hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", function()
	if coroutine.status(tick) == "dead" then return end
	local ok, msg = coroutine.resume(tick)
	if not ok then ErrorNoHalt(msg) end
end)

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Fix EyePos", EyePos)
