
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Splattershot"
ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					--false to semi-automatic
	Recoil				= .2,					--Viewmodel recoil intensity
	TakeAmmo			= .009,					--Ink consumption per fire[-]
	PlayAnimPercent		= 0,					--Play PLAYER_ATTACK1 animation frequency[%]
	FirePosition		= Vector(0, -6, -9),	--Ink spawn position
	Damage				= .36,					--Maximum damage[-]
	MinDamage			= .18,					--Minimum damage[-]
	InkRadius			= 19.20000076,			--Painting radius[Splatoon units]
	MinRadius			= 18,					--Minimum painting radius[Splatoon units]
	SplashRadius		= 13,					--Painting radius[Splatoon units]
	SplashPatterns		= 5,					--Paint patterns
	SplashNum			= 2,					--Number of splashes
	SplashInterval		= 75,					--Make an interval on each splash[Splatoon units]
	Spread				= 6,					--Aim cone[deg]
	SpreadJump			= 15,					--Aim cone while jumping[deg]
	SpreadBias			= .25,					--Aim cone random component[deg]
	MoveSpeed			= .72,					--Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					--Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					--Change hold type[frames]
		Fire			= 6,					--Fire rate[frames]
		Reload			= 20,					--Start reloading after firing weapon[frames]
		Crouch			= 6,					--Can't crouch for some frames after firing
		Straight		= 4,					--Ink goes without gravity[frames]
		MinDamage		= 15,					--Deals minimum damage[frames]
		DecreaseDamage	= 8,					--Start decreasing damage[frames]
	},
})

if SERVER then return end
ss:SetViewModelMods(SWEP, {
	["Base"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 30, -30),
		angle = Angle(0, 0, 0),
	},
	["ValveBiped.Bip01_Spine4"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 26, 30),
		angle = Angle(0, -8, -1),
	},
	["ValveBiped.Bip01_L_Finger0"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(7, -27, 0),
	},
	["ValveBiped.Bip01_L_Clavicle"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(2, -2, 2),
		angle = Angle(0, 0, 0),
	},
	["ValveBiped.Bip01_L_Hand"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, 23, -12),
	}
})

ss:SetViewModel(SWEP, {
	model = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl",
	pos = Vector(3.5, -24.3, -7.2),
	angle = Angle(12.736, 80, 90),
	size = Vector(0.56, 0.56, 0.56),
	skin = 6,
})

ss:SetWorldModel(SWEP, {
	model = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl",
	pos = Vector(4, 0.6, 0.5),
	angle = Angle(0, 1, 180),
	skin = 6,
})
