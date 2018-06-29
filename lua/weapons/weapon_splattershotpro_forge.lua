
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.SplattershotPro"
ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .02,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(24, 0, 7),		-- Thirdperson muzzle position in local coord.
	Damage				= .41999999,			-- Maximum damage[-]
	MinDamage			= .20999999,			-- Minimum damage[-]
	InkRadius			= 19.20000076,			-- Painting radius[Splatoon units]
	MinRadius			= 18,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12.5,					-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns
	SplashNum			= 3,					-- Number of splashes
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
		Crouch			= 6,					-- Can't crouch for some frames after firing
		Straight		= 6,					-- Ink goes without gravity[frames]
		MinDamage		= 18,					-- Deals minimum damage[frames]
		DecreaseDamage	= 9,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["Base"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 30, -30),
		angle = Angle(0, 0, 0),
	},
	["ValveBiped.Bip01_Spine4"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 27.5, 30),
		angle = Angle(0, -8, -0),
	},
	["ValveBiped.Bip01_L_Finger0"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(7, -27, 0),
	},
	["ValveBiped.Bip01_L_Clavicle"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(2.397, -2, 2),
		angle = Angle(0, 0, 0),
	},
	["ValveBiped.Bip01_L_Hand"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, 23, -12),
	}
})

ss:SetViewModel(SWEP, {
	model = "models/props_splatoon/weapons/primaries/splattershot_pro/splattershot_pro.mdl",
	pos = Vector(3.5, -22.8, -7),
	angle = Angle(12.736, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
	skin = 3,
})

ss:SetWorldModel(SWEP, {
	model = "models/props_splatoon/weapons/primaries/splattershot_pro/splattershot_pro.mdl",
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
	skin = 3,
})
