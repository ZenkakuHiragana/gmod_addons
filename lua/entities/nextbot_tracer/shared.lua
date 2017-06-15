
ENT.classname = "nextbot_tracer"

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "Nextbot Tracer"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true
ENT.Model = "models/player/ow_tracer.mdl"
ENT.SearchAngle = 60
ENT.MaxNavAreas = 400 --Maximum amount of searching NavAreas.
ENT.Bravery = 6

ENT.Act = {}
ENT.Act.Idle = ACT_HL2MP_IDLE_DUEL
ENT.Act.IdleCrouch = ACT_HL2MP_IDLE_CROUCH_DUEL
ENT.Act.Run = ACT_HL2MP_RUN_DUEL
ENT.Act.Walk = ACT_HL2MP_WALK_DUEL
ENT.Act.WalkCrouch = ACT_HL2MP_WALK_CROUCH_DUEL
ENT.Act.Attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL
ENT.Act.Melee = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
ENT.Act.Reload = ACT_HL2MP_GESTURE_RELOAD_DUEL

ENT.Dist = {}
ENT.Dist.Blink = 7 * 3.280839895 * 16 --blink distance in hammer unit, meters -> inches -> hammer units
ENT.Dist.BlinkSqr = ENT.Dist.Blink^2
ENT.Dist.FindSpots = 3000 --Search radius for finding where the nextbot should move to.
ENT.Dist.Grenade = 300 --Distance for detecting grenades.
ENT.Dist.GrenadeSqr = ENT.Dist.Grenade^2
ENT.Dist.Search = 4000 --Search radius for finding enemies.
ENT.Dist.ShootRange = 500
ENT.Dist.Manhack = ENT.Dist.Grenade / 2 --For Manhacks.
ENT.Dist.ManhackSqr = ENT.Dist.Manhack^2
ENT.Dist.Melee = 100
ENT.Dist.MeleeSqr = ENT.Dist.Melee^2
ENT.Dist.Mobbed = 300 --For Condition "Mobbed by Enemies"
ENT.Dist.MobbedSqr = ENT.Dist.Mobbed^2

ENT.HP = {}
ENT.HP.Init = 150

--GetConVar() needs to check if it's valid.  so this function wraps it.
function ENT:GetConVarBool(var)
	if not isstring(var) then return false end
	local convar = GetConVar(var)
	return convar and convar:GetBool()
end

--Returns the attachment of my eyes.
function ENT:GetEye()
	return self:GetAttachment(self:LookupAttachment("eyes"))
end

--Returns a table with information og what I am looking at.
function ENT:GetEyeTrace(dist)
	return util.QuickTrace(self:GetEye().Pos,
		self:GetEye().Ang:Forward() * (dist or 80), self)
end

--For Half Life Renaissance Reconstructed
function ENT:GetNoTarget()
	return false
end

--For Half Life Renaissance Reconstructed
function ENT:PercentageFrozen()
	return 0
end

list.Set("NPC", ENT.classname, {
	Name = "Nextbot Tracer",
	Class = ENT.classname,
	Category = "GreatZenkakuMan's NPCs"
})

local metatable = FindMetaTable("Entity")
local isnpc = metatable.IsNPC
--function metatable:IsNPC() return self:GetClass() == self.classname or isnpc(self) end
function metatable:AddEntityRelationship() end
function metatable:AddRelationship() end
function metatable:AlertSound() end
function metatable:CapabilitiesAdd() end
function metatable:CapabilitiesClear() end
function metatable:CapabilitiesGet() return CAP_MOVE_GROUND end
function metatable:CapabilitiesRemove() end
function metatable:Classify() return CLASS_CITIZEN_REBEL end
function metatable:ClearCondition() end
function metatable:ClearEnemyMemory() end
function metatable:ClearExpression() end
function metatable:ClearGoal() end
function metatable:ClearSchedule() end
function metatable:ConditionName(id) return "Fake function lol" end
function metatable:Disposition() return D_HT end
function metatable:ExitScriptedSequence() end
function metatable:FearSound() end
function metatable:FoundEnemySound() end
function metatable:GetActiveWeapon() return NULL end
function metatable:GetArrivalActivity() return 0 end
function metatable:GetArrivalSequence() return 0 end
function metatable:GetBlockingEntity() return NULL end
function metatable:GetCurrentWeaponProficiency() return WEAPON_PROFICIENCY_PERFECT end
function metatable:GetExpression() return "" end
function metatable:GetHullType() return HULL_HUMAN end
function metatable:GetMovementActivity() return 0 end
function metatable:GetMovementSequence() return 0 end
function metatable:GetNPCState() return NPC_STATE_INVALID end
function metatable:GetPathDistanceToGoal() return 0 end
function metatable:GetPathTimeToGoal() return 0 end
function metatable:GetShootPos() return self:GetPos() end
function metatable:GetTarget() return self:GetEnemy() end
function metatable:Give(classname) return NULL end
function metatable:IdleSound() end
function metatable:IsCurrentSchedule(sched) return false end
function metatable:IsMoving() return self:GetVelocity():IsZero() end
function metatable:IsRunningBehavior() return false end
function metatable:IsUnreachable(testent) return false end
function metatable:LostEnemySound() end
function metatable:MaintainActivity() end
function metatable:MarkEnemyAsEluded() end
function metatable:MoveOrder() end
function metatable:NavSetGoal(pos) end
function metatable:NavSetGoalTarget(targetent, offset) end
function metatable:NavSetRandomGoal() end
function metatable:NavSetWanderGoal() end
function metatable:PlaySentence(sentence, delay, volume) return -1 end
function metatable:RemoveMemory() end
function metatable:RunEngineTask(taskID, taskData) end
function metatable:SentenceStop() end
function metatable:SetArrivalActivity(act) end
function metatable:SetArrivalDirection() end
function metatable:SetArrivalDistance() end
function metatable:SetArrivalSequence() end
function metatable:SetArrivalSpeed() end
function metatable:SetCondition(condition) end
function metatable:SetCurrentWeaponProficiency(proficiency) end
function metatable:SetExpression(expression) end
function metatable:SetHullSizeNormal() end
function metatable:SetHullType(hulltype) end
function metatable:SetLastPosition(position) end
function metatable:SetMaxRouteRebuildTime() end
function metatable:SetMovementActivity(activity) end
function metatable:SetMovementSequence(sequenceId) end
function metatable:SetNPCState(state) end
function metatable:SetTarget(ply) end
function metatable:StartEngineTask(task, taskData) end
function metatable:StopMoving() end
function metatable:TargetOrder() end
function metatable:TaskComplete() end
function metatable:TaskFail(task) end
function metatable:UpdateEnemyMemory(enemy, pos) end
function metatable:UseActBusyBehavior() end
function metatable:UseAssaultBehavior() end
function metatable:UseFollowBehavior() end
function metatable:UseFuncTankBehavior() end
function metatable:UseLeadBehavior() end
function metatable:UseNoBehavior() end

--++Debugging functions++---------------------{
function ENT:ShowActAll()
	print("List of all available activities:")
	for i = 0, self:GetSequenceCount() - 1 do
		print(i .. " = " .. self:GetSequenceActivityName(i))
	end
end

function ENT:ShowSequenceAll()
	print("List of all available sequences:")
	PrintTable(self:GetSequenceList())
end

function ENT:ShowPoseParameters()
	for i = 0, self:GetNumPoseParameters() - 1 do
		local min, max = self:GetPoseParameterRange(i)
		print(self:GetPoseParameterName(i) .. " " .. min .. " / " .. max)
	end
end
----------------------------------------------}
