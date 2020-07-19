
SuperMetropoliceBlockedNavAreas = SuperMetropoliceBlockedNavAreas or {}

local c = ENT.Enum.Conditions
function ENT:Initialize_Movement()
    self.loco:SetJumpHeight(100)
    self.loco:SetStepHeight(18 * 2)
    self.Approach = {}
    self.FaceTowards = {}
    self.IsJumpingAcrossGap = false
    self.NavAttr = 0
    self.Path = Path "Follow"
    self.Time.PathStuck = CurTime()
    self.Time.CheckHull = CurTime()
    self.TimeToRepath = 5
    self.DesiredGoal = Vector()
    self.DesiredPathTarget = NULL
	self.Path:SetMinLookAheadDistance(50)
    self.Path:SetGoalTolerance(20)
    self.PreviousPosition = Vector()
end

function ENT:RequestJump(dest, facetowards)
    if not dest then return end
    if not self.loco:IsOnGround() then return end
    self.FaceTowards.JumpAcrossGap = facetowards and dest or nil
    self.IsJumpingAcrossGap = true
    self.loco:JumpAcrossGap(dest, Vector())
end

function ENT:DoApproach()
    for key, data in pairs(self.Approach) do
        if isvector(data) then data = {goal = data} end
        self.loco:Approach(data.goal, data.weight or 1)
        if self.loco:IsClimbingOrJumping() or CurTime() - self.Time.PathStuck > 1 then
            local accel = data.goal - self:GetPos()
            accel:Normalize()
            accel:Mul(self.loco:GetAcceleration() * FrameTime() * FrameTime())
            self.loco:SetVelocity(self.loco:GetVelocity() + accel)
            self:SetPos(self:GetPos() + accel)
        end
    end
end

function ENT:DoFaceTowards()
    local target = nil

    if self.IsJumpingAcrossGap then
        target = self.FaceTowards.JumpAcrossGap
    elseif self.FaceTowards.CombatSlide then
        target = self.FaceTowards.CombatSlide
    elseif self.FaceTowards.ToTarget then
        target = self.FaceTowards.ToTarget
    elseif self:HasCondition(self.Enum.Conditions.COND_SEE_ENEMY) then
        target = self:GetShootTo()
    end

    if not target then return end
    self.loco:FaceTowards(target)
    if not self.loco:IsAttemptingToMove() then return end
    self.loco:FaceTowards(target)
end

function ENT:OnNavAreaChanged(old, new)
    self.NavAttr = new:GetAttributes()
    if not self.Unstucking then return end
    local id = new:GetID()
    if not id then return end
    if IsValid(SuperMetropoliceBlockedNavAreas[id]) then return end
    self.UnStucking = nil
    self.Path:Invalidate()
end

function ENT:IsUnreachable(test)
    if isentity(test) then
        if not IsValid(test) then return end
        test = test:WorldSpaceCenter()
    end

    local a = navmesh.GetNavArea(test, 150)
    return not (a and a:IsValid())
end

function ENT:HandleStuck()
    self.loco:ClearStuck()
    self.Approach.Fix = nil
    if not self.Path:IsValid() then return end
    -- local dz = vector_up * 32
    -- local goal = self.Path:GetCurrentGoal()
    -- local t = util.TraceHull {
    --     start = self:WorldSpaceCenter(),
    --     endpos = goal.pos,
    --     mins = self:OBBMins() + dz,
    --     maxs = self:OBBMaxs() - dz,
    --     filter = self,
    --     mask = MASK_NPCSOLID,
    -- }

    -- local a = navmesh.GetNavArea(t.HitPos, 100)
    -- local id = a and a:GetID()
    -- if id then SuperMetropoliceBlockedNavAreas[id] = t.Entity end
    -- self:ComputePath(self.Path:GetStart())
    -- self.UnStucking = true
end

function ENT:ComputePath(to)
    if self:IsUnreachable(to) then
        local start = self:GetPos()
        local mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 64)
        local tr = util.TraceHull {
            start = start,
            endpos = to,
            filter = self,
            mask = MASK_NPCSOLID_BRUSHONLY,
            maxs = maxs,
            mins = mins,
        }

        self:line("ComputePath", start, to, false, true)
        self:point("ComputePath", start, false, true)
        self:point("ComputePath", to, false, true)
        self:swept("ComputePath", start, tr.HitPos, mins, maxs)
        self:text("ComputePath", start, self.Schedule.CurrentSchedule)
        self:text("ComputePath", start + vector_up * 5, self.Schedule.CurrentTask)
        self:text("ComputePath", start + vector_up * 10, tostring(tr.StartSolid))
        to = tr.HitPos
    end
    
    local stepheight = self.loco:GetStepHeight()
    local ddheight = -self.loco:GetDeathDropHeight()
    local function PathGenerator(area, fromArea, ladder, elevator, length)
        if not IsValid(fromArea) then
            return 0 -- first area in path, no cost
        else
            if area:IsBlocked() then return -1 end
            local areaID = area:GetID()
            local attr = area:GetAttributes()
            if bit.band(attr, NAV_MESH_JUMP) > 0 then return -1 end
            -- if areaID and IsValid(SuperMetropoliceBlockedNavAreas[areaID]) then return -1 end
            if not self.loco:IsAreaTraversable(area) then return -1 end

            -- compute distance traveled along path so far
            local dist = 0
            if IsValid(ladder) then
                dist = ladder:GetLength()
            elseif length > 0 then
                dist = length -- optimization to avoid recomputing length
            else
                dist = area:GetCenter():Distance(fromArea:GetCenter())
            end

            -- check height change
            local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange(area)
            if deltaZ >= stepheight then
                return -1 -- too high to reach
            elseif deltaZ < ddheight then
                return -1 -- too far to drop
            end
            
            if bit.band(attr, NAV_MESH_AVOID) > 0 then dist = dist * 500 end
            return area:GetCostSoFar() + dist
        end
    end

    -- local j = self.loco:GetJumpHeight()
    -- local s = self.loco:GetStepHeight()
    -- self.loco:SetJumpHeight(0)
    -- self.loco:SetStepHeight(0)
    -- self.Path:Compute(self, to)
    -- self.loco:SetJumpHeight(j)
    -- self.loco:SetStepHeight(s)
    self.Path:Compute(self, to, PathGenerator)
end

function ENT:FixPath()
    local fix = -self:GetHitDirectionAround(nil, 12)
    if fix:IsZero() then
        self.Time.PathStuck = CurTime()
        self.Approach.Fix = nil
    else
        self.Approach.Fix = self:GetPos() + fix
        self:line("FixPath", self:GetPos(), self.Approach.Fix)
    end

    -- local numents = 0
    -- local vsum = self.loco:GetVelocity()
    -- local speedsqr = math.max(vsum:LengthSqr() / 4, 900)
    -- for _, e in ipairs(ents.FindInSphere(self:GetPos(), 64)) do
    --     local v = e:GetVelocity()
    --     if v:LengthSqr() > speedsqr and vsum:Dot(v) < 0 then
    --         numents = numents + 1
    --         vsum:Add(-v)
    --     end
    -- end

    -- if numents > 0 then
    --     vsum:Normalize()
    --     self:line("AvoidNPCs", self:GetPos(), self:GetPos() + vsum * 64)
    --     self.Approach.AvoidNPCs = {
    --         goal = self:GetPos() + vsum * 64,
    --         weight = 0.001,
    --     }
    -- else
    --     self.Approach.AvoidNPCs = nil
    -- end
end

function ENT:UpdatePath()
    if self.loco:IsStuck() then
        self:HandleStuck()
        return
    end

    if not self.Path:IsValid() then
        self.Time.PathStuck = CurTime()
        return
    end

    local goal = self.Path:GetCurrentGoal()
    if not self.Approach.Fix then self.Path:Update(self) end
    self:drawpath()
    self:point("UpdatePath", goal.pos, true)
    self:vector("UpdatePath", self:GetPos(), self.loco:GetVelocity(), true)
    
    local togoal = self:GetRangeSquaredTo(self.Path:GetClosestPosition(self:GetPos()))
    if self.Path:GetAge() > self.TimeToRepath or togoal > 1e4 then
        self:ComputePath(self.Path:GetEnd())
    end

    local nextgoal = self.Path:NextSegment()
    local priorgoal = self.Path:PriorSegment()
    local dz = goal and goal.pos.z - self:GetPos().z
    local toohigh = dz and dz > self.loco:GetStepHeight() / 2
    local canjump = dz and dz < self.loco:GetJumpHeight()
    if canjump and toohigh or priorgoal and nextgoal and (priorgoal.type == 2 or priorgoal.type == 3) then
        if not dz or dz^2 > self:GetRangeSquaredTo(goal.pos) then
            self:RequestJump(goal.pos, goal.forward)
        end
    end
end

function ENT:OnLandOnGround_Movement(ent)
    self.FaceTowards.JumpAcrossGap = nil
    self.IsJumpingAcrossGap = false
end

function ENT:IsCoverPosition(start, endpos)
    return util.TraceLine {
        start = start,
        endpos = endpos,
        mask = MASK_BLOCKLOS,
        collisiongroup = COLLISION_GROUP_WORLD,
    }.Hit
end

local MAX_SAMPLES = 200
local SAMPLES_PER_YIELD = 10
local SPOT_TYPE_ALL = 1 + 2 + 4 + 8
local SPOT_TYPE_SNIPER = 2 + 4
local function FindPos(self, vecThreat, min, max, isLOS)
    local params = self:GetWeaponParameters()
    local min2 = min^2
    local path = Path "Follow"
    local org = self:WorldSpaceCenter()
    local dz = vector_up * (self:GetEyePos().z - self:GetPos().z)
    local areas = navmesh.Find(org, max, self.loco:GetStepHeight(), self.loco:GetStepHeight())
    local toThreat = vecThreat - org
    local shortest, pos = math.huge, nil
    local shortest_alt, pos_alt = math.huge, nil
    local fSamples = MAX_SAMPLES / #areas
    local nSamples, fSamplesFrac = math.modf(fSamples)
    local fSamplesAccumlate = 0
    local nSamplesAccumlate = 0
    local evaluateFunction = isLOS and self:GetWeaponParameters().CheckLOS or self.IsCoverPosition
    toThreat.z = 0
    toThreat:Normalize()
    for _, a in ipairs(areas) do
        local spots = {}
        local n = nSamples
        fSamplesAccumlate = fSamplesAccumlate + fSamplesFrac
        if fSamplesAccumlate > 1 then n, fSamplesAccumlate = n + 1, 0 end
        for i = 1, n do spots[i] = a:GetRandomPoint() end
        table.Add(spots, a:GetHidingSpots(isLOS and SPOT_TYPE_ALL or SPOT_TYPE_SNIPER))
        for _, s in ipairs(spots) do
            nSamplesAccumlate = nSamplesAccumlate + 1
            if nSamplesAccumlate > SAMPLES_PER_YIELD then
                nSamplesAccumlate = 0
                coroutine.yield()
            end

            local s_up = s + dz
            local tospot = s_up - org
            self:point(isLOS and "FindLOSAll" or "FindCoverPosAll", s)
            if tospot:Length2DSqr() > min2 and evaluateFunction(self, s_up, vecThreat) then
                path:Compute(self, s)
                if path:IsValid() then
                    local forward = path:FirstSegment().forward
                    local length = path:GetLength()
                    if length < shortest and toThreat:Dot(forward) < 0 then
                        self:line(isLOS and "FindLOSAttempt" or "FindCoverPosAttempt", org, s)
                        self:line(isLOS and "FindLOSAttempt" or "FindCoverPosAttempt", vecThreat, s)
                        pos, shortest = s, length
                    elseif length < shortest_alt and toThreat:Dot(forward) > 0 then
                        self:line(isLOS and "FindLOSAttemptAlt" or "FindCoverPosAttemptAlt", org, s)
                        self:line(isLOS and "FindLOSAttemptAlt" or "FindCoverPosAttemptAlt", vecThreat, s)
                        pos_alt, shortest_alt = s, length
                    end
                end
            end
        end
    end

    return pos or pos_alt
end

local function TestLateralCover(self, endpos, start, min)
    return start:DistToSqr(endpos) > min^2 and self:IsCoverPosition(start, endpos)
end

local function FindLateralPos(self, vecThreat, min, isLOS)
    local org = self:GetEyePos()
    local COVER_CHECKS = 5
    local COVER_DELTA = 48
    local right = vecThreat - org
    right.z = 0
    right:Normalize()
    right.x, right.y = -right.y, right.x

    local dz = org - self:GetPos()
    local leftTest = org
    local rightTest = org
    local checkStart = vecThreat
    local stepRight = right * COVER_DELTA
    local evaluateFunction = isLOS and self:GetWeaponParameters().CheckLOS or TestLateralCover

    for i = 1, COVER_CHECKS do
        leftTest = leftTest - stepRight
        rightTest = rightTest + stepRight
        self:line(isLOS and "FindLateralLOS" or "FindLateralCover", checkStart, leftTest)
        self:line(isLOS and "FindLateralLOS" or "FindLateralCover", checkStart, rightTest)
        if evaluateFunction(self, leftTest, checkStart, min) then
            return leftTest - dz
        end

        if evaluateFunction(self, rightTest, checkStart, min) then
            return rightTest - dz
        end
    end
end

function ENT:FindLOS(vecThreat, min, max)
    return FindPos(self, vecThreat, min, max, true)
end

function ENT:FindLateralLOS(vecThreat)
    return FindLateralPos(self, vecThreat, nil, true)
end

function ENT:FindCoverPos(vecThreat, min, max)
    return FindPos(self, vecThreat, min, max, false)
end

function ENT:FindLateralCover(vecThreat, min)
    return FindLateralPos(self, vecThreat, min, false)
end
