
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(0, 0, 0)
SWEP.ADSOffset = Vector(-3.5, 0, 2.5)
SWEP.ShootSound = "SplatoonSWEPs.SplattershotPro"
SWEP.Sub = "splatbomb"
SWEP.Special = "inkstrike"
SWEP.Variations = {
	{
		ClassName = "weapon_splattershotpro_forge",
		Sub = "pointsensor",
		Special = "inkzooka",
		Skin = 1,
	},
	{
		ClassName = "weapon_splattershotpro_berry",
		Sub = "suctionbomb",
		Special = "bombrush",
		Skin = 2,
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .02,		-- Ink consumption per fire[-]
	Damage				= .42,		-- Maximum damage[-]
	MinDamage			= .21,		-- Minimum damage[-]
	InkRadius			= 19.2,		-- Painting radius[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12.5,		-- Painting radius[Splatoon units]
	SplashPatterns		= 8,		-- Paint patterns[-]
	SplashNum			= 3,		-- Number of splashes[-]
	SplashInterval		= 70,		-- Make an interval on each splash[Splatoon units]
	Spread				= 3,		-- Aim cone[deg]
	SpreadJump			= 12,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random bias[-]
	SpreadBiasStep		= .1,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .5,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 8,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 6,		-- Ink goes without gravity[frames]
		MinDamage		= 18,		-- Deals minimum damage[frames]
		DecreaseDamage	= 9,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
