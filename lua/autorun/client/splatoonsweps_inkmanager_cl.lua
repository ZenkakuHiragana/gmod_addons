
--Clientside ink manager
if not SplatoonSWEPs then return end
SplatoonSWEPs.InkQueue = {}

local MAX_PROCESS_QUEUE_AT_ONCE = 10000
local mat = Material "splatoonsweps/splatoonink"
local lightmat = Material "splatoonsweps/splatooninklight"
local test = Material "gm_construct/water"
local WaterOverlap = Material "splatoonsweps/splatoonwater"
local function DrawMeshes()
	if SplatoonSWEPs.RenderTarget.Ready then
		render.SetMaterial(SplatoonSWEPs.RenderTarget.Material)
		for i, m in ipairs(SplatoonSWEPs.IMesh) do
			m:Draw()
		end
	end
end

local hsv = Material "vgui/hsv"
local function DrawCircle(x, y, r, seg, uv)
	uv = uv or 0
	
	-- surface.SetMaterial(hsv)
	-- surface.DrawTexturedRect(x - r, y - r, 2 * r, 2 * r)
end

local function ProcessQueue()
	while true do
		local done = 0
		for i, q in ipairs(SplatoonSWEPs.InkQueue) do
			local c = SplatoonSWEPs:GetColor(q.c)
			local facearray = tonumber(q.facearray) or q.facearray
			local f = SplatoonSWEPs.Surfaces[facearray][q.facenumber]
			local org = f.MeshVertex.origin * SplatoonSWEPs:GetRTSize()
			local p = org + SplatoonSWEPs:UnitsToPixels(SplatoonSWEPs:To2D(q.pos, f.origin, f.Vertices2D.angle))
			local bound = SplatoonSWEPs:UnitsToPixels(f.Vertices2D.bound)
			local radius = SplatoonSWEPs:UnitsToPixels(q.r)
			
			local amb = render.GetAmbientLightColor()
			local light = render.ComputeLighting(q.pos + vector_up, vector_up)
			local clamp = (amb + light) * 6
			local r = c.r * math.Clamp(clamp.x, 0, 1) / 255
			local g = c.g * math.Clamp(clamp.y, 0, 1) / 255
			local b = c.b * math.Clamp(clamp.z, 0, 1) / 255
			
			render.PushRenderTarget(SplatoonSWEPs.RenderTarget.Texture)
			render.SetScissorRect(math.floor(org.x) - 1, math.floor(org.y) - 1,
				math.ceil(org.x + bound.x) + 1, math.ceil(org.y + bound.y) + 1, true)
			cam.Start2D()
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(mat)
			mat:SetVector("$color", Vector(r, g, b))
			local circle = {{x = p.x, y = p.y, u = 0.5, v = 0.5}}
			for i = 0, 32 do
				local a = math.rad((i / 32) * -360)
				table.insert(circle, {
					x = p.x + math.sin(a) * radius,
					y = p.y + math.cos(a) * radius,
					u = math.sin(a) / 2 + 0.5,
					v = math.cos(a) / 2 + 0.5,
				})
			end
			table.insert(circle, {x = p.x, y = p.y + r, u = 0.5, v = 1})
			surface.DrawPoly(circle)
			mat:SetVector("$color", Vector(1, 1, 1))
			
			surface.SetMaterial(lightmat)
			lightmat:SetFloat("$alpha", math.Rand(0, (r + g + b) / 3 + 0.05))
			local uv = math.Rand(0.2, 1)
			local deg = math.Rand(-90, 90)
			circle = {{x = p.x, y = p.y, u = uv, v = uv}}
			for i = 0, 32 do
				local a = math.rad((i / 32) * -360)
				table.insert(circle, {
					x = p.x + math.sin(a) * radius,
					y = p.y + math.cos(a) * radius,
					u = math.sin(a + deg) * uv + uv,
					v = math.cos(a + deg) * uv + uv,
				})
			end
			table.insert(circle, {x = p.x, y = p.y + r, u = uv, v = 2 * uv})
			surface.DrawPoly(circle)
			lightmat:SetFloat("$alpha", 1.0)
			
			cam.End2D()
			render.SetScissorRect(0, 0, 0, 0, false)
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

-- hook.Remove("HUDPaint", "test")
-- hook.Add("HUDPaint", "test", function()
	-- render.PushRenderTarget(SplatoonSWEPs.RenderTarget.Texture)
	-- surface.SetAlphaMultiplier(0.5)
	-- render.SetBlend(0.5)
	-- surface.SetDrawColor(255, 255, 255, 255)
	-- surface.SetMaterial(mat)
	-- surface.DrawTexturedRect(0, 0, 512, 512)
	-- render.PopRenderTarget()
-- end)
