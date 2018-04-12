--[[
	The main projectile entity of SplatoonSWEPs!!!
]]

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.FlyingModel = Model "models/Items/grenadeAmmo.mdl"
ENT.IsSplatoonProjectile = true

-- Initialize function.
-- Honestly, I'm not really sure what SENTs should do in their initialization.
function ENT:SharedInit(mdl)
	self:SetModel(mdl or self.FlyingModel)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self:SetMoveCollide(MOVECOLLIDE_FLY_SLIDE)
	self:SetNoDraw(true)
	self:SetSolidFlags(FSOLID_NOT_STANDABLE)
end

function ENT:SetupDataTables() --For material proxy.
	self:NetworkVar("Vector", 0, "InkColorProxy")
end
