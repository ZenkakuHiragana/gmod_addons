--[[
	Seeker is a Splashooter's sub weapon.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Seeker"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and paint!"
ENT.Instructions	= "none"

ENT.Color = Color(0, 0, 0, 255)
ENT.touchflag = false

ENT.target = nil
ENT.touchheight = -25

local ThrowSound = Sound("SplatoonSWEPs/sub/seeker/Seeker_start.mp3")
local EndSound = Sound("SplatoonSWEPs/sub/seeker/Seeker_demolish.wav")
local RunSound = Sound("SplatoonSWEPs/sub/seeker/Seeker_run.wav")
local HitSound = Sound("SplatoonSWEPs/sub/BombExplosion01.mp3")
--ENT.run, ENT.ends

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
			util.Decal("Ink" .. self.InkColor, t.HitPos + t.HitNormal * 10, t.HitPos - t.HitNormal * 10)
		end
	end
end

local function explode(self, data)
	if CLIENT then return end
	local Owner = self.Owner
	local a = data.HitNormal:Angle()
	if not IsValid(Owner) then Owner = self end
	util.BlastDamage(Owner, Owner, data.HitPos, self.Radius * 2, self.Dmg)
	self:EmitSound(HitSound)
	self.run:Stop()
	self.ends:Stop()
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
			
			createink(self, t)
		end
		if _ == 1 then
			r = r * 0.4
			loops = 5
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

function ENT:Initialize()
	self:SetModel("models/props_splatoon/weapons/subs/seekers/seeker.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self.Radius = 70
	self.Dmg = 180
	
	if SERVER then
		local d = self.Dir:Length()
		self.Dir.z = 0
		self.Dir = self.Dir:GetNormalized() * d
		self:GetPhysicsObject():SetMass(1000)
		self:GetPhysicsObject():SetMaterial("gmod_ice")
	end
	
	self:ManipulateBoneAngles(self:LookupBone("body_1"), Angle(0, 0, -80))
	self:ManipulateBonePosition(self:LookupBone("body_1"), Vector(0, 0, 10))
	
	self:EmitSound(ThrowSound)
	self.run = CreateSound(self, RunSound)
	self.ends = CreateSound(self, EndSound)
	self.run:PlayEx(1, 100)
	timer.Simple(4, function()
		if IsValid(self) then
			self.ends:Play()
		end
	end)
	timer.Simple(5, function()
		if IsValid(self) then
			explode(self, {HitPos = self:GetPos(), HitNormal = self:GetForward()})
		end
	end)
end

function ENT:PhysicsUpdate()
	if CLIENT then return end
	
	local p = self:GetPhysicsObject()
	if not (p and IsValid(p)) then
		SafeRemoveEntityDelayed(self, 0)
		self.run:Stop()
		self.ends:Stop()
		return
	end
	
	if self:WaterLevel() > 1 then
		SafeRemoveEntityDelayed(self, 0)
		self.run:Stop()
		self.ends:Stop()
		return
	end
	
	local d, t = 15
	local tb = {
		start = p:GetPos() - self:GetRight() * d,
		endpos = p:GetPos() + Vector(0, 0, -40) - self:GetRight() * d,
		filter = {self, self.Owners}
	}
	for _ = 1, 2 do
		t = util.TraceLine(tb)
		if t.Hit and t.HitWorld then
			createink(self, t)
		end
		tb.start = p:GetPos() + self:GetRight() * d
		tb.endpos = p:GetPos() + Vector(0, 0, -40) + self:GetRight() * d
	end
	
	local sin = math.sin(CurTime() * 20) * 20
	self:ManipulateBoneAngles(self:LookupBone("screw_1"), Angle(CurTime() * 1800, 0, 0))
	self:ManipulateBoneAngles(self:LookupBone("pole_1"), Angle(sin, sin / 5, sin / 5))
	self:ManipulateBoneAngles(self:LookupBone("flag1_1"), Angle(sin, math.sin(CurTime() * 40) * 20, 0))
	self:ManipulateBoneAngles(self:LookupBone("flag2_1"), Angle(sin, math.sin(CurTime() * 40) * -20, 0))
	
	local v = p:GetVelocity()
	local a = p:GetAngles()
	local M = Vector(0, 0, 0)
	a.pitch = math.Clamp(a.pitch, 30, 150)
	a.yaw = v:Angle().yaw
	a.roll = 0
	
	p:SetAngles(a)
	p:SetVelocityInstantaneous(v)
	
	if IsValid(self.target) then
		M = self:GetForward():Cross(self.target:GetPos() - self:GetPos())
		M = -(self:GetRight() * M.z):GetNormalized()
		M.z = 0
	end
	
	p:ApplyForceCenter((self.Dir + 2 * M) * 4500)
	v = p:GetVelocity()
	if Vector(v.x, v.y, 0):LengthSqr() > 202500 then
		p:SetVelocity(Vector(v.x, v.y, 0):GetNormalized() * 450 + Vector(0, 0, v.z))
	end
end

function ENT:PhysicsCollide(d, p)
	if math.abs(d.HitNormal:Dot(Vector(0, 0, -1))) < 0.4 then
		timer.Simple(0, function() explode(self, d) end)
	end
	--for i = 0, self:GetBoneCount()-1 do
	--	print(self:GetBoneName(i))
	--end
end
