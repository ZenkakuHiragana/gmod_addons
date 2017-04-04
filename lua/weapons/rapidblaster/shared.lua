--[[
	Rapid Blaster is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/sploosh-o-matic00.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Rapid Blaster beta"
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
SWEP.ReloadSpeed = 0.06
SWEP.RelInk = 1
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 80

SWEP.Forward = 20	--Projectile spawns
SWEP.Right = 6
SWEP.Upward = -5
SWEP.PrimaryVelocity = 45000
SWEP.SplashNum = 11		--Projectiles splash count
SWEP.SplashLen = 25		--The length between splashes
SWEP.SplashPattern = 1
SWEP.SplashSpread = 15
SWEP.V0 = 1200
SWEP.Radius = 80
SWEP.InkRadius = 18
SWEP.FallTimer = 250
SWEP.FiringSpeed = 140.305
SWEP.StopReloading = 25		--Stop reloading several frames after firing weapon.
SWEP.FreezeTime = 26
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 50
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Delay = 0.58333333
SWEP.Primary.Spread = 0
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 4
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.04

SWEP.PrintName = "Rapid Blaster"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 23, -12) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-28, 27, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(2, -2, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 25, 30), angle = Angle(0, -8, 0) },
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(7, -27, 0) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/rapid_blaster/rapid_blaster.mdl", 
	bone = "ValveBiped.Bip01_Spine4", 
	rel = "", 
	pos = Vector(3.2, -23.7, -7.2), 
	angle = Angle(13, 80, 90), 
	size = Vector(0.56, 0.56, 0.56), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 0, 
	bodygroup = {} 
	}
}

SWEP.WElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/rapid_blaster/rapid_blaster.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(4, 0.6, 1), 
	angle = Angle(0, 1, 180), 
	size = Vector(1, 1, 1), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 0, 
	bodygroup = {} 
	}
}

------------------------------------------------------------------

include("weapons/splatsubweapons/inkmine.lua")
AddCSLuaFile("weapons/splatsubweapons/inkmine.lua")
include("weapons/weapon_blaster_base/shared.lua")
