
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Dual"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/squelcher/squelcher.mdl"
SWEP.Sub = "splatbomb"
SWEP.Special = "echolocator"
SWEP.Variations = {{
	ClassName = "weapon_dualsquelcher_custom",
	Sub = "squidbeakon",
	Special = "killerwail",
	Bodygroup = {1},
}}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .012,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(42, 0, 4.3),	-- Thirdperson muzzle position in local coord.
	Damage				= .28,					-- Maximum damage[-]
	MinDamage			= .14,					-- Minimum damage[-]
	InkRadius			= 21,					-- Painting radius[Splatoon units]
	MinRadius			= 18.5,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13,					-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns
	SplashNum			= 2,					-- Number of splashes
	SplashInterval		= 105,					-- Make an interval on each splash[Splatoon units]
	Spread				= 4,					-- Aim cone[deg]
	SpreadJump			= 12,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .5,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 6,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Can't crouch for some frames after firing
		Straight		= 6,					-- Ink goes without gravity[frames]
		MinDamage		= 18,					-- Deals minimum damage[frames]
		DecreaseDamage	= 9,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(7, -20, 0)},
	["ValveBiped.Bip01_L_Finger3"] = {angle = Angle(0, 6, 0)},
	["ValveBiped.Bip01_L_Finger41"] = {angle = Angle(0, 20, 0)},
	["ValveBiped.Bip01_L_Finger42"] = {angle = Angle(0, 20, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-3, -3.5, -2.5),
		angle = Angle(0, -8, 1),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(3.7, -24.3, -7.2),
	angle = Angle(13, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
	skin = 1,
})

ss:SetWorldModel(SWEP, {
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
	skin = 1,
})
