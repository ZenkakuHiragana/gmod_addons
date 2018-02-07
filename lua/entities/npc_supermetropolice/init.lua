
function ENT:GetEnemy()
	if self:Validate(self.Enemy) ~= 0 then return nil end
	return self.Enemy
end

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

for k, v in pairs(ENT.Sentence) do
	PrecacheSentenceGroup(v.name)
end

hook.Add("OnEntityCreated", "SuperMetropoliceIsAlone!", function(e)
	if IsValid(e) and e:GetClass() ~= "npc_supermetropolice" then
		local t = "SuperMetropolice_target" .. e:EntIndex()
		if isfunction(e.AddEntityRelationship) then
			timer.Create(t, 0.5, 0, function()
				if not IsValid(e) then timer.Remove(t) return end
				for v in pairs(SQUAD_MATES) do
					if IsValid(v) then
						e:AddEntityRelationship(v, D_HT, 0)
					end
				end
			end)
		end
		
	--	if isfunction(e.AddRelationship) then
	--		timer.Create(t .. "relationstring", 0.5, 0, function()
	--			if not IsValid(e) then timer.Remove(t .. "relationstring") return end
	--			e:AddRelationship("npc_supermetropolice D_HT 99")
	--		end)
	--	end
	end
end)

hook.Add("EntityEmitSound", "SuperMetropoliceNoticesFires", function(t)
	if not IsValid(t.Entity) then return end
	for v in pairs(SQUAD_MATES) do
		if IsValid(v) then
			if t.Entity == v then return end
			if v:IsHearingSound(t) then
				local f = v:Validate(t.Entity) == 0
				if f or v:XorRand() < 0.05 then
					v:Speak(v.Sentence.Heard, v:CanSpeak())
				end
				if f then v:SetEnemy(t.Entity) end
			end
		end
	end
end)

util.AddNetworkString("SuperMetropoliceHearSound")
net.Receive("SuperMetropoliceHearSound", function(len, ply)
	local bot = net.ReadEntity()
	local target = net.ReadEntity()
	if IsValid(bot) and IsValid(target) and 
		bot:GetClass() == "npc_supermetropolice" and 
		not IsValid(bot:GetEnemy()) and 
		bot:Validate(target) == 0 then
		
		bot:SetEnemy(target)
	end
end)

--Whether I can speak or not.  also returns if there're allies.
function ENT:CanSpeak(forced)
	local alone, can, time = true, true
	for v in pairs(SQUAD_MATES) do
		if IsValid(v) then
			if v:Health() > 0 and v ~= self then
				alone = false
				time = v.Time.SpokeOthers
			else
				time = v.Time.Spoke
			end
			if time > CurTime() then can = false end
			if not (alone or can) then break end
		end
	end
	return alone, can or forced
end

--Say something.  If squad is true, I won't when I'm alone.
function ENT:Speak(sentence, alone, can)
	if not (can and sentence) then return end
	if (sentence.squad and alone and self:XorRand() < (sentence.probability or 0.9)) or 
	(not (sentence.squad or alone) and self:XorRand() > (sentence.probability or 0.7)) then return end
	
	EmitSentence(sentence.name .. 
		math.random(0, sentence.patterns or 1), self:GetPos(), self:EntIndex(), 
		CHAN_AUTO, 1, sentence.vol or 100)
	local _next = self.SentenceLength[math.random(1, #self.SentenceLength)]
	if sentence.squad then _next = _next * 0.8 end
	
	self.Time.Spoke = CurTime() + _next
	self.Time.SpokeOthers = CurTime() + _next / 2
--	if sentence ~= self.Sentence.Pain then PrintMessage(HUD_PRINTTALK, sentence.name) end
	return true
end

--Classify for speaking.
function ENT:SpeakClassify(ent, kill)
	local sentence
	local c = ent:GetClass()
	if ent:IsPlayer() then --Player
		if kill then return self.Sentence.KillPlayer
		elseif ent:IsVehicle() then --In vehicle
			sentence = self.Sentence.AlertPlayerVehicle
		else --Out of vehicle
			sentence = self.Sentence.AlertPlayer
		end
	else --string search algorithm from: http://d.hatena.ne.jp/ux00ff/20110612/1307886259
		local TreeNode = {}
		TreeNode.new = function(chr)
			return {
				child = {}, value = chr,
				addWord = function(sel, value, id)
					if not sel or sel.bend then return end
					sel.bend = not value or #value <= 1
					if sel.bend then sel.index = id return end
					local chr = value[1]
					if not sel.child[chr] then sel.child[chr] = TreeNode:new(chr) end
					sel.child[chr]:addWord(string.sub(value, 2), id)
				end,
				
				addWords = function(sel, words)
					for k, v in pairs(words) do sel:addWord(v, k) end
				end,
			}
		end
		
		local currentNode, match
		local rootNode = TreeNode.new()
		rootNode:addWords({"antlion", "citizen", "zombi", "crab", "monster"})
		for i = 0, #c do
			currentNode = rootNode
			for k = 0, #c - i do
				currentNode = currentNode.child[c[i + k]]
				
				if not currentNode then break end
				if currentNode.bend then match = currentNode.index end
			end
		end
		
		if match then
			local KillList, AlertList = {
				self.Sentence.KillBugs,
				self.Sentence.KillCitizen,
				self.Sentence.KillZombies,
				self.Sentence.KillParasites,
				self.Sentence.KillMonste,
			}, {
				self.Sentence.AlertBugs,
				self.Sentence.AlertCitizen,
				self.Sentence.AlertZombies,
				self.Sentence.AlertParasites,
				self.Sentence.AlertMonster,
			}
			sentence = kill and KillList[match] or AlertList[match]
		else
			sentence = kill and self.Sentence.KillCharacter or self.Sentence.AlertCharacter
		end
	end
	return sentence
end

function ENT:InitializeTimers()
	self.Time = {
		Saw = CurTime(),		--saw the enemy
		Threw = CurTime(),		--threw grenade
		Moved = CurTime(),		--started moving
		Fired = CurTime(),		--fired weapon
		Stuck = CurTime(),		--lua-defined stack flag
		Damage = CurTime(),		--took damage
		Spoke = CurTime(),		--sentence spoke
		SpokeOthers = CurTime(),--sentence spoke for allies
		Requested = CurTime(),	--idle speaking; requested report
		Reported = CurTime(),	--idle speaking; reported
		Asked = CurTime(),		--idle speaking; asked question
		Answered = CurTime(),	--idle speaking; answered question
		Arrest = CurTime(),		--arrest behaviour; time to shoot
	}
end

function ENT:SetWeaponInfo()
	self.Primary.Name = TrueSniper and "weapon_357" or "weapon_pistol" --Weapon classname
	self.Primary.Clip = TrueSniper and 6 or 18 --Clip size
	self.Primary.Num = TrueSniper and 1 or 1 --Amount of bullets per shot
	self.Primary.Spread = TrueSniper and 0 or 15 --Spread
	self.Primary.Damage = TrueSniper and 40 or 5 --Damage per bullets
	self.Primary.AmmoType = TrueSniper and "357" or "Pistol" --Ammo type
	self.Primary.Delay = TrueSniper and 0.8 or 0.4 --Fire rate
	self.Primary.ReloadSoundDelay = TrueSniper and 1.5 or 0.8 --Reloading sound delay
	self.Primary.MuzzleProbability = TrueSniper and 0.8 or 0.5 --Probability of emitting muzzle flash
	self.Primary.MuzzleScale = TrueSniper and 1 or 0.6 --Scale of muzzle flash
	self.Primary.Sound = TrueSniper and self.Primary.Sound1 or self.Primary.Sound2 --Shooting sound
	self.Primary.Reload = TrueSniper and self.Primary.Reload1 or self.Primary.Reload2 --Reloading sound
	self.Primary.Ammo = self.Primary.Clip --Ammo that the weapon now has
	
	self.Secondary.Name = TrueSniper and "weapon_shotgun" or "weapon_smg1"
	self.Secondary.Clip = TrueSniper and 6 or 45
	self.Secondary.Num = TrueSniper and 7 or 1
	self.Secondary.Spread = TrueSniper and 10 or 20
	self.Secondary.Damage = TrueSniper and 8 or 4
	self.Secondary.AmmoType = TrueSniper and "Shotgun" or "SMG1"
	self.Secondary.Delay = TrueSniper and 0.5 or 0.1
	self.Secondary.ReloadSoundDelay = TrueSniper and 0.5 or 0.6
	self.Secondary.MuzzleProbability = TrueSniper and 1 or 0.75
	self.Secondary.MuzzleScale = TrueSniper and 1 or 0.95
	self.Secondary.Sound = TrueSniper and self.Secondary.Sound1 or self.Secondary.Sound2
	self.Secondary.Reload = TrueSniper and self.Secondary.Reload1 or self.Secondary.Reload2
	self.Secondary.Ammo = self.Secondary.Clip
end

function ENT:AddCondition(cd)
	table.insert(cd)
end

function ENT:Use()
	TrueSniper = not TrueSniper
	self:SetWeaponInfo()
	PrintMessage(HUD_PRINTTALK, "Super Metropolices have been " .. (TrueSniper and "buffed!" or "nerfed."))
end

function ENT:GetAimVector()
	if IsValid(self:GetEnemy()) and self:Validate(self:GetEnemy()) == 0 then
		return (self:GetTargetPos() - self:GetMuzzle().Pos):GetNormalized()
	else
		return self:GetForward()
	end
end

function ENT:GetActiveWeapon()
	return IsValid(self.Weapon) and self.Weapon or self
end

function ENT:GetMuzzle()
	return IsValid(self.Weapon) and
	self.Weapon:GetAttachment(self.Weapon:LookupAttachment("muzzle")) or
	self:GetAttachment(self:LookupAttachment("anim_attachment_RH"))
end

function ENT:SetEnemy( ent )
	self.Enemy = ent
	self:SetNetworkedEnemy(ent)
end

function ENT:GetHullType()
	return HULL_HUMAN
end

function ENT:GetRelationship(e)
	return D_HT
end

function ENT:GetShootPos()
	return self:GetMuzzle().Pos
end

--Get squad mates aiming at my target
function ENT:GetSameTarget()
	local looking, waiting = 0, 0
	for v in pairs(SQUAD_MATES) do
		if IsValid(v) and v ~= self and v:GetEnemy() == self:GetEnemy() then
			looking = looking + 1
			if v.waitingarrest then
				waiting = waiting + 1
			end
		end
	end
	return looking, waiting
end

--Return if my squad is in arrest behaviour
function ENT:IsArrestBehaviour(others)
	for v in pairs(SQUAD_MATES) do
		if v ~= self and isnumber(v.waitingarrest) and (not others and v:GetEnemy() == self:GetEnemy()) then
			return true
		end
	end
	return false
end

function ENT:ArrestReady()
	if self:IsArrestBehaviour() then
		if self.arrestspoken then
			self:Speak(self.Sentence.FreezeReady, self:CanSpeak(self.arrestspoken[3]))
			self.arrestspoken[3] = false
		end
		local t = CurTime() + 3 + math.Rand(-0.5, 1.5)
		for k in pairs(SQUAD_MATES) do
			if k:GetEnemy() == self:GetEnemy() then
				k.Time.Arrest = t
			end
		end
	end
end

SQUAD_MATES = SQUAD_MATES or {}
function ENT:Initialize()
	self.breakable_filter = ents.FindByClass("func_breakable")
	table.Add(self.breakable_filter, ents.FindByClass("func_breakable_surf"))
	
	self:SetModel("models/Police.mdl")
	self:SetHealth(self.MaxHealth)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:MakePhysicsObjectAShadow(true, true)
--	self:SetMoveType(MOVETYPE_STEP)
--	self.Entity:SetCollisionBounds(Vector(-4, -4, 16), Vector(4, 4, 64))
	
	SQUAD_MATES[self] = self
	SQUAD_MATES_NUM = (SQUAD_MATES_NUM or 0) + 1
	self.Condition = {}
	self.dist = 0 --Distance from myself to the enemy.
	self.escapebias = 10 --If I have low health, I'm more likely to escape from the enemy
	self.killcount = 0 --Counting how many kills I have.
	self.aimattach = 1 --Aiming at attachment, if I couldn't find the enemy's head.
	self.lastsaw = self:GetEye().Pos --I know his last position I've seen.
	self.havepistol = false --Which weapon I have
	self:SetMaxHealth(self.MaxHealth)
	self:SetUseType(SIMPLE_USE)
	self.loco:SetStepHeight(self.StepHeight)
	self.loco:SetJumpHeight(self.JumpHeight)
	self.loco:SetDeathDropHeight(self.StepHeight)--200
	self.loco:SetMaxYawRate(150)
	self:StartActivity(self.Idle)
	self:InitializeTimers()
	self:SetWeaponInfo()
	self:ClearArrest()
	self:ClearPath()
	self:ClearUserStuck()
	
	self:XorInit(CurTime())
end

function ENT:FireWeapon(smg)
	if not (IsValid(self:GetEnemy()) or IsValid(self.Weapon)) then return end
	if not self.shoot then return end
	if self.Weapon:GetForward():Dot(self:GetAimVector()) < 0.9 then self.loco:FaceTowards(self.lastsaw) return end
	if self.Weapon:GetNoDraw() then self.Weapon:SetNoDraw(false) end
	
	local wep = self.Weapon
	local shootPos = self:GetMuzzle().Pos
	local WeaponInfo = self.havepistol and self.Primary or self.Secondary
	local delay = math.Clamp(WeaponInfo.Delay + self:XorRand(-0.1, 0.1), 0.05, 3)
	
	if WeaponInfo.Ammo <= 0 then return end
	if CurTime() < self.Time.Fired then return end
	
	self:AddGesture(WeaponInfo.Act)
	
	WeaponInfo.Ammo = WeaponInfo.Ammo - 1
	wep:EmitSound(WeaponInfo.Sound)
	
	local dir = self:GetTargetPos(true)
--	local t = util.TraceLine({start = shootPos, endpos = dir, filter = {self, wep}})
--	debugoverlay.Line(t.StartPos, t.HitPos, 1, Color(0, 255, 0, 255), false)
	
	local bullet = {
		Attacker = self,
		Num = WeaponInfo.Num,
		Src = shootPos,
		Dir = dir - shootPos,
		Spread = Vector(WeaponInfo.Spread, WeaponInfo.Spread, 0),
		Force = 10000,
		Tracer = 1,
		TracerName = "Tracer",
		Damage = WeaponInfo.Damage,
		AmmoType = WeaponInfo.AmmoType,
		Callback = function(attacker, tr, dmginfo)
			if not IsValid(attacker:GetEnemy()) then return end
			if not IsValid(tr.Entity) then return end
			if tr.Entity ~= attacker:GetEnemy() then return end
			
			dmginfo:SetInflictor(wep)
			local c = tr.Entity:GetClass()
			local health, maxhealth = tr.Entity:Health(), tr.Entity:GetMaxHealth()
			if health <= 0 then health = 1 end
			if maxhealth <= 0 then maxhealth = 1 end
			local speak_flag = health / maxhealth < 0.25
			
			if c == "npc_turret_floor" then
			--	tr.Entity:Fire("SelfDestruct")
				speak_flag = false
			elseif c == "npc_rollermine" then
				util.BlastDamage(wep, self, tr.Entity:GetPos(), 1, 1)
				speak_flag = false
			end
			
			if speak_flag then self:Speak(self.Sentence.EnemyHurt, self:CanSpeak()) end
		end,
	}
	self:FireBullets(bullet)
	
	self:MuzzleFlash()
	wep:MuzzleFlash()
	self.Time.Fired = CurTime() + delay
	self.Time.Moved = CurTime() + delay / 5
	
	local ef = EffectData()
	ef:SetOrigin(shootPos)
	ef:SetAngles(self:GetMuzzle().Ang)
	ef:SetScale(WeaponInfo.MuzzleScale)
	ef:SetEntity(wep)
	ef:SetEntIndex(wep:EntIndex())
	ef:SetAttachment(wep:LookupAttachment("muzzle"))
	if self:XorRand() < WeaponInfo.MuzzleProbability then
		util.Effect("MuzzleEffect", ef)
	end
	
	local eject
	if self.havepistol then
		if not TrueSniper then
			eject = "ShellEject"
		end
	else
		if TrueSniper then
			eject = "ShotgunShellEject"
		else
			eject = "RifleShellEject"
		end
	end
	
	ef:SetAngles(self:GetMuzzle().Ang - Angle(0, 90, 0))
	ef:SetOrigin(shootPos - self:GetMuzzle().Ang:Forward() * 8)
	ef:SetStart(self:GetRight())
	if eject then util.Effect(eject, ef) end
end

function ENT:FindEnemy()
	local list = ents.FindInSphere(self:GetEye().Pos, self.FarDistance)
	local nearest = math.huge
	local dist = math.huge
	local enemy = nil
	local target = nil
	
	for k, v in pairs(list) do
		if IsValid(v) then
			local e = self:Validate(v)
			if e == 0 and (v:GetPos() - self:GetEye().Pos):GetNormalized():Dot(self:GetForward()) > 0.5 and
				self:CanSee(nil, 10000, self:GetTargetPos(false, v)) then --normal entity and can see
				
				dist = self:GetRangeSquaredTo(v:GetPos())
				if dist < nearest then
					nearest = dist
					target = v
				end
				
				if not IsValid(self:GetEnemy()) then
					local sentence = self:SpeakClassify(v)
					self:Speak(sentence, self:CanSpeak())
				end
			elseif e == 1 and IsValid(v:GetEnemy()) then --ally bot who have enemy
				
				dist = self:GetRangeSquaredTo(v:GetEnemy():GetPos())
				if dist < nearest then
					nearest = dist
					target = v:GetEnemy()
				end
			end
		end
	end
	
	self:SetEnemy(target)
	if not IsValid(target) then return false end
	self.lastsaw = self:GetTargetPos()
	self.dist = self:GetRangeTo(self.lastsaw)
	self.aimattach = 1
	return true
end

function ENT:HaveEnemy()
	if IsValid(self:GetEnemy()) then
		local e = self:GetEnemy()
		if not self:FindEnemy() then
			self:SetEnemy(e)
		end
		return true
	else
		return self:FindEnemy()
	end
end

function ENT:CanSee(vec, rad, entpos, shot, draw)
	local e = entpos or (IsValid(self:GetEnemy()) and self:GetTargetPos())
	if not e then return false end
	
	local FilterTable = table.Copy(self.breakable_filter)
	table.Add(FilterTable, {self, self.Weapon})
	local tr = util.TraceLine({
		start = vec or self:GetEye().Pos,
		endpos = e,
		filter = FilterTable,
		mask = shot and MASK_SHOT or MASK_BLOCKLOS_AND_NPCS
	})
--	debugoverlay.Line(tr.StartPos, tr.HitPos or self:GetTargetPos(false, e), 3, Color(0, 255, 0, 255), false)
	return not tr.StartSolid and not tr.HitWorld and (tr.HitPos - e):LengthSqr() < (rad or 10000)
end

--function ENT:OnContact(e)
--	if CurTime() % 1.5 < 0.2 then
--		if not e:IsWorld() then
--			self.userstuck = true
--		end
--	end
--end

function ENT:OnContact(v)
	if not IsValid(v) then return end
	if v:IsPlayer() or v:IsNPC() or v.Type == "nextbot" then return end
	local p = v:GetPhysicsObject()
	if not IsValid(p) then return end
--	p:SetInertia(-p:GetInertia() / 2)
	local f = -p:GetVelocity()
	p:SetVelocityInstantaneous(vector_origin)
	p:ApplyForceCenter(f)
	
	local e = p:GetEnergy()
	local division = 2.0 * 10^6
	
	if v:IsVehicle() and isfunction(v.GetSpeed) and isnumber(v:GetSpeed()) then
		e = v:GetSpeed() * division
	end
	
	if e < division then return end
	local d = DamageInfo()
	local attacker = v:GetPhysicsAttacker()
	if not IsValid(attacker) then attacker = v end
	d:SetAttacker(attacker)
	d:SetDamage(e / division)
	d:SetDamageForce(p:GetVelocity() / 2)
	d:SetDamagePosition(self:WorldSpaceCenter())
	d:SetDamageType(DMG_CRUSH)
	d:SetInflictor(v)
	d:SetMaxDamage(d:GetDamage())
	d:SetReportedPosition(p:GetMassCenter())
	
	self:TakeDamageInfo(d)
end

function ENT:OnRemove()
	self:SetEnemy(nil)
	SQUAD_MATES[self] = nil
	SQUAD_MATES_NUM = SQUAD_MATES_NUM - 1
	if SQUAD_MATES_NUM < 0 then SQUAD_MATES_NUM = 0 end
	
	if IsValid(self.Weapon) then self.Weapon:Remove() end
end

function ENT:OnOtherKilled(e, info)
	local sentence = self.Sentence.DangerGeneral
	local alone, can = self:CanSpeak()
	if info:GetAttacker() == self then
		self.killcount = self.killcount + 1
		sentence = self:SpeakClassify(e, "kill")
		self:Speak(sentence, alone, can)
	elseif e:GetClass() == "npc_supermetropolice" then
		sentence = alone and self.Sentence.DyingMateLast or self.Sentence.DyingMate
		self:Speak(sentence, alone, alone or can)
	end
end

function ENT:OnInjured(info)
	local tr = util.QuickTrace(info:GetDamagePosition(), info:GetDamageForce())
	if tr.Entity == self and tr.HitGroup == HITGROUP_HEAD then info:ScaleDamage(2) end
	
	local sentence = self.Sentence.Pain
	if not self.said_die and self:Health() - info:GetDamage() <= 0 then
		sentence = self.Sentence.Dying
		self.said_die = true
	elseif not self.said_painlight and self:Health() - info:GetDamage() > 0.9 * self:GetMaxHealth() then
		sentence = self.Sentence.PainLight
		self.said_painlight = true
	elseif not self.said_painheavy and self:Health() - info:GetDamage() < 0.25 * self:GetMaxHealth() then
		sentence = self.Sentence.PainHeavy
		self.said_painheavy = true
	end
	self:Speak(sentence, self:CanSpeak(self:XorRand() > self:Health() / self:GetMaxHealth()))
	
	if self.havepistol and (info:GetDamagePosition() - 
		info:GetReportedPosition()):GetNormalized():Dot(self:GetForward()) < -0.7 then
		self:ClearPath()
		self.Time.Moved = CurTime() + self:XorRand(0.4, 1)
		self:AddGestureSequence(self:LookupSequence("flinch_back1"))
	else
		if tr.Entity == self then
			local gr = tr.HitGroup
			local flinch = {
				[HITGROUP_HEAD] = "flinchheadgest" .. math.random(1, 2),
				[HITGROUP_STOMACH] = "flinchgutgest1" .. math.random(1, 2),
				[HITGROUP_LEFTARM] = "flinchlarmgest",
				[HITGROUP_RIGHTARM] = "flinchrarmgest",
			}
			if flinch[gr] then
				self:AddGestureSequence(self:LookupSequence(flinch[gr]))
			elseif self.havepistol and info:GetDamage() > self:GetMaxHealth() / 4 then
				self:ClearPath()
				self.Time.Moved = CurTime() + self:XorRand(0.4, 1)
				self:AddGestureSequence(self:LookupSequence("flinch2"))
			else
				self:AddGesture(ACT_GESTURE_SMALL_FLINCH)
			end
		end
	end
	
	if self.escapebias > 5 then self.escapebias = self.escapebias * 0.6 end
	if info:IsDamageType(DMG_BURN) or self:Validate(info:GetAttacker()) ~= 0 then return end
--	if not self.path then self:Escape(true, info:GetAttacker(), false) end
	
	if not IsValid(self:GetEnemy()) or not self:GetLook() or 
		(self:GetPos() - self:GetEnemy():GetPos()):LengthSqr() > 
		(self:GetPos() - info:GetAttacker():GetPos()):LengthSqr() then
		
		self:SetEnemy(info:GetAttacker())
	end
end

function ENT:OnKilled(info)
	hook.Call("OnNPCKilled", GAMEMODE, self, info:GetAttacker(), info:GetInflictor())
	if IsValid(self.Weapon) then
		local w = ents.Create(self.Weapon:GetClass())
		w:SetPos(self.Weapon:GetPos())
		w:SetAngles(self.Weapon:GetAngles())
		w:SetVelocity(self.Weapon:GetAbsVelocity())
		w:Spawn()
		self.Weapon:Remove()
	end
	self:BecomeRagdoll(info)
	self:OnRemove()
	
	if GetConVar("supermetropolice_showkillstreak"):GetBool() then
		PrintMessage(HUD_PRINTTALK, "Super Metropolice got " .. 
			(self.killcount or 0) .. " kill" .. (self.killcount == 1 and "" or "s") .. ".")
	end
end

--function ENT:GetThrowVec(v1, v2)
--	local g = GetConVar("sv_gravity"):GetFloat()
--	local x1, x2 = v1:Length2DSqr(), v2:LengthSqr()
--	local x1s, x2s = math.sqrt(x1), math.sqrt(x2)
--	local y1, y2 = v1.z, v2.z
--	
--	local tan = -(y1 - (x1 / x2) * y2) / ((x1s * x2s) - (x1 / x2s))
--	print(tan)
--	if tan < 0.176327 then tan = 0.176327 end
--	local tmp = (x1s / tan) - (y1 / (tan * tan))
--	if tmp < 0 then return end
--	local pow = math.sqrt((2 / (g * x1)) * tmp)
--	
--	local vec = v2 - v1
--	vec.z = 0
--	vec:Normalize()
--	vec:Mul(pow / tan)
--	vec.z = pow
--	
--	return vec
--end

function ENT:GetTossVec(v1, v2, pow, high)
	local tr
	local vMidPoint //halfway point between v1 and v2
	local vApex //highest point
	local vScale
	local velocity
	local vTemp
	local g = GetConVar("sv_gravity"):GetFloat() -- * gravity_adjust
	
	local mul = (0.875 / 2) * (pow / (v2 - v1):Length())^1.02 --multiplier of power
	local n = vector_up--(v1 - v2):Cross(self:GetRight()):GetNormalized() -- normal vector of parabola
	
--	if v1.z > v2.z + (pow * (500 / 650)) then return end //to high, fail
	
	// toss a little bit to the left or right, not right down on the enemy's bean (head).
	v2.x = v2.x + self:XorRand(-8, 8)
	v2.y = v2.y + self:XorRand(-8, 8)
	
	// How much time does it take to get there?
	// get a rough idea of how high it can be thrown
	vMidPoint = util.QuickTrace(v1 + (v2 - v1) * 0.5, n * high, self).HitPos
	// (subtract 15 so the grenade doesn't hit the ceiling)
	vMidPoint.z = vMidPoint.z - 15
	
	if (vMidPoint.z < v1.z) or (vMidPoint.z < v2.z) then return end //to not enough space, fail
	
	// How high should the grenade travel to reach the apex
	local d1 = vMidPoint.z - v1.z
	local d2 = vMidPoint.z - v2.z
	
	// How long will it take for the grenade to travel this distance
	local t1 = math.sqrt(2 * d1 / g)
	local t2 = math.sqrt(2 * d2 / g)
	
	if t1 < 0.1 then return end //too close
	
	// how hard to throw sideways to get there in time.
	velocity = ((v2 - v1) / (t1 + t2)) * mul * 1.05
	// how hard upwards to reach the apex at the right time.
	velocity = velocity + n * g * t1 * mul
	
	
	// find the apex
	vApex = vMidPoint
	vApex = vApex - n * (high * 0.15)
	
--	debugoverlay.Line(v1, vApex, 3, Color(255,255,0,255),true)
--	debugoverlay.Line(v2, vApex, 3, Color(255,255,0,255),true)
	tr = util.TraceLine({start = v1, endpos = vApex, filter = self})
	if tr.Fraction ~= 1.0 then return end //fail
	
	// UNDONE: either ignore monsters or change it to not care if we hit our enemy
	tr = util.TraceLine({start = v2, endpos = vApex, filter = self, mask = MASK_NPCSOLID_BRUSHONLY})
	if tr.Fraction ~= 1.0 then return end //fail
	
	velocity.x = velocity.x * 2
	velocity.y = velocity.y * 2
	return velocity, t1 + t2
end

function ENT:GetThrowVec(v1, v2, pow)
	local g = GetConVar("sv_gravity"):GetFloat()
	local velocity = v2 - v1
	local mul = (0.29 / 2) * (pow / velocity:Length())
	
	//throw at a constant time
	local time = velocity:Length() / 1000
	velocity = velocity:GetNormalized() * pow
	
	//adjust upward toss to compensate for gravity loss
	local n = vector_up--(v1 - v2):Cross(self:GetRight()):GetNormalized()
	velocity = velocity + (n * (g * time * mul))
	local vApex = v1 + ((v2 - v1) * 0.5)
	vApex = vApex + (n * (0.5 * g * (time * mul)^2))
	
--	debugoverlay.Line(v1, vApex, 3, Color(0,255,255,255),true)
--	debugoverlay.Line(v2, vApex, 3, Color(0,255,255,255),true)
	local tr = util.TraceLine({start = v1, endpos = vApex, filter = self})
	if tr.Fraction ~= 1.0 then return end
	tr = util.TraceLine({start = v2, endpos = vApex, filter = self, mask = MASK_NPCSOLID_BRUSHONLY})
	if tr.Fraction ~= 1.0 then return end
	
	return velocity, time * 0.72
end

function ENT:Throw()
	if CurTime() < self.Time.Threw then return end
	if self.dist < self.NearDistance / 2 then return end
	if IsValid(navmesh.GetNearestNavArea(self:GetPos())) and 
		navmesh.GetNearestNavArea(self:GetPos()):GetAdjacentCount() < 6 then return end
	
	if IsValid(self:GetEnemy()) then self.lastsaw = self:GetEnemy():WorldSpaceCenter() end
	local att = "anim_attachment_LH"
	local p = self:GetAttachment(self:LookupAttachment(att))
	local throwVec = self.lastsaw - p.Pos
	local tr = self:CanSee(self:GetEye().Pos, 10000, self.lastsaw)
	local time = 3.5
	local seq = tr and "grenadethrow" or "deploy"
	local wait = tr and 0.8 or 1
	
	if tr then
		local pow = self.dist * 2
		throwVec, time = self:GetThrowVec(p.Pos, self.lastsaw, pow, 50)
	else
		local tosshigh = 1000
		local pow = self.dist * 2
		tr = util.QuickTrace(p.Pos, vector_up * tosshigh, self)
		tr = tosshigh * tr.Fraction
	--	if tr.Fraction ~= 1.0 then return end
		throwVec, time = self:GetTossVec(p.Pos, self.lastsaw, pow, tr)
	end
	
	if not throwVec then return end
--	debugoverlay.Line(self.lastsaw, self:GetEye().Pos, 2, Color(0,255,0,255),true)
--	debugoverlay.Line(p.Pos, p.Pos + throwVec, 2, Color(0,255,0,255),true)
	
	timer.Simple(wait, function()
		if not IsValid(self) then return end
		local ent = ents.Create("npc_grenade_frag")
		ent:Input("settimer",self, self, time)
		ent:SetHealth(10000)
		ent:SetMaxHealth(10000)
	--	ent:Input("settimer",self, self, self.dist * 0.00055)
	--	ent:Input("settimer",self, self, self.dist * 0.00026)
		ent:SetPos(self:GetAttachment(self:LookupAttachment(att)).Pos)
		ent:SetAngles(self:GetAttachment(self:LookupAttachment(att)).Ang)
		ent:SetOwner(self)
		ent:SetSaveValue("m_hThrower", self)
		ent:Spawn()
		
		local phys = ent:GetPhysicsObject()
		phys:ApplyForceCenter(throwVec)
		phys:AddAngleVelocity(VectorRand() * 1000)
		phys:AddAngleVelocity(VectorRand() * 1000)
		
		if TrueSniper then
			timer.Simple(time / 2, function()
				if not IsValid(ent) then return end
				ent:AddCallback("OnAngleChange", function(ent, ang)
					if IsValid(ent.Owner) and IsValid(ent.Owner:GetEnemy()) then
						local phys = ent:GetPhysicsObject()
						local pos = ent.Owner:GetTargetPos()
						phys:ApplyForceCenter((pos - phys:GetPos()) * (pos - phys:GetPos()):LengthSqr() / 10)
					end
				end)
			end)
		else
			ent:AddCallback("OnAngleChange", function(ent, ang)
				if not IsValid(ent) or ent:IsOnFire() then return end
				ent:Ignite(0.1, 0)
			end)
		end
	end)
	
	self:RemoveAllGestures()
	self:ClearPath()
	self:ClearUserStuck()
	self:StartActivity(self.Idle)
	self.Time.Threw = CurTime() + 6 + self:XorRand(-1, 1)
	self:PlaySequenceAndWait(seq)
end

function ENT:StartMove(moveto, shoot, opt)
    local opt = opt or {}
    if not opt.overwrite and self.path then return "invalid" end
	
	self.path = Path("Follow")
	local to = self:GetMoveTo(opt.dist)
	local n = navmesh.Find(to, 1, self.StepHeight * 3, self.StepHeight)
	local vis = false
	for k, v in pairs(n) do
		if self.loco:IsAreaTraversable(v) then
			vis = true
			break
		end
	end
	
	if not vis then
	--	debugoverlay.Line(self:GetPos(), to, 5, Color(255, 0, 0, 255), true)
		if not opt.overwrite then
			self.path:Invalidate()
			self.path = nil
			self.shootflag = nil
		end
		return "invalid"
	end
	
    self:ClearUserStuck()
	self.shootflag = shoot
	self.overwrite = opt.overwrite
	
	self.loco:SetAcceleration(600)
	self.loco:SetDeceleration(5000)
	
	self.moveto = moveto
	self.runflag = opt.run
	self.tolerance = opt.tolerance or 10
	self.path:SetMinLookAheadDistance(opt.lookahead or 100)
	self.path:SetGoalTolerance(10)
	self.path:Compute(self, to)--, function(area, fromArea, ladder, elevator, length) return self:findpath(area, fromArea, ladder, elevator, length) end)
	
	if not moveto and self.path:GetLength() > 600 then
		self.path:Invalidate()
		self.path = nil
		self.shootflag = nil
		return "invalid"
	end
--	print(opt.typeid)
	return "ok"
end

function ENT:IsValidPos(target, enemy, distance)
	local enemypos = self:GetTargetPos(false, enemy)
	local distance = enemypos:DistToSqr(self:GetPos())
	local d1 = enemypos:DistToSqr(target)
	local d2 = self:GetPos():DistToSqr(target)
	
	if d2 < d1 then
		if distance < d1 then return true
		elseif distance < d1 * distance then return false end
	end
	
	return nil
end

function ENT:FindPosition(beginpos, radius, enemy, up, navmaxnum, cansee, see_radius, enemydistance)
	self.Time.Moved = CurTime() + self:XorRand(0.5, 1)
	
	local spots = navmesh.Find(beginpos, radius, self.loco:GetDeathDropHeight(), self.StepHeight)
	local target, found, alt = nil, {}, {}
	local visible = false
	local p = Path("Follow")
	
	local i = 0
	for k, n in pairs(spots) do
		if k > navmaxnum / SQUAD_MATES_NUM then break end
		visible, pos = n:IsVisible(self:GetTargetPos(false, enemy))
		pos = n:GetRandomPoint() + vector_up * up
		
		local see = self:CanSee(pos, see_radius, self:GetTargetPos(false, enemy), true)
	--	debugoverlay.Line(pos, self:GetTargetPos(false, enemy))
		if cansee == see then
			local valid = self:IsValidPos(pos, enemy, enemydistance or 0.7)
			if valid ~= nil then
				p:Invalidate()
				p:Compute(self, pos)
				if valid then
					table.insert(found, {vec = pos, len = p:GetLength()})
				else
					table.insert(alt, {vec = pos, len = p:GetLength()})
				end
			end
		end
	end
	return found, alt
end

function ENT:Advance(shoot)
	if self.path or CurTime() < self.Time.Moved then return end
	local found, alt = self:FindPosition(self.lastsaw, 2000, self:GetEnemy(), 55, 300, true, nil, 0.4)
	
	if #found > 0 then
		table.SortByMember(found, "len", true)
		self:StartMove(found[1].vec, shoot, {tolerance = 30, run = true, typeid = "advance"})
	elseif #alt > 0 then
		table.SortByMember(alt, "len", true)
		self:StartMove(alt[1].vec, shoot, {tolerance = 30, run = true, typeid = "advance"})
	elseif self:XorRand() < 0.5 then
		self:StartMove(self.lastsaw, shoot, {tolerance = 50, run = true, typeid = "advance"})
	else
		self.loco:FaceTowards(self.lastsaw)
	end
end

function ENT:SetSnipe()
	if self.path or CurTime() < self.Time.Moved then return end
	local found, alt = self:FindPosition(self:GetPos(), 2000, self:GetEnemy(), 55, 300, true, nil)
	
	if #found > 0 then
		table.SortByMember(found, "len", true)
		self:StartMove(found[1].vec, false, {tolerance = 30, run = true, typeid = "snipe"})
	elseif #alt > 0 then
		table.SortByMember(alt, "len", true)
		self:StartMove(alt[1].vec, false, {tolerance = 30, run = true, typeid = "snipe"})
	elseif self:XorRand() < 0.5 then
		self:StartMove(self.lastsaw, true, {tolerance = 50, run = true, typeid = "snipe"})
	else
		self.loco:FaceTowards(self.lastsaw)
	end
end

function ENT:Escape(shoot, ent, far, range, overwrite)
	if not overwrite and (self.path or CurTime() < self.Time.Moved) then return end
	local e = ent or self:GetEnemy()
	if IsValid(e) then
		e = self:GetTargetPos(false, e)
	else
		e = self:HaveEnemy() and self:GetTargetPos() or self.lastsaw
	end
	
	local found, alt = self:FindPosition(self:GetPos(), 5000, self:GetEnemy(), 40, 300, false, 400^2)
	if #found > 0 then
		table.SortByMember(found, "len", not far)
		local n = far and math.ceil(#found / 2) or 1
		self:StartMove(found[n].vec, shoot, 
			{tolerance = range or 20, run = true, overwrite = overwrite, typeid = "esc"})
	elseif #alt > 0 then
		table.SortByMember(alt, "len", not far)
		local n = far and math.ceil(#alt / 2) or 1
		self:StartMove(alt[n].vec, shoot, 
			{tolerance = range or 20, run = true, overwrite = overwrite, typeid = "esc"})
	else
		self:StartMove(self:GetPos() + self:GetRight() * self:XorRand(-200, 200), shoot, 
			{tolerance = range or 50, overwrite = overwrite, typeid = "esc"})
	end
end

function ENT:Give(class)
	self.havepistol = class
	if class == nil then class = "weapon_stunstick" else
	class = class and self.Primary.Name or self.Secondary.Name end
	
	local isfirstdeploy = true
	if IsValid(self.Weapon) then
		if self.Weapon:GetClass() == class then return end
		self.Weapon:Remove()
		isfirstdeploy = nil
	end
	
	local att = "anim_attachment_RH"
	local shootpos = self:GetAttachment(self:LookupAttachment(att))
	
	wep = ents.Create(class)
	wep.Owner = self
	wep:SetOwner(self)
	wep:SetPos(shootpos.Pos)
	wep:SetAngles(shootpos.Ang)
	--Adds Spawn Flags.  2 .. Deny player pickup, 4 .. Not puntable bu Gravity Gun.
	wep:SetKeyValue("spawnflags", 2+4)
	
	wep:SetSolid(SOLID_NONE)
	wep:SetParent(self)
	wep:Fire("SetParentAttachmentMaintainOffset", att, 0)
	wep:AddEffects(EF_BONEMERGE)
	wep:Spawn()
	
	local e = EffectData()
	e:SetEntity(self)
	util.Effect("supermetropolice_weaponspawn", e)
	self.Weapon = wep
	
	local laser = EffectData()
	laser:SetEntity(wep)
	util.Effect("supermetropolice_lasersight", laser)
	
	if isfirstdeploy and class == self.WeaponName1 then
		wep:SetNoDraw(true)
		wep:DrawShadow(false)
		
		local bLooking = self:GetLook()
		self:SetLook(false)
		timer.Simple(1, function()
			if IsValid(wep) then
				wep:SetNoDraw(false)
				wep:DrawShadow(true)
			end
		end)
		self:PlaySequenceAndWait("drawpistol")
		self:SetLook(bLooking)
		self:StartActivity(self.Idle)
	end
end

function ENT:Reload()
	if not self.reloadflag then return end
	if self.Primary.Ammo >= self.Primary.Clip and 
		self.Secondary.Ammo >= self.Secondary.Clip then
		self.reloadflag = false
		return
	end
	local pistol
	if self.Primary.Ammo == 0 then pistol = true
	elseif self.Secondary.Ammo == 0 then pistol = false
	elseif self.Primary.Ammo < self.Primary.Clip then pistol = true
	elseif self.Secondary.Ammo < self.Secondary.Clip then pistol = false end
	
	self:RemoveAllGestures()
	self:StartActivity(self.Idle)
	local bLooking = self:GetLook()
	self:SetLook(false)
	
	local WeaponInfo = pistol and self.Primary or self.Secondary
	if not IsValid(self.Weapon) or self.Weapon:GetClass() ~= WeaponInfo.Name then self:Give(pistol) end
	local seq = pistol and "pistol" or "smg1"
	
	if util.QuickTrace(self:GetEye().Pos, self:GetForward() * 100, {self, self.Weapon}).Hit or
		util.QuickTrace(self:GetEye().Pos, -self:GetForward() * 100, {self, self.Weapon}).Hit or
		util.QuickTrace(self:GetEye().Pos, self:GetRight() * 100, {self, self.Weapon}).Hit or
		util.QuickTrace(self:GetEye().Pos, -self:GetRight() * 100, {self, self.Weapon}).Hit then
		
		timer.Simple(WeaponInfo.ReloadSoundDelay, function()
			if IsValid(self) and IsValid(self.Weapon) then
				self.Weapon:EmitSound(WeaponInfo.Reload)
			end
		end)
		self:PlaySequenceAndWait(WeaponInfo.ReloadSequence)
	else
		self:PlaySequenceAndWait("Stand_to_crouch" .. seq, 1.5)
		
		timer.Simple(WeaponInfo.ReloadSoundDelay, function()
			if IsValid(self) and IsValid(self.Weapon) then
				self.Weapon:EmitSound(WeaponInfo.Reload)
			end
		end)
		self:PlaySequenceAndWait(WeaponInfo.ReloadSequenceCrouched)
		self:PlaySequenceAndWait("Crouch_to_stand" .. seq, 1.5)
	end
	WeaponInfo.Ammo = WeaponInfo.Clip
	
	self:SetLook(bLooking)
end

function ENT:GetYawPitch(vec)
	--This gets the offset from 0,2,0 on the entity to the vec specified as a vector
	local yawAng = vec - self:GetAttachment(self:LookupAttachment("eyes")).Pos
	--Then converts it to a vector on the entity and makes it an angle ("local angle")
	local yawAng = self:WorldToLocal(self:GetPos() + yawAng):Angle()
	
	--Same thing as above but this gets the pitch angle.
	--Since the turret's pitch axis and the turret's yaw axis are seperate I need to do this seperately.
	local pAng = vec - self:LocalToWorld((yawAng:Forward() * 8) + Vector(0, 0, 50))
	local pAng = self:WorldToLocal(self:GetPos() + pAng):Angle()

	--Y=Yaw. This is a number between 0-360.
	local y = yawAng.y
	--P=Pitch. This is a number between 0-360.
	local p = pAng.p
	
	--Numbers from 0 to 360 don't work with the pose parameters, so I need to make it a number from -180 to 180
	if y >= 180 then y = y - 360 end
	if p >= 180 then p = p - 360 end
	if y < -60 || y > 60 then return false end
	if p < -80 || p > 50 then return false end
	--Returns yaw and pitch as numbers between -180 and 180
	return y, p
end

--This grabs yaw and pitch from ENT:GetYawPitch. 
--This function sets the facing direction of the turret also.
function ENT:Aim(vec)
	local y, p = self:GetYawPitch(vec)
	if not y then return false end
	self:SetPoseParameter("aim_yaw", y)
	self:SetPoseParameter("aim_pitch", p)
	
	return true
end

function ENT:Wait(sec)
	local start = CurTime()
	
	while start + (sec or 2.5) > CurTime() do
		if IsValid(self.Weapon) then
			if self.havepistol then
				self:SetAnim(self.StandPistol)
			else
				self:SetAnim(self.StandRifle)
			end
		else
			self:SetAnim(self.Idle)
		end
		
		if self:HaveEnemy() then return end
		coroutine.yield()
		if self:GetEyeTrace().Fraction < 0.5 then
			self.loco:FaceTowards(self:GetEye().Pos + self:GetEyeTrace().HitNormal * 10)
		end
		for k, v in pairs(ents.FindInSphere(self:GetPos(), 200)) do
			if IsValid(v) and string.find(v:GetClass(), "grenade") then
				self:Escape(nil, v)
				return
			end
		end
	end
end

function ENT:SetAnim(a)
	if self:GetActivity() ~= a then
		self:StartActivity(a)
	end
end

function ENT:ClearArrest()
	self.waitingarrest = false --Waiting for an unaware enemy
	self.arrestspoken = {true, true, true} --Arrest sentence spoken
	self.arrestpos = nil --Check for fleeing
	self.Time.Arrest = CurTime()
end

function ENT:ClearPath()
	if self.path and self.path.Invalidate then self.path:Invalidate() end
	self.path = nil
	self.runflag = nil
	self.overwrite = nil
	self:ClearUserStuck()
	self.loco:ClearStuck()
end

function ENT:ClearUserStuck()
	self.userstuck = nil --lua-defined stuck flag
	self.Time.Stuck = nil --first userstuck detected
	self.stucknum = nil -- +1 every HandleStuck() called
	if self.altpath and self.altpath.Invalidate then self.altpath:Invalidate() end
	self.altpath = nil --do alternate path to avoid obstacles
	self.prevpos = vector_origin --to detect stopping
end

function ENT:GetMoveTo(dist)
	return self.moveto or (self:GetPos() + Vector(self:XorRand(-1, 1), self:XorRand(-1, 1), 0) * (dist or 400))
end

function ENT:IsUserStuck()
	if (self:GetPos() - self.prevpos):Length2DSqr() < 0.0001 then
		self.Time.Stuck = self.Time.Stuck or CurTime() + 2
		self.userstuck = self.Time.Stuck < CurTime()
	end
	self.prevpos = self:GetPos()
	return self.userstuck
end

function ENT:HandleStuck()
	self.userstuck = false
	local stuckpath = Path("Follow")
	stuckpath:SetMinLookAheadDistance(1)
	stuckpath:SetGoalTolerance(10)
	local n = navmesh.GetNearestNavArea(self:GetPos())
	if n then
		stuckpath:Compute(self, n:GetCenter())
	else
		stuckpath:Compute(self, self:GetMoveTo())
	end
	
	while stuckpath:IsValid() do
	--	stuckpath:Draw()
		stuckpath:Update(self)
		coroutine.yield()
		
		if self:IsUserStuck() or stuckpath:GetAge() > 3 then
			stuckpath:Invalidate()
			break
		end
	end
	self.loco:ClearStuck()
--	if self.path then self.path:Compute(self, self:GetMoveTo()) end
	
	self.stucknum = (self.stucknum or 0) + 1
	if self.stucknum > 3 then
		self.stucknum = 0
		self.loco:JumpAcrossGap(self:GetMoveTo(), self:GetForward())
		self:ClearUserStuck()
		return true
	end
	
	return false
end

function ENT:MoveBehaviour()
	if self.path then
		if self.path:IsValid() then
			if self.runflag or IsValid(self.Weapon) then
				self:SetAnim(IsValid(self.Weapon) and 
					(self.havepistol and self.RunPistol or self.RunRifle) or self.Run)
				self.loco:SetDesiredSpeed(self.RunSpeed)
			else
				self:SetAnim(self.Walk)
				self.loco:SetDesiredSpeed(self.WalkSpeed)
			end
			
			local seg = self.path:GetCursorData()
			if seg.pos:IsEqualTol(self.path:LastSegment().pos, 5) then
				self.path:SetGoalTolerance(self.tolerance + (self.stucknum or 0) * 40)
			end
			
			if self:GetVelocity():LengthSqr() > 100 then
				self:SetPoseParameter("move_yaw",
				math.Remap(self:WorldToLocal(self:GetPos() - self:GetVelocity()):Angle().y, 0, 360, -180, 180))
			else
				local vec = Vector(1, 0, 0)
				vec:Rotate(Angle(0, CurTime() * 180, 0))
				debugoverlay.Line(self:GetPos(), self:GetPos() + vec * 100)
				self.loco:Approach(self:GetPos() + vec, 100)
			end
			
			local d = 20
			local base = self:GetPos() + vector_up * self.StepHeight * 2
			local tr = {start = base - self:GetForward() * d,
						endpos = base + self:GetForward() * d,
						filter = SUPERPOLICE}
			local f = util.TraceEntity(tr, self)
			if f.HitWorld then
				local cross = self:GetForward():Cross(f.HitNormal).z
				if (f.HitPos - base):GetNormalized():Dot(self:GetForward()) < 0 then cross = cross * -1 end
				self.loco:Approach(self:GetPos() + self:GetRight() * (cross > 0 and -d or d), 10)
				self.loco:FaceTowards(self:GetPos() - f.HitNormal)
			end
			
		--	local bound = 20
		--	local basepos = self:WorldSpaceCenter() -- self:GetUp() * (bound + 10)
		--	local tr_left = util.TraceLine({
		--		start = basepos - self:GetRight() * bound + self:GetForward() * bound,
		--		endpos = basepos - self:GetRight() * bound - self:GetForward() * bound,
		--		filter = {self, self.Weapon, SQUAD_MATES},
		--	})
		--	local tr_right = util.TraceLine({
		--		start = basepos + self:GetRight() * bound + self:GetForward() * bound,
		--		endpos = basepos + self:GetRight() * bound - self:GetForward() * bound,
		--		filter = {self, self.Weapon, SQUAD_MATES},
		--	})
		--	tr_left.Hit = tr_left.Hit or tr_left.StartSolid or tr_left.AllSolid
		--	tr_right.Hit = tr_right.Hit or tr_right.StartSolid or tr_right.AllSolid
			
		--	local c = self.altpath and Color(255,255,255,64) or Color(0,255,0,64)
		--	debugoverlay.Line(tr_left.StartPos, tr_left.HitPos, 0.1, c, false)
		--	debugoverlay.Line(tr_right.StartPos, tr_right.HitPos, 0.1, c, false)
		--	if not self.altpath then
		--		self.path:Draw()
				self.path:Update(self)
		--		if tr_left.Hit or tr_right.Hit then
		--			self.altpath = Path("Follow")
		--			self.altpath:SetMinLookAheadDistance(1)
		--			self.altpath:SetGoalTolerance(10)
		--			
		--			local movelength = 50
		--			if tr_left.Hit and tr_right.Hit then --go back
		--				self.altpath:Compute(self, self:GetPos() - self:GetForward() * movelength)
		--			elseif tr_left.Hit then --go right
		--				self.altpath:Compute(self, self:GetPos() + self:GetRight() * movelength)
		--			else --go left
		--				self.altpath:Compute(self, self:GetPos() - self:GetRight() * movelength)
		--			end
		--		end
		--	else
		--	--	self.altpath:Draw()
		--		self.altpath:Update(self)
		--		
		--		if not (tr_left.Hit or tr_right.Hit) then
		--			self.altpath:Invalidate()
		--			self.altpath = nil
		--		--	self.path:Compute(self, self:GetMoveTo())
		--		end
		--	end
			
			-- If we're stuck then call the HandleStuck function and abandon
			if self:IsUserStuck() or self.loco:IsStuck() then
				if self:HandleStuck() then
					self:ClearPath()
					return false
				end
			end
			
			if IsValid(self:GetEnemy()) and self.shootflag then
				if self:CanSee(self:GetMuzzle().Pos, nil, nil, true) then
					self:ClearPath()
					self:ArrestReady()
					return false
				end
			elseif self.path and self.path:GetAge() > 1 and IsValid(self.Weapon) and 
				self.reloadflag and (self.path:GetLength() > 400 or self:GetActivity() == self.Walk)then
				local WeaponInfo = self.havepistol and self.Primary or self.Secondary
				if CurTime() > self.Time.Fired then
					if not self:IsPlayingGesture(WeaponInfo.ReloadAct) then
						local duration = self:GetLayerDuration(self:AddGesture(WeaponInfo.ReloadAct)) * 0.85
						self.Time.Fired = CurTime() + duration
						timer.Simple(WeaponInfo.ReloadSoundDelay, function()
							if not IsValid(self) or not IsValid(self.Weapon) or
								not self:IsPlayingGesture(WeaponInfo.ReloadAct) then return end
							local WeaponInfo = self.havepistol and self.Primary or self.Secondary
							self.Weapon:EmitSound(WeaponInfo.Reload)
						end)
					else
						WeaponInfo.Ammo = WeaponInfo.Clip
						self.reloadflag = false
						self.shootflag = true
					end
				end
			end
		else
			self:ClearPath()
			
			if self.reloadflag then
				self:Reload()
				self.reloadflag = false
			end
			
			if not IsValid(self:GetEnemy()) then
				self:SetAnim(self.Idle)
				self:Wait(self:XorRand(0.6, 2))
			end
			return true
		end
	else
		if IsValid(self.Weapon) then
			if not self.havepistol then
				self:SetAnim(self.StandRifle)
			else
				self:SetAnim(self.StandPistol)
			end
			
			self.loco:SetDesiredSpeed(self.RunSpeed)
		else
			self:SetAnim(self.Walk)
			self.loco:SetDesiredSpeed(self.WalkSpeed)
		end
		self:SetPoseParameter("move_yaw", 0)
	end
	
	return false
end

function ENT:RunBehaviour()
	while true do
		if not GetConVar("ai_disabled"):GetBool() then
			local alone, can = self:CanSpeak()
			if self:HaveEnemy() then
				--Speaking enemy status---------------
				if self:XorRand() < 0.05 then
					if self.Time.Saw + 10 > CurTime() then --lost the enemy under 10 seconds ago
						self:Speak(self.Sentence.LostEnemyShort, alone, can)
					elseif self.Time.Saw + 4 > CurTime() then
						self:Speak(self.Sentence.LostEnemyLong, alone, can)
					end
				end
				--------------------------------------
				
				self:SetLook(self:CanSee())
				self.shoot = self:CanSee(self:GetMuzzle().Pos, nil, nil, true)
				
				if self:GetLook() then --Can see enemy
					--Set the enemy info
					self.lastsaw = self:GetTargetPos()
					self.dist = self:GetRangeTo(self.lastsaw)
					self.loco:FaceTowards(self.lastsaw)
					self:Aim(self.lastsaw)
					
					if self.dist < self.MeleeDistance then --kick their butt
						self:SetAnim(self.Idle)
						self:Give()
						timer.Simple(0.45 / (TrueSniper and 2 or 1), function()
							if IsValid(self) and IsValid(self.Weapon) and IsValid(self:GetEnemy())
								and self:GetRangeTo(self:GetTargetPos()) < self.MeleeDistance then
								local d = DamageInfo()
								d:SetAttacker(self)
								d:SetDamage(40)
								d:SetDamageForce(self:GetForward())
								d:SetDamagePosition(self:GetEnemy():WorldSpaceCenter())
								d:SetDamageType(DMG_DISSOLVE)
								d:SetInflictor(self.Weapon)
								d:SetMaxDamage(d:GetDamage())
								self:GetEnemy():TakeDamageInfo(d)
								self.Weapon:EmitSound("Weapon_StunStick.Melee_Hit")
							end
						end)
						self.Weapon:EmitSound("Weapon_StunStick.Swing")
						self:PlaySequenceAndWait("swing", TrueSniper and 2 or 1)
					elseif not self.path and self:Health() > self:GetEnemy():Health() and
						self:Health() > self:GetMaxHealth() * 0.6 and
						self.dist < self.MeleeDistance * 3 then
						self:StartMove(self:GetEnemy():GetPos(), false, {tolerance = 30, typeid = "melee"})
					else
						self:Give(self.dist > self.NearDistance)
						
						if (self.waitingarrest and self:IsArrestBehaviour()) or self.arrestspoken then
							--Arrest behaviour
							
							local looking, arrest_squad = self:GetSameTarget()
							local dmg = (self.havepistol and self.Primary.Damage or self.Secondary.Damage) * looking
							local forcefire = (dmg > self:GetEnemy():Health() * 0.75) or
								(self:GetEnemy():GetForward():Dot(-self:GetForward()) > 0.7) or
								(isfunction(self:GetEnemy().GetEnemy) and SQUAD_MATES[self:GetEnemy():GetEnemy()])
							if forcefire or (not looking == 0 and looking <= arrest_squad) or 
								(isnumber(self.waitingarrest) and self.waitingarrest > 2 and 
								CurTime() > self.Time.Arrest) then
								
								if isnumber(self.waitingarrest) and self.waitingarrest < 5 then
									self:Speak(self.Sentence.FreezeFire, self:CanSpeak(self.waitingarrest))
								end
								self.waitingarrest = false
								self.arrestspoken = nil
								self:FireWeapon()
							elseif isnumber(self.waitingarrest) or looking == 0 then
								if looking == 0 then
									self.waitingarrest = isnumber(self.waitingarrest) and self.waitingarrest or 0
									self.arrestpos = self.lastsaw
									self.arrestspoken[3] = false
								end
								local freeze = {
									self.Sentence.FreezeFirst,
									self.Sentence.FreezeSecond,
									self.Sentence.FreezeReady,
									self.Sentence.FreezeFleeing,
								}
								local n = self.waitingarrest + 1
								if n < 5 then
									if (self.arrestpos - self.lastsaw):LengthSqr() > 6400 then
										n = 4
										self.waitingarrest = 9
									end
									local alone, can = self:CanSpeak()
									if n == 4 or (can and self.arrestspoken[n]) then can = true end
									local spoken = self:Speak(freeze[n], alone, can)
									if spoken then
										self.waitingarrest = self.waitingarrest + 1
										self.arrestspoken[n] = false
									end
									
									self.Time.Arrest = CurTime() + (n < 3 and 12 + self:XorRand(0, 8) or 0)
								end
							else
								self.waitingarrest = true
							end
						else
							--Sometimes throw a grenade
							if self.dist < self.NearDistance * 2 and self:Health() > self:GetMaxHealth() * 0.6 and
							self:XorRand() < 0.05 then
								self:Throw()
							end
							
							self:FireWeapon() --Fire at will
						end
						
						if not IsValid(self:GetEnemy()) then
							self:Wait() --If the enemy has been killed, wait for a while
						else
							--Just found enemy after lost long
							if not self:IsArrestBehaviour() and self.Time.Saw + 10 < CurTime() then
								self:Speak(self.Sentence.RefindEnemy, alone, can)
							end
							self.Time.Saw = CurTime() + 0.5
						end
					end
				else --Can't see enemy
					self:Give(self.dist > self.NearDistance)
					self:Aim(self:WorldSpaceCenter() + self:GetForward())
					if not self:IsArrestBehaviour() and CurTime() > self.Time.Saw and 
						self.dist < self.NearDistance * 2 then
						self:ClearArrest()
						self:Throw()
					end
				end
				
				local e = 0 --Detect dangerous thing
				local sentence = self.Sentence.DangerGeneral
				local escapefrom
				for k, v in pairs(ents.FindInSphere(self:GetPos(), self.NearDistance)) do
					if IsValid(v) then
						local dist = (v:GetPos() - self:WorldSpaceCenter()):LengthSqr()
						if self:Validate(v) == 0 and self:CanSee(nil, nil, nil, true) then
							e = (v:GetForward():Dot((self:GetPos() - v:GetPos()):GetNormalized()) > 0.8)
								and e + 2 or e + 1
						elseif dist < self.NearDistanceSqr and --Grenade is near, take cover
							string.find(v:GetClass(), "grenade") and (v.GetOwner and IsValid(v:GetOwner())
							and not SQUAD_MATES[v:GetOwner()]) then
							
							e = self.escapebias + 1
							escapefrom = v
							sentence = self.Sentence.DangerGrenade
						elseif dist < self.NearDistanceSqr / 64 and string.find(v:GetClass(), "manhack") then
							e = self.escapebias + 1
							sentence = self.Sentence.DangerManHack
						elseif v:IsVehicle() and v:GetSpeed() > 15 and --vehicle incoming
							v:GetVelocity():GetNormalized():Dot((self:WorldSpaceCenter() - 
							v:WorldSpaceCenter()):GetNormalized()) > 0.65 then
							
							e = self.escapebias + 1
							sentence = self.Sentence.DangerVehicle
						end
						
						if self.escapebias < e then break end
					end
				end
				
				if self:XorRand(0, self.escapebias) < e then
					self:Speak(sentence, self:CanSpeak())
					self:Escape(self:XorRand() < 0.5, escapefrom, false, 50, not self.overwrite)
				end
				
				if not self.path then
					if self:XorRand() < 0.05 and
						((self.Primary.Ammo <= self.Primary.Clip / 3) or
						(self.Secondary.Ammo <= self.Secondary.Clip / 3)) then
						self:Speak(self.Sentence.CoverLowAmmo, self:CanSpeak())
						self:Escape(false, nil, false, self.NearDistance)
						self.reloadflag = true
					elseif self:Health() > self:GetMaxHealth() * 0.6 and self.dist > self.FarDistance then
						self:Advance()
					--Arrest behaviour, called
					elseif self.arrestspoken and (not (self.shoot or self.waitingarrest)) and 
						self:IsArrestBehaviour() then
						self:StartMove(self.lastsaw, true, {tolerance = 50, run = true, typeid = "arrest"})
					elseif isbool(self.waitingarrest) and (not self.shoot or 
						self:XorRand() < 1.01 - (self:Health() / self:GetMaxHealth())) then
						local looking = self:GetSameTarget()
						if self:XorRand() > 0.8 and looking > math.ceil(SQUAD_MATES_NUM / 3) then
							self.loco:FaceTowards(self.lastsaw)
							if not self.shoot and 
								self.Time.Saw + 4 + self:XorRand(-0.5, 0.5) < CurTime() and
								(self.Primary.Ammo < self.Primary.Clip or
								self.Secondary.Ammo < self.Secondary.Clip) then
								self.reloadflag = true
							end
						elseif not self.shoot then
							self:SetSnipe()
						end
					end
				elseif self.Primary.Ammo <= 0 or self.Secondary.Ammo <= 0 then
					self:SetLook(false)
				end
				
				if (self.Primary.Ammo <= 0) or (self.Secondary.Ammo <= 0) then
					self:Speak(self.Sentence.CoverNoAmmo, self:CanSpeak())
					self:Escape(false, nil, false)
					self:SetLook(false)
					self.reloadflag = true
				end
			else
				--Idle speaking
				if can and self:XorRand() < 0.2 then
					if alone then
						self:Speak(self.Sentence.Idle, alone, can)
					else
						--sometimes says as if I were alone
						local rand = self:XorRand() < 0.5
						local speaking = rand and not self:Speak(self.Sentence.Idle, alone, can)
						
						if not rand or (rand and speaking) then --if I've said, skipping
							if self:XorRand() < 0.5 then
								if self.Time.Requested > self.Time.Reported then --reporting
									if self.Sentence.IdleReport ~= self:EntIndex() and
										self:Speak(self.Sentence.IdleClear, alone, can) then
										
										self.Time.Reported = CurTime()
									end
								else --request report
									if self:Speak(self.Sentence.IdleSquad, alone, can) then
										
										self.Sentence.IdleReport = self:EntIndex()
										self.Time.Requested = CurTime()
									end
								end
							else
								if self.Time.Asked > self.Time.Answered then --answer question
									if self.Sentence.IdleQuestioner ~= self:EntIndex() and
										self:Speak(self.Sentence.IdleAnswer, alone, can) then
										
										self.Time.Answered = CurTime()
									end
								else --ask question
									if self:Speak(self.Sentence.IdleQuestion, alone, can) then
										
										self.Sentence.IdleQuestioner = self:EntIndex()
										self.Time.Asked = CurTime()
									end
								end
							end
						end
					end
				end
				---------------
				
				self:ClearArrest()
				self:SetLook(false)
				self:Aim(self:WorldSpaceCenter() + self:GetForward())
				if not self.path then
					self:StartMove(nil, nil, {typeid = "idle"})
				end
				
				if self.Primary.Ammo < self.Primary.Clip or self.Secondary.Ammo < self.Secondary.Clip then
					self.havepistol = self.Primary.Ammo < self.Primary.Clip
					if not self.path then self:Escape(false, nil, true) end
					
					self.reloadflag = true
				end
				
				if not self.reloadflag and IsValid(self.Weapon) then
					self.Weapon:Remove()
				end
				
				for k, v in pairs(ents.FindInSphere(self:GetPos(), 200)) do
					if IsValid(v) and string.find(v:GetClass(), "grenade") then
						self:Escape(nil, v, false, nil, true)
					end
				end
			end
			
			self:MoveBehaviour()
			for k, v in pairs(ents.FindInSphere(self:GetEye().Pos, 60)) do
				if string.find(v:GetClass(), "door") then
					v:Input("Open", self, self)
					v:Input("OpenAwayFrom", self, self, self:GetClass())
					constraint.NoCollide(self, v, 0, 0)
				end
				if not SQUAD_MATES[v] and IsValid(v) and not v:IsPlayer() and self:Validate(v) ~= 0 then
					local ph = v:GetPhysicsObject()
					if ph and IsValid(ph) then
						ph:ApplyForceCenter((v:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() * 300)
					end
					if not (v:GetKeyValues().ExplodeRadius or v:GetKeyValues().ExplodeDamage) then
						v:TakeDamage(1, self, self)
					end
				end
			end
		end
		coroutine.yield()
	end
end
