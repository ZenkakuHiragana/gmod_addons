AddCSLuaFile()

ENT.GreatZenkakuMan_IsFakeNPC = true
if not GreatZenkakuMan_FakeNextbotIsNPC then
    GreatZenkakuMan_FakeNextbotIsNPC = true
    local meta = FindMetaTable "NextBot" or FindMetaTable "Entity"
    local IsNPC = meta.IsNPC
    if isfunction(IsNPC) then
        function meta:IsNPC()
            return self.GreatZenkakuMan_IsFakeNPC or IsNPC(self)
        end
    else
        function meta:IsNPC()
            return self.GreatZenkakuMan_IsFakeNPC or false
        end
    end
end

function ENT:PercentageFrozen() return 0 end -- For SLV Base

if CLIENT then
    function ENT:GetActiveWeapon()
        return NULL
    end
    
    return
end

local NPCFunctions = {
    AddEntityRelationship = "nil",
    AddRelationship = "nil",
    AlertSound = "nil",
    CapabilitiesAdd = "nil",
    CapabilitiesClear = "nil",
    CapabilitiesGet = CAP_MOVE_GROUND,
    CapabilitiesRemove = "nil",
    Classify = CLASS_NONE,
    ClearCondition = "nil",
    ClearEnemyMemory = "nil",
    ClearExpression = "nil",
    ClearGoal = "nil",
    ClearSchedule = "nil",
    ConditionName = "Condition",
    Disposition = D_ER,
    ExitScriptedSequence = "nil",
    FearSound = "nil",
    FoundEnemySound = "nil",
    GetActiveWeapon = NULL,
    GetActivity = ACT_INVALID,
    GetAimVector = ENT.GetForward,
    GetArrivalActivity = ACT_INVALID,
    GetArrivalSequence = -1,
    GetBlockingEntity = NULL,
    GetCurrentSchedule = -1,
    GetCurrentWeaponProficiency = WEAPON_PROFICIENCY_POOR,
    GetEnemy = NULL,
    GetExpression = "",
    GetHullType = HULL_HUMAN,
    GetMovementActivity = ACT_INVALID,
    GetMovementSequence = -1,
    GetNPCState = NPC_STATE_INVALID,
    GetPathDistanceToGoal = 0,
    GetPathTimeToGoal = 0,
    GetShootPos = Vector(),
    GetTarget = NULL,
    Give = NULL,
    HasCondition = false,
    IdleSound = "nil",
    IsCurrentSchedule = false,
    IsMoving = false,
    IsRunningBehavior = false,
    IsUnreachable = false,
    LostEnemySound = "nil",
    MaintainActivity = "nil",
    MarkEnemyAsEluded = "nil",
    MoveOrder = "nil",
    NavSetGoal = "nil",
    NavSetGoalTarget = "nil",
    NavSetRandomGoal = "nil",
    NavSetWanderGoal = "nil",
    PlaySentence = -1,
    RemoveMemory = "nil",
    RunEngineTask = "nil",
    SentenceStop = "nil",
    SetArrivalActivity = "nil",
    SetArrivalDirection = "nil",
    SetArrivalDistance = "nil",
    SetArrivalSequence = "nil",
    SetArrivalSpeed = "nil",
    SetCondition = "nil",
    SetCurrentWeaponProficiency = "nil",
    SetEnemy = "nil",
    SetExpression = -1,
    SetHullSizeNormal = "nil",
    SetHullType = "nil",
    SetLastPosition = "nil",
    SetMaxRouteRebuildTime = "nil",
    SetMovementActivity = "nil",
    SetMovementSequence = "nil",
    SetNPCState = "nil",
    SetSchedule = "nil",
    SetTarget = "nil",
    StartEngineTask = "nil",
    StopMoving = "nil",
    TargetOrder = "nil",
    TaskComplete = "nil",
    TaskFail = "nil",
    UpdateEnemyMemory = "nil",
    UseActBusyBehavior = false,
    UseAssaultBehavior = false,
    UseFollowBehavior = false,
    UseFuncTankBehavior = false,
    UseLeadBehavior = false,
    UseNoBehavior = "nil",
}

local function empty() end
for name, value in pairs(NPCFunctions) do
    if value == "nil" then
        ENT[name] = empty
    elseif isfunction(value) then
        ENT[name] = value
    else
        ENT[name] = function() return value end
    end
end

for name, value in pairs(FindMetaTable "NPC") do
    if NPCFunctions[name] == nil and isfunction(value) then
        ENT[name] = ENT[name] or value
    end
end
