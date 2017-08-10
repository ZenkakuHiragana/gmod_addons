
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
local WaterOverwrap = Material("splatoon/splatoonwater.vmt")
local IMesh = IMesh or {}
local Triangles = Triangles or {}
local Dummies = Dummies or {}
local Receiving = Receiving or {}

net.Receive("SplatoonSWEPs: Reset ink mesh by ID", function(len, ply)
	local id = net.ReadInt(32)
	IMesh[id] = {}
	Triangles[id] = {}
	if Dummies[id] then
		for k, v in ipairs(Dummies[id]) do
			if IsValid(v) then v:Remove() end
		end
	end
	Dummies[id] = {}
	Receiving = {}
end)

net.Receive("SplatoonSWEPs: Broadcast ink vertices", function(len, ply)
	local m = net.ReadTable()
	for k, v in ipairs(m) do
		table.insert(Receiving, v)
	end
end)

net.Receive("SplatoonSWEPs: Finalize ink refreshment", function(len, ply)
	local color = net.ReadVector()
	local org = net.ReadVector()
	local normal = net.ReadVector()
	local id = net.ReadInt(32)
	local imesh = Mesh()
	local dummy = ClientsideModel("models/error.mdl")
	dummy:SetModelScale(0)
	dummy:SetPos(org + normal)
	dummy:SetAngles(normal:Angle())
--	imesh:BuildFromTriangles(Receiving)

	mesh.Begin(imesh, MATERIAL_POLYGON, #Receiving)
	for i = #Receiving, 1, -1 do
		mesh.Position(Receiving[i].pos)
		mesh.Normal(normal)
		mesh.Color(color.x, color.y, color.z, 255)
		mesh.TexCoord(0, Receiving[i].u, Receiving[i].v)
		mesh.AdvanceVertex()
		if #Receiving > 16 then debugoverlay.Text(Receiving[i].pos, i, 4) end
	end
	mesh.End()
	table.insert(IMesh[id], {imesh = imesh, color = color, pos = org, normal = normal})
	table.insert(Triangles[id], Receiving)
	table.insert(Dummies[id], dummy)
	Receiving = {}
end)

function ClearInk()
	for i, e in ipairs(Dummies) do e:Remove() end
	Receiving, IMesh, Triangles, Dummies = {}, {}, {}, {}
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
	mesh.Color(255, 0, 255, 128)
	mesh.TexCoord(0, u[i], v[i])
	mesh.AdvanceVertex()
	debugoverlay.Text(reference_polys[i].pos, i, 4)
end
mesh.End()

local function DrawMeshes()
	dummy:DrawModel()
	for i, m in pairs(IMesh) do
		for k, v in ipairs(m) do
			render.SetMaterial(IMaterial)
			IMaterial:SetVector("$color", v.color)
			v.imesh:Draw()
			render.SetMaterial(WaterOverwrap)
			v.imesh:Draw()
		end
	end
	IMaterial:SetVector("$color", Vector(1, 1, 1))
	-- dummy:SetPos(vector_origin)
	-- dummy:SetAngles(angle_zero)
	-- dummy:SetColor(Color(255, 0, 255))
	-- dummy:DrawModel()
	-- render.SetMaterial(mat)
	-- for i = #reference_polys, 1, -1 do
		-- debugoverlay.Text(reference_polys[i].pos, i, 0.1)
	-- end
	-- render.SetMaterial(IMaterial)
--	im:Draw()
	-- render.SetColorMaterial()
	-- im:Draw()
end
hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", DrawMeshes)
