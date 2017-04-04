--[[
	Burst Bomb is a Splashooter's sub weapon.
	This splats ink by hitting a wall.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Quickbomb"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and paint!"
ENT.Instructions	= "none"

local Waterfall = Sound("SplatoonSWEPs/sub/CommonWaterFallLight00.wav")
local HitSound = Sound("SplatoonSWEPs/sub/BombExplosion00.mp3")
local ThrowSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingFly.mp3")
ENT.burstsound = ""

ENT.thrown = false

if SERVER then
	AddCSLuaFile("shared.lua")

elseif CLIENT then
	ENT.AutomaticFrameAdvance = true
end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "C")
end

if CLIENT then
	function ENT:Draw()
		self.ProxyentPaintColor = self
		self.ProxyentPaintColor.GetPaintVector = function()
			return self:GetC()
		end
		self.BaseClass.Draw(self)
	end
end

function ENT:Initialize()
	self:SetModel("models/props_splatoon/weapons/subs/burst_bombs/burst_bomb.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self.Radius = 70
	self.Dmg = 60
	self:GetPhysicsObject():SetMass(15)
	self.burstsound = CreateSound(self, ThrowSound)
end

local function createink(self, t)
	if t.Hit then
		if t.HitWorld then
			local p = ents.Create("splashootee")
			p:SetModel("models/spitball_small.mdl")
		--	p:SetPos(t.HitPos - t.HitNormal * 10)
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
			--if IsValid(t.HitEntity) then
				util.Decal("Ink" .. self.InkColor, t.HitPos + t.HitNormal, t.HitPos - t.HitNormal)
			--end
		end
	end
end

function ENT:PhysicsUpdate()
	if self:WaterLevel() > 1 then
		self.burstsound:FadeOut(0.5)
		self:EmitSound(Waterfall)
		self:Remove()
		return
	end
	
	if not self.thrown then
		self.thrown = true
		self.burstsound:Play()
	end
end

function ENT:PhysicsCollide(data, phys)
	
	if util.TraceLine({
		start = data.HitPos - data.HitNormal, 
		endpos = data.HitPos - data.HitNormal * 2, 
		filter = {self, self.Owner}
	}).HitWorld then
		data.HitNormal = -data.HitNormal
	end
	
	local Owner = self.Owner
	local a = data.HitNormal:Angle()
	if not IsValid(Owner) then Owner = self end
	util.BlastDamage(Owner, Owner, data.HitPos, self.Radius * 2, self.Dmg)
	self.burstsound:Stop()
	self:EmitSound(HitSound)
	
	local e = EffectData()
	e:SetAngles(self:GetAngles())
	e:SetEntity(self)
	e:SetFlags(0)
	e:SetNormal(self:GetUp())
	e:SetOrigin(self:GetPos())
	e:SetRadius(self.Radius)
	e:SetScale(1)
	e:SetStart(self:GetPos())
	util.Effect("HelicopterMegaBomb", e)
	
	timer.Simple(0, function()
	  	local d, r = Vector(1, 0, 0), self.Radius
	  	local loops = 10
		local ang = data.HitNormal:Angle()
		ang.pitch = ang.pitch - 90
	  	for _ = 1, 2 do
			for i = 1, loops do
				d:Rotate(Angle(0, 360 / loops, 0))
				local delta = d * r
				delta:Rotate(ang)
				local t = util.TraceLine({
					start = data.HitPos - data.HitNormal * self.Radius,
					endpos = data.HitPos + delta * 2 + data.HitNormal * self.Radius,
					filter = {self, self.Owner}
				})
				if not t.Hit then
					t = util.TraceLine({
						start = data.HitPos + delta - data.HitNormal * self.Radius,
						endpos = data.HitPos + delta + data.HitNormal * self.Radius,
						filter = {self, self.Owner}
					})
				end
				
			--	debugoverlay.Line(
			--		data.HitPos + delta - data.HitNormal * self.Radius,
			--		data.HitPos + delta + data.HitNormal * self.Radius,
			--		10,Color(0,255,0,255),false)
			--	debugoverlay.Line(
			--		data.HitPos - data.HitNormal * self.Radius,
			--		data.HitPos + delta * 2 + data.HitNormal * self.Radius,
			--		10,Color(0,255,255,255),false)
				
				createink(self, t)
			end
			r = r * 0.4
			loops = 4
		end
		
		local splatforce = Vector(0, 0, self.Radius * 3)
		splatforce:Rotate(ang)
		for _ = 1, 10 do
			local splat = ents.Create("splashootee")
			splat:SetModel("models/spitball_small.mdl")
			splat:SetOwner(self.Owner)
			splat:SetColor(self.ProjColor)
			splat:SetPhysicsAttacker(self.Owner)
			splat.InkColor = self.InkColor
			splat.Dmg = 0
			splat.InkRadius = self.InkRadius
			splat.SplashNum = self.SplashNum
			splat.SplashLen = self.SplashLen
			splat:Spawn()
			
			local ph = splat:GetPhysicsObject()
			if not (ph and IsValid(ph)) then
				SafeRemoveEntityDelayed(splat, 0)
				return
			end
			ph:SetPos(data.HitPos - data.HitNormal * 10)
			
			local a = Vector(self.Radius * 3.3, 0, 0)
			a:Rotate(Angle(0, math.random(0, 359, 0), 0))
			a:Rotate(ang)
			ph:ApplyForceCenter(splatforce + a)
			
			timer.Simple(0.8, function()
				if IsValid(ph) then
					local z = ph:GetVelocity().z
					if z > 0 then z = -z / 5 end
					ph:SetVelocity(Vector(0, 0, z))
				end
			end)
		end
		SafeRemoveEntityDelayed(self, 0)
	end)
end
