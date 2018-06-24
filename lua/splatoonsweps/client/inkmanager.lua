
-- Clientside ink manager

local ss = SplatoonSWEPs
if not ss then return end
local amb = render.GetAmbientLightColor() * .3
local amblen = amb:Length() * .3
if amblen > 1 then amb = amb / amblen end
local ambscale = ss.GrayScaleFactor:Dot(amb) / 2
local DecreaseFrame = 4 * ss.FrameToSec
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

function ss:ClearAllInk()
	ss.InkQueue, ss.InkTraces = {}, {}
	local amb = ss.AmbientColor
	if not amb then
		amb = render.GetAmbientLightColor():ToColor()
		ss.AmbientColor = amb
	end
	
	render.PushRenderTarget(ss.RenderTarget.BaseTexture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideColorWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(ss.RenderTarget.Normalmap)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(128, 128, 255, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(ss.RenderTarget.Lightmap)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(amb.r, amb.g, amb.b, 255)
	render.PopRenderTarget()
end

hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", coroutine.wrap(function()
	local Angles, Origins, Normals, Moved = surf.Angles, surf.Origins, surf.Normals, surf.Moved
	while not ss.RenderTarget.Ready do coroutine.yield() end
	while true do
		local done = 0
		for q in pairs(ss.InkQueue) do
			q.done, done = q.done + 1, done + 1
			if q.done > 5 then ss.InkQueue[q] = nil end
			local angle, origin, normal, moved = Angles[q.n], Origins[q.n], Normals[q.n], Moved[q.n]
			local bound = surf.Bounds[q.n] * ss.UnitsToPixels
			local color = ss:GetColor(q.c)
			local pos2d = ss:To2D(q.pos, origin, angle) * ss.UnitsToPixels
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
			if not ss:CollisionAABB2D(s, b, c - vrad, c + vrad) then q.done = math.huge continue end
			
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
				surface.SetDrawColor(GetLight(ss:To3D(rv, lightorg, angle), normal):ToColor())
				surface.DrawTexturedRect(math.floor(rx + c.x - r), math.floor(ry + c.y - r), 2 * r, 2 * r)
			end
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
		end
		
		coroutine.yield()
	end
end))

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Fix EyePos", EyePos)
hook.Add("PostDrawTranslucentRenderables", "SplatoonSWEPs: Simulate ink", function()
	if not rt.Ready then return end
	local ct = CurTime()
	for ink in pairs(ss.InkTraces) do
		local lifetime = math.max(0, ct - ink.InitTime)
		if lifetime < ink.Straight then -- Goes straight
			ink.endpos = ink.InitPos + ink.InitVelocity * lifetime
			ink.start = ink.InitPos + ink.InitVelocity * math.max(0, lifetime - ss.FrameToSec)
		elseif lifetime > ink.Straight + DecreaseFrame then -- Falls straight
			local pos = ink.InitPos + ink.InitVelocity * (ink.Straight + DecreaseFrame / 2)
			local falltime = lifetime - ink.Straight - DecreaseFrame
			ink.endpos = pos + physenv.GetGravity() * falltime * falltime / 2
			falltime = math.max(falltime - ss.FrameToSec, 0)
			ink.start = pos + physenv.GetGravity() * falltime * falltime / 2
		else
			local time = lifetime - ink.Straight
			ink.endpos = ink.InitPos + ink.InitVelocity * (ink.Straight + time / 2)
			time = time - ss.FrameToSec
			ink.start = ink.InitPos + ink.InitVelocity * (ink.Straight + time / (time > 0 and 2 or 1))
		end
		
		lifetime = lifetime - ink.TrailTime
		if lifetime > 0 then -- Second trajectory starts
			if not ink.TrailVelocity then
				ink.TrailVelocity = ink.InitVelocity
				if IsValid(ink.filter) then
					local aimvector = ss:ProtectedCall(ink.filter.GetAimVector, ink.filter) or ink.filter:GetForward()
					ink.TrailVelocity = aimvector * ink.Speed
				end
				ink.TrailVelocity = LerpVector(.125, ink.InitVelocity, ink.TrailVelocity)
			end
			
			if lifetime < ink.Straight then -- Goes straight
				ink.TrailPos = ink.InitPos + ink.TrailVelocity * lifetime
			elseif lifetime > ink.Straight + DecreaseFrame then -- Falls straight
				local pos = ink.InitPos + ink.TrailVelocity * (ink.Straight + DecreaseFrame / 2)
				local falltime = lifetime - ink.Straight - DecreaseFrame
				ink.TrailPos = pos + physenv.GetGravity() * falltime * falltime / 2
			else
				local time = lifetime - ink.Straight
				ink.TrailPos = ink.InitPos + ink.TrailVelocity * (ink.Straight + time / 2)
			end
		end
		
		local t = util.TraceHull(ink)
		local mean = (ink.start + ink.endpos) / 2
		render.SetColorMaterial()
		render.DrawSphere(mean, ss.mColRadius, 8, 8, ink.Color)
		-- render.DrawBox(ink.start, ink.InitVelocity:Angle(), ink.mins, ink.maxs, ink.Color, true)
		-- render.DrawBox(mean, ink.InitVelocity:Angle(), ink.mins, ink.maxs, ink.Color, true)
		-- render.DrawBox(ink.endpos, ink.InitVelocity:Angle(), ink.mins, ink.maxs, ink.Color, true)
		
		local a = ink.InitVelocity:Angle()
		local f, b = ink.endpos - mean, ink.start - mean
		local r, u = a:Right() * ss.mColRadius, a:Up() * ss.mColRadius
		local l, d = -r, -u
		-- f:Mul(10) -- b:Mul(10)
		l, r, u, d = l + mean, r + mean, u + mean, d + mean
		mesh.Begin(MATERIAL_TRIANGLES, 10)
		for s, t in pairs {[l] = u, [u] = r, [r] = d, [d] = l} do
			for _, v in ipairs {f + mean, s, t} do
				mesh.Color(ink.Color.r, ink.Color.g, ink.Color.b, 255)
				mesh.Position(v)
				mesh.AdvanceVertex()
			end
			for _, v in ipairs {1, t, s} do
				mesh.Color(ink.Color.r, ink.Color.g, ink.Color.b, 255)
				mesh.Position(v == 1 and ((s == r or s == d) and b + mean or ink.TrailPos) or v)
				mesh.AdvanceVertex()
			end
		end
		for _, v in ipairs {ink.TrailPos, l, ink.start, ink.TrailPos, ink.start, r} do
			mesh.Color(ink.Color.r, ink.Color.g, ink.Color.b, 255)
			mesh.Position(v)
			mesh.AdvanceVertex()
		end
		mesh.End()
		
		if not t.Hit then
			ink.start = t.HitPos
			continue
		elseif t.HitWorld then
			-- World hit effect here
		elseif IsValid(t.Entity) and t.Entity:Health() > 0 then
			-- Entity hit effect here
			local ent = ss:IsValidInkling(t.Entity)
			if not ent or ent.ColorCode ~= ink.ColorCode then
				surface.PlaySound(ink.IsCritical and ss.DealDamageCritical or ss.DealDamage)
			end
		end
		
		ss.InkTraces[ink] = nil
	end
end)
