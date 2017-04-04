--[[
	Splat Bomb is a Splashooter's sub weapon.
	This splats ink after a while.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Splatbomb"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and paint!"
ENT.Instructions	= "none"

ENT.touchflag = false

ENT.brightness = 0.5
ENT.touchheight = -25

local Waterfall = Sound("SplatoonSWEPs/sub/CommonWaterFallLight00.wav")
local AlertSound = Sound("SplatoonSWEPs/sub/BombAlert01.mp3")
local BurstSound = Sound("SplatoonSWEPs/sub/BombExplosion01.mp3")
local ThrowSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingFly.mp3")
local HitSound = {
	Sound("SplatoonSWEPs/sub/splatbomb/PlasticHit00.wav"),
	Sound("SplatoonSWEPs/sub/splatbomb/PlasticHit01.wav"),
	Sound("SplatoonSWEPs/sub/splatbomb/PlasticHit02.wav"),
	Sound("SplatoonSWEPs/sub/splatbomb/PlasticHit03.wav"),
}
ENT.throw = ""
ENT.bursttime = ""

if SERVER then
	AddCSLuaFile("shared.lua")

elseif CLIENT then
	--ENT.AutomaticFrameAdvance = true
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
	self:SetModel("models/props_splatoon/weapons/subs/splat_bombs/splat_bomb.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self.Radius = 130
	self.Dmg = 180
	
	self:GetPhysicsObject():SetMass(30)
	--self:AddEffects(EF_BRIGHTLIGHT)
	
	---throw = CreateSound(self, ThrowSound)
	--throw:Play()
	self.throw = CreateSound(self, ThrowSound)
	self.throw:Play()
	self.bursttime = "splatburst" .. self:EntIndex()
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
			}, r or 4)
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
  	local loops = 16
	local ang = data.HitNormal:Angle()
	ang.pitch = ang.pitch - 90
  	for _ = 1, 3 do
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
			
			--debugoverlay.Line(
			--	data.HitPos + delta - data.HitNormal * self.Radius,
			--	data.HitPos + delta + data.HitNormal * self.Radius,
			--	10,Color(0,255,0,255),true)
			--debugoverlay.Line(
			--	data.HitPos - data.HitNormal * self.Radius,
			--	data.HitPos + delta * 2 + data.HitNormal * self.Radius,
			--	10,Color(0,255,255,255),true)
			
			createink(self, t, 10)
		end
		if _ == 1 then
			r = r * 0.6
			loops = 10
		else
			r = r * 0.4
			loops = 4
		end
	end
	
	local splatforce = Vector(0, 0, self.Radius)
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
	self:Remove()
end

function ENT:Think()
	if SERVER and self:WaterLevel() > 1 then
		self:EmitSound(Waterfall)
		self.throw:FadeOut(0.25)
		self:Remove()
		return
	end
	
	local t = util.TraceLine({
		start = self:GetPos(),
		endpos = self:GetPos() + Vector(0, 0, self.touchheight),
		filter = self
	})
	if t.Hit then
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
					timer.Simple(0.1, function()
						if not IsValid(self) then return end
						self:EmitSound(AlertSound)
					end)
				end
				
				timer.Create(self.bursttime, 1, 1, function()
					if not IsValid(self) then return end
					
					local boom = util.TraceLine({
						start = self:GetPos(),
						endpos = self:GetPos() + Vector(0, 0, self.touchheight),
						filter = self
					})
					self:explode({
						HitPos = boom.HitPos,
						HitNormal = -boom.HitNormal
					})
				end)
			else
				timer.UnPause(self.bursttime)
				local left = timer.TimeLeft(self.bursttime)
				if left > 0 and left < 0.6 and not timer.Exists("blink" .. self:EntIndex()) then
					timer.Create("blink" .. self:EntIndex(), 0.07, 0, function()
						if not IsValid(self) then return end
						self:SetSkin(math.abs(1 - self:GetSkin()))
						self:ManipulateBoneScale(1, self:GetManipulateBoneScale(1) + Vector(0.15, 0.15, 0.15))
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

function ENT:OnRemove()
	timer.Destroy(self.bursttime)
	timer.Destroy("blink" .. self:EntIndex())
end

function ENT:PhysicsCollide(d, p)
	self:EmitSound(HitSound[math.ceil(math.random() * 4)], SNDLVL_30dB, math.Rand(50, 150), 1, CHAN_BODY)
	self:GetPhysicsObject():ApplyForceCenter(-self:GetPhysicsObject():GetVelocity() * 5)
end
