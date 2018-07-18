
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Aerospray"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/aerospray/aerospray.mdl"
SWEP.Sub = "seeker"
SWEP.Special = "inkzooka"
SWEP.Variations = {
	{
		ClassName = "weapon_aerospray_rg",
		Sub = "inkmine",
		Special = "inkstrike",
		Skin = 2,
	},
	{
		ClassName = "weapon_aerospray_pg",
		Sub = "burstbomb",
		Special = "kraken",
		Skin = 4,
	},
}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .005,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(20, 0, .6),	-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .245,					-- Maximum damage[-]
	MinDamage			= .1225,				-- Minimum damage[-]
	InkRadius			= 22,					-- Painting radius[Splatoon units]
	MinRadius			= 19,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.5,					-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns[-]
	SplashNum			= 1,					-- Number of splashes[-]
	SplashInterval		= 117,					-- Make an interval on each splash[Splatoon units]
	Spread				= 12,					-- Aim cone[deg]
	SpreadJump			= 18,					-- Aim cone while jumping[deg]
	SpreadBias			= .4,					-- Aim cone random component[deg]
	MoveSpeed			= .72,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 4,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 3,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, -1.5, 2)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 28, -13)},
	["ValveBiped.Bip01_R_Clavicle"] = {pos = Vector(0, 0, 0)},
	["ValveBiped.Bip01_R_Finger1"] = {angle = Angle(-8, -20, 0)},
	["ValveBiped.Bip01_R_Finger11"] = {angle = Angle(8, 25, 0)},
	["ValveBiped.Bip01_R_Finger12"] = {angle = Angle(0, -60, 0)},
	["ValveBiped.Bip01_R_Finger2"] = {angle = Angle(0, -30, 0)},
	["ValveBiped.Bip01_R_Finger22"] = {angle = Angle(0, 45, 0)},
	["ValveBiped.Bip01_R_Finger3"] = {angle = Angle(0, -20, 0)},
	["ValveBiped.Bip01_R_Finger32"] = {angle = Angle(0, 20, 0)},
	["ValveBiped.Bip01_R_Finger4"] = {angle = Angle(0, -40, 0)},
	["ValveBiped.Bip01_R_Finger41"] = {angle = Angle(0, 20, 0)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-5, -6, 0),
		angle = Angle(0, -10, 10),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(6.1, -26, -7),
	angle = Angle(0, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(11, 1, -4),
	angle = Angle(0, 10, 180),
})
