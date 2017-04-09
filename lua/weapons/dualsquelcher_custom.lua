--[[
	Custom Dual Squelcher is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/dual00.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Custom Dual Squelcher beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_splat_base"
SWEP.InkColor = "Green"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(0,255,0,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.06
SWEP.RelInk = 5
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 28

SWEP.Forward = 10	--Projectile spawns
SWEP.Right = 15
SWEP.Upward = -15
SWEP.PrimaryVelocity = 62000
SWEP.SplashNum = 2			--Projectiles splash count
SWEP.SplashLen = 210		--The length between splashes
SWEP.SplashPattern = 9
SWEP.SplashSpread = 3
SWEP.V0 = 1300
SWEP.InkRadius = 30
SWEP.FallTimer = 260
SWEP.FiringSpeed = 127.55
SWEP.StopReloading = 20
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 250
SWEP.Primary.DefaultClip = 250
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0.2
SWEP.Primary.Delay = 0.1
SWEP.Primary.Spread = 0.06666667
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 3
SWEP.Primary.Splash1 = 0.051
SWEP.Primary.Splash2 = 0.043

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "Custom Dual Squelcher"
SWEP.Slot = 1
SWEP.SlotPos = 4
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
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(7, -27, 0) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 28, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(2, -2, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 27, 30), angle = Angle(0, -8, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 23, -12) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/squelcher/squelcher.mdl", 
	bone = "ValveBiped.Bip01_Spine4", 
	rel = "", 
	pos = Vector(3.7, -24.3, -7.2), 
	angle = Angle(13, 80, 90), 
	size = Vector(0.56, 0.56, 0.56), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 1, 
	bodygroup = {[1] = 1} 
	}
}

SWEP.WElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/squelcher/squelcher.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(4, 0.6, 0.5), 
	angle = Angle(0, 1, 180), 
	size = Vector(1, 1, 1), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 1, 
	bodygroup = {[1] = 1} 
	}
}

------------------------------------------------------

include("weapons/splatsubweapons/beakon.lua")
AddCSLuaFile("weapons/splatsubweapons/beakon.lua")
