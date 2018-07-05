
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Jet"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/squelcher/squelcher.mdl"
SWEP.Sub = "splashwall"
SWEP.Special = "inkstrike"
SWEP.Variations = {{
	ClassName = "weapon_jetsquelcher_custom",
	Sub = "burstbomb",
	Special = "kraken",
	Bodygroup = {1},
}}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .017,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(42, 0, 4.3),	-- Thirdperson muzzle position in local coord.
	Damage				= .31,					-- Maximum damage[-]
	MinDamage			= .155,					-- Minimum damage[-]
	InkRadius			= 19.20000076,			-- Painting radius[Splatoon units]
	MinRadius			= 18,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,					-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns
	SplashNum			= 3,					-- Number of splashes
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
		Crouch			= 6,					-- Can't crouch for some frames after firing
		Straight		= 8,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 11,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["Base"] = {
		pos = Vector(-33, 27, -30.5),
		angle = Angle(1, 0, 0),
	},
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(7, -27, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-30, 27, 30),
		angle = Angle(0, -8, 0),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(3.7, -24.3, -7.2),
	angle = Angle(13, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
})
