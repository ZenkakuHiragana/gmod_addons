
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Jet"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/squelcher/squelcher.mdl"
SWEP.ShowSplashRing = true -- Muzzleflash effect
SWEP.Sub = "splashwall"
SWEP.Special = "inkstrike"
SWEP.Variations = {{
	ClassName = "weapon_jetsquelcher_custom",
	Sub = "burstbomb",
	Special = "kraken",
	Bodygroup = {1},
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .017,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(42, 0, 4.3),	-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .31,					-- Maximum damage[-]
	MinDamage			= .155,					-- Minimum damage[-]
	InkRadius			= 19.20000076,			-- Painting radius[Splatoon units]
	MinRadius			= 18,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,					-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns[-]
	SplashNum			= 3,					-- Number of splashes[-]
	SplashInterval		= 85,					-- Make an interval on each splash[Splatoon units]
	Spread				= 3,					-- Aim cone[deg]
	SpreadJump			= 10,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .40000001,			-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 8,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 8,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 11,					-- Start decreasing damage[frames]
	},
})
