--[[
	Bamboozler 14 MK II is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/charger/bamboozler00.mp3"),
	Sound("SplatoonSWEPs/charger/bamboozler01.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Bamboozler 14 MK II beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_charger_base"
SWEP.InkColor = "Purple"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(128,0,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.015
SWEP.RelInk = 4
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 9

SWEP.Forward = 6	--Projectile spawns
SWEP.Right = 10
SWEP.Upward = -10
SWEP.SplashMul = 3		--The lower charge, the longer length
SWEP.SplashLen = 45		--The length between splashes
SWEP.SplashSpread = 3
SWEP.SplashPattern = 3
SWEP.Range = 800
SWEP.Width = 18
SWEP.V0 = 1600
SWEP.InkRadius = 20
SWEP.FallTimer = 100
SWEP.FiringSpeed = 102.040816
SWEP.StopReloading = 20		--Stop reloading several frames after firing weapon.
SWEP.MinDamage = 30
SWEP.UptoDamage = 80
SWEP.MaxDamage = 80
SWEP.MinTime = 13
SWEP.ChargeSpeed = 4.5
SWEP.ShootCount = 0

SWEP.PrintName = "Bamboozler 14 MK II"
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize = 800
SWEP.Primary.DefaultClip = 800
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0
SWEP.Primary.Delay = 0.21666667
SWEP.Primary.Spread = 0
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 0.64
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.044

SWEP.HoldType = "shotgun"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-35, -10, 0) },
	["ValveBiped.Bip01_R_Finger21"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 8, 0) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, -30, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger02"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 15, 0) },
	["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(1, 20, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-23, -20, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(27.5, 26, 30), angle = Angle(0, -10, 0) },
	["ValveBiped.Bip01_L_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -23, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(2, 1, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(10, -3, 0) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/bamboozler/bamboozler.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(3, 1, -1), 
	angle = Angle(-180, 180, 5), 
	size = Vector(0.5, 0.5, 0.5), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 1, 
	bodygroup = {} 
	}
}

SWEP.WElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/bamboozler/bamboozler.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(4, 1.5, 0), 
	angle = Angle(-173, -173.5, -5), 
	size = Vector(1, 1, 1), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 1, 
	bodygroup = {} 
	}
}

----------------------------------------------------------

include("weapons/splatsubweapons/disruptor.lua")
AddCSLuaFile("weapons/splatsubweapons/disruptor.lua")
