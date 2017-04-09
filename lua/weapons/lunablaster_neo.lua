--[[
	Luna Blaster Neo is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/splattershotJr00.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Luna Blaster Neo beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_splat_base"
SWEP.InkColor = "Cyan"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(0,255,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.03
SWEP.RelInk = 1
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 125

SWEP.Forward = 15	--Projectile spawns
SWEP.Right = 6
SWEP.Upward = -5
SWEP.PrimaryVelocity = 26000
SWEP.SplashNum = 11		--Projectiles splash count
SWEP.SplashLen = 25		--The length between splashes
SWEP.SplashPattern = 1
SWEP.SplashSpread = 15
SWEP.V0 = 1200
SWEP.Radius = 127
SWEP.InkRadius = 26
SWEP.FallTimer = 250
SWEP.FiringSpeed = 127.55
SWEP.StopReloading = 30		--Stop reloading several frames after firing weapon.
SWEP.FreezeTime = 30
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Delay = 0.66666667
SWEP.Primary.Spread = 0
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 6
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.04

SWEP.PrintName = "Luna Blaster Neo"
SWEP.Slot = 2
SWEP.SlotPos = 5
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
	["ValveBiped.Bip01_L_Finger31"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(5, 12, 0) },
	["ValveBiped.Bip01_L_Finger21"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 20, 0) },
	["ValveBiped.Bip01_L_Finger11"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 21, 0) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 26, -30), angle = Angle(1, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(1, -2, 2.5), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 26, 30), angle = Angle(0, -8, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 28, -13) },
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(25, -40, 0) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/luna_blaster/luna_blaster.mdl", 
	bone = "ValveBiped.Bip01_Spine4", 
	rel = "", 
	pos = Vector(3, -23.5, -7), 
	angle = Angle(13, 80, 90), 
	size = Vector(0.56, 0.56, 0.56), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 0, 
	bodygroup = {[1] = 1} 
	}
}

SWEP.WElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/luna_blaster/luna_blaster.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(3.5, 0.6, 0.5), 
	angle = Angle(0, 1, 180), 
	size = Vector(1, 1, 1), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 0, 
	bodygroup = {[1] = 1} 
	}
}

------------------------------------------------------------------

include("weapons/splatsubweapons/splatbomb.lua")
AddCSLuaFile("weapons/splatsubweapons/splatbomb.lua")
include("weapons/weapon_blaster_base.lua")
