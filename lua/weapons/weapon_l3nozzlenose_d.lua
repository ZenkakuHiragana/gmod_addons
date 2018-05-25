
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.L-3"
ss:SetPrimary(SWEP, {
	IsAutomatic			= false,					--false to semi-automatic
	Recoil				= .2,					--Viewmodel recoil intensity
	TakeAmmo			= .01,					--Ink consumption per fire[-]
	PlayAnimPercent		= 0,					--Play PLAYER_ATTACK1 animation frequency[%]
	FirePosition		= Vector(1, -14, -9),	--Ink spawn position
	Damage				= .28999999,			--Maximum damage[-]
	MinDamage			= .145,					--Minimum damage[-]
	InkRadius			= 22,					--Painting radius[Splatoon units]
	MinRadius			= 22,					--Minimum painting radius[Splatoon units]
	SplashRadius		= 15,					--Painting radius[Splatoon units]
	SplashPatterns		= 10,					--Paint patterns
	SplashNum			= 1.5,					--Number of splashes
	SplashInterval		= 116,					--Make an interval on each splash[Splatoon units]
	Spread				= 1,					--Aim cone[deg]
	SpreadJump			= 6,					--Aim cone while jumping[deg]
	SpreadBias			= .25,					--Aim cone random component[deg]
	MoveSpeed			= .5,					--Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					--Ink initial velocity[Splatoon units/frame]	
	Delay = { --Crouch delay, Nozzlenose cooldown: mRepeatFrame * 3 + mTripleShotSpan)
		Aim				= 20,					--Change hold type[frames]
		Fire			= 4,					--Fire rate[frames]
		TripleShot		= 8,					--Nozzlenose cooldown[frames]
		Reload			= 25,					--Start reloading after firing weapon[frames]
		Crouch			= 6,					--Can't crouch for some frames after firing
		Straight		= 5,					--Ink goes without gravity[frames]
		MinDamage		= 15,					--Deals minimum damage[frames]
		DecreaseDamage	= 8,					--Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["Base"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 26, -30),
		angle = Angle(1, 0, 0),
	},
	["ValveBiped.Bip01_Spine4"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(-30, 26, 30),
		angle = Angle(0, -8, 0),
	},
	["ValveBiped.Bip01_L_Finger0"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(50, -40, 0),
	},
	["ValveBiped.Bip01_L_Clavicle"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(1, 0, 2),
		angle = Angle(0, 0, 0),
	},
	["ValveBiped.Bip01_L_Hand"] = {
		scale = Vector(1, 1, 1),
		pos = Vector(0, 0, 0),
		angle = Angle(0, 28, -30),
	}
})

ss:SetViewModel(SWEP, {
	model = "models/props_splatoon/weapons/primaries/nozzlenose/nozzlenose.mdl",
	pos = Vector(2.8, -23, -7),
	angle = Angle(12, 85, 90),
	size = Vector(0.56, 0.56, 0.56),
	bodygroup = {1},
})

ss:SetWorldModel(SWEP, {
	model = "models/props_splatoon/weapons/primaries/nozzlenose/nozzlenose.mdl",
	pos = Vector(4, 0.6, 0),
	angle = Angle(0, 1, 180),
	bodygroup = {1},
})
