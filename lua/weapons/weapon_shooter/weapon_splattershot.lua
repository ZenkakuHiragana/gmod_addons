
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.Splattershot"
SWEP.Sub = "burstbomb"
SWEP.Special = "bombrush"
SWEP.Variations = {
	{
		ClassName = "weapon_splattershot_tentatek",
		Sub = "suctionbomb",
		Special = "inkzooka",
		Skin = 1,
	},
	{
		ClassName = "weapon_splattershot_wasabi",
		Sub = "splatbomb",
		Special = "inkstrike",
		Skin = 2,
	},
	{
		ClassName = "weapon_heroshot",
		ModelPath = "models/splatoonsweps/weapon_heroshot/",
	},
	{
		ClassName = "weapon_octoshot",
		ShootSound = "SplatoonSWEPs.Octoshot",
		ModelPath = "models/splatoonsweps/weapon_octoshot/",
		Skin = 1,
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
	SpreadBias			= .25,		-- Aim cone random component[deg]
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
	},
})
