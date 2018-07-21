
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.52"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/52_96_gal/52_96_gal.mdl"
SWEP.Sub = "splashwall"
SWEP.Special = "killerwail"
SWEP.Variations = {{
	ClassName = "weapon_52gal_deco",
	Sub = "seeker",
	Special = "inkstrike",
	Skin = 3,
}}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .012,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(25, 0, 9),		-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .52,					-- Maximum damage[-]
	MinDamage			= .26,					-- Minimum damage[-]
	InkRadius			= 21,					-- Painting radius[Splatoon units]
	MinRadius			= 18.5,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.5,					-- Painting radius[Splatoon units]
	SplashPatterns		= 5,					-- Paint patterns[-]
	SplashNum			= 3,					-- Number of splashes[-]
	SplashInterval		= 50,					-- Make an interval on each splash[Splatoon units]
	Spread				= 6,					-- Aim cone[deg]
	SpreadJump			= 15,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .6,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 9,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 4,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(1.5, 0, 2.5)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(25, -40, 0)},
	["ValveBiped.Bip01_L_Finger3"] = {angle = Angle(0, 6, 0)},
	["ValveBiped.Bip01_L_Finger41"] = {angle = Angle(0, 15, 0)},
	["ValveBiped.Bip01_L_Finger42"] = {angle = Angle(0, 10, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 28, -13)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(0, -5, -1),
		angle = Angle(1, -8, -8.5),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(2.8, -24, -7),
	angle = Angle(13, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(5, 0.6, 0.5),
	angle = Angle(0, 1, 180),
})
