
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Sploosh-o-matic"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/splash_sploosh_o_matic/splash_sploosh_o_matic.mdl"
SWEP.Sub = "squidbeakon"
SWEP.Special = "killerwail"
SWEP.Variations = {
	{
		ClassName = "weapon_sploosh_o_matic_neo",
		Sub = "pointsensor",
		Special = "kraken",
		Bodygroup = {1, 1},
	},
	{
		ClassName = "weapon_sploosh_o_matic_7",
		Sub = "splatbomb",
		Special = "inkzooka",
		Skin = 4,
	},
}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .007,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(20, 0, 7),		-- Thirdperson muzzle position in local coord.
	Damage				= .38,					-- Maximum damage[-]
	MinDamage			= .19,					-- Minimum damage[-]
	InkRadius			= 24,					-- Painting radius[Splatoon units]
	MinRadius			= 19,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,					-- Painting radius[Splatoon units]
	SplashPatterns		= 4,					-- Paint patterns
	SplashNum			= 1.5,					-- Number of splashes
	SplashInterval		= 55,					-- Make an interval on each splash[Splatoon units]
	Spread				= 12,					-- Aim cone[deg]
	SpreadJump			= 18,					-- Aim cone while jumping[deg]
	SpreadBias			= .4,					-- Aim cone random component[deg]
	MoveSpeed			= .72,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 20,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 5,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Can't crouch for some frames after firing
		Straight		= 2,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 6,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(7, -15, 0)},
	["ValveBiped.Bip01_L_Finger1"] = {angle = Angle(-20, -10, 0)},
	["ValveBiped.Bip01_L_Finger2"] = {angle = Angle(-10, -10, 0)},
	["ValveBiped.Bip01_L_Finger21"] = {angle = Angle(0, -25, 0)},
	["ValveBiped.Bip01_L_Finger22"] = {angle = Angle(0, 20, 0)},
	["ValveBiped.Bip01_L_Finger3"] = {angle = Angle(0, -20, 0)},
	["ValveBiped.Bip01_L_Finger4"] = {angle = Angle(5, -20, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_R_Finger1"] = {angle = Angle(20, 0, 0)},
	["ValveBiped.Bip01_R_Finger11"] = {angle = Angle(0, 12, 0)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-3, -10, 0),
		angle = Angle(0, -12, -0.5),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(3.5, -23.5, -7.1),
	angle = Angle(13, 76, 90),
	size = Vector(0.56, 0.56, 0.56),
	bodygroup = {[2] = 1},
})

ss:SetWorldModel(SWEP, {
	pos = Vector(3.4, 0.6, 0.5),
	angle = Angle(0, 10, 180),
	bodygroup = {[2] = 1},
})
