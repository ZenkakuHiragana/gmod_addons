--[[
	Nextbot AI that uses schedule system like HL2 NPCs.
]]

include("conditions.lua")
include("tasks.lua")

function ENT:InitializeState()
	self.State = {}
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
		
		if math.Rand(0, self.Memory.Brave) < e then
			self:Speak(sentence, self:CanSpeak())
			return true, escapefrom
		end
	end
	self:SetSchedule("Idle")
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
	if self:GetConVarBool("developer") and ___DEBUG_SHOW_SCHEDULENAME then print(self, "Set a schedule: " .. s) end
	if isfunction(self.Schedule[s].Init) then
		self.Schedule[s].Init(self)
	end
	return true
end

--Gets the schedule which is executing.
function ENT:GetSchedule()
	return self.State.Schedule, self.State.ScheduleProgress
end

--Do a list of functions.
--Argument: Table t | list of functions.
--function | (function, argument) | taskname | (taskname, argument)
local function DoTaskList(self, l)
	if not istable(l) then return end
	for i, t in ipairs(l) do
		if isfunction(t) then
			if t(self) then break end
		elseif isstring(t) then
			if self.Task[t](self) then return end
		elseif istable(t) then
			if isfunction(t[1]) then
				if t[1](self, t[2]) then break end
			elseif isstring(t[1]) then
				if self.Task[t[1]](self, t[2]) then break end
			end
		end
	end
	self.State.TaskDone = nil
end

--------------------------------}
--++Schedules++-----------------{
--Nextbot schedules
--Usage:
--function Init(self) | Initializes the schedule.
--Table Interrupts | Defines interrupt functions.
----"<ConditionName>"
--string List of TaskNames
ENT.Schedule = {
Add = function(self, key, init, interrupts, tasks)
	self[key] = {}
	if isfunction(init) then
		self[key].Init = init
	else
		interrupts, tasks = init, interrupts
	end
	self[key].Interrupts = interrupts
	if istable(tasks) then table.Add(self[key], tasks) end
end}

--Determine what schedule should do.
ENT.Schedule.Build = {
	[NPC_STATE_IDLE] = function(self)
		--Sometimes look behind the nextbot.
		if CurTime() > self.Time.LookBack and math.Rand() < 0.5 then
			self.Time.LookBack = CurTime() + 10
			return "TurnBack"
		else --Just wander around.
			return "Idle"
		end
	end,
	[NPC_STATE_ALERT] = function(self)
		--TODO: Patrol around and hear the world.
		--Also can receive other squad mate's radio.
		return "PatrolAround"
	end,
	[NPC_STATE_COMBAT] = function(self)
		--Main combat schedule.
		local sched = "TakeCover"
		--The enemy is enough close, deploy my baton.
		if self:HasCondition("CanMeleeAttack") then
			sched = "SwingBaton"
		--I have low/no ammo, reload.
		elseif self:HasCondition("NoPrimaryAmmo") or
			self:HasCondition("NoSecondaryAmmo") or
			(math.Rand() < 0.3 and
			(self:HasCondition("LowPrimaryAmmo") or
			self:HasCondition("LowSecondaryAmmo")))then
			sched = "HideAndReload"
		--I've taken damage and feel dangerous, flee.
		elseif self:HasCondition("NearDanger") or
			self:HasCondition("HeavyDamage") or
			self:HasCondition("RepeatedDamage") or
			(self:Health() < self:GetMaxHealth() / 2 and
			self:HasCondition("LightDamage")) then
			sched = "Escape"
		--I think an enemy is behind me, turn my head back.
		elseif self:HasCondition("BehindEnemy") then
			sched = "TurnBack"
		--Enemy is occluded and past enough time, throw.
		elseif self:HasCondition("EnemyOccluded") and
			CurTime() > self.Time.Saw + 3 and
			self.Memory.Distance > self.NearDistance / 2 and
			CurTime() > self.Time.Threw then
			sched = "ThrowGrenade"
		--The enemy is not visible, chase it.
		elseif not self.Memory.Shoot or self:HasCondition("EnemyOccluded") then
			sched = "AppearUntilSee"
		else
			local d = 10
			local l, r = util.TraceLine({
				start = self:GetEye().Pos - self:GetRight() * d,
				endpos = self.Memory.EnemyPosition,
				filter = self.Sensor.breakable_filter,
				mask = MASK_SHOT,
			}), util.TraceLine({
				start = self:GetEye().Pos + self:GetRight() * d,
				endpos = self.Memory.EnemyPosition,
				filter = self.Sensor.breakable_filter,
				mask = MASK_SHOT,
			})
		--	debugoverlay.Line(l.StartPos, l.HitPos)
		--	debugoverlay.Line(r.StartPos, r.HitPos)
			--Hide if additional traces hit the enemy.
			if l.HitPos:DistToSqr(self.Memory.EnemyPosition) < 100e+2 and
				r.HitPos:DistToSqr(self.Memory.EnemyPosition) < 100e+2 then
				sched = "TakeCover"
			--The enemy notices me, and I can attack, fire.
			elseif self:HasCondition("EnemyFacingMe") or 
				self:HasCondition("CanPrimaryAttack") or
				self:HasCondition("CanSecondaryAttack") then
				sched = "RangeAttack"
			--Go to enemy position.
			else
				sched = "Advance"
			end
		end
		return sched
	end,
}

--==Idle==----------------------{
ENT.Schedule:Add(
	"Idle", function(self)
		self.Task.Variable = math.Rand(40, 55)
	end,{
	"NearDanger",
	"NewEnemy",
	"LightDamage",
	"HeavyDamage",
	"ReceiveEnemyInfo",
},{
	"InvalidatePath",
	"MaintainWeapons",
	"SetFaceEnemy",
	"WalkRandom",
	"WaitForMovement",
	{"Wait", {func = function(self, opt)
		local time = opt.time or 2
		self:SetPoseParameter("head_yaw", --Rotate the head.
			math.sin((self.Time.Task + time - CurTime())
			/ time * 2 * math.pi) * self.Task.Variable)
	end}},
	"Reload",
	"Reload",
})
--------------------------------}
--==PatrolAround==--------------{
ENT.Schedule:Add(
	"PatrolAround", {
	"NearDanger",
	"NewEnemy",
	"HaveEnemyLOS",
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"CanMeleeAttack",
	"LightDamage",
	"HeavyDamage",
	"ReceiveEnemyInfo",
},{
	"SetFaceEnemy",
	"InvalidatePath",
	{"Wait", {time = 0.7}},
	"SetFaceEnemy",
	{"WalkRandom", {distance = 350}},
	"Reload",
	"WaitForMovement",
})
--------------------------------}
--==Advance==-------------------{
ENT.Schedule:Add(
	"Advance", {
	"LightDamage",
	"HeavyDamage",
	"RepeatedDamage",
	"CanSecondaryAttack",
	"CanMeleeAttack",
	"NewEnemy",
	"EnemyDead",
	"MobbedByEnemies",
},{
	"InvalidatePath",
	"MaintainWeapons",
	{"SetFaceEnemy", true},
	"Advance",
	"SetCoverFireAnim",
	{"WaitForMovement", {"FireWeapon"}}
})	
--------------------------------}
--==Escape==--------------------{
ENT.Schedule:Add(
	"Escape", {
	"NewEnemy",
	"HeavyDamage",
	"EnemyDead",
	"EnemyOccluded",
},{
	"InvalidatePath",
	"MaintainWeapons",
	{"SetFaceEnemy", true},
	"Escape",
	{"Wait", {time = 1.2, func = DoTaskList, "FireWeapon"}},
})
--==TakeCover==-----------------{
ENT.Schedule:Add(
	"TakeCover", {
	"HeavyDamage",
	"NewEnemy",
	"EnemyDead",
	"CanMeleeAttack",
},{
	"InvalidatePath",
	"MaintainWeapons",
	{"SetFaceEnemy", true},
	"SetCoverFireAnim",
	"SearchCover",
	{"Wait", {time = 3.5, func = DoTaskList, "FireWeapon"}},
})
--------------------------------}
--==RangeAttack==---------------{
ENT.Schedule:Add(
	"RangeAttack", {
	"NearDanger",
	"NoPrimaryAmmo",
	"NoSecondaryAmmo",
	"LowPrimaryAmmo",
	"LowSecondaryAmmo",
	"EnemyDead",
	"EnemyOccluded",
},{
	"InvalidatePath",
	{"SetFaceEnemy", true},
	"SetCoverFireAnim",
	"MaintainWeapons",
	"FireWeapon",
})
--------------------------------}
--==AppearUntilSee==------------{
ENT.Schedule:Add(
	"AppearUntilSee", {
	"NearDanger",
--	"HaveEnemyLOS",
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"CanMeleeAttack",
	"EnemyDead",
	"NewEnemy",
},{
	"InvalidatePath",
	"MaintainWeapons",
	"Appear",
	"SetCoverFireAnim",
	"WaitForMovement",
})
--------------------------------}
--==HideAndReload==-------------{
ENT.Schedule:Add(
	"HideAndReload", {
	"NearDanger",
	"NewEnemy",
	"ReloadFinished",
},{
	"InvalidatePath",
	"MaintainWeapons",
	"Escape",
	{"WaitForMovement", {
	"Reload",
	"FireWeapon",}},
	"Reload",
})
--------------------------------}
--==SwingBaton==----------------{
ENT.Schedule:Add(
	"SwingBaton", {
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"EnemyDead",
	"EnemyOccluded",
	"EnemyUnreachable",
	"HeavyDamage",
	"LostEnemy",
	"NewEnemy",
	"RepeatedDamage",
},{
	"InvalidatePath",
	{"SetFaceEnemy", true},
	{"MaintainWeapons", true},
	"SwingBaton",
})
--------------------------------}
--==ThrowGrenade==--------------{
ENT.Schedule:Add(
	"ThrowGrenade", {
	"NearDanger",
},{
	"InvalidatePath",
	{"SetFaceEnemy", true},
	"MaintainWeapons",
	"TaskThrowGrenade",
})
--------------------------------}
--==TurnBack==------------------{
ENT.Schedule:Add(
	"TurnBack", function(self)
		self.Task.Variable = (math.Rand() < 0.5) and 1 or -1
	end, {
	"NearDanger",
	"LightDamage",
	"HeavyDamage",
	"MobbedByEnemies",
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"CanMeleeAttack",
},{
	"MaintainWeapons",
	{"Wait", {time = 1.5, func = function(self)
		local fraction = math.sin(((self.Time.Task + 1.5 - CurTime()) / 1.5) * math.pi) * self.Task.Variable	
		self:SetPoseParameter("body_yaw", fraction * 30) --Rotate the body.
		self:SetPoseParameter("spine_yaw", fraction * 30) --Rotate the spine.
		self:SetPoseParameter("head_yaw", fraction * 60) --Rotate the head.
	end}},
	{"Wait", {time = 0.4}},
})
--------------------------------}
--------------------------------}
