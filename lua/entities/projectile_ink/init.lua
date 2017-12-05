--[[
	The main projectile entity of Splatoon SWEPS!!!
]]
AddCSLuaFile "shared.lua"
include "shared.lua"

local reference_polys = {}
local reference_vert = Vector(1)
local circle_polys = 360 / 12
for i = 1, circle_polys do
	table.insert(reference_polys, Vector(reference_vert))
	reference_vert:Rotate(Angle(0, circle_polys, 0))
end

ENT.DisableDuplicator = true
function ENT:Initialize()
	if not file.Exists(self.FlyingModel, "GAME") then
		self:Remove()
		return
	end
	
	self:SharedInit()
	self:SetInkColorProxy(self.InkColor or vector_origin)
	self.InkRadius = 50
	
	local ph = self:GetPhysicsObject()
	if not IsValid(ph) then return end
	ph:SetMaterial "watermelon" --or "flesh"
end

function ENT:PhysicsCollide(coldata, collider)
	local tr = util.QuickTrace(coldata.HitPos, coldata.HitNormal, self)
	if not tr.HitSky and tr.HitWorld then
		SplatoonSWEPsInkManager.AddQueue(
			tr.HitPos,
			tr.HitNormal,
			self.InkRadius,
			self:GetColorCode(),
			reference_polys
		)
	end
	
	SafeRemoveEntityDelayed(self, 0)
end

function ENT:Think()
	if Entity(1):KeyDown(IN_ATTACK2) then
		self:Remove()
	end
end
