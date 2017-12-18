--[[
	The main projectile entity of Splatoon SWEPS!!!
]]
AddCSLuaFile "shared.lua"
include "shared.lua"

local dropangle = Angle(0, 0, 90)
local reference_polys = {}
local reference_vert = Vector(1)
local circle_polys = 360 / 12
for i = 1, circle_polys do
	table.insert(reference_polys, Vector(reference_vert))
	reference_vert:Rotate(Angle(0, circle_polys, 0))
end

ENT.DisableDuplicator = true
util.PrecacheModel(ENT.FlyingModel)
function ENT:Initialize()
	if not file.Exists(self.FlyingModel, "GAME") then
		self:Remove()
		return
	end
	
	self:SharedInit()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:StartMotionController()
	local ph = self:GetPhysicsObject()
	if not IsValid(ph) then return end
	ph:SetMaterial "watermelon"
	ph:EnableGravity(false)
	self.InitTime = CurTime()
	self.InitPos = self:GetPos()
	self.Straight = self.Straight or SplatoonSWEPs.MPdt
	self.ColorCode = self.ColorCode or 0
	self.SplashNum = self.SplashNum or -1
	self.SplashPatterns = self.SplashPatterns or 1
	self.SplashInterval = self.SplashInterval or 0
	self.SplashInitMul = self.SplashInitMul or 0
	self.SplashCount = 0
	self.Damage = self.Damage or 0
	self.DecreaseDamage = self.DecreaseDamage or 0
	self.MinDamage = self.MinDamage or 0
	self.MinDamageTime = self.MinDamageTime or 0
	self.InkRadius = self.InkRadius or 10
	self.MinRadius = self.MinRadius or 10
	self.DecreaseRadius = self.DecreaseRadius or 0
	self.MinRadiusTime = self.MinRadiusTime or 0
	self.SplashInit = self.SplashInterval / self.SplashPatterns * (self.SplashInitMul + math.random(0, 0))
	self.InitVelocity = self.InitVelocity or vector_origin
	self.ShadowParams = {
		secondstoarrive = self.Straight,
		pos = self.InitPos + self.InitVelocity * self.Straight,
		angle = dropangle,
		maxangular = 0,
		maxangulardamp = 0,
		maxspeed = 32768,
		maxspeeddamp = 10000,
		dampfactor = .8,
		teleportdistance = 0,
		deltatime = 0,
	}
	
	self.InitVelocity = nil
	util.SpriteTrail(self, 0, SplatoonSWEPs:GetColor(self.ColorCode), false,
	self.TrailWidth or 8, self.TrailEnd or 2, self.TrailLife or .15,
	1 / ((self.TrailWidth or 8) + (self.TrailEnd or 2)), "effects/beam_generic01.vmt")
end

local dampXY, dampZ = 5, 2
function ENT:PhysicsSimulate(phys, dt)
	local vel = phys:GetVelocity()
	if CurTime() - self.InitTime >= self.Straight then
		local accel = (math.NormalizeAngle(vel:Angle().pitch - phys:GetAngles().roll) / dt - phys:GetAngleVelocity().x) / dt
		vel.z = vel.z > 0 and vel.z * dampZ or 0
		return Vector(accel), -vel / (dampXY * dt) + physenv.GetGravity(), SIM_GLOBAL_ACCELERATION
	else
		self.ShadowParams.deltatime = dt
		phys:ComputeShadowControl(self.ShadowParams)
	end
	return vector_origin, vector_origin, SIM_GLOBAL_ACCELERATION
end

local dropposdelta = 16
function ENT:PhysicsUpdate(phys)
	phys:EnableGravity(CurTime() - self.InitTime >= self.Straight)
	
	if self.SplashCount > self.SplashNum then return end
	local len = self:GetPos() - self.InitPos
	local nextlen = self.SplashCount * self.SplashInterval + self.SplashInit
	len = len.x * len.x + len.y * len.y
	if len > nextlen * nextlen - self.InkRadius * self.InkRadius / dropposdelta then
		self.SplashCount = self.SplashCount + 1
		local splash = ents.Create "projectile_ink"
		if not IsValid(splash) then return end
		local rand = Vector(SplatoonSWEPs.mSplashDrawRadius)
		rand:Rotate(Angle(0, math.Rand(-180, 180), 0))
		splash:SetPos(phys:GetPos() + rand - vector_up * 6)
		splash:SetAngles(dropangle)
		splash:SetOwner(self:GetOwner())
		splash:SetInkColorProxy(self:GetInkColorProxy())
		splash.InkRadius = self.SplashRadius or self.InkRadius
		splash.MinRadius = splash.InkRadius * self.MinRadius / self.InkRadius
		splash.InkColor = self.InkColor
		splash.InitVelocity = -vector_up * 100
		splash.ColorCode = self.ColorCode
		splash.TrailWidth = 4
		splash.TrailEnd = 1
		splash.TrailLife = .1
		splash:Spawn()
		splash:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		splash:SetModelScale(0.5)
		splash.InitPos = self.InitPos
	end
end

function ENT:PhysicsCollide(coldata, collider)
	SafeRemoveEntityDelayed(self, 0)
	local tr = util.QuickTrace(coldata.HitPos, coldata.HitNormal, self)
	if not tr.HitSky and tr.HitWorld then
		SplatoonSWEPs.InkManager.AddQueue(
			tr.HitPos,
			tr.HitNormal,
			math.Remap(math.Clamp(self.InitPos.z - self:GetPos().z,
			SplatoonSWEPs.mPaintNearDistance, SplatoonSWEPs.mPaintFarDistance),
			SplatoonSWEPs.mPaintFarDistance, SplatoonSWEPs.mPaintNearDistance,
			self.MinRadius, self.InkRadius),
			self.ColorCode,
			reference_polys
		)
	else
		if IsValid(coldata.PhysObject) then
			coldata.PhysObject:SetMass(0)
			coldata.PhysObject:SetVelocityInstantaneous(vector_origin)
		end
		
		local d, o = DamageInfo(), self:GetOwner()
		local t = CurTime() - self.InitTime - self.DecreaseDamage
		d:SetAttacker(o)
		d:SetDamage(math.Remap(-math.Clamp(t, 0, self.MinDamageTime), -self.MinDamageTime, 0, self.MinDamage, self.Damage))
		d:SetDamageForce(vector_origin)
		d:SetDamagePosition(tr.HitPos)
		d:SetDamageType(DMG_BLAST)
		d:SetMaxDamage(self.Damage)
		d:SetReportedPosition(self:GetPos())
		d:SetInflictor(IsValid(o) and isfunction(o.GetActiveWeapon) and o:GetActiveWeapon() or NULL)
		coldata.HitEntity:TakeDamageInfo(d)
	end
end

function ENT:Think()
	if Entity(1):KeyDown(IN_ATTACK2) then
		self:Remove()
	end
end
