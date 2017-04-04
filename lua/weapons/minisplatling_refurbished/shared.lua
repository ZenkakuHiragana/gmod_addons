--[[
	Refurbished Mini Splatling is a weapon in Splatoon.
]]

SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Refurbished Mini Splatling beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Charge1 = Sound("SplatoonSWEPs/splatling/minisplatling00.mp3")
SWEP.Charge2 = Sound("SplatoonSWEPs/splatling/minisplatling01.mp3")
SWEP.Charged = Sound("SplatoonSWEPs/splatling/minisplatling02.wav")
SWEP.ShootSound = {
	Sound("SplatoonSWEPs/shooter/octoshot00.mp3")
}

SWEP.Base = "weapon_splatling_base"
SWEP.InkColor = "Blue"	--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(0, 0, 255, 255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.throw = false			--Whether subweapon is ready to use or not.
SWEP.wepAnim = ACT_VM_IDLE
SWEP.maxspeed = 250
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.03
SWEP.RelInk = 10
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 28

SWEP.Forward = -3	--Projectile spawns
SWEP.Right = 12
SWEP.Upward = -18
SWEP.PrimaryVelocity = 53000
SWEP.SplashNum = 1.8		--Projectiles splash count
SWEP.SplashMul = 1.58	--The lower charge, the longer length
SWEP.SplashLen = 340		--The length between splashes
SWEP.SplashPattern = 10
SWEP.SplashSpread = 3
SWEP.Width = 22
SWEP.V0 = 1600
SWEP.InkRadius = 22
SWEP.FallTimer = 290
SWEP.Range = SWEP.FallTimer * 0.000052 --for crosshair
SWEP.FiringSpeed = 191.66667
SWEP.ChargingSpeed = 142.13483
SWEP.StopReloading = 40		--Stop reloading several frames after firing weapon.
SWEP.ChargeSpeed = 3.75
SWEP.ChargeSpeed2 = 7.5
SWEP.FireLast = 72
SWEP.ShootCount = 0

SWEP.PrintName = "Refurbished Mini Splatling"
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize = 1000
SWEP.Primary.DefaultClip = 1000
SWEP.Primary.Automatic = true
SWEP.Primary.Recoil = 0.2
SWEP.Primary.Delay = 1 / 15
SWEP.Primary.Spread = 0.066666666
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 8
SWEP.Primary.Splash1 = 0.055
SWEP.Primary.Splash2 = 0.043

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_crossbow.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Finger31"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(5, -15, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(0, 1, -0.5), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-2, -20, 8.01) },
	["ValveBiped.Bip01_L_Finger22"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -10, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, 0, 170) },
	["ValveBiped.Bip01_L_Finger41"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(20, 2, 0) },
	["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -30, 0) },
	["ValveBiped.Bip01_L_Finger21"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-5, -40, 0) },
	["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(20, -10, 0) },
	["ValveBiped.Crossbow_base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, -30, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger02"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 50, 0) },
	["ValveBiped.Bip01_L_Finger32"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(10, -30, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 4), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(12, -20, 0) },
	["ValveBiped.Bip01_L_Finger01"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 10, 0) }
}

SWEP.VElements = {
	["element_name"] = { 
		type = "Model", 
		model = "models/props_splatoon/weapons/primaries/mini_splatling/mini_splatling.mdl", 
		bone = "ValveBiped.Bip01_L_Hand", 
		rel = "", 
		pos = Vector(-2, 2.5, 3), 
		angle = Angle(-30, 20, -80), 
		size = Vector(0.5, 0.5, 0.5), 
		color = Color(255, 255, 255, 255), 
		surpresslightning = false, 
		material = "", 
		skin = 6, 
		bodygroup = {} 
	}
}

SWEP.WElements = {
	["element_name"] = { 
		type = "Model", 
		model = "models/props_splatoon/weapons/primaries/mini_splatling/mini_splatling.mdl", 
		bone = "ValveBiped.Bip01_R_Hand", 
		rel = "", 
		pos = Vector(3, 1, -1.5), 
		angle = Angle(0, 1, 180), 
		size = Vector(1, 1, 1), 
		color = Color(255, 255, 255, 255), 
		surpresslightning = false, 
		material = "", 
		skin = 6, 
		bodygroup = {} 
	}
}

------------------------------------------------------------------

include("weapons/splatsubweapons/burstbomb.lua")
AddCSLuaFile("weapons/splatsubweapons/burstbomb.lua")
