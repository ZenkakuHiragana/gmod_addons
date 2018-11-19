
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.Octoshot"
SWEP.ChargeSound = {"SplatoonSWEPs.MiniSplatling", "SplatoonSWEPs.MiniSplatling2", "SplatoonSWEPs.MiniSplatlingFull"}
SWEP.Sub = "suctionbomb"
SWEP.Special = "inkzooka"
SWEP.Variations = {
	{
		Customized = true,
		ClassName = "weapon_minisplatling_zink",
		Sub = "disruptor",
		Special = "bubbler",
		Skin = 1,
	},
	{
		SheldonsPicks = true,
		ClassName = "weapon_minisplatling_refurbished",
		Sub = "burstbomb",
		Special = "bombrush",
		Skin = 2,
	},
}

ss.SetPrimary(SWEP, {
	PaintNearDistance	= 10,			-- mPaintNearDistance[Splatoon units]
	Recoil				= .2,			-- Viewmodel recoil intensity[-]
	TakeAmmo			= .15,			-- Ink consumption per fire[-]
	EmptyChargeMul		= 6,			-- When ink tank is empty, charging time increases[x times]
	Damage				= .28,			-- Maximum damage[-]
	MinDamage			= .14,			-- Minimum damage[-]
	InkRadius			= 22,			-- Painting radius[Splatoon units]
	MinRadius			= 21,			-- Minimum painting radius[Splatoon units]
	SplashRadius		= 14,			-- Painting radius[Splatoon units]
	SplashPatterns		= 5 * 1.5,		-- Paint patterns[-]  WORKAROUND - 1.5x as many as original value.
	SplashNum			= 1.8,			-- Number of splashes[-]
	SplashInterval		= 85,			-- Make an interval on each splash[Splatoon units]
	Spread				= 4,			-- Aim cone[deg]
	SpreadJump			= 8,			-- Aim cone while jumping[deg]
	SpreadVelocity		= .1,			-- Ink initial velocity random[Splatoon units/frame]
	SpreadBias			= .3,			-- Aim cone random bias[-]
	SpreadBiasStep		= .02,			-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .3,			-- Aim cone random bias while jumping[-]
	SpreadBiasVelocity	= .2,			-- Ink initial velocity random bias[-]
	MoveSpeed			= .8,			-- Walk speed while shooting[Splatoon units/frame]
	MoveSpeedCharge		= .7,			-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul				= .9,			-- Jump power multiplier when fully charged[-]
	MinVelocity			= 10.5,			-- Ink initial velocity at minimum charge[Splatoon units/frame]
	MediumVelocity		= 15,			-- Ink initial velocity at medium charge[Splatoon units/frame]
	InitVelocity		= 15,			-- Ink initial velocity at maximum charge[Splatoon units/frame]
	InkScale			= 1,			-- Ink size multiplier[-]
	Delay = {
		Aim				= 20,			-- Change hold type[frames]
		Fire			= 4,			-- Fire rate[frames]
		Reload			= 30,			-- Start reloading after firing weapon[frames]
		Crouch			= 6,			-- Cannot crouch for some frames after firing[frames]
		Straight		= 8,			-- Ink goes without gravity[frames]
		MinDamage		= 8,			-- Deals minimum damage[frames]
		DecreaseDamage	= 11,			-- Start decreasing damage[frames]
		SpreadJump		= 45,			-- Time to get spread angle back to normal[frames]
		MinCharge		= 8,			-- Time between pressing MOUSE1 and beginning of charge[frames]
		MaxCharge		= {20, 30},		-- Time between pressing MOUSE1 and being fully charged[frames]
		FireDuration	= {36, 72},		-- Splatling spin-up duration[frame]
	},
})
