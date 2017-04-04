--Unused nextbot AI that uses schedule system like HL2 NPCs.
AddCSLuaFile("shared.lua")
include('shared.lua')
include("schedules.lua")

for k, v in pairs(ENT.Sentence) do
	PrecacheSentenceGroup(v.name)
end

local ___DEBUG_DRAW_PATH = true
local ___DEBUG_DRAW_MOVEPOINT = false
local ___DEBUG_SEE = false
local ___DEBUG_SHOW_PATHNAME = false
local ___DEBUG_SHOW_SCHEDULENAME = false

--I guess using this is faster than ents.FindByClass("npc_supermetropolice")
SUPERPOLICE = SUPERPOLICE or {}
SUPERPOLICE_NUM = SUPERPOLICE_NUM or 0

local HEIGHT_STAND, HEIGHT_MOVE, HEIGHT_LOWERCOVER, HEIGHT_COVER, HEIGHT_CROUCH = 1, 2, 3, 4, 5

--++Entity base++-----------------{
--==Setters and Getters==---------{
-- function ENT:Use()
	-- self.TrueSniper = not self.TrueSniper
	-- self:SetWeaponInfo()
	-- PrintMessage(HUD_PRINTTALK, "Super Metropolices have been " .. (self.TrueSniper and "buffed!" or "nerfed."))
-- end

function ENT:GetAimVector()
	if self:GetEnemy() then
		return (self.Memory.EnemyPosition - self:GetMuzzle().Pos):GetNormalized()
	else
		return self:GetForward()
	end
end

function ENT:GetActiveWeapon()
	return IsValid(self.Weapon) and self.Weapon or nil
end

function ENT:GetMuzzle()
	return self:GetActiveWeapon() and
	self:GetActiveWeapon():GetAttachment(self:GetActiveWeapon():LookupAttachment("muzzle")) or
	self:GetAttachment(self:LookupAttachment("anim_attachment_RH"))
end

function ENT:GetHullType()
	return HULL_HUMAN
end

function ENT:GetRelationship(e)
	return D_HT
end
----------------------------------}
--==Initializing==----------------{
function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Look")
	self:NetworkVar("Entity", 0, "NetworkedEnemy")
end

--Sets the informations of primary and secondary weapon.
function ENT:SetWeaponInfo()
	self.Primary.Name = self.TrueSniper and "weapon_357" or "weapon_pistol" --Weapon classname
	self.Primary.Clip = self.TrueSniper and 6 or 18 --Clip size
	self.Primary.Num = self.TrueSniper and 1 or 1 --Amount of bullets per shot
	self.Primary.Spread = self.TrueSniper and 0 or 15 --Spread
	self.Primary.Damage = self.TrueSniper and 40 or 5 --Damage per bullets
	self.Primary.AmmoType = self.TrueSniper and "357" or "Pistol" --Ammo type
	self.Primary.Delay = self.TrueSniper and 0.8 or 0.4 --Fire rate
	self.Primary.ReloadSoundDelay = self.TrueSniper and 1.5 or 0.8 --Reloading sound delay
	self.Primary.MuzzleProbability = self.TrueSniper and 0.8 or 0.5 --Probability of emitting muzzle flash
	self.Primary.MuzzleScale = self.TrueSniper and 1 or 0.6 --Scale of muzzle flash
	self.Primary.Sound = self.TrueSniper and self.Primary.Sound1 or self.Primary.Sound2 --Shooting sound
	self.Primary.Reload = self.TrueSniper and self.Primary.Reload1 or self.Primary.Reload2 --Reloading sound
	self.Primary.Ammo = self.Primary.Clip --Ammo that the weapon now has
	
	self.Secondary.Name = self.TrueSniper and "weapon_shotgun" or "weapon_smg1"
	self.Secondary.Clip = self.TrueSniper and 6 or 45
	self.Secondary.Num = self.TrueSniper and 7 or 1
	self.Secondary.Spread = self.TrueSniper and 10 or 20
	self.Secondary.Damage = self.TrueSniper and 8 or 4
	self.Secondary.AmmoType = self.TrueSniper and "Shotgun" or "SMG1"
	self.Secondary.Delay = self.TrueSniper and 0.5 or 0.1
	self.Secondary.ReloadSoundDelay = self.TrueSniper and 0.5 or 0.6
	self.Secondary.MuzzleProbability = self.TrueSniper and 1 or 0.75
	self.Secondary.MuzzleScale = self.TrueSniper and 1 or 0.95
	self.Secondary.Sound = self.TrueSniper and self.Secondary.Sound1 or self.Secondary.Sound2
	self.Secondary.Reload = self.TrueSniper and self.Secondary.Reload1 or self.Secondary.Reload2
	self.Secondary.Ammo = self.Secondary.Clip
end

--Initialized the nextbot.
function ENT:Initialize()
	self.IsInitialing = true
	
	--Entity base-------------------
	self:SetModel("models/Police.mdl")
	self:SetHealth(self.MaxHealth)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:MakePhysicsObjectAShadow(true, true)
	self:SetMaxHealth(self.MaxHealth)
	self:SetUseType(SIMPLE_USE)
	self.loco:SetAcceleration(1200) --default: 400
	self.loco:SetDeceleration(5000) --default: 400
	self.loco:SetStepHeight(self.StepHeight) --default: 18
	self.loco:SetJumpHeight(self.JumpHeight) --default: 58
	self.loco:SetDeathDropHeight(200)--default: 200
	self.loco:SetMaxYawRate(300)
	self:StartActivity(self.Idle)
	self:XorInit(CurTime())
	
	self.TrueSniper = game.GetSkillLevel() > 2
	--------------------------------
	
	--Sensors-----------------------
	self.Sensor = {}
	self.Sensor.breakable_filter = ents.FindByClass("func_breakable") --See through breakable things.
	table.Add(self.Sensor.breakable_filter, ents.FindByClass("func_breakable_surf"))
	table.insert(self.Sensor.breakable_filter, self)
	--------------------------------
	
	--Personal memories-------------
	self.Memory = {}
	self.Memory.Enemy = nil --Target entity.
	self.Memory.DangerEntity = nil --An entity that I should run away from.
	self.Memory.Distance = 0 --Distance from myself to the enemy.
	self.Memory.Brave = 10 --If I have low health, I'm more likely to escape from the enemy
	self.Memory.Killstreak = 0 --Counting how many kills I have.
	self.Memory.AimAttach = 1 --Aiming at attachment, if I couldn't find the enemy's head.
	self.Memory.EnemyPosition = self:GetEye().Pos --I know his last position I've seen.
	self.Memory.FaceEnemy = false --Whether or not I face towards enemy position.
	self.Memory.Look = false --If I can see my enemy.
	self.Memory.Shoot = false --If I can shoot my enemy.
	self.Memory.Enemies = {} --Enemy pool
	--------------------------------
	
	--Times-------------------------
	self.Time = {
		Saw = CurTime(),			--saw the enemy
		Threw = CurTime(),			--threw grenade
		Moved = CurTime(),			--started moving
		Fired = CurTime(),			--fired weapon
		Reload = CurTime(),			--reloaded weapon while moving
		Stuck = CurTime(),			--lua-defined stack flag
		LookBack = CurTime(),		--looked behind the nextbot
		Damage = CurTime(),			--took damage
		DamageRepeated = CurTime(),	--took damage repeatedly
		Schedule = CurTime(),		--time of beginning schedule
		Task = CurTime(),			--began new task
		Spoke = CurTime(),			--sentence spoke
		SpokeOthers = CurTime(),	--sentence spoke for allies
		Requested = CurTime(),		--idle speaking; requested report **** unused ****
		Reported = CurTime(),		--idle speaking; reported
		Asked = CurTime(),			--idle speaking; asked question
		Answered = CurTime(),		--idle speaking; answered question
		Arrest = CurTime(),			--arrest behaviour; time to shoot **** unused ****
	}
	--------------------------------
	
	--Weapons and equipments--------
	self:SetWeaponInfo()
	self.Weapon = nil --Weapon entity
	self.Equipment = {}
	self.Equipment.IsPrimary = false --Holding a primary weapon.
	self.Equipment.Weapon = self.Primary --Weapon what I have now.
	--------------------------------
	
	--Path finding------------------
	self.Path = {}
	self:ClearPath()
	--------------------------------
	
	--Communication-----------------
	SUPERPOLICE[self] = self
	SUPERPOLICE_NUM = SUPERPOLICE_NUM + 1
	self.Squad ={}
	self.Squad.Leader = nil --For receiving operations.
	self.Squad.SaidLightDamage = false --Set true if I speak light damage sentence.
	self.Squad.SaidHeavyDamage = false --I speak heavy damage sentence.
	--------------------------------
	
	--Conditions--------------------
	self.State = self.State or {}
	self.State.Previous = {}
	self.State.Previous.HaveEnemy = nil --Detecting the enemy went null or dead.
	self.State.Previous.Health = self:GetMaxHealth() --Detecting damage.
	self.State.Previous.Path = false --Hook for finished moving.
	self.State.Previous.FailSchedule = nil --Recently failed schedule.
	self.State.Task = "" --The current task name.
	self.State.TaskParam = nil --The parameter of the current task.
	self.State.TaskDone = nil --True if the current task is done.
	self.State.State = NPC_STATE_IDLE --The nextbot is idle.
	self.State.Schedule = nil --Current shcedule name.
	self.State.ScheduleProgress = nil --Current task offset.
	self.State.Task = nil --Current task name.
	self.State.TaskParam = nil --Current task parameter.
	self.State.Build = function(self)
		local s = NPC_STATE_IDLE
		if self:GetEnemy() then
			s = NPC_STATE_COMBAT
		elseif self:GetState() == NPC_STATE_ALERT or
			self:HasCondition("LostEnemy") or
			self:HasCondition("EnemyDead") then
			s = NPC_STATE_ALERT
		end
		if s ~= self:GetState() then self.State.ScheduleProgress = #self.Schedule[self:GetSchedule()] + 1 end
		self:SetState(s)
	end
	
	self.State.GetDanger = function(self)
		local e = 0 --Detect dangerous thing
		local sentence = self.Sentence.DangerGeneral
		local escapefrom
		for k, v in pairs(ents.FindInSphere(self:GetPos(), self.NearDistance)) do
			if IsValid(v) then
				local dist = (v:GetPos() - self:WorldSpaceCenter()):LengthSqr()
				if self:Validate(v) == 0 and self:CanSee(self:GetTargetPos(false, v)) then
					e = (v:GetForward():Dot((self:GetPos() - v:GetPos()):GetNormalized()) > 0.75)
						and e + 2 or e + 1
				elseif dist < self.NearDistanceSqr and --Grenade is near, take cover
					string.find(v:GetClass(), "grenade") and (v.GetOwner and IsValid(v:GetOwner())
					and not SUPERPOLICE[v:GetOwner()]) then
					
					e = self.Memory.Brave + 1
					escapefrom = v
					sentence = self.Sentence.DangerGrenade
				elseif dist < self.NearDistanceSqr / 64 and string.find(v:GetClass(), "manhack") then
					e = self.Memory.Brave + 1
					sentence = self.Sentence.DangerManHack
				elseif v:IsVehicle() and v:GetSpeed() > 15 and --vehicle incoming
					v:GetVelocity():GetNormalized():Dot((self:WorldSpaceCenter() - 
					v:WorldSpaceCenter()):GetNormalized()) > 0.65 then
					
					e = self.Memory.Brave + 1
					sentence = self.Sentence.DangerVehicle
				end
				
				if self.Memory.Brave < e then break end
			end
		end
		
		if self:XorRand(0, self.Memory.Brave) < e then
			self:Speak(sentence, self:CanSpeak())
			return true, escapefrom
		end
	end
	self:SetSchedule("Idle")
	--------------------------------
	
	self.IsInitialing = nil
end
----------------------------------}
----------------------------------}
--++Personal Memories++-----------{
--Gets personal enemy entity.
function ENT:GetEnemy()
	if self:Validate(self.Memory.Enemy) ~= 0 then return nil end
	return self.Memory.Enemy
end

--Sets personal enemy memory.
function ENT:SetEnemy(ent)
--	if not IsValid(self.Enemy) then
--		sentence = self:SpeakClassify(ent)
--		self:Speak(sentence, self:CanSpeak())
--	end
	
	self.Memory.Enemy = ent
	self:SetNetworkedEnemy(ent)
	self.Memory.EnemyPosition = self:GetTargetPos()
	self.Memory.Distance = self:GetRangeTo(self.Memory.EnemyPosition)
	self.Memory.AimAttach = 1
end

--Adds the given condition.
--Arguments:
--string c | Condition.
--Bool state | Set condition state manually.
function ENT:AddCondition(c, state)
	if not self.Condition[c] then return end
	self.State[self.Condition[c]] = not isbool(state) or state
end

--Removes a condition.
--Argument: string c | Condition.
function ENT:RemoveCondition(c)
	if not self.Condition[c] then return end
	self.State[self.Condition[c]] = nil
end

--Removes all conditions.
function ENT:RemoveAllConditions()
	for i, c in pairs(self.Condition) do
		self.State[c] = nil
	end
end

--Returns if the nextbot has the given condition.
--Argument: number c | Condition.
function ENT:HasCondition(c)
	if not self.Condition[c] then return end
	return self.State[self.Condition[c]]
end

--Changes the state. Idle/Alert/Combat
--Argument: number s | New state.
function ENT:SetState(s)
	self.State.State = s
end

--Gets the state. Idle/Alert/Combat
function ENT:GetState()
	return self.State.State
end

--Starts the given schedule.
--Argument: Table s | Schedule.
function ENT:SetSchedule(s)
	if not istable(self.Schedule[s]) then return end
	self.State.Schedule = s --Schedule now executing.
	self.State.ScheduleProgress = 1
	self.Time.Schedule = CurTime()
	self.Time.Task = CurTime()
	self:ResetPoseParameters()
	if GetConVar("developer"):GetInt() > 0 and ___DEBUG_SHOW_SCHEDULENAME then print(self, "Set a schedule: " .. s) end
	if isfunction(self.Schedule[s].Init) then
		self.Schedule[s].Init(self)
	end
	return true
end

--Gets the schedule which is executing.
function ENT:GetSchedule()
	return self.State.Schedule, self.State.ScheduleProgress
end

--Sets current task.
function ENT:SetTask(t, tp)
	if not istable(self.Task[t]) then return end
	self.State.Task = t
	self.State.TaskParam = tp
	return true
end

--Gets current task.
function ENT:GetTask()
	return self.State.Task, self.State.TaskParam
end
----------------------------------}
--++Inputs++----------------------{
--==Hooks==-----------------------{
--Called when police heard something.
--Arguments:
----Entity self | myself.
----Table t | Sound informations.
local function OnHearSound(self, t)
	--TODO: Tell other mates to alert
	local f = self:Validate(t.Entity) == 0
	if f or self:XorRand() < 0.05 then
		self:Speak(self.Sentence.Heard, self:CanSpeak())
	end
	if f then
		self.Memory.Enemies[t.Entity] = {
			Pos = t.Entity:GetPos(),
			Distance = t.Entity:GetPos():DistToSqr(self:GetPos()),
			Forward = t.Entity:GetForward()}
	end
end

--Receiving serverside sound.
hook.Add("EntityEmitSound", "SuperMetropoliceHearSound", function(t)
	if not IsValid(t.Entity) then return end
	for v in pairs(SUPERPOLICE) do
		if t.Entity == v then return end
		if IsValid(v) and v:IsHearingSound(t) then
			OnHearSound(v, t)
		end
	end
end)

--Receiving clientside sound.
util.AddNetworkString("SuperMetropoliceHearSound")
net.Receive("SuperMetropoliceHearSound", function(len, ply)
	local bot = net.ReadEntity()
	local t = net.ReadTable()
	if IsValid(bot) and IsValid(t.Entity) and SUPERPOLICE[bot] then
		OnHearSound(bot, t)
	end
end)

--The nextbot hates everyone and no one likes it.
hook.Add("OnEntityCreated", "SuperMetropoliceIsAlone!", function(e)
	if IsValid(e) and e:GetClass() ~= "npc_supermetropolice" then
		local t = "SuperMetropolice_target" .. e:EntIndex()
		if isfunction(e.AddEntityRelationship) then
			timer.Create(t, 1, 0, function()
				if not IsValid(e) then timer.Remove(t) return end
				for v in pairs(SUPERPOLICE) do
					if IsValid(v) then
						e:AddEntityRelationship(v, D_HT, 0)
					end
				end
			end)
		end
		
	--	if isfunction(e.AddRelationship) then
	--		timer.Create(t .. "relationstring", 1.31, 0, function()
	--			if not IsValid(e) then timer.Remove(t .. "relationstring") return end
	--			e:AddRelationship("npc_supermetropolice D_HT 0")
	--		end)
	--	end
	end
end)

--Called when the nextbot touches another entity.
--Applies the physics damage.
--Argument: Entity v | The entity the nextbot came in contact with.
function ENT:OnContact(v)
	if not IsValid(v) then return end
	if v:IsPlayer() or v:IsNPC() or v.Type == "nextbot" then return end
	local p = v:GetPhysicsObject() if not IsValid(p) then return end
	local f = -p:GetVelocity()
	
	p:SetVelocityInstantaneous(vector_origin)
	p:ApplyForceCenter(f)
	
	local e, division = p:GetEnergy(), 2.0 * 10e+6 if e < division then return end
	if v:IsVehicle() then e = v:GetSpeed() * division end
	local d, attacker = DamageInfo(), v:GetPhysicsAttacker()
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
	SUPERPOLICE[self] = nil
	SUPERPOLICE_NUM = SUPERPOLICE_NUM - 1
	if SUPERPOLICE_NUM < 0 then SUPERPOLICE_NUM = 0 end
	
	if self:GetActiveWeapon() then self:GetActiveWeapon():Remove() end
end

function ENT:OnOtherKilled(e, info)
	local alone, can, sentence = self:CanSpeak(), nil
	
	if info:GetAttacker() == self then
		self.Memory.Killstreak = self.Memory.Killstreak + 1
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
	if CurTime() > self.Time.Damage + 3 then
		self.Time.DamageRepeated = CurTime()
	end
	self.Time.Damage = CurTime()
	
	local sentence = self.Sentence.Pain
	if self:Health() - info:GetDamage() <= 0 then
		sentence = self.Sentence.Dying
	elseif not self.Squad.SaidPainLight and self:Health() - info:GetDamage() > 0.9 * self:GetMaxHealth() then
		sentence = self.Sentence.PainLight
		self.Squad.SaidPainLight = true
	elseif not self.Squad.SaidPainHeavy and self:Health() - info:GetDamage() < 0.25 * self:GetMaxHealth() then
		sentence = self.Sentence.PainHeavy
		self.Squad.SaidPainHeavy = true
	end
	self:Speak(sentence, self:CanSpeak(self:XorRand() > self:Health() / self:GetMaxHealth()))
	
	if self.Equipment.IsPrimary and (info:GetDamagePosition() - 
		info:GetReportedPosition()):GetNormalized():Dot(self:GetForward()) < -0.7 then
		self:ClearPath()
		self.Time.Moved = CurTime() + self:XorRand(0.2, 0.3)
		self:AddGestureSequence(self:LookupSequence("flinch_back1"))
	else
		if tr.Entity == self then --Always do a flinch animation. TODO: do it when I take a high-impact damage.
			local gr = tr.HitGroup
			local flinch = {
				[HITGROUP_HEAD] = "flinchheadgest" .. math.random(1, 2),
				[HITGROUP_STOMACH] = "flinchgutgest1" .. math.random(1, 2),
				[HITGROUP_LEFTARM] = "flinchlarmgest",
				[HITGROUP_RIGHTARM] = "flinchrarmgest",
			}
			if flinch[gr] then
				self:AddGestureSequence(self:LookupSequence(flinch[gr]))
			elseif self.Equipment.IsPrimary and info:GetDamage() > self:GetMaxHealth() / 4 then
				self:ClearPath()
				self.Time.Moved = CurTime() + self:XorRand(0.2, 0.3)
				self:AddGestureSequence(self:LookupSequence("flinch2"))
			else
				self:AddGesture(ACT_GESTURE_SMALL_FLINCH)
			end
		end
	end
	
	if self.Memory.Brave > 5 then self.Memory.Brave = self.Memory.Brave * 0.6 end
	if info:IsDamageType(DMG_BURN) or self:Validate(info:GetAttacker()) ~= 0 then return end
	
	self.Memory.Enemies[info:GetAttacker()] =
		{Pos = info:GetAttacker():GetPos(),
		 Distance = info:GetAttacker():GetPos():DistToSqr(self:GetPos()),
		 Forward = info:GetAttacker():GetForward()}
--	if not (self:GetEnemy() and self.Memory.Look) or 
--		self:GetEnemy():GetPos():DistToSqr(self:GetPos()) >
--		info:GetAttacker():GetPos():DistToSqr(self:GetPos()) then
--		
--		self:SetEnemy(info:GetAttacker())
--	end
end

function ENT:OnKilled(info)
	hook.Call("OnNPCKilled", GAMEMODE, self, info:GetAttacker(), info:GetInflictor())
	if self:GetActiveWeapon() then
		local w = ents.Create(self:GetActiveWeapon():GetClass())
		w:SetPos(self:GetActiveWeapon():GetPos())
		w:SetAngles(self:GetActiveWeapon():GetAngles())
		w:SetAbsVelocity(self:GetActiveWeapon():GetAbsVelocity())
		w:Spawn()
		self:GetActiveWeapon():Remove()
	end
	self:BecomeRagdoll(info)
	self:OnRemove()
	
	if GetConVar("supermetropolice_showkillstreak"):GetBool() then
		PrintMessage(HUD_PRINTTALK, "Super Metropolice got "
		 .. self.Memory.Killstreak .. " kill"
		 .. (self.Memory.Killstreak == 1 and "." or "s."))
	end
end
----------------------------------}
--==Sensors==---------------------{
--Finds nearest enemy and returns it.
function ENT:FindEnemy()
	local lst = ents.FindInSphere(self:GetEye().Pos, self.FarDistance)
	local pos, dist, pool, nearestenemy, e, sentence = math.huge, math.huge, {}
	
	for k, v in pairs(lst) do
		e = self:Validate(v)
		if e == 0 and (v:GetPos() - self:GetEye().Pos):GetNormalized():Dot(self:GetEye().Ang:Forward())
			> math.cos(math.rad(self.SearchAngle)) then
			pos = self:GetTargetPos(false, v)
			dist = self:GetRangeSquaredTo(v:GetPos())
			if self:CanSee(pos) then --normal entity and can see
				self.Memory.Enemies[v] = {Pos = pos, Distance = dist, Forward = v:GetForward()}
			end
		end
	end
	
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		if self:Validate(k) ~= 0 or 
			(self:CanSee(v.Pos) and not self:CanSee(self:GetTargetPos(false, k))) then
			self.Memory.Enemies[k] = nil
		end
	end
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		if IsValid(k) then return k end --Get the nearest enemy.
	end
end

--Returns if a position is visible.
--Arguments:
----Vector pos | The end position of the trace.
----Table opt | Options.
------Vector start | The start position of the trace.
------Bool shoot | If true, check MASK_SHOT in place of visiblity.
function ENT:CanSee(pos, opt)
	local opt = opt or {}
	local e = pos or self.Memory.EnemyPosition
	--TODO: If mask = MASK_SHOT, check if FilterTable isn't needed.
	local FilterTable = table.Copy(self.Sensor.breakable_filter)
	table.insert(FilterTable, self:GetActiveWeapon())
	local tr = util.TraceLine({
		start = opt.start or self:GetEye().Pos,
		endpos = e,
		filter = FilterTable,
		mask = opt.shoot and MASK_SHOT or MASK_BLOCKLOS_AND_NPCS,
	})
	if ___DEBUG_SEE then
		debugoverlay.Line(tr.StartPos, tr.HitPos, 3, Color(0, 255, 0, 255), false)
	end
	return not tr.StartSolid and not tr.HitWorld and tr.HitPos:DistToSqr(e) < 100e+2
end
----------------------------------}
----------------------------------}
--++Outputs++---------------------{
--==Path finding==----------------{
--Returns a table that contain suggestions to move to.
--Arguments:
----Vector beginpos | Position to search around.
----Vector targetpos | Position that an evaluation function uses.
----number radius | Radius to search within.
----number navmaxnum | Max amount of checking NavAreas.
----number up | Check LOS from this height.
----function evaluation | The evaluation function.
------Arguments:
--------Nextbot self | Myself.
--------Vector navpos | Position of NavArea.
--------Vector targetpos | Position where self is looking at.
--------Bool visible | Result of CNavArea:IsVisible(targetpos).
------Returns:
--------true  | Add found position.
--------false | Add alternative position.
--------nil   | Don't add.
function ENT:FindPosition(beginpos, targetpos, radius, navmaxnum, up, evaluation)
	if self.Path.Main:IsValid() or CurTime() < self.Time.Moved then return end
	
	local target, found, alt = nil, {}, {}
	local radius = radius or 2000
	local navmaxnum = navmaxnum or 400
	local p, visible, valid = Path("Follow")
	local spots = navmesh.Find(beginpos, radius, self.loco:GetDeathDropHeight(), 0)
	local evaluation = evaluation or function(self, navpos, targetpos)
		local see = self:CanSee(targetpos, {start = navpos, shoot = true})
		if see then
			local distance = targetpos:DistToSqr(self:GetPos())
			local d1 = targetpos:DistToSqr(navpos)
			local d2 = self:GetPos():DistToSqr(navpos)
			
			if d2 < d1 then
				if distance < d1 then return true
				elseif distance < d1 * 0.7 then return false end
			end
		end
		return nil
	end
	
	for k, n in pairs(spots) do
		if k > navmaxnum then break end
		visible, pos = n:IsVisible(targetpos)
		pos = n:GetRandomPoint() + vector_up * (up or (self:GetMuzzle().Pos.z - self:GetPos().z))
	--	debugoverlay.Line(pos, targetpos, 5)
		valid = evaluation(self, pos, targetpos, visible)
		if valid ~= nil then
			p:Invalidate()
			p:Compute(self, pos)
			if valid then
				if ___DEBUG_DRAW_MOVEPOINT then debugoverlay.Line(pos, pos - vector_up * 55, 5, Color(0,255,0,255)) end
				table.insert(found, {vec = pos, len = p:GetLength()})
			else
				table.insert(alt, {vec = pos, len = p:GetLength()})
			end
		end
	end
	
	if #found > 0 then
		table.SortByMember(found, "len", true)
		return found
	elseif #alt > 0 then
		table.SortByMember(alt, "len", true)
		return alt
	end
end

--Clear stuck status
function ENT:ClearStuck()
	self.Time.Stuck = nil --first stuck detected
	self.Path.Stuck = nil --lua-defined stuck flag
	self.Path.StuckCalled = 0 -- +1 every HandleStuck() called
	self.Path.Alt:Invalidate() --do alternative path to avoid stucking
	self.Path.PreviousPosition = self:GetPos() --to detect stopping
end

--Reset path status.
function ENT:ClearPath()
	if self.Path.Main then
		self.Path.Main:Invalidate()
	else
		self.Path.Main = Path("Follow") --Path object.  Move along this
	end
	if self.Path.Alt then
		self.Path.Alt:Invalidate()
	else
		self.Path.Alt = Path("Follow") --Alternative path object to avoid stucking
	end
	if self.Path.SquadFollow then
		self.Path.SquadFollow:Invalidate()
	else
		self.Path.SquadFollow = Path("Chase") --Path for following squad leader.
	end
	self.Path.Approaching = nil --Using self.loco:Approach() behaviour.
	self.Path.Cease = nil --Function to determine to stop moving.
	self.Path.OverwriteLevel = 1 --Priority of path.
	self.Path.Goal = self:GetPos() --Current goal.
	self.Path.Tolerance = 10 --At last segment, set this tolerance.
	self.Path.ForceRun = false --Run to position.
	self:ClearStuck()
	self.loco:ClearStuck()
end

--Start moving to specified position.
--Arguments:
----Vector moveto | The position to move to.
----Table opt | Table that contains options.
------number tolerance | How close we can get to the goal to call it done.
------number lookahead | The minimum range movement goal must be along path.
------number overwrite | Level of overwriting the main path.
------string movetype | For debugging; type of movement.
function ENT:StartMove(moveto, opt)
    local opt = opt or {}
    if  CurTime() < self.Time.Moved or
	((opt.overwrite or 0) < self.Path.OverwriteLevel and self.Path.Main:IsValid()) then
		return "invalid"
	end
	self.Time.Moved = CurTime() + self:XorRand(0.5, 1)
	
	self.Path.Main:Invalidate()
	self.Path.Goal = moveto
	--Check if the position is traversable--
	local n = navmesh.Find(self.Path.Goal, 1, self.loco:GetDeathDropHeight(), self.loco:GetStepHeight())
	for k, v in pairs(n) do
		if not self.loco:IsAreaTraversable(v) then --available in the next update.
			if opt.overwrite > self.Path.OverwriteLevel then self:ClearPath() end
			return "invalid"
		end
	end
	----------------------------------------
	
	self:ClearStuck()
	self.Path.ForceRun = opt.run
	self.Path.OverwriteLevel = (opt.overwrite or 0) + 1
	self.Path.Tolerance = opt.tolerance or 25
	self.Path.Main:SetMinLookAheadDistance(opt.lookahead or 100)
	self.Path.Main:SetGoalTolerance(10)
	local valid = self.Path.Main:Compute(self, self.Path.Goal)
	if not valid then 
		self.Path.Approaching = true
		return "invalid"
	end
	if GetConVar("developer"):GetInt() > 0 and ___DEBUG_SHOW_PATHNAME then print(self, "Movetype: " .. (opt.movetype or "unknown")) end
	return "ok"
end

--Advances to the enemy.
function ENT:Advance()
	local found = self:FindPosition(
	self:GetPos(), self.Memory.EnemyPosition, nil, nil, nil, function(self, navpos, targetpos)
		local see = self:CanSee(targetpos, {start = navpos, shoot = true})
		if see then
			local distance = targetpos:DistToSqr(self:GetPos())
			local d1 = targetpos:DistToSqr(navpos)
			local d2 = self:GetPos():DistToSqr(navpos)
			
			if d2 < d1 then
				if distance < d1 then return true
				elseif distance < d1 * 0.4 then return false end
			end
		end
		return nil
	end)
	
	if found then
		self:StartMove(found[1].vec, {run = true, movetype = "advance"})
	end
end

--Appears in front of the enemy.
function ENT:Appear()
	local found = self:FindPosition(self:GetPos(), self.Memory.EnemyPosition)
	
	if found then
		self:StartMove(found[1].vec, {run = true, movetype = "snipe"})
	elseif self:XorRand() < 0.5 then
		self:StartMove(self.Memory.EnemyPosition, {run = true, movetype = "snipe_alt"})
	end
end

--Hide the nextbot from the enemy.
--Arguments:
----Entity ent | To hide from specified entity.
----Bool far | Sets true to move far away.
----number overwrite | Level of overwrite the current path.
function ENT:Escape(ent, far, overwrite)
	local e = IsValid(ent) and self:GetTargetPos(false, e) or self.Memory.EnemyPosition
	local found = self:FindPosition(self:GetPos(), self.Memory.EnemyPosition, 5000, nil,
		self.Height.Eye[HEIGHT_CROUCH], function(self, navpos, targetpos)
		local see = self:CanSee(targetpos, {start = navpos, shoot = true})
		if not see then
			local distance = targetpos:DistToSqr(self:GetPos())
			local d1 = targetpos:DistToSqr(navpos)
			local d2 = self:GetPos():DistToSqr(navpos)
			
			if d2 < d1 then
				if distance < d1 then return true
				elseif distance < d1 * 0.5 then return false end
			end
		end
		return nil
	end)
	
	if found then
		local n = far and math.ceil(#found / 2) or (#found > 3 and 3 or 1)
	--	debugoverlay.Line(found[n].vec, found[n].vec - vector_up * 55, 5, Color(0,255,0,255))
		self:StartMove(found[n].vec, {run = true, overwrite = overwrite, movetype = "esc"})
	else
		self:StartMove(self:GetPos() + self:GetRight() * self:XorRand(-400, 400), 
		{run = true, overwrite = overwrite, movetype = "esc_alt"})
	end
end

--Search a position where I can't see the enemy from my leg but can from my eye.
function ENT:SearchCover()
	local found = self:FindPosition(self:GetPos(), self.Memory.EnemyPosition, 1500, 150,
	self:WorldSpaceCenter().z - self:GetPos().z, function(self, navpos, targetpos)
		local dz = self:WorldSpaceCenter().z - self:GetPos().z
		local start_eye = navpos + vector_up * dz / 2
		local see_body = self:CanSee(targetpos, {start = navpos, shoot = true})
		local see_eye = self:CanSee(targetpos, {start = start_eye, shoot = true})
		if not see_body and see_eye then
			local distance = targetpos:DistToSqr(self:GetPos())
			local d1 = targetpos:DistToSqr(navpos)
			local d2 = self:GetPos():DistToSqr(navpos)
			
			if d2 < d1 then
				if distance < d1 then return true
				elseif distance < d1 * 0.5 then return false end
			end
		end
		return nil
	end)
	
	if found then
		self:StartMove(found[1].vec, {run = true, movetype = "cover"})
	end
end
----------------------------------}
--==Around weapons==--------------{
local function GetTossVec(self, v1, v2, pow, high)
	local tr
	local vMidPoint --halfway point between v1 and v2
	local vApex --highest point
	local vScale, velocity, vTemp
	local g = GetConVar("sv_gravity"):GetFloat() -- * gravity_adjust
	
	local mul = (0.875 / 2) * (pow / (v2 - v1):Length())^1.02 --multiplier of power
	local n = vector_up--(v1 - v2):Cross(self:GetRight()):GetNormalized() -- normal vector of parabola
	
--	if v1.z > v2.z + (pow * (500 / 650)) then return end --to high, fail
	
	-- toss a little bit to the left or right, not right down on the enemy's bean (head).
	v2.x = v2.x + self:XorRand(-8, 8)
	v2.y = v2.y + self:XorRand(-8, 8)
	
	-- How much time does it take to get there?
	-- get a rough idea of how high it can be thrown
	vMidPoint = util.QuickTrace(v1 + (v2 - v1) * 0.5, n * high, self).HitPos
	-- (subtract 15 so the grenade doesn't hit the ceiling)
	vMidPoint.z = vMidPoint.z - 15
	
	if (vMidPoint.z < v1.z) or (vMidPoint.z < v2.z) then return end --to not enough space, fail
	
	-- How high should the grenade travel to reach the apex
	local d1 = vMidPoint.z - v1.z
	local d2 = vMidPoint.z - v2.z
	
	-- How long will it take for the grenade to travel this distance
	local t1 = math.sqrt(2 * d1 / g)
	local t2 = math.sqrt(2 * d2 / g)
	
	if t1 < 0.1 then return end --too close
	
	-- how hard to throw sideways to get there in time.
	velocity = ((v2 - v1) / (t1 + t2)) * mul * 1.05
	-- how hard upwards to reach the apex at the right time.
	velocity = velocity + n * g * t1 * mul
	
	
	-- find the apex
	vApex = vMidPoint
	vApex = vApex - n * (high * 0.15)
	
--	debugoverlay.Line(v1, vApex, 3, Color(255,255,0,255),true)
--	debugoverlay.Line(v2, vApex, 3, Color(255,255,0,255),true)
	tr = util.TraceLine({start = v1, endpos = vApex, filter = self})
	if tr.Fraction ~= 1.0 then return end --fail
	
	-- UNDONE: either ignore monsters or change it to not care if we hit our enemy
	tr = util.TraceLine({start = v2, endpos = vApex, filter = self, mask = MASK_NPCSOLID_BRUSHONLY})
	if tr.Fraction ~= 1.0 then return end --fail
	
	velocity.x = velocity.x * 2
	velocity.y = velocity.y * 2
	return velocity, t1 + t2
end

local function GetThrowVec(self, v1, v2, pow)
	local g = GetConVar("sv_gravity"):GetFloat()
	local velocity = v2 - v1
	local mul = (0.29 / 2) * (pow / velocity:Length())
	
	--throw at a constant time
	local time = velocity:Length() / 1000
	velocity = velocity:GetNormalized() * pow
	
	--adjust upward toss to compensate for gravity loss
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
	if self.Memory.Distance < self.NearDistance / 2 then return end
	if IsValid(navmesh.GetNearestNavArea(self:GetPos())) and 
		navmesh.GetNearestNavArea(self:GetPos()):GetAdjacentCount() < 6 then return end
	
	local att = "anim_attachment_LH"
	local p = self:GetAttachment(self:LookupAttachment(att))
	local throwVec = self.Memory.EnemyPosition - p.Pos
	local tr = self:CanSee(self.Memory.EnemyPosition)
	local time, seq, wait = 3.5, tr and "grenadethrow" or "deploy", tr and 0.8 or 1
	
	if tr then
		local pow = self.Memory.Distance * 2
		throwVec, time = GetThrowVec(self, p.Pos, self.Memory.EnemyPosition, pow, 50)
	else
		local tosshigh, pow = 1000, self.Memory.Distance * 2
		tr = util.QuickTrace(p.Pos, vector_up * tosshigh, self)
		tr = tosshigh * tr.Fraction --if tr.Fraction ~= 1.0 then return end
		throwVec, time = GetTossVec(self, p.Pos, self.Memory.EnemyPosition, pow, tr)
	end
	
	if not throwVec then return end
--	debugoverlay.Line(self.lastsaw, self:GetEye().Pos, 2, Color(0,255,0,255),true)
--	debugoverlay.Line(p.Pos, p.Pos + throwVec, 2, Color(0,255,0,255),true)
	
	timer.Simple(wait, function()
		if not IsValid(self) then return end
		local ent = ents.Create("npc_grenade_frag")
		ent:Input("settimer",self, self, time)
		ent:SetPos(self:GetAttachment(self:LookupAttachment(att)).Pos)
		ent:SetAngles(self:GetAttachment(self:LookupAttachment(att)).Ang)
		ent:SetOwner(self)
		ent:SetSaveValue("m_hThrower", self)
		ent:Spawn()
		
		local phys = ent:GetPhysicsObject()
		phys:ApplyForceCenter(throwVec)
		phys:AddAngleVelocity(VectorRand() * 1000)
		phys:AddAngleVelocity(VectorRand() * 1000)
		
		timer.Simple(time / 2, function()
			if not IsValid(ent) then return end
			ent:AddCallback("OnAngleChange", function(ent, ang)
				if IsValid(ent.Owner) and IsValid(ent.Owner:GetEnemy()) then
					if ent.Owner.TrueSniper then
						local phys = ent:GetPhysicsObject()
						local pos = ent.Owner:GetTargetPos()
						phys:ApplyForceCenter((pos - phys:GetPos()) * phys:GetPos():DistToSqr(pos) / 10)
					elseif not ent:IsOnFire() then
						ent:Ignite(0.1, 0)
					end
				end
			end)
		end)
	end)
	
	self:RemoveAllGestures()
	self:ClearPath()
	self:ClearStuck()
	self:StartActivity(self.Idle)
	self.Time.Threw = CurTime() + 8 + self:XorRand(-1, 1)
	self:PlaySequenceAndWait(seq)
end

function ENT:FireWeapon()
	if CurTime() < self.Time.Fired or not (self.Memory.Shoot and 
		self:GetEnemy() and self:GetActiveWeapon()) then return end
	if self:GetActiveWeapon():GetForward():Dot(self:GetAimVector()) < 0.8 then
		return
	end
	if self:GetActiveWeapon():GetNoDraw() then self:GetActiveWeapon():SetNoDraw(false) end
	local WeaponInfo = self.Equipment.Weapon
	if WeaponInfo.Ammo <= 0 then return end
	
	local wep, shootPos = self:GetActiveWeapon(), self:GetMuzzle().Pos
	local delay = math.Clamp(WeaponInfo.Delay + self:XorRand(-0.1, 0.1), 0.05, 3)
	
	self:AddGesture(WeaponInfo.Act)
	wep:EmitSound(WeaponInfo.Sound)
	WeaponInfo.Ammo = WeaponInfo.Ammo - 1
	
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
			
			--Speak suspect-is-hurt sentence--
			local health, maxhealth = tr.Entity:Health(), tr.Entity:GetMaxHealth()
			if health <= 0 then health = 1 end
			if maxhealth <= 0 then maxhealth = 1 end
			local speak_flag = health * 4 / maxhealth
			
			if c == "npc_turret_floor" then
				tr.Entity:Fire("SelfDestruct")
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
	
	local ef, eject = EffectData(), nil
	ef:SetOrigin(shootPos)
	ef:SetAngles(self:GetMuzzle().Ang)
	ef:SetScale(WeaponInfo.MuzzleScale)
	ef:SetEntity(wep)
	ef:SetEntIndex(wep:EntIndex())
	ef:SetAttachment(wep:LookupAttachment("muzzle"))
	if self:XorRand() < WeaponInfo.MuzzleProbability then
		util.Effect("MuzzleEffect", ef)
	end
	
	if self.Equipment.IsPrimary then
		if not self.TrueSniper then
			eject = "ShellEject"
		end
	else
		if self.TrueSniper then
			eject = "ShotgunShellEject"
		else
			eject = "RifleShellEject"
		end
	end
	
	if eject then
		ef:SetAngles(self:GetMuzzle().Ang - Angle(0, 90, 0))
		ef:SetOrigin(shootPos - self:GetMuzzle().Ang:Forward() * 8)
		ef:SetStart(self:GetRight())
		util.Effect(eject, ef)
	end
end

--Gives a weapon.
--Arguments:
----Bool class | The weapon class.  true: primary, false: secondary, nil: melee
function ENT:Give(class)
	self.Equipment.IsPrimary = class
	self.Equipment.Weapon = self.Equipment.IsPrimary and self.Primary or self.Secondary
	if class == nil then class = "weapon_stunstick" else
	class = class and self.Primary.Name or self.Secondary.Name end
	
	local isfirstdeploy = true
	if self:GetActiveWeapon() then
		if self:GetActiveWeapon():GetClass() == class then return end
		self:GetActiveWeapon():Remove()
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
	wep:SetMoveType(MOVETYPE_NONE)
	wep:SetGravity(0)
	wep:SetParent(self)
	wep:Fire("SetParentAttachment", att)
	wep:AddEffects(EF_BONEMERGE)
	wep:Spawn()
	
	local e = EffectData()
	e:SetEntity(self)
	util.Effect("supermetropolice_weaponspawn", e)
	self.Weapon = wep
	
	local laser = EffectData()
	laser:SetEntity(wep)
	util.Effect("supermetropolice_lasersight", laser)
	
	if isfirstdeploy and class == self.Primary.Name then
		wep:SetNoDraw(true)
		wep:DrawShadow(false)
		
		local bLooking = self.Memory.Look
		self.Memory.Look = false
		timer.Simple(0.8, function()
			if IsValid(wep) then
				wep:SetNoDraw(false)
				wep:DrawShadow(true)
			end
		end)
		self:PlaySequenceAndWait("drawpistol")
		self.Memory.Look = bLooking
		self:StartActivity(self.Idle)
	end
	return true
end

--Reloads current weapon.
function ENT:Reload()
	if self.Time.Reload > CurTime() then return end
	if self.Primary.Ammo >= self.Primary.Clip and 
		self.Secondary.Ammo >= self.Secondary.Clip then
		return
	end
	local pistol
	if self.Primary.Ammo == 0 then pistol = true
	elseif self.Secondary.Ammo == 0 then pistol = false
	elseif self.Primary.Ammo < self.Primary.Clip then pistol = true
	elseif self.Secondary.Ammo < self.Secondary.Clip then pistol = false end
	
	self:RemoveAllGestures()
	
	local WeaponInfo = pistol and self.Primary or self.Secondary
	if not self:GetActiveWeapon() or
		self:GetActiveWeapon():GetClass() ~= WeaponInfo.Name then 
		self:Give(pistol)
	end
	
	local bLooking = self:GetLook()
	self:SetLook(false)
	if self.Path.Main:IsValid() then
		local duration = self:GetLayerDuration(self:AddGesture(WeaponInfo.ReloadAct)) * 1.2
		self.Time.Reload = CurTime() + duration
		timer.Simple(WeaponInfo.ReloadSoundDelay, function()
			if not IsValid(self) or not self:GetActiveWeapon() or
				not self:IsPlayingGesture(WeaponInfo.ReloadAct) then return end
			local WeaponInfo = self.Equipment.Weapon
			self:GetActiveWeapon():EmitSound(WeaponInfo.Reload)
		end)
		
		timer.Simple(duration, function()
			if not IsValid(self) or not self:GetActiveWeapon() then return end
			local WeaponInfo = self.Equipment.Weapon
			WeaponInfo.Ammo = WeaponInfo.Clip
			self:SetLook(self, bLooking)
		end)
	else
		self:SetAnim(self.Idle)
		if util.QuickTrace(self:GetEye().Pos, self:GetForward() * 100, {self, self:GetActiveWeapon()}).Hit or
			util.QuickTrace(self:GetEye().Pos, -self:GetForward() * 100, {self, self:GetActiveWeapon()}).Hit or
			util.QuickTrace(self:GetEye().Pos, self:GetRight() * 100, {self, self:GetActiveWeapon()}).Hit or
			util.QuickTrace(self:GetEye().Pos, -self:GetRight() * 100, {self, self:GetActiveWeapon()}).Hit then
			
			timer.Simple(WeaponInfo.ReloadSoundDelay, function()
				if IsValid(self) and self:GetActiveWeapon() then
					self:GetActiveWeapon():EmitSound(WeaponInfo.Reload)
				end
			end)
			self:PlaySequenceAndWait(WeaponInfo.ReloadSequence)
			WeaponInfo.Ammo = WeaponInfo.Clip
		else
			local seq = pistol and "pistol" or "smg1"
			self:PlaySequenceAndWait("Stand_to_crouch" .. seq, 1.5)
			
			timer.Simple(WeaponInfo.ReloadSoundDelay, function()
				if IsValid(self) and self:GetActiveWeapon() then
					self:GetActiveWeapon():EmitSound(WeaponInfo.Reload)
				end
			end)
			self:PlaySequenceAndWait(WeaponInfo.ReloadSequenceCrouched)
			WeaponInfo.Ammo = WeaponInfo.Clip
			self:PlaySequenceAndWait("Crouch_to_stand" .. seq, 1.5)
		end
		self.Time.Reload = CurTime()
		self:SetLook(self, bLooking)
	end
end
----------------------------------}
--==Animations==------------------{
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
	math.Remap(y, 0, 360, -180, 180)
	math.Remap(p, 0, 360, -180, 180)
	if y >= 180 then y = y - 360 end
	if p >= 180 then p = p - 360 end
	if math.abs(y) > 60 then return false end
	if 56.203525543213 < p or p < -86.324005126953 then return false end
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

--Resets pose parameters.
function ENT:ResetPoseParameters()
	if not self:GetEnemy() then
		self:SetPoseParameter("aim_yaw", 0)
		self:SetPoseParameter("aim_pitch", 0)
	end
	self:SetPoseParameter("body_yaw", 0)
	self:SetPoseParameter("spine_yaw", 0)
	self:SetPoseParameter("head_yaw", 0)
	self:SetPoseParameter("head_pitch", 0)
	self:SetPoseParameter("move_yaw", 0)
end

--Prevents the animation from resetting every frame.
function ENT:SetAnim(a)
	if self:GetActivity() ~= a then self:StartActivity(a) end
end

--Determines walking/running animation.
function ENT:SetLocoAnimation()
	local speed, anim = self.RunSpeed, self.Idle
	if (self.Path.Approaching or self.Path.Main:IsValid()) then --Running or walking
		if self:GetActiveWeapon() then
			if self:GetEnemy() then
				if self:GetActiveWeapon():GetClass() == "weapon_stunstick" then
					anim = self.Run
				else
					anim = self.Equipment.IsPrimary and self.RunPistol or self.RunRifle
				end
				speed = self.RunSpeed
			else
				anim = self.Equipment.IsPrimary and self.WalkPistol or self.WalkRifle
				speed = self.WalkSpeed
			end
		else
			anim = self.Path.ForceRun and self.Run or self.Walk
			speed = self.Path.ForceRun and self.RunSpeed or self.WalkSpeed
		end
	else --Is not moving.
		if self:GetActiveWeapon() and self:GetActiveWeapon():GetClass() ~= "weapon_stunstick" then
			anim = self.Equipment.IsPrimary and self.StandPistol or self.StandRifle
		end
	end
	self:SetAnim(anim)
	self.loco:SetDesiredSpeed(speed)
end
----------------------------------}
--==Radio chat==------------------{
--Whether I can speak or not.  also returns if there're allies.
function ENT:CanSpeak(forced)
	local alone, can, time = true, true
	for v in pairs(SUPERPOLICE) do
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
		math.floor(self:XorRand(0, sentence.patterns + 0.999)), self:GetPos(), self:EntIndex(), 
		CHAN_AUTO, 1, sentence.vol or 100)
	local _next = self.SentenceLength[math.floor(self:XorRand(1, #self.SentenceLength))]
	if sentence.squad then _next = _next * 0.8 end
	
	self.Time.Spoke = CurTime() + _next
	self.Time.SpokeOthers = CurTime() + _next / 2
--	if sentence ~= self.Sentence.Pain then PrintMessage(HUD_PRINTTALK, sentence.name) end
	return true
end

--Classify for speaking.
--Arguments:
----Entity ent | The entity to classify.
----Bool kill | If true, returns killing sentence.
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
					sel.child[chr]:addWord(value:sub(2), id)
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
----------------------------------}
----------------------------------}
--++Coroutine elements++----------{
function ENT:RunBehaviour()
	while true do
		if not (GetConVar("ai_disabled"):GetBool() or self.IsInitialing) then
			--Perform sensing.
			local nearestenemy, e = self:FindEnemy(), self:GetEnemy()
			if IsValid(nearestenemy) then
				self:SetEnemy(nearestenemy)
			end
			--Update enemy info
			self.Memory.Look = self:CanSee() --I have LOS of the enemy.
			self.Memory.Shoot = self:CanSee(self.Memory.EnemyPosition, --I can shoot the enemy.
				{start = self:GetMuzzle().Pos, shoot = true})
			
			if self.Memory.Look then
				--Update the position of current enemy
				self.Memory.EnemyPosition = self:GetTargetPos() --set the last position I saw
				self.Memory.Distance = self:GetRangeTo(self.Memory.EnemyPosition) --set the last distance I know
				self:SetLook(self.Memory.Shoot)
				self.Time.Saw = CurTime()
			end
			
			--Build conditions.
			self:RemoveAllConditions()
			self.Condition.Build(self, self.Memory.Enemy)
			
			--Choose a state.
			self.State.Build(self)
			
			--Select a new schedule
			local sched, progress = self:GetSchedule()
			if not istable(self.Schedule[sched]) or self:HasCondition("Done") then
				self:SetSchedule(self.Schedule.Build[self:GetState()](self))
			end
			
			if self.Memory.Shoot then
				self:FireWeapon()
			end
			
			--Do current schedule.
			if istable(self.Schedule[sched]) then --Current schedule is available, run task.
				for i = 1, 3 do
					sched, progress = self:GetSchedule()
					self.State.Task = self.Schedule[sched][progress]
					if istable(self.State.Task) then
						self.State.TaskParam = self.State.Task[2]
						self.State.Task = self.State.Task[1]
					else
						self.State.TaskParam = nil
					end
					
					local task, param, taskreturn, completed = self.State.Task, self.State.TaskParam, nil, nil
					if isfunction(self.Task[task]) then
						taskreturn = self.Task[task](self, param)
						completed = self.Task.IsCompleted(self)
						if completed then --Current task is completed, go to next task.
							if completed == "invalid" then
								self.State.Previous.FailSchedule = sched
								self.State.ScheduleProgress = #self.Schedule[sched] + 1
							else
								self.State.Previous.FailSchedule = nil
								self.State.ScheduleProgress = progress + 1
							end
							self.Time.Task = CurTime()
						end
						if not (completed and taskreturn) then break end
					end
				end
				
				for i, interrupt in ipairs(self.Schedule[sched].Interrupts) do
					if self:HasCondition(interrupt) then
						self.State.ScheduleProgress = #self.Schedule[sched] + 1
					end
				end
			end
			
			self.State.Previous.HaveEnemy = self.Memory.Enemy --For "EnemyDead" condition.
			self.State.Previous.Health = self:Health() --For "Light/HeavyDamage" condition.
			--For "PathFinished" condition.
			self.State.Previous.Path = self.Path.Main:IsValid() or self.Path.Approaching
			
			self:SetLocoAnimation()
			self:MoveBehaviour()
			if self.Memory.FaceEnemy then
				self.loco:FaceTowards(self.Memory.EnemyPosition)
				self.loco:FaceTowards(self.Memory.EnemyPosition)
				self:Aim(self.Memory.EnemyPosition)
			end
		end
		coroutine.yield()
	end
end

function ENT:IsStuck()
	if (self:GetPos() - self.Path.PreviousPosition):Length2DSqr() < 0.0001 then
		self.Time.Stuck = self.Time.Stuck or CurTime() + 2
		self.Path.Stuck = self.Time.Stuck < CurTime()
	end
	self.Path.PreviousPosition = self:GetPos()
	return self.Path.Stuck
end

function ENT:HandleStuck()
	self.Path.Stuck = false
	local stuckpath = Path("Follow")
	stuckpath:SetMinLookAheadDistance(1)
	stuckpath:SetGoalTolerance(10)
	local n = navmesh.GetNearestNavArea(self:GetPos())
	stuckpath:Compute(self, n and n:GetCenter() or self.Path.Goal)
	
	while stuckpath:IsValid() do
	--	stuckpath:Draw()
		stuckpath:Update(self)
		if stuckpath:GetAge() > 1 then stuckpath:Invalidate() break end
		coroutine.yield()
	end
	self.loco:ClearStuck()
	self.Path.Main:Compute(self, self.Path.Goal)
	self.Path.StuckCalled = self.Path.StuckCalled + 1
	if self.Path.StuckCalled > 3 then
		self.loco:Jump()
		self:ClearStuck()
		return true
	end
	return false
end

function ENT:MoveBehaviour()
	--Make a strafe-moving animation.-------
	if not self:GetVelocity():IsZero() then
		self:SetPoseParameter("move_yaw",
		math.Remap(self:WorldToLocal(self:GetPos() - self:GetVelocity()):Angle().y, 0, 360, -180, 180))
	end
	----------------------------------------
	if self.Path.Main:IsValid() then
		local seg = self.Path.Main:GetCurrentGoal()
		if seg.pos:IsEqualTol(self.Path.Main:LastSegment().pos, 5) then
			self.Path.Main:SetGoalTolerance(self.Path.Tolerance + self.Path.StuckCalled * 45)
		end
		
		--The struggle to avoid stucking--------
		local d = 40
		local base = self:GetPos() + vector_up * self.StepHeight * 2
		local tr = {start = base - self:GetForward() * d,
					endpos = base + self:GetForward() * d,
					filter = SUPERPOLICE}
		local f = util.TraceEntity(tr, self)
		if f.HitWorld then
			local cross = self:GetForward():Cross(f.HitNormal).z
			self.loco:Approach(self:GetPos() + self:GetRight() * (cross > 0 and -d or d), 10)
			self.loco:FaceTowards(self:GetPos() - f.HitNormal)
		end
		
		if seg.pos.z - self:GetPos().z > self.StepHeight and
			seg.pos.z - self:GetPos().z < self.JumpHeight / 2 then
			self.loco:JumpAcrossGap(seg.pos, seg.forward)
		end
		
	--	local bound, basepos = 14, self:WorldSpaceCenter() -- self:GetUp() * (bound + 10)
	--	local tr_left, tr_right = util.TraceLine({
	--		start = basepos - self:GetRight() * bound + self:GetForward() * bound,
	--		endpos = basepos - self:GetRight() * bound - self:GetForward() * bound,
	--		filter = {self, self:GetActiveWeapon()}, --TODO: Add squad mates to the filter.
	--	}), util.TraceLine({
	--		start = basepos + self:GetRight() * bound + self:GetForward() * bound,
	--		endpos = basepos + self:GetRight() * bound - self:GetForward() * bound,
	--		filter = {self, self:GetActiveWeapon()},
	--	})
	--	tr_left.Hit = tr_left.Hit or tr_left.StartSolid or tr_left.AllSolid
	--	tr_right.Hit = tr_right.Hit or tr_right.StartSolid or tr_right.AllSolid
	--	
	--	local c = (tr_left.Hit or tr_right.Hit) and Color(255,255,255,64) or Color(0,255,0,64)
	--	debugoverlay.Line(tr_left.StartPos, tr_left.HitPos, 0.1, c, false)
	--	debugoverlay.Line(tr_right.StartPos, tr_right.HitPos, 0.1, c, false)
	--	if not self.Path.Alt:IsValid() then
			if ___DEBUG_DRAW_PATH then self.Path.Main:Draw() end
			self.Path.Main:Update(self)
	--		if tr_left.Hit or tr_right.Hit then
	--			self.Path.Alt:Invalidate()
	--			self.Path.Alt:SetMinLookAheadDistance(1)
	--			self.Path.Alt:SetGoalTolerance(10)
	--			
	--			local movelength = 50
	--			if tr_left.Hit and tr_right.Hit then --go back
	--				self.Path.Alt:Compute(self, self:GetPos() - self:GetForward() * movelength)
	--			elseif tr_left.Hit then --go right
	--				self.Path.Alt:Compute(self, self:GetPos() + self:GetRight() * movelength)
	--			else --go left
	--				self.Path.Alt:Compute(self, self:GetPos() - self:GetRight() * movelength)
	--			end
	--		end
	--	else
	--	--	self.Path.Alt:Draw()
	--		self.Path.Alt:Update(self)
	--		
	--		if not (tr_left.Hit or tr_right.Hit) then
	--			self.Path.Alt:Invalidate()
	--			self.Path.Main:Compute(self, self.Path.Goal)
	--		end
	--	end
		----------------------------------------
		
		-- If we're stuck then call the HandleStuck function and abandon
		if self:IsStuck() or self.loco:IsStuck() then
			if self:HandleStuck() then
				self:ClearPath()
				return false
			end
		end
		return false
	else
		if self.Path.Approaching then
			local d = self.Path.Goal:DistToSqr(self:GetPos())
			if d > self.Path.Tolerance^2 and d < 262144 then --512^2
				self.loco:Approach(self.Path.Goal, 1)
				self.loco:FaceTowards(self.Path.Goal)
			else
				self.Path.Approaching = false
			end
		else
			self:SetPoseParameter("move_yaw", 0)
		end
	end
	return true
end
----------------------------------}
