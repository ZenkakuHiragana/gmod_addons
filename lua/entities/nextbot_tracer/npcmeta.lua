
local metatable = metatable or FindMetaTable("Entity")
local isnpc = metatable.IsNPC
function metatable:IsNPC() return self:GetClass() == self.classname or isnpc(self) end
function ENT:AddEntityRelationship() end
function ENT:AddRelationship() end
function ENT:AlertSound() end
function ENT:CapabilitiesAdd() end
function ENT:CapabilitiesClear() end
function ENT:CapabilitiesGet() return CAP_MOVE_GROUND end
function ENT:CapabilitiesRemove() end
function ENT:Classify() return CLASS_CITIZEN_REBEL end
function ENT:ClearCondition() end
function ENT:ClearEnemyMemory() end
function ENT:ClearExpression() end
function ENT:ClearGoal() end
function ENT:ClearSchedule() end
function ENT:ConditionName(id) return "Fake function lol" end
function ENT:Disposition() return D_HT end
function ENT:ExitScriptedSequence() end
function ENT:FearSound() end
function ENT:FoundEnemySound() end
function ENT:GetActiveWeapon() return self end
function ENT:GetArrivalActivity() return 0 end
function ENT:GetArrivalSequence() return 0 end
function ENT:GetBlockingEntity() return NULL end
function ENT:GetCurrentWeaponProficiency() return WEAPON_PROFICIENCY_PERFECT end
function ENT:GetExpression() return "" end
function ENT:GetHullType() return HULL_HUMAN end
function ENT:GetMovementActivity() return 0 end
function ENT:GetMovementSequence() return 0 end
function ENT:GetNPCState() return NPC_STATE_INVALID end
function ENT:GetPathDistanceToGoal() return 0 end
function ENT:GetPathTimeToGoal() return 0 end
function ENT:GetShootPos() return self:GetPos() end
function ENT:GetTarget() return self end
function ENT:Give(classname) return NULL end
function ENT:IdleSound() end
function ENT:IsCurrentSchedule(sched) return false end
function ENT:IsMoving() return self:GetVelocity():IsZero() end
function ENT:IsRunningBehavior() return false end
function ENT:IsUnreachable(testent) return false end
function ENT:LostEnemySound() end
function ENT:MaintainActivity() end
function ENT:MarkEnemyAsEluded() end
function ENT:MoveOrder() end
function ENT:NavSetGoal(pos) end
function ENT:NavSetGoalTarget(targetent, offset) end
function ENT:NavSetRandomGoal() end
function ENT:NavSetWanderGoal() end
function ENT:PlaySentence(sentence, delay, volume) return -1 end
function ENT:RemoveMemory() end
function ENT:RunEngineTask(taskID, taskData) end
function ENT:SentenceStop() end
function ENT:SetArrivalActivity(act) end
function ENT:SetArrivalDirection() end
function ENT:SetArrivalDistance() end
function ENT:SetArrivalSequence() end
function ENT:SetArrivalSpeed() end
function ENT:SetCondition(condition) end
function ENT:SetCurrentWeaponProficiency(proficiency) end
function ENT:SetExpression(expression) end
function ENT:SetHullSizeNormal() end
function ENT:SetHullType(hulltype) end
function ENT:SetLastPosition(position) end
function ENT:SetMaxRouteRebuildTime() end
function ENT:SetMovementActivity(activity) end
function ENT:SetMovementSequence(sequenceId) end
function ENT:SetNPCState(state) end
function ENT:SetTarget(ply) end
function ENT:StartEngineTask(task, taskData) end
function ENT:StopMoving() end
function ENT:TargetOrder() end
function ENT:TaskComplete() end
function ENT:TaskFail(task) end
function ENT:UseActBusyBehavior() end
function ENT:UseAssaultBehavior() end
function ENT:UseFollowBehavior() end
function ENT:UseFuncTankBehavior() end
function ENT:UseLeadBehavior() end
function ENT:UseNoBehavior() end