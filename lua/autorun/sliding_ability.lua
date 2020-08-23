AddCSLuaFile()

local SLOPE_MAX = math.cos(math.rad(45))
local SLIDE_ACCEL = 400
local SLIDE_ANIM_TRANSITION_TIME = 0.2
local SLIDE_TILT_DEG = 42
local IN_MOVE = bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)
local ACT_HL2MP_SIT_CAMERA = "sit_camera"
local ACT_HL2MP_SIT_DUEL = "sit_duel"
local ACT_HL2MP_SIT_PASSIVE = "sit_passive"
local acts = {
    revolver = ACT_HL2MP_SIT_PISTOL,
    pistol = ACT_HL2MP_SIT_PISTOL,
    shotgun = ACT_HL2MP_SIT_SHOTGUN,
    smg = ACT_HL2MP_SIT_SMG1,
    ar2 = ACT_HL2MP_SIT_AR2,
    physgun = ACT_HL2MP_SIT_PHYSGUN,
    grenade = ACT_HL2MP_SIT_GRENADE,
    rpg = ACT_HL2MP_SIT_RPG,
    crossbow = ACT_HL2MP_SIT_CROSSBOW,
    melee = ACT_HL2MP_SIT_MELEE,
    melee2 = ACT_HL2MP_SIT_MELEE2,
    slam = ACT_HL2MP_SIT_SLAM,
    fist = ACT_HL2MP_SIT_FIST,
    normal = ACT_HL2MP_SIT_DUEL,
    camera = ACT_HL2MP_SIT_CAMERA,
    duel = ACT_HL2MP_SIT_DUEL,
    passive = ACT_HL2MP_SIT_PASSIVE,
    magic = ACT_HL2MP_SIT_DUEL,
    knife = ACT_HL2MP_SIT_KNIFE,
}
local function GetSlidingActivity(ply)
    local w, a = ply:GetActiveWeapon(), ACT_HL2MP_SIT_DUEL
    if IsValid(w) then a = acts[w:GetHoldType()] or acts[w.HoldType] or ACT_HL2MP_SIT_DUEL end
    if isstring(a) then return ply:GetSequenceActivity(ply:LookupSequence(a)) end
    return a
end

local function ManipulateBones(ply, ent, base, thigh, calf)
    local t0 = ply:GetNWFloat "SlidingStartTime"
    local timefrac = math.TimeFraction(t0, t0 + SLIDE_ANIM_TRANSITION_TIME, CurTime())
    timefrac = math.Clamp(timefrac, 0, 1)
    ent:ManipulateBoneAngles(0, base * timefrac)
    ent:ManipulateBoneAngles(ent:LookupBone "ValveBiped.Bip01_R_Thigh", thigh * timefrac)
    ent:ManipulateBoneAngles(ent:LookupBone "ValveBiped.Bip01_R_Calf", calf * timefrac)
end

local function EndSliding(ply)
    ManipulateBones(ply, ply, Angle(), Angle(), Angle())
    ply:SetNWBool("IsSliding", false)
    ply:SetNWFloat("SlidingStartTime", CurTime())
    ply:StopSound "Flesh.ScrapeRough"
end

hook.Add("SetupMove", "Check sliding", function(ply, mv, cmd)
    if ply:GetNWFloat "SlidingPreserveWalkSpeed" > 0 then
        local v = Vector(ply:GetNWVector "SlidingCurrentVelocity")
        v.z = mv:GetVelocity().z
        ply:SetWalkSpeed(ply:GetNWFloat "SlidingPreserveWalkSpeed")
        mv:SetVelocity(v)
    end

    ply:SetNWFloat("SlidingPreserveWalkSpeed", -1)
    if CLIENT and not IsFirstTimePredicted() then return end
    if not ply:Crouching() and ply:GetNWBool "IsSliding" then EndSliding(ply) end
    if ply:Crouching() and ply:GetNWBool "IsSliding" then
        local v = ply:GetNWVector "SlidingCurrentVelocity"
        local vdir = v:GetNormalized()
        local forward = mv:GetMoveAngles():Forward()
        local speed = v:Length()
        local speedref_slide = ply:GetNWFloat "SlidingMaxSpeed"
        local speedref_crouch = ply:GetWalkSpeed() * ply:GetCrouchedWalkSpeed()
        local speedref_min = math.min(speedref_crouch, speedref_slide)
        local speedref_max = math.max(speedref_crouch, speedref_slide)
        local dp = mv:GetOrigin() - ply:GetNWVector "SlidingPreviousPosition"
        local dp2d = Vector(dp.x, dp.y)
        dp:Normalize()
        dp2d:Normalize()
        local dot = forward:Dot(dp2d)
        local speedref = Lerp(math.max(-dp.z, 0), speedref_min, speedref_max)
        local accel = SLIDE_ACCEL * FrameTime()
        if speed > speedref then accel = -accel end
        v = LerpVector(0.01, vdir, forward) * (speed + accel)

        ManipulateBones(ply, ply, -Angle(0, 0, math.deg(math.asin(dp.z)) * dot + SLIDE_TILT_DEG), Angle(0, 32, 0), Angle(0, -60, 0))
        ply:SetNWVector("SlidingCurrentVelocity", v)
        ply:SetNWVector("SlidingPreviousPosition", mv:GetOrigin())
        mv:SetVelocity(v)
        if not ply:OnGround() or mv:KeyPressed(IN_JUMP)
        or mv:KeyReleased(IN_DUCK) or math.abs(speed - speedref_min) < 100 then
            EndSliding(ply)
            if mv:KeyPressed(IN_JUMP) then
                ply:SetNWFloat("SlidingPreserveWalkSpeed", ply:GetWalkSpeed())
                ply:SetWalkSpeed(speed)
                ply:SetMaxSpeed(speed)
            end
        end

        local e = EffectData()
        e:SetOrigin(mv:GetOrigin())
        e:SetScale(1.6)
        util.Effect("WheelDust", e)
        
        return
    end

    if not ply:OnGround() then return end
    if not ply:Crouching() then return end
    if not mv:KeyDown(IN_DUCK) then return end
    if ply:GetNWBool "IsSliding" then return end
    if CurTime() < ply:GetNWFloat "SlidingStartTime" + SLIDE_ANIM_TRANSITION_TIME then return end
    if math.abs(ply:GetWalkSpeed() - ply:GetRunSpeed()) < 100 then return end
    if math.abs(mv:GetVelocity():Length() - ply:GetRunSpeed()) > 100 then return end
    local runspeed = math.max(ply:GetVelocity():Length(), mv:GetVelocity():Length(), ply:GetRunSpeed()) * 1.2
    local dir = mv:GetVelocity():GetNormalized()
    ply:SetNWBool("IsSliding", true)
    ply:SetNWFloat("SlidingStartTime", CurTime())
    ply:SetNWVector("SlidingCurrentVelocity", dir * runspeed)
    ply:SetNWVector("SlidingMaxSpeed", runspeed * 5)
    ply:EmitSound "Flesh.ImpactSoft"
    ply:EmitSound "Flesh.ScrapeRough"
end)

hook.Add("PlayerFootstep", "Sliding sound", function(ply, pos, foot, sound, volume, filter)
    return ply:GetNWBool "IsSliding" or nil
end)

hook.Add("CalcMainActivity", "Sliding animation", function(ply, velocity)
    if not ply:GetNWBool "IsSliding" then return end
    return GetSlidingActivity(ply), -1
end)

hook.Add("UpdateAnimation", "Sliding aim pose parameters", function(ply, velocity, maxSeqGroundSpeed)
    if not ply:GetNWBool "IsSliding" then
        if CLIENT and g_LegsVer then
            ManipulateBones(ply, GetPlayerLegs(), Angle(), Angle(), Angle())
        end

        return
    end

    local b = ply:GetManipulateBoneAngles(0).roll
    local p = ply:GetPoseParameter "aim_pitch" -- degrees in server, 0-1 in client
    local y = ply:GetPoseParameter "aim_yaw"
    if CLIENT then
        p = Lerp(p, ply:GetPoseParameterRange(ply:LookupPoseParameter "aim_pitch"))
        y = Lerp(y, ply:GetPoseParameterRange(ply:LookupPoseParameter "aim_yaw"))
    end

    p = p - b

    local a = ply:GetSequenceActivity(ply:GetSequence())
    local la = ply:GetSequenceActivity(ply:GetLayerSequence(0))
    if a == ply:GetSequenceActivity(ply:LookupSequence(ACT_HL2MP_SIT_DUEL)) and la ~= ACT_HL2MP_GESTURE_RELOAD_DUEL then
        p = p - 45
        ply:SetPoseParameter("aim_yaw", ply:GetPoseParameterRange(ply:LookupPoseParameter "aim_yaw"))
    elseif a == ply:GetSequenceActivity(ply:LookupSequence(ACT_HL2MP_SIT_CAMERA)) then
        y = y + 20
        ply:SetPoseParameter("aim_yaw", y)
    end

    ply:SetPoseParameter("aim_pitch", p)

    if SERVER or not g_LegsVer then return end
    local l = GetPlayerLegs()
    local dp = ply:GetPos() - (l.SlidingPreviousPosition or ply:GetPos())
    local dp2d = Vector(dp.x, dp.y)
    dp:Normalize()
    dp2d:Normalize()
    local dot = ply:GetForward():Dot(dp2d)
    ManipulateBones(ply, l, -Angle(0, 0, math.deg(math.asin(dp.z)) * dot + SLIDE_TILT_DEG), Angle(0, 32, 0), Angle(0, -60, 0))
    l.SlidingPreviousPosition = ply:GetPos()
end)

if SERVER then return end
hook.Add("CalcViewModelView", "Sliding view model tilt", function(w, vm, op, oa, p, a)
    if not (IsValid(w.Owner) and w.Owner:IsPlayer()) then return end
    local wp, wa = p, a
    if isfunction(w.CalcViewModelView) then wp, wa = w:CalcViewModelView(vm, op, oa, p, a) end
    if not (wp and wa) then wp, wa = p, a end
    if w.IsTFAWeapon and w:GetIronSights() then return end

    local ply = w.Owner
    local t0 = ply:GetNWFloat "SlidingStartTime"
    local timefrac = math.TimeFraction(t0, t0 + SLIDE_ANIM_TRANSITION_TIME, CurTime())
    timefrac = math.Clamp(timefrac, 0, 1)
    if not ply:GetNWBool "IsSliding" then timefrac = 1 - timefrac end
    if timefrac == 0 then return end
    wp:Add(LerpVector(timefrac, Vector(), LocalToWorld(Vector(0, 2, -6), Angle(), Vector(), wa)))
    wa:RotateAroundAxis(wa:Forward(), Lerp(timefrac, 0, -45))
end)