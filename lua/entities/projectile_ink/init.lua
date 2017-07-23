--[[
	The main projectile entity of Splatoon SWEPS!!!
	
]]
AddCSLuaFile "shared.lua"
include "shared.lua"

function ENT:Initialize()
	if not util.IsValidModel(self.FlyingModel) then
		self:Remove()
		return
	end
	
	self:SharedInit()
	self:SetInkColorProxy(self.InkColor or vector_origin)
end

function ENT:PhysicsCollide(coldata, collider)
	self.HitPos, self.HitNormal = coldata.HitPos, coldata.HitNormal
	self:SetAngles(self.HitNormal:Angle())
	timer.Simple(0, function()
		if not IsValid(self) then return end
		self:SetMoveType(MOVETYPE_NONE)
		self:PhysicsInit(SOLID_NONE)
		self:SetNoDraw(true)
		self:DrawShadow(false)
		self:SetPos(self.HitPos)
	end)
	
	local ang = self.HitNormal:Angle()
	ang:Normalize()
	local p = ents.Create("env_sprite_oriented")
	p:SetPos(self:GetPos())
	p:SetAngles(ang)
	p:SetParent(self)
	local color = self:GetCurrentInkColor()
	color = Color(color.x, color.y, color.z)
	p:SetColor(color)
	p:SetLocalPos(vector_origin)
	p:SetLocalAngles(angle_zero)
	
	local c, b = self:GetCurrentInkColor(), 8
	p:Input("rendercolor", Format("%i %i %i 255", c.r * b, c.g * b, c.b * b ))
	ang.p = -ang.p
	p:SetKeyValue("angles", tostring(ang))
	p:SetKeyValue("rendermode", "1")
	p:SetKeyValue("model", "sprites/splatoonink.vmt")
	p:SetKeyValue("spawnflags", "1")
	p:SetKeyValue("scale", "0.25")
	
	p:Spawn()
end

function ENT:OnRemove()
	if IsValid(self.proj) then self.proj:Remove() end
end

function ENT:Think()
	if Entity(1):KeyDown(IN_ATTACK2) then
		self:Remove()
	end
end
