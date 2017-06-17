--[[
	Inkbrush Nouveau is a weapon in Splatoon.
]]

SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Inkbrush Nouveau beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Base = "weapon_roller_base"
--SWEP.InkColor = "Blue"		--Ink Color. Only can swim in the same Ink Color.
--SWEP.ProjColor = Color(0,0,255,255)
SWEP.InkColor = "Purple"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(128,0,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.06
SWEP.RelInk = 1
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 28
SWEP.RollDamage = 20

SWEP.Forward = 20	--Projectile spawns
SWEP.Right = 0
SWEP.Upward = 0
SWEP.PrimaryVelocity = 30000
SWEP.SplashNum = 3		--Projectiles splash count
SWEP.SplashLen = 100		--The length between splashes
SWEP.SplashPattern = 6
SWEP.SplashSpread = 15
SWEP.SwingSpeed = 1 / 60
SWEP.SwingNum = 2
SWEP.RollWidth = 50
SWEP.RollWidthSlow = 25
SWEP.V0 = 600
SWEP.ZDelta = -3
SWEP.InkedBodygroup = nil
SWEP.InkRadius = 50
SWEP.FallTimer = 210
SWEP.FiringSpeed = 700
SWEP.StopReloading = 30		--Stop reloading several frames after firing weapon.
SWEP.FreezeTime = 30
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 667
SWEP.Primary.DefaultClip = 667
SWEP.Primary.Automatic = false
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Delay = 6 / 60
SWEP.Primary.Spread = 0.4 - 0.05
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 13
SWEP.Primary.Splash1 = 0.055
SWEP.Primary.Splash2 = 0.036

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "Inkbrush Nouveau"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.HoldType = "melee2"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Finger31"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(7, 0, 0) },
	["Bullet3"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger11"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -15, 0) },
	["Bullet6"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(2, -1.5, -0.164), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger42"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_L_Finger22"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["Bullet1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 50) },
	["Bullet4"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -15, 0) },
	["ValveBiped.Bip01_L_Finger21"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, 0, 0) },
	["ValveBiped.Bip01_L_Finger41"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(30, 0, 0) },
	["Bullet5"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(1, -5, 0) },
	["Python"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger12"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -75, 0) },
	["ValveBiped.Bip01_L_Finger12"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -75, 0) },
	["ValveBiped.Bip01_L_Finger32"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["Bullet2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_R_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(3, -20, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(0, -3, -4), angle = Angle(10, 0, 0) }
}

SWEP.VElements = {
	["element_name"] = {
	type = "Model",
	model = "models/props_splatoon/weapons/primaries/inkbrush/inkbrush.mdl",
	bone = "ValveBiped.Bip01_R_Hand",
	rel = "",
	pos = Vector(2.5, -2.5, -15),
	angle = Angle(0, -90, 180),
	size = Vector(0.5, 0.5, 0.5),
	color = SWEP.ProjColor,
	surpresslightning = false,
	material = "",
	skin = 1,
	bodygroup = {}
	}
}

SWEP.WElements = {
	["element_name"] = {
	type = "Model",
	model = "models/props_splatoon/weapons/primaries/inkbrush/inkbrush.mdl",
	bone = "ValveBiped.Bip01_R_Hand",
	rel = "", 
	pos = Vector(33, -3, -8),
	angle = Angle(-80, 100, 180),
	size = Vector(1, 1, 1),
	color = SWEP.ProjColor,
	surpresslightning = false,
	material = "",
	skin = 1,
	bodygroup = {}
	}
}
------------------------------------------------------------------

include("weapons/splatsubweapons/inkmine.lua")
AddCSLuaFile("weapons/splatsubweapons/inkmine.lua")