--[[
	This is the balloon for target practice in Splatoon.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Balloon"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Target Practice"
ENT.Instructions	= "none"
ENT.Spawnable = true
ENT.GetActiveWeapon = function() return {InkColor = "Balloon"} end
ENT.markable = true

ENT.Color = Color(0, 0, 0, 255)
ENT.height = 100

local HitSound = Sound("Breakable.Flesh")

if SERVER then
	AddCSLuaFile("shared.lua")

elseif CLIENT then
	ENT.AutomaticFrameAdvance = true
end

function ENT:eff(n)
	local e = EffectData()
	e:SetAngles(self:GetAngles())
	e:SetEntity(self)
	e:SetFlags(0)
	e:SetNormal(self:GetUp())
	e:SetOrigin(self:GetPos())
	e:SetRadius(0.1)
	e:SetScale(10)
	e:SetStart(self:GetPos())
	util.Effect(n, e)
end

if CLIENT then	
	function ENT:Draw()
		if self:GetNWBool("break", false) then
			for i = 2, 7 do
				self.balloon:ManipulateBoneScale(i, Vector(0, 0, 0))
				self.balloon:ManipulateBonePosition(i, Vector(0, -0.15 * self:GetMaxHealth(), 0))
			end
		else
			for i = 2, 7 do
				self.balloon:ManipulateBoneScale(i, Vector(1, 1, 1))
				self.balloon:ManipulateBonePosition(i, Vector(0, 0, 0))
			end
		end
		self.balloon.ProjColor = self:GetNWVector("c", Vector(0, 0, 0))
		self.balloon.ProxyentPaintColor = self.balloon
		self.balloon.ProxyentPaintColor.GetPaintVector = function()
			if not IsValid(self.balloon) then return Vector(0, 0, 0) end
			return Vector(self.balloon.ProjColor.r / 255, 
							self.balloon.ProjColor.g / 255, 
							self.balloon.ProjColor.b / 255)
		end
		
		self.balloon:SetSkin(self:GetSkin())
		self.balloon:SetPos(self:GetPos() + (self.delta or vector_origin) - self:GetUp() * 9.5)
		self.balloon:SetAngles(self:GetAngles())
		self.balloon:DrawModel()
		
		local p = (self:GetPos() - Vector(0, 0, self.height)):ToScreen()
		local c = 255
		if self:GetMaxHealth() - self:Health() >= 100 then c = 0 end
		local a = LocalPlayer():GetAimVector():Angle()
		a.pitch = 0
		a.yaw = a.yaw - 90
		a.roll = a.roll + 90
		local s = string.format("%4.1f", self:GetMaxHealth() - self:Health())
		local dy = -15
		if self:GetMaxHealth() - self:Health() >= 10 then dy = -22 end
		if self:GetMaxHealth() - self:Health() >= 100 then dy = -35 end
		
		cam.Start3D2D( (self:GetPos() + Vector(0, 0, self.height)), a, 1 )
			surface.SetFont("CloseCaption_Bold")
			surface.SetTextColor(255, c, 255, 255)
			surface.SetTextPos(dy, 2)
			surface.DrawText(s)
	    cam.End3D2D()
	end

	function ENT:OnRemove()
		self.balloon:Remove()
	end
end

function ENT:Initialize()
	self:SetModel("models/props_c17/canister_propane01a.mdl")
--	self:SetModel("models/props_splatoon/props/general/training_targets/training_target_small.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	--self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetHealth(100)
	if SERVER then
		self:SetMaxHealth(100)
		constraint.Weld(self, game.GetWorld(), 0, 0, 0, false, false)
	end
	if CLIENT then self.balloon = 
		ClientsideModel("models/props_splatoon/props/general/training_targets/training_target_small.mdl")
	end
end

local function restore(self)
	if IsValid(self) then
		self:SetNWBool("break", false)
		self:SetHealth(self:GetMaxHealth())
		self:SetSkin(0)
		self:RemoveAllDecals()
	end
end

function ENT:OnTakeDamage(d)
	if self:GetNWBool("break", false) then return end
	local rest = self:Health() - d:GetDamage()
	self:SetHealth(rest)
	if d:GetAttacker().GetActiveWeapon and 
		d:GetAttacker():GetActiveWeapon().ProjColor then 
		local c = d:GetAttacker():GetActiveWeapon().ProjColor
		self:SetNWVector("c", Vector(c.r, c.g, c.b))
	end
	
	if rest > 0 then
		self:SetSkin((self:GetMaxHealth() - rest) / (0.167 * self:GetMaxHealth()))
	else
		self:eff("balloon_pop")
		
		self:SetNWBool("break", true)
		self:SetSolid(SOLID_NONE)
	end
	
	if timer.Exists("restore" .. self:EntIndex()) then
		timer.Adjust("restore" .. self:EntIndex(), 3.4, 1, function()
			if IsValid(self) then
				restore(self)
				self:SetSolid(SOLID_VPHYSICS)
				self:eff("entity_remove")
			end
		end)
	else
		timer.Create("restore" .. self:EntIndex(), 3.4, 1, function()
			if IsValid(self) then
				restore(self)
				self:SetSolid(SOLID_VPHYSICS)
				self:eff("entity_remove")
			end
		end)
	end
end

--root_1
--leg_1
--burst_1
--body_1
--ear_0_1_L
--ear_1_1_L
--ear_0_1_R
--ear_1_1_R

