--[[
	Sprinkler is a Splashooter's sub weapon.
	This splats ink after a while.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Sprinkler"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and paint!"
ENT.Instructions	= "none"

ENT.Color = Color(0, 0, 0, 255)
ENT.SuckPos = Vector(0, 0, 0)
ENT.SuckNormal = Vector(0, 0, 0)

ENT.roll = true

local Break = Sound("SplatoonSWEPs/sub/GearMetal02.wav")
local Loop = Sound("SplatoonSWEPs/sub/SprinklerShotLoop00.mp3")
local Waterfall = Sound("SplatoonSWEPs/sub/CommonWaterFallLight00.wav")
local HitSound = Sound("SplatoonSWEPs/sub/SubWeapon_Put.mp3")
local ThrowSound = Sound("SplatoonSWEPs/sub/BulletBombMarkingFly.mp3")
--ENT.loop = CreateSound(ENT, Loop)
--ENT.throw = CreateSound(ENT, Loop)

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
	self:SetModel("models/props_splatoon/weapons/subs/sprinkler/sprinkler.mdl")
	--self:SetMaterial("models/props_building_details/courtyard_template001c_bars")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.Radius = 350
	self.Dmg = 30
	self:SetHealth(80)
	if SERVER then self:SetMaxHealth(80) end
	
	self:GetPhysicsObject():SetMass(15)
	--self:AddEffects(EF_BRIGHTLIGHT)
	self.throw = CreateSound(self, ThrowSound)
	self.throw:Play()
	self.loop = CreateSound(self, Loop)
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
		self:EmitSound(Break)
		self:Remove()
	end
end

function ENT:OnRemove()
	timer.Destroy("sprinkle" .. self:EntIndex())
	timer.Destroy("emitsound" .. self:EntIndex())
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

function ENT:Think()
	if SERVER and self:WaterLevel() > 1 then
		self:EmitSound(Waterfall)
		self.throw:FadeOut(0.25)
		self:Remove()
		return
	end
	
	if not IsValid(self) or not IsValid(self:GetOwner()) or self:GetOwner():Health() <= 0 then
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
	
	if self:GetMoveType() == MOVETYPE_NONE then
	
		if CurTime() % 0.4 > 0.2 then
			self:ManipulateBoneAngles(self:LookupBone("roll_1"), Angle(CurTime() * -60, 0, 0))
		end
		self:ManipulateBoneAngles(self:LookupBone("hammer_1"), Angle(math.sin(CurTime() * 30) * 12, 0, 0))
		
		if SERVER then
			self.loop:Play()
			
			if not timer.Exists("emitsound" .. self:EntIndex()) then
				timer.Create("emitsound" .. self:EntIndex(), 1.2, 0, function()
					if not IsValid(self) then return end
					self.loop:Stop()
					self.loop:Play()
				end)
			end
			local a = self.SuckNormal:Angle()
			a.p = a.p - 90
			self:SetAngles(a)
			self:SetPos(self.SuckPos)
			
			if not timer.Exists("sprinkle" .. self:EntIndex()) then
				timer.Create("sprinkle" .. self:EntIndex(), 0.2, 0, function()
					local alt = 90
					for _ = 1, 4 do
						if _ > 2 then alt = -90 end
						local a = Vector(self.Radius * 4, 0, 0)
						a:Rotate(Angle(math.random() * -70, self:GetManipulateBoneAngles(self:LookupBone("roll_1")).pitch + alt, 0))
						a:Rotate(self:GetAngles())
						
						local splat = ents.Create("splashootee")
						splat:Setscale(Vector(3, 1, 1))
						splat:SetModel("models/spitball_medium.mdl")
						splat:SetPos(self:GetPos() + self:GetUp() * 20 + a:GetNormalized() * 20)
						splat:SetAngles(a:Angle())
						splat:SetOwner(self.Owner)
						splat:SetColor(self.ProjColor)
						splat:SetPhysicsAttacker(self.Owner)
						splat.InkColor = self.InkColor
						splat.Dmg = 30
						splat.InkRadius = self.InkRadius
						splat.SplashNum = self.SplashNum
						splat.SplashLen = self.SplashLen
						splat:Spawn()
						
						local ph = splat:GetPhysicsObject()
						if not (ph and IsValid(ph)) then
							splat:Remove()
							return
						end
						ph:ApplyForceCenter(self:GetUp() * self.Radius + a)
						
						timer.Simple(0.8, function()
							if IsValid(ph) then
								local z = ph:GetVelocity().z
								if z > 0 then z = -z / 5 end
								ph:SetVelocity(Vector(0, 0, z))
							end
						end)
					end
				end)
			end
		end
	end
end

function ENT:PhysicsCollide(t, p)
	if self.SuckPos == Vector(0, 0, 0) and t.HitEntity:IsWorld() then
		self:EmitSound(HitSound)
		self.throw:Stop()
		
		local a = t.HitNormal:Angle()
		a.p = a.p - 90
		self:SetAngles(a)
		p:SetPos(t.HitPos)
		p:SetVelocityInstantaneous(Vector(0, 0, 0))
		self:PhysicsInit( SOLID_BBOX )
		timer.Simple(0, function() self:SetMoveType( MOVETYPE_NONE ) end)
		
		self.SuckPos = t.HitPos
		self.SuckNormal = t.HitNormal
		self.SuckWorld = t.HitEntity:IsWorld()
		
		local e = EffectData()
		e:SetAngles(self:GetAngles())
		e:SetEntity(self)
		e:SetFlags(0)
		e:SetNormal(t.HitNormal)
		e:SetOrigin(self:GetPos())
		e:SetRadius(self.Radius)
		e:SetScale(10)
		e:SetStart(self:GetPos())
		util.Effect("AirboatGunImpact", e)
		
		timer.Simple(0, function() 
			createink(self, {Hit = true, HitWorld = true, HitPos = t.HitPos, HitNormal = -t.HitNormal})
		end)
		
		for k, v in pairs(ents.FindByClass("splat_sprinkler")) do
			if v ~= self and v.Owner == self.Owner then
				e = EffectData()
				e:SetAngles(v:GetAngles())
				e:SetEntity(v)
				e:SetFlags(0)
				e:SetNormal(-v:GetForward())
				e:SetOrigin(v:GetPos())
				e:SetRadius(v.Radius)
				e:SetScale(10)
				e:SetStart(v:GetPos())
				util.Effect("AirboatGunImpact", e)
				
				SafeRemoveEntityDelayed(v, 0)
			end
		end
	end
end
