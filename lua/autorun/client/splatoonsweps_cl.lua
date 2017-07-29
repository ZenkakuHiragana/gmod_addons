
local reference_polys = {
	{pos = Vector(0, 0, 0)},
	{pos = Vector(1/2^0.5 * 100, 1/2^0.5 * 100, 0)},
	{pos = Vector(100, 0, 0)},
	{pos = Vector(0, 0, 0)},
	{pos = Vector(0, 100, 0)},
	{pos = Vector(1/2^0.5 * 100, 1/2^0.5 * 100, 0)}
}

local IMaterial = Material("splatoon/splatoonink.vmt")
local WaterOverwrap = Material("splatoon/splatoonwater.vmt")
local IMesh = {}
local Triangles = {}
local Dummies = {}
net.Receive("SplatoonSWEPs: Broadcast ink vertices", function(len, ply)
	local m = net.ReadTable()
	local color = net.ReadVector()
	local org = net.ReadVector()
	local normal = net.ReadVector()
	local imesh = Mesh()
	local dummy = ClientsideModel("error.mdl")
	dummy:SetModelScale(0)
	imesh:BuildFromTriangles(m)
	table.Add(IMesh, {{imesh = imesh, color = color, pos = org, normal = -normal}})
	table.Add(Triangles, {m})
	table.Add(Dummies, {dummy})
end)

function ClearInk()
	for i, e in ipairs(Dummies) do e:Remove() end
	IMesh, Triangles, Dummies = {}, {}, {}
end

local function DrawMeshes()
	for i, m in ipairs(IMesh) do
		Dummies[i]:SetPos(m.pos + m.normal)
		Dummies[i]:SetAngles(m.normal:Angle())
		Dummies[i]:DrawModel()
		render.SetMaterial(IMaterial)
		IMaterial:SetVector("$color", m.color)
		m.imesh:Draw()
		render.SetMaterial(WaterOverwrap)
		m.imesh:Draw()
	end
	IMaterial:SetVector("$color", Vector(1, 1, 1))
end
hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", DrawMeshes)
