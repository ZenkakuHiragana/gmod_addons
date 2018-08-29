
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.Sploosh-o-matic"
SWEP.Sub = "squidbeakon"
SWEP.Special = "killerwail"
SWEP.Skin = 1
SWEP.Variations = {
	{
		ClassName = "weapon_sploosh_o_matic_neo",
		Sub = "pointsensor",
		Special = "kraken",
		Skin = 0,
	},
	{
		ClassName = "weapon_sploosh_o_matic_7",
		Sub = "splatbomb",
		Special = "inkzooka",
		Skin = 2,
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .007,					-- Ink consumption per fire[-]
	Damage				= .38,					-- Maximum damage[-]
	MinDamage			= .19,					-- Minimum damage[-]
	InkRadius			= 24,					-- Painting radius[Splatoon units]
	MinRadius			= 19,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,					-- Painting radius[Splatoon units]
	SplashPatterns		= 4,					-- Paint patterns[-]
	SplashNum			= 1.5,					-- Number of splashes[-]
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
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 2,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 6,					-- Start decreasing damage[frames]
	},
})
