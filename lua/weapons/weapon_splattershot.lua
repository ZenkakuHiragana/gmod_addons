
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"
SWEP.ShootSound = "SplatoonSWEPs.Splattershot"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl"
SWEP.Sub = "burstbomb"
SWEP.Special = "bombrush"
SWEP.Variations = {
	{
		ClassName = "weapon_splattershot_tentatek",
		Sub = "suctionbomb",
		Special = "inkzooka",
		Skin = 3,
	},
	{
		ClassName = "weapon_splattershot_wasabi",
		Sub = "splatbomb",
		Special = "inkstrike",
		Skin = 6,
	},
	{
		ClassName = "weapon_heroshot",
		MuzzlePosition = Vector(20, 0, 7.5),
		WeaponModelName = Model "models/props_splatoon/weapons/primaries/hero_shot/hero_shot.mdl",
		ViewModelPos = Vector(4, -23, -7.2),
		ViewModelAng = Angle(12.736, 75, 90),
	},
	{
		ClassName = "weapon_octoshot",
		ShootSound = "SplatoonSWEPs.Octoshot",
		MuzzlePosition = Vector(20, 0, 0.3),
		WeaponModelName = Model "models/props_splatoon/weapons/primaries/octoshot/octoshot.mdl",
		ViewModelPos = Vector(6, -24.3, -7.1),
		WorldModelPos = Vector(4, 0.6, -4.5),
		WorldModelAng = Angle(0, 5, 180),
	},
}

ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity
	TakeAmmo			= .009,					-- Ink consumption per fire[-]
	MuzzlePosition		= Vector(21, 0, 4.8),	-- Thirdperson muzzle position in local coord.
	Damage				= .36,					-- Maximum damage[-]
	MinDamage			= .18,					-- Minimum damage[-]
	InkRadius			= 19.20000076,			-- Painting radius[Splatoon units]
	MinRadius			= 18,					-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13,					-- Painting radius[Splatoon units]
	SplashPatterns		= 5,					-- Paint patterns
	SplashNum			= 2,					-- Number of splashes
	SplashInterval		= 75,					-- Make an interval on each splash[Splatoon units]
	Spread				= 6,					-- Aim cone[deg]
	SpreadJump			= 15,					-- Aim cone while jumping[deg]
	SpreadBias			= .25,					-- Aim cone random component[deg]
	MoveSpeed			= .72,					-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					-- Change hold type[frames]
		Fire			= 6,					-- Fire rate[frames]
		Reload			= 20,					-- Start reloading after firing weapon[frames]
		Crouch			= 6,					-- Can't crouch for some frames after firing
		Straight		= 4,					-- Ink goes without gravity[frames]
		MinDamage		= 15,					-- Deals minimum damage[frames]
		DecreaseDamage	= 8,					-- Start decreasing damage[frames]
	},
})

ss:SetViewModelMods(SWEP, {
	["Base"] = {pos = Vector(-30, 30, -30)},
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, -2, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(7, -27, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(0, 23, -12)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-30, 26, 30),
		angle = Angle(0, -8, -1),
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
