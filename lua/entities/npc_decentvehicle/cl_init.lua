include "shared.lua"
include "playermeta.lua"

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	self:SetModel(self.Modelname)
	self:SetMoveType(MOVETYPE_NONE)
end
