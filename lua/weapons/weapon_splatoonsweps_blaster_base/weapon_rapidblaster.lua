
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(5, 0, 0)
SWEP.ADSOffset = Vector(-5, 0, 4)
SWEP.ShootSound = "SplatoonSWEPs.Sploosh-o-matic"
SWEP.Special = "bubbler"
SWEP.Sub = "inkmine"
SWEP.Variations = {{
	Customized = true,
	Skin = 1,
	Special = "bombrush",
	Sub = "suctionbomb",
	Suffix = "deco",
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .08,		-- Ink consumption per fire[-]
	Damage				= .8,		-- Maximum damage[-]
	MinDamage			= .8,		-- Minimum damage[-]
	DamageClose			= .8,		-- Damage within close range[-]
	ColRadiusClose		= 5,		-- Radius recognized as close range[Splatoon units]
	DamageMiddle		= .5,		-- Damage within medium range[-]
	ColRadiusMiddle		= 10,		-- Radius recognized as middle range[Splatoon units]
	DamageFar			= .25,		-- Damage within far range[-]
	ColRadiusFar		= 35,		-- Radius recognized as far range[Splatoon units]
	InkRadius			= 19.2,		-- Painting radius[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 11,		-- Painting radius[Splatoon units]
	SplashPatterns		= 1,		-- Paint patterns[-]
	SplashNum			= 10,		-- Number of splashes[-]
	SplashInterval		= 15.4,		-- Make an interval on each splash[Splatoon units]
	Spread				= 0,		-- Aim cone[deg]
	SpreadJump			= 10,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random bias[-]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .55,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 12,		-- Ink initial velocity[Splatoon units/frame]
	Delay = {
		Aim				= 30,		-- Change hold type[frames]
		Explosion		= 15,		-- Time to detonate[frames]
		Fire			= 35,		-- Fire rate[frames]
		Reload			= 25,		-- Start reloading after firing weapon[frames]
		Crouch			= 30,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 11,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 15,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
