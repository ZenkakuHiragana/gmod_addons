
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.52"
SWEP.ChargeSound = {"SplatoonSWEPs.HydraSplatling", "SplatoonSWEPs.HydraSplatling2", "SplatoonSWEPs.HydraSplatlingFull"}
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
	Recoil				= .2,			-- Viewmodel recoil intensity[-]
	TakeAmmo			= .35,			-- Ink consumption per fire[-]
	EmptyChargeMul		= 3,			-- When ink tank is empty, charging time increases[x times]
	Damage				= .28,			-- Maximum damage[-]
	MinDamage			= .14,			-- Minimum damage[-]
	InkRadius			= 19.2,			-- Painting radius[Splatoon units]
	MinRadius			= 18,			-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,			-- Painting radius[Splatoon units]
	SplashPatterns		= 8 * 1.5,		-- Paint patterns[-]  WORKAROUND - 1.5x as many as original value.
	SplashNum			= 1,			-- Number of splashes[-]
	SplashInterval		= 235,			-- Make an interval on each splash[Splatoon units]
	Spread				= 3,			-- Aim cone[deg]
	SpreadJump			= 6,			-- Aim cone while jumping[deg]
	SpreadVelocity		= .14,			-- Ink initial velocity random[Splatoon units/frame]
	SpreadBias			= .3,			-- Aim cone random bias[-]
	SpreadBiasStep		= .02,			-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .3,			-- Aim cone random bias while jumping[-]
	SpreadBiasVelocity	= .2,			-- Ink initial velocity random bias[-]
	MoveSpeed			= .6,			-- Walk speed while shooting[Splatoon units/frame]
	MoveSpeedCharge		= .4,			-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul				= .6,			-- Jump power multiplier when fully charged[-]
	MinVelocity			= 10.5,			-- Ink initial velocity at minimum charge[Splatoon units/frame]
	MediumVelocity		= 24,			-- Ink initial velocity at medium charge[Splatoon units/frame]
	InitVelocity		= 24,			-- Ink initial velocity at maximum charge[Splatoon units/frame]
	InkScale			= 1.2,			-- Ink size multiplier[-]
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
		MaxCharge		= {108, 135},	-- Time between pressing MOUSE1 and being fully charged[frames]
		FireDuration	= {108, 216},	-- Splatling spin-up duration[frame]
	},
})
