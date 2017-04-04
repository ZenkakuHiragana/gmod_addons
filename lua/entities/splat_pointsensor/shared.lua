--[[
	Point Sensor is a Splashooter's sub weapon.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Point Sensor"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and Mark!"
ENT.Instructions	= "none"

local Waterfall = Sound("SplatoonSWEPs/sub/CommonWaterFallLight00.wav")
local HitSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingBomb.mp3")
local ThrowSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingFly.mp3")
local MarkSound = Sound("SplatoonSWEPs/MarkingStart.mp3")
local MarkOn = Sound("SplatoonSWEPs/AllMarkingOnDamage.mp3")
local MarkOff = Sound("SplatoonSWEPs/AllMarkingOffDamage.mp3")
ENT.burstsound = ""

ENT.thrown = false
ENT.Duration = 8

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
	self:SetModel("models/props_splatoon/weapons/subs/point_sensor/point_sensor.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.Radius = 160
	self.Dmg = 60
	self:GetPhysicsObject():SetMass(24)
	self.burstsound = CreateSound(self, ThrowSound)
	
	if CLIENT then
		self:SetNWInt("halonum", 0)
		
		hook.Add("PreDrawHalos", self, function()
			if IsValid(self) then
				local c = Color(self:GetNWInt("r", 255), self:GetNWInt("g", 255), self:GetNWInt("b", 255), 255)
				for i = 1, self:GetNWInt("halonum", 0) do
					local e = self:GetNWEntity("halo" .. i, nil)
					if IsValid(e) and (c == LocalPlayer():GetActiveWeapon().ProjColor or e == LocalPlayer()) then
						halo.Add({e}, c, 2, 2, 1, true, true)
					end
					hook.Add("PostDrawTranslucentRenderables", e, function(depth, skybox)
						if IsValid(self) and c == LocalPlayer():GetActiveWeapon().ProjColor then
							local p = e:WorldSpaceCenter()
							if e ~= LocalPlayer() then
								render.DrawLine(p, LocalPlayer():GetPos(), c)
							end
						end
					end)
				end
			end
		end)
		
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
	
	self:SetLocalAngularVelocity(Angle(0, 0, 0))
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
	
	local i = 0
	for k,v in pairs(ents.FindInSphere(data.HitPos, self.Radius * 2)) do
		if v.markable or v.Type == "nextbot" or v:IsNPC() or v:IsPlayer() then
			if (not v.GetActiveWeapon) or v:GetActiveWeapon().ProjColor ~= self.ProjColor then
				i = i + 1
				self:SetNWEntity("halo" .. i, v)
				v:EmitSound(MarkOn)
			end
		end
	end
	self:SetNWInt("halonum", i)
	self:SetNWInt("r", self.ProjColor.r)
	self:SetNWInt("g", self.ProjColor.g)
	self:SetNWInt("b", self.ProjColor.b)
	
	if i > 0 then
		timer.Simple(0, function() self:SetMoveType(MOVETYPE_NONE) end)
		self:SetNoDraw(true)
		self.Owner:EmitSound(MarkSound)
		timer.Simple(self.Duration, function()
			if IsValid(self) then
				for k = 1, self:GetNWInt("halonum", 0) do
					local e = self:GetNWEntity("halo" .. i, nil)
					if IsValid(e) then
						e:EmitSound(MarkOff)
					end
				end
				SafeRemoveEntityDelayed(self, 0)
			end
		end)
	else
		SafeRemoveEntityDelayed(self, 0)
	end
	
end
