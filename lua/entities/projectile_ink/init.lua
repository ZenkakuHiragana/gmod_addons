--[[
	The main projectile entity of Splatoon SWEPS!!!
]]
AddCSLuaFile "shared.lua"
include "shared.lua"

ENT.DisableDuplicator = true
ENT.IsSplatoonProjectile = true
local dropangle = Angle(0, 0, 90)
function ENT:Initialize()
	if not file.Exists(self.FlyingModel, "GAME") then
		self:Remove()
		return
	end
	
	self.Hit = false
	self:SharedInit()
	self:PhysicsInitSphere(self.ColRadius or SplatoonSWEPs.mColRadius, "watermelon")
	self:StartMotionController()
	local ph = self:GetPhysicsObject()
	if not IsValid(ph) then return end
	ph:ApplyForceCenter(vector_origin)
	ph:EnableGravity(false)
	self.InitTime = CurTime()
	self.InitPos = self:GetPos()
	self.Straight = self.Straight or 0
	self.ColorCode = self.ColorCode or 0
	self.SplashNum = self.SplashNum or -1
	self.SplashPatterns = self.SplashPatterns or 1
	self.SplashInterval = self.SplashInterval or 0
	self.SplashInitMul = self.SplashInitMul or 0
	self.SplashRandom = self.SplashRandom or 0
	self.SplashCount = 0
	self.Damage = self.Damage or 0
	self.DecreaseDamage = self.DecreaseDamage or 0
	self.MinDamage = self.MinDamage or 0
	self.MinDamageTime = self.MinDamageTime or 0
	self.InkRadius = self.InkRadius or 10
	self.MinRadius = self.MinRadius or 10
	self.DecreaseRadius = self.DecreaseRadius or 0
	self.MinRadiusTime = self.MinRadiusTime or 0
	self.SplashInit = self.SplashInterval / self.SplashPatterns * self.SplashInitMul
	self.InitVelocity = self.InitVelocity or vector_origin
	self.ShadowParams = {
		secondstoarrive = self.Straight,
		pos = self.InitPos + self.InitVelocity * self.Straight,
		angle = dropangle,
		maxangular = .1,
		maxangulardamp = .8,
		maxspeed = 32768,
		maxspeeddamp = 10000,
		dampfactor = .8,
		teleportdistance = 0,
		deltatime = 0,
	}
	
	self.ColRadius = nil
	util.SpriteTrail(self, 0, SplatoonSWEPs:GetColor(self.ColorCode), false,
	self.TrailWidth or 8, self.TrailEnd or 2, self.TrailLife or .15,
	1 / ((self.TrailWidth or 8) + (self.TrailEnd or 2)), "effects/beam_generic01.vmt")
end

local dampXY, dampZ = 6, 2
function ENT:PhysicsSimulate(phys, dt)
	local vel = phys:GetVelocity()
	if math.max(0, CurTime() - self.InitTime) >= self.Straight then
		local accel = (math.NormalizeAngle(vel:Angle().pitch - phys:GetAngles().roll) / dt - phys:GetAngleVelocity().x) / dt
		vel.z = vel.z > 0 and vel.z * dampZ or 0
		return Vector(accel), -vel / (dampXY * dt) + physenv.GetGravity() * 5, SIM_GLOBAL_ACCELERATION
	else
		self.ShadowParams.deltatime = dt
		phys:ComputeShadowControl(self.ShadowParams)
	end
	return vector_origin, vector_origin, SIM_GLOBAL_ACCELERATION
end

local dropposdelta = -vector_up * 6
local splashrandom = {-1, 0, 1}
function ENT:PhysicsUpdate(phys)
	if not (IsValid(phys) and self:IsInWorld()) then
		return SafeRemoveEntityDelayed(self, 0)
	end
	phys:EnableGravity(math.max(0, CurTime() - self.InitTime) >= self.Straight)
	if self.SplashCount > self.SplashNum then return end
	local len = self:GetPos() - self.InitPos
	local nextlen = self.SplashCount * self.SplashInterval + self.SplashInit
	len = len.x * len.x + len.y * len.y
	if len > nextlen * nextlen then
		local splash = ents.Create "projectile_ink"
		if not IsValid(splash) then return end
		nextlen = nextlen + splashrandom[(self.SplashCount + self.SplashRandom) % 3 + 1] * SplatoonSWEPs.mSplashDrawRadius
		splash:SetPos(self.InitPos + self.InitVelocity:GetNormalized() * nextlen + dropposdelta)
		splash:SetAngles(dropangle)
		splash:SetOwner(self:GetOwner())
		splash:SetInkColorProxy(self:GetInkColorProxy())
		splash.ColRadius = SplatoonSWEPs.mSplashColRadius
		splash.InkRadius = self.SplashRadius or self.InkRadius
		splash.MinRadius = splash.InkRadius * self.MinRadius / self.InkRadius
		splash.ColorCode = self.ColorCode
		splash.TrailWidth = 4
		splash.TrailEnd = 1
		splash.TrailLife = .1
		splash.InkYaw = self.InkYaw
		splash.InkType = math.random(1, 3)
		splash:Spawn()
		splash:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		splash:SetModelScale(.5)
		splash.InitPos = self.InitPos
		self.SplashCount = self.SplashCount + 1
	end
end

local MAX_SLOPE = math.cos(math.rad(45))
function ENT:PhysicsCollide(coldata, collider)
	SafeRemoveEntityDelayed(self, 0)
	local ss = SplatoonSWEPs
	local t = math.max(0, CurTime() - self.InitTime)
	if coldata.HitEntity:IsWorld() then
		local tr = util.QuickTrace(coldata.HitPos, coldata.HitNormal, self)
		if tr.HitSky then return end
		self:EmitSound "SplatoonSWEPs_Ink.HitWorld"
		local radius = math.Remap(math.Clamp(self.InitPos.z - self:GetPos().z,
			ss.mPaintNearDistance, ss.mPaintFarDistance),
			ss.mPaintFarDistance, ss.mPaintNearDistance,
			self.MinRadius, self.InkRadius)
		if self.InkType > 3 and tr.HitNormal.z > MAX_SLOPE and collider:IsGravityEnabled() then
			local min, max, actual = self.InitVelocity * self.Straight, nil, tr.HitPos - self.InitPos
			max, actual = min:Length(), actual:Length2D() min = max / 3
			radius = radius * math.Remap(math.Clamp(actual, min, max), min, max, 1, 1.6)
		else
			self.InkType = math.random(1, 3)
		end
		
		return ss.InkManager.AddQueue(tr.HitPos, tr.HitNormal, radius, self.ColorCode, self.InkYaw, self.InkType)
	elseif self.Damage > 0 then
		local d, o = DamageInfo(), self:GetOwner()
		t = t - self.DecreaseDamage
		d:SetDamage(math.Remap(-math.Clamp(t, 0, self.MinDamageTime), -self.MinDamageTime, 0, self.MinDamage, self.Damage))
		d:SetDamageForce(-coldata.HitNormal)
		d:SetDamagePosition(coldata.HitPos)
		d:SetDamageType(DMG_GENERIC)
		d:SetMaxDamage(self.Damage)
		d:SetReportedPosition(self:GetPos())
		d:SetAttacker(o)
		d:SetInflictor(IsValid(o) and isfunction(o.GetActiveWeapon) and o:GetActiveWeapon() or NULL)
		return coldata.HitEntity:TakeDamageInfo(d)
	end
end

function ENT:Think()
	if self.Hit then self:Remove() --end
	elseif Entity(1):KeyDown(IN_ATTACK2) then
		self:Remove()
	end
end
