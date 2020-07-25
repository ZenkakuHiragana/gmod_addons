
SuperMetropoliceBlockedNavAreas = SuperMetropoliceBlockedNavAreas or {}

local c = ENT.Enum.Conditions
function ENT:Initialize_Movement()
    self.loco:SetAcceleration(1600)
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

    if not test then debug.Trace() return true end
    local a = navmesh.GetNearestNavArea(test, false, 100, false, false)
    return not (a and a:IsValid())
end

function ENT:HandleStuck()
    self.loco:ClearStuck()
    self.Approach.Fix = nil
end

function ENT:ComputePath(to, path)
    if self:IsUnreachable(to) then
        local start = self:GetPos()
        local tr = self:TraceHullStand(nil, to, MASK_NPCSOLID_BRUSHONLY, self)

        self:line("ComputePath", start, to, false, true)
        self:point("ComputePath", start, false, true)
        self:point("ComputePath", to, false, true)
        self:swept("ComputePath", start, tr.HitPos, self:GetMins(), self:GetMaxs())
        self:text("ComputePath", start, self.Schedule.CurrentSchedule)
        self:text("ComputePath", start + vector_up * 5, self.Schedule.CurrentTask)
        self:text("ComputePath", start + vector_up * 10, tostring(tr.StartSolid))
        to = tr.HitPos
    end

    to = util.TraceLine {
        start = to + vector_up,
        endpos = to - vector_up * 16384,
        mask = MASK_NPCSOLID_BRUSHONLY,
        filter = self,
    }.HitPos
    
    local stepheight = self.loco:GetStepHeight()
    local ddheight = -self.loco:GetDeathDropHeight()
    local t0 = SysTime()
    local MAX_TIME = 0.010
    local function PathGenerator(area, fromArea, ladder, elevator, length)
        if SysTime() - t0 > MAX_TIME then return -1 end
        if not IsValid(fromArea) then
            return 0 -- first area in path, no cost
        else
            if not self.loco:IsAreaTraversable(area) then return -1 end
            -- if area:IsBlocked() then return -1 end
            -- local areaID = area:GetID()
            local attr = area:GetAttributes()
            -- if bit.band(attr, NAV_MESH_JUMP) > 0 then return -1 end
            -- if areaID and IsValid(SuperMetropoliceBlockedNavAreas[areaID]) then return -1 end

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
            elseif deltaZ <= -stepheight then
                return -1 -- too far to drop
            end
            
            if bit.band(attr, NAV_MESH_AVOID) > 0 then dist = dist * 500 end
            return area:GetCostSoFar() + dist
        end
    end
    
    local p = path or self.Path
    return p:Compute(self, to, PathGenerator)
end

function ENT:FixPath()
    local fix = -self:GetHitDirectionAround(nil, 12, nil, MASK_NPCSOLID)
    if fix:IsZero() then
        self.Time.PathStuck = CurTime()
        self.Approach.Fix = nil
    else
        self.Approach.Fix = self:GetPos() + fix
        self:line("FixPath", self:GetPos(), self.Approach.Fix)
    end
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
local function FindPos(self, vecThreat, min, max, spottype, evalFunc)
    local org = self:GetPos()
    local min2 = min^2
    local areas = navmesh.Find(org, max, self.loco:GetStepHeight(), self.loco:GetStepHeight())
    local path = Path "Follow"
    local pos = nil
    local fSamples = MAX_SAMPLES / #areas
    local nSamples, fSamplesFrac = math.modf(fSamples)
    local fSamplesAccumlate = 0
    local nSamplesAccumlate = 0
    for _, a in ipairs(areas) do
        local spots = {}
        local n = nSamples
        fSamplesAccumlate = fSamplesAccumlate + fSamplesFrac
        if fSamplesAccumlate > 1 then n, fSamplesAccumlate = n + 1, 0 end
        for i = 1, n do spots[i] = a:GetRandomPoint() end
        table.Add(spots, a:GetHidingSpots(spottype))
        for _, spot in ipairs(spots) do
            nSamplesAccumlate = nSamplesAccumlate + 1
            if nSamplesAccumlate > SAMPLES_PER_YIELD then
                nSamplesAccumlate = 0
                coroutine.yield()
            end

            if (spot - org):Length2DSqr() > min2 then
                path:Invalidate()
                self:ComputePath(spot, path)
                if path:IsValid() then
                    pos = evalFunc(self, spot, path, pos) or pos
                end 
            end
        end
    end

    path:Invalidate()
    return pos
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

local function GetEvalFunc(self, vecThreat, checkVisibility)
    local dz = vector_up * (self:GetEyePos().z - self:GetPos().z)
    local evaluation = self.Config.GetEvaluatePos(self, vecThreat)
    return function(self, spot, path, pos_candidate)
        if not checkVisibility(self, spot + dz, vecThreat) then return end
        return evaluation(self, vecThreat, spot, path, pos_candidate)
    end
end

function ENT:FindLOS(vecThreat, min, max)
    return FindPos(self, vecThreat, min, max, SPOT_TYPE_ALL,
    GetEvalFunc(self, vecThreat, self:GetWeaponParameters().CheckLOS))
end

function ENT:FindLateralLOS(vecThreat)
    return FindLateralPos(self, vecThreat, nil, true)
end

function ENT:FindCoverPos(vecThreat, min, max)
    return FindPos(self, vecThreat, min, max, SPOT_TYPE_SNIPER,
    GetEvalFunc(self, vecThreat, self.IsCoverPosition))
end

function ENT:FindLateralCover(vecThreat, min)
    return FindLateralPos(self, vecThreat, min, false)
end
