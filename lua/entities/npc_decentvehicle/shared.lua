
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile()
AddCSLuaFile "playermeta.lua"
include "playermeta.lua"

list.Set("NPC", "npc_decentvehicle", {
	Name = "Decent Vehicle",
	Class = "npc_decentvehicle",
	Category = "GreatZenkakuMan's NPCs"
})

ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.PrintName = "Decent Vehicle"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = "Decent Vehicle."
ENT.Instructions = ""
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Seat")
	self:NetworkVar("Vector", 0, "SeatPos")
	self:NetworkVar("Angle", 0, "SeatAng")
end
