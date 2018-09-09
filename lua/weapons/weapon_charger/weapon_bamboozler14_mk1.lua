
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.Bamboozler"
SWEP.ShootSound2 = "SplatoonSWEPs.BamboozlerFull"
SWEP.ScopePos = Vector(-8.5, 6, 3)	-- Scoped viewmodel position[Hammer units]
SWEP.ScopeAng = Angle(2, 0, 0)		-- Scoped viewmodel angles[deg]
SWEP.Sub = "splashwall"
SWEP.Special = "killerwail"
SWEP.Variations = {
	{
		ClassName = "weapon_bamboozler14_mk2",
		Sub = "disruptor",
		Special = "echolocator",
		Bodygroup = {1},
	},
	{
		ClassName = "weapon_bamboozler14_mk3",
		Sub = "burstbomb",
		Special = "inkstrike",
		Bodygroup = {1},
		Skin = 1,
	},
}

ss.SetPrimary(SWEP, {
	MinRange					= 200,	-- Minimum distance [Splatoon units]
	MaxRange					= 200,	-- Maximum distance before fully charged [Splatoon units]
	FullRange					= 200,	-- Distance when fully charged [Splatoon units]
	EmptyChargeMul				= 5,	-- When ink tank is empty, charging time increases[x times]
	MinVelocity					= 40,	-- Initial velocity at minimum charge[Splatoon units/frame]
	MaxVelocity					= 40,	-- Initial velocity at maximum charge[Splatoon units/frame]
	MinDamage					= .3,	-- Minimum damage[-]
	MaxDamage					= .8,	-- Maximum damage before fully chaged[-]
	FullDamage					= .8,	-- Damage at maximum charge[-]
	MinColRadius				= 2,	-- Minimum collision radius[Splatoon units]
	MaxColRadius				= 2,	-- Maximum collision radius[Splatoon units]
	MinWallPaintNum				= 0,	-- At minimum charge, number of draw calls to paint wall on hit[-]
	MaxWallPaintNum				= 5,	-- At maximum charge, number of draw calls to paint wall on hit[-]
	WallPaintChargeThreshold	= 1,	-- Lerp between 0 to this charge rate for wall painting.
	FootpaintChargeRate			= 1.01,	-- Required charge to paint on feet[Charge rate]
	TakeAmmo					= .08,	-- Ink consumption per full charged shot[-]
	MoveSpeed					= .4,	-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul						= .7,	-- Jump power multiplier when fully charged[-]
	MaxChargeSplashPaintRadius	= 12,	-- Painting radius at maximum charge[Splatoon units]
	MinChargeSplashPaintRadius	= .7,	-- Painting radius at minimum charge[x times of MaxChargeSplashPaintRadius]
	LastSplashRadiusMul			= 1.5,	-- Ratio between the last splash on ground and others[x times]
	MinSplashRatio				= 3.5,	-- Ground drop ratio at minimum charge[-]
	MaxSplashRatio				= 3,	-- Ground drop ratio at maximum charge[-]
	SplashPatterns				= 3,	-- Paint patterns[-]
	MinSplashInterval			= 3,	-- Paint interval coeff. at minimum charge[-]
	MaxSplashInterval			= 1.5,	-- Paint interval coeff. at maximum charge[-]
	Delay = {
		Aim						= 20,	-- Change hold type[frames]
		Reload					= 20,	-- Start reloading after firing weapon[frames]
		Crouch					= 6,	-- Cannot crouch for some frames after firing[frames]
		MinCharge				= 8,	-- Time between pressing MOUSE1 and beginning of charge[frames]
		MaxCharge				= 20,	-- Time between pressing MOUSE1 and being fully charged[frames]
		MinFreeze				= 1,	-- Delay time from ZR released to fire ink[frames]
		MaxFreeze				= 1,	-- 
	},
	Scope = {
		StartMove				= 0,	-- Start moving camera position at specific charge[-].
		EndMove					= 1,	-- End moving camera position at specific charge[-]
		CameraFOV				= 28,	-- Camera FOV[deg]
		PlayerAlpha				= .5,	-- Player becomes translucent at specific charge[-]
		PlayerInvisible			= .85,	-- Player becomes invisible at specific charge[-]
	},
})
