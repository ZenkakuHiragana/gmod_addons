
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(-2, 1.5, -45)
SWEP.ADSOffset = Vector(-5, 0, -0.7)
SWEP.IronSightsPos = {
	Vector(), -- right
	Vector(), -- left
	Vector(), -- top-right
	Vector(), -- top-left
	Vector(0, 6, -4.5), -- center
}
SWEP.ShootSound = "SplatoonSWEPs.SplattershotJr"
SWEP.Special = "inkzooka"
SWEP.Sub = "inkmine"
SWEP.Variations = {{
	Bodygroup = {1},
	Customized = true,
	Special = "bombrush",
	Sub = "splatbomb",
	Suffix = "neo",
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .06,		-- Ink consumption per fire[-]
	Damage				= 1.25,		-- Maximum damage[-]
	MinDamage			= 1.25,		-- Minimum damage[-]
	DamageClose			= 1.25,		-- Damage within close range[-]
	DamageMiddle		= .65,		-- Damage within medium range[-]
	DamageFar			= .5,		-- Damage within far range[-]
	DamageWallMul		= .5,		-- Damage multiplier for hitting wall[-]
	ColRadiusClose		= 5,		-- Radius recognized as close range[Splatoon units]
	ColRadiusMiddle		= 20,		-- Radius recognized as middle range[Splatoon units]
	ColRadiusFar		= 40,		-- Radius recognized as far range[Splatoon units]
	ColRadiusWallMul	= .5,       -- Radius multiplier for hitting wall[-]
	InkRadius			= 40,		-- Painting radius[Splatoon units]
	InkRadiusBlastMax	= 25,		-- Maximum painting radius by explosion[Splatoon units]
	InkRadiusBlastMin	= 20,		-- Minimum painting radius by explosion[Splatoon units]
	InkRadiusGround		= 24,		-- Painting radius when ink hit on ground[Splatoon units]
	InkRadiusWall		= 20,		-- Painting radius when ink hit on wall[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 14,		-- Painting radius[Splatoon units]
	SplashPatterns		= 1,		-- Paint patterns[-]
	SplashNum			= 6,		-- Number of splashes[-]
	SplashInterval		= 13,		-- Make an interval on each splash[Splatoon units]
	Spread				= 0,		-- Aim cone[deg]
	SpreadJump			= 10,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random bias[-]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .5,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 8.5,		-- Ink initial velocity[Splatoon units/frame]
	Delay = {
		Aim				= 30,		-- Change hold type[frames]
		Explosion		= 11,		-- Time to detonate[frames]
		PreFire			= 10,		-- Time between trigger and fire[frames]
		PreFireSquid	= 15,		-- Time between trigger and fire, if squid[frames]
		PostFire		= 30,		-- Time after fire[frames]
		Fire			= 40,		-- Fire rate[frames]
		Reload			= 30,		-- Start reloading after firing weapon[frames]
		Crouch			= 30,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 7,		-- Ink goes without gravity[frames]
		MinDamage		= 10,		-- Deals minimum damage[frames]
		DecreaseDamage	= 11,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
