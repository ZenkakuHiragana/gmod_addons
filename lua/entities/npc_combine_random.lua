
AddCSLuaFile()
local AIDisabled = GetConVar "ai_disabled"
local IgnorePlayers = GetConVar "ai_ignoreplayers"
local Category = "GreatZenkakuMan's NPCs"
local Addons = engine.GetAddons()
local CUPID = 488470325 -- Combine Units +PLUS+
local SpartansID = 686233970 -- Combine Spartans
local SparbineID = 685698324 -- Project Sparbine
local ArmoredID = 1357960725 -- Combine Armored PMs and NPCs
local NeonID = 485030576 -- Neon Combines
local MetropolicePackID = 104491619 -- Metropolice Pack
local HLSNPCID = 759043063 -- Half-Life SNPCs

-- These NPC lists all spawn npc_combine_random, and decide what NPCs should be spawned in ENT:Initialize()
-- This addon uses (probably) unused KeyValue "friction" to store the type of the NPC.
local COMBINE_RANDOM = 1
local COMBINE_OVERWATCH = 2
local COMBINE_PRISON_PLUS_ELITE = 3
local COMBINE_SOLDIER = 4
local COMBINE_SHOTGUN = 5
local COMBINE_PRISON = 6
local COMBINE_PRISON_SHOTGUN = 7
local COMBINE_ELITE = 8
local COMBINE_POLICE = 9
local COMBINE_PLUS = 10
local COMBINE_SPARTANS = 11
local COMBINE_SPARBINE = 12
local COMBINE_ARMORED = 13
local COMBINE_NEON = 14
local METROPOLICE_PACK = 15
local GRUNT = 16
local BARNEYS = 17
local BLACK_OPS = 18
local HL_ALLIES = 19
local HL_ARCTIC = 20
local HL_CT = 21

-- Isn't there a useful function for checking addons?
local function HasAddon(id)
	for k, v in pairs(Addons) do
		if v.wsid - id == 0 and v.mounted then
			return true
		end
	end
end

-- Random Combine
list.Set("NPC", "npc_combine_random", {
	Name = "Combine Random",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_RANDOM},
	Category = Category,
})

-- Random Overwatch (No Prison Guards)
list.Set("NPC", "npc_combine_random_overwatch", {
	Name = "Random Overwatch",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_OVERWATCH},
	Category = Category,
})

-- Random Prison Guards + Elite
list.Set("NPC", "npc_combine_prison_plus_elite", {
	Name = "Random Prison + Elite",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_PRISON_PLUS_ELITE},
	Category = Category,
})

-- random_combine_additional_weapons doesn't work for specified rappel combines.
-- Rappel Combine
list.Set("NPC", "npc_combine_rappel", {
	Name = "Rappel Combine",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_SOLDIER, SquadName = "overwatch"},
	Weapons = {"weapon_smg1", "weapon_ar2"},
	Category = Category,
})

-- Rappel Shotgunner
list.Set("NPC", "npc_combine_shotgunner_rappel", {
	Name = "Rappel Shotgunner",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_SHOTGUN, SquadName = "overwatch"},
	Skin = 1,
	Weapons = {"weapon_shotgun"},
	Category = Category,
})

-- Rappel Prison
list.Set("NPC", "npc_combine_prison_rappel", {
	Name = "Rappel Prison",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_PRISON, SquadName = "novaprospekt"},
	Weapons = {"weapon_smg1", "weapon_ar2"},
	Category = Category,
})

-- Rappel Prison Shotgunner
list.Set("NPC", "npc_combine_prison_shotgunner_rappel", {
	Name = "Rappel Prison Shotgun",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_PRISON_SHOTGUN, SquadName = "novaprospekt"},
	Skin = 1,
	Weapons = {"weapon_shotgun"},
	Category = Category,
})

-- Rappel Elite
list.Set("NPC", "npc_combine_elite_rappel", {
	Name = "Rappel Elite",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_ELITE, SquadName = "overwatch"},
	Weapons = {"weapon_ar2"},
	Category = Category,
})

-- Rappel Police
list.Set("NPC", "npc_metropolice_rappel", {
	Name = "Rappel Police",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_POLICE, SquadName = "overwatch"},
	Weapons = {"weapon_stunstick", "weapon_pistol", "weapon_smg1"},
	Category = Category,
})

-- Random +PLUS+
if HasAddon(CUPID) then
	list.Set("NPC", "npc_combine_random_plus", {
		Name = "Random +PLUS+",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_PLUS},
		Category = Category,
	})
end

-- Random Spartans
if HasAddon(SpartansID) then
	list.Set("NPC", "npc_combine_random_spartans", {
		Name = "Random Spartans",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_SPARTANS},
		Category = Category,
	})
end

-- Random Sparbine
if HasAddon(SparbineID) then
	list.Set("NPC", "npc_combine_random_sparbine", {
		Name = "Random Sparbine",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_SPARBINE},
		Category = Category,
	})
end

-- Armored Combine
if HasAddon(ArmoredID) then
	list.Set("NPC", "npc_combine_random_armored", {
		Name = "Random Armored Combine",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_ARMORED},
		Category = Category,
	})
end

-- Neon Combine
if HasAddon(NeonID) then
	list.Set("NPC", "npc_combine_random_neon", {
		Name = "Random Neon Combine",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_NEON},
		Category = Category,
	})
end

-- Metropolice Pack
if HasAddon(MetropolicePackID) then
	list.Set("NPC", "npc_metropolice_pack_random", {
		Name = "Random Police Pack",
		Class = "npc_combine_random",
		KeyValues = {friction = METROPOLICE_PACK},
		Category = Category,
	})
end

--Random Grunts from Half-Life SNPCs
if HasAddon(HLSNPCID) then
	-- Random Grunt
	list.Set("NPC", "monster_human_grunt_random", {
		Name = "Random Grunt",
		Class = "npc_combine_random",
		KeyValues = {friction = GRUNT},
		Category = Category,
	})
	-- Random Security Officer
	list.Set("NPC", "monster_barney_random", {
		Name = "Random Officer",
		Class = "npc_combine_random",
		KeyValues = {friction = BARNEYS},
		Category = Category,
	})
	-- Random Black Ops
	list.Set("NPC", "monster_blackops_random", {
		Name = "Random Black Ops",
		Class = "npc_combine_random",
		KeyValues = {friction = BLACK_OPS},
		Category = Category,
	})
	-- Random Ally Grunt
	list.Set("NPC", "monster_ally_random", {
		Name = "Random Ally Grunt",
		Class = "npc_combine_random",
		KeyValues = {friction = HL_ALLIES},
		Category = Category,
	})
	-- Random Arctic Soldier
	list.Set("NPC", "monster_arctic_random", {
		Name = "Random Arctic Soldier",
		Class = "npc_combine_random",
		KeyValues = {friction = HL_ARCTIC},
		Category = Category,
	})
	-- Random Counter-Terrorist
	list.Set("NPC", "monster_ct_random", {
		Name = "Random Counter-Terrorist",
		Class = "npc_combine_random",
		KeyValues = {friction = HL_CT},
		Category = Category,
	})
end


ENT.Base = "base_entity"
ENT.Type = "anim" -- Actually, this isn't an NPC.
ENT.PrintName = "Combine Random"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = "Spawns Combine Soldier Randomly."
ENT.Instructions = ""
ENT.Spawnable = false
ENT.NextEnemyCheck = CurTime()
ENT.NextCheckRappelling = CurTime()

if CLIENT then return end
local CVarFlags = bit.bor(FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE)
local CVarShouldPatrol = CreateConVar("random_combine_start_patrolling", 1, CVarFlags,
"Random Combine: Set this to 1 to start patrolling automatically.")
local CVarAdvancedCombine = CreateConVar("random_combine_plus", 0, CVarFlags, 
"Random Combine: Spawns All of Combines including who can not rappel down.")
local CVarCombineShield = CreateConVar("random_combine_shield", 0, CVarFlags, 
"Random Combine: *NEED Combine Units +PLUS+*  Percentage of combines that have shield(0-1).  0 is none, 0.5 is half, 1 is all of them.")
local CVarShouldRappel = CreateConVar("random_combine_rappel", 1, CVarFlags, 
"Random Combine: Whether combines can rappel down or not.")
local CVarAdditionalWeapons = CreateConVar("random_combine_additional_weapons", 0, CVarFlags, 
"Random Combine: 1 to allow to use Annabelle and Crossbow.")
local CVarSearchLedgeDistance = CreateConVar("random_combine_search_ledge_radius", 80, CVarFlags, 
"Random Combine: Radius of searching ledge for rappelling in units.  Larger values might cause some problems.")
local CVarDropHealthVial = CreateConVar("random_combine_healthvial", 0.2, CVarFlags, 
"Random Combine: Percentage of combines that drop a health vial on their death.  0 is none, 0.5 is half, 1 is all of them.")
local CVarManhacks = CreateConVar("random_combine_manhacks", 0, CVarFlags, 
"Random Combine: Amount of Manhacks that Rappel Polices have. Set this to -1 to have randomly.")
local CVarGrenades = CreateConVar("random_combine_grenades", -20, CVarFlags, 
"Random Combine: Amount of grenades that Random Combines have. Less than 0 means a random value up to -X.")

local RopeTexture = "cable/cable_metalwinch01.vmt" -- Rope texture for rappelling
local ZipSound = "npc/combine_soldier/zipline%s.wav"
if not IsMounted "ep2" then
	RopeTexture = "cable/cable2.vmt"
end

-- Weapon skills are also randomly selected.
local skills = {
	WEAPON_PROFICIENCY_POOR,
	WEAPON_PROFICIENCY_AVERAGE,
	WEAPON_PROFICIENCY_GOOD,
	WEAPON_PROFICIENCY_VERY_GOOD,
	WEAPON_PROFICIENCY_PERFECT
}

-- Combine Soldiers have 6 rappel animations.
-- Desired heights of rappel animations.
local rappelheight = {384, 456, 480, 480, 552, 648}
local rappelledge = {4, 4, 1, 24, 4, 32}
local rappelsequences = {
	"rappel_e",
	"rappel_c",
	"rappel_b",
	"rappel_f",
	"rappel_d",
	"rappel_a",
}

-- Makes a rope and gets ready for landing.
local function BeginRappelWall(self, i)
	if not IsValid(self) then return end
	if not IsValid(self.npc) then return end
	if not IsValid(self.seq) then return end
	if self.npc:OnGround() then
		-- It's on the ground, not started rappelling yet.  Check it later.
		timer.Simple(0.3, function() BeginRappelWall(self, i) end)
	else -- If the NPC already played rappel animation, it should be in the air.
		self.RappelWallSequencePlayed = true
		if IsValid(self.rope) then return end
		self.rope = constraint.CreateKeyframeRope(self.RappelWallRopePos, 2, RopeTexture, nil, game.GetWorld(), self.RappelWallRopePos, 0, self.npc, self.npc:WorldSpaceCenter() - self.npc:GetPos(), 0)
		self.rope:SetKeyValue("Slack", 50)
		self:DeleteOnRemove(self.rope)
	end
end

local function setmanhack(self)
	local manhack = CVarManhacks:GetInt()
	if manhack < 0 then
		manhack = math.Round(math.random())
	end

	self.npc:SetKeyValue("manhacks", manhack)
end

local function setgrenades(self)
	local max = CVarGrenades:GetInt()
	local min = math.max(max, 0)
	self.npc:SetKeyValue("NumGrenades", math.random(min, math.abs(max)))
end

local function SpawnGeneral(self, weapon, classname)
	local npcdata = list.Get "NPC"
	local spawndata = npcdata[classname]
	local w = weapon
	self.npc = ents.Create(spawndata.Class)

	if w == "" or w == "none" then -- Setting default weapon
		w = spawndata.Weapons[math.random(#spawndata.Weapons)]
	end
	
	if spawndata.Health then
		self.npc:SetHealth(spawndata.Health)
		self.npc:SetMaxHealth(spawndata.Health)
		self:SetHealth(spawndata.Health)
		self:SetMaxHealth(spawndata.Health)
	end

	if spawndata.Model then
		self.npc:SetModel(spawndata.Model)
		self.SetModelAfterSpawn = spawndata.Model
	end
	
	self.npc:SetKeyValue("additionalequipment", w)
	self.npc:SetKeyValue("tacticalvariant", math.random(0, 2))
	if spawndata.KeyValues then
		for key, value in pairs(spawndata.KeyValues) do
			self.npc:SetKeyValue(key, value)
		end
	end
	
	if not CVarShouldPatrol:GetBool() then return end
	self.npc:Fire "StartPatrolling"
end

function ENT:Initialize()
	self:SetNoDraw(true)
	self:SetModel "models/Gibs/wood_gib01e.mdl"
	self:SetNotSolid(true)
	self.npctype = self:GetKeyValues().friction
	
	local weapon
	if game.IsDedicated() then
		local printname = list.Get"NPC"[self:GetClass()].Name
		for id, block in pairs(undo.GetTable()) do
			for _, data in ipairs(block) do
				if not IsValid(data.Entities[1]) and data.CustomUndoText
				and data.CustomUndoText:find(printname) then
					weapon = data.Owner:GetInfo "gmod_npcweapon"
				end
			end
		end
		
		if not weapon and IsValid(player.GetByID(1)) then
			weapon = player.GetByID(1):GetInfo "gmod_npcweapon"
		end
	else
		weapon = GetConVar "gmod_npcweapon"
		weapon = weapon and weapon:GetString() or ""
	end
	
	local f = 256 -- Spawnflags.
	local switch = { -- Actual spawn functions.
		-- Combine Random
		[COMBINE_RANDOM] = function(self, specify)
			local weaponlist = {
				"weapon_shotgun",
				"weapon_ar2",
				"weapon_smg1",
				"weapon_crossbow",
				"weapon_annabelle"
			}
			
			local models = {
				"models/Combine_Super_Soldier.mdl",
				"",
				"",
				"models/Combine_Soldier_PrisonGuard.mdl",
				"models/Combine_Soldier_PrisonGuard.mdl",
				"models/Police.mdl"
			}
			local modelnum = CVarAdvancedCombine:GetBool() and #models or #models - 1
			local weaponnum = CVarAdditionalWeapons:GetBool() and #weaponlist or #weaponlist - 2
			local mi = specify or math.random(modelnum)
			local ispolice = mi == #models
			local m = models[mi]
			local w = weapon
			
			if w == "" or w == "none" then -- Setting default weapon
				if m == models[1] then
					w = "weapon_ar2"
				elseif ispolice then -- police
					weaponlist = {
						"weapon_stunstick",
						"weapon_pistol",
						"weapon_smg1",
					}
					w = weaponlist[math.random(#weaponlist)]
				elseif specify then
					if specify % 2 > 0 then -- Shotgunner
						w = weaponlist[1]
					else
						w = weaponlist[math.random(2, weaponnum)]
					end
				else
					w = weaponlist[math.random(weaponnum)]
				end
			end
			
			if ispolice then --police
				self.npc = ents.Create "npc_metropolice"
				self.npc:SetKeyValue("additionalequipment", w)
				setmanhack(self)
			else
				self.npc = ents.Create "npc_combine_s"
				self.npc:SetKeyValue("model", m)
				self.npc:SetKeyValue("additionalequipment", w)
				self.npc:SetKeyValue("tacticalvariant", math.random(0, 2))
				
				if w == weaponlist[1] then
					self.npc:SetKeyValue("skin", 1)
				end
				setgrenades(self)
			end
			
			if not CVarShouldPatrol:GetBool() then return end
			self.npc:Fire "StartPatrolling"
		end,
		
		-- Random +PLUS+
		[COMBINE_PLUS] = function(self)
			local CUPClassname = {
				"npc_combine_burner",
				"npc_combine_commander",
				"npc_combine_elite",
				"npc_combine_engineer",
				"npc_combine_grenadier",
				"npc_combine_hg",
				"npc_combine_medic",
				"npc_combine_overwatch",
				"npc_combine_overwatch_s",
				"npc_combine_prisonguard",
				"npc_combine_prisonguard_s",
				"npc_combine_sniper",
				"npc_combine_support",
				"npc_combine_synth",
				"npc_combine_synth_elite",
				"npc_combine_veteran",
				"npc_combine_assassin",
				"npc_combine_shield",
				"npc_metro_arrest",
			}
			local n = CVarAdvancedCombine:GetBool() and #CUPClassname or #CUPClassname - 3
			self.npc = ents.Create(CUPClassname[math.random(n)])
		end,
		
		-- Random Spartans
		[COMBINE_SPARTANS] = function(self)
			local models = {
				"models/frosty/sparbines/sc_police.mdl",
				"models/frosty/sparbines/sc_prisonguard.mdl",
				"models/frosty/sparbines/sc_soldier.mdl",
				"models/frosty/sparbines/sc_supersoldier.mdl",
			}
			local index = math.random(#models)
			local w = weapon
			
			if index == 1 then
				self.npc = ents.Create "npc_metropolice"
				if w == "" or w == "none" then
					w = "weapon_pistol"
				end
				
				timer.Simple(0.05, function()
					if IsValid(self) and IsValid(self.npc) then
						self.npc:SetModel(models[1])
					end
				end)
			else
				self.npc = ents.Create "npc_combine_s"
				self.npc:SetKeyValue("tacticalvariant", math.random(0, 2))
				setgrenades(self)
				if w == "" or w == "none" then
					w = "weapon_ar2"
				end
			end
			
			self.npc:SetMaxHealth(200)
			self.npc:SetHealth(200)
			self.npc:SetKeyValue("citizentype", "4")
			self.npc:SetKeyValue("model", models[index])
			self.npc:SetKeyValue("additionalequipment", w)
			if not CVarShouldPatrol:GetBool() then return end
			self.npc:Fire "StartPatrolling"
		end,
		
		-- Random Sparbine
		[COMBINE_SPARBINE] = function(self)
			local models = {
				"models/frosty/sparbines/sc_police.mdl",
				"models/frosty/sparbines/sc_soldier.mdl",
				"models/frosty/sparbines/sc_soldier.mdl",
				"models/frosty/sparbines/sc_prisonguard.mdl",
				"models/frosty/sparbines/sc_prisonguard.mdl",
				"models/frosty/sparbines/sc_supersoldier.mdl",
			}
			local mk1 = {
				"weapon_smg1",
				"weapon_ar2",
			}
			local mk2 = {
				"weapon_ar2",
				"weapon_crossbow",
			}
			local mk3 = {
				"weapon_stunstick",
				"weapon_pistol",
				"weapon_smg1",
			}
			local grenades = {0, 5, 5, 3, 3, 10}
			local index = math.random(#models)
			local w = weapon
			
			if index == 1 then -- Mark III
				self.npc = ents.Create "npc_metropolice"
				if w == "" or w == "none" then
					w = mk3[math.random(#mk3)]
				end
				timer.Simple(0.05, function()
					if IsValid(self) and IsValid(self.npc) then
						self.npc:SetModel(models[1])
					end
				end)
				self.npc:SetKeyValue("weapondrawn", 0)
			else
				self.npc = ents.Create "npc_combine_s"
				self.npc:SetKeyValue("tacticalvariant", math.random(0, 2))
				self.npc:SetKeyValue("NumGrenades", grenades[index])
				if w == "" or w == "none" then
					if index == 3 then --Mark I B
						w = "weapon_shotgun"
						self.npc:SetKeyValue("skin", 1)
					elseif index == 4 or index == 5 then -- Mark II
						w = mk2[math.random(#mk2)]
						if index == 5 then -- Mark II B
							self.npc:SetKeyValue("skin", 1)
						end
					else -- Mark I A and Mark S
						w = mk1[math.random(#mk1)]
					end
				end
				self.npc:SetKeyValue("model", models[index])
			end
			self.npc:SetKeyValue("squadname", "overwatch")
			self.npc:SetKeyValue("additionalequipment", w)
			if not CVarShouldPatrol:GetBool() then return end
			self.npc:Fire "StartPatrolling"
		end,

		[COMBINE_ARMORED] = function(self)
			local Classname = {
				"npc_combine_advisor_guard",
				"npc_combine_advisor_guard_armored",
				"npc_combine_advisor_guard_soldier",
				"npc_combine_advisor_guard_soldier_armored",
				"npc_combine_elite_guard",
				"npc_combine_elite_guard_armored",
				"npc_combine_elite_soldier",
				"npc_combine_elite_soldier_armored",
				"npc_combine_guard_armored",
				"npc_combine_heavy",
				"npc_combine_hunter",
				"npc_combine_hunter_armored",
				"npc_combine_hunter_soldier",
				"npc_combine_hunter_soldier_armored",
				"npc_combine_shotgunner_armored",
				"npc_combine_soldier_armored",
				"npc_combine_super_elite_soldier",
				"npc_combine_super_elite_soldier_armored",
				"npc_combine_super_shotgunner",
				"npc_combine_super_shotgunner_armored",
				"npc_combine_super_soldier_armored",

				"npc_police_armored",
				"npc_police_elite",
				"npc_police_elite_armored",
			}
			local n = CVarAdvancedCombine:GetBool() and #Classname or #Classname - 3
			SpawnGeneral(self, weapon, Classname[math.random(n)])
		end,

		[COMBINE_NEON] = function(self)
			local Classname = {
				"neon-combine_soldier",
				"neon-elite_combine",
				"neon-combine_soldier_prison_guard",
				"neon-combine_shotgun_soldier",
				"neon-metrocop",
			}
			local n = CVarAdvancedCombine:GetBool() and #Classname or #Classname - 1
			SpawnGeneral(self, weapon, Classname[math.random(n)])
		end,

		[METROPOLICE_PACK] = function(self)
			local Classname = {
				"Arctic",
				"Badass",
				"Beta Metro Police",
				"Black Metro Police",
				"Blue eyed Metro Police",
				"Breen Troops",
				"City 08 Police",
				"Civil Medic",
				"Concept Trenchcoat",
				"Elite Shock Unit",
				"Female Metro Police",
				"Fragger Police",
				"HD Metro Police",
				"Hunter Squad",
				"Phoenix Metro Police",
				"Retro Police",
				"Rogue Police",
				"Skull Squad",
				"Spec Ops",
				"Steampunk Police",
				"TF2 BLU Police",
				"TF2 RED Police",
				"Trenchcoat Metro Police",
				"Tribal Police",
				"Tron Styled Blue",
				"Tron Styled Orange",
				"Urban Camo",
			}
			SpawnGeneral(self, weapon, Classname[math.random(#Classname)])
		end,
		
		-- Random Grunt
		[GRUNT] = function(self)
			local Classname = {
				"monster_bs_grunt",
				"monster_bs_gruntcigar",
				"monster_bs_shotgun",
				"monster_human_grunt_crossbow",
				"monster_heavy_grunt_hostile",
				"monster_human_hlgruntsnip",
				"monster_human_hlcigar",
				"monster_human_hlcigar2",
				"monster_human_hlgrunt_deagle",
				"monster_human_hlgrunt",
				"monster_human_hlshotgun",
				"monster_hungergrunt",
				"monster_hungergruntshotgun",
				"monster_mercgrunt",
				"monster_mercgruntshotgun",
				"monster_human_hlgruntsaw",
				"monster_germangrunt",
				"monster_germangruntshotgun",
				-- Added in "Continued" version
				"monster_hostile_human_grunt_grenade",
				"monster_hostile_medic",
				"monster_hostile_sniperop",
				"monster_hostile_torch",
				"monster_human_grunt_hostile",
				"monster_shotgun_grunt_hostile",
				
				"monster_heavy_assault",
				"monster_evil_barnabus",
				"monster_evil_otto",
				"monster_robo_grunt",
				"monster_robo_shotgun_grunt",
				"monster_sven_hgrunt",
				"monster_human_svengrunt",
				"monster_sven_hgrunt_m4",
				"monster_sven_hgrunt_shotgun",
			}
			local n = CVarAdvancedCombine:GetBool() and #Classname or #Classname - 9
			self.npc = ents.Create(Classname[math.random(n)])
		end,

		[BARNEYS] = function(self)
			local Classname = {
				"monster_hlbarney",
				"monster_hlbarniel",
				"monster_hfbarney",
				"monster_m4_barney",
				"monster_mallcop_otis",
				"monster_security_otis",
				"monster_shotgun_barney",
				"monster_hdbarney", -- Added in "Continues" version
			}
			self.npc = ents.Create(Classname[math.random(#Classname)])
		end,
		
		-- Random Black Ops
		[BLACK_OPS] = function(self)
			local Classname = {
				"monster_female_assassin",
				"monster_male_assassin_hd",
				"monster_male_assassin",
				"monster_male_assassin_deagle",
				"monster_male_assassin_katana",
				"monster_male_assassin_rapidfire",
				"monster_male_assassin_shotgun",
				"monster_sniper_male_assassin",
				"monster_male_assassin_grenade",
				"monster_male_assassin_hdgrenade",

				"monster_svenmassn_assault",
				"monster_svenmassn",
				"monster_svenmassn_sniper",
			}
			local n = CVarAdvancedCombine:GetBool() and #Classname or #Classname - 3
			self.npc = ents.Create(Classname[math.random(n)])
		end,
		
		-- Random Ally Grunt
		[HL_ALLIES] = function(self)
			local Classname = {
				"monster_adrian",
				"monster_ally_torch",
				"monster_grunt_ally_hd",
				"monster_ally_torchhd",
				"monster_ally_sniperop",
				"monster_ally_sniperophd",
				"monster_heavy_assault_ally",
				"monster_heavy_grunt_ally",
				"monster_heavy_grunt_ally_hd",
				"monster_human_grunt_ally",
				"monster_ally_human_grunt_grenade",
				"monster_grunt_ally_hdgrenade",
				"monster_ally_medic",
				"monster_ally_medichd",
				"monster_shotgun_grunt_ally",
				"monster_shotgun_grunt_ally_hd",
				"monster_ally_grunt_sniper",

				"monster_robo_ally",
				"monster_robo_shotgun_ally",
			}
			local n = CVarAdvancedCombine and #Classname or #Classname - 2
			self.npc = ents.Create(Classname[math.random(n)])
		end,
		
		-- Random Arctic Soldier
		[HL_ARCTIC] = function(self)
			local Classname = {
				"monster_arcticak47",
				"monster_arcticmach",
				"monster_arcticsaw",
				"monster_arcticshotg",
				"monster_arcticsni",
				"monster_arcticlo",
			}
			self.npc = ents.Create(Classname[math.random(#Classname)])
		end,
		
		-- Random Counter-Terrorist
		[HL_CT] = function(self)
			local Classname = {
				"monster_ally_ct_machete",
				"monster_ally_ct",
				"monster_ally_ctpistol",
				"monster_ally_ctsniper",
			}
			self.npc = ents.Create(Classname[math.random(#Classname)])
		end,
	}
	
	-- Rappel Combines(Specified)
	switch[COMBINE_OVERWATCH] = function(self)
		switch[COMBINE_RANDOM](self, math.random(3))
	end
	switch[COMBINE_PRISON_PLUS_ELITE] = function(self)
		switch[COMBINE_RANDOM](self, ({1, 4, 5})[math.random(3)])
	end
	switch[COMBINE_ELITE] = function(self)
		switch[COMBINE_RANDOM](self, 1)
	end
	switch[COMBINE_SOLDIER] = function(self)
		switch[COMBINE_RANDOM](self, 2)
	end
	switch[COMBINE_SHOTGUN] = function(self)
		switch[COMBINE_RANDOM](self, 3)
	end
	switch[COMBINE_PRISON] = function(self)
		switch[COMBINE_RANDOM](self, 4)
	end
	switch[COMBINE_PRISON_SHOTGUN] = function(self)
		switch[COMBINE_RANDOM](self, 5)
	end
	switch[COMBINE_POLICE] = function(self)
		switch[COMBINE_RANDOM](self, 6)
	end
	
	-- Spawn a NPC randomly.
	switch[self.npctype](self)
	
	if math.random() < CVarDropHealthVial:GetFloat() then
		f = f + 8 -- Drop health vial
	end

	self.npc:SetKeyValue("spawnflags", f)
	self.npc:SetKeyValue("wakeradius", 2000)
	self.npc:SetKeyValue("wakesquad", 1) -- Wake all of the squadmates.
	self.npc:SetPos(self:GetPos())
	self.npc:SetAngles(self:GetAngles())
	self.npc:Spawn()
	self.npc:Activate()
	
	if IsValid(self.npc:GetNWEntity "HLSNPC_NPCEntity") then
		self.parent = self.npc -- Compatible for Half-Life SNPCs.
		self.npc = self.npc:GetNWEntity "HLSNPC_NPCEntity"
		self.npc:DeleteOnRemove(self)
		self:DeleteOnRemove(self.parent)
		self:DeleteOnRemove(self.npc)
	elseif IsValid(self.npc.npc) then -- Compatible for Combine Units +PLUS+
		self.parent = self.npc
		self.npc = self.npc.npc
		self.npc:DeleteOnRemove(self)
		self:DeleteOnRemove(self.parent)
		self:DeleteOnRemove(self.npc)
	else
		self.npc:DeleteOnRemove(self)
		self:DeleteOnRemove(self.npc)
	end
	
	-- To be honest, I don't know how to make Grunts rappel.
	if not util.QuickTrace(self:GetPos(), -vector_up * 50, self.npc).Hit then
		if self.npctype >= GRUNT or self.npc:SelectWeightedSequence(ACT_RAPPEL_LOOP) > 0 then
			self:SetPos(self:GetPos() - vector_up * 45)
			self.npc:SetKeyValue("waitingtorappel", 1)
			self.npc:AddFlags(FL_FLY)
			self.IsWaitingToRappel = true
			self.npc.inpcIgnore = true -- iNPC Compatible
			if self.npc.npc then
				self.npc.RappelTypeSet = 2 -- For Combine Units +PLUS+
			end
		end
	end

	self.NextCheckRappelling = CurTime() + 1
	self.npc.RandomCombineNPC = self
	self.npc:SetName("npc" .. self.npc:EntIndex())
	self:SetSquadName()

	if self.SetModelAfterSpawn then
		self.npc:SetModel(self.SetModelAfterSpawn)
	end

	if self:Health() <= 0 then
		self:SetHealth(self.npc:Health())
		self:SetMaxHealth(self.npc:GetMaxHealth())
	end

	timer.Simple(0, function() -- This is for Entity Group Spawner. it changes my angle after spawning.
		if not IsValid(self) then return end
		if not IsValid(self.npc) then return end
		self.npc:SetAngles(self:GetAngles())

		-- And this is for NPC Spawn Platforms v2.  it has a health multiplier.
		if self:Health() > 0 then
			self.npc:SetHealth(self:Health())
			self.npc:SetMaxHealth(self:GetMaxHealth())
		end

		-- Fix around undo
		for _, u in pairs(undo.GetTable()) do
			for _, t in pairs(u) do
				if t.Entities and t.Entities[1] == self then
					self.undolist = t.Entities
				end
			end
		end

		-- Grunt rappelling setup
		if not self.IsWaitingToRappel then return end
		local seq = self.npc:LookupSequence "repel_repel"
		if seq < 0 then return end
		self.IsGruntWaitingToRappel = true
		self.npc:AddFlags(FL_FLY)
		self.npc:NextThink(math.huge)
		self.npc:SetSequence(seq)
	end)

	if isfunction(self.npc.CapabilitiesAdd) then self.npc:CapabilitiesAdd(CAP_MOVE_JUMP) end
	if isfunction(self.npc.SetCurrentWeaponProficiency) then
		self.npc:SetCurrentWeaponProficiency(skills[math.random(#skills)])
	end
	
	-- Perform a spawn effect.
	local e = EffectData()
	e:SetEntity(self.npc)
	util.Effect("propspawn", e)
	
	-- Make a shield.
	if not HasAddon(CUPID) then return end
	if math.random() > CVarCombineShield:GetFloat() then return end
	self.shield = ents.Create "cup_shield"
	self.shield:SetPos(self.npc:GetPos() + self.npc:GetForward() * 30 + self.npc:GetUp() * 20)
	self.shield:SetParent(self.npc, 0)
	self.shield:SetAngles(self.npc:GetAngles() + Angle(10,160,-5))
	self.shield:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self.shield:SetOwner(self.npc)
	self.shield:Spawn()
	self.shield:Activate()
	self:DeleteOnRemove(self.shield)
end

-- Start a wall-rappelling animation.
function ENT:CheckRappelling(isRappellingAgain)
	if not CVarShouldRappel:GetBool() then return end
	if AIDisabled:GetBool() then return end
	if not IsValid(self.npc) then return end
	
	-- Perform some traces and check if it should be a good time to rappel.
	local filter = self.npc:GetChildren()
	table.insert(filter, self.npc)
	local lookahead = CVarSearchLedgeDistance:GetInt()
	local lookdown, lookup = 680, 60
	local vahead = self.npc:GetForward() * lookahead
	local vdown = vector_up * lookdown
	local vup = vector_up * lookup
	local npcpos = self.npc:GetPos()
	local npcforward = self.npc:GetForward()
	local t = util.QuickTrace(npcpos + vahead + vup, -(vup + vdown), filter)
	local i = 6

	if util.QuickTrace(npcpos + vup, vahead, filter).Hit then
		return
	elseif t.Hit then
		for x = 1, 6 do -- Determines a suitable animation.
			local h = rappelheight[x]
			local d = npcpos.z - t.HitPos.z - h
			if d < 0 then
				if x == 1 then
					if d + rappelheight[1] < 192 then
						i = 0
					else
						i = 1
					end
				elseif t.HitPos.z - npcpos.z + rappelheight[x - 1] < d then
					i = x
				else
					i = x - 1
				end
				
				break
			end
		end
	end
	
	if isRappellingAgain or not t.StartSolid and i > 0 then
		local dz = vector_up * 20
		local tr = util.QuickTrace(t.StartPos - vup - dz, -vahead, filter)
		local rappelseq = rappelsequences[i] or rappelsequences[1]
		local rappeldist = rappelledge[i] or rappelledge[1]
		if isRappellingAgain or tr.HitNormal:Dot(npcforward) > 0.7 then
			local pos = tr.HitPos - npcforward * rappeldist + dz
			local ang = tr.HitNormal:Angle()
			local moveto = 2 -- Move to position.
			if self.npc:LookupSequence(rappelseq) < 0 then
				self.LerpSequence = self.npc:LookupSequence "repel_jump"
				if self.LerpSequence < 0 then -- For Combine Female Assassin
					self.LerpSequence = self.npc:LookupSequence "JumpStart"
				end
				if self.LerpSequence < 0 then -- For Condition Zero NPC
					self.LerpSequence = self.npc:LookupSequence "jump_down"
				end
				if self.LerpSequence < 0 then -- For Metropolice
					self.LerpSequence = self.npc:LookupSequence "jump_holding_glide"
				end
				if self.LerpSequence < 0 then -- For Black Ops Assassin
					self.LerpSequence = self.npc:LookupSequence "fly_up"
				end
				
				if self.LerpSequence < 0 then return end
				if self.parent then self.parent:NextThink(math.huge) end
				self.ForcedRappel = true
				self:SetPos(tr.HitPos + dz + tr.HitNormal * 32)
				self:SetAngles(ang)
				self.npc:StopMoving()
				self.npc:SetLastPosition(tr.HitPos + dz)
				self.npc:SetSchedule(SCHED_FORCED_GO_RUN)
				return
			end

			if isRappellingAgain then
				if i == 0 then i = 1 end
				pos = self.RappelStartPos
				ang = self.RappelStartAng
				moveto = 0 -- Do immediately.
				self.npc:SetAngles(ang)
			else
				self.RappelStartPos = pos
				self.RappelStartAng = ang
				self.RappelWallRopePos = tr.HitPos
				timer.Simple(0.8, function() BeginRappelWall(self, i) end)
			end
			
			self.seq = IsValid(self.seq) and self.seq or ents.Create "scripted_sequence"
			self.seq:SetPos(pos)
			self.seq:SetAngles(ang)
			self.seq:SetKeyValue("m_fMoveTo", moveto)
			self.seq:SetKeyValue("m_flRepeat", 1)
			self.seq:SetKeyValue("m_iszEntity", self.npc:GetName())
			self.seq:SetKeyValue("m_iszEntry", "rappel_a_preIdle")
			self.seq:SetKeyValue("m_iszPlay", rappelseq)
			self.seq:SetKeyValue("spawnflags", 16 + 32 + 64 + 128)
			if not isRappellingAgain then self.seq:Spawn() end
			self.seq:Fire "beginsequence"

			self.npc:Fire "StopPatrolling"
			self.npc:SetVelocity(-self.npc:GetVelocity()) -- Reset velocity to 0
			self.npc.inpcIgnore = true -- iNPC Compatible
			
			self:DeleteOnRemove(self.seq)
			self.RappelWallStartTime = CurTime()
			self.RappelWallSequenceDuration = select(2, self.npc:LookupSequence(rappelsequences[i]))
			if IsValid(self.parent) then
				self.parent:NextThink(CurTime() + 5)
			end
		end
	end
end

-- Begins to rappel(straight down).
function ENT:BeginRappel()
	self.npc:EmitSound(ZipSound:format("_clip" .. math.random(2)))
	self.IsWaitingToRappel = nil
	self.IsRappellingDown = true
	
	timer.Simple(0.3, function()
		if not IsValid(self) then return end
		if not IsValid(self.npc) then return end
		self.npc:EmitSound(ZipSound:format(math.random(2)))
		self.npc:Fire "BeginRappel"
	end)

	if not self.IsGruntWaitingToRappel then return end
	self.IsGruntWaitingToRappel = nil
	self.IsGruntRappellingDown = true

	if self.npctype < GRUNT then return end
	self.rope = constraint.CreateKeyframeRope(self:GetPos(), 2, RopeTexture, NULL, game.GetWorld(), self:GetPos(), 0, self.npc, vector_up * 70, 0)
	self.rope:SetKeyValue("Slack", 50)
	self:DeleteOnRemove(self.rope)
end

function ENT:SetSquadName()
	if self.npctype >= COMBINE_PLUS then return end
	if self.npctype == COMBINE_PRISON_PLUS_ELITE then
		self.npc:SetKeyValue("squadname", "novaprospekt")
		return
	end

	local sq = self.npc:GetKeyValues().squadname
	if sq == "novaprospekt" or sq == "overwatch" then return end
	if self.npc:GetModel():lower() == "models/combine_soldier_prisonguard.mdl" then
		self.npc:SetKeyValue("squadname", "novaprospekt")
	else
		self.npc:SetKeyValue("squadname", "overwatch")
	end
end

function ENT:Think()
	if not IsValid(self.npc) then self:Remove() return end
	if self.npc:Health() <= 0 then self:Remove() return end
	if CurTime() > self.NextCheckRappelling then
		self.NextCheckRappelling = CurTime() + 2
		self:CheckRappelling()
	end

	if self.ForcedRappel and not self.npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then
		if util.TraceHull {
			start = self:GetPos(),
			endpos = self:GetPos(),
			mins = self.npc:OBBMins(),
			maxs = self.npc:OBBMaxs(),
			filter = self.npc,
		}.Hit then return end

		self.ForcedRappel = nil
		self.DoingLerpMovement = true
		self.LerpStart = CurTime()
		self.LerpStartPos = self.npc:GetPos()
		self.LerpStartAng = self.npc:GetAngles()
		self.npc:AddFlags(FL_FLY)
		self.npc:RemoveFlags(FL_ONGROUND)
		self.npc:SetSequence(self.LerpSequence)
		self.npc:NextThink(math.huge)

		timer.Simple(0.2, function()
			if not IsValid(self) then return end
			if not IsValid(self.npc) then return end
			self.DoingLerpMovement = nil
			self.npc:SetPos(self:GetPos())
			self.npc:AddFlags(FL_FLY)
			self.npc:RemoveFlags(FL_ONGROUND)
			self.npc:SetVelocity(-self.npc:GetVelocity())
			self.npc:ClearSchedule()
			
			if self.npctype >= GRUNT or self.npc:SelectWeightedSequence(ACT_RAPPEL_LOOP) < 0 then
				local seq = self.npc:LookupSequence "repel_repel"
				if seq < 0 then seq = self.npc:LookupSequence "fly_down" end -- For Black Ops Assassin
				if seq < 0 then seq = self.npc:LookupSequence "JumpLoop" end -- For Combine Female Assassin

				if seq < 0 then return end
				self.IsGruntWaitingToRappel = true
				self.npc:RemoveFlags(FL_ONGROUND)
				self.npc:SetSequence(seq)
			else
				self.npc:SetKeyValue("waitingtorappel", 1)
				self.npc:NextThink(CurTime())
			end
			
			self:BeginRappel()
		end)
	end
	
	if self.DoingLerpMovement then
		local f = math.Clamp((CurTime() - self.LerpStart) / 0.2, 0, 1)
		self.npc:SetPos(LerpVector(f, self.LerpStartPos, self:GetPos()))
		self.npc:SetAngles(LerpAngle(f, self.LerpStartAng, self:GetAngles()))
		self.npc:AddFlags(FL_FLY)
		self.npc:RemoveFlags(FL_ONGROUND)
		self.npc:FrameAdvance(FrameTime())
		self:NextThink(CurTime())
		return true
	end
	
	-- Check if the NPC should begin rappelling.
	if self.IsWaitingToRappel then
		if IsValid(self.npc:GetEnemy()) then
			self:BeginRappel()
			return
		end
		
		if CurTime() < self.NextEnemyCheck then return end
		self.NextEnemyCheck = CurTime() + 0.5

		-- If squadmates have an enemy.
		for k, v in pairs(ents.FindByClass "npc_*") do
			if v ~= self.npc then
				if v:GetKeyValues().squadname == self.npc:GetKeyValues().squadname then
					if IsValid(v:GetEnemy()) then
						self:BeginRappel()
						return
					end
				end
			end
		end
		
		-- If the NPC can see an enemy.
		for k, v in pairs(ents.FindInSphere(self.npc:GetPos(), 3000)) do
			if IsValid(v) and self.npc:Visible(v) and self.npc:Disposition(v) == D_HT and not (v:IsPlayer() and IgnorePlayers:GetBool()) then
				self:BeginRappel()
				return
			end
		end
	end

	if self.IsGruntRappellingDown then -- Alternative rappelling down script
		if self.IsRappellingDown then
			local speed = 600
			local t = util.QuickTrace(self.npc:GetPos(), -vector_up * 240, self.npc)
			local v = -vector_up * math.max(60, speed * t.Fraction)
			self.npc:SetVelocity(v - self.npc:GetVelocity()) -- Actually adds velocity

			if IsValid(self.rope) then
				self.rope:SetKeyValue("Slack", self:GetPos().z - self.npc:GetPos().z + 50)
			end

			if self.npc:OnGround() then
				local seq, duration = self.npc:LookupSequence "repel_land"
				if seq < 0 then seq, duration = self.npc:LookupSequence "JumpLand" end -- For Combine Female Assassin
				if seq >= 0 then self.npc:SetSequence(seq) end
				duration = duration or 0
				self.npc:RemoveFlags(FL_FLY)
				self.npc:NextThink(CurTime() + duration)
				self.IsRappellingDown = nil
				timer.Simple(duration, function()
					if not IsValid(self) then return end
					self.IsGruntRappellingDown = nil
					if not IsValid(self.rope) then return end
					self.rope:Fire "Break"
					SafeRemoveEntityDelayed(self.rope, 3)
				end)
			end
		end

		self.npc:FrameAdvance(FrameTime())
		self:NextThink(CurTime())
		return true
	end

	-- The NPC is now rappelling down.
	if self.IsRappellingDown then
		-- Check if the NPC is on ground. and stop rappelling immidiately.
		if not self.npc:OnGround() then return end
		if self.parent then self.parent:NextThink(CurTime()) end
		self.npc:EmitSound(ZipSound:format("_hitground" .. math.random(2)))
		self.IsRappellingDown = nil
		self.npc.inpcIgnore = false -- iNPC Compatible
	-- The NPC already played a rappel animation.
	elseif self.RappelWallSequencePlayed and self.RappelWallRopePos.z > self.npc:GetPos().z then
		if CurTime() < self.RappelWallStartTime + self.RappelWallSequenceDuration then
			self.rope:SetKeyValue("Slack", (self:GetPos().z - self.npc:GetPos().z) + 50)

			local tr = util.TraceLine {
				start = self.npc:WorldSpaceCenter(),
				endpos = self.npc:GetPos() - vector_up * 10,
				filter = self.npc,
			}
			if not tr.Hit or tr.HitNormal:Dot(vector_up) < 0.7 then return end
			self.npc:SetPos(tr.HitPos + tr.HitNormal * 10)
			self.npc.inpcIgnore = false -- iNPC Compatible
			self.RappelWallSequencePlayed = nil
			self.RappelStartPos = nil
			self.RappelStartAng = nil
			self.rope:Fire "Break"
			SafeRemoveEntityDelayed(self.rope, 3)

			if IsValid(self.seq) then self.seq:Fire "CancelSequence" end
			if not CVarShouldPatrol:GetBool() then return end
			self.npc:Fire "StartPatrolling"
		else -- Sequence end and restart rappelling
			if IsValid(self.seq) then self.seq:Fire "CancelSequence" end
			self:CheckRappelling(true)
			-- self.npc:SetAngles(self.RappelStartAng)
			-- self.rope:Fire "Break"
			-- self.npc:SetKeyValue("waitingtorappel", 1)
			-- self.npc:AddFlags(FL_FLY)
			-- self.npc:SetVelocity(-self.npc:GetVelocity())
			-- self.npc:ClearSchedule()
			-- self.npc:Fire "BeginRappel"
			-- self.RappelWallSequencePlayed = nil
			-- self.RappelStartPos = nil
			-- self.RappelStartAng = nil
		end
	end
end

hook.Add("OnNPCKilled", "Random Combine: Undo ragdoll", function(ent, attacker, inflictor)
	if not IsValid(ent.RandomCombineNPC) then return end
	local pos = ent:GetPos()
	local undolist = ent.RandomCombineNPC.undolist
	timer.Simple(0, function()
		for _, e in ipairs(ents.FindInSphere(pos, 64)) do
			if e:IsRagdoll() and e:GetOwner() == ent then
				table.insert(undolist, e)
				break
			end
		end
	end)
end)
