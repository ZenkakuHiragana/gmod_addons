
AddCSLuaFile "cl_init.lua"
include "debug.lua"
include "shared.lua"
include "animation.lua"
include "conditions.lua"
include "movement.lua"
include "relationship.lua"
include "task.lua"
include "tacticalconfig.lua"
include "schedule.lua"
include "target.lua"
include "trace.lua"
include "weapon.lua"

ENT.IsSuperMetropolice = true
ENT.MaxHealth = 40
ENT.CollisionBoundMaxs = Vector(16, 16, 72)
ENT.CollisionBoundMaxsCrouched = Vector(16, 16, 36)
ENT.CollisionBoundMins = Vector(-16, -16, 0)

local BULLET_NEAR_DISTANCE_SQR = 50^2
hook.Add("EntityFireBullets", "GreatZenkakuMan's Nextbot EntityFireBullets", function(ent, bullet)
    local dir = bullet.Dir:GetNormalized()
    local org = bullet.Src
    local length = bullet.Distance
    for i, self in ipairs(ents.FindByClass "npc_supermetropolice") do
        if self:HasValidEnemy(ent) then
            local org2 = self:WorldSpaceCenter()
            local dir2 = org2 - org
            if dir2:GetNormalized():Dot(dir) > 0.7 then
                local length2 = dir:Dot(dir2)
                local endpos = org + dir * math.min(length, length2)
                local radiussqr = org2:DistToSqr(endpos)
                if radiussqr < BULLET_NEAR_DISTANCE_SQR then
                    self:RegisterCondition(true, "COND_BULLET_NEAR")
                    self.Time.LastHearBullet = CurTime()
                end
            end
        end
    end
end)

function ENT:RunHook(prefix, ...)
    for name, func in pairs(self:GetTable()) do
        if name ~= prefix and name:StartWith(prefix) then
            func(self, ...)
        end
    end
end

function ENT:Initialize()
    self:SetModel "models/player/police_fem.mdl"
    self:SetMaxHealth(self.MaxHealth)
    self:SetHealth(self:GetMaxHealth())
    self:AddFlags(FL_NPC)
    self:AddFlags(FL_OBJECT)
    self:SetSolid(SOLID_BBOX)
    self:PhysicsInitShadow()
    self:SetCollisionBounds(self.CollisionBoundMins, self.CollisionBoundMaxs)
    self:SetBloodColor(BLOOD_COLOR_ANTLION_WORKER)
    self.Time = {}
    self.Coroutines = {}
    self:RunHook "Initialize"
    self:AddCallback("PhysicsCollide", function(self, data)
        self:RunHook("PhysicsCollide", data)
    end)
end

function ENT:OnInjured(d)
    self:RunHook("OnInjured", d)
    self.BaseClass.OnInjured(self, d)
end

function ENT:OnKilled(d)
    self:RunHook("OnKilled", d)
    self.BaseClass.OnKilled(self, d)
end

function ENT:OnOtherKilled(victim, d)
    self.BaseClass.OnOtherKilled(self, victim, d)
    if self:HasValidEnemy() then return end
    if self:Disposition(victim) ~= D_LI then return end
    self:SetEnemy(d:GetAttacker())
end

function ENT:OnLandOnGround(ent)
    self:RunHook("OnLandOnGround", ent)
end

function ENT:OnContact(ent)
    if not IsValid(ent) then return end
    self:RunHook("OnContact", ent)
end

local function ShouldStopSchedule(self)
    return self:TaskFailed()
    or self.Schedule.ChangeSchedule
    or self.Schedule.CeaseSchedule
    or self:HasInterrupt()
end

local Benchmark = true
function ENT:RunTaskBatch(task)
    if Benchmark then
        util.TimerCycle()
        self:UpdateConditions()
        local max, str = util.TimerCycle(), "UpdateConditions"
        self:CheckCrouching()
        self:DoTask(task)
        local t = util.TimerCycle()
        if max < t then max, str = t, self.Schedule.CurrentTask end
        self:DoApproach()
        local t = util.TimerCycle()
        if max < t then max, str = t, "DoApproach" end
        self:DoFaceTowards()
        local t = util.TimerCycle()
        if max < t then max, str = t, "DoFaceTowards" end
        self:UpdatePath()
        local t = util.TimerCycle()
        if max < t then max, str = t, "UpdatePath" end
        if max > 1 then self:print("Benchmark", max, str) end
        self:FixPath()
        self:FireWeapon()
    else
        self:UpdateConditions()
        self:CheckCrouching()
        self:DoTask(task)
        self:DoApproach()
        self:DoFaceTowards()
        self:UpdatePath()
        self:FixPath()
        self:FireWeapon()
    end
end

function ENT:RunScheduleLoop()
    for _, task in ipairs(self.ScheduleList[self.Schedule.CurrentSchedule]) do
        self.Schedule.CurrentTask = isstring(task) and task or istable(task) and task[1] or ""
        self:print("TaskStart", self.Schedule.CurrentTask)
        self:OnTaskInitialize()
        while not self:TaskFinished() do
            if self.PlaySequence then
                self:PlaySequenceAndWait(self.PlaySequence)
                self:StartActivity(ACT_INVALID)
                self.PlaySequence = nil
            end

            self:FindEnemy()
            self:point("LastPos", self:GetLastPosition())
            if self:HasValidEnemy() then
                local e = self:GetEnemy()
                local epos = e:EyePos()
                local toenemy = epos - self:EyePos()
                local edir = toenemy:GetNormalized()
                if self:Visible(e) and self:GetAimVector():Dot(edir) > 0.7 then
                    self:SetLastPosition(epos)
                    self:SetLastVelocity(e:GetVelocity())
                    self.Time.LastEnemySeen = CurTime()
                end
            end

            self:RunTaskBatch(task)
            self.PreviousPosition = self:GetPos()
            if ShouldStopSchedule(self) then return end

            coroutine.yield()
        end
    end
end

function ENT:MainLoop()
    self:SelectNPCState()
    self.Schedule.CurrentSchedule = self:SelectSchedule(self.Schedule.NPCState)
    if self.Schedule.CurrentSchedule and self.ScheduleList[self.Schedule.CurrentSchedule] then
        self:OnScheduleInitialize()
        self:print("ScheduleStart", self.Schedule.CurrentSchedule)
        self:RunScheduleLoop()

        if self.Schedule.TaskFinalize then
            local t = self.Schedule.TaskFinalize
            local name = istable(t) and t[1] or t
            local arg = istable(t) and t[2] or nil
            self.Schedule.CurrentTask = name
            self:DoTask {name, arg}
        end
    end
end

function ENT:DisabledMainLoop()
    if Entity(1):KeyDown(IN_ATTACK2) then
        self:ComputePath(Entity(1):GetEyeTrace().HitPos)
    end
    
    self:UpdateConditions()
    self:CheckCrouching()
    self:DoApproach()
    self:DoFaceTowards()
    self:UpdatePath()
    self:FixPath()
end

function ENT:RunBehaviour()
    local disabledAI = GetConVar "ai_disabled"
    while true do
        if not disabledAI:GetBool() then
            self:MainLoop()
        else
            self:DisabledMainLoop()
        end
        
        coroutine.yield()
    end
end

function ENT:BehaveUpdate(fInterval)
    if not self.BehaveThread then return end

    -- Give a silent warning to developers if RunBehaviour has returned
    if coroutine.status(self.BehaveThread) == "dead" then
        self.BehaveThread = nil
        print(self, "Warning: ENT:RunBehaviour() has finished executing")
        return
    end

    self:print("fInterval", fInterval)
    -- Continue RunBehaviour's execution
    local ok, msg = coroutine.resume(self.BehaveThread)
    if not ok then
        self.BehaveThread = nil
        ErrorNoHalt(self, " Error: ", msg, "\n")
        return
    end

    for name, c in pairs(self.Coroutines) do
        if coroutine.status(c) == "dead" then
            self.Coroutines[name] = nil
        else
            local ok, msg = coroutine.resume(c, self)
            if not ok then
                self.Coroutines[name] = nil
                ErrorNoHalt(self, name, " Error: ", msg, "\n")
            end
        end
    end
end

function ENT:OnKilled_Dissolve(dmg)
    if not dmg:IsDamageType(DMG_DISSOLVE) then return end
    if self:IsFlagSet(FL_DISSOLVING) then return end
    local d = ents.Create "env_entity_dissolver"
    if not IsValid(d) then return end
    self:SetName("Dissolved GreatZenkakuMan's Nextbot" .. self:EntIndex())
    d:Fire("Dissolve", self:GetName())
    
    for _, wt in ipairs(self.Weapons) do
        local w = wt.Entity
        if IsValid(w) then
            w:SetName("Dissolved GreatZenkakuMan's Nextbot Weapon" .. w:EntIndex())
            d:Fire("Dissolve", w:GetName())
        end
    end

    d:Remove()
    dmg:SetDamageForce(vector_origin)
end

function ENT:PhysicsCollide_ApplyPhysicsDamage(data)
    local ent = data.HitEntity
    local phys = data.HitObject
    local dvsqr = data.TheirOldVelocity:DistToSqr(data.TheirNewVelocity)
    local damage = math.floor(dvsqr * phys:GetMass() / 100000)
    if ent:IsPlayerHolding() then return end
    if ent:GetClass() == "prop_combine_ball" then return end
    if damage < 5 then return end
    local dmg = DamageInfo()
    if ent:IsVehicle() and IsValid(ent:GetDriver()) then
        dmg:SetAttacker(ent:GetDriver())
    elseif IsValid(ent:GetPhysicsAttacker()) then
        dmg:SetAttacker(ent:GetPhysicsAttacker())
    else
        dmg:SetAttacker(ent)
    end

    dmg:SetInflictor(ent)
    dmg:SetDamage(damage)
    dmg:SetDamageType(ent:IsVehicle() and DMG_VEHICLE or DMG_CRUSH)
    dmg:SetDamageForce(phys:GetVelocity())
    self:TakeDamageInfo(dmg)
end
