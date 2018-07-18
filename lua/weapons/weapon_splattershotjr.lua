
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.SplattershotJr"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/splattershot_jr/splattershot_jr.mdl"
SWEP.Sub = "splatbomb"
SWEP.Special = "bubbler"
SWEP.Variations = {{
	ClassName = "weapon_splattershotjr_custom",
	Sub = "disruptor",
	Special = "echolocator",
	Bodygroup = {1},
}}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .005,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(17, 0, 6),		-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .245,					-- Maximum damage[-]
	MinDamage			= .1225,				-- Minimum damage[-]
	InkRadius			= 21,					-- Painting radius[Splatoon units]
	MinRadius			= 18.5,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.19999981,			-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns[-]
	SplashNum			= 1,					-- Number of splashes[-]
	SplashInterval		= 117,					-- Make an interval on each splash[Splatoon units]
	Spread				= 12,					-- Aim cone[deg]
	SpreadJump			= 18,					-- Aim cone while jumping[deg]
	SpreadBias			= .4,					-- Aim cone random component[deg]
	MoveSpeed			= .72000003,			-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 5,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 3,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2.397, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(7, -32, 0)},
	["ValveBiped.Bip01_L_Finger1"] = {angle = Angle(5, 10, 0)},
	["ValveBiped.Bip01_L_Finger11"] = {angle = Angle(0, -15, 0)},
	["ValveBiped.Bip01_L_Finger12"] = {angle = Angle(0, -15, 0)},
	["ValveBiped.Bip01_L_Finger2"] = {angle = Angle(0, 5, 0)},
	["ValveBiped.Bip01_L_Finger21"] = {angle = Angle(0, -15, 0)},
	["ValveBiped.Bip01_L_Finger4"] = {angle = Angle(0, 5, 0)},
	["ValveBiped.Bip01_L_Finger41"] = {angle = Angle(0, 5, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-1, -5, -2),
		angle = Angle(0, -8, 0),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(4, -23, -7),
	angle = Angle(10, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 0, 180),
})
