
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Splash-o-matic"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/splash_sploosh_o_matic/splash_sploosh_o_matic.mdl"
SWEP.Sub = "suctionbomb"
SWEP.Special = "bombrush"
SWEP.Variations = {
	{
		ClassName = "weapon_splash_o_matic_neo",
		Sub = "burstbomb",
		Special = "inkzooka",
		Bodygroup = {1},
	},
}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .007,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(20, 0, 7),		-- Thirdperson muzzle position in local coord.
	Damage				= .26,					-- Maximum damage[-]
	MinDamage			= .13,					-- Minimum damage[-]
	InkRadius			= 22,					-- Painting radius[Splatoon units]
	MinRadius			= 19,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.19999981,			-- Painting radius[Splatoon units]
	SplashPatterns		= 7,					-- Paint patterns
	SplashNum			= 1.5,					-- Number of splashes
	SplashInterval		= 80,					-- Make an interval on each splash[Splatoon units]
	Spread				= 3,					-- Aim cone[deg]
	SpreadJump			= 12,					-- Aim cone while jumping[deg]
	SpreadBias			= .4,					-- Aim cone random component[deg]
	MoveSpeed			= .72,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 5,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Can't crouch for some frames after firing
		Straight		= 3,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["Base"] = {pos = Vector(-30, 30, -30)},
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(7, -15, 0)},
	["ValveBiped.Bip01_L_Finger1"] = {angle = Angle(-20, -10, 0)},
	["ValveBiped.Bip01_L_Finger2"] = {angle = Angle(-10, -10, 0)},
	["ValveBiped.Bip01_L_Finger21"] = {angle = Angle(0, -25, 0)},
	["ValveBiped.Bip01_L_Finger22"] = {angle = Angle(0, 20, 0)},
	["ValveBiped.Bip01_L_Finger3"] = {angle = Angle(0, -20, 0)},
	["ValveBiped.Bip01_L_Finger4"] = {angle = Angle(5, -20, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-30, 27.5, 30),
		angle = Angle(0, -8, 0)
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(3.5, -23.2, -7.2),
	angle = Angle(13, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(3.4, 0.6, 0.5),
	angle = Angle(0, 10, 180),
})
