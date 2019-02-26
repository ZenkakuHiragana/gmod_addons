
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(5, 0, 0)
SWEP.ADSOffset = Vector(-5, 0, 3.8)
SWEP.ShootSound = "SplatoonSWEPs.H-3"
SWEP.Special = "echolocator"
SWEP.Sub = "suctionbomb"
SWEP.Variations = {
	{
		Bodygroup = {[0] = 1},
		Customized = true,
		Special = "inkzooka",
		Sub = "pointsensor",
		Suffix = "d",
	},
	{
		Bodygroup = {[0] = 2},
		SheldonsPicks = true,
		Special = "bubbler",
		Sub = "splashwall",
		Suffix = "cherry",
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= false,	-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .016,		-- Ink consumption per fire[-]
	Damage				= .41,		-- Maximum damage[-]
	MinDamage			= .205,		-- Minimum damage[-]
	InkRadius			= 22,		-- Painting radius[Splatoon units]
	MinRadius			= 22,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 14.5,		-- Painting radius[Splatoon units]
	SplashPatterns		= 5,		-- Paint patterns[-]
	SplashNum			= 3.5,		-- Number of splashes[-]
	SplashInterval		= 54,		-- Make an interval on each splash[Splatoon units]
	Spread				= 1,		-- Aim cone[deg]
	SpreadJump			= 6,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random component[deg]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .45,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = { -- Crouch delay, Nozzlenose cooldown: mRepeatFrame * 3 + mTripleShotSpan)
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 5,		-- Fire rate[frames]
		TripleShot		= 20,		-- Nozzlenose cooldown[frames]
		Reload			= 30,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 5,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
