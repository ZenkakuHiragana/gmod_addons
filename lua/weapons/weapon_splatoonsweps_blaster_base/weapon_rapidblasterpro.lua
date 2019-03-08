
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(5, 0, 0)
SWEP.ADSOffset = Vector(-5, 0, 4)
SWEP.ShootSound = "SplatoonSWEPs.Zap"
SWEP.Special = "inkzooka"
SWEP.Sub = "seeker"
SWEP.Variations = {{
	Customized = true,
	Skin = 1,
	Special = "killerwail",
	Sub = "disruptor",
	Suffix = "deco",
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .1,		-- Ink consumption per fire[-]
	Damage				= .8,		-- Maximum damage[-]
	MinDamage			= .8,		-- Minimum damage[-]
	DamageClose			= .8,		-- Damage within close range[-]
	DamageMiddle		= .5,		-- Damage within medium range[-]
	DamageFar			= .25,		-- Damage within far range[-]
	DamageWallMul		= .5,		-- Damage multiplier for hitting wall[-]
	ColRadiusClose		= 5,		-- Radius recognized as close range[Splatoon units]
	ColRadiusMiddle		= 10,		-- Radius recognized as middle range[Splatoon units]
	ColRadiusFar		= 35,		-- Radius recognized as far range[Splatoon units]
	ColRadiusWallMul	= .5,       -- Radius multiplier for hitting wall[-]
	InkRadius			= 28,		-- Painting radius[Splatoon units]
	InkRadiusBlastMax	= 23,		-- Maximum painting radius by explosion[Splatoon units]
	InkRadiusBlastMin	= 18,		-- Minimum painting radius by explosion[Splatoon units]
	InkRadiusGround		= 18,		-- Painting radius when ink hit on ground[Splatoon units]
	InkRadiusWall		= 17,		-- Painting radius when ink hit on wall[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 11.5,		-- Painting radius[Splatoon units]
	SplashPatterns		= 1,		-- Paint patterns[-]
	SplashNum			= 12,		-- Number of splashes[-]
	SplashInterval		= 15,		-- Make an interval on each splash[Splatoon units]
	Spread				= 0,		-- Aim cone[deg]
	SpreadJump			= 10,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random bias[-]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .5,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 14,		-- Ink initial velocity[Splatoon units/frame]
	Delay = {
		Aim				= 30,		-- Change hold type[frames]
		Explosion		= 15,		-- Time to detonate[frames]
		PreFire			= 8,		-- Time between trigger and fire[frames]
		PreFireSquid	= 17,		-- Time between trigger and fire, if squid[frames]
		PostFire		= 26,		-- Time after fire[frames]
		Fire			= 40,		-- Fire rate[frames]
		Reload			= 30,		-- Start reloading after firing weapon[frames]
		Crouch			= 30,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 11,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 15,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
