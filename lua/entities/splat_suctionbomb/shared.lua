--[[
	Suction Bomb is a Splashooter's sub weapon.
	This splats ink after a while.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Suctionbomb"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and paint!"
ENT.Instructions	= "none"

ENT.Color = Color(0, 0, 0, 255)
ENT.SuckPos = Vector(0, 0, 0)
ENT.SuckNormal = Vector(0, 0, 0)

ENT.brightness = 0.5
ENT.bursttime = ""

local Waterfall = Sound("SplatoonSWEPs/sub/CommonWaterFallLight00.wav")
local AlertSound = Sound("SplatoonSWEPs/sub/BombAlert01.mp3")
local BurstSound = Sound("SplatoonSWEPs/sub/BombExplosion01.mp3")
local SuckSound = Sound("SplatoonSWEPs/sub/BombSucker00.mp3")
local ThrowSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingFly.mp3")
ENT.throw = ""

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
	self:SetModel("models/props_splatoon/weapons/subs/suction_bomb/suction_bomb.mdl")
	--self:SetMaterial("models/props_building_details/courtyard_template001c_bars")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self.Radius = 180
	self.Dmg = 220
	
	self:GetPhysicsObject():SetMass(15)
	--self:AddEffects(EF_BRIGHTLIGHT)
	self.throw = CreateSound(self, ThrowSound)
	self.throw:Play()
	
	self.bursttime = "burst" .. self:EntIndex()
end

function ENT:OnRemove()
	timer.Destroy(self.bursttime)
	timer.Destroy("blink" .. self:EntIndex())
end

local function createink(self, t, r)
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
			util.Decal("Ink" .. self.InkColor, t.HitPos + t.HitNormal * 10, t.HitPos - t.HitNormal * 10)
		end
	end
end

function ENT:explode(data)
	if CLIENT then return end
	local Owner = self.Owner
	local a = data.HitNormal:Angle()
	if not IsValid(Owner) then Owner = self end
	util.BlastDamage(Owner, Owner, data.HitPos, self.Radius * 2, self.Dmg)
	self:EmitSound(BurstSound)
	
	local e = EffectData()
	e:SetAngles(self:GetAngles())
	e:SetEntity(self)
	e:SetFlags(0)
	e:SetNormal(self:GetUp())
	e:SetOrigin(self:GetPos())
	e:SetRadius(self.Radius)
	e:SetScale(10)
	e:SetStart(self:GetPos())
	util.Effect("HelicopterMegaBomb", e)
	
  	local d, r = Vector(1, 0, 0), self.Radius
  	local loops = 20
	local ang = data.HitNormal:Angle()
	ang.pitch = ang.pitch - 90
  	for _ = 1, 4 do
		for i = 1, loops do
			d:Rotate(Angle(0, 360 / loops, 0))
			local delta = d * r
			delta:Rotate(ang)
			local t = util.TraceLine({
				start = data.HitPos - data.HitNormal * self.Radius,
				endpos = data.HitPos + delta + data.HitNormal * self.Radius / 10,
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
		--		10,Color(0,255,0,255),true)
		--	debugoverlay.Line(
		--		data.HitPos - data.HitNormal * self.Radius,
		--		data.HitPos + delta * 2 + data.HitNormal * self.Radius,
		--		10,Color(0,255,255,255),true)
			
			createink(self, t, 10)
		end
		if _ == 1 then
			r = r * 0.75
			loops = 16
		elseif _ == 2 then
			r = r * 0.65
			loops = 12
		else
			r = r * 0.5
			loops = 8
		end
	end
	
	local splatforce = Vector(0, 0, self.Radius / 2)
	splatforce:Rotate(ang)
	for _ = 1, 16 do
		local splat = ents.Create("splashootee")
		splat:SetModel("models/spitball_small.mdl")
		splat:SetPos(data.HitPos - data.HitNormal * 10)
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
			splat:Remove()
			return
		end
		
		local a = Vector(self.Radius * 4, 0, 0)
		a:Rotate(Angle(0, math.random() * 360, 0))
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
	self:Remove()
end

function ENT:Think()
	if SERVER and self:WaterLevel() > 1 then
		self:EmitSound(Waterfall)
		self.throw:FadeOut(0.25)
		self:Remove()
		return
	end
	
	if self:GetNWBool("suck", false) then
		if CLIENT then
			self:SetNextClientThink(CurTime() + 0.05)
			
			if self:GetVelocity():LengthSqr() < 1000 then
				local light = DynamicLight(self:EntIndex())
				light.pos = self:GetPos()
				self.brightness = self.brightness + 0.1
				light.brightness = self.brightness
				light.decay = 300
				light.dietime = CurTime() + 1
				light.r, light.g, light.b = 255, 255, 255
				light.size = 256
			end
		else
			if not timer.Exists(self.bursttime) then
				if self:GetVelocity():LengthSqr() < 1000000 and not self.touchflag then
					self.touchflag = true
					timer.Simple(1, function()
						if not IsValid(self) then return end
						self:EmitSound(AlertSound)
					end)
				end
				
				timer.Create(self.bursttime, 2, 1, function()
					if not IsValid(self) then return end
					
					self:explode({
						HitPos = self.SuckPos,
						HitNormal = self.SuckNormal
					})
				end)
			else
				timer.UnPause(self.bursttime)
				local left = timer.TimeLeft(self.bursttime)
				if left > 0 and left < 0.6 and not timer.Exists("blink" .. self:EntIndex()) then
					timer.Create("blink" .. self:EntIndex(), 0.07, 0, function()
						if not IsValid(self) then return end
						self:SetSkin(math.abs(1 - self:GetSkin()))
						self:ManipulateBoneScale(1, self:GetManipulateBoneScale(1) + Vector(0.02, 0.02, 0.02))
					end)
				end
			end
		end
	else
		if self.touchflag and timer.Exists(self.bursttime) then
			timer.Pause(self.bursttime)
		end
	end
end

function ENT:PhysicsUpdate()
	local p = self:GetPhysicsObject()
	if SERVER and not (p and IsValid(p)) then
		self:Remove()
		return
	end
	
	local v = p:GetVelocity()
	local a = p:GetVelocity():Angle()
	a.p = a.p - 90
	if v.x == 0 and v.y == 0 then
		a = Angle(0, 0, 0)
	end
	
	p:SetAngles(a)
	p:SetVelocityInstantaneous(v)
end

function ENT:PhysicsCollide(t, p)
	if t.HitEntity:IsWorld() then
		if util.TraceLine({
		start = t.HitPos - t.HitNormal, 
		endpos = t.HitPos - t.HitNormal * 2, 
		filter = {self, self.Owner}
		}).HitWorld then
			t.HitNormal = -t.HitNormal
		end
		
		self.throw:FadeOut(0.25)
		self:EmitSound(SuckSound)
		self:SetNWBool("suck", true)
		
		local a = t.HitNormal:Angle()
		a.p = a.p - 90
		timer.Simple(0, function() self:SetPos(t.HitPos) end)
		self:SetAngles(a)
		self:GetPhysicsObject():SetVelocityInstantaneous(Vector(0, 0, 0))
		self:PhysicsInit( SOLID_NONE )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		
		self.SuckPos = t.HitPos
		self.SuckNormal = t.HitNormal
		self.SuckWorld = t.HitEntity:IsWorld()
	end
end
