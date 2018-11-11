
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.52"
SWEP.ShootSound2 = SWEP.ShootSound
SWEP.Sub = "pointsensor"
SWEP.Special = "bubbler"
SWEP.Variations = {{
	Customized = true,
	ClassName = "weapon_hydrasplatling_custom",
	Sub = "inkmine",
	Special = "inkzooka",
	Bodygroup = {1},
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .025,		-- Ink consumption per fire[-]
	Damage				= .62,		-- Maximum damage[-]
	MinDamage			= .31,		-- Minimum damage[-]
	InkRadius			= 21,		-- Painting radius[Splatoon units]
	MinRadius			= 18.5,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 14.5,		-- Painting radius[Splatoon units]
	SplashPatterns		= 5,		-- Paint patterns[-]
	SplashNum			= 4,		-- Number of splashes[-]
	SplashInterval		= 50,		-- Make an interval on each splash[Splatoon units]
	Spread				= 4.5,		-- Aim cone[deg]
	SpreadJump			= 12,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random component[deg]
	SpreadBiasStep		= .2,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .4,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 3,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 6,		-- Ink goes without gravity[frames]
		MinDamage		= 18,		-- Deals minimum damage[frames]
		DecreaseDamage	= 9,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
