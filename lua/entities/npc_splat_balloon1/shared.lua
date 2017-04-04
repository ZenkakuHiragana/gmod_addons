--[[
	This is the balloon for target practice in Splatoon.
]]

ENT.Base = "npc_splat_balloon"
 
ENT.PrintName		= "Balloon(Def. 1)"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Target Practice"
ENT.Instructions	= "none"
ENT.Spawnable = true
ENT.d = 10

ENT.defmul = 1
ENT.mul = 1

if SERVER then
	AddCSLuaFile("shared.lua")

elseif CLIENT then
	ENT.AutomaticFrameAdvance = true
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.defmul = ((0.99 * self.d) - (0.09 * 0.09 * self.d * self.d)) / 100
	self.mul = 1 - (self.defmul / 1.8)
	if CLIENT then
		self.balloon:SetBodygroup(1, self.d / 10)
	end
end

function ENT:OnTakeDamage(d)
	d:SetDamage(d:GetDamage() * self.mul)
	self.BaseClass.OnTakeDamage(self, d)
end
