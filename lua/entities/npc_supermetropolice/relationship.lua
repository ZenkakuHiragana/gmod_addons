AddCSLuaFile()

if CLIENT then return end
local classnames = {npc_supermetropolice = true, npc_supermetropolice_2p = true,}
local RelationshipTable_Citizen = {
	Nextbot = D_LI,
	[CLASS_NONE] = D_NU,
	[CLASS_PLAYER] = D_LI,
	[CLASS_PLAYER_ALLY] = D_LI,
	[CLASS_PLAYER_ALLY_VITAL] = D_LI,
	[CLASS_ANTLION] = D_HT,
	[CLASS_BARNACLE] = D_HT,
	[CLASS_BULLSEYE] = D_NU,
	[CLASS_CITIZEN_PASSIVE] = D_LI,
	[CLASS_CITIZEN_REBEL] = D_LI,
	[CLASS_COMBINE] = D_HT,
	[CLASS_COMBINE_GUNSHIP] = D_FR,
	[CLASS_CONSCRIPT] = D_NU,
	[CLASS_HEADCRAB] = D_HT,
	[CLASS_MANHACK] = D_HT,
	[CLASS_METROPOLICE] = D_HT,
	[CLASS_MILITARY] = D_HT,
	[CLASS_SCANNER] = D_HT,
	[CLASS_STALKER] = D_NU,
	[CLASS_VORTIGAUNT] = D_LI,
	[CLASS_ZOMBIE] = D_HT,
	[CLASS_PROTOSNIPER] = D_FR,
	[CLASS_MISSILE] = D_FR,
	[CLASS_FLARE] = D_NU,
	[CLASS_EARTH_FAUNA] = D_NU,
	[CLASS_HACKED_ROLLERMINE] = D_LI,
	[CLASS_COMBINE_HUNTER] = D_HT,
	[CLASS_MACHINE] = D_HT,
	[CLASS_HUMAN_PASSIVE] = D_LI,
	[CLASS_HUMAN_MILITARY] = D_HT,
	[CLASS_ALIEN_MILITARY] = D_HT,
	[CLASS_ALIEN_MONSTER] = D_HT,
	[CLASS_ALIEN_PREY] = D_HT,
	[CLASS_ALIEN_PREDATOR] = D_HT,
	[CLASS_INSECT] = D_NU,
}
local RelationshipTable_Combine = {
	Nextbot = D_HT,
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
	[CLASS_MACHINE] = D_HT,
	[CLASS_HUMAN_PASSIVE] = D_HT,
	[CLASS_HUMAN_MILITARY] = D_HT,
	[CLASS_ALIEN_MILITARY] = D_HT,
	[CLASS_ALIEN_MONSTER] = D_HT,
	[CLASS_ALIEN_PREY] = D_HT,
	[CLASS_ALIEN_PREDATOR] = D_HT,
	[CLASS_INSECT] = D_NU,
}
local RelationshipTable_Hostile = {
	Nextbot = D_HT,
	[CLASS_NONE] = D_HT,
	[CLASS_PLAYER] = D_HT,
	[CLASS_PLAYER_ALLY] = D_HT,
	[CLASS_PLAYER_ALLY_VITAL] = D_HT,
	[CLASS_ANTLION] = D_HT,
	[CLASS_BARNACLE] = D_HT,
	[CLASS_BULLSEYE] = D_HT,
	[CLASS_CITIZEN_PASSIVE] = D_HT,
	[CLASS_CITIZEN_REBEL] = D_HT,
	[CLASS_COMBINE] = D_HT,
	[CLASS_COMBINE_GUNSHIP] = D_HT,
	[CLASS_CONSCRIPT] = D_HT,
	[CLASS_HEADCRAB] = D_HT,
	[CLASS_MANHACK] = D_HT,
	[CLASS_METROPOLICE] = D_HT,
	[CLASS_MILITARY] = D_HT,
	[CLASS_SCANNER] = D_HT,
	[CLASS_STALKER] = D_HT,
	[CLASS_VORTIGAUNT] = D_HT,
	[CLASS_ZOMBIE] = D_HT,
	[CLASS_PROTOSNIPER] = D_HT,
	[CLASS_MISSILE] = D_FR,
	[CLASS_FLARE] = D_NU,
	[CLASS_EARTH_FAUNA] = D_NU,
	[CLASS_HACKED_ROLLERMINE] = D_HT,
	[CLASS_COMBINE_HUNTER] = D_HT,
	[CLASS_MACHINE] = D_HT,
	[CLASS_HUMAN_PASSIVE] = D_HT,
	[CLASS_HUMAN_MILITARY] = D_HT,
	[CLASS_ALIEN_MILITARY] = D_HT,
	[CLASS_ALIEN_MONSTER] = D_HT,
	[CLASS_ALIEN_PREY] = D_HT,
	[CLASS_ALIEN_PREDATOR] = D_HT,
	[CLASS_INSECT] = D_HT,
}
local RelationshipTable = {
	[CLASS_NONE] = RelationshipTable_Citizen,
	[CLASS_PLAYER] = RelationshipTable_Citizen,
	[CLASS_PLAYER_ALLY] = RelationshipTable_Citizen,
	[CLASS_PLAYER_ALLY_VITAL] = RelationshipTable_Citizen,
	[CLASS_ANTLION] = RelationshipTable_Hostile,
	[CLASS_BARNACLE] = RelationshipTable_Hostile,
	[CLASS_BULLSEYE] = RelationshipTable_Hostile,
	[CLASS_CITIZEN_PASSIVE] = RelationshipTable_Citizen,
	[CLASS_CITIZEN_REBEL] = RelationshipTable_Citizen,
	[CLASS_COMBINE] = RelationshipTable_Combine,
	[CLASS_COMBINE_GUNSHIP] = RelationshipTable_Combine,
	[CLASS_CONSCRIPT] = RelationshipTable_Hostile,
	[CLASS_HEADCRAB] = RelationshipTable_Hostile,
	[CLASS_MANHACK] = RelationshipTable_Combine,
	[CLASS_METROPOLICE] = RelationshipTable_Combine,
	[CLASS_MILITARY] = RelationshipTable_Hostile,
	[CLASS_SCANNER] = RelationshipTable_Combine,
	[CLASS_STALKER] = RelationshipTable_Combine,
	[CLASS_VORTIGAUNT] = RelationshipTable_Citizen,
	[CLASS_ZOMBIE] = RelationshipTable_Hostile,
	[CLASS_PROTOSNIPER] = RelationshipTable_Combine,
	[CLASS_MISSILE] = RelationshipTable_Hostile,
	[CLASS_FLARE] = RelationshipTable_Hostile,
	[CLASS_EARTH_FAUNA] = RelationshipTable_Hostile,
	[CLASS_HACKED_ROLLERMINE] = RelationshipTable_Citizen,
	[CLASS_COMBINE_HUNTER] = RelationshipTable_Combine,
	[CLASS_MACHINE] = RelationshipTable_Hostile,
	[CLASS_HUMAN_PASSIVE] = RelationshipTable_Hostile,
	[CLASS_HUMAN_MILITARY] = RelationshipTable_Hostile,
	[CLASS_ALIEN_MILITARY] = RelationshipTable_Hostile,
	[CLASS_ALIEN_MONSTER] = RelationshipTable_Hostile,
	[CLASS_ALIEN_PREY] = RelationshipTable_Hostile,
	[CLASS_ALIEN_PREDATOR] = RelationshipTable_Hostile,
	[CLASS_INSECT] = RelationshipTable_Hostile,
}
hook.Add("OnEntityCreated", "GreatZenkakuMan's Nextbot relationship setting", function(e)
    if not IsValid(e) then return end
    if not e:IsNPC() then return end
	if not isfunction(e.AddEntityRelationship) then return end
	if classnames[e:GetClass()] then return end
	for c in pairs(classnames) do
		if e:GetClass() ~= c then
			for i, v in ipairs(ents.FindByClass(c)) do
				e:AddEntityRelationship(v, v:Disposition(e), 1)
			end
		end
	end
end)

ENT.NPCClass = CLASS_ALIEN_PREDATOR
ENT.Relationship = RelationshipTable
function ENT:Initialize_Relationship()
	self.RelationshipEntity = {}
	for _, v in ipairs(ents.GetAll()) do
		if v:IsNPC() and isfunction(v.AddEntityRelationship) then
			if not classnames[v:GetClass()] then
				v:AddEntityRelationship(self, self:Disposition(v), 1)
			end
		end
	end
end

function ENT:Classify()
	return self.NPCClass
end

local IgnorePlayers = GetConVar "ai_ignoreplayers"
function ENT:Disposition(e)
	local rt = self.Relationship[self.NPCClass]
    if not IsValid(e) then
        return D_ER
    elseif e:IsFlagSet(FL_NOTARGET) then
        return D_NU -- Ignore the entity.
	elseif self.RelationshipEntity[e] then
		return self.RelationshipEntity[e]
	elseif e:IsNPC() and isfunction(e.Classify) and e:Classify() then
		if self.NPCClass == e:Classify() then return D_LI end
		return rt[e:Classify()] or D_ER
    elseif e:IsPlayer() and not IgnorePlayers:GetBool() then
		return rt[CLASS_PLAYER]
    elseif e.Type == "nextbot" then
		return rt.Nextbot
	end
end

-- Priority does nothing for nextbots.
function ENT:AddEntityRelationship(entity, disposition, priority)
	if entity == self then return end
	self.RelationshipEntity[entity] = disposition
end

function ENT:AddRelationship(relationstring)
	local parse = string.Explode(" ", relationstring, false)
	for _, ent in pairs(ents.FindByClass(parse[1])) do
		self:AddEntityRelationship(ent, parse[2], parse[3])
	end
end
