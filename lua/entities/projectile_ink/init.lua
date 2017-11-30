--[[
	The main projectile entity of Splatoon SWEPS!!!
]]
AddCSLuaFile "shared.lua"
include "shared.lua"

local circle_polys = 12
local reference_polys = {}
local reference_vert = Vector(1, 0)
local reference_vert45 = Vector(1, 0)
for i = 1, circle_polys do
	table.insert(reference_polys, Vector(reference_vert))
	reference_vert:Rotate(Angle(0, 360 / circle_polys, 0))
end

function ENT:Initialize()
	if not util.IsValidModel(self.FlyingModel) then
		self:Remove()
		return
	end
	
	self:SharedInit()
	self:SetIsInk(false)
	self:SetInkColorProxy(self.InkColor or vector_origin)
	
	local ph = self:GetPhysicsObject()
	if not IsValid(ph) then return end
	ph:SetMaterial("watermelon") --or "flesh"
	
	self.InkRadius = 50
	self.InkRadiusSqr = self.InkRadius^2
end

function ENT:PhysicsCollide(coldata, collider)
	local tr = util.QuickTrace(coldata.HitPos, coldata.HitNormal, self)
	if tr.HitSky or not tr.HitWorld then
		SafeRemoveEntityDelayed(self, 0)
		return
	end
	
	SplatoonSWEPsInkManager.AddQueue(
		tr.HitPos,
		-coldata.HitNormal,
		self.InkRadius,
		self:GetColorCode(),
		reference_polys
	)
	
	self:SetIsInk(true)
	self:SetHitPos(coldata.HitPos)
	self:SetHitNormal(coldata.HitNormal)
	self:SetAngles(coldata.HitNormal:Angle())
	self:DrawShadow(false)
	
	timer.Simple(0, function()
		if not IsValid(self) then return end
		self:SetMoveType(MOVETYPE_NONE)
		self:PhysicsInit(SOLID_NONE)
		self:SetPos(coldata.HitPos)
	end)
	
	SafeRemoveEntityDelayed(self, 1)
end

function ENT:Think()
	if Entity(1):KeyDown(IN_ATTACK2) then
		self:Remove()
	end
end
