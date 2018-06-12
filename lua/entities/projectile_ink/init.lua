--[[
	The main projectile entity of SplatoonSWEPs!!!
]]
local ss = SplatoonSWEPs
if not ss then return end

AddCSLuaFile "shared.lua"
include "shared.lua"

ENT.DisableDuplicator = true
ENT.SplashCount = 0 -- Vars for ink drop pattern
ENT.SplashInitMul = 0 --
ENT.SplashInterval = 0 --
ENT.SplashNum = -1 --
ENT.SplashPatterns = 1 --
ENT.SplashRandom = 0 --

ENT.Damage = 0 -- Ink damage amount
ENT.MinDamage = 0 --
ENT.DecreaseDamage = 0 --
ENT.MinDamageTime = 0 --

ENT.InkType = 1 -- Ink graphics type
ENT.InkRatio = 1 -- Ink graphics X:Y
ENT.InkYaw = 0 -- Shooting direction

ENT.InkRadius = 1 -- Ink draw radius
ENT.MinRadius = 1 --
ENT.DecreaseRadius = 0 --
ENT.MinRadiusTime = 0 --
ENT.SplashRadius = 0 --
ENT.SplashMinRadius = 0 --

ENT.ColRadius = ss.mColRadius
ENT.ColorCode = 0 -- Ink color
ENT.InitVelocity = vector_origin -- Initial velocity
ENT.InitVelocityLength = 0 -- Short for ENT.InitVelocity:Length()
ENT.IsDrop = false -- Ink is created from another ink = true
ENT.Straight = 0 -- mStraightFrame, flying time without gravity

ENT.TrailWidth = 10 -- Sprite trail properties
ENT.TrailEnd = 4 --
ENT.TrailLife = .15 --

-- Localized global functions
local GetGravity = physenv.GetGravity
local Angle, CurTime, DamageInfo, FrameTime, ipairs, isfunction,
	IsValid, pairs, SafeRemoveEntityDelayed, Vector
 =	Angle, CurTime, DamageInfo, FrameTime, ipairs, isfunction,
	IsValid, pairs, SafeRemoveEntityDelayed, Vector
local abs, Clamp, cos, max, min, NormalizeAngle, rad, random, Remap, sqrt
 =	math.abs, math.Clamp, math.cos, math.max, math.min,
	math.NormalizeAngle, math.rad, math.random,
	math.Remap, math.sqrt
local SpriteTrail, TraceHull, QuickTrace
 =	util.SpriteTrail, util.TraceHull, util.QuickTrace
local entsCreate, cleanupAdd, insert, playerGetAll, tSimple
 =	ents.Create, cleanup.Add, table.insert, player.GetAll, timer.Simple

-- Localized constant values
local FarDistance, NearDistance
 =	ss.mPaintFarDistance, ss.mPaintNearDistance
local gravity = GetGravity()
local world = game.GetWorld()
local droptime = sqrt(2 / 600)
local dropangle = Angle(0, 0, 90)
local MAX_SLOPE = cos(rad(45))

-- Shared moving shadow parameter table
local shadowparams = {
	secondstoarrive = ENT.Straight,
	pos = vector_origin,
	angle = dropangle,
	maxangular = .1,
	maxangulardamp = .8,
	maxspeed = 32768,
	maxspeeddamp = 10000,
	dampfactor = 0,
	teleportdistance = 0,
	deltatime = 0,
}
local function MakeNoCollide(self, ent)
	ss:MakeNoCollide(self, ent, self.NoCollide)
	insert(self.NoCollideFilter, ent)
end

-- Returns ink draw radius.
-- The higher it started to fall, the smaller the radius.
function ENT:GetRadius(min, rad)
	return Remap(Clamp(self.InitPos.z - self:GetPos().z,
	NearDistance, FarDistance), NearDistance, FarDistance, min, rad)
end

function ENT:Initialize()
	ss.NumInkEntities = ss.NumInkEntities + 1
	self.ColBound = ss.vector_one * self.ColRadius
	self:SharedInit()
	self:PhysicsInitSphere(self.ColRadius, "watermelon")
	self:PhysWake()
	
	local ph = self:GetPhysicsObject()
	if not IsValid(ph) then return end
	ph:AddGameFlag(FVPHYSICS_CONSTRAINT_STATIC)
	ph:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
	ph:AddGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG)
	ph:AddGameFlag(FVPHYSICS_NO_PLAYER_PICKUP)
	ph:AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
	ph:EnableGravity(self.IsDrop)
	ph:SetBuoyancyRatio(0)
	self:SetFriction(5)
	self:StartMotionController()
	self.InitPos = self:GetPos()
	self.InitTime = CurTime()
	self.InitVelocityLength = self.InitVelocityLength / 4.5
	self.InitDirection = self.InitVelocity:GetNormalized()
	self.NoCollide = {}
	self.NoCollideFilter = {self, self:GetOwner()}
	self.SplashInit = self.SplashInterval / self.SplashPatterns * self.SplashInitMul
	self.Destination = self.InitPos + self.InitVelocity * self.Straight
	self.SplashMinRadius = self.SplashRadius * self.MinRadius / self.InkRadius
	self.Trail = SpriteTrail(self, 0, ss:GetColor(self.ColorCode), false,
	self.TrailWidth, self.TrailEnd, self.TrailLife, 1 / (self.TrailWidth + self.TrailEnd),
	"effects/beam_generic01.vmt")
	
	if GetGravity() == gravity then return end
	gravity = GetGravity()
	droptime = sqrt(2 / gravity:Length())
end

function ENT:OnRemove()
	ss.NumInkEntities = ss.NumInkEntities - 1
	for _, n in pairs(self.NoCollide) do
		SafeRemoveEntity(n)
	end
end

-- Physics simulation for ink trajectory
-- The first some frames(1/60 sec.) ink flies without gravity
-- After that, ink decelerates horizontally and is affected by gravity
function ENT:PhysicsSimulate(p, t)
	local pos, v = p:GetPos(), p:GetVelocity()
	local fence = ss:CheckFence(self, pos, pos + v * t, self.NoCollideFilter, -self.ColBound, self.ColBound)
	if fence then
		MakeNoCollide(self, fence)
		tSimple(0, function()
			if not IsValid(self) then return end
			self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		end)
	else
		ss:RemoveNoCollide(self, nil, self.NoCollide)
		tSimple(0, function()
			if not IsValid(self) then return end
			self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
		end)
	end
	
	if self.IsDrop or self.Hit then return vector_origin, vector_origin, SIM_GLOBAL_ACCELERATION end
	if max(0, CurTime() - self.InitTime + FrameTime()) >= self.Straight then -- Affected by gravity and decelerates horizontally
		local accel = (NormalizeAngle(v:Angle().p - p:GetAngles().r) / t - p:GetAngleVelocity().x) / t
		v.z = max(0, v.z)
		return Vector(accel), -v / (t * self.InitVelocityLength) + gravity, SIM_GLOBAL_ACCELERATION
	else -- Goes straight
		shadowparams.deltatime = t
		shadowparams.pos = self.Destination
		shadowparams.secondstoarrive = self.Straight
		p:ComputeShadowControl(shadowparams)
	end
	
	return vector_origin, vector_origin, SIM_GLOBAL_ACCELERATION
end

function ENT:PhysicsUpdate(phys)
	if not (IsValid(phys) and self:IsInWorld()) then
		return SafeRemoveEntityDelayed(self, 0)
	elseif self.IsDrop or self.Hit then
		return
	end
	
	phys:EnableGravity(max(0, CurTime() - self.InitTime) >= self.Straight)
	if self.SplashCount > self.SplashNum then return end -- Creates an ink drop
	local len = (phys:GetPos() - self.InitPos):Length2DSqr()
	local nextlen = self.SplashCount * self.SplashInterval + self.SplashInit
	if len < nextlen * nextlen then return end
	self.SplashCount = self.SplashCount + 1
	nextlen = nextlen + random(-1, 1) * ss.mSplashDrawRadius
	
	local droppos = self.InitPos + self.InitDirection * nextlen - vector_up * 6
	if ss.NumInkEntities > 50 then
		local t = ss.SquidTrace
		t.start, t.endpos = droppos, droppos - vector_up * 32768
		t.mins, t.maxs = -self.ColBound, self.ColBound
		t.filter = self
		local tr = TraceHull(t)
		local radius = self:GetRadius(self.SplashMinRadius, self.SplashRadius)
		local color, yaw = self.ColorCode, self.InkYaw
		tSimple(sqrt(abs(phys:GetPos().z - tr.HitPos.z)) * droptime, function()
			ss:Paint(tr.HitPos, tr.HitNormal, radius, color, yaw, random(1, 3), 1)
		end)
		
		return
	end
	
	local splash = entsCreate "projectile_ink"
	if not IsValid(splash) then return end
	splash:SetPos(droppos)
	splash:SetAngles(dropangle)
	splash:SetOwner(self:GetOwner())
	splash:SetInkColorProxy(self:GetInkColorProxy())
	splash.InkRadius = self.SplashRadius
	splash.MinRadius = self.SplashMinRadius
	splash.ColorCode = self.ColorCode
	splash.TrailWidth = 4
	splash.TrailEnd = 1
	splash.TrailLife = .1
	splash.InkYaw = self.InkYaw
	splash.InkType = random(1, 3)
	splash.InitPos = self.InitPos
	splash.IsDrop = true
	splash:Spawn()
	for _, p in ipairs(playerGetAll()) do
		cleanupAdd(p, SplatoonSWEPs.CleanupTypeInk, splash)
	end
end

function ENT:PhysicsCollide(coldata, collider) -- If ink hits something
	local dp = coldata.OurOldVelocity * FrameTime()
	if ss:CheckFence(self, coldata.HitPos, coldata.HitPos, self.NoCollideFilter, -self.ColBound, self.ColBound) then
		MakeNoCollide(self, coldata.HitEntity)
		coldata.HitEntity:SetVelocity(coldata.TheirOldVelocity)
		coldata.HitObject:SetVelocityInstantaneous(coldata.TheirOldVelocity)
		tSimple(0, function()
			if not (IsValid(collider) and IsValid(self)) then return end
			self:SetPos(coldata.HitPos)
			self:SetVelocity(coldata.OurOldVelocity)
			collider:SetPos(coldata.HitPos)
			collider:SetVelocityInstantaneous(coldata.OurOldVelocity)
		end)
		
		return
	end
	
	self.Hit = true
	SafeRemoveEntityDelayed(self.Trail, self.TrailLife)
	SafeRemoveEntityDelayed(self, self.TrailLife)
	tSimple(0, function()
		if not IsValid(self) then return end
		self:SetMoveType(MOVETYPE_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end)
	
	local t = max(0, CurTime() - self.InitTime)
	if coldata.HitEntity:IsWorld() then -- If ink hits worldspawn
		local tr = QuickTrace(coldata.HitPos, coldata.HitNormal, self)
		if tr.HitSky then return end
		self:EmitSound "SplatoonSWEPs_Ink.HitWorld"
		
		local ratio = self.InkRatio -- Shooter ink is sometimes stretched
		local radius = self:GetRadius(self.MinRadius, self.InkRadius)
		if self.InkType > 3 and tr.HitNormal.z > MAX_SLOPE and collider:IsGravityEnabled() then
			local min = self.InitVelocity * self.Straight
			local max = min:Length() min = max / 3
			local actual = tr.HitPos:DistToSqr(self.InitPos)
			local stretch = Remap(Clamp(actual, min, max), min, max, 1, 1.5)
			radius, ratio = radius * stretch, .6 / stretch
		else
			self.InkType = random(1, 3)
		end
		
		ss:Paint(tr.HitPos, tr.HitNormal, radius, self.ColorCode, self.InkYaw, self.InkType, ratio)
	elseif self.Damage > 0 then -- If ink hits an NPC or something
		local w = ss:IsValidInkling(coldata.HitEntity)
		if not w or w.ColorCode == self.ColorCode then return end
		local d, o = DamageInfo(), self:GetOwner()
		t = t - self.DecreaseDamage
		d:SetDamage(Remap(-Clamp(t, 0, self.MinDamageTime), -self.MinDamageTime, 0, self.MinDamage, self.Damage))
		d:SetDamageForce(-coldata.HitNormal)
		d:SetDamagePosition(coldata.HitPos)
		d:SetDamageType(DMG_GENERIC)
		d:SetMaxDamage(self.Damage)
		d:SetReportedPosition(self:GetPos())
		d:SetAttacker(IsValid(o) and o or world)
		d:SetInflictor(IsValid(o) and isfunction(o.GetActiveWeapon) and IsValid(o:GetActiveWeapon()) and o:GetActiveWeapon() or world)
		coldata.HitEntity:TakeDamageInfo(d)
	end
end
