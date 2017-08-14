
local reference_polys = {
	{pos = Vector(100, 0, 0)},
	{pos = Vector(1/2^0.5 * 100, 1/2^0.5 * 100, 0)},
	{pos = Vector(0, 100, 0)},
	{pos = Vector(-1/2^0.5 * 100, 1/2^0.5 * 100, 0)},
	{pos = Vector(-100, 0, 0)},
	{pos = Vector(-1/2^0.5 * 100, -1/2^0.5 * 100, 0)},
	{pos = Vector(0, -100, 0)},
	{pos = Vector(1/2^0.5 * 100, -1/2^0.5 * 100, 0)},
--	{pos = Vector(0, -150, 0)},
}

local mat = Material("debug/debugbrushwireframe")
local IMaterial = Material("splatoon/splatoonink.vmt")
local WaterOverlap = Material("splatoon/splatoonwater.vmt")
local InkGroup = {}

net.Receive("SplatoonSWEPs: Broadcast ink vertices", function(len, ply)
	if not LocalPlayer().IsReceivingInkData then
		LocalPlayer().IsReceivingInkData = true
		LocalPlayer().ReceivingInkData = {}
	end
	
	local pos, u, v = vector_origin, 0, 0
	for i = 1, len / 8 do
		pos = net.ReadVector()
		u = net.ReadFloat()
		v = net.ReadFloat()
		if pos == vector_origin then break end
		table.insert(LocalPlayer().ReceivingInkData, {pos = pos, u = u, v = v})
	end
end)

net.Receive("SplatoonSWEPs: Finalize ink refreshment", function(...)
	local org = net.ReadVector()
	local normal = net.ReadVector()
	local color = net.ReadColor()
	local id = net.ReadInt(32)
	local inkid = net.ReadDouble()
	local newink = LocalPlayer().ReceivingInkData
	if not InkGroup[id] then InkGroup[id] = {} end
	if InkGroup[id].imesh then
		InkGroup[id].imesh:Destroy()
	end
	InkGroup[id].imesh = Mesh()
	InkGroup[id][inkid] = {}
	
	local triangles = {}
	local lightcolor, r, g, b = vector_origin, 0, 0, 0
	for i, v in ipairs(newink) do
		lightcolor = render.ComputeLighting(v.pos, normal) + Vector(0.1, 0.1, 0.1)
		r = math.Clamp(color.r * lightcolor.x, 0, 255)
		g = math.Clamp(color.g * lightcolor.y, 0, 255)
		b = math.Clamp(color.b * lightcolor.z, 0, 255)
		newink[i].color = Color(r, g, b)
		table.insert(InkGroup[id][inkid], newink[i])
	end
	
	for i, ink in pairs(InkGroup[id]) do
		if not isnumber(i) then continue end
		for k, v in ipairs(ink) do
			table.insert(triangles, v)
		end
	end
	triangles = table.Reverse(triangles)
	
	InkGroup[id].imesh:BuildFromTriangles(triangles)
	LocalPlayer().IsReceivingInkData = nil
	LocalPlayer().ReceivingInkData = {}
end)

function ClearInk()
	for k, v in pairs(InkGroup) do
		if v.imesh then v.imesh:Destroy() end
	end
	InkGroup = {}
end

local im = Mesh()
local dummy = ClientsideModel("models/error.mdl")
dummy:SetModelScale(0)
local u = {}
local v = {}
for i = 1, #reference_polys do
	u[i], v[i] = math.random(), math.random()
end
mesh.Begin(im, MATERIAL_POLYGON, #reference_polys)
for i = #reference_polys, 1, -1 do
	mesh.Position(reference_polys[i].pos)
	mesh.Normal(Vector(0.7, 0, 1))
	mesh.Color(math.random(0, 255), 255, 255, 255)
	mesh.TexCoord(0, u[i], v[i])
	mesh.AdvanceVertex()
	debugoverlay.Text(reference_polys[i].pos, i, 4)
end
mesh.End()

local function DrawMeshes()
	for id, ink in pairs(InkGroup) do
		render.SetMaterial(IMaterial)
		ink.imesh:Draw()
		render.SetMaterial(WaterOverlap)
		ink.imesh:Draw()
	end
	
	-- for i = #reference_polys, 1, -1 do
		-- debugoverlay.Text(reference_polys[i].pos, i, 0.1)
	-- end
	-- render.SetMaterial(IMaterial)
	-- im:Draw()
end
hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", DrawMeshes)
