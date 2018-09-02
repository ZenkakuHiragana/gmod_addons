
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.Zap"
SWEP.Sub = "splatbomb"
SWEP.Special = "echolocator"
SWEP.Variations = {
	{
		ClassName = "weapon_nzap89",
		Sub = "sprinkler",
		Special = "inkstrike",
		Skin = 1,
	},
	{
		ClassName = "weapon_nzap83",
		Sub = "pointsensor",
		Special = "kraken",
		Skin = 2,
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .008,		-- Ink consumption per fire[-]
	Damage				= .28,		-- Maximum damage[-]
	MinDamage			= .14,		-- Minimum damage[-]
	InkRadius			= 19.2,		-- Painting radius[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,		-- Painting radius[Splatoon units]
	SplashPatterns		= 11,		-- Paint patterns[-]
	SplashNum			= 1.5,		-- Number of splashes[-]
	SplashInterval		= 110,		-- Make an interval on each splash[Splatoon units]
	Spread				= 12,		-- Aim cone[deg]
	SpreadJump			= 18,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random component[deg]
	MoveSpeed			= .72,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 5,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
	},
})
