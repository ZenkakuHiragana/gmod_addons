
--Clientside ink manager
if not SplatoonSWEPs then return end
SplatoonSWEPs.InkQueue = {}

local MAX_PROCESS_QUEUE_AT_ONCE = 80
local inkmaterial = Material "splatoonsweps/splatoonink"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
local inklightmaterial = Material "splatoonsweps/splatooninklight"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local WaterOverlap = Material "splatoonsweps/splatoonwater"
local colormat = Material "color"
local function DrawMeshes(bDrawingDepth, bDrawingSkybox)
	if (GetConVar "r_3dsky":GetBool() and SplatoonSWEPs.Has3DSkyBox or false) == bDrawingSkybox
		or bDrawingDepth or not SplatoonSWEPs.RenderTarget.Ready then return end
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
end

local function GetLight(p, n)
	local amb = render.GetAmbientLightColor()
	local lightcolor = render.GetLightColor(p + n)
	local light = render.ComputeLighting(p + n, n)
	local avg = (light + lightcolor + amb / 5) / 2.2
	avg.x = math.Remap(avg.x, 0, 1, 0, SplatoonSWEPs.InkLightLevel)
	avg.y = math.Remap(avg.y, 0, 1, 0, SplatoonSWEPs.InkLightLevel)
	avg.z = math.Remap(avg.z, 0, 1, 0, SplatoonSWEPs.InkLightLevel)
	return avg
end

local NumPoly = 16
local Polysin, Polycos = {}, {}
for i = 0, NumPoly do
	local a = math.rad(i * -360 / NumPoly)
	Polysin[i], Polycos[i] = math.sin(a), math.cos(a)
end

local LightmapSampleTable = {[7] = 1.3, [14] = 2.4, [18] = 3.6}
local LightmapSampleTable = {[7] = 1.5}
local Lightsin, Lightcos = {}, {}
for n in pairs(LightmapSampleTable) do
	Lightsin[n], Lightcos[n] = {}, {}
	local frac = math.rad(360 / n)
	for k = 1, n do
		Lightsin[n][k] = math.sin(frac * k)
		Lightcos[n][k] = math.cos(frac * k)
	end
end

local function ProcessQueue()
	local self = SplatoonSWEPs
	while true do
		local done = 0
		for i, q in ipairs(self.InkQueue) do
			q.done = true
			local c = self:GetColor(q.c)
			local radius = self:UnitsToPixels(q.r)
			local size = radius * 2
			local surf = self.SequentialSurfaces
			-- print(surf.Normals[q.facenumber] == q.normal, surf.Normals[q.facenumber], q.normal)
			-- print(surf.Angles[q.facenumber] == q.angle, surf.Angles[q.facenumber], q.angle)
			-- print(surf.Origins[q.facenumber] == q.origin, surf.Origins[q.facenumber], q.origin)
			local org = self:UVToPixels(Vector(surf.u[q.facenumber], surf.v[q.facenumber]))
			local bound = self:UnitsToPixels(surf.Bounds[q.facenumber])
			local center = org + self:UnitsToPixels(self:To2D(q.pos, q.origin, q.angle))
			local s = Vector(math.floor(org.x) - 1, math.floor(org.y) - 1)
			local b = Vector(math.ceil(org.x + bound.x) + 1, math.ceil(org.y + bound.y) + 1)
			local light = GetLight(q.pos, q.normal)
			local corner = center - Vector(radius, radius)
			if not self:CollisionAABB2D(s, b, corner, corner + Vector(size, size)) then continue end
			
			inkmaterial:SetVector("$color", Vector(c.r, c.g, c.b) / 255)
			inklightmaterial:SetFloat("$alpha", q.alpha)
			lightmapmaterial:SetVector("$color", light)
			render.PushRenderTarget(self.RenderTarget.BaseTexture)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(color_white)
			surface.SetMaterial(inkmaterial)
			surface.DrawTexturedRect(corner.x, corner.y, size, size)
			surface.SetMaterial(inklightmaterial)
			surface.DrawTexturedRectRotated(center.x, center.y, size, size, q.rotate)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on normal map
			render.PushRenderTarget(self.RenderTarget.Normalmap)
			render.OverrideBlendFunc(true, BLEND_ONE, BLEND_ZERO, BLEND_ONE, BLEND_ZERO)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetMaterial(normalmaterial)
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
			surface.DrawPoly(circle)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideBlendFunc(false)
			render.PopRenderTarget()
			
			--Draw on lightmap
			radius, size, bound = math.ceil(radius / 4), math.ceil(size / 4), bound / 2
			center, org = center / 2, org / 2
			s = Vector(math.floor(s.x / 2), math.floor(s.y / 2))
			b = Vector(math.ceil(b.x / 2), math.ceil(b.y / 2))
			render.PushRenderTarget(self.RenderTarget.Lightmap)
			render.SetScissorRect(s.x, s.y, b.x, b.y, true)
			cam.Start2D()
			surface.SetDrawColor(light:ToColor())
			surface.SetMaterial(lightmapmaterial)
			surface.DrawTexturedRect(math.floor(center.x - radius), math.floor(center.y - radius), size, size)
			for n, mul in pairs(LightmapSampleTable) do
				for i = 1, n do
					local r = Vector(Lightcos[n][i], Lightsin[n][i]) * radius * mul + center
					lightmapmaterial:SetVector("$color", GetLight(self:To3D(
						self:PixelsToUnits((r - org) * 2), q.origin, q.angle), q.normal))
					r.x, r.y = math.floor(r.x - radius), math.floor(r.y - radius)
					surface.DrawTexturedRect(r.x, r.y, size, size)
				end
			end
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideAlphaWriteEnable(false)
			render.PopRenderTarget()
			
			done = done + 1
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
	if coroutine.status(DoCoroutine) ~= "dead" then
		local ok, message = coroutine.resume(DoCoroutine)
		if not ok then
			ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n")
		end
	end
end

hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", DrawMeshes)
hook.Add("Tick", "SplatoonSWEPsRegisterInk_cl", GMTick)
hook.Add("PostDrawSkyBox", "SplatoonSWEPsTestIfMapHas3DSkyBox", function()
	SplatoonSWEPs.Has3DSkyBox = true
	hook.Remove("PostDrawSkyBox", "SplatoonSWEPsTestIfMapHas3DSkyBox")
end)
