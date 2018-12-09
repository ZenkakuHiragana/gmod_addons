
ENT.Type = "point"
function ENT:Initialize()
	if #ents.FindByClass(self.ClassName) > 1 then self:Remove() return end
	DecentVehicleDestination.SaveEntity = self
end
