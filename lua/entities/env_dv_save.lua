
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

ENT.Type = "point"
local dvd = DecentVehicleDestination
function ENT:Initialize()
	if #ents.FindByClass(self.ClassName) > 1 then self:Remove() return end
	dvd.SaveEntity = self
end

if CLIENT then return end
function ENT:PreEntityCopy()
	duplicator.StoreEntityModifier(self, "Decent Vehicle: Save waypoints", dvd.GetSaveTable())
end
