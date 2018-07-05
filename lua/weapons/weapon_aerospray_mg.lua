
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Aerospray"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/aerospray/aerospray.mdl"
SWEP.Sub = "seeker"
SWEP.Special = "inkzooka"
SWEP.Variations = {
	{
		ClassName = "weapon_aerospray_rg",
		Sub = "inkmine",
		Special = "inkstrike",
		Skin = 2,
	},
	{
		ClassName = "weapon_aerospray_pg",
		Sub = "burstbomb",
		Special = "kraken",
		Skin = 4,
	},
}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .005,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(20, 0, .6),	-- Thirdperson muzzle position in local coord.
	Damage				= .245,					-- Maximum damage[-]
	MinDamage			= .1225,				-- Minimum damage[-]
	InkRadius			= 22,					-- Painting radius[Splatoon units]
	MinRadius			= 19,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.5,					-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns
	SplashNum			= 1,					-- Number of splashes
	SplashInterval		= 117,					-- Make an interval on each splash[Splatoon units]
	Spread				= 12,					-- Aim cone[deg]
	SpreadJump			= 18,					-- Aim cone while jumping[deg]
	SpreadBias			= .4,					-- Aim cone random component[deg]
	MoveSpeed			= .72,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 4,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Can't crouch for some frames after firing
		Straight		= 3,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["Base"] = {pos = Vector(-30, 30, -30)},
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2.397, -2, 2)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-31, 25, 30),
		angle = Angle(0, -8, -2)
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(8, -26, -6),
	angle = Angle(13, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(11, 1, -4),
	angle = Angle(0, 10, 180),
})
