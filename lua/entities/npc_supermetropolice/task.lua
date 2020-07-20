ENT.Enum.GoalType = {
    GOAL_NONE = -1,
    GOAL_ENEMY = 0, -- Our current enemy's position
    GOAL_TARGET = 1, -- Our current target's position
    GOAL_ENEMY_LKP = 2, -- Our current enemy's last known position
    GOAL_SAVED_POSITION = 3 -- Our saved position
}
ENT.Enum.PathType = {
    PATH_NONE = -1,
    PATH_TRAVEL = 0, -- Path that will take us to the goal
    PATH_LOS = 1, -- Path that gives us line of sight to our goal
    PATH_FLANK = 2, -- Path that will take us to a flanking position of our goal
    PATH_FLANK_LOS = 3, -- Path that will take us to within line of sight to the flanking position of our goal
    PATH_COVER = 4, -- Path that will give us cover from our goal
    PATH_COVER_LOS = 5 -- Path that will give us line of sight to cover from our goal
}
ENT.Enum.TaskStatus = {
    TASKSTATUS_NEW = 0, -- Just started
    TASKSTATUS_RUN_MOVE_AND_TASK = 1, -- Running task & movement
    TASKSTATUS_RUN_MOVE = 2, -- Just running movement
    TASKSTATUS_RUN_TASK = 3, -- Just running task
    TASKSTATUS_COMPLETE = 4 -- Completed, get next task
}
ENT.Enum.TaskFailure = {
    "NO_TASK_FAILURE",
    "FAIL_NO_TARGET",
    "FAIL_WEAPON_OWNED",
    "FAIL_ITEM_NO_FIND",
    "FAIL_NO_HINT_NODE",
    "FAIL_SCHEDULE_NOT_FOUND",
    "FAIL_NO_ENEMY",
    "FAIL_NO_BACKAWAY_NODE",
    "FAIL_NO_COVER",
    "FAIL_NO_FLANK",
    "FAIL_NO_SHOOT",
    "FAIL_NO_ROUTE",
    "FAIL_NO_ROUTE_GOAL",
    "FAIL_NO_ROUTE_BLOCKED",
    "FAIL_NO_ROUTE_ILLEGAL",
    "FAIL_NO_WALK",
    "FAIL_ALREADY_LOCKED",
    "FAIL_NO_SOUND",
    "FAIL_NO_SCENT",
    "FAIL_BAD_ACTIVITY",
    "FAIL_NO_GOAL",
    "FAIL_NO_PLAYER",
    "FAIL_NO_REACHABLE_NODE",
    "FAIL_NO_AI_NETWORK",
    "FAIL_BAD_POSITION",
    "FAIL_BAD_PATH_GOAL",
    "FAIL_STUCK_ONTOP",
    "FAIL_ITEM_TAKEN",
    "NUM_FAIL_CODES"
}
for i, t in ipairs(ENT.Enum.TaskFailure) do
    ENT.Enum.TaskFailure[t], ENT.Enum.TaskFailure[i] = i
end

local f = ENT.Enum.TaskFailure

-- Invalid Tasks ----------------------------------------------
function ENT:Task_Invalid()
    self:TaskComplete()
end

function ENT:Task_ResetActivity()
    self:StartActivity(ACT_RESET)
    self:TaskComplete()
end
-- Invalid Tasks ----------------------------------------------

-- Wait Tasks -------------------------------------------------
function ENT:Task_WaitForSequence()
    if not self.PlaySequence then self:TaskComplete() end
end

function ENT:Task_Wait(arg)
    local wait = arg or 0
    if CurTime() > self.Time.TaskStart + wait then
        self:TaskComplete()
    end
end

function ENT:Task_WaitRandom(arg)
    if self.Schedule.TaskStatus == self.Enum.TaskStatus.TASKSTATUS_NEW then
        local wait = arg or 0
        self.Schedule.TaskData = math.Rand(0, wait)
        self:TaskStatus(TASKSTATUS_RUN_MOVE_AND_TASK)
    end

    if CurTime() > self.Time.TaskStart + self.Schedule.TaskData then
        self:TaskComplete()
    end
end
ENT.Task_WaitFaceEnemy = ENT.Task_Wait
ENT.Task_WaitFaceEnemyRandom = ENT.Task_WaitRandom
function ENT:Task_WaitPVS()
    if self:CheckPVS() then self:TaskComplete() end
end

function ENT:Task_WaitIndefinite()
end

function ENT:Task_WaitForMovement()
    if not self.Path:IsValid() then self:TaskComplete() end
end
ENT.Task_WaitForMovementStep = ENT.Task_WaitForMovement

function ENT:Task_StopMoving()
    self.Path:Invalidate()
    self:TaskComplete()
end

function ENT:Task_WaitForLand()
    if self:OnGround() then self:TaskComplete() end
end

function ENT:Task_WaitUntilCondition(arg)
    if self:HasCondition(arg) then self:TaskComplete() end
end
-- Wait Tasks -------------------------------------------------

-- Target/Get Tasks -------------------------------------------
function ENT:Task_TargetPlayer()
    if player.GetCount() == 0 then
        self:TaskFail(f.FAIL_NO_PLAYER)
        return
    end

    local nearest, nearestDist = NULL, math.huge
    for _, p in ipairs(player.GetAll()) do
        local d = self:GetRangeSquaredTo(p:GetPos())
        if nearestDist > d then
            nearest, nearestDist = p, d
        end
    end

    if not IsValid(nearest) then
        self:TaskFail(f.FAIL_NO_PLAYER)
        return
    end
    
    self:SetEnemy(nearest)
    self:TaskComplete()
end

function ENT:Task_SetGoal(arg)
    local g = self.Enum.GoalType
    local goaltype = arg or 0
    if goaltype == g.GOAL_ENEMY then
        local e = self:GetEnemy()
        if not IsValid(e) then
            self:TaskFail(f.FAIL_NO_ENEMY)
            return
        end

        self.DesiredGoal = e:GetPos()
        self.DesiredPathTarget = e
    elseif goaltype == g.GOAL_ENEMY_LKP then
        local e = self:GetEnemy()
        if not IsValid(e) then
            self:TaskFail(f.FAIL_NO_ENEMY)
            return
        end

        self.DesiredGoal = self:GetLastPosition()
        self.DesiredPathTarget = NULL
    elseif goaltype == g.GOAL_TARGET then
        local t = self:GetTarget()
        if not IsValid(t) then
            self:TaskFail(f.FAIL_NO_TARGET)
            return
        end

        self.DesiredGoal = t:GetPos()
        self.DesiredPathTarget = t
    elseif goaltype == g.GOAL_SAVED_POSITION then
        self.DesiredGoal = self.SavedPosition or self:GetPos()
        self.DesiredPathTarget = NULL
    end
    
    self:TaskComplete()
end

function ENT:Task_GetPathToGoal(arg)
    local p = self.Enum.PathType
    local pathtype = arg or 0
    local foundpath = false
    local goal = self.DesiredGoal
    local target = self.DesiredPathTarget
    if pathtype == p.PATH_TRAVEL then
        if not goal then
            self:TaskFail(f.FAIL_NO_ROUTE_GOAL)
            return
        end

        self:ComputePath(goal)
        foundpath = self.Path:IsValid()
    elseif pathtype == p.PATH_LOS then
        local toofar = self.HasLongRange and 1e9 or 1024
        local max, min = 2000, 0
        local params = self:GetWeaponParameters()
        if params then
            max, min = params.MaxRange, params.MinRange
        end

        max = math.min(max, toofar) -- Check against NPC's max range
        local eyepos = IsValid(target) and target:EyePos() or goal
        local posLos = self:FindLOS(eyepos, min, max)
        if posLos then -- See if we've found it
            self:ComputePath(posLos)
            foundpath = self.Path:IsValid()
        else -- No LOS to goal
            self:TaskFail(f.FAIL_NO_SHOOT)
            return
        end
    elseif pathtype == p.PATH_COVER then
        local coverRadius = 1024
        local posCover = self:FindLateralCover(goal, 0) or self:FindCoverPos(goal, 0, coverRadius)
        if posCover then
            self:ComputePath(posCover)
            foundpath = self.Path:IsValid()
        else
            self:TaskFail(f.FAIL_NO_COVER)
            return
        end
    end

    if not foundpath then
        self:TaskFail(f.FAIL_NO_ROUTE)
        return
    end
    
    self:TaskComplete()
end

function ENT:Task_GetPathToEnemy()
    if not IsValid(self:GetEnemy()) then
        self:TaskFail(self.Enum.TaskFailure.FAIL_NO_ENEMY)
        return
    end

    self:ComputePath(self:GetEnemy():GetPos())
    self:TaskComplete()
end

function ENT:Task_GetPathToEnemyLKP()
    if not IsValid(self:GetEnemy()) then
        self:TaskFail(self.Enum.TaskFailure.FAIL_NO_ENEMY)
    end

    self:ComputePath(self:GetLastPosition())
    self:TaskComplete()
end

function ENT:Task_GetChasePathToEnemy(arg)
    if not IsValid(self:GetEnemy()) then
        self:TaskFail(self.Enum.TaskFailure.FAIL_NO_ENEMY)
        return
    end

    if self:GetShootTo():DistToSqr(self:GetLastPosition()) < arg^2 then
        self:Task_GetPathToEnemy()
    else
        self:Task_GetPathToEnemyLKP()
    end
end

function ENT:Task_GetPathToEnemyLOS(arg)
    if not IsValid(self:GetEnemy()) then
        self:TaskFail(f.FAIL_NO_ENEMY)
        return
    end

    local task = self.Schedule.CurrentTask
    local toofar = self.HasLongRange and 1e9 or 1024
    local max, min = 2000, 0
    local params = self:GetWeaponParameters()
    if params then
        max, min = params.MaxRange, params.MinRange
    end

    max = math.min(max, toofar) -- Check against NPC's max range
    local enemypos = self:GetShootTo()
    local posLos, found = nil, false
    if not task:find "Flank" then
        posLos = self:FindLateralLOS(enemypos) or self:FindLOS(enemypos, min, max)
        if posLos then
            local d = posLos:Distance(enemypos)
            found = min < d and d < max
        end
    end

    if not found then
        local flankType = 0 -- FLANKTYPE_NONE
        local refPos = Vector()
        local flankParam = 0
        if task == "GetFlankRadiusPathToEnemyLOS" then
            flankType = 2 -- FLANKTYPE_RADIUS
            refPos = self:GetPos() -- m_vSavePosition
            flankParam = arg
        elseif task == "GetFlankArcPathToEnemyLOS" then
            flankType = 1 -- FLANKTYPE_ARC
            refPos = self:GetPos() -- m_vSavePosition
            flankParam = arg
        end

        posLos = self:FindLOS(enemypos, min, max, flankType, refPos, flankParam)
    end

    if not posLos then -- No LOS to goal
        self:TaskFail(f.FAIL_NO_SHOOT)
        return
    end
    
    self:ComputePath(posLos)
    self:TaskComplete()
end

function ENT:Task_GetPathToEnemyCorpse()
    if not IsValid(self:GetEnemy()) then
        self:TaskFail(self.Enum.TaskFailure.FAIL_NO_ENEMY)
        return
    end

    self:ComputePath(self:GetLastPosition() - self:GetForward() * 64)
    self:TaskComplete()
end

ENT.Task_GetPathToEnemyLKPLOS = ENT.Task_GetPathToEnemyLOS

function ENT:Task_GetPathToRandom(arg)
    local dir = self:GetForward()
    local range = arg or 256
    range = range * math.Rand(0.5, 1)
    dir:Rotate(Angle(0, math.Rand(-180, 180), 0))
    local desired = self:GetPos() + dir * range
    self:ComputePath(self:TraceHullStand(nil, desired).HitPos)
    self:TaskComplete()
end

function ENT:Task_SetToleranceDistance(arg)
    self.Path:SetGoalTolerance(arg)
    self:TaskComplete()
end

function ENT:Task_SetRouteSearchTime(arg)
    self.TimeToRepath = arg
    self:TaskComplete()
end

function ENT:Task_FaceEnemy()
    if self:HasValidEnemy() then
        local e = self:GetEnemy()
        local forward = self:GetForward()
        local enemypos = self:GetShootTo()
        local toenemy = enemypos - self:WorldSpaceCenter()
        toenemy.z = 0
        toenemy:Normalize()
        if forward:Dot(toenemy) < 0.994 then
            self.FaceTowards.ToTarget = enemypos
            return
        end
    end

    self:TaskComplete()
end

function ENT:Task_FaceReasonable()
    if self.Schedule.TaskStatus == self.Enum.TaskStatus.TASKSTATUS_NEW then
        local dir = self:CalcReasonableDirection()
        self.FaceTowards.ToTarget = self:GetPos() + dir * 16384
        self.Schedule.TaskData = dir
        self:TaskStatus(TASKSTATUS_RUN_MOVE_AND_TASK)
    end

    if self.Schedule.TaskData:Dot(self:GetForward()) < 0.994 then
        return
    end
    self:TaskComplete()
end

function ENT:Task_SetFailSchedule(arg)
    self.Schedule.Fallback = arg
    self:TaskComplete()
end

function ENT:Task_SetSchedule(arg)
    self.Schedule.ChangeSchedule = arg
    self:TaskComplete()
end

function ENT:Task_SetFinalizeTask(arg)
    self.Schedule.TaskFinalize = arg
    self:TaskComplete()
end

function ENT:Task_RangeAttack1()
    if not self:PrimaryFire() then return end
    self:TaskComplete()
end

ENT.Task_MeleeAttack1 = ENT.Task_RangeAttack1

function ENT:Task_Reload()
    self:Reload()
    self:TaskComplete()
end

function ENT:Task_Remember(arg)
    self.Schedule.Memory[arg] = true
    self:TaskComplete()
end

function ENT:Task_Forget(arg)
    self.Schedule.Memory[arg] = nil
    self:TaskComplete()
end

function ENT:Task_AnnounceAttack(arg)
    self:TaskComplete()
end

function ENT:Task_SpeakSentence(arg)
    self:TaskComplete()
end

function ENT:Task_PlaySequence(arg)
    if isnumber(arg) then
        arg = self:SelectWeightedSequence(arg)
        arg = self:GetSequenceName(arg)
    end

    self.PlaySequence = arg
    self:TaskComplete()
end

function ENT:Task_SetActivity(arg)
    -- self:SetActivity(arg) -- Dummy!!
    self:TaskComplete()
end

function ENT:Task_RunPath()
    self:TaskComplete()
end

function ENT:Task_WalkPath()
    self:TaskComplete()
end

function ENT:Task_FindCoverFromEnemy(arg)
    local task = self.Schedule.CurrentTask
    local bNodeCover = task ~= "FindCoverFromEnemy"
    local min = task == "FindFarNodeCoverFromEnemy" and arg or 0
    local max = task == "FindNearNodeCoverFromEnemy" and arg or 1024
    local pos = self:WorldSpaceCenter() + self:GetForward()
    if self:HasValidEnemy() then
        pos = self:GetEnemy():WorldSpaceCenter()
    end

    local cover = self:FindLateralCover(pos, 0) or self:FindCoverPos(pos, min, max)
    if not cover then
        self:TaskFail(f.FAIL_NO_COVER)
        return
    end
    
    self:ComputePath(cover)
    self:TaskComplete()
end

ENT.Task_FindFarNodeCoverFromEnemy = ENT.Task_FindCoverFromEnemy
ENT.Task_FindNearNodeCoverFromEnemy = ENT.Task_FindCoverFromEnemy

function ENT:Task_MoveAwayPath(arg)
    local ROTATE_STEP = 22.5
    local ang = self:GetAngles():SnapTo("y", ROTATE_STEP)
    local org = self:GetPos() + vector_up * 7
    local pos = org - ang:Forward() * arg
    local attempts = {}
    self:swept("MoveAwayPath", org, pos)
    if self:TraceHull(org, pos).Hit then
        pos = nil
        for i = 1, 6 do
            local left = Angle(ang)
            local right = Angle(ang)
            left:RotateAroundAxis(vector_up, ROTATE_STEP * i)
            right:RotateAroundAxis(vector_up, -ROTATE_STEP * i)
            local trleft = self:TraceHull(org, org - left:Forward() * arg)
            local trright = self:TraceHull(org, org - right:Forward() * arg)
            self:swept("MoveAwayPath", org, trleft.HitPos)
            self:swept("MoveAwayPath", org, trright.HitPos)

            table.insert(attempts, {pos = trleft.HitPos, frac = trleft.Fraction})
            table.insert(attempts, {pos = trright.HitPos, frac = trright.Fraction})
            if not (trleft.Hit or trright.Hit) then
                pos = math.random() > 0.5 and trleft.HitPos or trright.HitPos
                break
            elseif trleft.Hit and not trright.Hit then
                pos = trright.HitPos
                break
            elseif trright.Hit and not trleft.Hit then
                pos = trleft.HitPos
                break
            end
        end

        if not pos then
            table.SortByMember(attempts, "frac", true)
            pos = attempts[1].pos
        end
    end

    self:ComputePath(pos)
    if not self.Path:IsValid() or self.Path:GetLength() < arg / 2 then
        self:TaskFail(f.FAIL_BAD_PATH_GOAL)
        return
    end

    self:TaskComplete()
end

function ENT:Task_MoveLateral()
    if not self.Path:IsValid() then
        local dir = math.random() > .5 and 100 or -100
        local pos = self:TraceHullStand(nil, self:GetPos() + self:GetRight() * dir).HitPos
        self:ComputePath(pos)
    end

    self:TaskComplete()
end

function ENT:Task_IgnoreOldEnemies()
    self:TaskComplete()
end

function ENT:Task_StoreFearPositionInSavePosition()
    self:TaskComplete()
    if not self.FearPosition then
        self:TaskFail(f.FAIL_NO_GOAL)
        return
    end

    self.SavedPosition = self.FearPosition
end

function ENT:Task_SetSequence(arg)
    self.ForceSequence = arg
    self:TaskComplete()
end

function ENT:Task_Rappel(arg)
    local accel = arg.acceleration or 600
    local c = self.Enum.Conditions
    local status = self.Schedule.TaskStatus
    local ts = self.Enum.TaskStatus
    if self.Schedule.TaskStatus == self.Enum.TaskStatus.TASKSTATUS_NEW then
        -- self.ForceSequence = "deploy"
        self.Schedule.TaskData = CurTime() + 0.6
        self:TaskStatus(ts.TASKSTATUS_RUN_TASK)
        return
    elseif status == ts.TASKSTATUS_RUN_TASK then
        if CurTime() < self.Schedule.TaskData then return end
        self:RequestJump(self:GetPos())
        self:TaskStatus(TASKSTATUS_RUN_MOVE)
        self.loco:SetVelocity(vector_origin)
        local ratio = arg.angle
        local dir = vector_up * (1 - ratio) + self:GetForward() * ratio
        local distance = arg.distance
        if distance == "Weapon" then
            distance = 900
            if self:HasValidEnemy() then
                local p = self:GetWeaponParameters()
                local range = self:GetRangeTo(self:GetEnemy())
                distance = math.max(500, math.min(range, range - p.MaxRange)) * 0.7
            end
        end

        local tr = util.QuickTrace(self:WorldSpaceCenter(), dir * distance, self)
        local anchor, ap = constraint.CreateStaticAnchorPoint(
            self:GetAttachment(self:LookupAttachment "anim_attachment_LH").Pos)
        local rope = constraint.CreateKeyframeRope(
            self:WorldSpaceCenter(), 1, "cable/cable_metalwinch01", nil,
            anchor, vector_origin, 0,
            self, self:WorldSpaceCenter() - self:GetPos(), 0, {
                Breakable = 0,
                Collide = 1,
                Dangling = 0,
                Length = tr.HitPos:Distance(self:WorldSpaceCenter()) + 100,
                spawnflags = 1,
                target = self:GetName(),
                parentname = self:GetName(),
                Type = 0,
            })
        anchor:SetNoDraw(false)
        anchor:SetModelScale(0.2)
        ap:EnableCollisions(true)
        ap:EnableMotion(true)
        ap:EnableGravity(false)
        ap:SetVelocity(dir * 4096)
        self:DeleteOnRemove(anchor)
        self.ForceActivity = ACT_HL2MP_SWIM
        self.ForceSequence = nil
        self.RappelAnchor = anchor
        self.RappelRope = rope
        self.Schedule.TaskData = {
            ap = ap,
            filter = {self, anchor, rope},
            pos = tr.HitPos,
            time = CurTime(),
            startpos = self:GetPos(),
            velocity = Vector(),
        }
    end

    if arg.shoot and self:HasCondition(c.COND_WEAPON_HAS_LOS) then
        self:PrimaryFire()
    end

    local data = self.Schedule.TaskData
    local span = arg.maxtime
    local dt = CurTime() - data.time
    local timefrac = dt / span
    local dir = data.pos - self:WorldSpaceCenter()
    local ang = self:GetAngles()
    local distance = data.pos:Distance(self:WorldSpaceCenter())
    local mul = 1
    local lookat = arg.shoot and self:GetShootTo() or nil
    dir:Normalize()
    
    self.FaceTowards.JumpAcrossGap = lookat
    self.DesiredPitch = math.deg(math.acos(dir.z, -1, 1))
    if arg.stay and distance < 300 then
        mul = (distance - 200) / 100
        if mul < 0.1 then self.DesiredPitch = 0 end
    end
    
    self.RappelRope:SetKeyValue("Length", distance + 100)
    data.velocity:Add(dir * accel * FrameTime())
    self.loco:SetVelocity(data.velocity * mul)
    if data.ap:IsMotionEnabled() and dir:Dot(data.ap:GetPos() - data.pos) > 0 then
        data.ap:SetPos(data.pos)
        data.ap:EnableMotion(false)
    end
    
    local tr = util.QuickTrace(self:WorldSpaceCenter(), data.velocity / 5, data.filter)
    if dir.z < 0 or timefrac > 1 or distance < 100 or tr.Hit then
        if tr.Hit and self:GetRangeSquaredTo(data.startpos) < 0.01 then
            self:TaskFail(f.FAIL_BAD_POSITION)
            return
        end

        if arg.shouldslide and dt > arg.mintime then
            self.PlayLandAnimation = false
            self.Schedule.ChangeSchedule = "GoForwardSlide"
        end

        self:TaskComplete()
    end
end

function ENT:Task_FinalizeRappel()
    self.ForceSequence = nil
    self.ForceActivity = nil
    self.FaceTowards.JumpAcrossGap = nil
    self.DesiredPitch = 0
    local anchor2, ap2 = constraint.CreateStaticAnchorPoint(self:WorldSpaceCenter())
    if IsValid(anchor2) then
        anchor2:SetNoDraw(false)
        anchor2:SetModelScale(0.2)
        anchor2:PhysicsInit(SOLID_VPHYSICS)
        anchor2:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        anchor2:PhysWake()
        anchor2:Activate()
        SafeRemoveEntityDelayed(anchor2, 3)
    end

    if IsValid(self.RappelAnchor) then
        self.RappelAnchor:SetNoDraw(false)
        self.RappelAnchor:PhysicsInit(SOLID_VPHYSICS)
        self.RappelAnchor:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self.RappelAnchor:PhysWake()
        self.RappelAnchor:Activate()
        SafeRemoveEntityDelayed(self.RappelAnchor, 3)
    end

    if IsValid(self.RappelRope) then
        self.RappelRope:SetEntity("EndEntity", anchor2)
        self.RappelRope:SetKeyValue("EndOffset", "0 0 0")
        SafeRemoveEntityDelayed(self.RappelRope, 3)
    end
end

local SLIDE_VELOCITY = 500
local SLIDE_TIME = 1
local SLIDE_DISTANCE = SLIDE_VELOCITY * SLIDE_TIME
local MIN_SLIDE_DISTANCE_SQR = 30^2
function ENT:Task_CombatSlide(arg)
    if CurTime() < self.Time.NextCombatSlide then return end
    
    local c = self.Enum.Conditions
    local ts = self.Enum.TaskStatus
    if self.Schedule.TaskStatus == ts.TASKSTATUS_NEW then
        local pos = self:GetPos() + self:GetForward() * SLIDE_DISTANCE
        if arg == "PathFollow" and self.Path:IsValid() then
            pos = self.Path:GetEnd()
        elseif self:HasValidEnemy() then
            local e = self:GetEnemy()
            local sign = math.random() > 0.5 and 1 or -1
            if arg == "Cover" then
                pos = self:FindLateralCover(self:GetShootTo(), 50)
                or self:GetPos() + self:GetRight() * sign * SLIDE_DISTANCE
            elseif arg == "Maneuver" then
                local side = e:GetPos() + self:GetRight() * sign * 55
                local toside = side - self:GetPos()
                if toside:Length() > SLIDE_DISTANCE * 0.75 then
                    self:TaskFail(f.FAIL_BAD_POSITION)
                    return
                end
                
                toside:Normalize()
                toside:Mul(SLIDE_DISTANCE)
                pos = self:GetPos() + toside
            end
        end
        
        local dir = pos - self:GetPos()
        local lsqr = dir:LengthSqr()
        if lsqr < MIN_SLIDE_DISTANCE_SQR then
            self:TaskFail(f.FAIL_BAD_PATH_GOAL)
            return
        end

        dir:Normalize()
        self.Approach.CombatSlide = pos
        self.DesiredPitch = -45
        self.DesiredSpeed = SLIDE_VELOCITY
        self.FaceTowards.CombatSlide = pos
        self.ForceActivity = ACT_HL2MP_SIT
        self.ForceSequence = nil
        self.MaxPitchRollRate = 900
        self.Schedule.TaskData = {
            time = CurTime(),
            pos = self:GetPos() + dir * SLIDE_VELOCITY * FrameTime(),
        }
        self.loco:SetVelocity(dir * SLIDE_VELOCITY)
        self:TaskStatus(ts.TASKSTATUS_RUN_MOVE)
    end

    if self:HasCondition(c.COND_CAN_RANGE_ATTACK1) then
        self:PrimaryFire()
    end

    if self:OnGround() then
        local e = EffectData()
        e:SetOrigin(self:GetPos() + vector_up + VectorRand())
        e:SetNormal(-self:GetForward())
        e:SetScale(2)
        util.Effect("ManhackSparks", e)
    end
    
    if CurTime() - self.Schedule.TaskData.time > 0.6
    or arg == "Maneuver" and self:HasCondition(c.COND_NOT_FACING_ATTACK)
    or self.loco:GetVelocity():Dot(self:GetForward()) < -0.7
    or self:GetRangeSquaredTo(self.Schedule.TaskData.pos) == 0 then
        self:TaskComplete()
    end

    self.Schedule.TaskData.pos = self:GetPos()
end

function ENT:Task_FinalizeCombatSlide()
    self.MaxPitchRollRate = self.loco:GetMaxYawRate()
    self.Approach.CombatSlide = nil
    self.FaceTowards.CombatSlide = nil
    self.ForceActivity = nil
    self.PlayLandAnimation = true
    self.DesiredPitch = 0
    self.DesiredSpeed = nil
    self.Time.NextCombatSlide = CurTime() + 0.8
end

function ENT:Task_SwitchWeapon(arg)
    self:TaskComplete()
    if arg == "Reload" then
        for i, w in ipairs(self.Weapons) do
            if w.Clip < w.Parameters.ClipSize then
                self:SetActiveWeapon(i)
                return
            end
        end
    elseif arg == "CloseRange" or arg == "LongRange" then
        if not IsValid(self:GetEnemy()) then
            self:TaskFail(f.FAIL_NO_ENEMY)
            return
        end

        local close = arg == "CloseRange"
        local dist = self:GetRangeTo(self:GetEnemy())
        local first, last, step = 1, #self.Weapons, 1
        if close then first, last, step = last, first, -step end
        for i = first, last, step do -- Weapons are sorted by their range
            local p = self.Weapons[i].Parameters
            if Either(close, p.MinRange < dist, dist < p.MaxRange) then
                self:SetActiveWeapon(i)
                return
            end
        end

        self:SetActiveWeapon(close and 1 or #self.Weapons)
    end
end
