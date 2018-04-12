
include "shared.lua"

local ss = SplatoonSWEPs
if not ss then return end
ENT.AutomaticFrameAdvance = true
ENT.Author			= "GreatZenkakuMan"
ENT.Contact			= ""
ENT.Instructions	= ""
ENT.PrintName		= "Projectile Ink"
ENT.Purpose			= "Projectile Ink"
function ENT:Initialize()
	if not file.Exists(self.FlyingModel, "GAME") and not ss.HasNotifiedCantSpawnInk then
		ss.HasNotifiedCantSpawnInk = true
		return chat.AddText(ss.Text.Error.CantSpawnInk)
	end
	
	self:SharedInit()
end
