
--Clientside ink manager
if not SplatoonSWEPs then return end
SplatoonSWEPs.InkQueue = {}

util.PrecacheModel "models/hunter/blocks/cube025x025x025.mdl"
-- local dummy

local MAX_PROCESS_QUEUE_AT_ONCE = 10000
local inkmaterial = Material "splatoonsweps/splatoonink"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
local inklightmaterial = Material "splatoonsweps/splatooninklight"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local test = Material "gm_construct/water"
local WaterOverlap = Material "splatoonsweps/splatoonwater"
local function DrawMeshes()
	-- if not IsValid(dummy) then
		-- dummy = ents.CreateClientProp "models/hunter/blocks/cube025x025x025.mdl"
		-- dummy:SetPos(vector_origin)
		-- dummy:Spawn()
	-- end
		
	if SplatoonSWEPs.RenderTarget.Ready then
		-- dummy:DrawModel()
		local lighton = LocalPlayer():FlashlightIsOn() or #ents.FindByClass("*projectedtexture*") > 0
		render.SetMaterial(SplatoonSWEPs.RenderTarget.Material)
		render.SetLightmapTexture(SplatoonSWEPs.RenderTarget.Lightmap)
		for i, m in ipairs(SplatoonSWEPs.IMesh) do
			m:Draw()
		end
		
		if lighton then
			render.PushFlashlightMode(true)
			for i, m in ipairs(SplatoonSWEPs.IMesh) do
				m:Draw()
			end
			render.PopFlashlightMode()
		end
		
		render.SetMaterial(SplatoonSWEPs.RenderTarget.WaterMaterial)
		for i, m in ipairs(SplatoonSWEPs.IMesh) do
			m:Draw()
		end
	end
end

local CircleFraction = -360 / 32
local function CirclePoly(x, y, r, uv, deg)
	uv, deg = uv or 0.5, deg or 0
	local c = {{x = x, y = y, u = uv, v = uv}, {x = x, y = y + r, u = uv, v = uv * 2}}
	for i = 0, 32 do
		local a = math.rad(i * CircleFraction)
		local sin, cos = math.sin(a + deg), math.cos(a + deg)
		table.insert(c, i + 2, {
			x = x + sin * r, y = y + cos * r,
			u = sin * uv + uv, v = cos * uv + uv,
		})
	end
	return c
end

local function GetLight(p, n)
	local amb = render.GetAmbientLightColor()
	local lightcolor = render.GetLightColor(p)
	local light = render.ComputeLighting(p + n * 100, n)
	local avg = (light + lightcolor + amb / 5) / 2.2
	avg.x = math.Remap(avg.x, 0, 1, 0, 0.3)
	avg.y = math.Remap(avg.y, 0, 1, 0, 0.3)
	avg.z = math.Remap(avg.z, 0, 1, 0, 0.3)
	return avg
end

local function ProcessQueue()
	local self = SplatoonSWEPs
	local vector_one = Vector(1, 1, 1)
	while true do
		local done = 0
		for i, q in ipairs(self.InkQueue) do
			local c = self:GetColor(q.c)
			local facearray = tonumber(q.facearray) or q.facearray
			local f = self.Surfaces[facearray][q.facenumber]
			local org = f.MeshVertex.origin * self:GetRTSize()
			local p = org + self:UnitsToPixels(self:To2D(q.pos, f.origin, f.Vertices2D.angle))
			local bound = self:UnitsToPixels(f.Vertices2D.bound)
			local radius = self:UnitsToPixels(q.r)
			local sx, sy = math.floor(org.x) - 1, math.floor(org.y) - 1
			local bx, by = math.ceil(org.x + bound.x) + 1, math.ceil(org.y + bound.y) + 1
			local circle = CirclePoly(p.x, p.y, radius)
			local circle_white = CirclePoly(p.x, p.y, radius, math.Rand(0.2, 1), math.Rand(-90, 90))
			local circle_normal = CirclePoly(p.x, p.y, radius, math.Rand(0.08, 0.16), math.Rand(-30, 30))
			facearray = self.Surfaces[facearray]
			
			render.PushRenderTarget(self.RenderTarget.BaseTexture)
			render.SetScissorRect(sx, sy, bx, by, true)
			cam.Start2D()
			surface.SetDrawColor(color_white)
			surface.SetMaterial(inkmaterial)
			inkmaterial:SetVector("$color", Vector(c.r, c.g, c.b) / 255)
			surface.DrawPoly(circle)
			inkmaterial:SetVector("$color", vector_one)
			
			surface.SetMaterial(inklightmaterial)
			inklightmaterial:SetFloat("$alpha", math.Rand(0.05, .4))
			surface.DrawPoly(circle_white)
			inklightmaterial:SetFloat("$alpha", 1.0)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopRenderTarget()
			
			--Draw on normal map
			render.PushRenderTarget(self.RenderTarget.Normalmap)
			render.OverrideBlendFunc(true, BLEND_ONE, BLEND_ZERO, BLEND_ONE, BLEND_ZERO)
			render.SetScissorRect(sx, sy, bx, by, true)
			cam.Start2D()
			surface.SetMaterial(normalmaterial)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawPoly(circle_normal)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideBlendFunc(false)
			render.PopRenderTarget()
			
			--Draw on lightmap
			local light = GetLight(q.pos, facearray.normal)
			local lp = (p - org) / 2
			org, bound = org / 2, bound / 2
			sx, sy = math.floor(org.x) - 1, math.floor(org.y) - 1
			bx, by = math.ceil(org.x + bound.x) + 1, math.ceil(org.y + bound.y) + 1
			render.PushRenderTarget(self.RenderTarget.Lightmap)
			render.SetScissorRect(sx, sy, bx, by, true)
			cam.Start2D()
			draw.NoTexture()
			surface.SetDrawColor(light:ToColor())
			surface.DrawPoly(CirclePoly(p.x / 2, p.y / 2, radius / 6))
			surface.SetMaterial(lightmapmaterial)
			lightmapmaterial:SetVector("$color", light)
			radius = radius / 8
			for n, rad in pairs {[8] = radius * 1.6, [14] = radius * 2.6, [18] = radius * 3.6} do
				for i = 1, n do
					local rx = rad * math.cos(math.rad(360 / n) * i) + lp.x
					local ry = rad * math.sin(math.rad(360 / n) * i) + lp.y
					local vec = self:To3D(self:PixelsToUnits(Vector(rx, ry) * 2), f.origin, f.Vertices2D.angle)
					light = GetLight(vec, facearray.normal)
					lightmapmaterial:SetVector("$color", light)
					surface.DrawPoly(CirclePoly(rx + org.x, ry + org.y, radius))
				end
			end
			lightmapmaterial:SetVector("$color", vector_one)
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
			render.OverrideAlphaWriteEnable(false)
			render.PopRenderTarget()
			
			q.done = true
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
