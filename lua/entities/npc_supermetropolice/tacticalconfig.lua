
local function DefaultEnemyValue(self, e, lensqr)
    local distanceValue = 10000 / lensqr
    local healthValue = 1 / math.max(e:Health(), 1)
    return distanceValue + healthValue
end

local function DefaultEvaluatePos(self, vecThreat)
    local shortest = math.huge
    return function(self, vecThreat, spot, path, pos_candidate)
        local length = path:GetLength()
        if length > shortest then return end
        local toThreat = vecThreat - self:WorldSpaceCenter()
        local dot = toThreat:Dot(path:FirstSegment().forward)
        if dot < 0 then
            shortest = pos_candidate and length or math.huge
            return spot
        elseif not pos_candidate and dot > 0 then
            shortest = length
            return spot
        end
    end
end

local function DefaultMovingAnim(self, act)
    local c = self.Enum.Conditions
    if self:GetWeaponParameters().IsMelee
    or self:HasCondition(c.COND_WEAPON_SIGHT_OCCLUDED)
    or self:HasCondition(c.COND_SEE_GRENADE) then
        return ACT_HL2MP_RUN_FAST
    end

    return act
end

local function LongRangePos(self, vecThreat)
    local longest = 0
    return function(self, vecThreat, spot, path, pos_candidate)
        local length = vecThreat:DistToSqr(spot)
        if length < longest then return end
        local toThreat = vecThreat - self:WorldSpaceCenter()
        if toThreat:Dot(path:FirstSegment().forward) > 0 then return end
        longest = length
        return spot
    end
end

local function CloseRangePos(self, vecThreat)
    local shortest = math.huge
    return function(self, vecThreat, spot, path, pos_candidate)
        local length = path:GetLength()
        if length > shortest then return end
        shortest = length
        return spot
    end
end

local function CameraPos(self, vecThreat)
    local e = self:GetEnemy()
    local ef = IsValid(e) and e:GetForward() or -self:GetForward()
    return function(self, vecThreat, spot, path, pos_candidate)
        local toThreat = vecThreat - self:WorldSpaceCenter()
        if toThreat:Dot(path:FirstSegment().forward) > 0 then return end
        if ef:Dot(path:LastSegment().forward) > 0 then return spot end
    end
end

local function CameraMove(self, act)
    return ACT_HL2MP_RUN_FAST, 270
end

local function CameraEnemyValue(self, e, lensqr)
    local squad = ents.FindByClass(self.ClassName)
    local marked = 0
    for _, v in ipairs(squad) do
        if v ~= self and v:GetEnemy() == e
        and not v:HasCondition(v.Enum.Conditions.COND_SEE_ENEMY) then
            marked = marked + 1
        end
    end

    return marked
end

ENT.TacticalConfig = {
    Default = {
        GetEnemyValue = DefaultEnemyValue,
        GetEvaluatePos = DefaultEvaluatePos,
        HeavyDamage = 10,
        LightDamage = 1,
        RepeatedDamage = 0.05,
        SumDamageDuration = 1,
        SelectMovingAnim = DefaultMovingAnim,
        RandomPathRange = 200,
    },
    LongRange = {
        GetEvaluatePos = LongRangePos,
    },
    CloseRange = {
        GetEvaluatePos = CloseRangePos,
    },
    Camera = {
        GetEnemyValue = CameraEnemyValue,
        GetEvaluatePos = CameraPos,
        SelectMovingAnim = CameraMove,
        RandomPathRange = 2048,
    },
}

local LookupConfig = {
    gmod_camera      = "Camera",
    weapon_ar2       = "LongRange",
    weapon_frag      = "LongRange",
    weapon_rpg       = "LongRange",
    weapon_shotgun   = "CloseRange",
    weapon_stunstick = "CloseRange",
}

function ENT:SetTacticalConfig(name)
    self.Config = table.Copy(self.TacticalConfig.Default)
    table.Merge(self.Config, self.TacticalConfig[name] or {})
end

function ENT:SelectTacticalConfigByWeapon(weaponID)
    local wt = self.Weapons[weaponID]
    if not wt then return "Default" end
    local w = wt.Entity
    if not IsValid(w) then return "Default" end

    return LookupConfig[w:GetClass()] or "Default"
end
