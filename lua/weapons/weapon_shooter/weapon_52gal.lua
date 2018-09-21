
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(0, 0, 0)
SWEP.ADSOffset = Vector(-5, 0, 1.8)
SWEP.ShootSound = "SplatoonSWEPs.52"
SWEP.Sub = "splashwall"
SWEP.Special = "killerwail"
SWEP.Variations = {{
	Customized = true,
	ClassName = "weapon_52gal_deco",
	Sub = "seeker",
	Special = "inkstrike",
	Skin = 1,
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .012,		-- Ink consumption per fire[-]
	Damage				= .52,		-- Maximum damage[-]
	MinDamage			= .26,		-- Minimum damage[-]
	InkRadius			= 21,		-- Painting radius[Splatoon units]
	MinRadius			= 18.5,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.5,		-- Painting radius[Splatoon units]
	SplashPatterns		= 5,		-- Paint patterns[-]
	SplashNum			= 3,		-- Number of splashes[-]
	SplashInterval		= 50,		-- Make an interval on each splash[Splatoon units]
	Spread				= 6,		-- Aim cone[deg]
	SpreadJump			= 15,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random bias[-]
	SpreadBiasStep		= .12,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .6,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 9,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
