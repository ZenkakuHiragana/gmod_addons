
--Clientside ink manager
if not SplatoonSWEPs then return end
SplatoonSWEPs.InkQueue = {}

local MAX_PROCESS_QUEUE_AT_ONCE = 80
local inkmaterial = Material "splatoonsweps/splatoonink"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
-- local inkmaterial = Material "vgui/gmod_tool"
-- local normalmaterial = Material "vgui/gmod_tool"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local LightmapSampleTable = {[7] = .8}
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
local ambscale = SplatoonSWEPs.GrayScaleFactor:Dot(amb) / 2
local function DrawMeshes(bDrawingDepth, bDrawingSkybox, ...)
	if (GetConVar "r_3dsky":GetBool() and SplatoonSWEPs.Has3DSkyBox or false) == bDrawingSkybox
	or bDrawingDepth or not SplatoonSWEPs.RenderTarget.Ready or GetConVar "mat_wireframe":GetBool() then return end
	local hdrscale = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(hdrscale * ambscale) --Set HDR scale for custom lightmap
	render.SetMaterial(SplatoonSWEPs.RenderTarget.Material) --Ink base texture
	render.SetLightmapTexture(SplatoonSWEPs.RenderTarget.Lightmap) --Set custom lightmap
	render.OverrideDepthEnable(true, true) --Write to depth buffer for translucent surface culling
	for i, m in ipairs(SplatoonSWEPs.IMesh) do m:Draw() end --Draw whole ink surface
	render.OverrideDepthEnable(false) --Back to default
	render.SetToneMappingScaleLinear(hdrscale) --Back to default
	render.UpdateRefractTexture() --Make the ink "watery"
	render.SetMaterial(SplatoonSWEPs.RenderTarget.WaterMaterial) --Set water texture for ink
	for i, m in ipairs(SplatoonSWEPs.IMesh) do m:Draw() end --Draw ink again
	if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then return end
	render.PushFlashlightMode(true) --Ink lit by player's flashlight or projected texture
	render.SetMaterial(SplatoonSWEPs.RenderTarget.Material) --Ink base texture
	for i, m in ipairs(SplatoonSWEPs.IMesh) do m:Draw() end --Draw once again
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
	local self = SplatoonSWEPs
	while true do
		local done = 0
		for i, q in ipairs(self.InkQueue) do
			local c = self:GetColor(q.c)
			local radius = math.Round(self:UnitsToPixels(q.r))
			local size, vrad = radius * 2, self.vector_one * radius
			local surf = self.SequentialSurfaces
			local bound = self:UnitsToPixels(surf.Bounds[q.n])
			local uvorg = self:UVToPixels(Vector(surf.u[q.n], surf.v[q.n]))
			local angle, origin, normal, moved = Angle(surf.Angles[q.n]), surf.Origins[q.n], surf.Normals[q.n], surf.Moved[q.n]
			local pos2d = self:UnitsToPixels(self:To2D(q.pos, origin, angle))
			if moved then pos2d.x, q.inkangle = -pos2d.x, -(q.inkangle + 90) end
			local lightorg = q.pos - normal * (normal:Dot(q.pos - origin) - 1) * q.dispflag
			local light = GetLight(lightorg, normal)
			local center = Vector(math.Round(pos2d.x + uvorg.x), math.Round(pos2d.y + uvorg.y))
			local s = Vector(math.floor(uvorg.x) - 1, math.floor(uvorg.y) - 1)
			local b = Vector(math.ceil(uvorg.x + bound.x) + 1, math.ceil(uvorg.y + bound.y) + 1)
			if not self:CollisionAABB2D(s, b, center - vrad, center + vrad) then q.done = math.huge continue end
			local settexture = "splatoonsweps/inkshot/shot" .. tostring(q.t)
			local sizeres = q.t < 4 and 1 or .5
			
			inkmaterial:SetTexture("$basetexture", settexture)
			normalmaterial:SetTexture("$basetexture", settexture .. "n")
			render.PushRenderTarget(self.RenderTarget.BaseTexture)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(c)
			surface.SetMaterial(inkmaterial)
			surface.DrawTexturedRectRotated(center.x, center.y, size * sizeres, size, q.inkangle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on normal map
			render.PushRenderTarget(self.RenderTarget.Normalmap)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(color_white)
			surface.SetMaterial(normalmaterial)
			surface.DrawTexturedRectRotated(center.x , center.y, size * sizeres, size, q.inkangle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on lightmap
			radius, size = radius / 2, size / 2
			center, uvorg, s, b = center / 2, uvorg / 2, s / 2, b / 2
			s.x, s.y, b.x, b.y = math.floor(s.x), math.floor(s.y), math.ceil(b.x), math.ceil(b.y)
			render.PushRenderTarget(self.RenderTarget.Lightmap)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(light:ToColor())
			surface.SetMaterial(lightmapmaterial)
			surface.DrawTexturedRect(center.x - radius, center.y - radius, size, size)
			for n, mul in pairs(LightmapSampleTable) do
				for i = 1, n do
					local r = Lightrad[n][i] * radius * mul
					surface.SetDrawColor(GetLight(self:To3D(self:PixelsToUnits(
					surf.Moved[q.n] and Vector(-r.x, r.y) or r) * 2, lightorg, angle), normal):ToColor())
					r = r + center - self.vector_one * radius
					surface.DrawTexturedRect(r.x, r.y, size, size)
				end
			end
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideAlphaWriteEnable(false)
			render.PopRenderTarget()
			
			q.done, done = q.done + 1, done + 1
			if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then coroutine.yield() end
		end
		
		local newqueue = {}
		for i, v in ipairs(SplatoonSWEPs.InkQueue) do
			if not v.done or v.done < 8 then newqueue[#newqueue + 1] = v end
		end
		SplatoonSWEPs.InkQueue = newqueue
		coroutine.yield()
	end
end

local DoCoroutine = coroutine.create(ProcessQueue)
local function GMTick()
	if coroutine.status(DoCoroutine) == "dead" then return end
	local ok, message = coroutine.resume(DoCoroutine)
	if not ok then ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n") end
	if not SplatoonSWEPs.RenderTarget.Ready then
		net.Start "SplatoonSWEPs: Fetch ink information"
		net.SendToServer()
	end
end

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPsDrawInk", DrawMeshes)
hook.Add("Tick", "SplatoonSWEPsRegisterInk_cl", GMTick)
hook.Add("PostDrawSkyBox", "SplatoonSWEPsTestIfMapHas3DSkyBox", function()
	SplatoonSWEPs.Has3DSkyBox = true
	hook.Remove("PostDrawSkyBox", "SplatoonSWEPsTestIfMapHas3DSkyBox")
end)
