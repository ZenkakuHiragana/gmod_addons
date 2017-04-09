--[[
	Splattershot Pro is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/splattershotpro00.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Splattershot Pro beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_splat_base"
SWEP.InkColor = "Pink"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(255,0,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.06
SWEP.RelInk = 1
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 22

SWEP.Forward = 30	--Projectile spawns
SWEP.Right = 6
SWEP.Upward = -6
SWEP.PrimaryVelocity = 62000
SWEP.SplashNum = 3			--Projectiles splash count
SWEP.SplashLen = 140		--The length between splashes
SWEP.SplashPattern = 9
SWEP.SplashSpread = 15
SWEP.V0 = 1300
SWEP.InkRadius = 28
SWEP.FallTimer = 260
SWEP.FiringSpeed = 127.55
SWEP.StopReloading = 20
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 50
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0.6
SWEP.Primary.Delay = 0.13333333
SWEP.Primary.Spread = 0.05
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 1
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.044

SWEP.ViewModel = "models/weapons/c_IRifle.mdl"
SWEP.WorldModel = "models/weapons/w_IRifle.mdl"

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "Splattershot Pro"
SWEP.Slot = 1
SWEP.SlotPos = 11
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
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 30, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(2.397, -2, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 27.5, 30), angle = Angle(0, -8, 0) }
}

SWEP.VElements = {
	["element_name"] = {
	type = "Model",
	model = "models/props_splatoon/weapons/primaries/splattershot_pro/splattershot_pro.mdl",
	bone = "ValveBiped.Bip01_Spine4",
	rel = "",
	pos = Vector(3.5, -22.8, -7),
	angle = Angle(12.736, 80, 90),
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
	model = "models/props_splatoon/weapons/primaries/splattershot_pro/splattershot_pro.mdl",
	bone = "ValveBiped.Bip01_R_Hand",
	rel = "",
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
	size = Vector(1, 1, 1),
	color = Color(255, 255, 255, 255),
	surpresslightning = false,
	material = "",
	skin = 0,
	bodygroup = {}
	}
}

-------------------------------------------------------

include("weapons/splatsubweapons/splatbomb.lua")
AddCSLuaFile("weapons/splatsubweapons/splatbomb.lua")
