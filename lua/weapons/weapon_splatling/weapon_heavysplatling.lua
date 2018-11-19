
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.Zap"
SWEP.ChargeSound = {"SplatoonSWEPs.HeavySplatling", "SplatoonSWEPs.HeavySplatling2", "SplatoonSWEPs.HeavySplatlingFull"}
SWEP.Sub = "splashwall"
SWEP.Special = "inkstrike"
SWEP.Variations = {
	{
		Customized = true,
		ClassName = "weapon_heavysplatling_deco",
		Sub = "pointsensor",
		Special = "kraken",
		Skin = 1,
	},
	{
		SheldonsPicks = true,
		ClassName = "weapon_heavysplatling_remix",
		Sub = "sprinkler",
		Special = "killerwail",
		Skin = 2,
	},
}

ss.SetPrimary(SWEP, {
	Recoil				= .2,			-- Viewmodel recoil intensity[-]
	TakeAmmo			= .25,			-- Ink consumption per fire[-]
	EmptyChargeMul		= 4,			-- When ink tank is empty, charging time increases[x times]
	Damage				= .28,			-- Maximum damage[-]
	MinDamage			= .14,			-- Minimum damage[-]
	InkRadius			= 19.2,			-- Painting radius[Splatoon units]
	MinRadius			= 18,			-- Minimum painting radius[Splatoon units]
	SplashRadius		= 14,			-- Painting radius[Splatoon units]
	SplashPatterns		= 8 * 1.5,		-- Paint patterns[-]  WORKAROUND - 1.5x as many as original value.
	SplashNum			= 1,			-- Number of splashes[-]
	SplashInterval		= 200,			-- Make an interval on each splash[Splatoon units]
	Spread				= 3.5,			-- Aim cone[deg]
	SpreadJump			= 7,			-- Aim cone while jumping[deg]
	SpreadVelocity		= .12,			-- Ink initial velocity random[Splatoon units/frame]
	SpreadBias			= .3,			-- Aim cone random bias[-]
	SpreadBiasStep		= .02,			-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .3,			-- Aim cone random bias while jumping[-]
	SpreadBiasVelocity	= .2,			-- Ink initial velocity random bias[-]
	MoveSpeed			= .7,			-- Walk speed while shooting[Splatoon units/frame]
	MoveSpeedCharge		= .55,			-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul				= .8,			-- Jump power multiplier when fully charged[-]
	MinVelocity			= 10.5,			-- Ink initial velocity at minimum charge[Splatoon units/frame]
	MediumVelocity		= 21,			-- Ink initial velocity at medium charge[Splatoon units/frame]
	InitVelocity		= 21,			-- Ink initial velocity at maximum charge[Splatoon units/frame]
	InkScale			= 1.4,			-- Ink size multiplier[-]
	Delay = {
		Aim				= 20,			-- Change hold type[frames]
		Fire			= 4,			-- Fire rate[frames]
		Reload			= 40,			-- Start reloading after firing weapon[frames]
		Crouch			= 6,			-- Cannot crouch for some frames after firing[frames]
		Straight		= 8,			-- Ink goes without gravity[frames]
		MinDamage		= 8,			-- Deals minimum damage[frames]
		DecreaseDamage	= 11,			-- Start decreasing damage[frames]
		SpreadJump		= 45,			-- Time to get spread angle back to normal[frames]
		MinCharge		= 8,			-- Time between pressing MOUSE1 and beginning of charge[frames]
		MaxCharge		= {50, 75},		-- Time between pressing MOUSE1 and being fully charged[frames]
		FireDuration	= {72, 144},	-- Splatling spin-up duration[frame]
	},
})
