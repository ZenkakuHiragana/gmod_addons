
function ENT:SetNPCState(state)
    self.Schedule.NPCState = state
end

function ENT:GetNPCState()
    return self.Schedule.NPCState
end

function ENT:TaskComplete()
    self.Schedule.TaskStatus = self.Enum.TaskStatus.TASKSTATUS_COMPLETE
end

function ENT:TaskFail(reason)
    self.Schedule.TaskFailureCode = reason
    self:TaskComplete()
end

function ENT:TaskStatus(status)
    self.Schedule.TaskStatus = status
end

function ENT:TaskFailed()
    return self.Schedule.TaskFailureCode ~= self.Enum.TaskFailure.NO_TASK_FAILURE
end

function ENT:TaskFinished()
    return self.Schedule.TaskStatus == self.Enum.TaskStatus.TASKSTATUS_COMPLETE
end

function ENT:HasMemory(mem)
    return self.Schedule.Memory[mem]
end

function ENT:Initialize_Schedule()
    self.Time.NextCombatSlide = CurTime()
    self.Time.ScheduleStart = CurTime()
    self.Time.TaskStart = CurTime()
    self.Time.Wait = CurTime()
    self.Schedule = {
        CurrentSchedule = "IdleStand",
        CurrentTask = 0,
        Fallback = nil,
        Memory = {},
        NextSchedule = nil,
        NPCState = NPC_STATE_IDLE,
        TaskData = nil,
        TaskFailureCode = self.Enum.TaskFailure.NO_TASK_FAILURE,
        TaskStatus = self.Enum.TaskStatus.TASKSTATUS_NEW,
    }
end

function ENT:HasInterrupt()
    local i = self.Interrupts[self.Schedule.CurrentSchedule]
    if not i then return end
    for c in pairs(i) do
        if self:HasCondition(c) then
            self:print("HasInterrupt", self:ConditionName(c))
            return true
        end
    end
end

function ENT:OnScheduleInitialize()
    self.Schedule.CeaseSchedule = nil
    self.Schedule.ChangeSchedule = nil
    self.Schedule.Fallback = nil
    self.Schedule.TaskFailureCode = self.Enum.TaskFailure.NO_TASK_FAILURE
    self.Schedule.TaskFinalize = nil
    self.Time.ScheduleStart = CurTime()
end

function ENT:OnTaskInitialize()
    self.FaceTowards.ToTarget = nil
    self.Schedule.TaskData = nil
    self.Schedule.TaskStatus = self.Enum.TaskStatus.TASKSTATUS_NEW
    self.Time.TaskStart = CurTime()
end

local c = ENT.Enum.Conditions
function ENT:DoTask(task)
    local taskName = self.Schedule.CurrentTask
    local taskArg = istable(task) and (task[2] or task.Argument) or nil
    local func = self["Task_" .. taskName]
    if not isfunction(func) then
        print(string.format("Wawrning! Task %s is not found!", taskName))
        self:TaskFail(self.Enum.TaskFailure.FAIL_SCHEDULE_NOT_FOUND)
        return
    end
    
    func(self, taskArg)
end

function ENT:SelectNPCState()
    local state = NPC_STATE_IDLE
    if self:HasValidEnemy() then
        state = NPC_STATE_COMBAT
    elseif CurTime() - self.Time.LastEnemySeen < 20 then
        state = NPC_STATE_ALERT
    end

    self:SetNPCState(state)
end

function ENT:GetCurrentSchedule()
    return self.Schedule.CurrentSchedule
end

function ENT:IsCurrentSchedule(schedule)
    return self:GetCurrentSchedule() == schedule
end

function ENT:ClearSchedule()
    self.Schedule.CeaseSchedule = true
end

function ENT:FireWeapon()
    if not (self:HasCondition(c.COND_CAN_RANGE_ATTACK1)
    or self:HasCondition(c.COND_CAN_MELEE_ATTACK1)) then return end
    self:PrimaryFire()
end

local function IdleSchedule(self)
    local w = self:GetActiveWeapon()
    local params = self:GetWeaponParameters()
    local sched_list = {"IdleStand", "IdleWander"}
    local s = sched_list[math.random(#sched_list)]
    if self:HasCondition(c.COND_SEE_GRENADE) then
        s = "GrenadeEscape"
    elseif not self.IsReloading and IsValid(w)
    and params and self:GetClip() < params.ClipSize then
        s = "HideAndReload"
    elseif not self.IsReloading then
        for i, w in ipairs(self.Weapons) do
            if w.Clip < w.Parameters.ClipSize then
                return "SwitchWeaponToReload"
            end
        end
    end
    
    return s
end

local function AlertSchedule(self)
    local w = self:GetActiveWeapon()
    local params = self:GetWeaponParameters()
    local sched_list = {"AlertStand", "IdleWander"}
    local s = sched_list[math.random(#sched_list)]
    if self:HasCondition(c.COND_SEE_GRENADE) then
        s = "GrenadeEscape"
    elseif CurTime() - self.Time.LastEnemySeen < 3 then
        s = "AlertStand"
    elseif not self.IsReloading and IsValid(w)
    and params and self:GetClip() < params.ClipSize then
        s = "HideAndReload"
    elseif not self.IsReloading then
        for i, w in ipairs(self.Weapons) do
            if w.Clip < w.Parameters.ClipSize then
                return "SwitchWeaponToReload"
            end
        end
    end
    
    return s
end

local CAP_RANGE_ATTACKS = bit.bor(CAP_WEAPON_RANGE_ATTACK1,
CAP_WEAPON_RANGE_ATTACK2, CAP_INNATE_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK2)
local function CombatSchedule(self)
    local e = self:GetEnemy()
    local p = self:GetWeaponParameters()
    local s = nil
    local cap = isfunction(e.CapabilitiesGet) and e:CapabilitiesGet()
    local restdelay = math.max(p.MaxBurstRestDelay / 2, 1)
    local ismelee = p and p.IsMelee
    if self:HasCondition(c.COND_ENEMY_DEAD) then
        s = "IdleStand"
    elseif self:HasCondition(c.COND_SEE_GRENADE) then
        s = "GrenadeEscape"
    elseif not ismelee and self:HasCondition(c.COND_REPEATED_DAMAGE) then
        s = "TakeCoverFromEnemy"
    elseif self:HasCondition(c.COND_TOO_FAR_TO_ATTACK) then
        s = self:ScheduleDecision_ApproachEnemy()
    elseif self:HasCondition(c.COND_TOO_CLOSE_TO_ATTACK) then
        s = self:ScheduleDecision_TooCloseToEnemy()
    else
        s = self:ScheduleDecision_EstablishLOS()
    end
    
    return s
end

local SelectSchedule = {
    [NPC_STATE_IDLE] = IdleSchedule,
    [NPC_STATE_ALERT] = AlertSchedule,
    [NPC_STATE_COMBAT] = CombatSchedule,
}
function ENT:SelectSchedule(iNPCState)
    local s
    if self:TaskFailed() and self.Schedule.Fallback then
        s = self.Schedule.Fallback
    elseif self.Schedule.ChangeSchedule then
        s = self.Schedule.ChangeSchedule
    elseif SelectSchedule[iNPCState] then
        s = SelectSchedule[iNPCState](self)
    end

    self:text("SelectSchedule", self:GetEyePos() + vector_up * math.random(-3, 3) * 2, s)
    return s
end

function ENT:ScheduleDecision_ApproachEnemy()
    if self:HasCondition(c.COND_WEAPON_SIGHT_OCCLUDED)
    and self:HasCondition(c.COND_LOW_PRIMARY_AMMO) then
        return "HideAndReload"
    elseif not self.IsReloading
    and self:HasCondition(c.COND_SEE_ENEMY)
    and self.Weapons.ActiveWeaponID < #self.Weapons then
        return "SwitchWeaponToLongRange"
    else
        return "ChaseEnemy"
    end
end

function ENT:ScheduleDecision_TooCloseToEnemy()
    if not self.IsReloading and self.Weapons.ActiveWeaponID > 1 then
        return "SwitchWeaponToCloseRange"
    else
        return "MoveAwayFromEnemy"
    end
end

function ENT:ScheduleDecision_EstablishLOS()
    if self:HasCondition(c.COND_WEAPON_BLOCKED_BY_FRIEND) then
        return "MoveLateral"
    elseif self:HasCondition(c.COND_NO_PRIMARY_AMMO) then
        return "HideAndReload"
    elseif self:HasCondition(c.COND_WEAPON_SIGHT_OCCLUDED) then
        if self:HasCondition(c.COND_LOW_PRIMARY_AMMO) then
            return "HideAndReload"
        else
            return "EstablishLineOfFire"
        end
    elseif self:HasCondition(c.COND_NOT_FACING_ATTACK) then
        return "CombatFace"
    elseif self:HasCondition(c.COND_CAN_RANGE_ATTACK1) then
        if self:HasCondition(c.COND_LOW_PRIMARY_AMMO) then
            return "MoveAwayFromEnemy"
        elseif self:HasCondition(c.COND_SEE_ENEMY)
        and self:HasCondition(c.COND_ENEMY_FACING_ME)
        and self:HasCondition(c.COND_ENEMY_CAN_RANGE_ATTACK) then
            return "MoveLateral"
        else
            return "RangeAttack1"
        end
    elseif self:HasCondition(c.COND_CAN_MELEE_ATTACK1) then
        return "ChaseEnemy"
    elseif self:HasCondition(c.COND_BEHIND_ENEMY) then
        return "CombatStand"
    else
        return "EstablishLineOfFire"
    end
end

ENT.ScheduleList = {
    AlertStand = {
        "StopMoving",
        {"Wait", 3},
    },
    ChaseEnemy = {
        {"SetFailSchedule", "ChaseEnemyFailed"},
        "StopMoving",
        {"SetGoal", ENT.Enum.GoalType.GOAL_ENEMY},
        {"GetPathToGoal", ENT.Enum.PathType.PATH_TRAVEL},
        "WaitForMovement",
        "FaceEnemy",
    },
    ChaseEnemyFailed = {
        {"SetFailSchedule", "Standoff"},
        "StopMoving",
        {"Wait", 0.2},
        "FindCoverFromEnemy",
        "WaitForMovement",
        {"Remember", "Incover"},
        "FaceEnemy",
        {"Wait", 1}
    },
    CombatFace = {
        "StopMoving",
        "FaceEnemy",
    },
    CombatSlide = {
        {"SetFailSchedule", "ChaseEnemy"},
        {"SetFinalizeTask", "FinalizeCombatSlide"},
        "StopMoving",
        "WaitForLand",
        {"CombatSlide", "Maneuver"},
    },
    CombatStand = {
        "StopMoving",
        "WaitIndefinite",
    },
    Cower = {
        "StopMoving",
        {"PlaySequence", ACT_COWER},
        "WaitIndefinite",
    },
    EstablishLineOfFire = {
        {"SetFailSchedule", "EstablishLineOfFireFallback"},
        "GetPathToEnemyLOS",
        {"SpeakSentence", 1},
        "WaitForMovement",
        {"SetSchedule", "CombatFace"},
    },
    EstablishLineOfFireFallback = {
        "StopMoving",
        {"GetChasePathToEnemy", 300},
        "WaitForMovement",
        "FaceEnemy",
    },
    GoForwardSlide = {
        {"SetFinalizeTask", "FinalizeCombatSlide"},
        "StopMoving",
        "WaitForLand",
        "CombatSlide",
    },
    GrenadeEscape = {
        {"SetFailSchedule", "TakeCoverFromEnemy"},
        "StopMoving",
        "StoreFearPositionInSavePosition",
        {"SetGoal", ENT.Enum.GoalType.GOAL_SAVED_POSITION},
        {"GetPathToGoal", ENT.Enum.PathType.PATH_COVER},
        "WaitForMovement",
        "FaceEnemy",
        {"WaitUntilCondition", ENT.Enum.Conditions.COND_NO_GRENADE_NEARBY},
    },
    HideAndReload = {
        {"SetFailSchedule", "Reload"},
        "StopMoving",
        "FindCoverFromEnemy",
        "WaitForMovement",
        {"Remember", "Incover"},
        "FaceEnemy",
        {"SetSchedule", "Reload"},
    },
    IdleRappelUp = {
        {"SetFinalizeTask", "FinalizeRappel"},
        "StopMoving",
        "WaitForLand",
        {"Rappel", {
            angle = 0,
            cancelondamage = true,
            distance = 750,
            maxtime = 5,
            mintime = 0,
            stay = true,
            shoot = false,
            shouldslide = false,
        }},
    },
    IdleStand = {
        "StopMoving",
        "FaceReasonable",
        {"Wait", 5},
        "WaitPVS",
    },
    IdleWander = {
        {"SetRouteSearchTime", 5},
        {"GetPathToRandom", 200},
        "WaitForMovement",
        "FaceReasonable",
        "WaitPVS",
    },
    MeleeAttack1 = {
        "StopMoving",
        "FaceEnemy",
        {"AnnounceAttack", 1},
        "MeleeAttack1",
    },
    MoveAwayEnd = {
        "StopMoving",
        "FaceReasonable",
    },
    MoveAwayFail = {
        "StopMoving",
        {"SetSchedule", "TakeCoverFromEnemy"},
    },
    MoveAwayFromEnemy = {
        {"SetFailSchedule", "MoveAwayFail"},
        "FaceEnemy",
        {"MoveAwayPath", 240},
        "WaitForMovement",
        {"SetSchedule", "MoveAwayEnd"},
    },
    MoveLateral = {
        "StopMoving",
        "MoveLateral",
        "WaitForMovement",
        "FaceEnemy",
    },
    RangeAttack1 = {
        "StopMoving",
        "FaceEnemy",
        {"AnnounceAttack", 1},
        "RangeAttack1",
    },
    RappelApproach = {
        {"SetFailSchedule", "MoveLateral"},
        {"SetFinalizeTask", "FinalizeRappel"},
        "StopMoving",
        "WaitForLand",
        "FaceEnemy",
        {"Rappel", {
            angle = 0.5,
            distance = "Weapon",
            maxtime = 2,
            mintime = 0.7,
            shoot = false,
            shouldslide = true,
        }},
    },
    RappelUp = {
        {"SetFinalizeTask", "FinalizeRappel"},
        "StopMoving",
        "WaitForLand",
        "FaceEnemy",
        {"Rappel", {
            angle = 0,
            distance = 750,
            maxtime = 5,
            mintime = 0,
            stay = true,
            shoot = true,
            shouldslide = false,
        }},
        "WaitForLand",
    },
    Reload = {
        "StopMoving",
        "WaitForLand",
        "Reload",
        "WaitForSequence",
    },
    Standoff = {
        "StopMoving",
        {"WaitFaceEnemy", 2},
    },
    SwitchWeaponToCloseRange = {
        {"SwitchWeapon", "CloseRange"},
        {"SetSchedule", "TakeCoverFromEnemy"},
    },
    SwitchWeaponToLongRange = {
        {"SwitchWeapon", "LongRange"},
        {"SetSchedule", "EstablishLineOfFire"},
    },
    SwitchWeaponToReload = {
        {"SwitchWeapon", "Reload"},
    },
    TakeCoverFromEnemy = {
        "StopMoving",
        {"Wait", 0.2},
        {"SetToleranceDistance", 20},
        {"FindCoverFromEnemy", 24},
        "WaitForMovement",
        {"Remember", "Incover"},
        "FaceEnemy",
        {"Wait", 1},
    },
    TakeCoverSlide = {
        {"SetFailSchedule", "MoveLateral"},
        {"SetFinalizeTask", "FinalizeCombatSlide"},
        "StopMoving",
        "WaitForLand",
        {"CombatSlide", "Cover"},
    },
}
ENT.Interrupts = {
    AlertStand = {
        c.COND_NEW_ENEMY,
	    c.COND_LIGHT_DAMAGE,
	    c.COND_HEAVY_DAMAGE,
	    c.COND_SEE_ENEMY,
	    c.COND_CAN_RANGE_ATTACK1,
	    c.COND_CAN_RANGE_ATTACK2,
	    c.COND_CAN_MELEE_ATTACK1,
	    c.COND_CAN_MELEE_ATTACK2,
        c.COND_SEE_GRENADE,
    },
    CombatStand = {
	    c.COND_NEW_ENEMY,
	    c.COND_LIGHT_DAMAGE,
	    c.COND_HEAVY_DAMAGE,
	    c.COND_SEE_ENEMY,
	    c.COND_CAN_RANGE_ATTACK1,
	    c.COND_CAN_RANGE_ATTACK2,
	    c.COND_CAN_MELEE_ATTACK1,
	    c.COND_CAN_MELEE_ATTACK2,
        c.COND_SEE_GRENADE,
        c.COND_BULLET_NEAR,
    },
    ChaseEnemy = {
    	c.COND_NEW_ENEMY,
		c.COND_ENEMY_DEAD,
		c.COND_ENEMY_UNREACHABLE,
		c.COND_CAN_RANGE_ATTACK1,
		c.COND_CAN_MELEE_ATTACK1,
		c.COND_CAN_RANGE_ATTACK2,
        c.COND_CAN_MELEE_ATTACK2,
        c.COND_NO_PRIMARY_AMMO,
		c.COND_TOO_CLOSE_TO_ATTACK,
		c.COND_TASK_FAILED,
		c.COND_LOST_ENEMY,
		c.COND_BETTER_WEAPON_AVAILABLE,
		c.COND_HEAR_DANGER,
        c.COND_SEE_GRENADE,
    },
    ChaseEnemyFailed = {
        c.COND_NEW_ENEMY,
        c.COND_ENEMY_DEAD,
        c.COND_CAN_RANGE_ATTACK1,
        c.COND_CAN_MELEE_ATTACK1,
        c.COND_CAN_RANGE_ATTACK2,
        c.COND_CAN_MELEE_ATTACK2,
        c.COND_HEAR_DANGER,
        c.COND_BETTER_WEAPON_AVAILABLE,
        c.COND_LIGHT_DAMAGE,
        c.COND_HEAVY_DAMAGE,
    },
    CombatFace = {
    	c.COND_CAN_RANGE_ATTACK1,
		c.COND_CAN_RANGE_ATTACK2,
		c.COND_CAN_MELEE_ATTACK1,
		c.COND_CAN_MELEE_ATTACK2,
		c.COND_NEW_ENEMY,
		c.COND_ENEMY_DEAD,
    },
    CombatSlide = {},
    CombatStand = {
	    c.COND_NEW_ENEMY,
	    c.COND_ENEMY_DEAD,
	    c.COND_LIGHT_DAMAGE,
	    c.COND_HEAVY_DAMAGE,
	    c.COND_SEE_ENEMY,
	    c.COND_CAN_RANGE_ATTACK1,
	    c.COND_CAN_RANGE_ATTACK2,
	    c.COND_CAN_MELEE_ATTACK1,
	    c.COND_CAN_MELEE_ATTACK2,
        c.COND_SEE_GRENADE,
    },
    Cower = {
        c.COND_NO_GRENADE_NEARBY,
        c.COND_NO_HEAR_DANGER,
    },
    EstablishLineOfFire = {
    	c.COND_NEW_ENEMY,
		c.COND_ENEMY_DEAD,
		c.COND_LOST_ENEMY,
		c.COND_CAN_RANGE_ATTACK1,
		c.COND_CAN_MELEE_ATTACK1,
		c.COND_CAN_RANGE_ATTACK2,
		c.COND_CAN_MELEE_ATTACK2,
		c.COND_HEAR_DANGER,
        c.COND_SEE_GRENADE,
    },
    EstablishLineOfFireFallback = {
    	c.COND_NEW_ENEMY,
		c.COND_ENEMY_DEAD,
		c.COND_ENEMY_UNREACHABLE,
		c.COND_CAN_RANGE_ATTACK1,
		c.COND_CAN_MELEE_ATTACK1,
		c.COND_CAN_RANGE_ATTACK2,
		c.COND_CAN_MELEE_ATTACK2,
		c.COND_TOO_CLOSE_TO_ATTACK,
		c.COND_TASK_FAILED,
		c.COND_LOST_ENEMY,
		c.COND_BETTER_WEAPON_AVAILABLE,
		c.COND_HEAR_DANGER,
    },
    GoForwardSlide = {
        c.COND_TOO_CLOSE_TO_ATTACK,
    },
    GrenadeEscape = {
        c.COND_NO_GRENADE_NEARBY,
    },
    HideAndReload = {
        c.COND_HEAR_DANGER,
        c.COND_SEE_GRENADE,
        c.COND_LIGHT_DAMAGE,
    },
    IdleRappelUp = {
        c.COND_NEW_ENEMY,
    },
    IdleStand = {
        c.COND_NEW_ENEMY,
        c.COND_SEE_ENEMY,
        c.COND_SEE_FEAR,
        c.COND_LIGHT_DAMAGE,
        c.COND_CAN_RANGE_ATTACK1,
        c.COND_SMELL,
        c.COND_PROVOKED,
        c.COND_GIVE_WAY,
        c.COND_HEAR_PLAYER,
        c.COND_HEAR_DANGER,
        c.COND_HEAR_COMBAT,
        c.COND_HEAR_BULLET_IMPACT,
        c.COND_IDLE_INTERRUPT,
        c.COND_SEE_GRENADE,
    },
    IdleWander = {
        c.COND_GIVE_WAY,
        c.COND_HEAR_COMBAT,
        c.COND_HEAR_DANGER,
        c.COND_NEW_ENEMY,
        c.COND_SEE_ENEMY,
        c.COND_SEE_FEAR,
        c.COND_LIGHT_DAMAGE,
        c.COND_HEAVY_DAMAGE,
        c.COND_IDLE_INTERRUPT,
    },
    MeleeAttack1 = {
    	c.COND_NEW_ENEMY,
		c.COND_ENEMY_DEAD,
		c.COND_LIGHT_DAMAGE,
		c.COND_HEAVY_DAMAGE,
		c.COND_ENEMY_OCCLUDED,
        c.COND_TOO_FAR_TO_ATTACK,
        c.COND_NOT_FACING_ATTACK,
    },
    MoveAwayEnd = {
    	c.COND_NEW_ENEMY,
		c.COND_SEE_ENEMY,
		c.COND_SEE_FEAR,
		c.COND_LIGHT_DAMAGE,
		c.COND_HEAVY_DAMAGE,
		c.COND_PROVOKED,
		c.COND_SMELL,
		c.COND_HEAR_COMBAT,	-- sound flags
		c.COND_HEAR_WORLD,
		c.COND_HEAR_PLAYER,
		c.COND_HEAR_DANGER,
		c.COND_HEAR_BULLET_IMPACT,
		c.COND_IDLE_INTERRUPT,
    },
    MoveAwayFail = {},
    MoveAwayFromEnemy = {
        c.COND_NEW_ENEMY,
        c.COND_CAN_RANGE_ATTACK1,
        c.COND_CAN_RANGE_ATTACK2,
        c.COND_CAN_MELEE_ATTACK1,
        c.COND_CAN_MELEE_ATTACK2,
    },
    MoveLateral = {
        c.COND_TOO_CLOSE_TO_ATTACK,
    },
    RangeAttack1 = {
    	c.COND_NEW_ENEMY,
		c.COND_ENEMY_DEAD,
		c.COND_LIGHT_DAMAGE,
		c.COND_HEAVY_DAMAGE,
		c.COND_NO_PRIMARY_AMMO,
        c.COND_HEAR_DANGER,
        c.COND_TOO_CLOSE_TO_ATTACK,
        c.COND_TOO_FAR_TO_ATTACK,
        c.COND_NOT_FACING_ATTACK,
		c.COND_WEAPON_BLOCKED_BY_FRIEND,
		c.COND_WEAPON_SIGHT_OCCLUDED,
        c.COND_SEE_GRENADE,
    },
    RappelApproach = {},
    RappelUp = {
        c.COND_LIGHT_DAMAGE,
    },
    Reload = {
        c.COND_HEAR_DANGER,
    },
    Standoff = {
        c.COND_CAN_RANGE_ATTACK1,
        c.COND_CAN_RANGE_ATTACK2,
        c.COND_CAN_MELEE_ATTACK1,
        c.COND_CAN_MELEE_ATTACK2,
        c.COND_ENEMY_DEAD,
        c.COND_NEW_ENEMY,
        c.COND_HEAR_DANGER,
        c.COND_SEE_GRENADE,
    },
    SwitchWeaponToCloseRange = {},
    SwitchWeaponToLongRange = {},
    SwitchWeaponToReload = {},
    TakeCoverFromEnemy = {
        c.COND_NEW_ENEMY,
        c.COND_ENEMY_DEAD,
        c.COND_HEAR_DANGER,
    },
    TakeCoverSlide = {},
}
for name, sched in pairs(ENT.Interrupts) do
    local t = {}
    for _, c in ipairs(sched) do t[c] = true end
    ENT.Interrupts[name] = t
end
