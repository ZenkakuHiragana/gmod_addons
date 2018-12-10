
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/m33_333/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile()

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
	
	if CLIENT then return end
	self:NetworkVarNotify("Pattern", function(self, name, old, new)
		if not self.Waypoints then return end
		self.Waypoints.Pattern = new
		duplicator.StoreEntityModifier(self, "Decent Vehicle: Save traffic light link", self.Waypoints)
	end)
end	
