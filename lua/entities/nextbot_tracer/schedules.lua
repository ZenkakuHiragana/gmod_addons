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
				v:GetVelocity():GetNormalized():Dot(self:GetAimVector(v:WorldSpaceCenter())) > 0.65 then
				
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
	self.State.FailNextSchedule = nil --If a schedule failed, do this schedule.
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
--Table  tasks | List of TaskNames.
--string failschedule | If this schedule failed, go to this schedule(Optional).
ENT.Schedule = {
Add = function(self, key, init, interrupts, tasks, failschedule)
	self[key] = {}
	if isfunction(init) then
		self[key].Init = init
	else
		interrupts, tasks, failschedule = init, interrupts, tasks
	end
	self[key].Interrupts = interrupts
	if istable(tasks) then table.Add(self[key], tasks) end
	self[key].FailSchedule = failschedule
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
		local sched = "Escape"
		--The enemy is enough close, do a melee attack.
		if self:HasCondition("CanMeleeAttack") and self:GetEnemy():Health() < 30 then
			return "MeleeAttack"
		--I have low/no ammo, reload.
		elseif CurTime() > self.Time.Reload and 
			(self:HasCondition("NoPrimaryAmmo") or
			self:HasCondition("NoSecondaryAmmo") or
			(math.random() < 0.3 and
			(self:HasCondition("LowPrimaryAmmo") or
			self:HasCondition("LowSecondaryAmmo"))))then
			
			if self:HasCondition("CanBlink") and
				self:HasCondition("EnemyFacingMe") and
				self.Memory.Distance < self.Dist.Blink * 0.75 then
				return "BlinkTowardEnemyAndReload"
			else
				return "HideAndReload"
			end
		--Blink and sidestep.
		elseif self:HasCondition("CanBlink") then 
			if self.Memory.Distance < self.Dist.Blink and 
				self:HasCondition("EnemyFacingMe") then
				return "BlinkSidestep"
			--I've taken repeated damage and enemies are near, blink and go behind them.
			elseif self.Memory.Distance < self.Dist.Blink * 2 and 
				self:HasCondition("RepeatedDamage") then
				return "BlinkTowardEnemy"
			end
		--I've taken damage and feel dangerous, flee.
		elseif self:HasCondition("NearDanger") or
			self:HasCondition("HeavyDamage") or
			(self:Health() < self:GetMaxHealth() / 2 and
			self:HasCondition("LightDamage")) then
			
			if self:HasCondition("CanBlink") then
				if self:HasCondition("EnemyFacingMe") and --The enemy is near,
					self.Memory.Distance < self.Dist.Blink / 2 then
					return "BlinkTowardEnemy" --Go behind the enemy.
				else
					return math.random() > 0.5 and "BlinkFromEnemy" or "BlinkSidestep"
				end
			else
				return "TaleCover"
			end
		--Enemy is out of range.
		elseif self:HasCondition("EnemyTooFar") then
			if self:HasCondition("CanBlink") and
				self.Memory.Distance > self.Dist.Blink then
				return "BlinkTowardEnemy"
			elseif self.State.Previous.FailSchedule ~= "Advance" then
				return "Advance"
			end
		end
		
		--An enemy is behind me.
		if self:HasCondition("CanBlink") and
			self:HasCondition("MobbedByEnemies") then
			return "BlinkTowardEnemy"
		--The enemy is not visible, chase it.
		elseif self:HasCondition("EnemyOccluded") then
			return "AppearUntilSee"
		else
			--The enemy knows me, and I can attack, fire.
			if self:HasCondition("CanPrimaryAttack") or
				self:HasCondition("CanSecondaryAttack") then
				return "RangeAttack"
			--Go to enemy position.
			elseif self:HasCondition("CanBlink") and self.Memory.Distance < self.Dist.Blink / 2 then
				return "BlinkTowardEnemy"
			else
				return "Advance"
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
		{"NearDanger", "Escape"},
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
		"LightDamage",
		"HeavyDamage",
		"ReceiveEnemyInfo",
	},
	{
		"InvalidatePath",
		{"Wait", {time = 0.7}},
		"SetFaceEnemy",
		{"SetRandomPosition", {dist = 350}},
		"StartMove",
		{"WaitForMovement", {"Reload"}},
	}
)
--------------------------------}
--==RunAround==-----------------{
ENT.Schedule:Add(
	"RunAround",
	function(self)
		self.State.TaskVariable = math.Rand(100, 200)
	end,
	{
		"LightDamage",
		"HeavyDamage",
		"RepeatedDamage",
		"CanMeleeAttack",
		"NearDanger",
		"NewEnemy",
		"InvalidPath",
	},
	{
		"SetFaceEnemy",
		"InvalidatePath",
		{"SetRandomPosition", {dist = 256}},
		"StartMove",
		{"WaitForMovement", {"FireWeapon"}},
	}
)
--------------------------------}
--==Advance==-------------------{
ENT.Schedule:Add(
	"Advance",
	function(self)
		timer.Simple(2, function()
			if not IsValid(self) then return end
			self.Task.Fail(self)
		end)
	end,
	{
		{"LightDamage", "BlinkTowardEnemy"},
		{"HeavyDamage", "BlinkSidestep"},
		{"RepeatedDamage", "BlinkSidestep"},
		"CanPrimaryAttack",
		"CanSecondaryAttack",
		"CanMeleeAttack",
		"NewEnemy",
		"EnemyDead",
		"MobbedByEnemies",
		{"InvalidPath", "RunAround"},
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
	function(self)
		timer.Simple(2, function()
			if not IsValid(self) then return end
			self.Task.Fail(self, "BlinkTowardEnemy")
		end)
	end,
	{
		"NewEnemy",
		"LightDamage",
		"HeavyDamage",
		"RepeatedDamage",
		"EnemyDead",
		{"EnemyOccluded", "AppearUntilSee"},
		{"InvalidPath", "RunAround"},
	},
	{
		"InvalidatePath",
		"SetFaceEnemy",
		"Escape",
		"StartMove",
		{"WaitForMovement", {"FireWeapon", "Reload"}},
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
		{"InvalidPath", "RunAround"},
	},
	{
		"InvalidatePath",
		{"SetFaceEnemy", true},
		{"Escape", {nearby = true}},
		"StartMove",
		
		{"WaitForMovement", {"FireWeapon"}},
	--	{"Wait", {time = 2}},
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
		"NewEnemy",
		"ReloadFinished",
		{"MobbedByEnemies", "Escape"},
	},
	{
		"InvalidatePath",
		{"SetFaceEnemy", true},
		"Escape",
		"StartMove",
		{"WaitForMovement", {"FireWeapon", "Reload"}},
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
		"SetFaceEnemy",
		{"SetBlinkPosition", "TowardEnemy"},
		"Blink",
		"RecomputePath",
	}
)
--------------------------------}
--==BlinkTowardEnemyAndReload==-{
ENT.Schedule:Add(
	"BlinkTowardEnemyAndReload",
	{
	},
	{
		"SetFaceEnemy",
		{"SetBlinkPosition", "TowardEnemy"},
		"Blink",
		"InvalidatePath",
		{"SetFaceEnemy", true},
		"Advance",
		"StartMove",
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
		"SetFaceEnemy",
		{"SetBlinkPosition", "FromEnemy"},
		"Blink",
		"RecomputePath",
	}
)
--------------------------------}
--==BlinkSidestep==-------------{
ENT.Schedule:Add(
	"BlinkSidestep",
	{
	},
	{
		"SetFaceEnemy",
		{"SetBlinkPosition", "Sidestep"},
		"Blink",
		"RecomputePath",
	},
	"Advance"
)
--------------------------------}
--------------------------------}
