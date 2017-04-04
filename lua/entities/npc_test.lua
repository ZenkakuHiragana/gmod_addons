list.Set("NPC", "npc_test", {
	Name = "Combine Test NPC",
	Class = "npc_test",
	Category = "GreatZenkakuMan's NPCs"
})
AddCSLuaFile("npc_test.lua")

ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.PrintName = "Combine Test NPC"
ENT.Author = "Himajin Jichiku"
ENT.Contact = ""
ENT.Purpose = "Spawns Test."
ENT.Instruction = ""
ENT.Spawnable = false

ENT.CUP = true

if SERVER then
	
	ENT.weaponlist = {
		"weapon_pistol",
		"weapon_stunstick",
		"weapon_smg1",
	}
	
	local models = {
		"models/Combine_Super_Soldier.mdl",
		"models/Combine_Soldier.mdl",
		"models/police_cheaple.mdl",
		"models/Police.mdl",
		"models/Combine_Soldier_PrisonGuard.mdl",
	}
	
	local CUPClassname = {
	--	"npc_combine_assassin",
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
	--	"npc_combine_shield",
		"npc_combine_sniper",
		"npc_combine_support",
		"npc_combine_synth",
		"npc_combine_synth_elite",
		"npc_combine_veteran",
	--	"npc_metro_arrest",
	}
	
	local skills = {
		WEAPON_PROFICIENCY_POOR,
		WEAPON_PROFICIENCY_AVERAGE,
		WEAPON_PROFICIENCY_GOOD,
		WEAPON_PROFICIENCY_VERY_GOOD,
		WEAPON_PROFICIENCY_PERFECT
	}
	
	function ENT:SpawnFunction( ply, tr )
		if not tr.Hit then return end
		
		local SpawnPos = tr.HitPos + tr.HitNormal * 6
		self.Spawn_angles = ply:GetAngles()
		self.Spawn_angles.pitch = 0
		self.Spawn_angles.roll = 0
		self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180
		
		local ent = ents.Create( "npc_test" )
		ent:SetPos( SpawnPos )
		ent:SetAngles( self.Spawn_angles )
		ent:Spawn()
		ent:Activate()
		
		return ent
	end
	
	function ENT:Initialize()
		self:SetNoDraw(true)
		self:SetModel( "models/Gibs/wood_gib01e.mdl" )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		local f = 256
		local m = models[math.random(1, #models)]
		local w = GetConVar("gmod_npcweapon"):GetString()
		local weaponnum = #self.weaponlist
		if GetConVar("random_combine_additional_weapons"):GetInt() == 0 then
		--	weaponnum = weaponnum - 2
		end
		if m == models[1] then
		--	w = "weapon_ar2"
	--	else
		end
			if w == "" or w == "none" then
				w = self.weaponlist[math.random(1, #self.weaponlist)]
			end
		
		self.CUP = GetConVar("random_combine_plus"):GetInt() ~= 0
		if self.CUP then
			self.npc = ents.Create( CUPClassname[math.random(1, #CUPClassname)] )
		else
			self.npc = ents.Create( "npc_metropolice" )
			self.npc:SetName( "npc" .. self.npc:EntIndex() )
			self.npc:SetKeyValue( "weapondrawn", "1" )
			self.npc:SetKeyValue( "additionalequipment", w )
		--	self.npc:SetKeyValue( "tacticalvariant", math.random(0, 2) )
			
			if w == self.weaponlist[1] then
		--		self.npc:SetKeyValue( "skin", 1 )
			end
		--	self.npc:SetKeyValue( "manhacks", math.random(0, 5) )
			if math.random() < 0.2 then
				f = f + 8	--Drop health vial
			end
			self.npc:SetKeyValue("spawnflags", f)
			
			if not util.QuickTrace(self:GetPos(), Vector(0, 0, -50), {self, self.npc}).Hit then
				self:SetPos( self:GetPos() - Vector(0, 0, 46))
				self.npc:SetKeyValue( "waitingtorappel", 1 )
				self.Rappel = true
				self.npc.inpcIgnore = true --iNPC Compatible
			else
			--	self.npc:SetKeyValue("spawnflags", f)
			--	self.npc:Fire("StartPatrolling")
			end
		end
		
		self.npc:SetPos( self:GetPos() )
		self.npc:SetAngles( self:GetAngles() )
	--	PrintTable(self.npc:GetKeyValues())
		self.npc:Spawn()
		self.npc:Activate()
		if IsValid(self.npc.npc) then
			self.parent = self.npc
			self.npc = self.npc.npc
		end
		self.npc:SetNoDraw(true)
		
		local md = ents.Create("prop_physics")
		md:SetModel(m)
	--	md:Spawn()
		md:SetPos(self.npc:GetPos())
		md:SetAngles(self.npc:GetAngles())
		md:SetParent(self.npc)
		md:AddEffects(EF_BONEMERGE)
	--	self.npc:CapabilitiesAdd(CAP_MOVE_JUMP)
		self.npc:SetCurrentWeaponProficiency(skills[math.random(1, #skills)])
		
		local e = EffectData()
		e:SetAngles(self.npc:GetAngles())
		e:SetEntity(md)
		e:SetFlags(0)
		e:SetNormal(self.npc:GetUp())
		e:SetOrigin(self.npc:GetPos())
		e:SetRadius(0.1)
		e:SetScale(10)
		e:SetStart(self.npc:GetPos())
		util.Effect("propspawn", e)
		
	--	timer.Create("rappel" .. self:EntIndex(), 2, 0, function()
	--		self:SetRappelling()
	--	end)
		self:SetPos( Vector(0, 0, 0) )
		
		if math.random() < GetConVar("random_combine_shield"):GetFloat() then
		--	PrintTable(self.npc:GetAttachments())
			self.shield = ents.Create("cup_shield")
			self.shield:SetPos( self.npc:GetPos() + self.npc:GetForward() * 30 + self.npc:GetUp() * 20)-- + self.npc:GetRight() * 30 )
			self.shield:SetParent(self.npc, 0)
			self.shield:SetAngles( self.npc:GetAngles() + Angle(10,160,-5) )
			self.shield:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			self.shield:SetOwner( self.npc )
			self.shield:Spawn()
			self.shield:Activate()
		end
	end
	
	function ENT:OnRemove()
		if IsValid(self.npc) then
			self.npc:Remove()
		end
		
		if IsValid(self.parent) then
			self.parent:Remove()
		end
		
		if IsValid(self.seq) then
			self.seq:Remove()
		end
		
		if IsValid(self.shield) then
			self.shield:Remove()
		end
		
		timer.Destroy("rappel" .. self:EntIndex())
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
		if not IsValid(self.npc) or self.npc:Health() <= 0 then
			self:Remove()
			return
		end
		
		self:NextThink(CurTime() + 0.4)
		
		if self.Rappel then
			if IsValid(self.npc:GetEnemy()) then
				self:BeginRappel()
				return
			end
			
			for k, v in pairs(ents.FindByClass("npc_metropolice")) do
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
			
			for k, v in pairs(ents.FindInSphere(self.npc:GetPos(), 10000)) do
				if IsValid(v) then
					if (v:IsNPC() and self.npc:Disposition(v) == D_HT and (v ~= self.npc)) or
						(v:IsPlayer() and not GetConVar("ai_ignoreplayers"):GetBool()) then
						
						local t = util.TraceLine({
							start = self.npc:GetPos() + Vector(0, 0, 30),
							endpos = v:GetPos() + Vector(0, 0, 1),
							filter = {self, self.npc}
						})
						if t.Entity == v or (t.HitPos - v:GetPos()):LengthSqr() < 200 then
							self:BeginRappel()
							break
						end
					end
				end
			end
		elseif self.Rappel == false then
			if self.npc:OnGround() then
				self.npc:EmitSound("npc/combine_soldier/zipline_hitground" .. math.random(1, 2) .. ".wav")
				self.Rappel = nil
				self.npc.inpcIgnore = false --iNPC Compatible
			end
		end
	end
end
