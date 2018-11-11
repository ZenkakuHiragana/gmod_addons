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
ENT.Modelname = "models/player/gman_high.mdl"
