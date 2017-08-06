
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
local Receiving = {}

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
	imesh:BuildFromTriangles(Receiving)
	
	table.insert(IMesh[id], {id = id, imesh = imesh, color = color, pos = org, normal = -normal})
	table.insert(Triangles[id], Receiving)
	table.insert(Dummies[id], dummy)
	Receiving = {}
end)

-- net.Receive("SplatoonSWEPs: ", function(len, ply)
	-- local m = net.ReadTable()
	-- local color = net.ReadVector()
	-- local org = net.ReadVector()
	-- local normal = net.ReadVector()
	-- local imesh = Mesh()
	-- local dummy = ClientsideModel("models/error.mdl")
	-- dummy:SetModelScale(0)
	-- imesh:BuildFromTriangles(m)
	-- table.insert(IMesh, {imesh = imesh, color = color, pos = org, normal = -normal})
	-- table.insert(Triangles, m)
	-- table.insert(Dummies, dummy)
-- end)

function ClearInk()
	for i, e in ipairs(Dummies) do e:Remove() end
	Receiving, IMesh, Triangles, Dummies = {}, {}, {}, {}
end

local function DrawMeshes()
	for i, m in pairs(IMesh) do
		for k, v in ipairs(m) do
			Dummies[i][k]:SetPos(v.pos + v.normal)
			Dummies[i][k]:SetAngles(v.normal:Angle())
			Dummies[i][k]:DrawModel()
			render.SetMaterial(IMaterial)
			IMaterial:SetVector("$color", v.color)
			v.imesh:Draw()
			render.SetMaterial(WaterOverwrap)
			v.imesh:Draw()
		end
	end
	IMaterial:SetVector("$color", Vector(1, 1, 1))
end
hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", DrawMeshes)
