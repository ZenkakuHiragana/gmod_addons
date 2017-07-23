
include "shared.lua"

function ENT:Initialize()
	if not util.IsValidModel(self.FlyingModel) then
		chat.AddText("Splatoon SWEPs: Can't spawn ink!  Required model is not found!")
		return
	end
	
	self:SharedInit()
end

function ENT:Draw()
	self:DrawModel()
end
