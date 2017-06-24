
AddCSLuaFile()

ENT.classname = "nextbot_tracer_hostile"

ENT.Base = "nextbot_tracer"
ENT.Type = "nextbot"

ENT.PrintName = "Nextbot Tracer(Hostile)"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true

if SERVER then
	ENT.NPCClass = CLASS_COMBINE
	ENT.Relationship = {
		[CLASS_NONE] = D_NU,
		[CLASS_PLAYER] = D_HT,
		[CLASS_PLAYER_ALLY] = D_HT,
		[CLASS_PLAYER_ALLY_VITAL] = D_HT,
		[CLASS_ANTLION] = D_HT,
		[CLASS_BARNACLE] = D_HT,
		[CLASS_BULLSEYE] = D_NU,
		[CLASS_CITIZEN_PASSIVE] = D_HT,
		[CLASS_CITIZEN_REBEL] = D_HT,
		[CLASS_COMBINE] = D_LI,
		[CLASS_COMBINE_GUNSHIP] = D_NU,
		[CLASS_CONSCRIPT] = D_NU,
		[CLASS_HEADCRAB] = D_HT,
		[CLASS_MANHACK] = D_NU,
		[CLASS_METROPOLICE] = D_LI,
		[CLASS_MILITARY] = D_LI,
		[CLASS_SCANNER] = D_LI,
		[CLASS_STALKER] = D_LI,
		[CLASS_VORTIGAUNT] = D_HT,
		[CLASS_ZOMBIE] = D_HT,
		[CLASS_PROTOSNIPER] = D_LI,
		[CLASS_MISSILE] = D_FR,
		[CLASS_FLARE] = D_NU,
		[CLASS_EARTH_FAUNA] = D_NU,
		[CLASS_HACKED_ROLLERMINE] = D_HT,
		[CLASS_COMBINE_HUNTER] = D_LI,
	}
end

list.Set("NPC", ENT.classname, {
	Name = ENT.PrintName,
	Class = ENT.classname,
	Category = "GreatZenkakuMan's NPCs"
})
