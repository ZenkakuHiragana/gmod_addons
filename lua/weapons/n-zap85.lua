--[[
	N-ZAP '85 is a weapon in Splatoon.
]]

SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/zap00.wav")
}
SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's N-ZAP '85 beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_splat_base"
SWEP.InkColor = "Purple"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(128,0,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.06
SWEP.RelInk = 5
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 28

SWEP.Forward = 1	--Projectile spawns
SWEP.Right = 10
SWEP.Upward = -9
SWEP.PrimaryVelocity = 62000
SWEP.SplashNum = 1.5		--Projectiles splash count
SWEP.SplashLen = 220		--The length between splashes
SWEP.SplashPattern = 12
SWEP.SplashSpread = 15
SWEP.V0 = 1200
SWEP.InkRadius = 28
SWEP.FallTimer = 210
SWEP.FiringSpeed = 186
SWEP.StopReloading = 20
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 250
SWEP.Primary.DefaultClip = 250
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0.1
SWEP.Primary.Delay = 0.08333333
SWEP.Primary.Spread = 0.1
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 2
SWEP.Primary.Splash1 = 0.052
SWEP.Primary.Splash2 = 0.04

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "N-ZAP '85"
SWEP.Slot = 1
SWEP.SlotPos = 6
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
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(7, -27, 0) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 30, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(2, -2, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 27.5, 30), angle = Angle(0, -8, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 23, -12) }
}

SWEP.VElements = {
	["element_name"] = {
		type = "Model",
		model = "models/props_splatoon/weapons/primaries/n_zap/n_zap.mdl",
		bone = "ValveBiped.Bip01_Spine4",
		rel = "",
		pos = Vector(3.5, -24.3, -7.2),
		angle = Angle(12.736, 80, 90),
		size = Vector(0.56, 0.56, 0.56),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 2,
		bodygroup = {}
		}
}

SWEP.WElements = {
	["element_name"] = {
	type = "Model",
	model = "models/props_splatoon/weapons/primaries/n_zap/n_zap.mdl",
	bone = "ValveBiped.Bip01_R_Hand",
	rel = "",
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
	size = Vector(1, 1, 1),
	color = Color(255, 255, 255, 255),
	surpresslightning = false,
	material = "",
	skin = 2,
	bodygroup = {}
	}
}

------------------------------------------------------------------

include("weapons/splatsubweapons/splatbomb.lua")
AddCSLuaFile("weapons/splatsubweapons/splatbomb.lua")
