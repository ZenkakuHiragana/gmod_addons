
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
    "COND_SEE_ENEMY", -- Set if you are seeing the enemy
    "COND_LOST_ENEMY",
    "COND_ENEMY_WENT_NULL",	-- What most people think COND_LOST_ENEMY is: This condition is set in the edge case where you had an enemy last think, but don't have one this think.
    "COND_ENEMY_OCCLUDED",	-- Can't see m_hEnemy
    "COND_TARGET_OCCLUDED",	-- Can't see m_hTargetEnt
    "COND_HAVE_ENEMY_LOS", -- You can see the enemy if you rotate the head
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
    "COND_ENEMY_CAN_RANGE_ATTACK",
    "COND_RELOAD_FINISHED",
    "COND_RELOADING",
    "COND_SEE_LAST_POSITION",
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
        Register = {},
    }
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

function ENT:ManipulateCondition(state, name)
    if state then
        self:SetCondition(c[name])
    else
        self:ClearCondition(c[name])
    end
end

function ENT:RegisterCondition(state, name)
    self.Conditions.Register[name] = tobool(state)
end

function ENT:UnRegisterCondition(name)
    self.Conditions.Register[name] = nil
end

local MIN_SLIDE_SPEED_SQR = 100^2
local function IsGoodToSlide(self)
    if CurTime() < self.Time.NextCombatSlide then return end
    return false
end

local GRENADE_RADIUS = 512
local GRENADE_RADIUS_SQR = GRENADE_RADIUS^2
local function UpdateGreanadeConditions(self)
    self.FearPosition = nil
    self:ClearCondition(c.COND_SEE_GRENADE)
    self:SetCondition(c.COND_NO_GRENADE_NEARBY)
    local org = self:WorldSpaceCenter()
    for _, g in ipairs(ents.FindInSphere(self:GetPos(), GRENADE_RADIUS)) do
        if g:GetClass() == "npc_grenade_frag" or g:GetClass() == "grenade_hand" then
            local hitpos      = util.QuickTrace(g:GetPos(), g:GetVelocity()).HitPos
            local withinrange = self:GetRangeSquaredTo(hitpos) < GRENADE_RADIUS_SQR
            local speedsqr    = g:GetVelocity():LengthSqr()
            local incoming    = g:GetVelocity():Dot(g:GetPos() - org) < 0.25
            if withinrange and (incoming or speedsqr < 400)  then
                if not util.TraceLine {
                    start  = org,
                    endpos = g:GetPos(),
                    filter = {self, g},
                    mask   = MASK_SHOT,
                }.Hit then
                    self.FearPosition = hitpos
                    self:SetTarget(g)
                    self:SetCondition(c.COND_SEE_GRENADE)
                end
                
                self:ClearCondition(c.COND_NO_GRENADE_NEARBY)
            end
        end
    end
end

local CAP_RANGE_ATTACKS = bit.bor(
    CAP_WEAPON_RANGE_ATTACK1,
    CAP_WEAPON_RANGE_ATTACK2,
    CAP_INNATE_RANGE_ATTACK1,
    CAP_INNATE_RANGE_ATTACK2)
local function UpdateEnemyConditions(self)
    self:ClearCondition(c.COND_BEHIND_ENEMY)
    self:ClearCondition(c.COND_ENEMY_CAN_RANGE_ATTACK)
    self:ClearCondition(c.COND_ENEMY_DEAD)
    self:ClearCondition(c.COND_ENEMY_FACING_ME)
    self:ClearCondition(c.COND_ENEMY_OCCLUDED)
    self:ClearCondition(c.COND_ENEMY_UNREACHABLE)
    self:ClearCondition(c.COND_HAVE_ENEMY_LOS)
    self:ClearCondition(c.COND_LOST_ENEMY)
    self:ClearCondition(c.COND_NEW_ENEMY)
    self:ClearCondition(c.COND_SEE_ENEMY)

    if not self:HasValidEnemy() then return end
    local prevsee    = self.Conditions.PrevSeeEnemy
    local e          = self:GetEnemy()
    local lookat     = isfunction(e.GetAimVector) and e:GetAimVector() or e:GetForward()
    local toenemy    = e:EyePos() - self:GetEyePos()
    local cap        = isfunction(e.CapabilitiesGet) and e:CapabilitiesGet() or 0
    local canrange   = bit.band(cap, CAP_RANGE_ATTACKS) > 0 or e:IsPlayer()
    local dot        = lookat:Dot(toenemy:GetNormalized())
    local visible    = self:Visible(e)
    local tr         = self:GetTraceToLastPos()
    local trlensqr   = tr.StartPos:DistToSqr(self:GetLastPosition())
    local seelastpos = not tr.Hit
    local enemyseen  = CurTime() - self.Time.LastEnemySeen
    local lostenemy  = trlensqr < 60^2 or enemyseen > 10
    self:ManipulateCondition(dot > -0.7,             "COND_BEHIND_ENEMY"          )
    self:ManipulateCondition(not self:CheckAlive(e), "COND_ENEMY_DEAD"            )
    self:ManipulateCondition(canrange,               "COND_ENEMY_CAN_RANGE_ATTACK")
    self:ManipulateCondition(dot < -0.7,             "COND_ENEMY_FACING_ME"       )
    self:ManipulateCondition(not visible,            "COND_ENEMY_OCCLUDED"        )
    self:ManipulateCondition(self:IsUnreachable(e),  "COND_ENEMY_UNREACHABLE"     )
    self:ManipulateCondition(visible,                "COND_HAVE_ENEMY_LOS"        )
    self:ManipulateCondition(lostenemy,              "COND_LOST_ENEMY"            )
    self:ManipulateCondition(enemyseen < 0.2,        "COND_SEE_ENEMY"             )
    self:ManipulateCondition(seelastpos,             "COND_SEE_LAST_POSITION"     )

    self.Conditions.PrevSeeEnemy = self:HasCondition(c.COND_SEE_ENEMY)
    if prevsee and not self.Conditions.PrevSeeEnemy then -- predict enemy position
        self:SetLastPosition(self:GetLastPosition() + self:GetLastVelocity())
    end
end

local function UpdateWeaponConditions(self)
    self:ClearCondition(c.COND_CAN_MELEE_ATTACK1)
    self:ClearCondition(c.COND_CAN_RANGE_ATTACK1)
    self:ClearCondition(c.COND_LOW_PRIMARY_AMMO)
    self:ClearCondition(c.COND_NO_PRIMARY_AMMO)
    self:ClearCondition(c.COND_NO_WEAPON)
    self:ClearCondition(c.COND_NOT_FACING_ATTACK)
    self:ClearCondition(c.COND_RELOAD_FINISHED)
    self:ClearCondition(c.COND_RELOADING)
    self:ClearCondition(c.COND_TOO_CLOSE_TO_ATTACK)
    self:ClearCondition(c.COND_TOO_FAR_TO_ATTACK)
    self:ClearCondition(c.COND_WEAPON_BLOCKED_BY_FRIEND)
    self:ClearCondition(c.COND_WEAPON_HAS_LOS)
    self:ClearCondition(c.COND_WEAPON_SIGHT_OCCLUDED)

    local params = self:GetWeaponParameters()
    if not params then return end
    if not self:HasValidEnemy() then return end
    if not IsValid(self:GetActiveWeapon()) then
        self:SetCondition(c.COND_NO_WEAPON)
        return
    end

    local toenemy   = self:GetShootTo() - self:GetShootPos()
    local enemydir  = toenemy:GetNormalized()
    local distance  = toenemy:Length()
    local ismelee   = params.IsMelee
    local face      = ismelee and 0 or 0.9
    local clip      = self:GetClip()

    local facing    = enemydir:Dot(self:GetAimVector()) > face
    local tooclose  = distance < params.MinRange
    local toofar    = distance > params.MaxRange
    local hasLOS    = params.CheckLOS(self)
    local lowammo   = not params.UnlimitedAmmo and clip > 0 and clip < params.ClipSize / 2
    local noammo    = not params.UnlimitedAmmo and clip == 0
    local reloading = CurTime() < self.Time.FinishReloading
    local canattack = self:CanPrimaryFire() and self:HasCondition(c.COND_SEE_ENEMY)
    and facing and hasLOS and not (reloading or noammo or tooclose or toofar)
    local canmelee  = canattack and ismelee and CurTime() > self.Time.WeaponFire

    self:ManipulateCondition(canattack,  "COND_CAN_RANGE_ATTACK1"    )
    self:ManipulateCondition(canmelee,   "COND_CAN_MELEE_ATTACK1"    )
    self:ManipulateCondition(lowammo,    "COND_LOW_PRIMARY_AMMO"     )
    self:ManipulateCondition(noammo,     "COND_NO_PRIMARY_AMMO"      )
    self:ManipulateCondition(noweapon,   "COND_NO_WEAPON"            )
    self:ManipulateCondition(not facing, "COND_NOT_FACING_ATTACK"    )
    self:ManipulateCondition(reloading,  "COND_RELOADING"            )
    self:ManipulateCondition(tooclose,   "COND_TOO_CLOSE_TO_ATTACK"  )
    self:ManipulateCondition(toofar,     "COND_TOO_FAR_TO_ATTACK"    )
    self:ManipulateCondition(hasLOS,     "COND_WEAPON_HAS_LOS"       )
    self:ManipulateCondition(not hasLOS, "COND_WEAPON_SIGHT_OCCLUDED")
end

local function UpdateHealthConditions(self)
    local prevhealth = self.Conditions.Health or self:Health()
    local health_diff = prevhealth - self:Health()
    local cfg = self.Config
    local lightdmg = cfg.LightDamage
    local heavydmg = cfg.HeavyDamage
    local repdmg   = cfg.RepeatedDamage
    if lightdmg % 1 > 0 then lightdmg = lightdmg * self:GetMaxHealth() end
    if heavydmg % 1 > 0 then heavydmg = heavydmg * self:GetMaxHealth() end
    if repdmg   % 1 > 0 then repdmg   = repdmg   * self:GetMaxHealth() end
    self.Conditions.Health = self:Health()
    self:ManipulateCondition(health_diff > lightdmg,             "COND_LIGHT_DAMAGE"   )
    self:ManipulateCondition(health_diff > heavydmg,             "COND_HEAVY_DAMAGE"   )
    self:ManipulateCondition(self.Conditions.SumDamage > repdmg, "COND_REPEATED_DAMAGE")

    if CurTime() < self.Time.LastDamage + cfg.SumDamageDuration then return end
    self.Conditions.SumDamage = 0
end

function ENT:UpdateConditions()
    if CurTime() < self.Time.NextUpdateCondition then return end
    self.Time.NextUpdateCondition = CurTime() + 0.3

    if CurTime() > self.Time.LastHearBullet + 0.1 then
        self:ClearCondition(c.COND_BULLET_NEAR)
    end
    
    UpdateEnemyConditions(self)
    UpdateGreanadeConditions(self)
    UpdateHealthConditions(self)
    UpdateWeaponConditions(self)

    self:ManipulateCondition(not self:HasCondition(c.COND_GIVE_WAY), "COND_WAY_CLEAR")
    self:ManipulateCondition(self:CheckPVS(), "COND_IN_PVS")
    self:ManipulateCondition(IsGoodToSlide(self), "COND_GOOD_TO_SLIDE")
    self:ClearCondition(c.COND_SHOULD_CROUCH_SHOOT)

    for name, state in pairs(self.Conditions.Register) do
        self:ManipulateCondition(state, name)
        self.Conditions.Register[name] = nil
    end
end
