
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.L-3"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/nozzlenose/nozzlenose.mdl"
SWEP.Sub = "disruptor"
SWEP.Special = "killerwail"
SWEP.Variations = {{
	ClassName = "weapon_l3nozzlenose_d",
	Sub = "burstbomb",
	Special = "kraken",
	Bodygroup = {1},
}}

ss:SetPrimary(SWEP, {
	IsAutomatic			= false,				-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .01,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(30, 0, 12),	-- Thirdperson muzzle position in local coord.[Hammer units]
	Damage				= .28999999,			-- Maximum damage[-]
	MinDamage			= .145,					-- Minimum damage[-]
	InkRadius			= 22,					-- Painting radius[Splatoon units]
	MinRadius			= 22,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 15,					-- Painting radius[Splatoon units]
	SplashPatterns		= 10,					-- Paint patterns[-]
	SplashNum			= 1.5,					-- Number of splashes[-]
	SplashInterval		= 116,					-- Make an interval on each splash[Splatoon units]
	Spread				= 1,					-- Aim cone[deg]
	SpreadJump			= 6,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .5,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = { -- Crouch delay, Nozzlenose cooldown: mRepeatFrame * 3 + mTripleShotSpan)
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 4,					-- Fire rate[frames]
		TripleShot		= 8,					-- Nozzlenose cooldown[frames]
		Reload			= 25,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Cannot crouch for some frames after firing[frames]
		Straight		= 5,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(1, 0, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(50, -40, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 28, -30)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-0.15, -5.5, -1),
		angle = Angle(1, -8, -8),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(2.8, -23, -7),
	angle = Angle(12, 85, 90),
	size = Vector(0.56, 0.56, 0.56),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(4, 0.6, 0),
	angle = Angle(0, 1, 180),
})
