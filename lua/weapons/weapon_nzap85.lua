
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Zap"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/n_zap/n_zap.mdl"
SWEP.Sub = "splatbomb"
SWEP.Special = "echolocator"
SWEP.Variations = {
	{
		ClassName = "weapon_nzap89",
		Sub = "sprinkler",
		Special = "inkstrike",
		Skin = 3,
	},
	{
		ClassName = "weapon_nzap83",
		Sub = "pointsensor",
		Special = "kraken",
		Skin = 6,
	},
}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,						-- false to semi-automatic
	Recoil				= .2,						-- Viewmodel recoil intensity[-]
	TakeAmmo			= .008,						-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(23.5, 0, 4.75),	-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .28,						-- Maximum damage[-]
	MinDamage			= .14,						-- Minimum damage[-]
	InkRadius			= 19.20000076,				-- Painting radius[Splatoon units]
	MinRadius			= 18,						-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,						-- Painting radius[Splatoon units]
	SplashPatterns		= 11,						-- Paint patterns[-]
	SplashNum			= 1.5,						-- Number of splashes[-]
	SplashInterval		= 110,						-- Make an interval on each splash[Splatoon units]
	Spread				= 12,						-- Aim cone[deg]
	SpreadJump			= 18,						-- Aim cone while jumping[deg]
	SpreadBias			= .25,						-- Aim cone random component[deg]
	MoveSpeed			= .72,						-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,						-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,						-- Change hold type[frames]
		Fire			= 5,						-- Fire rate[frames]
		Reload			= 20,						-- Start reloading after firing weapon[frames]
		Crouch			= 6,						-- Cannot crouch for some frames after firing[frames]
		Straight		= 4,						-- Ink goes without gravity[frames]
		MinDamage		= 15,						-- Deals minimum damage[frames]
		DecreaseDamage	= 8,						-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(10, -2, 0)},
	["ValveBiped.Bip01_L_Finger02"] = {angle = Angle(-15, 0, 0)},
	["ValveBiped.Bip01_L_Finger1"] = {angle = Angle(-30, 0, 0)},
	["ValveBiped.Bip01_L_Finger11"] = {angle = Angle(0, -10, 0)},
	["ValveBiped.Bip01_L_Finger12"] = {angle = Angle(0, -20, 0)},
	["ValveBiped.Bip01_L_Finger2"] = {angle = Angle(-10, -10, 0)},
	["ValveBiped.Bip01_L_Finger21"] = {angle = Angle(0, -10, 0)},
	["ValveBiped.Bip01_L_Finger22"] = {angle = Angle(0, -20, 0)},
	["ValveBiped.Bip01_L_Finger31"] = {angle = Angle(0, -10, 0)},
	["ValveBiped.Bip01_L_Finger32"] = {angle = Angle(0, -20, 0)},
	["ValveBiped.Bip01_L_Finger42"] = {angle = Angle(0, -10, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(0, -2.5, 0),
		angle = Angle(0, -8, 0),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(3.5, -24.3, -7.2),
	angle = Angle(12.736, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
})
