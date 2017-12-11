
include "shared.lua"

ENT.AutomaticFrameAdvance = true
ENT.Author			= "GreatZenkakuMan"
ENT.Contact			= ""
ENT.Instructions	= ""
ENT.PrintName		= "Projectile Ink"
ENT.Purpose			= "Projectile Ink"
function ENT:Initialize()
	if not file.Exists(self.FlyingModel, "GAME") then
		chat.AddText("Splatoon SWEPs: Can't spawn ink!  Required model is not found!")
		return
	end
	
	self:SharedInit()
end
