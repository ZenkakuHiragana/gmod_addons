--[[
	The main projectile entity of Splatoon SWEPS!!!
]]

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.FlyingModel = Model "models/Items/grenadeAmmo.mdl"
ENT.IsSplatoonProjectile = true
function ENT:SharedInit(mdl)
	self:SetModel(mdl or self.FlyingModel)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self:SetCustomCollisionCheck(true)
	self:SetMoveCollide(MOVECOLLIDE_FLY_SLIDE)
	self:SetNoDraw(true)
	self:SetSolidFlags(FSOLID_NOT_STANDABLE)
end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "InkColorProxy") --For material proxy.
end
