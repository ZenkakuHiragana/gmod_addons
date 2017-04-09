--[[
	H-3 Nozzlenose is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/H3nozzlenose00.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's H-3 Nozzlenose beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_splat_base"
SWEP.InkColor = "Blue"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(0,0,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.024
SWEP.RelInk = 1
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 41

SWEP.Forward = 1	--Projectile spawns
SWEP.Right = 10
SWEP.Upward = -9
SWEP.PrimaryVelocity = 62000
SWEP.SplashNum = 3.5		--Projectiles splash count
SWEP.SplashLen = 108		--The length between splashes
SWEP.SplashPattern = 5
SWEP.SplashSpread = 15
SWEP.V0 = 1600
SWEP.InkRadius = 32
SWEP.FallTimer = 260
SWEP.FiringSpeed = 114.795918
SWEP.StopReloading = 30
SWEP.ShootCount = 0

SWEP.L3Delay = 5
SWEP.Primary.ClipSize = 125
SWEP.Primary.DefaultClip = 125
SWEP.Primary.Automatic = false
SWEP.Primary.Recoil = 0.1
SWEP.Primary.Delay = 0.33333333
SWEP.Primary.Spread = 0.0166667
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 2
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.04

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Spread = 0.14
SWEP.Secondary.Ammo = "none"

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "H-3 Nozzlenose"
SWEP.Slot = 2
SWEP.SlotPos = 7
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(50, -40, 0) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 26, -30), angle = Angle(1, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(1, 0, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 26, 30), angle = Angle(0, -8, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 28, -30) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/nozzlenose/nozzlenose.mdl", 
	bone = "ValveBiped.Bip01_Spine4", 
	rel = "", 
	pos = Vector(2.8, -23, -7), 
	angle = Angle(12, 85, 90), 
	size = Vector(0.56, 0.56, 0.56), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 0, 
	bodygroup = {[2] = 1} 
	}
}

SWEP.WElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/nozzlenose/nozzlenose.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(4, 0.6, 0), 
	angle = Angle(0, 1, 180), 
	size = Vector(1, 1, 1), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 0, 
	bodygroup = {[2] = 1} 
	}
}

------------------------------------------------------------------

include("weapons/splatsubweapons/suctionbomb.lua")
AddCSLuaFile("weapons/splatsubweapons/suctionbomb.lua")

function SWEP:Holster()
	timer.Destroy("L3" .. self:EntIndex())
	self.BaseClass.Holster(self)
	return true
end

function SWEP:Think()
	self.BaseClass.Think(self)
	if IsValid(self) and IsValid(self.Owner) then
		if self.Owner:IsPlayer() then
			if self.Owner:GetDuckSpeed() > 100 then
				self.Owner:RemoveFlags(FL_DUCKING)
				self.Owner:SetWalkSpeed(self.FiringSpeed)
				self.Owner:SetRunSpeed(self.FiringSpeed)
			else
				if not self.Owner:Crouching() then
					self.Owner:SetWalkSpeed(230)
					self.Owner:SetRunSpeed(230)
				end
			end
			
			if not self:GetNWBool("throw", false) then
				if self:GetNWBool("fire", false) then
					self:SetWeaponHoldType(self.HoldType)
				else
					self:SetWeaponHoldType("passive")
				end
			end
		end
	end
end

function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Owner) or timer.Exists("L3" .. self:EntIndex()) then return end
	if not self:CanPrimaryAttack() or
		(self.Owner:IsPlayer() and self.Owner:Crouching()) then return end
	
	self:SetNWBool("fire", true)
	
	self:TakePrimaryAmmo(self.Primary.TakeAmmo)
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self:SetNextReloadTime(self.StopReloading)
	
	if self.Owner:IsPlayer() then
		self.Owner:SetDuckSpeed(math.huge)
	end
	
	timer.Simple(self.StopReloading / 60, function()
		if IsValid(self) and IsValid(self.Owner) then
			if self.Owner:IsPlayer() then
				self.Owner:SetDuckSpeed(0.1)
				timer.Simple(0.15, function()
					if IsValid(self) and IsValid(self.Owner) and self.Owner:GetDuckSpeed() < 100 then
						self:SetNWBool("fire", false)
					end
				end)
			else
				self:SetNWBool("fire", false)
			end
		end
	end)
	
	timer.Create("L3" .. self:EntIndex(), self.L3Delay / 60, 3, function()
		if IsValid(self) and IsValid(self.Owner) then
			self:SetHoldType(self.HoldType)
			self.BaseClass.PrimaryAttack(self)
			self:SetClip1(self:Clip1() + self.Primary.TakeAmmo)
			self:SetNextReloadTime(self.StopReloading)
		end
	end)
end
