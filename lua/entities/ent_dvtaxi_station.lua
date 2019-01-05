
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Taxi station"
ENT.Author = "DangerKiddy(DK)"
ENT.Category = "Decent Vehicle"
ENT.Spawnable = true
ENT.Editable = true
ENT.IsDVTaxiStation = true

local dvd = DecentVehicleDestination
function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "StationName", {
		KeyName = "stationname",
		Edit = {type = "Name", order = 4}
	})
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
	
	return
end

function ENT:Initialize()
	self:SetModel "models/decentvehicle/ent_dvtaxi_station.mdl"
	
	self:PhysicsInitShadow()
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(false)
	dvd.TaxiStations[self] = true
end

function ENT:OnRemove()
	dvd.TaxiStations[self] = nil
end

function ENT:Use(activator, caller)
	if not caller:IsPlayer() then return end
	
	net.Start "Decent Vehicle: Open a taxi menu"
	net.WriteEntity(self)
	net.Send(caller)
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end
	local pos = tr.HitPos + tr.HitNormal
	local ang = dvd.GetDir(tr.StartPos, tr.HitPos):Angle()
	local ent = ents.Create(ClassName)
	ent:SetAngles(Angle(0, ang.yaw, 0))
	ent:SetPos(pos)
	ent:Spawn()
	
	return ent
end
