--[[
	Ink Mine is a Splashooter's sub weapon.
]]

ENT.Type = "anim"
ENT.Base = "splashootee"
 
ENT.PrintName		= "Ink Mine"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "splat ink"
ENT.Instructions	= "none"

local ThrowSound = Sound("SplatoonSWEPs/sub/SubWeapon_Put.mp3")
local HitSound = Sound("SplatoonSWEPs/sub/BombExplosion01.mp3")

if SERVER then
	AddCSLuaFile("shared.lua")

elseif CLIENT then
	ENT.AutomaticFrameAdvance = true
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
			}, r or 8)
		else
			util.Decal("Ink" .. self.InkColor, t.HitPos + t.HitNormal * 10, t.HitPos - t.HitNormal * 10)
		end
	end
end

local function explode(self, data)
	if CLIENT then return end
	
	local e = EffectData()
	e:SetAngles(self:GetAngles())
	e:SetEntity(self)
	e:SetFlags(0)
	e:SetNormal(self.Normal)
	e:SetOrigin(self:GetPos())
	e:SetRadius(self.Radius)
	e:SetScale(10)
	e:SetStart(self:GetPos())
	util.Effect("HelicopterMegaBomb", e)
				
	local Owner = self.Owner
	local a = data.HitNormal:Angle()
	if not IsValid(Owner) then Owner = self end
	util.BlastDamage(Owner, Owner, data.HitPos, self.Radius * 2, self.Dmg)
	self:EmitSound(HitSound)
	
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
			
			createink(self, t)
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

function ENT:Initialize()
	
	self.BaseClass.Initialize(self)
	self:EmitSound(ThrowSound)
	
	self.Radius = 180
	self.Dmg = 220
	
	timer.Simple(10, function()
		if IsValid(self) then
			explode(self, {HitPos = self:GetPos(), HitNormal = -self.Normal})
		end
	end)
	
	--self:SetNoDraw(false)
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	for k,v in pairs(ents.FindInSphere(self:GetPos(), 20)) do
		if v:GetClass() ~= "npc_bullseye" and v ~= self and v ~= self.Owner then
			if v:GetClass() == "splashootee" or v:Health() > 0 then
				if v.InkColor ~= self.InkColor or (v.GetActiveWeapon and v:GetActiveWeapon().InkColor ~= self.InkColor) then
					timer.Simple(0.5, function()
						if not IsValid(self) then return end
						explode(self, {HitPos = self:GetPos(), HitNormal = -self.Normal})
						self:NextThink(CurTime() + 1)
					end)
					return
				end
			end
		end
	end
end

function ENT:Touch(t)
	if self.BaseClass.Touch(self, t) then
		explode(self, {HitPos = self:GetPos(), HitNormal = -self.Normal})
	end
end

function ENT:StartTouch(t)
	if self.BaseClass.StartTouch(self, t) then
		explode(self, {HitPos = self:GetPos(), HitNormal = -self.Normal})
	end
end
