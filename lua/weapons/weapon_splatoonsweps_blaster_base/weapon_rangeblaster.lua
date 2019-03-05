
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(0, 0, 0)
SWEP.ADSOffset = Vector(-5, 0, 1.8)
SWEP.ShootSound = "SplatoonSWEPs.96"
SWEP.Special = "inkstrike"
SWEP.Sub = "splashwall"
SWEP.Variations = {
	{
		Customized = true,
		Skin = 1,
		Special = "splatbomb",
		Sub = "kraken",
		Suffix = "custom",
	},
	{
		SheldonsPicks = true,
		Skin = 2,
		Special = "killerwail",
		Sub = "burstbomb",
		Suffix = "grim",
	}
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .1,		-- Ink consumption per fire[-]
	Damage				= 1.25,		-- Maximum damage[-]
	MinDamage			= 1.25,		-- Minimum damage[-]
	InkRadius			= 19.2,		-- Painting radius[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.5,		-- Painting radius[Splatoon units]
	SplashPatterns		= 1,		-- Paint patterns[-]
	SplashNum			= 9,		-- Number of splashes[-]
	SplashInterval		= 15,		-- Make an interval on each splash[Splatoon units]
	Spread				= 0,		-- Aim cone[deg]
	SpreadJump			= 10,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random component[deg]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .4,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 10.8,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 30,		-- Change hold type[frames]
		Fire			= 60,		-- Fire rate[frames]
		Reload			= 50,		-- Start reloading after firing weapon[frames]
		Crouch			= 30,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 11,		-- Ink goes without gravity[frames]
		MinDamage		= 10,		-- Deals minimum damage[frames]
		DecreaseDamage	= 15,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
