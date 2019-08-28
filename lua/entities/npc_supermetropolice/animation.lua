
include "ai_translations.lua"

function ENT:Initialize_Animation()
	local translate = {}
	for _, t in ipairs {
		"ar2",
		"crossbow",
		"grenade",
		"melee",
		"melee2",
        "passive",
        "pistol",
		"revolver",
		"rpg",
		"shotgun",
		"smg",
	} do
		self:SetupWeaponHoldTypeForAI(t)
    end

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

function ENT:ActivityTranslate(act)
    local h = self.WeaponParameters.HoldType
    local t = self.ActivityTranslateAI
    if not t[h] then return act end
    local a = t[h][act]
    while not a or self:SelectWeightedSequence(a) < 0 do
        h = t[h].Fallback
        if not (h and t[h]) then break end
        a = t[h][act]
        if not t[h].Fallback then break end
    end

    return a or act
end

function ENT:SetActivity(act)
    if self:GetActivity() ~= act then
        self:StartActivity(act)
    end
end

function ENT:SetMovementActivity(act)
    self:SetActivity(act)
    local seq = self:SelectWeightedSequence(act)
    self.CurrentDesiredSpeed = self.DesiredSpeed or self:GetSequenceGroundSpeed(seq)
    self.loco:SetDesiredSpeed(self.CurrentDesiredSpeed)
end

function ENT:CheckCrouching()
    if self.ForceCrouch then
        self.Crouching = true
        return
    end
    
    local org = self:GetPos()
    local t = self:TraceHullStand(org)
    local mins, maxs = self:GetCollisionBounds()
    self:box("CheckCrouching", org + vector_up * 7, mins, maxs, true)
    self.Crouching = t.Hit
end

function ENT:UpdateAimParameters()
    local p, y = 0, 0
    if self:HasValidEnemy() and self:HasCondition(self.Enum.Conditions.COND_SEE_ENEMY) then
        local from = self:GetShootPos()
        local to = self:GetShootTo()
        local dz = from.z - self:GetPos().z
        local dir = self:WorldToLocal(to - vector_up * dz)
        local ang = dir:Angle()
        ang:Normalize()
        p, y = ang.pitch, ang.yaw
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
    self:BodyMoveXY()
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
    
    if self.ForceSequence then self:SetSequence(self:LookupSequence(self.ForceSequence)) self:ResetSequenceInfo() return end
    if self.PlaySequence then return end

    local crouch = self.Crouching or bit.band(self.NavAttr, NAV_MESH_CROUCH) > 0
    local act = crouch and ACT_CROUCH or ACT_IDLE
    if self.IsJumpingAcrossGap then
        act = ACT_JUMP
    elseif self.loco:IsAttemptingToMove() then
        local hasenemy = self:HasValidEnemy() or aidisabled:GetBool()
        local run = hasenemy and ACT_RUN or ACT_WALK
        if hasenemy and self:HasCondition(self.Enum.Conditions.COND_SEE_ENEMY) then
            run = ACT_RUN_AIM
        end
        
        act = crouch and ACT_WALK_CROUCH or run
    elseif self:HasValidEnemy() or CurTime() < self.Time.Wait then
        act = crouch and ACT_CROUCH or ACT_IDLE_ANGRY
    end
    
    if self.ForceActivity then act = self.ForceActivity end
    if IsValid(self:GetActiveWeapon()) then
        local transact = self:ActivityTranslate(act)
        if self:SelectWeightedSequence(transact) >= 0 then
            act = transact
        end
    end

    self:SetMovementActivity(act)
    self:UpdateAimParameters()

    if not self:LookupPoseParameter "move_yaw" then return end
    local yaw = 0
    if self.loco:IsOnGround() then
        local dir = self.loco:GetGroundMotionVector()
        yaw = dir:Dot(self:GetForward())
        yaw = math.deg(math.acos(math.Clamp(yaw, -1, 1)))
        if self:GetForward():Cross(dir).z < 0 then
            yaw = -yaw
        end

        yaw = math.NormalizeAngle(yaw)
    end

    local current_yaw = self:GetPoseParameter "move_yaw"
    local dy = yaw - current_yaw
    local sy = dy == 0 and 0 or dy > 0 and 1 or -1
    dy = math.min(math.abs(dy), self.loco:GetMaxYawRate()) * sy
    current_yaw = math.NormalizeAngle(current_yaw + dy)
    self:SetPoseParameter("move_yaw", current_yaw)
end

function ENT:OnLandOnGround_Animation(ent)
    if self.PlayLandAnimation and self:GetVelocity().z < -500 then
        self.PlaySequence = "jump_holding_land"
    end
end

function ENT:OnInjured_Animation(d)
    local pos = d:GetDamagePosition()
    local att = d:GetAttacker()
    local org = IsValid(att) and att:WorldSpaceCenter() or pos
    local tr = util.QuickTrace(pos, d:GetDamageForce())
    local params = self.WeaponParameters
	if tr.Entity ~= self then return end
	if tr.HitGroup == HITGROUP_HEAD then d:ScaleDamage(2) end
    local flinch = ({
        [HITGROUP_HEAD] = ACT_GESTURE_FLINCH_HEAD,
        [HITGROUP_STOMACH] = ACT_GESTURE_FLINCH_STOMACH,
        [HITGROUP_LEFTARM] = ACT_GESTURE_FLINCH_LEFTARM,
        [HITGROUP_RIGHTARM] = ACT_GESTURE_FLINCH_RIGHTARM,
    })[tr.HitGroup]
    if d:GetDamage() > self:GetMaxHealth() / 4 and params and params.HoldType == "pistol" then
        self:AddGesture(ACT_BIG_FLINCH)
    else
        self:AddGesture(flinch or ACT_GESTURE_SMALL_FLINCH)
    end
end
