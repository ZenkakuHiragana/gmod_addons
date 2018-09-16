
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
local ScopePos = Vector(-5, 5.98, 1.13)
SWEP.ShootSound = "SplatoonSWEPs.SplatCharger"
SWEP.ShootSound2 = "SplatoonSWEPs.SplatChargerFull"
SWEP.ScopePos = Vector(-5, 6, 2.2)	-- Scoped viewmodel position[Hammer units]
SWEP.ScopeAng = Angle()				-- Scoped viewmodel angles[deg]
SWEP.RTScopeNum = 10				-- Submaterial number for RT scope option.
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
		RTScopeNum = 11,
	},
	{
		ClassName = "weapon_herocharger",
		ScopePos = Vector(-5, 6.03, .2),
		SharedThink = Either(SERVER, nil, function(self)
			ss.ProtectedCall(self.BaseClass.SharedThink, self)
			self.Skin = self:GetNWInt("Level", ss.Options[self.Base][self.ClassName].Level)
		end),
	},
	{
		ClassName = "weapon_splatterscope",
		ScopePos = ScopePos,
		Bodygroup = {3},
		Scoped = true,
	},
	{
		ClassName = "weapon_splatterscope_kelp",
		ScopePos = ScopePos,
		Sub = "sprinkler",
		Special = "killerwail",
		Bodygroup = {4},
		Scoped = true,
	},
	{
		ClassName = "weapon_splatterscope_bento",
		ScopePos = ScopePos,
		Sub = "splashwall",
		Special = "echolocator",
		Bodygroup = {5},
		Skin = 1,
		Scoped = true,
		RTScopeNum = 11,
	},
}

ss.SetPrimary(SWEP, {
	MinRange					= 90,	-- Minimum distance [Splatoon units]
	MaxRange					= 250,	-- Maximum distance before fully charged [Splatoon units]
	FullRange					= 250,	-- Distance when fully charged [Splatoon units]
	EmptyChargeMul				= 3,	-- When ink tank is empty, charging time increases[x times]
	MinVelocity					= 12,	-- Initial velocity at minimum charge[Splatoon units/frame]
	MaxVelocity					= 48,	-- Initial velocity at maximum charge[Splatoon units/frame]
	MinDamage					= .4,	-- Minimum damage[-]
	MaxDamage					= 1,	-- Maximum damage before fully chaged[-]
	FullDamage					= 1.6,	-- Damage at maximum charge[-]
	MinColRadius				= 1,	-- Minimum collision radius[Splatoon units]
	MaxColRadius				= 1,	-- Maximum collision radius[Splatoon units]
	MinWallPaintNum				= 0,	-- At minimum charge, number of draw calls to paint wall on hit[-]
	MaxWallPaintNum				= 8,	-- At maximum charge, number of draw calls to paint wall on hit[-]
	WallPaintChargeThreshold	= .54,	-- Lerp between 0 to this charge rate for wall painting.
	FootpaintChargeRate			= .166,	-- Required charge to paint on feet[Charge rate]
	TakeAmmo					= .18,	-- Ink consumption per full charged shot[-]
	MoveSpeed					= .2,	-- Walk speed while fully charged[Splatoon units/frame]
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
		MaxCharge				= 60,	-- Time between pressing MOUSE1 and being fully charged[frames]
		MinFreeze				= 1,	-- Delay time from ZR released to fire ink[frames]
		MaxFreeze				= 1,	-- 
	},
	Scope = {
		StartMove				= .5,	-- Start moving camera position at specific charge[-]
		EndMove					= 1,	-- End moving camera position at specific charge[-]
		CameraFOV				= 28,	-- Camera FOV[deg]
		PlayerAlpha				= .5,	-- Player becomes translucent at specific charge[-]
		PlayerInvisible			= .85,	-- Player becomes invisible at specific charge[-]
	},
})

function SWEP:HideRTScope(alpha)
	self.RTMaterial:SetVector("$envmaptint", ss.vector_one * alpha)
end
