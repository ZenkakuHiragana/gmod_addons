AddCSLuaFile()

local cf = {FCVAR_REPLICATED, FCVAR_ARCHIVE}
local CVarAccel = CreateConVar("sliding_ability_acceleration", 250, cf,
"The acceleration/deceleration of the sliding.  Larger value makes shorter sliding.")
local CVarCooldown = CreateConVar("sliding_ability_cooldown", 0.3, cf,
"Cooldown time to be able to slide again in seconds.")
local CVarCooldownJump = CreateConVar("sliding_ability_cooldown_jump", 0.6, cf,
"Cooldown time to be able to slide again when you jump while sliding, in seconds.")
local SLIDING_ABILITY_BLACKLIST = {
    climb_swep2 = true,
    parkourmod = true,
}
local SLOPE_MAX = math.cos(math.rad(45))
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

local BoneAngleCache = SERVER and {} or nil
local function ManipulateBoneAnglesLessTraffic(ent, bone, ang, frac)
    local a = SERVER and ang or ang * frac
    if CLIENT or not BoneAngleCache[ent] or BoneAngleCache[ent][bone] ~= a then
        ent:ManipulateBoneAngles(bone, a)
        if CLIENT then return end
        if not BoneAngleCache[ent] then BoneAngleCache[ent] = {} end
        BoneAngleCache[ent][bone] = a
    end
end

local function ManipulateBones(ply, ent, base, thigh, calf)
    if not IsValid(ent) then return end
    local t0 = ply:GetNWFloat "SlidingStartTime"
    local timefrac = math.TimeFraction(t0, t0 + SLIDE_ANIM_TRANSITION_TIME, CurTime())
    timefrac = SERVER and 1 or math.Clamp(timefrac, 0, 1)
    ManipulateBoneAnglesLessTraffic(ent, 0, base, timefrac)
    ManipulateBoneAnglesLessTraffic(ent, ent:LookupBone "ValveBiped.Bip01_R_Thigh", thigh, timefrac)
    ManipulateBoneAnglesLessTraffic(ent, ent:LookupBone "ValveBiped.Bip01_R_Calf", calf, timefrac)
    local dp = thigh:IsZero() and Vector() or Vector(10, 0, -10)
    local w, pose = ply:GetActiveWeapon(), ""
    if IsValid(w) then pose = w:GetHoldType() or w.HoldType end
    if pose:find "all" then pose = "normal" end
    if pose == "smg1" then pose = "smg" end
    if EnhancedCamera and ent == EnhancedCamera.entity then
        if pose then
            EnhancedCamera.pose = pose
            EnhancedCamera:OnPoseChange()
        end
        ent:ManipulateBonePosition(0, dp * timefrac)
    end
    if EnhancedCameraTwo and ent == EnhancedCameraTwo.entity then
        if pose then
            EnhancedCameraTwo.pose = pose
            EnhancedCameraTwo:OnPoseChange()
        end
        ent:ManipulateBonePosition(0, dp * timefrac)
    end
end

local function EndSliding(ply)
    ManipulateBones(ply, ply, Angle(), Angle(), Angle())
    ply:SetNWBool("IsSliding", false)
    ply:SetNWFloat("SlidingStartTime", CurTime())
    if SERVER then ply:StopSound "Flesh.ScrapeRough" end
    if CLIENT then ply.IsSliding = nil end
end

local function SetSlidingPose(ply, ent, body_tilt)
    ManipulateBones(ply, ent, -Angle(0, 0, body_tilt), Angle(20, 35, 85), Angle(0, 45, 0))
    if CLIENT then ply.IsSliding = true end
end

hook.Add("SetupMove", "Check sliding", function(ply, mv, cmd)
    local w = ply:GetActiveWeapon()
    if IsValid(w) and SLIDING_ABILITY_BLACKLIST[w:GetClass()] then return end
    if ConVarExists "savav_parkour_Enable" and GetConVar "savav_parkour_Enable":GetBool() then return end
    if ply:GetNWFloat "SlidingPreserveWalkSpeed" > 0 then
        local v = ply.SlidingCurrentVelocity or Vector()
        v.z = mv:GetVelocity().z
        mv:SetVelocity(v)
    end
    
    ply:SetNWFloat("SlidingPreserveWalkSpeed", -1)
    if CLIENT and not IsFirstTimePredicted() then return end
    if not ply:Crouching() and ply:GetNWBool "IsSliding" then EndSliding(ply) end
    if ply:Crouching() and ply:GetNWBool "IsSliding" then
        local v = ply.SlidingCurrentVelocity or Vector()
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
        local accel_cvar = CVarAccel:GetFloat()
        local accel = accel_cvar * FrameTime()
        if speed > speedref then accel = -accel end
        v = LerpVector(0.005, vdir, forward) * (speed + accel)

        SetSlidingPose(ply, ply, math.deg(math.asin(dp.z)) * dot + SLIDE_TILT_DEG)
        ply.SlidingCurrentVelocity = v
        ply:SetNWVector("SlidingPreviousPosition", mv:GetOrigin())
        mv:SetVelocity(v)
        if not ply:OnGround() or mv:KeyPressed(IN_JUMP) or mv:KeyReleased(IN_DUCK) or math.abs(speed - speedref_crouch) < 10 then
            EndSliding(ply)
            if mv:KeyPressed(IN_JUMP) then
                ply:SetNWFloat("SlidingStartTime", CurTime() + CVarCooldownJump:GetFloat())
                ply:SetNWFloat("SlidingPreserveWalkSpeed", ply:GetWalkSpeed())
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
    if not mv:KeyDown(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)) then return end
    if ply:GetNWBool "IsSliding" then return end
    if CurTime() < ply:GetNWFloat "SlidingStartTime" + CVarCooldown:GetFloat() then return end
    if math.abs(ply:GetWalkSpeed() - ply:GetRunSpeed()) < 100 then return end
    local v = mv:GetVelocity()
    local speed = v:Length()
    local run = ply:GetRunSpeed()
    local crouched = ply:GetWalkSpeed() * ply:GetCrouchedWalkSpeed()
    local threshold = (run + crouched) / 2
    if run > crouched and speed < threshold then return end
    if run < crouched and (not mv:KeyDown(IN_SPEED) or speed < run - 1 or speed > threshold) then return end
    local runspeed = math.max(ply:GetVelocity():Length(), speed, run) * 1.5
    local dir = v:GetNormalized()
    ply:SetNWBool("IsSliding", true)
    ply:SetNWFloat("SlidingStartTime", CurTime())
    ply.SlidingCurrentVelocity = dir * runspeed
    ply:SetNWVector("SlidingMaxSpeed", runspeed * 5)
    ply:EmitSound "Flesh.ImpactSoft"
    if SERVER then ply:EmitSound "Flesh.ScrapeRough" end
end)

hook.Add("PlayerFootstep", "Sliding sound", function(ply, pos, foot, sound, volume, filter)
    return ply:GetNWBool "IsSliding" or nil
end)

hook.Add("CalcMainActivity", "Sliding animation", function(ply, velocity)
    if not ply:GetNWBool "IsSliding" then return end
    return GetSlidingActivity(ply), -1
end)

hook.Add("UpdateAnimation", "Sliding aim pose parameters", function(ply, velocity, maxSeqGroundSpeed)
    -- Workaround!!!  Revive Mod disables the sliding animation so we disable it
    local ReviveModUpdateAnimation = hook.GetTable().UpdateAnimation.BleedOutAnims
    if ReviveModUpdateAnimation then hook.Remove("UpdateAnimation", "BleedOutAnims") end
    if ReviveModUpdateAnimation and ply:IsBleedOut() then
        ReviveModUpdateAnimation(ply, velocity, maxSeqGroundSpeed)
        return
    end

    if not ply:GetNWBool "IsSliding" then
        if CLIENT then
            if g_LegsVer then ManipulateBones(ply, GetPlayerLegs(), Angle(), Angle(), Angle()) end
            if EnhancedCamera then ManipulateBones(ply, EnhancedCamera.entity, Angle(), Angle(), Angle()) end
            if EnhancedCameraTwo then ManipulateBones(ply, EnhancedCameraTwo.entity, Angle(), Angle(), Angle()) end
            if ply.IsSliding then EndSliding(ply) end
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

    if SERVER then return end

    local l = ply
    if ply == LocalPlayer() then
        if g_LegsVer then l = GetPlayerLegs() end
        if EnhancedCamera then l = EnhancedCamera.entity end
        if EnhancedCameraTwo then l = EnhancedCameraTwo.entity end
        if not IsValid(l) then return end
    end
    
    local dp = ply:GetPos() - (l.SlidingPreviousPosition or ply:GetPos())
    local dp2d = Vector(dp.x, dp.y)
    dp:Normalize()
    dp2d:Normalize()
    local dot = ply:GetForward():Dot(dp2d)
    SetSlidingPose(ply, l, math.deg(math.asin(dp.z)) * dot + SLIDE_TILT_DEG)
    l.SlidingPreviousPosition = ply:GetPos()
end)

if SERVER then
    hook.Add("PlayerInitialSpawn", "Prevent breaking TPS model on changelevel", function(ply, transition)
        if not transition then return end
        timer.Simple(1, function()
            for i = 0, ply:GetBoneCount() - 1 do
                ply:ManipulateBoneScale(i, Vector(1, 1, 1))
                ply:ManipulateBoneAngles(i, Angle())
                ply:ManipulateBonePosition(i, Vector())
            end
        end)
    end)

    return
end

CreateClientConVar("sliding_ability_tilt_viewmodel", 1, true, true, "Enable viewmodel tilt like Apex Legends when sliding.")
hook.Add("CalcViewModelView", "Sliding view model tilt", function(w, vm, op, oa, p, a)
    if w.SuppressSlidingViewModelTilt then return end -- For the future addons which are compatible with this addon
    if w.ArcCW and w:GetState() == ArcCW.STATE_SIGHTS then return end
    if not (IsValid(w.Owner) and w.Owner:IsPlayer()) then return end
    if not GetConVar "sliding_ability_tilt_viewmodel":GetBool() then return end
    if w.IsTFAWeapon and w:GetIronSights() then return end
    local wp, wa = p, a
    if isfunction(w.CalcViewModelView) then wp, wa = w:CalcViewModelView(vm, op, oa, p, a) end
    if not (wp and wa) then wp, wa = p, a end

    local ply = w.Owner
    local t0 = ply:GetNWFloat "SlidingStartTime"
    local timefrac = math.TimeFraction(t0, t0 + SLIDE_ANIM_TRANSITION_TIME, CurTime())
    timefrac = math.Clamp(timefrac, 0, 1)
    if not ply:GetNWBool "IsSliding" then timefrac = 1 - timefrac end
    if timefrac == 0 then return end
    wp:Add(LerpVector(timefrac, Vector(), LocalToWorld(Vector(0, 2, -6), Angle(), Vector(), wa)))
    wa:RotateAroundAxis(wa:Forward(), Lerp(timefrac, 0, -45))
end)
