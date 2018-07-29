
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.SplattershotPro"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/splattershot_pro/splattershot_pro.mdl"
SWEP.ShowSplashRing = true -- Muzzleflash effect
SWEP.Sub = "splatbomb"
SWEP.Special = "inkstrike"
SWEP.Variations = {
	{
		ClassName = "weapon_splattershotpro_forge",
		Sub = "pointsensor",
		Special = "inkzooka",
		Skin = 3,
	},
	{
		ClassName = "weapon_splattershotpro_berry",
		Sub = "suctionbomb",
		Special = "bombrush",
		Skin = 4,
	},
}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .02,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(24, 0, 7),		-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .41999999,			-- Maximum damage[-]
	MinDamage			= .20999999,			-- Minimum damage[-]
	InkRadius			= 19.20000076,			-- Painting radius[Splatoon units]
	MinRadius			= 18,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12.5,					-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns[-]
	SplashNum			= 3,					-- Number of splashes[-]
	SplashInterval		= 70,					-- Make an interval on each splash[Splatoon units]
	Spread				= 3,					-- Aim cone[deg]
	SpreadJump			= 12,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .5,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 8,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 6,					-- Ink goes without gravity[frames]
		MinDamage		= 18,					-- Deals minimum damage[frames]
		DecreaseDamage	= 9,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2.397, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(7, -27, 0)},
	["ValveBiped.Bip01_L_Finger1"] = {angle = Angle(0, -10, 0)},
	["ValveBiped.Bip01_L_Finger2"] = {angle = Angle(0, -10, 0)},
	["ValveBiped.Bip01_L_Finger3"] = {angle = Angle(0, -5, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(0.4, -5, 0),
		angle = Angle(1.5, -9, -9),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(3.5, -22.8, -7),
	angle = Angle(12.736, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
})
