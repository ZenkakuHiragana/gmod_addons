--[[
	Gold Dynamo Roller is a weapon in Splatoon.
]]

SWEP.PreSwingSound = {
	Sound("SplatoonSWEPs/roller/dynamopreswing00.mp3"),
}
SWEP.ShootSound = {
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray10.wav"),
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray11.wav"),
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray12.wav"),
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray13.wav"),
}
SWEP.RollSound = Sound("SplatoonSWEPs/roller/dynamoroll00.mp3")
SWEP.SwingVolume = 100

SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Gold Dynamo Roller beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_roller_base"
SWEP.InkColor = "Orange"	--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(255, 128, 0, 255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.03
SWEP.RelInk = 10
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 125
SWEP.RollDamage = 160

SWEP.Forward = 0	--Projectile spawns
SWEP.Right = 0
SWEP.Upward = 20
SWEP.PrimaryVelocity = 50000
SWEP.SplashNum = 10		--Projectiles splash count
SWEP.SplashLen = 60		--The length between splashes
SWEP.SplashPattern = 8
SWEP.SplashSpread = 15
SWEP.SwingSpeed = 45 / 60
SWEP.SwingNum = 32
SWEP.RollWidth = 60
SWEP.RollWidthSlow = 25
SWEP.V0 = 800
SWEP.InkedBodygroup = 1
SWEP.ZDelta = 1
SWEP.InkRadius = 40
SWEP.FallTimer = 400
SWEP.FiringSpeed = 244.89796
SWEP.StopReloading = 50		--Stop reloading several frames after firing weapon.
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 1000
SWEP.Primary.DefaultClip = 1000
SWEP.Primary.Automatic = false
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Delay = 10 / 60
SWEP.Primary.Spread = 0.4 - 0.05
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 200
SWEP.Primary.Splash1 = 0.054
SWEP.Primary.Splash2 = 0.043

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "Gold Dynamo Roller"
SWEP.Slot = 0
SWEP.SlotPos = 2
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
	["ValveBiped.Bip01_L_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(2, -2.689, -0.164), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger42"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_L_Finger22"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["Bullet1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 50) },
	["Bullet4"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -15, 0) },
	["ValveBiped.Bip01_L_Finger21"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, -5), angle = Angle(0, 0, 0) },
	["Bullet5"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(1, -5, 0) },
	["ValveBiped.Bip01_R_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(3, -20, 0) },
	["ValveBiped.Bip01_L_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_L_Finger12"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -75, 0) },
	["ValveBiped.Bip01_L_Finger32"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["Bullet2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger12"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -75, 0) },
	["Python"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger41"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(30, 0, 0) }
}

SWEP.VElements = {
	["element_name"] = { 
	type = "Model", 
	model = "models/props_splatoon/weapons/primaries/dynamo_roller/dynamo_roller.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(3, -1.5, 0.7), 
	angle = Angle(0, 0, 180), 
	size = Vector(0.5, 0.5, 0.5), 
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
	model = "models/props_splatoon/weapons/primaries/dynamo_roller/dynamo_roller.mdl", 
	bone = "ValveBiped.Bip01_R_Hand", 
	rel = "", 
	pos = Vector(3.3, -2.3, 10), 
	angle = Angle(4, 20, 164), 
	size = Vector(1, 1, 1), 
	color = Color(255, 255, 255, 255), 
	surpresslightning = false, 
	material = "", 
	skin = 1, 
	bodygroup = {[1] = 1} 
	}
}

------------------------------------------------------------------

include("weapons/splatsubweapons/splatbomb.lua")
AddCSLuaFile("weapons/splatsubweapons/splatbomb.lua")

