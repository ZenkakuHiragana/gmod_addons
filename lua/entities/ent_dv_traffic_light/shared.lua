
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

ENT.Type = "anim"
ENT.PrintName = "Traffic Light"
ENT.Category = "Decent Vehicle"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Editable = true
ENT.IsDVTrafficLight = true

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
