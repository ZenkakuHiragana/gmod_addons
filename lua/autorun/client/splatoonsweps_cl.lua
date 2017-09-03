
-- local reference_polys = {
	-- {pos = Vector(100, 0, 0)},
	-- {pos = Vector(1/2^0.5 * 100, 1/2^0.5 * 100, 0)},
	-- {pos = Vector(0, 100, 0)},
	-- {pos = Vector(-1/2^0.5 * 100, 1/2^0.5 * 100, 0)},
	-- {pos = Vector(-100, 0, 0)},
	-- {pos = Vector(-1/2^0.5 * 100, -1/2^0.5 * 100, 0)},
	-- {pos = Vector(0, -100, 0)},
	-- {pos = Vector(1/2^0.5 * 100, -1/2^0.5 * 100, 0)},
-- }

-- local im = Mesh()
-- local dummy = ClientsideModel("models/error.mdl")
-- dummy:SetModelScale(0)
-- local u = {}
-- local v = {}
-- for i = 1, #reference_polys do
	-- u[i], v[i] = math.random(), math.random()
-- end
-- mesh.Begin(im, MATERIAL_POLYGON, #reference_polys)
-- for i = #reference_polys, 1, -1 do
	-- mesh.Position(reference_polys[i].pos)
	-- mesh.Normal(Vector(0.7, 0, 1))
	-- mesh.Color(math.random(0, 255), 255, 255, 255)
	-- mesh.TexCoord(0, u[i], v[i])
	-- mesh.AdvanceVertex()
	-- debugoverlay.Text(reference_polys[i].pos, i, 4)
-- end
-- mesh.End()

local MAX_PROCESS_QUEUE_AT_ONCE = 10

local mat = Material("debug/debugbrushwireframe")
local IMaterial = Material("splatoon/splatoonink.vmt")
local WaterOverlap = Material("splatoon/splatoonwater.vmt")
local InkGroup = InkGroup or {}
local InkQueue = InkQueue or {}

net.Receive("SplatoonSWEPs: Broadcast ink vertices", function(len, ply)
	if not LocalPlayer().IsReceivingInkData then
		LocalPlayer().IsReceivingInkData = true
		LocalPlayer().ReceivingInkData = {}
	end
	
	local pos, u, v = vector_origin, 0, 0
	for i = 1, len / 8 do
		pos = net.ReadVector()
		if pos == vector_origin then break end
		u = net.ReadFloat()
		v = net.ReadFloat()
		table.insert(LocalPlayer().ReceivingInkData, {pos = pos, u = u, v = v})
	end
end)

net.Receive("SplatoonSWEPs: Finalize ink refreshment", function(...)
	local normal = net.ReadVector()
	local color = net.ReadColor()
	local id = net.ReadInt(32)
	local inkid = net.ReadDouble()
	local newink = LocalPlayer().ReceivingInkData
	table.insert(InkQueue, {
		normal = normal,
		color = color,
		id = id,
		inkid = inkid,
		newink = newink,
	})
	LocalPlayer().IsReceivingInkData = nil
	LocalPlayer().ReceivingInkData = {}
end)

function ClearInk()
	for k, v in pairs(InkGroup) do
		if v.imesh then v.imesh:Destroy() end
	end
	InkGroup = {}
	InkQueue = {}
end

local function DrawMeshes()
	for id, ink in pairs(InkGroup) do
		render.SetMaterial(IMaterial)
		ink.imesh:Draw()
		-- render.SetMaterial(WaterOverlap)
		-- ink.imesh:Draw()
	end
end

local function ProcessQueue()
	while true do
		local done = 0
		for i, q in ipairs(InkQueue) do
			if not InkGroup[q.id] then InkGroup[q.id] = {} end
			if InkGroup[q.id].imesh then
				InkGroup[q.id].imesh:Destroy()
			end
			InkGroup[q.id].imesh = Mesh()
			InkGroup[q.id][q.inkid] = {}
			
			local triangles = {}
			local lightcolor, r, g, b = vector_origin, 0, 0, 0
			for i, v in ipairs(q.newink) do
				lightcolor = render.ComputeLighting(v.pos, q.normal) + Vector(0.1, 0.1, 0.1)
				r = math.Clamp(q.color.r * lightcolor.x, 0, 255)
				g = math.Clamp(q.color.g * lightcolor.y, 0, 255)
				b = math.Clamp(q.color.b * lightcolor.z, 0, 255)
				q.newink[i].color = Color(r, g, b)
				table.insert(InkGroup[q.id][q.inkid], q.newink[i])
			end
			
			for i, ink in pairs(InkGroup[q.id]) do
				if not isnumber(i) then continue end
				for k, v in ipairs(ink) do
					table.insert(triangles, v)
				end
			end
			triangles = table.Reverse(triangles)
			InkGroup[q.id].imesh:BuildFromTriangles(triangles)
			
			q.done = true
			done = done + 1
			if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then coroutine.yield() end
		end
		local newqueue = {}
		for i, v in ipairs(InkQueue) do
			if not v.done then table.insert(newqueue. v) end
		end
		InkQueue = newqueue
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