
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(0, 0, 0)
SWEP.ADSOffset = Vector(-5, 0, 2)
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
	DamageClose			= 1.25,		-- Damage within close range[-]
	DamageMiddle		= .6,		-- Damage within medium range[-]
	DamageFar			= .5,		-- Damage within far range[-]
	DamageWallMul		= .5,		-- Damage multiplier for hitting wall[-]
	ColRadiusClose		= 5,		-- Radius recognized as close range[Splatoon units]
	ColRadiusMiddle		= 15,		-- Radius recognized as middle range[Splatoon units]
	ColRadiusFar		= 35,		-- Radius recognized as far range[Splatoon units]
	ColRadiusWallMul	= .5,       -- Radius multiplier for hitting wall[-]
	InkRadius			= 32,		-- Painting radius[Splatoon units]
	InkRadiusWall		= 18,		-- Painting radius when ink hit on wall[Splatoon units]
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
		Explosion		= 15,		-- Time to detonate[frames]
		PreFire			= 10,		-- Time between trigger and fire[frames]
		PreFireSquid	= 15,		-- Time between trigger and fire, if squid[frames]
		PostFire		= 30,		-- Time after fire[frames]
		Fire			= 60,		-- Fire rate[frames]
		Reload			= 50,		-- Start reloading after firing weapon[frames]
		Crouch			= 30,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 11,		-- Ink goes without gravity[frames]
		MinDamage		= 10,		-- Deals minimum damage[frames]
		DecreaseDamage	= 15,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
