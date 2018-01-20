
--Clientside ink manager
if not SplatoonSWEPs then return end
SplatoonSWEPs.InkQueue = {}

local MAX_PROCESS_QUEUE_AT_ONCE = 80
local inkmaterial = Material "splatoonsweps/splatoonink"
-- local inkmaterial = Material "vgui/cursors/up"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
local inklightmaterial = Material "splatoonsweps/splatooninklight"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local WaterOverlap = Material "splatoonsweps/splatoonwater"
local wireframe = Material "color"
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

function SplatoonSWEPs:DrawMeshes(bDrawingSkybox, bDrawingDepth)
	if (GetConVar "r_3dsky":GetBool() and SplatoonSWEPs.Has3DSkyBox or false) == bDrawingSkybox or bDrawingDepth then return end
	if not SplatoonSWEPs.RenderTarget.Ready then return end
	local hdrscale = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(hdrscale / 9)
	render.SetMaterial(SplatoonSWEPs.RenderTarget.Material)
	render.SetLightmapTexture(SplatoonSWEPs.RenderTarget.Lightmap)
	for i, m in ipairs(SplatoonSWEPs.IMesh) do m:Draw() end
	if LocalPlayer():FlashlightIsOn() or #ents.FindByClass "*projectedtexture*" > 0 then
		render.PushFlashlightMode(true)
		for i, m in ipairs(SplatoonSWEPs.IMesh) do m:Draw() end
		render.PopFlashlightMode()
	end
	
	render.SetMaterial(SplatoonSWEPs.RenderTarget.WaterMaterial)
	for i, m in ipairs(SplatoonSWEPs.IMesh) do m:Draw() end
	render.SetToneMappingScaleLinear(hdrscale)
end

local amb
local function GetLight(p, n)
	local lightcolor = render.GetLightColor(p + n) / 2
	local light = render.ComputeLighting(p + n, n) / 2
	if lightcolor:LengthSqr() > 1 then lightcolor:Normalize() end
	if light:LengthSqr() > 1 then light:Normalize() end
	return (light + lightcolor + amb) / 2.1
end

local function ProcessQueue()
	amb = render.GetAmbientLightColor() / 10
	local self = SplatoonSWEPs
	local amblen = amb:Length() * 10
	if amblen > 1 then amb = amb / amblen end
	while true do
		local done = 0
		for i, q in ipairs(self.InkQueue) do
			local c = self:GetColor(q.c)
			local radius = math.Round(self:UnitsToPixels(q.r))
			local size = radius * 2
			local surf = self.SequentialSurfaces
			local bound = self:UnitsToPixels(surf.Bounds[q.n])
			local uvorg = self:UVToPixels(Vector(surf.u[q.n], surf.v[q.n]))
			local angle, origin, normal = Angle(surf.Angles[q.n]), surf.Origins[q.n], surf.Normals[q.n]
			if surf.Moved[q.n] then angle:RotateAroundAxis(normal, -90) end
			local light = GetLight(q.pos, normal)
			local pos2d = self:UnitsToPixels(self:To2D(q.pos, origin, angle))
			if surf.Moved[q.n] then pos2d.x = -pos2d.x end
			local center = Vector(math.Round(pos2d.x + uvorg.x), math.Round(pos2d.y + uvorg.y))
			local corner = center - self.vector_one * radius
			local s = Vector(math.floor(uvorg.x) - 1, math.floor(uvorg.y) - 1)
			local b = Vector(math.ceil(uvorg.x + bound.x) + 1, math.ceil(uvorg.y + bound.y) + 1)
			if not self:CollisionAABB2D(s, b, corner, corner + self.vector_one * size) then continue end
			local _, roll = WorldToLocal(vector_origin, angle, vector_origin, normal:Angle())
			local cr = radius * 1.01
			local circle = {
				{x = center.x, y = center.y, u = .5, v = .5},
				{x = center.x, y = center.y + cr, u = .5, v = 1},
			}
			for i = 0, NumPoly do
				table.insert(circle, 2, {
					x = center.x + cr * Polycos[i],
					y = center.y + cr * Polysin[i],
					u = Polycos[i] / 2 + .5,
					v = Polysin[i] / 2 + .5,
				})
			end
			inkmaterial:SetVector("$color", Vector(c.r, c.g, c.b) / 255)
			render.PushRenderTarget(self.RenderTarget.BaseTexture)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(color_white)
			surface.SetMaterial(inkmaterial)
			surface.DrawTexturedRectRotated(center.x, center.y, size, size, roll.roll - q.inkangle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			for i, v in ipairs(surf.Vertices[q.n]) do
				local w = surf.Vertices[q.n][i % #surf.Vertices[q.n] + 1]
				DebugLine(Vector(v.u, v.v) * 1000, Vector(w.u, w.v) * 1000, true)
				-- DebugLine(v.pos, w.pos, true)
			end
			--Draw on normal map
			render.PushRenderTarget(self.RenderTarget.Normalmap)
			render.OverrideBlendFunc(true, BLEND_ONE, BLEND_ZERO, BLEND_ONE, BLEND_ZERO)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetMaterial(normalmaterial)
			surface.DrawPoly(circle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideBlendFunc(false)
			render.PopRenderTarget()
			
			--Draw on lightmap
			radius, size, bound = radius / 2, size / 2, bound / 2
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
					lightmapmaterial:SetVector("$color", GetLight(self:To3D(self:PixelsToUnits(
					surf.Moved[q.n] and Vector(-r.x, r.y) or r) * 2, q.pos, angle), normal))
					r = r + center - self.vector_one * radius
					surface.DrawTexturedRect(r.x, r.y, size, size)
				end
			end
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideAlphaWriteEnable(false)
			render.PopRenderTarget()
			
			q.done, done = true, done + 1
			if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then coroutine.yield() end
		end
		
		local newqueue = {}
		for i, v in ipairs(SplatoonSWEPs.InkQueue) do
			if not v.done then newqueue[#newqueue + 1] = v end
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

hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", SplatoonSWEPs.DrawMeshes)
hook.Add("Tick", "SplatoonSWEPsRegisterInk_cl", GMTick)
hook.Add("PostDrawSkyBox", "SplatoonSWEPsTestIfMapHas3DSkyBox", function()
	SplatoonSWEPs.Has3DSkyBox = true
	hook.Remove("PostDrawSkyBox", "SplatoonSWEPsTestIfMapHas3DSkyBox")
end)
