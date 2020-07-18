
ENT.ConditionNameList = {
    "COND_NONE",				-- A way for a function to return no condition to get

    "COND_IN_PVS",
    "COND_IDLE_INTERRUPT",	-- The schedule in question is a low priority idle, and therefore a candidate for translation into something else
    
    "COND_LOW_PRIMARY_AMMO",
    "COND_NO_PRIMARY_AMMO",
    "COND_NO_SECONDARY_AMMO",
    "COND_NO_WEAPON",
    "COND_SEE_HATE",
    "COND_SEE_FEAR",
    "COND_SEE_DISLIKE",
    "COND_SEE_ENEMY",
    "COND_LOST_ENEMY",
    "COND_ENEMY_WENT_NULL",	-- What most people think COND_LOST_ENEMY is: This condition is set in the edge case where you had an enemy last think, but don't have one this think.
    "COND_ENEMY_OCCLUDED",	-- Can't see m_hEnemy
    "COND_TARGET_OCCLUDED",	-- Can't see m_hTargetEnt
    "COND_HAVE_ENEMY_LOS",
    "COND_HAVE_TARGET_LOS",
    "COND_LIGHT_DAMAGE",
    "COND_HEAVY_DAMAGE",
    "COND_PHYSICS_DAMAGE",
    "COND_REPEATED_DAMAGE",	--  Damaged several times in a row

    "COND_CAN_RANGE_ATTACK1",	-- Hitscan weapon only
    "COND_CAN_RANGE_ATTACK2",	-- Grenade weapon only
    "COND_CAN_MELEE_ATTACK1",
    "COND_CAN_MELEE_ATTACK2",

    "COND_PROVOKED",
    "COND_NEW_ENEMY",

    "COND_ENEMY_TOO_FAR",		--	Can we get rid of this one!?!?
    "COND_ENEMY_FACING_ME",
    "COND_BEHIND_ENEMY",
    "COND_ENEMY_DEAD",
    "COND_ENEMY_UNREACHABLE",	-- Not connected to me via node graph

    "COND_SEE_PLAYER",
    "COND_LOST_PLAYER",
    "COND_SEE_NEMESIS",
    "COND_TASK_FAILED",
    "COND_SCHEDULE_DONE",
    "COND_SMELL",
    "COND_TOO_CLOSE_TO_ATTACK", -- FIXME: most of this next group are meaningless since they're shared between all attack checks!
    "COND_TOO_FAR_TO_ATTACK",
    "COND_NOT_FACING_ATTACK",
    "COND_WEAPON_HAS_LOS",
    "COND_WEAPON_BLOCKED_BY_FRIEND",	-- Friend between weapon and target
    "COND_WEAPON_PLAYER_IN_SPREAD",	    -- Player in shooting direction
    "COND_WEAPON_PLAYER_NEAR_TARGET",	-- Player near shooting position
    "COND_WEAPON_SIGHT_OCCLUDED",
    "COND_BETTER_WEAPON_AVAILABLE",
    "COND_HEALTH_ITEM_AVAILABLE",		-- There's a healthkit available.
    "COND_GIVE_WAY",					-- Another npc requested that I give way
    "COND_WAY_CLEAR",					-- I no longer have to give way
    "COND_HEAR_DANGER",
    "COND_HEAR_THUMPER",
    "COND_HEAR_BUGBAIT",
    "COND_HEAR_COMBAT",
    "COND_HEAR_WORLD",
    "COND_HEAR_PLAYER",
    "COND_HEAR_BULLET_IMPACT",
    "COND_HEAR_PHYSICS_DANGER",
    "COND_HEAR_MOVE_AWAY",
    "COND_HEAR_SPOOKY",				-- Zombies make this when Alyx is in darkness mode

    "COND_NO_HEAR_DANGER",			-- Since we can't use ~CONDITION. Mutually exclusive with COND_HEAR_DANGER

    "COND_FLOATING_OFF_GROUND",

    "COND_MOBBED_BY_ENEMIES",		-- Surrounded by a large number of enemies melee attacking me. (Zombies or Antlions, usually).

    -- Commander stuff
    "COND_RECEIVED_ORDERS",
    "COND_PLAYER_ADDED_TO_SQUAD",
    "COND_PLAYER_REMOVED_FROM_SQUAD",

    "COND_PLAYER_PUSHING",
    "COND_NPC_FREEZE",				-- We received an npc_freeze command while we were unfrozen
    "COND_NPC_UNFREEZE",			-- We received an npc_freeze command while we were frozen

    -- This is a talker condition, but done here because we need to handle it in base AI
    -- due to it's interaction with behaviors.
    "COND_TALKER_RESPOND_TO_QUESTION",
    
    "COND_NO_CUSTOM_INTERRUPTS",	-- Don't call BuildScheduleTestBits for this schedule. Used for schedules that must strictly control their interruptibility.

    -- ======================================
    -- IMPORTANT: This must be the last enum
    -- ======================================
    "LAST_SHARED_CONDITION",

    -- Custom conditions --------------
    "COND_SEE_GRENADE",
    "COND_NO_GRENADE_NEARBY",
    "COND_CAN_RAPPEL_UP",
    "COND_CAN_RAPPEL_FORWARD",
    "COND_GOOD_TO_SLIDE",
    "COND_SHOULD_CROUCH_SHOOT",
    "COND_BULLET_NEAR",
}

ENT.Enum.Conditions = {}
for i, c in ipairs(ENT.ConditionNameList) do
    ENT.Enum.Conditions[c] = i - 1
end

local c = ENT.Enum.Conditions
function ENT:Initialize_Conditions()
    self.Conditions = {
        Health = self:Health(),
        SumDamage = 0,
    }
    self.Time.GiveWay = CurTime()
    self.Time.LastDamage = CurTime()
    self.Time.LastHearBullet = CurTime()
    self.Time.NextUpdateCondition = CurTime()
end

function ENT:OnInjured_Condition(d)
    if d:GetDamage() == 0 then return end
    self.Conditions.SumDamage = d:GetDamage() + self.Conditions.SumDamage
    self.Time.LastDamage = CurTime()
end

function ENT:SetCondition(condition)
    self.Conditions[condition] = true
end

function ENT:ClearCondition(condition)
    self.Conditions[condition] = nil
end

function ENT:HasCondition(condition)
    return self.Conditions[condition]
end

function ENT:ConditionName(condition)
    if not isnumber(condition) then return end
    return self.ConditionNameList[condition + 1]
end

function ENT:ManipulateCondition(funcresult, conditionName)
    if funcresult then
        self:SetCondition(c[conditionName])
    else
        self:ClearCondition(c[conditionName])
    end
end

local GRENADE_RADIUS = 512
local GRENADE_RADIUS_SQR = GRENADE_RADIUS^2
function ENT:UpdateConditions()
    if CurTime() < self.Time.NextUpdateCondition then return end
    self.Time.NextUpdateCondition = CurTime() + 0.3

    local e = self:GetEnemy()
    local enemyisvalid = self:HasValidEnemy()
    local prevenemy = self.Conditions.Enemy or e
    local prevhealth = self.Conditions.Health or self:Health()
    local tookdamage = prevhealth - self:Health()
    local lookat = enemyisvalid and (isfunction(e.GetAimVector) and e:GetAimVector() or e:GetForward())
    local toenemy = enemyisvalid and (e:EyePos() - self:GetEyePos())
    local dot = enemyisvalid and lookat:Dot(toenemy:GetNormalized())
    local org = self:WorldSpaceCenter()
    local seegrenade, grenadenearby = false, false
    self.FearPosition = nil
    self.Conditions.Enemy = e
    self.Conditions.Health = self:Health()
    
    for _, g in ipairs(ents.FindInSphere(self:GetPos(), GRENADE_RADIUS)) do
        if g:GetClass() == "npc_grenade_frag" then
            local hitpos = util.QuickTrace(g:GetPos(), g:GetVelocity()).HitPos
            local withinrange = self:GetRangeSquaredTo(hitpos) < GRENADE_RADIUS_SQR
            local speedsqr = g:GetVelocity():LengthSqr()
            local incoming = g:GetVelocity():Dot(g:GetPos() - org) < 0.25
            if withinrange and (incoming or speedsqr < 400)  then
                local tr = util.TraceLine {
                    start = org,
                    endpos = g:GetPos(),
                    filter = {self, g},
                    mask = MASK_SHOT,
                }
                if not tr.Hit then
                    seegrenade = true
                    self.FearPosition = hitpos
                    self:SetTarget(g)
                end
                
                grenadenearby = true
            end
        end
    end

    if CurTime() > self.Time.LastDamage + 1 then
        self.Conditions.SumDamage = 0
    end

    if CurTime() > self.Time.LastHearBullet + 0.1 then
        self:ClearCondition(c.COND_BULLET_NEAR)
    end
    
    if CurTime() > self.Time.GiveWay then
        self:ClearCondition(c.COND_GIVE_WAY)
        self.Time.GiveWay = CurTime() + 5
    end
    
    self:ManipulateCondition(not self:HasCondition(c.COND_GIVE_WAY), "COND_WAY_CLEAR")
    self:ManipulateCondition(seegrenade, "COND_SEE_GRENADE")
    self:ManipulateCondition(not grenadenearby, "COND_NO_GRENADE_NEARBY")
    self:ManipulateCondition(prevenemy ~= e, "COND_NEW_ENEMY")
    self:ManipulateCondition(dot and dot < -0.7, "COND_ENEMY_FACING_ME")
    self:ManipulateCondition(dot and dot > -0.7, "COND_BEHIND_ENEMY")
    self:ManipulateCondition(not self:CheckAlive(e), "COND_ENEMY_DEAD")
    self:ManipulateCondition(self:IsUnreachable(e), "COND_ENEMY_UNREACHABLE")
    self:ManipulateCondition(tookdamage > 0, "COND_LIGHT_DAMAGE")
    self:ManipulateCondition(tookdamage > 20, "COND_HEAVY_DAMAGE")
    self:ManipulateCondition(self.Conditions.SumDamage > self:GetMaxHealth() * 0.05, "COND_REPEATED_DAMAGE")
    self:ManipulateCondition(self:CheckPVS(), "COND_IN_PVS")

    self:ClearCondition(c.COND_CAN_RAPPEL_UP)
    self:ClearCondition(c.COND_CAN_RAPPEL_FORWARD)
    self:ClearCondition(c.COND_GOOD_TO_SLIDE)
    self:ClearCondition(c.COND_HAVE_ENEMY_LOS)
    self:ClearCondition(c.COND_ENEMY_OCCLUDED)
    self:ClearCondition(c.COND_SEE_ENEMY)
    self:ClearCondition(c.COND_NO_WEAPON)
    self:ClearCondition(c.COND_WEAPON_HAS_LOS)
    self:ClearCondition(c.COND_WEAPON_SIGHT_OCCLUDED)
    self:ClearCondition(c.COND_TOO_FAR_TO_ATTACK)
    self:ClearCondition(c.COND_TOO_CLOSE_TO_ATTACK)
    self:ClearCondition(c.COND_LOW_PRIMARY_AMMO)
    self:ClearCondition(c.COND_NO_PRIMARY_AMMO)
    self:ClearCondition(c.COND_NOT_FACING_ATTACK)
    self:ClearCondition(c.COND_CAN_MELEE_ATTACK1)
    self:ClearCondition(c.COND_CAN_RANGE_ATTACK1)
    self:ClearCondition(c.COND_SHOULD_CROUCH_SHOOT)
    self.ForceCrouch = false

    local params = self.WeaponParameters
    local dz = vector_up * self.loco:GetStepHeight() / 2
    if not self:HasValidEnemy() or self:GetRangeSquaredTo(e) > 360000 then
        local dir = (vector_up + self:GetForward()) / 2
        local start = self:GetPos() + dz
        local trup = util.TraceHull {
            start = start,
            endpos = start + vector_up * 512,
            filter = self,
            mask = MASK_NPCSOLID_BRUSHONLY,
            mins = self:OBBMins(),
            maxs = self:OBBMaxs() - dz,
        }
        local trforward = util.TraceHull {
            start = start,
            endpos = start + dir * 512,
            filter = self,
            mask = MASK_NPCSOLID_BRUSHONLY,
            mins = self:OBBMins(),
            maxs = self:OBBMaxs() - dz,
        }
        self:ManipulateCondition(not (params and not params.AllowRappel or trup.Hit), "COND_CAN_RAPPEL_UP")
        self:ManipulateCondition(not (params and not params.AllowRappel or trforward.Hit), "COND_CAN_RAPPEL_FORWARD")
        self:swept("CanRappelUp", start, trup.HitPos, nil, nil, true)
        self:swept("CanRappelForward", start, trforward.HitPos, nil, nil, true)
    end

    if not enemyisvalid then return end
    local shootpos = self:GetShootPos()
    local targetpos = self:GetShootTo()
    local canslide = CurTime() > self.Time.NextCombatSlide
    local goodrange = self:GetRangeSquaredTo(self:GetLastPosition()) > 40000
    local ismelee = params and params.IsMelee
    local trleft = util.QuickTrace(targetpos, (self:GetRight() - e:GetForward()) * 160, {self, e})
    local trright = util.QuickTrace(targetpos, (-self:GetRight() - e:GetForward()) * 160, {self, e})
    trleft = not trleft.Hit and not util.TraceHull {start = self:GetPos() + dz, endpos = trleft.HitPos,
    filter = self, mins = self:OBBMins(), maxs = self:OBBMaxs() - dz}.Hit
    trright = not trright.Hit and not util.TraceHull {start = self:GetPos() + dz, endpos = trright.HitPos,
    filter = self, mins = self:OBBMins(), maxs = self:OBBMaxs() - dz}.Hit
    self:ManipulateCondition(canslide and goodrange and ismelee and trleft and trright, "COND_GOOD_TO_SLIDE")
    self:ManipulateCondition(self:Visible(e), "COND_HAVE_ENEMY_LOS")
    self:ManipulateCondition(not self:HasCondition(c.COND_HAVE_ENEMY_LOS), "COND_ENEMY_OCCLUDED")
    self:ManipulateCondition(self:HasCondition(c.COND_HAVE_ENEMY_LOS) and self:GetAimVector():Dot(toenemy) > 0.7, "COND_SEE_ENEMY")
    self:ManipulateCondition(not IsValid(self:GetActiveWeapon()), "COND_NO_WEAPON")

    if not IsValid(self:GetActiveWeapon()) then return end
    local CAP_RANGE_ATTACKS = bit.bor(CAP_WEAPON_RANGE_ATTACK1,
    CAP_WEAPON_RANGE_ATTACK2, CAP_INNATE_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK2)
    local toenemy = targetpos - shootpos
    local d = toenemy:Length()
    local cap = isfunction(e.CapabilitiesGet) and e:CapabilitiesGet() or 0
    local enemycanmelee = bit.band(cap, CAP_RANGE_ATTACKS) == 0
    local minrange = enemycanmelee and not ismelee and math.max(params.MinRange, 80) or params.MinRange
    local face_threshold = ismelee and 0 or 0.9
    toenemy:Normalize()
    self:ManipulateCondition(params.CheckLOS(self), "COND_WEAPON_HAS_LOS")
    self:ManipulateCondition(not self:HasCondition(c.COND_WEAPON_HAS_LOS), "COND_WEAPON_SIGHT_OCCLUDED")
    self:ManipulateCondition(d > params.MaxRange, "COND_TOO_FAR_TO_ATTACK")
    self:ManipulateCondition(d < minrange, "COND_TOO_CLOSE_TO_ATTACK")
    self:ManipulateCondition(not self.IsReloading and self.Clip > 0 and self.Clip < params.ClipSize / 2, "COND_LOW_PRIMARY_AMMO")
    self:ManipulateCondition(not self.IsReloading and self.Clip == 0, "COND_NO_PRIMARY_AMMO")
    self:ManipulateCondition(toenemy:Dot(self:GetAimVector()) < face_threshold, "COND_NOT_FACING_ATTACK")
    local canattack = self:CanPrimaryFire() and not (
        self:HasCondition(c.COND_WEAPON_SIGHT_OCCLUDED) or
        self:HasCondition(c.COND_WEAPON_BLOCKED_BY_FRIEND) or
        self:HasCondition(c.COND_TOO_FAR_TO_ATTACK) or
        self:HasCondition(c.COND_TOO_CLOSE_TO_ATTACK) or
        self:HasCondition(c.COND_NO_PRIMARY_AMMO) or
        self:HasCondition(c.COND_NOT_FACING_ATTACK))
    self:ManipulateCondition(canattack, "COND_CAN_RANGE_ATTACK1")
    self:ManipulateCondition(canattack, "COND_CAN_MELEE_ATTACK1")

    -- local crouch = {
    --     pistol = true,
    --     ar2 = true,
    --     smg = true,
    --     shotgun = true,
    -- }
    -- self:ClearCondition(c.COND_SHOULD_CROUCH_SHOOT)
    -- self.ForceCrouch = false
    -- if crouch[params.HoldType] then
    --     for _, e in ipairs(ents.FindInSphere(self:GetPos(), 100)) do
    --         if e.IsSuperMetropolice
    --         and self:CheckAlive(e)
    --         and crouch[e.WeaponParameters.HoldType] then
    --             local dir = self:GetPos() - e:GetPos()
    --             local dot = e:GetAimVector():Dot(dir:GetNormalized())
    --             if dot > 0.85 then
    --                 self:SetCondition(c.COND_SHOULD_CROUCH_SHOOT)
    --                 self.ForceCrouch = true
    --                 break
    --             end
    --         end
    --     end
    -- end
end
