
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.Category = "Splatoon SWEPs"
SWEP.PrintName = ss.PrintName.weapon_aerospray_mg
SWEP.Spawnable = true

SWEP.ShootSound = "SplatoonSWEPs.Aerospray"
ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					--false to semi-automatic
	Recoil				= .2,					--Viewmodel recoil intensity
	TakeAmmo			= .005,					--Ink consumption per fire[-]
	PlayAnimPercent		= 0,					--Play PLAYER_ATTACK1 animation frequency[%]
	FirePosition		= Vector(0, -5, -10),	--Ink spawn position
	Damage				= .245,					--Maximum damage[-]
	MinDamage			= .1225,					--Minimum damage[-]
	InkRadius			= 22,			--Painting radius[Splatoon units]
	MinRadius			= 19,					--Minimum painting radius[Splatoon units]
	SplashRadius		= 13.5,					--Painting radius[Splatoon units]
	SplashPatterns		= 8,					--Paint patterns
	SplashNum			= 1,					--Number of splashes
	SplashInterval		= 117,					--Make an interval on each splash[Splatoon units]
	Spread				= 12,					--Aim cone[deg]
	SpreadJump			= 18,					--Aim cone while jumping[deg]
	SpreadBias			= .4,					--Aim cone random component[deg]
	MoveSpeed			= .72,					--Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					--Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					--Change hold type[frames]
		Fire			= 4,					--Fire rate[frames]
		Reload			= 20,					--Start reloading after firing weapon[frames]
		Crouch			= 6,					--Can't crouch for some frames after firing
		Straight		= 3,					--Ink goes without gravity[frames]
		MinDamage		= 15,					--Deals minimum damage[frames]
		DecreaseDamage	= 8,					--Start decreasing damage[frames]
	},
})

if SERVER then return end

SWEP.ViewModelBoneMods = {
	["Base"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 30, -30),
		angle = Angle(0, 0, 0)
	},
	["ValveBiped.Bip01_L_Clavicle"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(2.397, -2, 2),
		angle = Angle(0, 0, 0)
	},
	["ValveBiped.Bip01_Spine4"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-31, 25, 30),
		angle = Angle(0, -8, -2)
	},
}

SWEP.VElements = {
	weapon = {
		type = "Model",
		model = "models/props_splatoon/weapons/primaries/aerospray/aerospray.mdl",
		bone = "ValveBiped.Bip01_Spine4",
		rel = "",
		pos = Vector(8, -26, -6),
		angle = Angle(13, 80, 90),
		size = Vector(0.56, 0.56, 0.56),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}

SWEP.WElements = {
	weapon = {
		type = "Model",
		model = "models/props_splatoon/weapons/primaries/aerospray/aerospray.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(11, 1, -4),
		angle = Angle(0, 10, 180),
		size = Vector(1, 1, 1),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}
