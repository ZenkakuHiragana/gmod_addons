
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
	if ss.GetOption "hideink" then return end
	if not rt.Ready or bDrawingSkybox or CVarWireframe:GetBool() or CVarMinecraft:GetBool() then return end
	local hdrscale = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(inkhdrscale) -- Set HDR scale for custom lightmap
	render.SetMaterial(rt.Material) -- Ink base texture
	render.SetLightmapTexture(rt.Lightmap) -- Set custom lightmap
	render.OverrideDepthEnable(true, true) -- Write to depth buffer for translucent surface culling
	for i, m in ipairs(ss.IMesh) do m:Draw() end -- Draw ink surface
	render.OverrideDepthEnable(false) -- Back to default
	render.SetToneMappingScaleLinear(hdrscale) -- Back to default

	if not ss.GetConVar "norefract":GetBool() then
		render.UpdateRefractTexture() -- Make the ink watery
		render.SetMaterial(rt.WaterMaterial) -- Set water texture for ink
		for i, m in ipairs(ss.IMesh) do m:Draw() end -- Draw ink again
	end

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
	table.Empty(ss.InkQueue)
	table.Empty(ss.PaintSchedule)
	if rt.Ready then table.Empty(ss.PaintQueue) end
	local amb = ss.AmbientColor
	if not amb then
		amb = render.GetAmbientLightColor():ToColor()
		ss.AmbientColor = amb
	end

	for i, v in pairs(surf.InkCircles) do
		table.Empty(v)
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

local texturename = "splatoonsweps/inkshot/shot%s"
local function ProcessPaintQueue()
	local Angles = surf.Angles
	local Bounds = surf.Bounds
	local Moved = surf.Moved
	local Normals = surf.Normals
	local Origins = surf.Origins
	local u = surf.u
	local v = surf.v
	local Benchmark = SysTime()
	while not rt.Ready do coroutine.yield() end
	while true do
		Benchmark = SysTime()
		for time, queuetable in SortedPairs(ss.PaintQueue) do
			for id, q in SortedPairs(queuetable) do
				local angle, origin, normal, moved = Angle(Angles[q.n]), Origins[q.n], Normals[q.n], Moved[q.n]
				if moved then angle:RotateAroundAxis(normal, -90) end
				local pos2d = ss.To2D(q.pos, origin, angle) * ss.UnitsToPixels
				local bound = Bounds[q.n] * ss.UnitsToPixels
				if moved then bound.x, bound.y = bound.y, bound.x end
				local color = ss.GetColor(q.c)
				local r = math.Round(q.r * ss.UnitsToPixels)
				local uvorg = Vector(u[q.n], v[q.n]) * ss.UVToPixels
				local lightorg = q.pos - normal * (normal:Dot(q.pos - origin) - 1) * q.dispflag
				local light = GetLight(lightorg, normal)
				local settexture = texturename:format(q.t)
				local vrad = ss.vector_one * r
				if moved then pos2d.x, pos2d.y = -pos2d.x, bound.y - pos2d.y end
				local b = Vector(math.ceil(uvorg.x + bound.x) + 1, math.ceil(uvorg.y + bound.y) + 1) -- ScissorRect end
				local c = Vector(math.Round(pos2d.x + uvorg.x), math.Round(pos2d.y + uvorg.y)) -- 2D center position
				local s = Vector(math.floor(uvorg.x) - 1, math.floor(uvorg.y) - 1) -- ScissorRect start
				if ss.CollisionAABB2D(s, b, c - vrad, c + vrad) then
					if ss.Debug then ss.Debug.ShowInkDrawn(s, c, b, surf, q, moved) end
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
					local num = 7
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

					q.done = q.done + 1
					if q.done > 5 then
						queuetable[id] = nil
						if q.owner ~= LocalPlayer() then
							ss.AddInkRectangle(q.c, q.n, q.t, q.inkangle, q.pos, q.r, q.ratio, surf)
						end
					end

					if SysTime() - Benchmark > ss.FrameToSec then
						coroutine.yield()
						Benchmark = SysTime()
					end
				else
					queuetable[id] = nil
				end
			end

			if not next(queuetable) then ss.PaintQueue[time] = nil end
		end

		coroutine.yield()
	end
end

local process = coroutine.create(ProcessPaintQueue)
hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", function()
	if coroutine.status(process) == "dead" then return end
	local ok, msg = coroutine.resume(process)
	if not ok then ErrorNoHalt(msg) end
end)

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
