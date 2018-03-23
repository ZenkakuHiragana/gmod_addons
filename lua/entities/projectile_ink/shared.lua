--[[
	The main projectile entity of Splatoon SWEPS!!!
]]

ENT.Type = "anim"
ENT.FlyingModel = Model "models/blooryevan/ink/inkprojectile.mdl"
ENT.IsSplatoonProjectile = true
function ENT:SharedInit(mdl)
	self:SetModel(mdl or self.FlyingModel)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self:SetCustomCollisionCheck(true)
	self:SetMoveCollide(MOVECOLLIDE_FLY_SLIDE)
	self:SetNoDraw(true)
end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "InkColorProxy") --For material proxy.
end
