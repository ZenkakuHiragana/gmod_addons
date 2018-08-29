
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.SplatCharger"
SWEP.ShootSound2 = "SplatoonSWEPs.SplatChargerFull"
SWEP.ModelPath = "models/splatoonsweps/weapon_splatcharger/"
SWEP.Sub = "splatbomb"
SWEP.Special = "bombrush"
SWEP.Variations = {
	{
		ClassName = "weapon_splatcharger_kelp",
		Sub = "sprinkler",
		Special = "killerwail",
		Bodygroup = {1},
	},
	{
		ClassName = "weapon_splatcharger_bento",
		Sub = "splashwall",
		Special = "echolocator",
		Bodygroup = {2},
		Skin = 1,
	},
	{
		ClassName = "weapon_splatterscope",
		Bodygroup = {3},
	},
	{
		ClassName = "weapon_splatterscope_kelp",
		Sub = "sprinkler",
		Special = "killerwail",
		Bodygroup = {4},
	},
	{
		ClassName = "weapon_splatterscope_bento",
		Sub = "splashwall",
		Special = "echolocator",
		Bodygroup = {5},
		Skin = 1,
	},
}

ss.SetPrimary(SWEP, {
	MinRange					= 90,						-- Minimum distance [Splatoon units]
	MaxRange					= 250,						-- Maximum distance before fully charged [Splatoon units]
	FullRange					= 250,						-- Distance when fully charged [Splatoon units]
	EmptyChargeMul				= 3,						-- When ink tank is empty, charging time increases[x times]
	MinVelocity					= 12,						-- Initial velocity at minimum charge[Splatoon units/frame]
	MaxVelocity					= 48,						-- Initial velocity at maximum charge[Splatoon units/frame]
	MinDamage					= .40000001,				-- Minimum damage[-]
	MaxDamage					= 1,						-- Maximum damage before fully chaged[-]
	FullDamage					= 1.60000002,				-- Damage at maximum charge[-]
	MinColRadius				= 1,						-- Minimum collision radius[Splatoon units]
	MaxColRadius				= 1,						-- Maximum collision radius[Splatoon units]
	MinWallPaintNum				= 0,						-- At minimum charge, number of draw calls to paint wall on hit[-]
	MaxWallPaintNum				= 8,						-- At maximum charge, number of draw calls to paint wall on hit[-]
	WallPaintChargeThreshold	= .54000002,				-- Lerp between 0 to this charge rate for wall painting.
	FootpaintChargeRate			= .16599999,				-- Required charge to paint on feet[Charge rate]
	TakeAmmo					= .18000001,				-- Ink consumption per full charged shot[-]
	MoveSpeed					= .2,						-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul						= .69999999,				-- Jump power multiplier when fully charged[-]
	MaxChargeSplashPaintRadius	= 18.5,						-- Painting radius at maximum charge[Splatoon units]
	MinChargeSplashPaintRadius	= .44999999,				-- Painting radius at minimum charge[x times of MaxChargeSplashPaintRadius]
	LastSplashRadiusMul			= 1.60000002,				-- Ratio between the last splash on ground and others[x times]
	MinSplashRatio				= 3,						-- Ground drop ratio at minimum charge[-]
	MaxSplashRatio				= 1,						-- Ground drop ratio at maximum charge[-]
	SplashPatterns				= 1,						-- Paint patterns[-]
	MinSplashInterval			= 1.32000005,				-- Paint interval coeff. at minimum charge[-]
	MaxSplashInterval			= 1.58000004,				-- Paint interval coeff. at maximum charge[-]
	Delay = {
		Aim						= 20,						-- Change hold type[frames]
		Reload					= 20,						-- Start reloading after firing weapon[frames]
		Crouch					= 6,						-- Cannot crouch for some frames after firing[frames]
		MinCharge				= 8,						-- Time between pressing MOUSE1 and beginning of charge[frames]
		MaxCharge				= 60,						-- Time between pressing MOUSE1 and being fully charged[frames]
		MinFreeze				= 1,						-- Delay time from ZR released to fire ink[frames]
		MaxFreeze				= 1,
	},
})
