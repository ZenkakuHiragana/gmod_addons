
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(0, 0, 0)
SWEP.ADSOffset = Vector(0, 0, 1.5)
SWEP.ShootSound = "SplatoonSWEPs.Splattershot"
SWEP.Special = "bombrush"
SWEP.Sub = "burstbomb"
SWEP.Variations = {
	{
		Customized = true,
		Skin = 1,
		Special = "inkzooka",
		Sub = "suctionbomb",
		Suffix = "tentatek",
	},
	{
		SheldonsPicks = true,
		Skin = 2,
		Special = "inkstrike",
		Sub = "splatbomb",
		Suffix = "wasabi",
	},
	{
		ClassName = "heroshot",
		IsHeroShot = true,
	},
	{
		ClassName = "octoshot",
		IsOctoShot = true,
		ShootSound = "SplatoonSWEPs.Octoshot",
		Skin = 1,
		Special = "inkzooka",
		Sub = "suctionbomb",
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .009,		-- Ink consumption per fire[-]
	Damage				= .36,		-- Maximum damage[-]
	MinDamage			= .18,		-- Minimum damage[-]
	InkRadius			= 19.2,		-- Painting radius[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13,		-- Painting radius[Splatoon units]
	SplashPatterns		= 5,		-- Paint patterns[-]
	SplashNum			= 2,		-- Number of splashes[-]
	SplashInterval		= 75,		-- Make an interval on each splash[Splatoon units]
	Spread				= 6,		-- Aim cone[deg]
	SpreadJump			= 15,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random bias[-]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .72,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 6,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
