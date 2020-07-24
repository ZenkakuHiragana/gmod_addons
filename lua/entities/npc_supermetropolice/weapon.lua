
local c = ENT.Enum.Conditions
local function CheckHitFriendly(self)
    local tr = util.TraceLine {
        start = start or self:GetShootPos(),
        endpos = endpos or self:GetShootTo(),
        mask = MASK_SHOT,
        collisiongroup = COLLISION_GROUP_BREAKABLE_GLASS,
        filter = {self, self:GetEnemy()},
    }

    local e = tr.Entity
    local hit = self:Disposition(e) == D_LI and (IsValid(e) and self:Disposition(e:GetParent()) == D_LI)
    self:RegisterCondition(hit, "COND_WEAPON_BLOCKED_BY_FRIEND")
end

local function DefaultCheckLOS(self)
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

local function DefaultCheckLOSOnGround(self)
    if not self:OnGround() then return end
    return DefaultCheckLOS(self)
end

local function CheckLOSMelee(self)
    return self:VisibleVec(self:GetShootTo())
    or DefaultCheckLOSOnGround(self)
end

local function DefaultFireCallback(attacker, tr, dmginfo)
    if not IsValid(attacker) then return end
    local w = attacker:GetActiveWeapon()
    if not IsValid(w) then return end
    local params = attacker:GetWeaponTable()
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
    local params = self:GetWeaponParameters()
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
            endpos = self:WorldSpaceCenter() + d * params.MaxRange,
            filter = self,
            mask = MASK_SHOT,
        }
        self:line("MeleeTrace", tr.StartPos, tr.HitPos, 3)
        if tr.Hit then
            local d = DamageInfo()
            d:SetAttacker(bullet.Attacker)
            d:SetDamage(bullet.Damage)
            d:SetDamageForce(dir)
            d:SetDamagePosition(tr.HitPos)
            d:SetDamageType(params.DamageType or DMG_CLUB)
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
        self:GetWeaponTable().Clip = self:GetClip() - 1
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

local function ActivateStunStick(self, weapon, weaponTable)
end

local function CalcThrowVec(self, v1, v2, toss, velocity)
    local g = physenv.GetGravity():Length()
    local v = velocity or self:GetWeaponParameters().MaxRange * 0.8
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

local function TestThrowVec(self, from, to)
    local halfg = physenv.GetGravity():Length() / 2
    local filter = {self, self:GetEnemy()}
    local att = self:LookupAttachment "anim_attachment_LH"
    local from = self:GetAttachment(att).Pos
    local to = self:GetShootTo()
    local dir = to - from
    local dist2D = dir:Length2D()
    local occluded = self:HasCondition(c.COND_ENEMY_OCCLUDED)
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

                self:swept("TestThrowVec", tr.StartPos, tr.HitPos,
                -Vector(2, 2, 2), Vector(2, 2, 2), nil, Color(0, tr.Hit and 0 or 255, 0))

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

local function GrenadeLOS(self)
    if DefaultCheckLOSOnGround(self) then return true end
    self.GrenadeTossVelocity = nil
    self.GrenadeTossDirection2D = nil
    self.GrenadeTossVelocity2D = nil
    self:RegisterCondition(false, "COND_WEAPON_BLOCKED_BY_FRIEND")
    return TestThrowVec(self)
end

local function ThrowGrenade(self, w, pos, dir)
    local att = self:LookupAttachment "anim_attachment_RH"
    local p = self:GetAttachment(att)
    local shootTo = self:GetShootTo()
    local dist2D = (shootTo - p.Pos):Length2D()
    local throwVec, dir2D, v2D = TestThrowVec(self, p.Pos, shootTo)
    if not throwVec then return end

    local timetoland = dist2D / v2D
    if self:HasCondition(c.COND_SEE_ENEMY) then
        shootTo = shootTo + self:GetLastVelocity() * timetoland
        throwVec, dir2D, v2D = TestThrowVec(self, p.Pos, shootTo)
    end

    if not throwVec then return end
    local ent = ents.Create "npc_grenade_frag"
    local p = self:GetAttachment(att)
    ent:Input("settimer", self, self, timetoland)
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

    util.SpriteTrail(ent, 0, color_white, true, 15, 5, 1, 0.025, "cable/redlaser")
    w:EmitSound(self:GetWeaponParameters().ShootSound)
end

local function CheckRPGGuide(self)
    local path = Path "Follow"
    path:Compute(self, self:GetShootTo())
    local isvalid = path:IsValid()
    path:Invalidate()
    return isvalid
end

local RPG_SPEED = 1500
local function FireRPG(self, w, pos, dir)
    if not self:HasValidEnemy() then return end

    local r = ents.Create "rpg_missile"
    if not IsValid(r) then return end
    local e = self:GetEnemy()
    local params = self:GetWeaponParameters()
    local enemypos = self:GetEnemyPos()
    local distance = enemypos:Distance(pos)
    local targetpos = enemypos + self:GetLastVelocity() * distance / RPG_SPEED
    local dmg = params.Damage
    if isstring(dmg) then
        dmg = GetConVar(dmg)
        dmg = dmg and dmg:GetInt() or 0
    end
    
    local path = Path "Follow"
    local step = self.loco:GetStepHeight()
    self.loco:SetStepHeight(8192)
    path:Compute(self, enemypos)
    self.loco:SetStepHeight(step)

    local aim = path:FirstSegment().forward
    r:SetPos(pos)
    r:SetOwner(self)
    r:SetAngles(aim:Angle())
    r:AddEffects(EF_NOSHADOW)
    r:SetVelocity(aim * 300 + vector_up * 128)
    r:SetLocalAngularVelocity(Angle(0, 0, 720))
    r:SetSaveValue("m_flDamage", dmg)
    r:SetNotSolid(true)
    r:Spawn()

    local t0 = CurTime()
    local t = "GreatZenkakuMan's SuperMetropolice: Guide Missile #" .. r:EntIndex()
    local traveled = 0
    timer.Create(t, 0, 0, function()
        if not (IsValid(self) and IsValid(r)) then
            timer.Remove(t)
            path:Invalidate()
            return
        end
        
        if CurTime() - t0 < 0.2 then return end
        if not IsValid(e) then
            e = self:GetEnemy()
            return
        end

        r:SetNotSolid(false)
        local p = r:GetPos()
        local epos = e:WorldSpaceCenter()
        local speed = r:GetVelocity():Length()
        path:MoveCursorToClosestPosition(r:GetPos(), 1)
        path:MoveCursor(60)
        path:Draw()

        local cursor = path:GetCursorData()
        local forward = cursor.forward
        local ppos = cursor.pos
        traveled = math.max(traveled, path:GetCursorPosition())

        local len = path:GetLength()
        local pathleft = len - traveled
        if pathleft > 60 then ppos.z = ppos.z + 120 end
        if (ppos - epos):Length2DSqr() < 40000 then ppos = epos end

        local topath = ppos - r:GetPos()
        if topath:LengthSqr() < 5000 then return end
        topath:Normalize()
        topath:Mul(speed)
        r:SetVelocity(topath - r:GetVelocity())
        r:SetAngles(topath:Angle())

        if path:GetAge() > 1 then
            local step = self.loco:GetStepHeight()
            self.loco:SetStepHeight(8192)
            path:Compute(self, epos)
            self.loco:SetStepHeight(step)
        end
    end)

    w:EmitSound(params.ShootSound)
end

local function UseCamera(self, w, pos, dir)
    if not self:HasValidEnemy() then return end
    if self:HasCondition(c.COND_ENEMY_OCCLUDED) then return end
    for _, v in ipairs(ents.FindByClass(self.ClassName)) do
        if v ~= self then
            v:SetLastPosition(self:GetShootTo())
            v:SetLastVelocity(self:GetEnemy():GetVelocity())
            v.Time.LastEnemySeen = CurTime()
            if not v:HasValidEnemy() or v:GetEnemyValue() < self:GetEnemyValue() then
                v:SetEnemy(self:GetEnemy())
                v:SetEnemyValue(self:GetEnemyValue())
            end
        end
    end

    w:EmitSound(self:GetWeaponParameters().ShootSound)
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
    MinRange = 100,
    MuzzleEffectName = "attack_npc",
    PlayGesture = true,
    ReloadSound = "Weapon_Pistol.NPC_Reload",
    ShootSound = "Weapon_Pistol.NPC_Single",
    Spread = 5,
    Tracer = 1,
    TracerName = "Tracer",
}

local WeaponList = {
    "weapon_rpg",
    "weapon_357",
    "gmod_camera",
    "weapon_frag",
    "weapon_ar2",
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_stunstick",
    "weapon_pistol",
}
local HL2Weapons = {
    gmod_camera = {
        FireFunction = UseCamera,
        HoldType = "camera",
        MaxBurstDelay = 0.4,
        MaxBurstNum = 7,
        MaxBurstRestDelay = 0.7,
        MaxRange = 4096,
        MinBurstDelay = 0.1,
        MinBurstNum = 3,
        MinBurstRestDelay = 0.5,
        MinRange = 600,
        ShootSound = "NPC_CScanner.TakePhoto",
        UnlimitedAmmo = true,
    },
    weapon_357 = {
        AmmoType = "357",
        ClipSize = 6,
        Damage = "sk_npc_dmg_357",
        Force = 1,
        HoldType = "revolver",
        MaxBurstDelay = 1.5,
        MaxBurstNum = 2,
        MaxBurstRestDelay = 2,
        MaxRange = 4096,
        MinBurstDelay = 0.8,
        MinBurstNum = 1,
        MinBurstRestDelay = 1.5,
        MinRange = 200,
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
        HoldType = "grenade",
        MaxBurstDelay = 1.5,
        MaxBurstNum = 2,
        MaxBurstRestDelay = 10,
        MaxRange = 4096,
        MinBurstDelay = 0.9,
        MinBurstNum = 1,
        MinBurstRestDelay = 4,
        MinRange = 400,
        ReloadSound = "WeaponFrag.Roll",
        ShootSound = "WeaponFrag.Throw",
        UnlimitedAmmo = true,
    },
    weapon_ar2 = {
        AmmoType = "AR2",
        ClipSize = 30,
        Damage = "sk_npc_dmg_ar2",
        HoldType = "ar2",
        ImpactEffectName = "AR2Impact",
        MaxBurstDelay = 0.1,
        MaxBurstNum = 5,
        MaxBurstRestDelay = 0.35,
        MaxRange = 2048,
        MinBurstDelay = 0.1,
        MinBurstNum = 2,
        MinBurstRestDelay = 0.2,
        MinRange = 160,
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
        HoldType = "shotgun",
        MaxBurstDelay = 0.8,
        MaxBurstNum = 3,
        MaxBurstRestDelay = 1.5,
        MaxRange = 500,
        MinBurstDelay = 0.7,
        MinBurstNum = 1,
        MinBurstRestDelay = 1.2,
        MinRange = 80,
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
        MinRange = 100,
        MuzzleEffectName = "attack1",
        ReloadSound = "Weapon_SMG1.NPC_Reload",
        ShootSound = "Weapon_SMG1.NPC_Single",
    },
    weapon_stunstick = {
        CheckLOS = CheckLOSMelee,
        Damage = 40,
        DamageType = DMG_DISSOLVE,
        DelayedFire = 0.35,
        Force = 0.1,
        HitSound = "Weapon_StunStick.Melee_Hit",
        HoldType = "melee",
        InitFunction = ActivateStunStick,
        IsMelee = true,
        MaxBurstDelay = 1.2,
        MaxBurstNum = 1,
        MaxBurstRestDelay = 1.2,
        MaxRange = 100,
        MinBurstDelay = 1,
        MinBurstNum = 1,
        MinBurstRestDelay = 1,
        MinRange = 0,
        MissSound = "Weapon_StunStick.Swing",
        MuzzleEffectName = "attack1",
        ReloadSound = "Weapon_StunStick.Activate",
        ShootSound = false,
        Spread = 0,
        UnlimitedAmmo = true,
    },
    weapon_rpg = {
        CheckLOS = CheckRPGGuide,
        Damage = "sk_npc_dmg_rpg_round",
        FireFunction = FireRPG,
        HoldType = "rpg",
        MaxBurstDelay = 0.25,
        MaxBurstNum = 5,
        MaxBurstRestDelay = 10,
        MaxRange = 8192,
        MinBurstDelay = 0.25,
        MinBurstNum = 2,
        MinBurstRestDelay = 5,
        MinRange = 800,
        ReloadSound = "Weapon_RPG.LaserOff",
        ShootSound = "Weapon_RPG.NPC_Single",
        UnlimitedAmmo = true,
    },
}

local SF_WEAPON_DENY_PLAYER_PICKUP = 2
local SF_WEAPON_NOT_PUNTABLE_BY_GRAVITY_GUN = 4
function ENT:SetActiveWeapon(weaponID)
    local wTable = self.Weapons[weaponID]
    if not wTable then return end
    local weapon = wTable.Entity
    if not IsValid(weapon) then return end
    local oldWeapon = self:GetNWEntity "ActiveWeapon"
    if IsValid(oldWeapon) then oldWeapon:SetNoDraw(true) end
    self:SetSaveValue("m_hActiveWeapon", weapon)
    self:SetNWEntity("ActiveWeapon", weapon)
    self.Weapons.ActiveWeaponID = weaponID
    weapon:SetNoDraw(false)

    self:SetTacticalConfig(self:SelectTacticalConfigByWeapon(weaponID))
end

function ENT:GetWeaponTable()
    return self.Weapons[self.Weapons.ActiveWeaponID]
end

function ENT:GetWeaponParameters()
    local wTable = self:GetWeaponTable()
    return wTable.Parameters
end

function ENT:GetClip()
    local wTable = self:GetWeaponTable()
    return wTable.Clip
end

function ENT:Give(classname)
    local w = ents.Create(classname)
    if not IsValid(w) then return end
    w:SetKeyValue("spawnflags", SF_WEAPON_DENY_PLAYER_PICKUP + SF_WEAPON_NOT_PUNTABLE_BY_GRAVITY_GUN)
    w:SetParent(self)
    w:SetOwner(self)
    w:Fire("SetParentAttachmentMaintainOffset", "anim_attachment_RH")
    w:AddEffects(EF_BONEMERGE)
    w:SetNoDraw(true)
    w:Spawn()

    local t = {
        Clip = 0,
        Entity = w,
        Parameters = table.Merge(table.Copy(DefaultParameters), HL2Weapons[classname]),
    }
    t.Clip = t.Parameters.ClipSize

    table.insert(self.Weapons, t)
    self:DeleteOnRemove(w)
    if isfunction(t.Parameters.InitFunction) then
        t.Parameters.InitFunction(self, w, t)
    end

    table.sort(self.Weapons, function(a, b)
        return a.Parameters.MaxRange < b.Parameters.MaxRange
    end)
    
    return w
end

function ENT:Initialize_Weapon()
    local skill = game.GetSkillLevel()
    local SpreadMul = {1.2, 1, 0.3}
    local BurstRestMul = {1.1, 1, 0.8}
    local WeaponRestrict = {5, 3, 1}
    self.BurstNum = 0
    self.Weapons = {}
    self.WeaponShootCount = 0
    self.WeaponSpreadMul = SpreadMul[skill]
    self.WeaponBurstRestMul = BurstRestMul[skill]
    self.Time.WeaponBurstRest = CurTime()
    self.Time.WeaponFire = CurTime()
    self.Time.FinishReloading = CurTime()

    local weaponclass = GetConVar "gmod_npcweapon":GetString()
    if HL2Weapons[weaponclass] then
        self:Give(weaponclass)
    else
        local WeaponSelection = {}
        for i = WeaponRestrict[skill], #WeaponList do
            table.insert(WeaponSelection, i)
        end

        local NumWeapons = 2
        if skill == 3 and math.random() > 0.9 then
            NumWeapons = #WeaponSelection
        end

        for _ = 1, NumWeapons do
            local i = math.random(#WeaponSelection)
            local n = WeaponSelection[i]
            table.remove(WeaponSelection, i)
            self:Give(WeaponList[n])
        end
    end
    
    self:SetActiveWeapon(math.random(#self.Weapons))
end

function ENT:OnKilled_DropWeapon(d)
    local id = self:LookupAttachment "anim_attachment_RH"
    local att = self:GetAttachment(id)
    local pos, ang = att.Pos, att.Ang
    for _, wt in ipairs(self.Weapons) do
        local w = wt.Entity
        if IsValid(w) then
            w:SetOwner(NULL)
            w:SetParent(NULL)
            w:RemoveEffects(EF_BONEMERGE)
            w:SetMoveType(MOVETYPE_VPHYSICS)
            w:SetNoDraw(false)
            w:SetPos(pos)
            w:SetAngles(ang)
        end
    end
end

function ENT:CanPrimaryFire()
    if self:HasCondition(c.COND_RELOADING) then return end
    local w = self:GetActiveWeapon()
    if not IsValid(w) then return end
    if CurTime() < self.Time.FinishReloading then return end
    return self:GetWeaponParameters().IsMelee or self:GetClip() > 0
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

    if self:HasCondition(c.COND_ENEMY_OCCLUDED) then
        return self:GetLastPosition()
    end
    
    local params = self:GetWeaponParameters()
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
    if self:HasValidEnemy() and not self:HasCondition(c.COND_WEAPON_SIGHT_OCCLUDED) then
        local dir = (self:GetShootTo() - self:GetShootPos()):GetNormalized()
        if dir:Dot(self:GetForward()) > 0.9 then
            return dir
        end
    end

    local id = w:LookupAttachment "muzzle"
    if id == 0 then
        return self:GetAttachment(self:LookupAttachment "eyes").Ang:Forward()
    end

    return w:GetAttachment(id).Ang:Forward()
end

function ENT:PrimaryFire()
    if CurTime() < self.Time.WeaponFire then return end
    if not self:CanPrimaryFire() then return end

    local w = self:GetActiveWeapon()
    if not IsValid(w) then return end
    local params = self:GetWeaponParameters()
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
        if not self:CheckAlive(self) then return end
        if not IsValid(w) then return end
        local shootPos = self:GetShootPos()
        local dir = self:GetAimVector()
        if w:IsScripted() and w:GetClass() ~= "gmod_camera" then
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
        self:RestartGesture(self:TranslateActivity(ACT_HL2MP_GESTURE_RANGE_ATTACK))
    end

    return true
end

function ENT:Reload()
    if self:HasCondition(c.COND_RELOADING) then return end
    local params = self:GetWeaponParameters()
    if not params then return end
    local s = params.ReloadSound
    local act = self:TranslateActivity(ACT_HL2MP_GESTURE_RELOAD)
    local seq = self:SelectWeightedSequence(act)
    if seq < 0 then return end
    local reloadtime = self:SequenceDuration(seq)
    if params.ReloadSoundDelay then
        timer.Simple(params.ReloadSoundDelay, function()
            if not IsValid(self) then return end
            self:EmitSound(s)
        end)
    else
        self:EmitSound(s)
    end

    self:SetMovementActivity(self:TranslateActivity(ACT_HL2MP_IDLE))
    self:AddGesture(act)

    self:RegisterCondition(true, "COND_RELOADING")
    self.Time.FinishReloading = CurTime() + reloadtime
    timer.Simple(reloadtime, function()
        if not IsValid(self) then return end
        self:RegisterCondition(false, "COND_RELOADING")
        self:RegisterCondition(true, "COND_RELOAD_FINISHED")
        self:GetWeaponTable().Clip = params.ClipSize
    end)
end
