AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Traffic Light"
ENT.Category = "Decent Vehicle"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Pattern", {
		KeyName = "pattern",
		Edit = {
			type = "Int",
			order = 1,
			min = 1,
			max = #DecentVehicleDestination.TrafficLights,
		},
	})
end	
