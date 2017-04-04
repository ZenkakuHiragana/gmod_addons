--[[
	Splash Wall is a Splashooter's sub weapon.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Splash Wall"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "Throw and paint!"
ENT.Instructions	= "none"

ENT.Color = Color(0, 0, 0, 255)
ENT.Hit = false
ENT.HitYaw = 0
ENT.HitPos = Vector(0, 0, 0)

ENT.brightness = 0.5

local HitSound = Sound("SplatoonSWEPs/sub/SubWeapon_Put.mp3")
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
	self:SetModel("models/props_splatoon/weapons/subs/splash_wall/splash_wall.mdl")
	--self:SetMaterial("models/props_combine/pipes03")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	if SERVER then
		self:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE)
	end
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.Radius = 180
	self.Dmg = 220
	
	self:GetPhysicsObject():SetMass(35)
	--self:AddEffects(EF_BRIGHTLIGHT)
	self.HitYaw = self:GetAngles().yaw
	
	self.throw = CreateSound(self, ThrowSound)
	self.throw:Play()
end

function ENT:OnRemove()
	timer.Destroy("inkwall" .. self:EntIndex())
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
			p.Dmg = 50
			p.InkRadius = self.InkRadius
			p.SplashNum = self.SplashNum
			p.SplashLen = self.SplashLen
			p:SetNoDraw(true)
			p:Spawn()
			p.size = 2
			p:BecomeTrigger({
				HitPos = t.HitPos,
				HitNormal = -t.HitNormal
			})
		else
			util.Decal("Ink" .. self.InkColor, t.HitPos + t.HitNormal * 10, t.HitPos - t.HitNormal * 10)
		end
	end
end

function ENT:PhysicsUpdate()	
	self:SetLocalAngularVelocity(Angle(0, self:GetLocalAngularVelocity().yaw, 0))

	local p = self:GetPhysicsObject()
	if not (p and IsValid(p)) then
		self:Remove()
		return
	end
	
	if self:GetMoveType() == MOVETYPE_NONE then		
		if not timer.Exists("inkwall" .. self:EntIndex()) then
			timer.Create("inkwall" .. self:EntIndex(), 0.15, 0, function()
				if not IsValid(self) or not IsValid(self.Owner) then return end
				for i = -3, 3 do
					local s = self:GetPos() + self:GetRight() * i * -20 + self:GetUp() * 115 - self:GetForward()
					local t = util.QuickTrace(s, -self:GetUp() * 120, {self, self.Owner})
					
					local p = ents.Create("splashootee")
					p:SetModel("models/spitball_small.mdl")
					p:SetOwner(self.Owner)
					p:SetColor(self.ProjColor)
					p:SetAngles(self:GetAngles())
					p:SetPos(s)
					p:SetPhysicsAttacker(self.Owner)
					p.InkColor = self.InkColor
					p.Dmg = 50
					p.InkRadius = self.InkRadius
					p.SplashNum = self.SplashNum
					p.SplashLen = self.SplashLen
					p:SetNoDraw(true)
					p:Spawn()
					p.size = 2
					p:GetPhysicsObject():ApplyForceCenter(Vector(0, 0, -500))
				end
			end)
		end
	end
end

function ENT:RenderOverride()
	self:DrawModel()
	if self:GetNWBool("Hit", false) then
		for i = -20, 20 do
			if i ~= 0 then
				local c = Color(self:GetC().x * 255, self:GetC().y * 255, self:GetC().z * 255, 255)
				local s = self:GetPos() + self:GetRight() * i * -3.5
				local t = util.QuickTrace(s, self:GetUp() * 115, {self.Owner})
				render.DrawLine(t.HitPos, s, c, true)
			end
		end
	end
end

function ENT:StartTouch(t)
	if not IsValid(t) then return end
	
	if (t.ProjColor ~= nil and t.ProjColor ~= self.ProjColor) or
		(t.InkColor ~= nil and t.InkColor ~= self.InkColor) then
		if t:GetClass() == "splat_burstbomb" then
			t:PhysicsCollide({
				HitPos = self:GetPos(),
				HitNormal = self:GetPos() - t:GetPos()
			}, self:GetPhysicsObject())
		elseif t:GetClass() == "splat_splatbomb" then
			t:explode({
				HitPos = self:GetPos() + Vector(0, 0, 0.1),
				HitNormal = -self:GetUp()
			})
		elseif t:GetClass() == "splat_suctionbomb" then
			t:explode({
				HitPos = self:GetPos() + Vector(0, 0, -50),
				HitNormal = -self:GetUp()
			})
		elseif t:GetClass() == "splat_seeker" then
			t:PhysicsCollide({
				HitPos = self:GetPos(),
				HitNormal = t:GetUp()
			}, self:GetPhysicsObject())
		else
			t:Remove()
		end
		
		self.Timer = self.Timer - ((t.Dmg or 0) / 300 * 6)
	else
		if (t.GetActiveWeapon and t:GetActiveWeapon().InkColor ~= self.InkColor) or
			not t.GetActiveWeapon then
			
			t:SetVelocity(-t:GetVelocity() * 20)
			t:TakeDamage(50, self, self:GetOwner() or self)
		end
	end
end

function ENT:Think()
	if CLIENT then return end
	
	local t = util.TraceLine({
		start = self:GetPos() + Vector(0, 0, 120),
		endpos = self:GetPos() + Vector(0, 0, -10),
		filter = {self, self.Owner}
	})
--	debugoverlay.Line(self:GetPos(),self:GetPos() + Vector(0, 0, -10),0.1, Color(0, 255, 0, 255), true)
	if t.HitWorld then
		if not self.Hit then
			self.Timer = CurTime()
			self:EmitSound(HitSound)
			self.throw:Stop()
		end
		
		self:SetVelocity(Vector(0, 0, 0))
		self:SetGravity(0)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetAngles(Angle(0, self:GetAngles().yaw, 0))
		
		self.HitPos = self:GetPos()
		self.Hit = true
		self:SetNWBool("Hit", true)
		self:SetTrigger(true)
		self:UseTriggerBounds(true)
		
		--SafeRemoveEntityDelayed(self, 8)
	end
	
	self:ManipulateBoneScale(self:LookupBone("ink_1"), Vector(1, math.Clamp(6 - CurTime() + (self.Timer or CurTime()), 0, 6) / 6, 1))
	if self.Timer and CurTime() - self.Timer > 6 then
		SafeRemoveEntityDelayed(self, 0.5)
	end
end