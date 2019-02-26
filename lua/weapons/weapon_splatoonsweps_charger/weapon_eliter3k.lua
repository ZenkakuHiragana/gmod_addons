
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.RTScopeNum = 4							-- Submaterial number for RT scope option.
SWEP.ScopeAng = Angle()						-- Scoped viewmodel angles [deg]
SWEP.ScopePos = Vector(-11.5, 3.1, 2.55)	-- Scoped viewmodel position [Hammer units]
SWEP.ShootSound = "SplatoonSWEPs.Eliter3K"
SWEP.ShootSound2 = "SplatoonSWEPs.Eliter3KFull"
SWEP.Special = "echolocator"
SWEP.Sub = "burstbomb"
SWEP.Variations = {
	{
		Bodygroup = {1},
		Customized = true,
		Special = "kraken",
		Sub = "squidbeakon",
		Suffix = "custom",
	},
	{
		Bodygroup = {[2] = 1},
		Scoped = true,
		Suffix = "scope",
	},
	{
		Bodygroup = {1, 1},
		Customized = true,
		Scoped = true,
		Special = "kraken",
		Sub = "squidbeakon",
		Suffix = "scope_custom",
	},
}

ss.SetPrimary(SWEP, {
	MinRange					= 90,	-- Minimum distance [Splatoon units]
	MaxRange					= 340,	-- Maximum distance before fully charged [Splatoon units]
	FullRange					= 340,	-- Distance when fully charged [Splatoon units]
	EmptyChargeMul				= 3,	-- When ink tank is empty, charging time increases[x times]
	MinVelocity					= 12,	-- Initial velocity at minimum charge[Splatoon units/frame]
	MaxVelocity					= 64,	-- Initial velocity at maximum charge[Splatoon units/frame]
	MinDamage					= .4,	-- Minimum damage[-]
	MaxDamage					= 1.2,	-- Maximum damage before fully chaged[-]
	FullDamage					= 1.8,	-- Damage at maximum charge[-]
	MinColRadius				= 1,	-- Minimum collision radius[Splatoon units]
	MaxColRadius				= 1,	-- Maximum collision radius[Splatoon units]
	MinWallPaintNum				= 0,	-- At minimum charge, number of draw calls to paint wall on hit[-]
	MaxWallPaintNum				= 8,	-- At maximum charge, number of draw calls to paint wall on hit[-]
	WallPaintChargeThreshold	= .324,	-- Lerp between 0 to this charge rate for wall painting.
	FootpaintChargeRate			= .1,	-- Required charge to paint on feet[Charge rate]
	TakeAmmo					= .3,	-- Ink consumption per full charged shot[-]
	MoveSpeed					= .15,	-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul						= .7,	-- Jump power multiplier when fully charged[-]
	MaxChargeSplashPaintRadius	= 18.5,	-- Painting radius at maximum charge[Splatoon units]
	MinChargeSplashPaintRadius	= .45,	-- Painting radius at minimum charge[x times of MaxChargeSplashPaintRadius]
	LastSplashRadiusMul			= 1.6,	-- Ratio between the last splash on ground and others[x times]
	MinSplashRatio				= 3,	-- Ground drop ratio at minimum charge[-]
	MaxSplashRatio				= 1,	-- Ground drop ratio at maximum charge[-]
	SplashPatterns				= 1,	-- Paint patterns[-]
	MinSplashInterval			= 1.32,	-- Paint interval coeff. at minimum charge[-]
	MaxSplashInterval			= 1.58,	-- Paint interval coeff. at maximum charge[-]
	Delay = {
		Aim						= 20,	-- Change hold type[frames]
		Reload					= 20,	-- Start reloading after firing weapon[frames]
		Crouch					= 6,	-- Cannot crouch for some frames after firing[frames]
		MinCharge				= 8,	-- Time between pressing MOUSE1 and beginning of charge[frames]
		MaxCharge				= 100,	-- Time between pressing MOUSE1 and being fully charged[frames]
		MinFreeze				= 1,	-- Delay time from ZR released to fire ink[frames]
		MaxFreeze				= 1,	-- 
	},
	Scope = {
		StartMove				= .5,	-- Start moving camera position at specific charge[-].
		EndMove					= 1,	-- End moving camera position at specific charge[-]
		CameraFOV				= 20,	-- Camera FOV[deg]
		PlayerAlpha				= .5,	-- Player becomes translucent at specific charge[-]
		PlayerInvisible			= .85,	-- Player becomes invisible at specific charge[-]
	},
})

function SWEP:HideRTScope(alpha)
	cam.Start2D()
	draw.NoTexture()
	surface.SetDrawColor(ColorAlpha(color_black, alpha * 225))
	surface.DrawRect(0, 0, 512, 512)
	cam.End2D()
end
