--[[
	Nextbot AI that uses schedule system like HL2 NPCs.
]]

include("conditions.lua")
include("tasks.lua")
include("build.lua")

local function GetDanger(self)
	local bravery = 0 --Detect dangerous thing
	local escapefrom --Nextbot should escape from specified entity, such as grenades.
	for k, v in pairs(ents.FindInSphere(self:GetPos(), self.Dist.ShootRange)) do
		if IsValid(v) then
			local dist = v:WorldSpaceCenter():DistToSqr(self:WorldSpaceCenter())
			local relationship = self:Disposition(v)
			if (relationship == D_HT or relationship == D_FR) and self:CanSee(v:WorldSpaceCenter()) then
				bravery = bravery + (self:IsFacingMe(v) and 2 or 1)
			elseif dist < self.Dist.GrenadeSqr and --Grenade is near, take cover
				v:GetClass():find("grenade") then
				
				bravery, escapefrom = math.huge, v
			elseif dist < self.Dist.ManhackSqr and v:GetClass():find("manhack") then
				bravery = math.huge
			elseif v:IsVehicle() and --vehicle incoming
				(isfunction(v.GetSpeed) and v:GetSpeed() or v:GetVelocity()) > 15 and
				v:GetVelocity():GetNormalized():Dot(self:GetAimVector(v:WorldSpaceCenter())) > 0.65 then
				
				bravery = math.huge
			end
			
			if self:Health() / self:GetMaxHealth() * math.Rand(self.Bravery, self.Bravery * 2) < bravery then
				return true, escapefrom
			end
		end
	end
end

function ENT:InitializeState()
	self.State = {}
	self.State.Previous = {}
	self.State.Previous.ApproachingPos = vector_origin --For "EnemyApproaching" condition.
	self.State.Previous.HaveEnemy = nil --Detecting the enemy went null or dead.
	self.State.Previous.Health = self:GetMaxHealth() --Detecting damage.
	self.State.Previous.HealthForRecall = self:GetMaxHealth() --Detecting damage, for recall.
	self.State.Previous.Path = false --Hook for finished moving.
	self.State.Build = self.BuildNPCState --Building function of NPCState.
	self.State.FailReason = "NoReasonGiven" --This is why the previous schedule is failed.
	self.State.FailSchedule = nil --If a schedule is failed, do this schedule.
	self.State.GetDanger = GetDanger --Gets if it's dangerous. (ex. There's a grenade nearby.)
	self.State.InterruptCondition = nil --The previous schedule has stopped by this condition.
	self.State.Mode = "" --Subcategory of NPC state.
	self.State.Task = "" --The current task name.
	self.State.TaskVariable = nil --Variable for some tasks.
	self.State.TaskParam = nil --The parameter of the current task.
	self.State.TaskDone = nil --True if the current task is done.
	self.State.State = NPC_STATE_IDLE --The nextbot is idle.
	self.State.Schedule = "Idle" --Current shcedule name.
	self.State.ScheduleProgress = 1 --Current task offset.
	
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
	
	if self.Debug.ShowPreviousSchedule then
		print(self, "Previous schedule: " .. self.State.Schedule .. "    Schedule progress: " .. self.State.ScheduleProgress)
		print(self, "FailReason: ", self.State.FailReason, "FSched: ", self.State.FailSchedule, "InterC: ", self.State.InterruptCondition)
		print("")
	end
	
	self.Schedule:SetInterrupt(true)
	self.State.FailReason = "NoReasonGiven"
	self.State.FailSchedule = nil
	self.State.InterruptCondition = nil
	self.State.Schedule = s --Schedule now executing.
	self.State.ScheduleProgress = 1
	self.Time.Schedule = CurTime()
	self.Time.Task = CurTime()
	
	if self.Debug.ShowNextSchedule then
		print(self, "Set a schedule: " .. s)
		print("")
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
--string ScheduleName | The name of the schedule.
--function Init(self) | Initializes the schedule.
--Table Interrupts | Defines interrupt conditions.
----"<ConditionName>"
--Table  tasks | List of TaskNames.
ENT.Schedule = {}
function ENT.Schedule:Add(key, init, interrupts, tasks, failschedule)
	self[key] = {}
	if isfunction(init) then
		self[key].Init = init
	else
		interrupts, tasks, failschedule = init, interrupts, tasks
	end
	self[key].Interrupts = interrupts
	if istable(tasks) then table.Add(self[key], tasks) end
end

--Sets a flag by interrupt condition.
--Arguments:
----string cond | the condition name that stops the current schedule.
----bool clearflag | true if this clears the flag.
function ENT.Schedule:SetInterrupt(clearflag)
	self.Interrupt = not flag
end

--Returns true if the current schedule has an interrupt.
function ENT.Schedule:HasInterrupt()
	return self.Interrupt
end

--Determine what schedule should be done.
ENT.Schedule.Build = {
	[NPC_STATE_IDLE] = ENT.BuildIdleSchedule,
	[NPC_STATE_ALERT] = ENT.BuildAlertSchedule,
	[NPC_STATE_COMBAT] = ENT.BuildCombatSchedule,
}

--==Idle==----------------------{
ENT.Schedule:Add(
	"Idle",
	function(self)
		self.State.TaskVariable = math.Rand(20, 65)
	end,
	{
		"HeavyDamage",
		"LightDamage",
		{"NearDanger", "Escape"},
		"NewEnemy",
		"ReceiveEnemyInfo",
	},
	{
		"Reload",
		"Wait",
	}
)
--------------------------------}
--==PatrolAround==--------------{
ENT.Schedule:Add(
	"PatrolAround",
	function(self)
		self.State.TaskVariable = math.Rand(20, 65)
	end,
	{
		"HeavyDamage",
		"LightDamage",
		{"NearDanger", "Escape"},
		"NewEnemy",
		"ReceiveEnemyInfo",
	},
	{
		"SetFaceEnemy",
		"StartMove",
		{"WaitForMovement", {"Reload"}},
		{"Wait", {"TurnBackToWall"}},
		"SetRandomPosition",
	}
)
--------------------------------}
--==RunAroundAndFire==----------{
ENT.Schedule:Add(
	"RunAroundAndFire",
	function(self)
		timer.Simple(1.5, function()
			if not IsValid(self) or self:GetSchedule() ~= "RunAroundAndFire" then return end
			self.Task.Fail(self, self.FailReason.TimeOut)
		end)
		self.State.TaskVariable = math.Rand(100, 200)
	end,
	{
		"CanRecall",
		"EnemyDead",
		"EnemyOccluded",
		"HeavyDamage",
		"LightDamage",
		"NoPrimaryAmmo",
		"OnContact",
		"RepeatedDamage",
	},
	{
		{"SetFaceEnemy", true},
		{"SetRandomPosition", {dist = 256}},
		"StartMove",
		{"WaitForMovement", {"FireWeapon"}},
	}
)
--------------------------------}
--==RunFromEnemy==--------------{
ENT.Schedule:Add(
	"RunFromEnemy",
	function(self)
		timer.Simple(1.5, function()
			if not IsValid(self) or self:GetSchedule() ~= "RunFromEnemy" then return end
			self.Task.Fail(self, self.FailReason.TimeOut)
		end)
		self.State.TaskVariable = math.Rand(100, 200)
	end,
	{
		"CanRecall",
		"EnemyDead",
		"EnemyOccluded",
		"HeavyDamage",
		"LightDamage",
		"NewEnemy",
		"OnContact",
		"ReloadFinished",
		"RepeatedDamage",
	},
	{
		{"SetFaceEnemy", true},
		{"SetRunFromEnemy", {deg = 100, dist = 256}},
		"StartMove",
		{"WaitForMovement", {"Reload"}},
	}
)
--------------------------------}
--==RunIntoEnemy==--------------{
ENT.Schedule:Add(
	"RunIntoEnemy",
	function(self)
		timer.Simple(1.5, function()
			if not IsValid(self) or self:GetSchedule() ~= "RunIntoEnemy" then return end
			self.Task.Fail(self, self.FailReason.TimeOut)
		end)
		self.State.TaskVariable = math.Rand(100, 200)
	end,
	{
		"CanRecall",
		"EnemyApproaching",
		"EnemyDead",
		"HeavyDamage",
		"LightDamage",
		"MobbedByEnemies",
		"NewEnemy",
		"NoPrimaryAmmo",
		"OnContact",
		"RepeatedDamage",
	},
	{
		{"SetFaceEnemy", true},
		{"SetRunIntoEnemy", {deg = 100, dist = 256}},
		"StartMove",
		{"WaitForMovement", {"FireWeapon"}},
	}
)
--------------------------------}
--==Advance==-------------------{
ENT.Schedule:Add(
	"Advance",
	function(self)
		timer.Simple(3, function()
			if not IsValid(self) or self:GetSchedule() ~= "Advance" then return end
			self.Task.Fail(self, self.FailReason.TimeOut)
		end)
	end,
	{
		"CanRecall",
		"EnemyApproaching",
		"EnemyDead",
		"HeavyDamage",
		"InvalidPath",
		"LightDamage",
		"MobbedByEnemies",
		"NewEnemy",
		"NoPrimaryAmmo",
		"OnContact",
		"RepeatedDamage",
	},
	{
		{"SetFailSchedule", "RunIntoEnemy"},
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
	function(self)
		timer.Simple(6, function()
			if not IsValid(self) or self:GetSchedule() ~= "Escape" then return end
			self.Task.Fail(self, self.FailReason.TimeOut)
		end)
	end,
	{
		"EnemyDead",
		"EnemyOccluded",
		"HeavyDamage",
		{"InvalidPath", "RunFromEnemy"},
		"NewEnemy",
		"RepeatedDamage",
	},
	{
		{"SetFailSchedule", "RunFromEnemy"},
		"SetFaceEnemy",
		"Escape",
		"StartMove",
		{"WaitForMovement", {"Reload"}},
		{"Wait", {time = 1.2}},
	}
)
--------------------------------}
--==TakeCover==-----------------{
ENT.Schedule:Add(
	"TakeCover",
	function(self)
		timer.Simple(3, function()
			if not IsValid(self) or self:GetSchedule() ~= "TakeCover" then return end
			self.Task.Fail(self, self.FailReason.TimeOut)
		end)
	end,
	{
		"EnemyDead",
		"HeavyDamage",
		{"InvalidPath", "RunFromEnemy"},
		"NewEnemy",
		"NoPrimaryAmmo",
		"RepeatedDamage",
	},
	{
		{"SetFailSchedule", "RunFromEnemy"},
		{"SetFaceEnemy", true},
		{"Escape", {nearby = true}},
		"StartMove",
		
		{"WaitForMovement", {"FireWeapon"}},
	}
)
--------------------------------}
--==EscapeLimitedTime==---------{
ENT.Schedule:Add(
	"EscapeLimitedTime",
	function(self)
		self.State.TaskVariable = math.Rand(0.8, 1.75)
	end,
	{
		"EnemyDead",
		{"EnemyOccluded", "AppearUntilSee"},
		"HeavyDamage",
		{"InvalidPath", "RunFromEnemy"},
		"LightDamage",
		"NewEnemy",
		"RepeatedDamage",
	},
	{
		{"SetFailSchedule", "RunFromEnemy"},
		{"SetFaceEnemy", true},
		"MakeDistance",
		"StartMove",
		{"Wait", {time = "Variable", "FireWeapon"}},
	}
)
--------------------------------}
--==RangeAttack==---------------{
ENT.Schedule:Add(
	"RangeAttack",
	{
		"EnemyDead",
		"EnemyOccluded",
		"NearDanger",
		"NoPrimaryAmmo",
		"NoSecondaryAmmo",
		"LowPrimaryAmmo",
		"LowSecondaryAmmo",
	},
	{
		{"SetFaceEnemy", true},
		"FireWeapon",
	}
)
--------------------------------}
--==Reload==--------------------{
ENT.Schedule:Add(
	"Reload",
	{
	},
	{
		"Reload",
	}
)
--------------------------------}
--==AppearUntilSee==------------{
ENT.Schedule:Add(
	"AppearUntilSee",
	{
		"CanMeleeAttack",
		"CanPrimaryAttack",
		"CanRecall",
		"CanSecondaryAttack",
		"EnemyDead",
		"HaveEnemyLOS",
		"HeavyDamage",
		"LightDamage",
		"NearDanger",
		"NewEnemy",
		"RepeatedDamage",
	},
	{
		{"SetFailSchedule", "RunIntoEnemy"},
		{"SetFaceEnemy", true},
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
		"HeavyDamage",
		"LightDamage",
		"MobbedByEnemies",
		"NewEnemy",
		"ReloadFinished",
		"RepeatedDamage",
	},
	{
		{"SetFailSchedule", "RunFromEnemy"},
		"SetFaceEnemy",
		"Escape",
		"StartMove",
		{"WaitForMovement", {"Reload"}},
		"Reload",
	}
)
--------------------------------}
--==MeleeAttack==---------------{
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
	},
	{
		"InvalidatePath",
		"SetFaceEnemy",
		{"SetBlinkDirection", "TowardEnemy"},
		"Blink",
	}
)
--------------------------------}
--==BlinkTowardEnemyAndReload==-{
ENT.Schedule:Add(
	"BlinkTowardEnemyAndReload",
	{
		"HeavyDamage",
		"LightDamage",
	},
	{
		"SetFaceEnemy",
		{"SetBlinkDirection", "TowardEnemy"},
		"Blink",
		{"SetFaceEnemy", true},
		"Advance",
		"StartMove",
		{"SetFailSchedule", "RunIntoEnemy"},
		{"Wait", {time = 0.5, "Reload"}},
	}
)
--------------------------------}
--==BlinkFromEnemy==------------{
ENT.Schedule:Add(
	"BlinkFromEnemy",
	{
	},
	{
		"InvalidatePath",
		"SetFaceEnemy",
		{"SetBlinkDirection", "FromEnemy"},
		"Blink",
	}
)
--------------------------------}
--==BlinkSidestep==-------------{
ENT.Schedule:Add(
	"BlinkSidestep",
	{
	},
	{
		"InvalidatePath",
		"SetFaceEnemy",
		{"SetBlinkDirection", "Sidestep"},
		"Blink",
	}
)
--------------------------------}
--==Recall==--------------------{
ENT.Schedule:Add(
	"Recall",
	{
	},
	{
		"InvalidatePath",
		"SetFaceEnemy",
		"Recall",
	}
)
--------------------------------}
