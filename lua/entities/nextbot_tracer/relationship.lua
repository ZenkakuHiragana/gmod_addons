
ENT.NPCClass = CLASS_CITIZEN_REBEL
ENT.Relationship = {
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
	[CLASS_MANHACK] = D_NU,
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
}

function ENT:InitializeRelationship()
	self.RelationshipEntity = {}
end

--nextbot_tracer allies itself with players.
function ENT.Replacement:Classify()
	return self.NPCClass
end

function ENT.Replacement:Disposition(e)
	if not IsValid(e) then return D_ER end
	local relationship = D_NU
	if self.RelationshipEntity[e] then
		relationship = self.RelationshipEntity[e]
	elseif e:IsNPC() and isfunction(e.Classify) and e:Classify() then
		relationship = self.Relationship[e:Classify()]
		if not relationship then relationship = D_ER end
	elseif e:IsPlayer() then
		relationship = self.Relationship[CLASS_PLAYER]
	elseif e.Type == "nextbot" then
		relationship = self:GetConVarBool("nextbot_tracer_hates_nextbot") and D_HT or D_NU
	end
	
	if (e:IsPlayer() and self:GetConVarBool("ai_ignoreplayers")) or
		e:IsFlagSet(FL_NOTARGET) or e:Health() <= 0 then
		relationship = D_NU --Ignore the entity.
	end
	
	return relationship
end

--Priority doesn't work for now.
function ENT.Replacement:AddEntityRelationship(entity, disposition, priority)
	if entity == self then return end
	self.RelationshipEntity[entity] = disposition
end

function ENT.Replacement:AddRelationship(relationstring)
	local parse = string.Explode(" ", relationstring, false)
	for _, ent in pairs(ents.FindByClass(parse[1])) do
		self:AddEntityRelationship(ent, parse[2], parse[3])
	end
end