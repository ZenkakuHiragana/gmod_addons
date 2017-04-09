--[[
	Custom E-Liter 3K is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/charger/e-liter00.mp3"),
	Sound("SplatoonSWEPs/charger/e-liter01.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Custom E-Liter 3K beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_charger_base"
SWEP.InkColor = "Blue"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(0,0,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.02
SWEP.RelInk = 6
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 9

SWEP.Forward = 6	--Projectile spawns
SWEP.Right = 10
SWEP.Upward = -10
SWEP.SplashMul = 1.58	--The lower charge, the longer length
SWEP.SplashLen = 40		--The length between splashes
SWEP.SplashSpread = 3
SWEP.Range = 1496
SWEP.Width = 22
SWEP.V0 = 1600
SWEP.InkRadius = 20
SWEP.FallTimer = 100
SWEP.FiringSpeed = 38.2653065625
SWEP.StopReloading = 20		--Stop reloading several frames after firing weapon.
SWEP.MinDamage = 40
SWEP.UptoDamage = 120
SWEP.MaxDamage = 180
SWEP.MinTime = 13
SWEP.ChargeSpeed = 0.9
SWEP.ShootCount = 0

SWEP.PrintName = "Custom E-Liter 3K"
SWEP.Slot = 5
SWEP.SlotPos = 6
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize = 900
SWEP.Primary.DefaultClip = 900
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0
SWEP.Primary.Delay = 0.18333333
SWEP.Primary.Spread = 0
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 2.7
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
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, -30, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(2, 1, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(1, 20, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-23, -20, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(27.5, 26, 30), angle = Angle(0, -10, 0) },
	["ValveBiped.Bip01_L_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -23, 0) },
	["ValveBiped.Bip01_L_Finger02"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 15, 0) },
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(10, -3, 0) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/e_liter_3k/e_liter_3k.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(8, 1, -3), 
	angle = Angle(-180, 180, 0), 
	size = Vector(0.5, 0.5, 0.5), 
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
	model = "models/props_splatoon/weapons/primaries/e_liter_3k/e_liter_3k.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(12.5, 1, -4.5), 
	angle = Angle(-175, -175, -5), 
	size = Vector(1, 1, 1), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 0, 
	bodygroup = {[1] = 1} 
	}
}

----------------------------------------------------------

include("weapons/splatsubweapons/beakon.lua")
AddCSLuaFile("weapons/splatsubweapons/beakon.lua")
