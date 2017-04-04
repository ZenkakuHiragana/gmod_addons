--[[
	Splashootee is a Splashooter's projectile.
	This prints orange ink if it hit a wall.
]]

ENT.Type = "anim"
ENT.Base = "splashootee"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
 
ENT.PrintName		= "Splat Blaster Projectile"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "explode ink"
ENT.Instructions	= "none"

ENT.FallTimer = 10
ENT.SplashNum = 1
ENT.SplashLen = 1
ENT.SplashInit = 1
ENT.V0 = Vector(0, 0, 0)
ENT.InkRadius = 20
ENT.DropInitname = ""
ENT.Dropname = ""
ENT.InkDmgname = ""
ENT.Normal = Vector(0, 0, 0)

local DirectHitSound = Sound("SplatoonSWEPs/ShotExplosionDirect00.mp3")
local HitSound = Sound("SplatoonSWEPs/shooter/ShotExplosion00.wav")
local WallHitSound = Sound("SplatoonSWEPs/shooter/ShotExplosionLight00.mp3")
local mat = Material("models/props_c17/metalladder001")
local big, medium, small, micro = 19, 10, 5, 3

if SERVER then
	AddCSLuaFile("shared.lua")

elseif CLIENT then
	ENT.AutomaticFrameAdvance = true
end

local function createink(self, t)
	if t.Hit then
		if t.HitWorld then
			local p = ents.Create("splashootee")
			p:SetModel("models/spitball_small.mdl")
			p:SetOwner(self.Owner)
			p:SetColor(self.ProjColor)
			p:SetPhysicsAttacker(self.Owner)
			p.InkColor = self.InkColor
			p.Dmg = 0
			p.InkRadius = self.InkRadius
			p.SplashNum = self.SplashNum
			p.SplashLen = self.SplashLen
			p:SetNoDraw(true)
			p:Spawn()
			p:BecomeTrigger({
				HitPos = t.HitPos,
				HitNormal = -t.HitNormal
			})
		else
			util.Decal("Ink" .. self.InkColor, t.HitPos + t.HitNormal, t.HitPos - t.HitNormal)
		end
	end
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Blaster = true
end

function ENT:Explode(ent)
	local dl, r = {Vector(1, 0, 0), Vector(-1, 0, 0),
					Vector(0, 1, 0), Vector(0, -1, 0),
					Vector(0, 0, 1), Vector(0, 0, -1)
				}, self.Radius
	local rl = {Angle(30, 0, 0), Angle(30, 0, 0),
				Angle(0, 30, 0), Angle(0, 30, 0),
				Angle(0, 0, 30), Angle(0, 0, 30)
				}
	
	local loops = 12
	local loopssphere = 12
	local d = Vector(1, 0, 0)
	d:Rotate(Angle(90 - 180 / loopssphere, 0, 0))
	
	for _ = 1, loopssphere do
		for i = 1, loops do
			if (i % 2 == 0 and _ == loopssphere / 3) or _ == loopssphere / 2 then
				local p = ents.Create("splashootee")
				local pos = self:GetPos() + d * self.Radius
				pos.z = self:GetPos().z
				p:SetPos(pos)
				p:SetModel("models/spitball_medium.mdl")
				p:SetOwner(self.Owner)
				p:SetColor(self.ProjColor)
				p:SetPhysicsAttacker(self.Owner)
				p.InkColor = self.InkColor
				p.Dmg = 0
				p.InkRadius = self.InkRadius
				p.SplashNum = self.SplashNum
				p.SplashLen = self.SplashLen
				p:DrawShadow(false)
				p:SetNoDraw(true)
				p:Spawn()
				
				local ph = p:GetPhysicsObject()
				if not ph or not IsValid(ph) then
					p:Remove()
					return
				end
				
				ph:ApplyForceCenter(Vector(0, 0, -100))
				--debugoverlay.Line(p:GetPos(), p:GetPos() + Vector(0, 0, -1000), 7, Color(0, 255, 255, 255), true)
			else
				local t = util.TraceLine({
					start = self:GetPos(),
					endpos = self:GetPos() + d * self.Radius,
					filter = self
				})
				--debugoverlay.Line(self:GetPos(), self:GetPos() + d * self.Radius, 7, Color(0, 255, 0, 255), true)
				
				createink(self, t)
			end
			
			d:Rotate(Angle(0, 360 / loops, 0))
		end
		d:Rotate(Angle(180 / loopssphere, 0, 0))
	end
	
	self.Blaster = IsValid(ent)
	if not self.Blaster then
		self:EmitSound(HitSound, 100)
	else
		ent:TakeDamage(self.Dmg, self.Owner or self, self)
	end
	util.BlastDamage(self.Owner or self, self.Owner or self, self:GetPos(), self.Radius, self.Dmg)
	SafeRemoveEntityDelayed(self, 0)
end

function ENT:PhysicsUpdate()
	if self:WaterLevel() > 1 then
		self:Remove()
		return
	end
end

function ENT:PhysicsCollide(data)
	if data.HitEntity == self.Owner then return end
	
	local Owner, dmg = self.Owner, self.Dmg
	if not IsValid(Owner) then self:Remove() return end
	self.Radius = 60
	self:GetPhysicsObject():SetPos(self:GetPos() - data.HitNormal * self.Radius / 3)
	if data.HitEntity.GetActiveWeapon and (data.HitEntity.InkColor ~= self.InkColor or data.HitEntity:GetActiveWeapon().InkColor ~= self.InkColor) then
		self.Owner:EmitSound(DirectHitSound)
	else
		self:EmitSound(WallHitSound)
	end
	
	if data.HitEntity:IsWorld() then
		dmg = 35
	end
	--print(data.HitNormal:Angle())
	timer.Destroy(self.DropInitname)
	timer.Destroy(self.Dropname)
	
	local e = EffectData()
	e:SetAngles(self:GetAngles())
	e:SetEntity(self)
	e:SetFlags(0)
	e:SetOrigin(data.HitPos)
	e:SetRadius(self.Radius)
	e:SetScale(10)
	e:SetStart(data.HitPos)
	util.Effect("cball_explode", e)
	
	timer.Simple(0, function() self:Explode(data.HitEntity) end)
end

