
local function CheckHitFriendly(self)
    local tr = util.TraceLine {
        start = start or self:GetShootPos(),
        endpos = endpos or self:GetShootTo(),
        mask = MASK_SHOT,
        collisiongroup = COLLISION_GROUP_BREAKABLE_GLASS,
        filter = {self, self:GetEnemy()},
    }

    local e = tr.Entity
    local hit = self:Disposition(e) ~= D_HT and (IsValid(e) and self:Disposition(e:GetParent()) ~= D_HT)
    self:ManipulateCondition(hit, "COND_WEAPON_BLOCKED_BY_FRIEND")
end

local function DefaultCheckLOS(self, start, endpos)
    if util.TraceLine {
        start = self:WorldSpaceCenter(),
        endpos = self:GetShootPos(),
        filter = self,
        mask = MASK_SHOT,
    }.Hit then return end
    local tr = util.TraceLine {
        start = start or self:GetShootPos(),
        endpos = endpos or self:GetShootTo(),
        mask = MASK_SHOT,
        collisiongroup = COLLISION_GROUP_BREAKABLE_GLASS,
        filter = {self, self:GetEnemy()},
    }
    
    CheckHitFriendly(self)
    return not tr.Hit or self:Disposition(tr.Entity) == D_HT
    or (IsValid(tr.Entity) and self:Disposition(tr.Entity:GetParent()) == D_HT)
end

local function DefaultCheckLOSOnGround(self, start, endpos)
    if not self:OnGround() then return end
    return DefaultCheckLOS(self, start, endpos)
end

local function CheckLOSMelee(self, start, endpos)
    return self:VisibleVec(endpos or self:GetShootTo())
    or DefaultCheckLOSOnGround(self, start, endpos)
end

local function DefaultFireCallback(attacker, tr, dmginfo)
    if not IsValid(attacker) then return end
    local w = attacker:GetActiveWeapon()
    if not IsValid(w) then return end
    local params = attacker.WeaponParameters
    if not tr.HitSky and params.ImpactEffectName then
        local e = EffectData()
        e:SetOrigin(tr.HitPos + tr.HitNormal)
        e:SetNormal(tr.HitNormal)
        util.Effect(params.ImpactEffectName, e)
    end

	if not IsValid(tr.Entity) then return end
	local c = tr.Entity:GetClass()
    if c == "npc_turret_floor" and not tr.Entity:GetInternalVariable "m_bSelfDestructing" then
		tr.Entity:Fire "SelfDestruct"
	elseif c == "npc_rollermine" then
		util.BlastDamage(game.GetWorld(), game.GetWorld(), tr.Entity:GetPos(), 1, 1)
    end
    
	dmginfo:SetInflictor(w)
end

local function DefaultFireFunction(self, w, pos, dir)
    local e = self:GetEnemy()
    if not IsValid(e) then return end
    local params = self.WeaponParameters
    local tan = math.tan(math.rad(params.Spread))
    local dmg = params.Damage
    if isstring(dmg) then
        dmg = GetConVar(dmg)
        dmg = dmg and dmg:GetInt() or 0
    end

    local bullet = {
        AmmoType = params.AmmoType,
        Attacker = self,
        Callback = params.Callback,
        Damage = dmg,
        Dir = dir * params.MaxRange,
        Force = params.Force,
        Num = params.BulletPerShot,
        Spread = Vector(tan, tan) * params.MaxRange * self.WeaponSpreadMul,
        Src = pos,
        Tracer = params.Tracer,
        TracerName = params.TracerName,
    }

    if params.IsMelee then
        local d = e:WorldSpaceCenter() - self:WorldSpaceCenter()
        d:Normalize()
        local tr = util.TraceLine {
            start = self:WorldSpaceCenter(),
            endpos = self:WorldSpaceCenter() + d * params.MaxRange * 1.2,
            filter = self,
            mask = MASK_SHOT,
        }
        -- debugoverlay.Line(tr.StartPos, tr.HitPos, 5, Color(0, 255, 0))
        if tr.Hit then
            local d = DamageInfo()
            d:SetAttacker(bullet.Attacker)
            d:SetDamage(bullet.Damage)
            d:SetDamageForce(dir)
            d:SetDamagePosition(tr.HitPos)
            d:SetDamageType(DMG_DISSOLVE)
            d:SetInflictor(w)
            d:SetMaxDamage(d:GetDamage())
            local ent = IsValid(tr.Entity) and tr.Entity or e
            ent:DispatchTraceAttack(d, tr)
        end
        
        if params.HitSound and params.MissSound then
            w:EmitSound(tr.Hit and params.HitSound or params.MissSound)
        end
    else
        self:FireBullets(bullet)
        self.Clip = self.Clip - 1
    end

    if params.ShootSound then
       w:EmitSound(params.ShootSound)
    end

    if params.MuzzleEffectName then
        w:ResetSequence(params.MuzzleEffectName)
        return
    end

    w:MuzzleFlash()
    self:MuzzleFlash()
    if math.random() > 0.5 then return end
    local e = EffectData()
    e:SetEntity(w)
    e:SetEntIndex(w:EntIndex())
    e:SetOrigin(pos)
    e:SetAngles(dir:Angle())
    e:SetScale(1)
    util.Effect("MuzzleEffect", e)
end

local function CalcThrowVec(self, v1, v2, toss, velocity)
    local g = physenv.GetGravity():Length()
    local v = velocity or self.WeaponParameters.MaxRange * 0.8
    local to = v2 - v1
    local dir2D = Vector(to.x, to.y)
    local x = dir2D:Length()
    local y = to.z
    local vsqr = 2 * v * v
    local gx = g * x
    local b = -vsqr / gx
    local c = 1 + vsqr * y / (gx * x)
    local D = b * b - 4 * c
    if D < 0 then return end
    -- 4 * v^4 - 8 * y * v^2 = 4 * gx^2

    local Dsqrt = math.sqrt(D)
    local tan1 = -(b + Dsqrt) / 2
    local tan2 = -(b - Dsqrt) / 2
    local ang1 = math.atan(tan1)
    local ang2 = math.atan(tan2)
    local ang = toss and math.max(ang1, ang2) or math.min(ang1, ang2)
    local cos = math.cos(ang)
    local sin = math.sin(ang)
    dir2D:Normalize()
    local velocity = dir2D * v * cos
    velocity.z = v * sin
    return velocity, dir2D, v * cos
end

local function TestThrowVec(self, from, to, draw)
    local halfg = physenv.GetGravity():Length() / 2
    local filter = {self, self:GetEnemy()}
    local att = self:LookupAttachment "anim_attachment_LH"
    local from = from or self:GetAttachment(att).Pos
    local to = to or self:GetShootTo()
    local dir = to - from
    local dist2D = dir:Length2D()
    local occluded = self:HasCondition(self.Enum.Conditions.COND_ENEMY_OCCLUDED)
    for i = 3, 14 do
        local v0 = 100 * i
        local velocity, ndir2D, v2D = CalcThrowVec(self, from, to, occluded, v0)
        if velocity then
            local pass = true
            local vz = velocity.z
            local T = dist2D / v2D
            local steps = 6 + math.floor(T * 3)
            local dt = T / steps
            local tr = {}
            for i = 1, steps do
                local t0 = dt * (i - 1)
                local t = t0 + dt
                tr = util.TraceLine {
                    start = from + ndir2D * v2D * t0 + vector_up * (vz - halfg * t0) * t0,
                    endpos = from + ndir2D * v2D * t + vector_up * (vz - halfg * t) * t,
                    filter = filter,
                    mins = -Vector(2, 2, 2),
                    maxs = Vector(2, 2, 2),
                }

                -- local color = Color(0, tr.Hit and 0 or 255, 0)
                -- debugoverlay.SweptBox(tr.StartPos, tr.HitPos, -Vector(2, 2, 2), Vector(2, 2, 2), Angle(), 3, color)
                if tr.Hit and self:Disposition(tr.Entity) ~= D_HT then
                    pass = false
                    break
                end
            end

            if pass then
                return velocity, dir2D, v2D
            end
        end
    end
end

local function GrenadeLOS(self, start, endpos)
    if DefaultCheckLOSOnGround(self, start, endpos) then return true end
    self.GrenadeTossVelocity = nil
    self.GrenadeTossDirection2D = nil
    self.GrenadeTossVelocity2D = nil
    self:ClearCondition(self.Enum.Conditions.COND_WEAPON_BLOCKED_BY_FRIEND)
    return TestThrowVec(self, start, endpos) and true
end

local function ThrowGrenade(self, w, pos, dir)
    local att = self:LookupAttachment "anim_attachment_LH"
    local p = self:GetAttachment(att)
    local shootTo = self:GetShootTo()
    local occluded = self:HasCondition(self.Enum.Conditions.COND_ENEMY_OCCLUDED)
    if occluded then shootTo = self:GetLastPosition() + vector_up * 100 end
    local wait = occluded and 1 or 0.8
    local dist2D = (shootTo - p.Pos):Length2D()
    local throwVec, dir2D, v2D = TestThrowVec(self, p.Pos, shootTo)
    if not throwVec then return end

    self.PlaySequence = occluded and "deploy" or "grenadethrow"
	timer.Simple(wait, function()
        if not IsValid(self) then return end
        if not self:CheckAlive(self) then return end
        local ent = ents.Create "npc_grenade_frag"
        local p = self:GetAttachment(att)
		ent:Input("settimer", self, self, dist2D / v2D * (math.random() < 0.3 and 2 or 1))
		ent:SetHealth(math.huge)
		ent:SetMaxHealth(math.huge)
		ent:SetPos(p.Pos)
		ent:SetAngles(p.Ang)
		ent:SetOwner(self)
		ent:SetSaveValue("m_hThrower", self)
		ent:Spawn()
		
        local phys = ent:GetPhysicsObject()
        if not IsValid(phys) then ent:Remove() return end
        phys:EnableDrag(false)
		phys:SetVelocityInstantaneous(throwVec)
		phys:AddAngleVelocity(VectorRand() * 10)
		
        ent:AddCallback("OnAngleChange", function(ent, ang)
            phys:AddAngleVelocity(VectorRand())
            if not IsValid(ent) or ent:IsOnFire() then return end
            ent:Ignite(0.1)
        end)
    end)
end

local DefaultParameters = {
    AllowRappel = true,
    AmmoType = "Pistol",
    BulletPerShot = 1,
    Callback = DefaultFireCallback,
    CheckLOS = DefaultCheckLOS,
    ClipSize = 18,
    Damage = "sk_npc_dmg_pistol",
    FireFunction = DefaultFireFunction,
    Force = 0.5,
    HoldType = "pistol",
    ImpactEffectName = nil,
    MaxBurstDelay = 0.15,
    MaxBurstNum = 3,
    MaxBurstRestDelay = 0.8,
    MaxRange = 1500,
    MinBurstDelay = 0.1,
    MinBurstNum = 1,
    MinBurstRestDelay = 0.3,
    MinRange = 24,
    MuzzleEffectName = "attack_npc",
    PlayGesture = true,
    ReloadSound = "Weapon_Pistol.NPC_Reload",
    ShootSound = "Weapon_Pistol.NPC_Single",
    Spread = 5,
    Tracer = 1,
    TracerName = "Tracer",
}

local WeaponList = {
    "weapon_357",
    "weapon_frag",
    "weapon_ar2",
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_stunstick",
    "weapon_pistol",
}
local HL2Weapons = {
    weapon_357 = {
        AmmoType = "357",
        ClipSize = 6,
        Damage = "sk_npc_dmg_357",
        Force = 1,
        HoldType = "pistol",
        MaxBurstDelay = 1.5,
        MaxBurstNum = 2,
        MaxBurstRestDelay = 2,
        MaxRange = 4096,
        MinBurstDelay = 0.8,
        MinBurstNum = 1,
        MinBurstRestDelay = 1.5,
        MinRange = 80,
        MuzzleEffectName = "attack_npc",
        ReloadSound = "Weapon_357.Spin",
        ReloadSoundDelay = 0.5,
        ShootSound = "Weapon_357.Single",
        Spread = 1,
    },
    weapon_frag = {
        AllowRappel = false,
        FireFunction = ThrowGrenade,
        CheckLOS = GrenadeLOS,
        HoldType = "passive",
        MaxBurstDelay = 1.5,
        MaxBurstNum = 2,
        MaxBurstRestDelay = 10,
        MaxRange = 4096,
        MinBurstDelay = 0.9,
        MinBurstNum = 1,
        MinBurstRestDelay = 4,
        MinRange = 400,
        PlayGesture = false,
        Spread = 3,
    },
    weapon_ar2 = {
        AmmoType = "AR2",
        ClipSize = 30,
        Damage = "sk_npc_dmg_ar2",
        HoldType = "smg",
        ImpactEffectName = "AR2Impact",
        MaxBurstDelay = 0.1,
        MaxBurstNum = 5,
        MaxBurstRestDelay = 0.35,
        MaxRange = 2048,
        MinBurstDelay = 0.1,
        MinBurstNum = 2,
        MinBurstRestDelay = 0.2,
        MinRange = 65,
        ReloadSound = "Weapon_AR2.NPC_Reload",
        ShootSound = "Weapon_AR2.NPC_Single",
        Spread = 3,
        TracerName = "AR2Tracer",
    },
    weapon_pistol = DefaultParameters,
    weapon_shotgun = {
        AmmoType = "Buckshot",
        BulletPerShot = 8,
        ClipSize = 6,
        Damage = "sk_npc_dmg_buckshot",
        Force = 1,
        HoldType = "smg",
        MaxBurstDelay = 0.8,
        MaxBurstNum = 3,
        MaxBurstRestDelay = 1.5,
        MaxRange = 500,
        MinBurstDelay = 0.7,
        MinBurstNum = 1,
        MinBurstRestDelay = 1.2,
        MinRange = 0,
        MuzzleEffectName = "fire",
        ReloadSound = "Weapon_Shotgun.NPC_Reload",
        ShootSound = "Weapon_Shotgun.NPC_Single",
    },
    weapon_smg1 = {
        AmmoType = "SMG",
        ClipSize = 45,
        Damage = "sk_npc_dmg_smg1",
        Force = 0.6,
        HoldType = "smg",
        MaxBurstDelay = 0.075,
        MaxBurstNum = 5,
        MaxBurstRestDelay = 0.35,
        MaxRange = 1400,
        MinBurstDelay = 0.075,
        MinBurstNum = 2,
        MinBurstRestDelay = 0.2,
        MinRange = 0,
        MuzzleEffectName = "attack1",
        ReloadSound = "Weapon_SMG1.NPC_Reload",
        ShootSound = "Weapon_SMG1.NPC_Single",
    },
    weapon_stunstick = {
        CheckLOS = CheckLOSMelee,
        Damage = 40,
        DelayedFire = 0.35,
        Force = 0.1,
        HitSound = "Weapon_StunStick.Melee_Hit",
        HoldType = "melee",
        IsMelee = true,
        MaxBurstDelay = 1.2,
        MaxBurstNum = 1,
        MaxBurstRestDelay = 1.2,
        MaxRange = 70,
        MinBurstDelay = 1,
        MinBurstNum = 1,
        MinBurstRestDelay = 1,
        MinRange = 0,
        MissSound = "Weapon_StunStick.Swing",
        MuzzleEffectName = "attack1",
        ReloadSound = "Weapon_StunStick.Activate",
        ShootSound = false,
        Spread = 0,
    },
}

local SF_WEAPON_DENY_PLAYER_PICKUP = 2
local SF_WEAPON_NOT_PUNTABLE_BY_GRAVITY_GUN = 4
function ENT:Give(classname)
    SafeRemoveEntity(self:GetActiveWeapon())
    local w = ents.Create(classname)
    if not IsValid(w) then return end
    w:SetKeyValue("spawnflags", SF_WEAPON_DENY_PLAYER_PICKUP + SF_WEAPON_NOT_PUNTABLE_BY_GRAVITY_GUN)
    w:SetParent(self)
    w:SetOwner(self)
    w:Fire("SetParentAttachmentMaintainOffset", "anim_attachment_RH")
    w:AddEffects(EF_BONEMERGE)
    w:Spawn()

    self:SetSaveValue("m_hActiveWeapon", w)
    self:SetNWEntity("ActiveWeapon", w)
    self:RegisterWeaponParameters(HL2Weapons[classname])
    self.Clip = self.WeaponParameters.ClipSize or 0
    return w
end

function ENT:OnKilled_DropWeapon(d)
    local w = self:GetActiveWeapon()
    if not IsValid(w) then return end
    local id = self:LookupAttachment "anim_attachment_RH"
    local att = self:GetAttachment(id)
    local drop = ents.Create(w:GetClass())
    att.Ang:RotateAroundAxis(att.Ang:Up(), 180)
    drop:SetPos(att.Pos)
    drop:SetAngles(att.Ang)
    drop:SetAbsVelocity(w:GetAbsVelocity())
    drop:Spawn()
    SafeRemoveEntity(w)
end

function ENT:RegisterWeaponParameters(params)
    local p = table.Copy(DefaultParameters)
    self.WeaponParameters = table.Merge(p, params or {})
end

function ENT:Initialize_Weapon()
    local skill = game.GetSkillLevel()
    local SpreadMul = {1.2, 1, 0.3}
    local BurstRestMul = {1.1, 1, 0.8}
    local WeaponRestrict = {3, 2, 1}
    self.BurstNum = 0
    self.WeaponParameters = {}
    self.WeaponShootCount = 0
    self.WeaponSpreadMul = SpreadMul[skill]
    self.WeaponBurstRestMul = BurstRestMul[skill]
    self.Clip = 0
    self.Time.WeaponBurstRest = CurTime()
    self.Time.WeaponFire = CurTime()
    self.Time.FinishReloading = CurTime()
    self:Give(WeaponList[math.random(WeaponRestrict[skill], #WeaponList)])
end

function ENT:CanPrimaryFire()
    local w = self:GetActiveWeapon()
    if not IsValid(w) then return end
    if CurTime() < self.Time.FinishReloading then return end
    return self.WeaponParameters.IsMelee or self.Clip > 0
end

function ENT:GetShootPos()
    local w = self:GetActiveWeapon()
    if not IsValid(w) then return self:WorldSpaceCenter() end
    local id = w:LookupAttachment "muzzle"
    if id == 0 then
        return self:GetAttachment(self:LookupAttachment "anim_attachment_RH").Pos
    end

    return w:GetAttachment(id).Pos
end

function ENT:GetShootTo()
    local e = self:GetEnemy()
    if not IsValid(e) then
        return self:WorldSpaceCenter() + self:GetForward() * 100
    end

    local params = self.WeaponParameters
    local pos = e:WorldSpaceCenter()
    if params and (params.IsMelee or self:GetRangeTo(pos) < (params.MinRange + params.MaxRange) / 2) then
        local id = e:LookupAttachment "head"
        if id == 0 then id = e:LookupAttachment "eyes" end
        if id > 0 then pos = e:GetAttachment(id).Pos end
    end

    return pos
end

function ENT:GetAimVector()
    local w = self:GetActiveWeapon()
    if not IsValid(w) then return self:GetForward() end
    if self:HasValidEnemy() then
        return (self:GetShootTo() - self:GetShootPos()):GetNormalized()
    else
        local id = w:LookupAttachment "muzzle"
        if id == 0 then
            return self:GetAttachment(self:LookupAttachment "eyes").Ang:Forward()
        end

        return w:GetAttachment(id).Ang:Forward()
    end
end

function ENT:PrimaryFire()
    if CurTime() < self.Time.WeaponFire then return end
    if not self:CanPrimaryFire() then return end

    local w = self:GetActiveWeapon()
    if not IsValid(w) then return end
    local params = self.WeaponParameters
    if self.WeaponShootCount == 0 then
        self.BurstNum = math.random(params.MinBurstNum, params.MaxBurstNum)
    end
    
    self.WeaponShootCount = self.WeaponShootCount + 1
    if self.WeaponShootCount < self.BurstNum then
        self.Time.WeaponFire = CurTime()
        + math.Rand(params.MinBurstDelay, params.MaxBurstDelay)
    else
        self.WeaponShootCount = 0
        self.Time.WeaponFire = CurTime()
        + math.Rand(params.MinBurstRestDelay, params.MaxBurstRestDelay)
        * self.WeaponBurstRestMul
    end

    local function fire()
        if not IsValid(self) then return end
        if not IsValid(w) then return end
        local shootPos = self:GetShootPos()
        local dir = self:GetAimVector()
        if w:IsScripted() then
            w:NPCShoot_Primary(shootPos, dir)
        elseif isfunction(params.FireFunction) then
            params.FireFunction(self, w, shootPos, dir)
        end
    end

    if params.DelayedFire then
        timer.Simple(params.DelayedFire, fire)
    else
        fire()
    end

    if params.PlayGesture then
        self:RestartGesture(self:ActivityTranslate(ACT_GESTURE_RANGE_ATTACK1))
    end

    return true
end

function ENT:Reload()
    local params = self.WeaponParameters
    if not params then return end
    local s = params.ReloadSound
    local low = self.Crouching
    local act = self:ActivityTranslate(low and ACT_RELOAD_LOW or ACT_RELOAD)
    local seq = self:SelectWeightedSequence(act)
    if seq >= 0 then
        self.PlaySequence = self:GetSequenceName(seq)
    end

    self.Clip = params.ClipSize
    if params.ReloadSoundDelay then
        timer.Simple(params.ReloadSoundDelay, function()
            if not IsValid(self) then return end
            self:EmitSound(s)
        end)
    else
        self:EmitSound(s)
    end
end
