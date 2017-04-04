--[[
	This is the balloon for target practice in Splatoon.
]]

ENT.Base = "npc_splat_balloon"
 
ENT.PrintName		= "Balloon(Big)"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Target Practice"
ENT.Instructions	= "none"
ENT.Spawnable = true

ENT.height = 100

if SERVER then
	AddCSLuaFile("shared.lua")

elseif CLIENT then
	ENT.AutomaticFrameAdvance = true
end

function ENT:Initialize()
	self:SetModel("models/props_interiors/VendingMachineSoda01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetHealth(500)
	self:DrawShadow(false)
	if SERVER then
		self:SetMaxHealth(500)
		self:SetPos(self:GetPos() + Vector(0, 0, self:OBBMaxs().z))
		self:DropToFloor()
		constraint.Weld(self, game.GetWorld(), 0, 0, 0, false, false)
	end
	
	if CLIENT then self.balloon = 
		ClientsideModel("models/props_splatoon/props/general/training_targets/training_target_large.mdl")
		self.delta = Vector(0, 0, self:OBBMins().z + 10.5)
	end
end
