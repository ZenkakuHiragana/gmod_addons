
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.Aerospray"
SWEP.Sub = "seeker"
SWEP.Special = "inkzooka"
SWEP.Variations = {
	{
		ClassName = "weapon_aerospray_rg",
		Sub = "inkmine",
		Special = "inkstrike",
		Skin = 1,
	},
	{
		ClassName = "weapon_aerospray_pg",
		Sub = "burstbomb",
		Special = "kraken",
		Skin = 2,
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .005,		-- Ink consumption per fire[-]
	Damage				= .245,		-- Maximum damage[-]
	MinDamage			= .1225,	-- Minimum damage[-]
	InkRadius			= 22,		-- Painting radius[Splatoon units]
	MinRadius			= 19,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.5,		-- Painting radius[Splatoon units]
	SplashPatterns		= 8,		-- Paint patterns[-]
	SplashNum			= 1,		-- Number of splashes[-]
	SplashInterval		= 117,		-- Make an interval on each splash[Splatoon units]
	Spread				= 12,		-- Aim cone[deg]
	SpreadJump			= 18,		-- Aim cone while jumping[deg]
	SpreadBias			= .4,		-- Aim cone random component[deg]
	MoveSpeed			= .72,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 4,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 3,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
	},
})
