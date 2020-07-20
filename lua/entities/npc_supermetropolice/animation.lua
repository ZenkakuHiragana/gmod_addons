
include "ai_translations.lua"

function ENT:Initialize_Animation()
    self.PoseParameterIDs = {}
    for i = 0, self:GetNumPoseParameters() - 1 do
        self.PoseParameterIDs[self:GetPoseParameterName(i)] = i
    end

    local pitchid = self:LookupPoseParameter "aim_pitch"
    local yawid = self:LookupPoseParameter "aim_yaw"
    self.aim_pitch_min, self.aim_pitch_max = self:GetPoseParameterRange(pitchid)
    self.aim_yaw_min, self.aim_yaw_max = self:GetPoseParameterRange(yawid)
    self.aim_pitch, self.aim_yaw = 0, 0

    self.DesiredPitch = 0
    self.DesiredRoll = 0
    self.ShouldAim = false
    self.AimVector = Vector()
    self.PlayLandAnimation = true
    self.MaxPitchRollRate = self.loco:GetMaxYawRate()
end

if not ENT.LookupPoseParameter then
    function ENT:LookupPoseParameter(name)
        return self.PoseParameterIDs[name]
    end
end

function ENT:SetActivity(act)
    if self:GetActivity() ~= act then
        self:StartActivity(act)
    end
end

function ENT:SetMovementActivity(act, speed)
    self:SetActivity(act)
    local seq = self:SelectWeightedSequence(act)
    self.CurrentDesiredSpeed = self.DesiredSpeed or speed or self:GetSequenceGroundSpeed(seq)
    self.loco:SetDesiredSpeed(math.max(self.CurrentDesiredSpeed, 50))
end

function ENT:CheckCrouching()
    if self.ForceCrouch then
        self.Crouching = true
        return
    end
    
    local org = self:GetPos()
    local t = self:TraceHullStand(org, nil, MASK_NPCSOLID, ents.FindByClass(self.ClassName))
    local mins, maxs = self:GetHull(true)
    self:box("CheckCrouching", org + vector_up * 7, mins, maxs, true)
    self.Crouching = t.Hit
end

function ENT:UpdateAimParameters()
    local p, y = -self:GetAngles().pitch, 0
    if self:HasValidEnemy() and not self:HasCondition(self.Enum.Conditions.COND_WEAPON_SIGHT_OCCLUDED) then
        local from = self:GetShootPos()
        local to = self:GetShootTo()
        local dz = from.z - self:GetPos().z
        local dir = self:WorldToLocal(to - vector_up * dz)
        local ang = dir:Angle()
        ang:Normalize()
        p, y = p + ang.pitch, ang.yaw
        self:print("UpdateAimParameters", p, y)
        self:line("UpdateAimParameters", self:GetPos() + vector_up * dz, to, true)
    end

    local rate = self.loco:GetMaxYawRate() * FrameTime()
    local dp = p - self.aim_pitch
    local dy = y - self.aim_yaw
    if math.abs(dp) > rate then
        local sp = dp == 0 and 0 or dp > 0 and 1 or -1
        self.aim_pitch = math.NormalizeAngle(self.aim_pitch + sp * rate)
    else
        self.aim_pitch = math.NormalizeAngle(p)
    end

    if math.abs(dy) > rate then
        local sy = dy == 0 and 0 or dy > 0 and 1 or -1
        self.aim_yaw = math.NormalizeAngle(self.aim_yaw + sy * rate)
    else
        self.aim_yaw = math.NormalizeAngle(y)
    end

    self.aim_pitch = math.Clamp(self.aim_pitch, self.aim_pitch_min, self.aim_pitch_max)
    self.aim_yaw = math.Clamp(self.aim_yaw, self.aim_yaw_min, self.aim_yaw_max)
    self:SetPoseParameter("aim_pitch", self.aim_pitch)
    self:SetPoseParameter("aim_yaw", self.aim_yaw)
end

local aidisabled = GetConVar "ai_disabled"
function ENT:BodyUpdate()
    local rate = self.MaxPitchRollRate * FrameTime()
    local ang = self:GetAngles()
    local dp = self.DesiredPitch - ang.pitch
    local dr = self.DesiredRoll - ang.roll
    local sp = dp == 0 and 0 or dp > 0 and 1 or -1
    local sr = dr == 0 and 0 or dr > 0 and 1 or -1
    dp = math.min(math.abs(dp), rate) * sp
    dr = math.min(math.abs(dr), rate) * sr
    ang.pitch = math.NormalizeAngle(ang.pitch + dp)
    ang.roll = math.NormalizeAngle(ang.roll + dr)
    self:SetAngles(ang)
    
    if self.PlaySequence then return end
    if self.ForceSequence then
        self:SetSequence(self:LookupSequence(self.ForceSequence))
        self:ResetSequenceInfo()
        return
    end

    local crouch = self.Crouching or bit.band(self.NavAttr, NAV_MESH_CROUCH) > 0
    local act = crouch and ACT_HL2MP_IDLE_CROUCH or ACT_HL2MP_IDLE
    local speed = nil
    if self.IsJumpingAcrossGap then
        act = ACT_HL2MP_SWIM_IDLE
    elseif self.loco:IsAttemptingToMove() then
        local hasenemy = self:HasValidEnemy() or aidisabled:GetBool()
        local run = hasenemy and ACT_HL2MP_RUN_FAST or ACT_HL2MP_WALK
        if hasenemy and not (self:GetWeaponParameters().IsMelee or
        self:HasCondition(self.Enum.Conditions.COND_WEAPON_SIGHT_OCCLUDED)) then
            run = ACT_HL2MP_RUN
        end
        
        act = crouch and ACT_HL2MP_WALK_CROUCH or run
    elseif self:HasValidEnemy() or CurTime() < self.Time.Wait then
        act = crouch and ACT_HL2MP_CROUCH or ACT_HL2MP_IDLE
    end
    
    if self.ForceActivity then act = self.ForceActivity end
    if IsValid(self:GetActiveWeapon()) then
        local translated = self:TranslateActivity(act)
        if self:SelectWeightedSequence(translated) >= 0 then
            act = translated
        end
    end

    self:SetMovementActivity(act, speed)
    self:UpdateAimParameters()
    self:BodyMoveXY()

    local dir = self.loco:GetGroundMotionVector()
    local yaw = 0
    if self.loco:IsOnGround() then
        yaw = dir:Dot(self:GetForward())
        yaw = math.deg(math.acos(math.Clamp(yaw, -1, 1)))
        if self:GetForward():Cross(dir).z < 0 then
            yaw = -yaw
        end

        yaw = math.NormalizeAngle(yaw)
    end

    local current_yaw
    local move_yaw_exists = self:LookupPoseParameter "move_yaw" >= 0
    if move_yaw_exists then
        current_yaw = self:GetPoseParameter "move_yaw"
    else
        current_yaw = self.PreviousCurrentYaw or 0
    end

    local dy = yaw - current_yaw
    local sy = dy == 0 and 0 or dy > 0 and 1 or -1
    dy = math.min(math.abs(dy), self.loco:GetMaxYawRate()) * sy
    current_yaw = math.NormalizeAngle(current_yaw + dy)

    if move_yaw_exists then
        self:SetPoseParameter("move_yaw", current_yaw)
    else
        self:SetPoseParameter("move_x", math.cos(math.rad(current_yaw)))
        self:SetPoseParameter("move_y", -math.sin(math.rad(current_yaw)))
        self.PreviousCurrentYaw = current_yaw
    end
end

function ENT:OnLandOnGround_Animation(ent)
    if self.PlayLandAnimation and self:GetVelocity().z < -500 then
        self:AddGestureSequence(self:LookupSequence "jump_land")
    end
end

local a = ENT.Enum.ACT
function ENT:OnInjured_Animation(d)
    local pos = d:GetDamagePosition()
    local att = d:GetAttacker()
    local org = IsValid(att) and att:WorldSpaceCenter() or pos
    local tr = util.QuickTrace(pos, d:GetDamageForce())
    local params = self:GetWeaponParameters()
	if tr.Entity ~= self then return end
    local flinch = ({
        [HITGROUP_HEAD] = ACT_FLINCH_HEAD,
        [HITGROUP_STOMACH] = ACT_FLINCH_STOMACH,
        [HITGROUP_LEFTARM] = ACT_FLINCH_LEFTARM,
        [HITGROUP_RIGHTARM] = ACT_FLINCH_RIGHTARM,
    })[tr.HitGroup]
    if d:GetDamage() > self:GetMaxHealth() / 4 then
        if d:GetDamageForce():Dot(self:GetForward()) > 0 then
            self:AddGesture(a.ACT_FLINCH_BACK)
        else
            self:AddGesture(ACT_FLINCH_PHYSICS)
        end
    else
        self:AddGesture(flinch or a.ACT_FLINCH)
    end
end
