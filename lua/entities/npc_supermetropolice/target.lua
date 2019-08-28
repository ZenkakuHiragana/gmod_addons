
AccessorFunc(ENT, "m_vecLastPosition", "LastPosition")
AccessorFunc(ENT, "m_hEnemy", "Enemy")
AccessorFunc(ENT, "m_hTargetEnt", "Target")
function ENT:Initialize_Target()
    self.Time.LastEnemySeen = 0
    self.Time.NextFindEnemy = CurTime()
    self:SetLastPosition(Vector())
    self:SetEnemy(NULL)
    self:SetTarget(NULL)
end

function ENT:OnInjured_Target(d)
	if self:HasValidEnemy() then return end
    self:SetEnemy(d:GetAttacker())
end

function ENT:CheckAlive(ent)
	if not IsValid(ent) then return end
	return ent:GetInternalVariable "m_lifeState" == 0
end

function ENT:HasValidEnemy(e)
    local e = e or self:GetEnemy()
    if not IsValid(e) then return end
    if self:Disposition(e) ~= D_HT then return end
    if e:GetNoDraw() then return end
    return self:CheckAlive(e)
end

local FIND_CONE = math.cos(math.rad(90))
local MAX_DIST_SQR = 4096^2
function ENT:FindEnemy()
    if CurTime() < self.Time.NextFindEnemy then return end
    self.Time.NextFindEnemy = CurTime() + 0.5

    local targetlist = ents.FindInPVS(self)
    local nearestTarget, nearestDist = NULL, math.huge
    for i, e in ipairs(targetlist) do
        if self:Visible(e) and self:HasValidEnemy(e)
        and (self:GetForward():Dot(e:WorldSpaceCenter() - self:WorldSpaceCenter()) > 0
        or self:GetRangeSquaredTo(e) < MAX_DIST_SQR) then
            local d = self:GetRangeSquaredTo(e)
            if d < nearestDist then
                nearestTarget, nearestDist = e, d
            end
        end
    end

    if not IsValid(nearestTarget) then
        for _, a in ipairs(ents.FindByClass "npc_supermetropolice") do
            if a ~= self and self:GetRangeSquaredTo(a) < 9e+6 then
                if a:HasValidEnemy() then
                    nearestTarget = a:GetEnemy()
                    if a:HasCondition(a.Enum.Conditions.COND_SEE_ENEMY) then
                        self:SetLastPosition(a:GetLastPosition())
                    end

                    break
                end
            end
        end
    end

    if not IsValid(nearestTarget) then return end
    self:SetEnemy(nearestTarget)
end

function ENT:CheckPVS()
    local finish = player.GetCount() == 0
    for _, p in ipairs(player.GetAll()) do
        finish = finish or self:TestPVS(p)
        if finish then break end
    end

    return finish
end

function ENT:IsValidReasonableFacing()
    return true
end

function ENT:CalcReasonableDirection()
    local dir = self:GetForward()
    local idealYaw = 0
    local longestTrace = 0
    local Angles = Angle()
    local forward = Vector()
    local MIN_DIST = 5 * 12
    local SLICES = 8
    local SIZE_SLICE = 360 / SLICES
    local SEARCH_MAX = SLICES / 2
    local zEye = self:GetEyePos()
    for i = 0, SEARCH_MAX do
        local offset = i * SIZE_SLICE
        for k = -1, 1, 2 do
            Angles.y = offset * k + idealYaw
            forward = Angles:Forward()
            local tr = util.QuickTrace(zEye, forward * 16384, self)
            if tr.Fraction > longestTrace and self:IsValidReasonableFacing() then
                dir = forward
                longestTrace = tr.Fraction
            end

            if longestTrace > MIN_DIST then break end
            if i == 0 or i == SEARCH_MAX then break end
        end

        if longestTrace > MIN_DIST then break end
    end

    return dir
end
