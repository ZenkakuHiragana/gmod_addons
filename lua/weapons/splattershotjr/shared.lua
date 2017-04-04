--[[
	Splattershot Jr. is a weapon in Splatoon.
	This shoots ink, and looks like submachine gun.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/splattershotJr00.mp3")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Splattershot Jr. beta"
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
SWEP.ReloadSpeed = 0.015
SWEP.RelInk = 1
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 9

SWEP.Forward = -5	--Projectile spawns
SWEP.Right = 10
SWEP.Upward = -10
SWEP.PrimaryVelocity = 62000
SWEP.SplashNum = 1.5		--Projectiles splash count
SWEP.SplashLen = 160		--The length between splashes
SWEP.SplashPattern = 8
SWEP.SplashSpread = 3
SWEP.V0 = 1600
SWEP.InkRadius = 20
SWEP.FallTimer = 180
SWEP.FiringSpeed = 186
SWEP.StopReloading = 20		--Stop reloading several frames after firing weapon.
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 200
SWEP.Primary.DefaultClip = 200
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0
SWEP.Primary.Delay = 0.083333333
SWEP.Primary.Spread = 0.22
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 1
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.044

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "Splattershot Jr."
SWEP.Slot = 1
SWEP.SlotPos = 10
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_crossbow.mdl"
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
	model = "models/props_splatoon/weapons/primaries/splattershot_jr/splattershot_jr.mdl",
	bone = "ValveBiped.Bip01_Spine4",
	rel = "",
	pos = Vector(4, -23, -7),
	angle = Angle(10, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
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
	model = "models/props_splatoon/weapons/primaries/splattershot_jr/splattershot_jr.mdl",
	bone = "ValveBiped.Bip01_R_Hand",
	rel = "",
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 0, 180),
	size = Vector(1, 1, 1),
	color = Color(255, 255, 255, 255),
	surpresslightning = false,
	material = "",
	skin = 0,
	bodygroup = {}
	}
}

-------------------------------------------------------------------

include("weapons/splatsubweapons/splatbomb.lua")
AddCSLuaFile("weapons/splatsubweapons/splatbomb.lua")
