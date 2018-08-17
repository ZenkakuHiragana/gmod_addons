
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.H-3"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/nozzlenose/nozzlenose.mdl"
SWEP.ShowMuzzleMist = true -- Muzzleflash effect
SWEP.Sub = "suctionbomb"
SWEP.Special = "echolocator"
SWEP.Variations = {
	{
		ClassName = "weapon_h3nozzlenose_d",
		Sub = "pointsensor",
		Special = "inkzooka",
		Bodygroup = {[0] = 1},
	},
	{
		ClassName = "weapon_h3nozzlenose_cherry",
		Sub = "splashwall",
		Special = "bubbler",
		Bodygroup = {[0] = 2},
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= false,				-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .016,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(40, 0, 12),	-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .41,					-- Maximum damage[-]
	MinDamage			= .205,					-- Minimum damage[-]
	InkRadius			= 22,					-- Painting radius[Splatoon units]
	MinRadius			= 22,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 14.5,					-- Painting radius[Splatoon units]
	SplashPatterns		= 5,					-- Paint patterns[-]
	SplashNum			= 3.5,					-- Number of splashes[-]
	SplashInterval		= 54,					-- Make an interval on each splash[Splatoon units]
	Spread				= 1,					-- Aim cone[deg]
	SpreadJump			= 6,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .44999999,			-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = { -- Crouch delay, Nozzlenose cooldown: mRepeatFrame * 3 + mTripleShotSpan)
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 5,					-- Fire rate[frames]
		TripleShot		= 20,					-- Nozzlenose cooldown[frames]
		Reload			= 30,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 5,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})
