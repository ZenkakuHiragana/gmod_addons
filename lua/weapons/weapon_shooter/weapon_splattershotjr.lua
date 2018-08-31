
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.SplattershotJr"
SWEP.Sub = "splatbomb"
SWEP.Special = "bubbler"
SWEP.Variations = {{
	ClassName = "weapon_splattershotjr_custom",
	Sub = "disruptor",
	Special = "echolocator",
	Bodygroup = {1},
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .005,					-- Ink consumption per fire[-]
	Damage				= .245,					-- Maximum damage[-]
	MinDamage			= .1225,				-- Minimum damage[-]
	InkRadius			= 21,					-- Painting radius[Splatoon units]
	MinRadius			= 18.5,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.19999981,			-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns[-]
	SplashNum			= 1,					-- Number of splashes[-]
	SplashInterval		= 117,					-- Make an interval on each splash[Splatoon units]
	Spread				= 12,					-- Aim cone[deg]
	SpreadJump			= 18,					-- Aim cone while jumping[deg]
	SpreadBias			= .4,					-- Aim cone random component[deg]
	MoveSpeed			= .72000003,			-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 5,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 3,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})