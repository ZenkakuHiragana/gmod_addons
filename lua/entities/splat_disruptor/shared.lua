--[[
	Disruptor is a Splashooter's sub weapon.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Disruptor"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and Mark!"
ENT.Instructions	= "none"

local Waterfall = Sound("SplatoonSWEPs/sub/CommonWaterFallLight00.wav")
local HitSound = Sound("SplatoonSWEPs/sub/DisruptorExplosion00.mp3")
local ThrowSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingFly.mp3")
local MarkOn = Sound("SplatoonSWEPs/Devil_OnDamage.mp3")
local MarkOff = Sound("SplatoonSWEPs/Devil_OffDamage.mp3")
ENT.burstsound = ""

ENT.thrown = false
ENT.Duration = 5

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
	self:SetModel("models/props_splatoon/weapons/subs/disruptor/disruptor.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.Radius = 100
	self.Dmg = 60
	self:GetPhysicsObject():SetMass(22)
	self.burstsound = CreateSound(self, ThrowSound)
	
	if CLIENT then
		self:SetNWInt("halonum", 0)
		
		hook.Add("PreDrawHalos", self, function()
			for i = 1, self:GetNWInt("halonum", 0) do
				local e = self:GetNWEntity("halo" .. i, nil)
				if IsValid(e) then
					halo.Add({e}, Color(32, 32, 32, 255), 2, 2, 1, false)
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
	
	local a = self:GetAngles()
	a.yaw = a.yaw + 110
	self:ManipulateBoneAngles(1, a)
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
	e:SetFlags(3)
	e:SetNormal(-data.HitNormal)
	e:SetOrigin(self:GetPos())
	e:SetRadius(self.Radius)
	e:SetScale(1)
	e:SetStart(self:GetPos())
	util.Effect("HunterDamage", e)
	
	local e = EffectData()
	e:SetAngles(self:GetAngles())
	e:SetEntity(self)
	e:SetFlags(3)
	e:SetNormal(-data.HitNormal)
	e:SetOrigin(self:GetPos())
	e:SetScale(1.8)
	e:SetStart(self:GetPos())
	util.Effect("StriderBlood", e)
	
	local i = 0
	for k,v in pairs(ents.FindInSphere(data.HitPos, self.Radius * 2)) do
		if v.markable or v.Type == "nextbot" or v:IsNPC() or v:IsPlayer() then
			if (not v.GetActiveWeapon) or v:GetActiveWeapon().ProjColor ~= self.ProjColor then
				i = i + 1
				self:SetNWEntity("halo" .. i, v)
				v:EmitSound(MarkOn)
				if v.GetActiveWeapon then
					v:GetActiveWeapon().poison = true
				end
			end
		end
	end
	self:SetNWInt("halonum", i)
	
	if i > 0 then
		self:SetNoDraw(true)
		self:SetMoveType(MOVETYPE_NONE)
		timer.Simple(self.Duration, function()
			if IsValid(self) then
				for k = 1, self:GetNWInt("halonum", 0) do
					local e = self:GetNWEntity("halo" .. i, nil)
					if IsValid(e) then
						e:EmitSound(MarkOff)
						if e.GetActiveWeapon then
							e:GetActiveWeapon().poison = false
						end
					end
				end
				SafeRemoveEntityDelayed(self, 0)
			end
		end)
	else
		SafeRemoveEntityDelayed(self, 0)
	end
	
end
