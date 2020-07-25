AddCSLuaFile()
ENT.Base = "npc_supermetropolice"
ENT.ModelName = "models/player/police.mdl"
ENT.PrintName = "Super Metropolice 2P"
ENT.Skin = 0
ENT.NPCClass = CLASS_ALIEN_MONSTER
ENT.Category = "GreatZenkakuMan's NPCs"
ENT.ClassName = "npc_supermetropolice_2p"

list.Set("NPC", ENT.ClassName, {
    Category = ENT.Category,
    Class = ENT.ClassName,
    Name = ENT.PrintName,
})
