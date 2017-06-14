--[[
	Nextbot AI that uses schedule system like HL2 NPCs.
]]

local ___DEBUG_SHOW_SCHEDULENAME = true
local ___DEBUG_SHOW_PREVIOUS_SCHEDULE = false
include("conditions.lua")
include("tasks.lua")

local function GetDanger(self)
	local bravery = 0 --Detect dangerous thing
	local escapefrom --Nextbot should escape from specified entity, such as grenades.
	for k, v in pairs(ents.FindInSphere(self:GetPos(), self.Dist.ShootRange)) do
		if IsValid(v) then
			local dist = v:WorldSpaceCenter():DistToSqr(self:WorldSpaceCenter())
			if self:Validate(v) == 0 and self:CanSee(v:WorldSpaceCenter()) then
				bravery = bravery + (self:IsFacingMe(v) and 2 or 1)
			elseif dist < self.Dist.GrenadeSqr and --Grenade is near, take cover
				v:GetClass():find("grenade") then
				
				bravery, escapefrom = math.huge, v
			elseif dist < self.Dist.ManhackSqr and v:GetClass():find("manhack") then
				bravery = math.huge
			elseif v:IsVehicle() and --vehicle incoming
				(isfunction(v.GetSpeed) and v:GetSpeed() or v:GetVelocity()) > 15 and
				v:GetVelocity():GetNormalized():Dot(
				(self:WorldSpaceCenter() - v:WorldSpaceCenter()):GetNormalized()) > 0.65 then
				
				bravery = math.huge
			end
			
			if self:Health() / self:GetMaxHealth() * self.Bravery < bravery then break end
		end
	end
	
	if math.Rand(0, self.Bravery) < bravery then
		return true, escapefrom
	end
end

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
	self.State.Schedule = "Idle" --Current shcedule name.
	self.State.ScheduleProgress = 1 --Current task offset.
	self.State.Build = function(self)
		local s = NPC_STATE_IDLE
		if self:GetEnemy() then
			s = NPC_STATE_COMBAT
		elseif self:GetState() == NPC_STATE_ALERT or
			self:HasCondition("LostEnemy") or
			self:HasCondition("EnemyDead") then
			s = NPC_STATE_ALERT
		end
		if s ~= self:GetState() then self.State.ScheduleProgress = math.huge end
		self:SetState(s)
	end
	
	self.State.GetDanger = GetDanger
	
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
	
	if ___DEBUG_SHOW_PREVIOUS_SCHEDULE then
		print(self, "Previous schedule: " .. self.State.Schedule .. "    Schedule progress: " .. self.State.ScheduleProgress)
	end
	
	self.State.Schedule = s --Schedule now executing.
	self.State.ScheduleProgress = 1
	self.Time.Schedule = CurTime()
	self.Time.Task = CurTime()
	
	if ___DEBUG_SHOW_SCHEDULENAME then
		print(self, "Set a schedule: " .. s)
	end
	
	if isfunction(self.Schedule[s].Init) then
		self.Schedule[s].Init(self)
	end
	return true
end

--Gets the schedule which is executing.
function ENT:GetSchedule()
	return self.State.Schedule, self.State.ScheduleProgress
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
		--Just wander around.
		return "Idle"
	end,
	[NPC_STATE_ALERT] = function(self)
		--TODO: Patrol around and hear the world.
		return "PatrolAround"
	end,
	[NPC_STATE_COMBAT] = function(self)
		--Main combat schedule.
		local sched = "TakeCover"
		--The enemy is enough close, do a melee attack.
		if self:HasCondition("CanMeleeAttack") and self:GetEnemy():Health() < 30 then
			sched = "MeleeAttack"
		--I have low/no ammo, reload.
		elseif self:HasCondition("NoPrimaryAmmo") or
			self:HasCondition("NoSecondaryAmmo") or
			(math.random() < 0.3 and
			(self:HasCondition("LowPrimaryAmmo") or
			self:HasCondition("LowSecondaryAmmo")))then
			sched = "HideAndReload"
		--Enemy is out of range.
		elseif self:HasCondition("EnemyTooFar") then
			if self.State.Previous.FailSchedule ~= "BlinkTowardEnemy" and 
				self.Memory.Distance > self.Dist.Blink then
				sched = "BlinkTowardEnemy"
			else
				sched = "Advance"
			end
		--I've taken damage and feel dangerous, flee.
		elseif self:HasCondition("NearDanger") or
			self:HasCondition("HeavyDamage") or
			self:HasCondition("RepeatedDamage") or
			(self:Health() < self:GetMaxHealth() / 2 and
			self:HasCondition("LightDamage")) then
			sched = "Escape"
		--An enemy is behind me.
		elseif self:HasCondition("BehindEnemy") then
			sched = "TakeCover"
		--Enemy is occluded.
		elseif self:HasCondition("EnemyOccluded") and
			CurTime() > self.Time.SeeEnemy + 3 and
			self.Memory.Distance > self.Dist.ShootRange / 2 then
			sched = "AppearUntilSee"
		--The enemy is not visible, chase it.
		elseif self:HasCondition("EnemyOccluded") then
			sched = "AppearUntilSee"
		else
			--The enemy knows me, and I can attack, fire.
			if self:HasCondition("CanPrimaryAttack") or
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
	"Idle",
	function(self)
		self.Task.Variable = math.Rand(20, 65)
	end,
	{
		"NearDanger",
		"NewEnemy",
		"LightDamage",
		"HeavyDamage",
		"ReceiveEnemyInfo",
	},
	{
		"InvalidatePath",
		"SetFaceEnemy",
		"SetRandomPosition",
		"StartMove",
		{"WaitForMovement", {"Reload"}},
		{
			"Wait",
			{
				func = function(self, opt)
					local time = opt.time or 2
					self:SetPoseParameter("head_yaw", --Rotate the head.
						math.sin((self.Time.Task + time - CurTime())
						/ time * 2 * math.pi) * self.Task.Variable)
					if math.random() < 0.008 then self.Time.Task = CurTime() - time end
				end
			}
		},
	}
)
--------------------------------}
--==PatrolAround==--------------{
ENT.Schedule:Add(
	"PatrolAround",
	{
		"NearDanger",
		"NewEnemy",
		"HaveEnemyLOS",
		"CanPrimaryAttack",
		"CanSecondaryAttack",
		"CanMeleeAttack",
		"LightDamage",
		"HeavyDamage",
		"ReceiveEnemyInfo",
	},
	{
		"SetFaceEnemy",
		"InvalidatePath",
		{"Wait", {time = 0.7}},
		"SetFaceEnemy",
		{"SetRandomPosition", {distance = 350}},
		"StartMove",
		"WaitForMovement",
	}
)
--------------------------------}
--==Advance==-------------------{
ENT.Schedule:Add(
	"Advance",
	{
		"LightDamage",
		"HeavyDamage",
		"RepeatedDamage",
		"CanSecondaryAttack",
		"CanMeleeAttack",
		"NewEnemy",
		"EnemyDead",
		"MobbedByEnemies",
	},
	{
		"InvalidatePath",
		{"SetFaceEnemy", true},
		"Advance",
		"StartMove",
		{"WaitForMovement", {"FireWeapon"}}
	}
)	
--------------------------------}
--==Escape==--------------------{
ENT.Schedule:Add(
	"Escape",
	{
		"NewEnemy",
		"HeavyDamage",
		"EnemyDead",
		"EnemyOccluded",
	},
	{
		"InvalidatePath",
		{"SetFaceEnemy", true},
		"Escape",
		"StartMove",
		{"WaitForMovement", {"FireWeapon"}},
		{"Wait", {time = 1.2}},
	}
)
--==TakeCover==-----------------{
ENT.Schedule:Add(
	"TakeCover",
	{
		"HeavyDamage",
		"NewEnemy",
		"EnemyDead",
		"CanMeleeAttack",
	},
	{
		"InvalidatePath",
		{"SetFaceEnemy", true},
		"Escape",
		"StartMove",
		{"WaitForMovement", {"FireWeapon"}},
		{"Wait", {time = 3.5}},
	}
)
--------------------------------}
--==RangeAttack==---------------{
ENT.Schedule:Add(
	"RangeAttack",
	{
		"NearDanger",
		"NoPrimaryAmmo",
		"NoSecondaryAmmo",
		"LowPrimaryAmmo",
		"LowSecondaryAmmo",
		"EnemyDead",
		"EnemyOccluded",
	},
	{
		"InvalidatePath",
		{"SetFaceEnemy", true},
		"FireWeapon",
	}
)
--------------------------------}
--==AppearUntilSee==------------{
ENT.Schedule:Add(
	"AppearUntilSee",
	{
		"NearDanger",
		"HaveEnemyLOS",
		"CanPrimaryAttack",
		"CanSecondaryAttack",
		"CanMeleeAttack",
		"EnemyDead",
		"NewEnemy",
	},
	{
		"InvalidatePath",
		"Appear",
		"StartMove",
		"WaitForMovement",
	}
)
--------------------------------}
--==HideAndReload==-------------{
ENT.Schedule:Add(
	"HideAndReload",
	{
		"NewEnemy",
		"ReloadFinished",
	},
	{
		"InvalidatePath",
		"Escape",
		"StartMove",
		{"WaitForMovement", {"FireWeapon", "Reload"}},
		"Reload",
	}
)
--------------------------------}
--==MeleeAttack==----------------{
ENT.Schedule:Add(
	"MeleeAttack",
	{
		"CanPrimaryAttack",
		"CanSecondaryAttack",
		"EnemyDead",
		"EnemyOccluded",
		"EnemyUnreachable",
		"HeavyDamage",
		"LostEnemy",
		"NewEnemy",
		"RepeatedDamage",
	},
	{
		"InvalidatePath",
		{"SetFaceEnemy", true},
		"MeleeAttack",
	}
)
--------------------------------}
--==BlinkTowardEnemy==----------{
ENT.Schedule:Add(
	"BlinkTowardEnemy",
	{
		"CanPrimaryAttack",
	},
	{
		{"SetBlinkPosition", "TowardEnemy"},
		"Blink",
		"RecomputePath",
	}
)
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
