--[[
	Squid Beakon is a Splashooter's sub weapon.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Squid Beakon"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and Mark!"
ENT.Instructions	= "none"

local Waterfall = Sound("SplatoonSWEPs/sub/CommonWaterFallLight00.wav")
local HitSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingBomb.mp3")
local ThrowSound = Sound("SplatoonSWEPs/sub/SubWeapon_Put.mp3")
local MarkSound = Sound("SplatoonSWEPs/MarkingStart.mp3")
local MarkOn = Sound("SplatoonSWEPs/AllMarkingOnDamage.mp3")
local MarkOff = Sound("SplatoonSWEPs/AllMarkingOffDamage.mp3")
ENT.burstsound = ""

ENT.thrown = false
ENT.SpawnTime = 0

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
	self:SetModel("models/props_splatoon/weapons/subs/squid_beakon/squid_beakon.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self.Radius = 160
	self.Dmg = 60
	self:GetPhysicsObject():SetMass(500)
	self:SetHealth(80)
	if SERVER then 
		self:SetMaxHealth(80)
	end
	self.burstsound = CreateSound(self, ThrowSound)
	
	self.SpawnTime = CurTime() * 60
end

function ENT:OnTakeDamage(d)
	local c = self:Health() - d:GetDamage()
	if c > 0 then
		self:SetHealth(c)
	else
		self:SetHealth(0)
		local e = EffectData()
		e:SetAngles(self:GetAngles())
		e:SetEntity(self)
		e:SetFlags(0)
		e:SetNormal(self:GetUp())
		e:SetOrigin(self:GetPos())
		e:SetRadius(self.Radius)
		e:SetScale(10)
		e:SetStart(self:GetPos())
		util.Effect("ManhackSparks", e)
		self:Remove()
	end
end

function ENT:Think()
	if self:WaterLevel() > 1 then
		self.burstsound:FadeOut(0.5)
		self:EmitSound(Waterfall)
		self:Remove()
		return
	end
	
	if not IsValid(self) then
		local e = EffectData()
		e:SetAngles(self:GetAngles())
		e:SetEntity(self)
		e:SetFlags(0)
		e:SetNormal(self:GetUp())
		e:SetOrigin(self:GetPos())
		e:SetRadius(self.Radius)
		e:SetScale(10)
		e:SetStart(self:GetPos())
		util.Effect("AirboatGunImpact", e)
		self:EmitSound(Break)
		self:Remove()
	end
	
	if not self.thrown then
		self.thrown = true
		self.burstsound:Play()
	end
	
	if CLIENT then
		self:ManipulateBoneAngles(self:LookupBone("neck_1"),
			Angle((CurTime() + self.SpawnTime) * 60, 0, 0))
	end
end
