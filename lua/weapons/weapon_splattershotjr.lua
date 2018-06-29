
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.SplattershotJr"
ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .005,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(17, 0, 6),		-- Thirdperson muzzle position in local coord.
	Damage				= .245,					-- Maximum damage[-]
	MinDamage			= .1225,				-- Minimum damage[-]
	InkRadius			= 21,					-- Painting radius[Splatoon units]
	MinRadius			= 18.5,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13.19999981,			-- Painting radius[Splatoon units]
	SplashPatterns		= 8,					-- Paint patterns
	SplashNum			= 1,					-- Number of splashes
	SplashInterval		= 117,					-- Make an interval on each splash[Splatoon units]
	Spread				= 12,					-- Aim cone[deg]
	SpreadJump			= 18,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .72000003,			-- Walk speed while shooting[Splatoon units/frame]
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
	["Base"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 30, -30),
		angle = Angle(0, 0, 0),
	},
	["ValveBiped.Bip01_Spine4"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 27.5, 30),
		angle = Angle(0, -8, 0),
	},
	["ValveBiped.Bip01_L_Finger0"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(7, -27, 0),
	},
	["ValveBiped.Bip01_L_Finger1"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(5, 10, 0),
	},
	["ValveBiped.Bip01_L_Finger11"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, -15, 0),
	},
	["ValveBiped.Bip01_L_Finger12"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, -15, 0),
	},
	["ValveBiped.Bip01_L_Finger2"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, 5, 0),
	},
	["ValveBiped.Bip01_L_Finger21"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, -15, 0),
	},
	["ValveBiped.Bip01_L_Finger4"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, 5, 0),
	},
	["ValveBiped.Bip01_L_Finger41"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, 5, 0),
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
	model = "models/props_splatoon/weapons/primaries/splattershot_jr/splattershot_jr.mdl",
	pos = Vector(4, -23, -7),
	angle = Angle(10, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	model = "models/props_splatoon/weapons/primaries/splattershot_jr/splattershot_jr.mdl",
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 0, 180),
})
