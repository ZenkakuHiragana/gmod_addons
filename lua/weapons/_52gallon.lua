--[[
	.52 Gallon is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/52gallon00.wav")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's .52 Gallon beta"
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
SWEP.RelInk = 5
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 52

SWEP.Forward = 15	--Projectile spawns
SWEP.Right = 6
SWEP.Upward = -5
SWEP.PrimaryVelocity = 62000
SWEP.SplashNum = 3		--Projectiles splash count
SWEP.SplashLen = 100		--The length between splashes
SWEP.SplashPattern = 6
SWEP.SplashSpread = 15
SWEP.V0 = 1200
SWEP.InkRadius = 30
SWEP.FallTimer = 210
SWEP.FiringSpeed = 153.06125
SWEP.StopReloading = 20
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 250
SWEP.Primary.DefaultClip = 250
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Delay = 0.15
SWEP.Primary.Spread = 0.11
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 3
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.04

SWEP.PrintName = ".52 Gallon"
SWEP.Slot = 1
SWEP.SlotPos = 1
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
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(25, -40, 0) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 26, -30), angle = Angle(1, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(1.5, 0, 2.5), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 26, 30), angle = Angle(0, -8, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 28, -13) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/52_96_gal/52_96_gal.mdl", 
	bone = "ValveBiped.Bip01_Spine4", 
	rel = "", 
	pos = Vector(2.8, -24, -7), 
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
	model = "models/props_splatoon/weapons/primaries/52_96_gal/52_96_gal.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(5, 0.6, 0.5), 
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

include("weapons/splatsubweapons/splashwall.lua")
AddCSLuaFile("weapons/splatsubweapons/splashwall.lua")
