
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile()
AddCSLuaFile "playermeta.lua"
include "playermeta.lua"

local dvd = DecentVehicleDestination
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = dvd.Texts.npc_decentvehicle
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = ""
ENT.Spawnable = false

list.Set("NPC", "npc_decentvehicle", {
	Name = ENT.PrintName,
	Class = "npc_decentvehicle",
	Category = "GreatZenkakuMan's NPCs",
})

function ENT:SetDriverPosition()
	local seat = self:GetNWEntity "Seat"
	if not IsValid(seat) then return end
	local pos = seat:LocalToWorld(self:GetNWVector "Pos")
	self:SetPos(pos)
	self:SetNetworkOrigin(pos)
	self:SetAngles(seat:LocalToWorldAngles(self:GetNWAngle "Ang"))
end

function ENT:GetVehicleForward()
	local vehicle = self:GetNWEntity "Vehicle"
	if not IsValid(vehicle) then return end
	if vehicle.IsScar then
		return vehicle:GetForward()
	elseif vehicle.IsSimfphyscar then
		return vehicle:LocalToWorldAngles(vehicle.VehicleData.LocalAngForward):Forward()
	else
		return vehicle:GetForward()
	end
end

function ENT:GetVehicleRight()
	local vehicle = self:GetNWEntity "Vehicle"
	if not IsValid(vehicle) then return end
	if vehicle.IsScar then
		return vehicle:GetRight()
	elseif vehicle.IsSimfphyscar then
		return vehicle:LocalToWorldAngles(vehicle.VehicleData.LocalAngForward):Right()
	else
		return vehicle:GetRight()
	end
end

function ENT:GetVehicleUp()
	local vehicle = self:GetNWEntity "Vehicle"
	if not IsValid(vehicle) then return end
	if vehicle.IsScar then
		return vehicle:GetUp()
	elseif vehicle.IsSimfphyscar then
		return vehicle:LocalToWorldAngles(vehicle.VehicleData.LocalAngForward):Up()
	else
		return vehicle:GetUp()
	end
end

ENT.GetAimVector = ENT.GetVehicleForward -- For SCAR base
