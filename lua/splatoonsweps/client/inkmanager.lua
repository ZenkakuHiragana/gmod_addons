
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

function ss.ClearAllInk()
	table.Empty(ss.InkQueue)
	table.Empty(ss.PaintSchedule)
	if rt.Ready then table.Empty(ss.PaintQueue) end
	local amb = ss.AmbientColor
	if not amb then
		amb = render.GetAmbientLightColor():ToColor()
		ss.AmbientColor = amb
	end

	for _, s in ipairs(ss.SurfaceArray) do
		for i, v in pairs(s.InkSurfaces) do
			table.Empty(v)
		end
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

local function ProcessPaintQueue()
	while not rt.Ready do coroutine.yield() end
	local NumRepetition = 5
	local BlendFuncs = {
		BLEND_ONE,
		BLEND_ZERO,
		BLENDFUNC_ADD,
		BLEND_ONE,
		BLEND_ONE,
		BLENDFUNC_ADD,
	}
	local Benchmark = SysTime()
	local texturename = "splatoonsweps/inkshot/shot%s"

	local BaseTexture = rt.BaseTexture
	local Normalmap = rt.Normalmap
	local Lightmap = rt.Lightmap
	local PixelsToUnits = ss.PixelsToUnits
	local UnitsToPixels = ss.UnitsToPixels
	local UVToPixels = ss.UVToPixels

	local AddInkRectangle = ss.AddInkRectangle
	local Angle = Angle
	local ceil = math.ceil
	local cos = math.cos
	local CollisionAABB2D = ss.CollisionAABB2D
	local Dot = Vector().Dot
	local floor = math.floor
	local GetColor = ss.GetColor
	local LocalPlayer = LocalPlayer
	local max = math.max
	local next = next
	local PaintQueue = ss.PaintQueue
	local rad = math.rad
	local Recompute = inkmaterial.Recompute
	local RotateAroundAxis = Angle().RotateAroundAxis
	local Round = math.Round
	local SetFloat = inkmaterial.SetFloat
	local SetTexture = inkmaterial.SetTexture
	local sin = math.sin
	local SortedPairs = SortedPairs
	local SysTime = SysTime
	local To2D = ss.To2D
	local To3D = ss.To3D
	local ToColor = Vector().ToColor
	local unpack = unpack
	local Vector = Vector
	local yield = coroutine.yield

	local Start2D = cam.Start2D
	local End2D = cam.End2D
	local OverrideBlend = render.OverrideBlend
	local PushRenderTarget = render.PushRenderTarget
	local PopRenderTarget = render.PopRenderTarget
	local SetScissorRect = render.SetScissorRect
	local DrawTexturedRect = surface.DrawTexturedRect
	local DrawTexturedRectRotated = surface.DrawTexturedRectRotated
	local SetDrawColor = surface.SetDrawColor
	local SetMaterial = surface.SetMaterial
	local function GetLight(p, n)
		local lightcolor = render.GetLightColor(p + n)
		local light = render.ComputeLighting(p + n, n)
		if lightcolor:LengthSqr() > 1 then lightcolor:Normalize() end
		if light:LengthSqr() > 1 then light:Normalize() end
		return ToColor((light + lightcolor + amb) / 2.3)
	end

	local num = 7
	local frac = num / 7 -- Used to sample lightmap
	local radfrac = rad(360 / num)
	while true do
		Benchmark = SysTime()
		for time, queuetable in SortedPairs(PaintQueue, true) do
			for id, q in SortedPairs(queuetable) do
				local s = ss.SurfaceArray[q.index]
				local angle, origin, normal, moved = Angle(s.Angles), s.Origin, s.Normal, s.Moved
				if moved then RotateAroundAxis(angle, normal, -90) end
				local pos2d = To2D(q.pos, origin, angle) * UnitsToPixels
				local px = pos2d.x
				local py = pos2d.y
				local bx = s.Bound.x * UnitsToPixels
				local by = s.Bound.y * UnitsToPixels
				if moved then bx, by = by, bx end
				local color = GetColor(q.c)
				local r = Round(q.r * UnitsToPixels)
				local up = s.u * UVToPixels
				local vp = s.v * UVToPixels
				local lightorg = q.pos - normal * q.dispflag * (Dot(normal, q.pos - origin) - 1)
				local settexture = texturename:format(q.t)
				if moved then px, py = -px, by - py end
				local cx = Round(px + up) -- 2D center position
				local cy = Round(py + vp)
				local sx = floor(up) - 1 -- ScissorRect start
				local sy = floor(vp) - 1
				local tx = ceil(up + bx) + 1 -- ScissorRect end
				local ty = ceil(vp + by) + 1
				if q.done == 0 then
					q.draw = CollisionAABB2D(Vector(sx, sy) , Vector(tx, ty), Vector(cx - r, cy - r), Vector(cx + r, cy + r))
				end

				if q.draw then
					local alphatestreference = max(1 - q.done / NumRepetition, 0.0625)
					if 10 <= q.t and q.t <= 12 then alphatestreference = 0.0625 end
					SetTexture(inkmaterial, "$basetexture", settexture)
					SetTexture(normalmaterial, "$basetexture", settexture .. "n")
					SetFloat(inkmaterial, "$alphatestreference", alphatestreference)
					Recompute(inkmaterial)
					SetFloat(normalmaterial, "$alphatestreference", alphatestreference)
					Recompute(normalmaterial)
					PushRenderTarget(BaseTexture)
					SetScissorRect(sx, sy, tx, ty, true)
					Start2D()
					SetDrawColor(color)
					SetMaterial(inkmaterial)
					OverrideBlend(true, unpack(BlendFuncs))
					DrawTexturedRectRotated(cx, cy, 2 * r * q.ratio, 2 * r, q.inkangle)
					OverrideBlend(false)
					End2D()
					SetScissorRect(0, 0, 0, 0, false)
					PopRenderTarget()

					--Draw on normal map
					PushRenderTarget(Normalmap)
					SetScissorRect(sx, sy, tx, ty, true)
					Start2D()
					SetDrawColor(color_white)
					SetMaterial(normalmaterial)
					OverrideBlend(true, unpack(BlendFuncs))
					DrawTexturedRectRotated(cx, cy, 2 * r * q.ratio, 2 * r, q.inkangle)
					OverrideBlend(false)
					End2D()
					SetScissorRect(0, 0, 0, 0, false)
					PopRenderTarget()

					--Draw on lightmap
					r = r / 2
					PushRenderTarget(Lightmap)
					SetScissorRect(sx, sy, tx, ty, true)
					Start2D()
					SetDrawColor(GetLight(lightorg, normal))
					SetMaterial(lightmapmaterial)
					DrawTexturedRect(cx - r * frac, cy - r * frac, 2 * r * frac, 2 * r * frac)
					local sign = moved and -1 or 1
					for i = 1, num do
						local rx = cos(radfrac * i) * r * sign
						local ry = sin(radfrac * i) * r
						local rv = Vector(rx, ry) * PixelsToUnits
						SetDrawColor(GetLight(To3D(rv, lightorg, angle), normal))
						DrawTexturedRect(floor(rx + cx - r), floor(ry + cy - r), 2 * r, 2 * r)
					end
					End2D()
					SetScissorRect(0, 0, 0, 0, false)
					PopRenderTarget()

					q.done = q.done + 1
					if q.done > NumRepetition then
						queuetable[id] = nil
						if q.owner ~= LocalPlayer() then
							AddInkRectangle(q.c, q.t, q.inkangle, q.pos, q.r, q.ratio, surf)
						end
					end

					if SysTime() - Benchmark > ss.FrameToSec then
						yield()
						Benchmark = SysTime()
					end
					
					-- if ss.Debug then ss.Debug.ShowInkDrawn(Vector(sx, sy), Vector(cx, cy), Vector(tx, ty), surf, q, moved) end
				else
					queuetable[id] = nil
				end
			end

			if not next(queuetable) then PaintQueue[time] = nil end
		end

		yield()
	end
end

local process = coroutine.create(ProcessPaintQueue)
hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", function()
	if coroutine.status(process) == "dead" then return end
	local ok, msg = coroutine.resume(process)
	if not ok then ErrorNoHalt(msg) end
end)

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
