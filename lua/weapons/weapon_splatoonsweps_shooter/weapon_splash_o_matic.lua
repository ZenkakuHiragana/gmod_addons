
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(0, 0, 0)
SWEP.ADSOffset = Vector(0, 0, 1.5)
SWEP.ShootSound = "SplatoonSWEPs.Splash-o-matic"
SWEP.Special = "bombrush"
SWEP.Sub = "suctionbomb"
SWEP.Variations = {
	{
		Bodygroup = {1},
		Customized = true,
		Special = "inkzooka",
		Sub = "burstbomb",
		Suffix = "neo",
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .007,		-- Ink consumption per fire[-]
	Damage				= .26,		-- Maximum damage[-]
	MinDamage			= .13,		-- Minimum damage[-]
	InkRadius			= 22,		-- Painting radius[Splatoon units]
	MinRadius			= 19,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.2,		-- Painting radius[Splatoon units]
	SplashPatterns		= 7,		-- Paint patterns[-]
	SplashNum			= 1.5,		-- Number of splashes[-]
	SplashInterval		= 80,		-- Make an interval on each splash[Splatoon units]
	Spread				= 3,		-- Aim cone[deg]
	SpreadJump			= 12,		-- Aim cone while jumping[deg]
	SpreadBias			= .4,		-- Aim cone random component[deg]
	SpreadBiasStep		= .1,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .72,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 5,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 3,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
