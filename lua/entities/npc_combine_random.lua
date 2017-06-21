
AddCSLuaFile("npc_combine_random.lua")
local Category = "GreatZenkakuMan's NPCs"
local Addons = engine.GetAddons()
local CUPID = 488470325 --The addon ID of Combine Units +PLUS+
local SpartansID = 686233970 --The addon ID of Combine Spartans.
local SparbineID = 685698324 --The addon ID of Project Sparbine.
local HLSNPCID = 759043063 --The addon ID of Half-Life SNPCs.
local COMBINE_BETA_SNPCS_ID = 108511284 --Counter-Terrorist Machete conflicts with Combine Beta SNPCs.
local HL_RENAISSANCE_RECONSTRUCTED_ID = 534755660 --Counter-Terrorist Machete conflicts with Half Life SNPCs.
local COMBINE_RANDOM, COMBINE_SOLDIER, COMBINE_SHOTGUN, 
	COMBINE_PRISON, COMBINE_PRISON_SHOTGUN, COMBINE_ELITE, 
	COMBINE_POLICE, COMBINE_PLUS, COMBINE_SPARTANS, COMBINE_SPARBINE, 
	GRUNT, BLACK_OPS, HL_ALLIES, HL_ARCTIC, HL_CT
	= 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15

--Isn't there a useful function for checking addons?
local function HasAddon(id)
	for k, v in pairs(Addons) do
		if v.wsid - id == 0 then
			if v.mounted then
				return true
			end
		end
	end
	return false
end

--Random Combine
list.Set("NPC", "npc_combine_random", {
	Name = "Combine Random",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_RANDOM},
	Category = Category
})

--random_combine_additional_weapons doesn't work for specified rappel combines.
--Rappel Combine
list.Set("NPC", "rappel_combine", {
	Name = "Rappel Combine",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_SOLDIER, SquadName = "overwatch"},
	Weapons = {"weapon_smg1", "weapon_ar2"},
	Category = Category
})

--Rappel Shotgunner
list.Set("NPC", "rappel_shotgunner", {
	Name = "Rappel Shotgunner",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_SHOTGUN, SquadName = "overwatch"},
	Skin = 1,
	Weapons = {"weapon_shotgun"},
	Category = Category
})

--Rappel Prison
list.Set("NPC", "rappel_prison", {
	Name = "Rappel Prison",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_PRISON, SquadName = "novaprospekt"},
	Weapons = {"weapon_smg1", "weapon_ar2"},
	Category = Category
})

--Rappel Prison Shotgunner
list.Set("NPC", "rappel_prison_shotgunner", {
	Name = "Rappel Prison Shotgunner",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_PRISON_SHOTGUN, SquadName = "novaprospekt"},
	Skin = 1,
	Weapons = {"weapon_shotgun"},
	Category = Category
})

--Rappel Elite
list.Set("NPC", "rappel_elite", {
	Name = "Rappel Elite",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_ELITE, SquadName = "overwatch"},
	Weapons = {"weapon_ar2"},
	Category = Category
})

--Rappel Police
list.Set("NPC", "rappel_police", {
	Name = "Rappel Police",
	Class = "npc_combine_random",
	KeyValues = {friction = COMBINE_POLICE, SquadName = "overwatch"},
	Weapons = {"weapon_stunstick", "weapon_pistol", "weapon_smg1"},
	Category = Category
})

--Random +PLUS+
if HasAddon(CUPID) then
	list.Set("NPC", "rappel_plus", {
		Name = "Random +PLUS+",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_PLUS},
		Category = Category
	})
end

--Random Spartans
if HasAddon(SpartansID) then
	list.Set("NPC", "rappel_spartans", {
		Name = "Random Spartans",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_SPARTANS},
		Category = Category
	})
end

--Random Sparbine
if HasAddon(SparbineID) then
	list.Set("NPC", "rappel_sparbine", {
		Name = "Random Sparbine",
		Class = "npc_combine_random",
		KeyValues = {friction = COMBINE_SPARBINE},
		Category = Category
	})
end

--Random Grunts from Half-Life SNPCs
if HasAddon(HLSNPCID) then
	--Random Grunt
	list.Set("NPC", "monster_human_grunt_random", {
		Name = "Random Grunt",
		Class = "npc_combine_random",
		KeyValues = {friction = GRUNT},
		Category = Category
	})
	--Random Black Ops
	list.Set("NPC", "monster_blackops_random", {
		Name = "Random Black Ops",
		Class = "npc_combine_random",
		KeyValues = {friction = BLACK_OPS},
		Category = Category
	})
	--Random Ally Grunt
	list.Set("NPC", "monster_ally_random", {
		Name = "Random Ally Grunt",
		Class = "npc_combine_random",
		KeyValues = {friction = HL_ALLIES},
		Category = Category
	})
	--Random Arctic Soldier
	list.Set("NPC", "monster_arctic_random", {
		Name = "Random Arctic Soldier",
		Class = "npc_combine_random",
		KeyValues = {friction = HL_ARCTIC},
		Category = Category
	})
	--Random Counter-Terrorist
	list.Set("NPC", "monster_ct_random", {
		Name = "Random Counter-Terrorist",
		Class = "npc_combine_random",
		KeyValues = {friction = HL_CT},
		Category = Category
	})
end

--Check if Counter-Terrorist Machete can spawn.
local CanSpawnCounterMachete = not (HasAddon(HL_RENAISSANCE_RECONSTRUCTED_ID) or HasAddon(COMBINE_BETA_SNPCS_ID))

ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.PrintName = "Combine Random"
ENT.Author = "Himajin Jichiku"
ENT.Contact = ""
ENT.Purpose = "Spawns Combine Soldier Randomly."
ENT.Instructions = ""
ENT.Spawnable = false

if SERVER then
	--Console Variables
	CreateConVar("random_combine_start_patrolling", 1, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE,
	"Random Combine: Set 1 to start patrolling automatically.")
	CreateConVar("random_combine_plus", 0, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE, 
	"Random Combine: Spawns All of Combines including who can not rappel down.")
	CreateConVar("random_combine_shield", 0, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE, 
	"Random Combine: *NEED Combine Units +PLUS+*  Percentage of combines that have shield(0-1)." .. 
	"  0 is never, 0.5 is half, 1 is 100%.")
	CreateConVar("random_combine_rappel", 1, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE, 
	"Random Combine: Whether combines can rappel down or not.")
	CreateConVar("random_combine_additional_weapons", 0, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE, 
	"Random Combine: 1 to allow to use Annabelle and Crossbow.")
	
	--Weapon skills are also randomly selected.
	local skills = {
		WEAPON_PROFICIENCY_POOR,
		WEAPON_PROFICIENCY_AVERAGE,
		WEAPON_PROFICIENCY_GOOD,
		WEAPON_PROFICIENCY_VERY_GOOD,
		WEAPON_PROFICIENCY_PERFECT
	}
	
	--Rappel animations are for certain heights.
	local rappelheight = {
		384, 456, 480, 480, 552, 648
	}
	--6 Rappel animations for Combine Soldiers.
	local rappelindex = {
		"e", "c", "b", "f", "d", "a"
	}
	
	--Start a wall-rappelling animation.
	function ENT:SetRappelling(rope)
		if GetConVar("random_combine_rappel"):GetInt() == 0 then return end
		if GetConVar("ai_disabled"):GetInt() ~= 0 then return end
		if IsValid(self.seq) then return end
		if not IsValid(self.npc) then return end
		if self.npc:LookupSequence("rappel_" .. rappelindex[1]) == -1 then
			timer.Remove("rappel" .. self:EntIndex())
			return
		end
		
		--Perform some traces and check if it should be a good time to rappel.
		local filter = {self, self.npc}
		local lookahead, lookdown, lookup = 40, 680, 60
		
		if util.QuickTrace(
			self.npc:GetPos() + Vector(0, 0, lookup),
			self.npc:GetForward() * lookahead, filter).Hit then
			return
		end
		
		local t = util.QuickTrace(self.npc:GetPos() + self.npc:GetForward() * lookahead + Vector(0, 0, lookup),
			-Vector(0, 0, lookdown + lookup), filter)
		local i = 6
		
		if t.Hit then
			for x = 1, 6 do
				local d = self.npc:GetPos().z - t.HitPos.z - rappelheight[x]
				if d < 0 then
					if x > 1 then
						i = rappelheight[x - 1]
					else
						if d + rappelheight[1] < 192 then
							i = 0
						else
							i = 1
						end
						break
					end
					
					if t.HitPos.z + rappelheight[x] - self.npc:GetPos().z
						< self.npc:GetPos().z - t.HitPos.z - i then
						i = x
					else
						i = x - 1
					end
					break
				end
			end
		end
		
		if rope or not t.StartSolid and i > 0 then
			local tr = util.QuickTrace(
				t.StartPos - Vector(0, 0, lookup + 20),
				-self.npc:GetForward() * lookahead, filter)
			
			if rope or tr.HitNormal:Dot(self.npc:GetForward()) > 0.7 then
				local pos = tr.HitPos - self.npc:GetForward() * 32 + Vector(0, 0, 20)
				local ang = tr.HitNormal:Angle()
				local moveto = "5"
				if rope then
					if i == 0 then i = 1 end
					pos = self.pos
					moveto = "5"
					ang = self.angle
					local a = self.npc:GetAngles()
					a.yaw = a.yaw + 90
					self.npc:SetAngles(a)
				else
					self.pos = pos
					self.angle = ang
					self:SetPos(tr.HitPos + tr.HitNormal)
					timer.Simple(0.8, function()
						if IsValid(self) and IsValid(self.npc) then
							self.played = true
							self.z = self.npc:GetPos().z - 1
							self.const, self.rope = constraint.Rope(
								self, self.npc,
								0, 0,
								Vector(0, 0, 10), Vector(-26, 0, 48),-- self.npc:GetLocalPos(),
								rappelheight[i] / 3, 10,
								0, 2, "cable/cable_metalwinch01", false)
							if IsValid(self.rope) then
								self.rope:Activate()
							end
						--	self.npc:SetSequence(self.npc:LookupSequence(rappelindex[i]))
						end
					end)
				end
				self.npc:Fire("StopPatrolling")
				self.seq = ents.Create("scripted_sequence")
				self.seq:SetPos(pos)
				
				self.seq:SetAngles(ang)
				self.seq:SetKeyValue("m_iszPlay", "rappel_" .. rappelindex[i])
				self.seq:SetKeyValue("m_iszEntity", self.npc:GetName())
				self.seq:SetKeyValue("spawnflags", 16 + 32 + 64 + 128)
				self.seq:SetKeyValue("m_fMoveTo", moveto)
				self.seq:SetKeyValue("m_flRepeat", "1")
				
				self.seq:Spawn()
				self.seq:Fire("beginsequence")
			--	self.npc:SetSequence("Run_turretCarry_ALL")
			--	PrintTable(self.npc:GetSequenceList())
				
				if IsValid(self.parent) then
					self.parent:NextThink(CurTime() + 5)
				end
				
			--	self.inpcIgnore = true --iNPC Compatible
				self.npc.inpcIgnore = true --iNPC Compatible
			end
		end
	end
	
	function ENT:Initialize()
		self:SetNoDraw(true)
		self:SetModel( "models/Gibs/wood_gib01e.mdl" )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self.kind = self:GetKeyValues()["friction"]
		
		local f = 256		
		local switch = {
			--Rappel Police
			[COMBINE_POLICE] = function(self)
				local weaponlist = {
					"weapon_stunstick",
					"weapon_pistol",
					"weapon_smg1",
				}
				local w = GetConVar("gmod_npcweapon"):GetString()
				self.npc = ents.Create("npc_metropolice")
				if w == "" or w == "none" then
					w = weaponlist[math.random(1, #weaponlist)]
				end
				
				self.npc:SetKeyValue("additionalequipment", w)
			end,
			
			--Combine Random
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
				local modelnum = GetConVar("random_combine_plus"):GetInt() == 0 and #models - 1 or #models
				local weaponnum = GetConVar("random_combine_additional_weapons"):GetInt() == 0 and
					#weaponlist - 2 or #weaponlist
				local m = models[math.random(1, modelnum)]
				local w = GetConVar("gmod_npcweapon"):GetString()
				
				if specify then
					m = models[specify]
				end
				
				if m == models[1] then
					w = "weapon_ar2"
				else
					if w == "" or w == "none" then
						if specify then
							if specify % 2 == 1 then --Shotgunner
								w = weaponlist[1]
							else
								w = weaponlist[math.random(2, weaponnum)]
							end
						else
							if m == models[#models] then --police
								weaponlist = {
									"weapon_stunstick",
									"weapon_pistol",
									"weapon_smg1",
								}
								w = weaponlist[math.random(1, #weaponlist)]
							else
								w = weaponlist[math.random(1, weaponnum)]
							end
						end
					end
				end
				
				if m == models[#models] then --police
					self.npc = ents.Create("npc_metropolice")
					self.npc:SetKeyValue("additionalequipment", w)
				else
					self.npc = ents.Create( "npc_combine_s" )
					self.npc:SetKeyValue("model", m)
					self.npc:SetKeyValue("additionalequipment", w)
					self.npc:SetKeyValue("tacticalvariant", math.random(0, 2))
					
					if w == weaponlist[1] then
						self.npc:SetKeyValue("skin", 1)
					end
					self.npc:SetKeyValue("NumGrenades", math.random(3, 20))
				end
				
				if GetConVar("random_combine_start_patrolling"):GetBool() then
					self.npc:Fire("StartPatrolling")
				end
			end,
			
			--Random +PLUS+
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
				local n = #CUPClassname
				if GetConVar("random_combine_plus"):GetInt() == 0 then
					n = n - 3
				end
				self.npc = ents.Create(CUPClassname[math.random(1, n)])
			end,
			
			--Random Spartans
			[COMBINE_SPARTANS] = function(self)
				local models = {
					"models/frosty/sparbines/sc_police.mdl",
					"models/frosty/sparbines/sc_prisonguard.mdl",
					"models/frosty/sparbines/sc_soldier.mdl",
					"models/frosty/sparbines/sc_supersoldier.mdl",
				}
				local index = math.random(1, #models)
				local w = GetConVar("gmod_npcweapon"):GetString()
				
				if index == 1 then
					self.npc = ents.Create("npc_metropolice")
					if w == "" or w == "none" then
						w = "weapon_pistol"
					end
					
					timer.Simple(0.05, function()
						if IsValid(self) and IsValid(self.npc) then
							self.npc:SetModel(models[1])
						end
					end)
				else
					self.npc = ents.Create( "npc_combine_s" )
					self.npc:SetKeyValue("tacticalvariant", math.random(0, 2))
					self.npc:SetKeyValue("NumGrenades", math.random(3, 20))
					if w == "" or w == "none" then
						w = "weapon_ar2"
					end
				end
				
				self.npc:SetMaxHealth(200)
				self.npc:SetHealth(200)
				self.npc:SetKeyValue("citizentype", "4")
				self.npc:SetKeyValue("model", models[index])
				self.npc:SetKeyValue("additionalequipment", w)
				if GetConVar("random_combine_start_patrolling"):GetBool() then
					self.npc:Fire("StartPatrolling")
				end
			end,
			
			--Random Sparbine
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
				local index = math.random(1, #models)
				local w = GetConVar("gmod_npcweapon"):GetString()
				
				if index == 1 then -- Mark III
					self.npc = ents.Create("npc_metropolice")
					if w == "" or w == "none" then
						w = mk3[math.random(1, #mk3)]
					end
					timer.Simple(0.05, function()
						if IsValid(self) and IsValid(self.npc) then
							self.npc:SetModel(models[1])
						end
					end)
					self.npc:SetKeyValue("weapondrawn", 0)
				else
					self.npc = ents.Create( "npc_combine_s" )
					self.npc:SetKeyValue("tacticalvariant", math.random(0, 2))
					self.npc:SetKeyValue("NumGrenades", grenades[index])
					if w == "" or w == "none" then
						if index == 3 then --Mark I B
							w = "weapon_shotgun"
							self.npc:SetKeyValue("skin", 1)
						elseif index == 4 or index == 5 then -- Mark II
							w = mk2[math.random(1, #mk2)]
							if index == 5 then -- Mark II B
								self.npc:SetKeyValue("skin", 1)
							end
						else -- Mark I A and Mark S
							w = mk1[math.random(1, #mk1)]
						end
					end
					self.npc:SetKeyValue("model", models[index])
				end
				self.npc:SetKeyValue("squadname", "overwatch")
				self.npc:SetKeyValue("additionalequipment", w)
				if GetConVar("random_combine_start_patrolling"):GetBool() then
					self.npc:Fire("StartPatrolling")
				end
			end,
			
			--Random Grunt
			[GRUNT] = function(self)
				local Classname = {
					"monster_bs_grunt",
					"monster_bs_gruntcigar",
					"monster_bs_shotgun",
					"monster_heavy_assault",
					"monster_human_hlgruntsnip",
					"monster_human_hlcigar",
					"monster_human_hlcigar2",
					"monster_human_hlgrunt_deagle",
					"monster_human_hlgrunt",
					"monster_human_hlshotgun",
					"monster_hungergrunt",
					"monster_hungergruntshotgun",
					
					"monster_evil_barnabus",
					"monster_evil_otto",
					"monster_robo_grunt",
					"monster_robo_shotgun_grunt",
					"monster_sven_hgrunt",
					"monster_human_svengrunt",
					"monster_sven_hgrunt_m4",
					"monster_sven_hgrunt_shotgun",
				}
				local n = GetConVar("random_combine_plus"):GetInt() == 0 and #Classname - 8 or #Classname
				self.npc = ents.Create(Classname[math.random(1, n)])
			end,
			
			--Random Black Ops
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
				}
				self.npc = ents.Create(Classname[math.random(1, #Classname)])
			end,
			
			--Random Ally Grunt
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
					
					"monster_hlbarney",
					"monster_hlbarniel",
					"monster_hfbarney",
					"monster_m4_barney",
					"monster_mallcop_otis",
					"monster_security_otis",
					"monster_shotgun_barney",
					"monster_robo_ally",
					"monster_robo_shotgun_ally",
				}
				local n = GetConVar("random_combine_plus"):GetInt() == 0 and #Classname - 9 or #Classname
				self.npc = ents.Create(Classname[math.random(1, n)])
			end,
			
			--Random Arctic Soldier
			[HL_ARCTIC] = function(self)
				local Classname = {
					"monster_arcticak47",
					"monster_arcticmach",
					"monster_arcticsaw",
					"monster_arcticshotg",
					"monster_arcticsni",
					"monster_arcticlo",
				}
				self.npc = ents.Create(Classname[math.random(1, #Classname)])
			end,
			
			--Random Counter-Terrorist
			[HL_CT] = function(self)
				local Classname = {
					--CT Machete sometimes can't spawn.
					"monster_ally_ct_machete",
					--These are always spawnable.
					"monster_ally_ct",
					"monster_ally_ctpistol",
					"monster_ally_ctsniper",
				}
				local begin = CanSpawnCounterMachete and 1 or 2
				self.npc = ents.Create(Classname[math.random(begin, #Classname)])
			end,
		}
		
		--Rappel Combines(Specified)
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
		
		--Spawn a NPC randomly.
		switch[self.kind](self)
		
		if math.random() < 0.2 then
			f = f + 8	--Drop health vial
		end
		
		--To be honest, I don't know how to make Grunts rappel.
		if not util.QuickTrace(self:GetPos(), Vector(0, 0, -50), {self, self.npc}).Hit then
			self:SetPos(self:GetPos() - Vector(0, 0, 80))
			self.npc:SetKeyValue("waitingtorappel", 1)
			self.Rappel = true
			self.npc.inpcIgnore = true --iNPC Compatible
		end
		self.npc:SetKeyValue("spawnflags", f)
		self.npc:SetKeyValue("wakeradius", 2000)
		self.npc:SetKeyValue("wakesquad", 1) --Wake all of the squadmates.
		
		self.npc:SetPos(self:GetPos())
		self.npc:SetAngles(self:GetAngles())
		
		self.npc:Spawn()
		self.npc:Activate()
		--Compatible for Half-Life SNPCs.
		if IsValid(self.npc:GetNWEntity("HLSNPC_NPCEntity", nil)) then
			self.parent = self.npc
			self.npc = self.npc:GetNWEntity("HLSNPC_NPCEntity", nil)
		end
		--Compatible for Combine +PLUS+
		if IsValid(self.npc.npc) then
			self.parent = self.npc
			self.npc = self.npc.npc
		end
		if self.npc.CapabilitiesAdd then
			self.npc:CapabilitiesAdd(CAP_MOVE_JUMP)
		end
		if self.npc.SetCurrentWeaponProficiency then
			self.npc:SetCurrentWeaponProficiency(skills[math.random(1, #skills)])
		end
		self.npc:SetName("npc" .. self.npc:EntIndex())
		
		--Perform a spawn effect.
		local e = EffectData()
		e:SetAngles(self.npc:GetAngles())
		e:SetEntity(self.npc)
		e:SetFlags(0)
		e:SetNormal(self.npc:GetUp())
		e:SetOrigin(self.npc:GetPos())
		e:SetRadius(0.1)
		e:SetScale(10)
		e:SetStart(self.npc:GetPos())
		util.Effect("propspawn", e)
		
		timer.Create("rappel" .. self:EntIndex(), 2, 0, function()
			self:SetRappelling()
		end)
		self:SetPos(vector_origin)
		
		--Make a shield.
		if HasAddon(CUPID) and
			math.random() < GetConVar("random_combine_shield"):GetFloat() then
		--	PrintTable(self.npc:GetAttachments())
			self.shield = ents.Create("cup_shield")
			self.shield:SetPos(self.npc:GetPos() + self.npc:GetForward() * 30 + self.npc:GetUp() * 20)
			self.shield:SetParent(self.npc, 0)
			self.shield:SetAngles(self.npc:GetAngles() + Angle(10,160,-5))
			self.shield:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			self.shield:SetOwner(self.npc)
			self.shield:Spawn()
			self.shield:Activate()
		end
	end
	
	function ENT:OnRemove()
		if IsValid(self.seq) then
			self.seq:Remove()
		end
		if IsValid(self.shield) then
			self.shield:Remove()
		end
		if IsValid(self.npc) then
			self.npc:Remove()
		end
		if IsValid(self.parent) then
			self.parent:Remove()
		end
		timer.Remove("rappel" .. self:EntIndex())
	end
	
	function ENT:BeginRappel()
		self.npc:EmitSound("npc/combine_soldier/zipline_clip" .. math.random(1, 2) .. ".wav")
		self.Rappel = false
		
		timer.Simple(0.3, function()
			if IsValid(self) and IsValid(self.npc) then
				self.npc:EmitSound("npc/combine_soldier/zipline" .. math.random(1, 2) .. ".wav")
				self.npc:Fire("BeginRappel")
			end
		end)
	end
	
	function ENT:Think()
		if not IsValid(self.npc) then self:Remove() return end
		self:NextThink(CurTime() + 0.4)
		
		if self.kind >= GRUNT then return end
		if self.npc:Health() <= 0 then self:Remove() return end
		if self.kind < COMBINE_PLUS then
			local sq = self.npc:GetKeyValues()["squadname"]
			if sq ~= "novaprospekt" or sq ~= "overwatch" then
				if self.npc:GetModel():lower() == "models/combine_soldier_prisonguard.mdl" then
					self.npc:SetKeyValue( "squadname", "novaprospekt" )
				else
					self.npc:SetKeyValue( "squadname", "overwatch" )
				end
			end
		end
		
		--Check if the NPC should begin rappelling.
		if self.Rappel then
			if IsValid(self.npc:GetEnemy()) then
				self:BeginRappel()
				return
			end
			
			--If squadmates have an enemy.
			for k, v in pairs(ents.FindByClass("npc_*")) do
				if v ~= self.npc then
				--	print(v:GetKeyValues()["squadname"], self.npc:GetKeyValues()["squadname"])
					if v:GetKeyValues()["squadname"] == self.npc:GetKeyValues()["squadname"] then
						if IsValid(v:GetEnemy()) then
							self:BeginRappel()
							return
						end
					end
				end
			end
			
			--If the NPC can see an enemy.
			for k, v in pairs(ents.FindInSphere(self.npc:GetPos(), 3000)) do
				if IsValid(v) and ((v.Type == "nextbot") or 
					(v:IsNPC() and self.npc:Disposition(v) == D_HT) or
					(v:IsPlayer() and not GetConVar("ai_ignoreplayers"):GetBool())) then
					
					local t = util.TraceLine({
						start = self.npc:WorldSpaceCenter(),
						endpos = v:WorldSpaceCenter(),
						filter = {self, self.npc},
						mask = MASK_BLOCKLOS_AND_NPCS,
					})
					if t.Entity == v or t.HitPos:DistToSqr(v:WorldSpaceCenter()) < 200 then
						self:BeginRappel()
						break
					end
				end
			end
		--The NPC is now rappelling down.
		elseif self.Rappel == false then
			--Check if the NPC is on ground.
			if self.npc:OnGround() then
				--Stop rappelling immidiately.
				self.npc:EmitSound("npc/combine_soldier/zipline_hitground" .. math.random(1, 2) .. ".wav")
				self.Rappel = nil
				self.npc.inpcIgnore = false --iNPC Compatible
			end
		--The NPC already played a rappel animation.
		elseif self.played then
			if string.find(self.npc:GetSequenceName(self.npc:GetSequence()), "Rappel_") or 
				(self.z or self:GetPos().z) <= self.npc:GetPos().z then
				local tr = util.QuickTrace(self.npc:GetPos() + Vector(0, 0, 60), 
					Vector(0, 0, -90), 
					{self, self.npc, self.seq, self.npc:GetChildren()[1]})
			--	debugoverlay.Line(tr.StartPos, tr.HitPos, 3, Color(0,255,0,255),true)
				if tr.Hit and tr.HitNormal:Dot(Vector(0, 0, 1)) > 0.7 then
					self.npc:SetPos(tr.HitPos + tr.HitNormal * 10)
					self.played = nil
					if IsValid(self.seq) then
						self.seq:Remove()
					end
					constraint.RemoveAll(self.npc)
					self.angle = nil
					self.pos = nil
					self.npc.inpcIgnore = false --iNPC Compatible
					if GetConVar("random_combine_start_patrolling"):GetBool() then
						self.npc:Fire("StartPatrolling")
					end
				end
			else--if self.pos and self.pos.z > self.npc:GetPos().z then
				if IsValid(self.seq) then
					self.seq:Remove()
				end
				if self.pos then
					if self.pos.z > self.npc:GetPos().z then
						self.pos.z = self.npc:GetPos().z
					else
						constraint.RemoveAll(self.npc)
						self.angle = nil
						self.pos = nil
						self.npc.inpcIgnore = false --iNPC Compatible
						self.played = nil
						return
					end
				else
					self.pos = self.npc:GetPos()
				end
				self:SetRappelling(true)
			end
		end
	end
end
