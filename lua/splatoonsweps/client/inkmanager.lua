
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

local TrailLagTime = 10 * ss.FrameToSec
local TrailMergeTime = 20 * ss.FrameToSec
hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Fix EyePos", EyePos)
hook.Add("PostDrawTranslucentRenderables", "SplatoonSWEPs: Simulate ink", function()
	if not rt.Ready then return end
	local ct, rtime = CurTime(), RealTime()
	for ink in pairs(ss.InkTraces) do
		local lifetime = math.max(0, ct - ink.InitTime)
		local trailtime = lifetime - ink.TrailDelay
		local App = ink.Appearance -- Effect position fix
		local w = ss:IsValidInkling(ink.filter)
		if w and lifetime < ink.Straight + DecreaseFrame then
			local wt = ((ink.filter ~= LocalPlayer() or ink.filter:ShouldDrawLocalPlayer())
			and w.WElements or w.VElements).weapon
			local ent = wt.modelEnt
			if IsValid(ent) then
				local time = ink.Straight + DecreaseFrame / 2
				local straightpos = ink.InitPos + ink.Velocity * time
				local mp = w.Primary.MuzzlePosition
				local pos, ang = ent:GetPos(), ent:GetAngles()
				mp = Vector(mp.x * wt.size.x, mp.y * wt.size.y, mp.z * wt.size.z)
				App.InitPos = LocalToWorld(mp, angle_zero, pos, ang)
				App.Velocity = (straightpos - App.InitPos) / time
				App.Speed = App.Velocity:Length()
				if trailtime < 0 then App.TrailPos = App.InitPos end
			end
		end
		
		if lifetime < ink.Straight then -- Goes straight
			ink.endpos = ink.InitPos + ink.Velocity * lifetime
			ink.start = ink.InitPos + ink.Velocity * math.max(0, lifetime - ss.FrameToSec)
			App.Pos = App.InitPos + App.Velocity * lifetime
		elseif lifetime > ink.Straight + DecreaseFrame then -- Falls straight
			local time = ink.Straight + DecreaseFrame / 2
			local falltime = lifetime - ink.Straight - DecreaseFrame
			local pos = ink.InitPos + ink.Velocity * time
			local tpspos = App.InitPos + App.Velocity * time
			ink.endpos = pos + physenv.GetGravity() * falltime * falltime / 2
			App.Pos = tpspos + physenv.GetGravity() * falltime * falltime / 2
			falltime = math.max(falltime - ss.FrameToSec, 0)
			ink.start = pos + physenv.GetGravity() * falltime * falltime / 2
		else
			local t = lifetime - ink.Straight -- 0 <= t <= DecreaseFrame
			local time = ink.Straight + t / 2
			ink.endpos = ink.InitPos + ink.Velocity * time
			App.Pos = App.InitPos + App.Velocity * time
			t = t - ss.FrameToSec
			ink.start = ink.InitPos + ink.Velocity * (ink.Straight + t / (t > 0 and 2 or 1))
		end
		
		if trailtime > 0 then -- Second trajectory starts
			if not App.TrailVelocity then
				App.TrailVelocity = App.Velocity
				if IsValid(ink.filter) then
					local aimvector = ss:ProtectedCall(ink.filter.GetAimVector, ink.filter) or ink.filter:GetForward()
					App.TrailVelocity = aimvector * App.Speed
				end
			end
			
			if trailtime < ink.Straight then -- Goes straight
				App.TrailPos = App.InitPos + App.TrailVelocity * trailtime
			elseif trailtime > ink.Straight + DecreaseFrame then -- Falls straight
				local time = ink.Straight + DecreaseFrame / 2
				local pos = App.InitPos + App.TrailVelocity * time
				local falltime = trailtime - ink.Straight - DecreaseFrame
				App.TrailPos = pos + physenv.GetGravity() * 1.5 * falltime * falltime / 2
			else
				local time = ink.Straight + (trailtime - ink.Straight) / 2
				App.TrailPos = App.InitPos + App.TrailVelocity * time
			end
			
			App.TrailPos = LerpVector(math.Clamp(
			(trailtime - ink.Straight) / TrailMergeTime, 0, .75), App.TrailPos, App.Pos)
		end
		
		local radius = Lerp(lifetime / ink.Straight, ss.mColRadius / 5, ss.mColRadius)
		local dir = ink.endpos - ink.start
		local f = App.Pos -- Forward position
		local mean, a = f - dir / 2, App.Velocity:Angle()
		local r, u = mean + a:Right() * radius, mean + a:Up() * radius
		local l, d = mean * 2 - r, mean * 2 - u
		local tr = util.TraceHull(ink)
		local frac = math.Clamp((rtime - ink.TrailTime) / TrailLagTime, 0, 1)
		local trpos = LerpVector(frac, App.InitPos, App.TrailPos)
		
		render.SetColorMaterial()
		mesh.Begin(MATERIAL_TRIANGLES, 5)
		for s, t in pairs {[l] = u, [u] = r, [r] = d, [d] = l} do
			for _, v in ipairs {trpos, s, t} do
				mesh.Color(ink.Color.r, ink.Color.g, ink.Color.b, 255)
				mesh.Position(v)
				mesh.AdvanceVertex()
			end
		end
		mesh.End()
		render.DrawSphere(mean, radius, 8, 8, ink.Color)
		
		if not tr.Hit then
			ink.start = tr.HitPos
			continue
		elseif tr.HitWorld then
			-- World hit effect here
		elseif IsValid(tr.Entity) and tr.Entity:Health() > 0 then
			-- Entity hit effect here
			if ink.filter == LocalPlayer() then
				local ent = ss:IsValidInkling(tr.Entity)
				if not ent or ent:GetColorCode() ~= ink.ColorCode then
					surface.PlaySound(ink.IsCritical and ss.DealDamageCritical or ss.DealDamage)
				end
			end
		end
		
		ss.InkTraces[ink] = nil
	end
end)
