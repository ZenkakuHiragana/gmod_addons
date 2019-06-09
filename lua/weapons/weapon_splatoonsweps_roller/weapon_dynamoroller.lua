
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.PreSwingSound = "SplatoonSWEPs.RollerPreSwing"
SWEP.SwingSound = "SplatoonSWEPs.RollerSwing"
SWEP.SplashSound = "SplatoonSWEPs.RollerSplashMedium"
SWEP.RollSound = ss.DynamoRollerRoll
SWEP.Special = "echolocator"
SWEP.Sub = "sprinker"
SWEP.Variations = {
	{
		Customized = true,
		Skin = 1,
		Special = "inkstrike",
		Sub = "splatbomb",
		Suffix = "gold",
	},
	{
		SheldonsPicks = true,
		Skin = 2,
		Special = "killerwail",
		Sub = "seeker",
		Suffix = "tempered",
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= false,				-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .2,					-- Ink consumption per fire[-]
	TakeAmmoGround		= .001,					-- Ink consumption for painting ground[-]
	Damage				= 1.25,					-- Maximum damage[-]
	DamageSub			= 1.4,					-- Maximum damage of additional splashes[-]
	MinDamage			= .25,					-- Minimum damage[-]
	MinDamageSub		= .3,					-- Minimum damage of additional splashes[-]
	DamageGround		= 1.6,					-- Damage for running over a player[-]
	MoveSpeed			= .96,					-- Walk speed while painting the ground[Splatoon units/frame]
	InitVelocity		= 10,					-- Initial velocity of splashes base[Splatoon units/frame]
	SpreadVelocity		= Vector(.5714, 0, 5),	-- Initial velocity spread[Splatoon units/frame]
	Spread				= 2.5,					-- Aim cone[deg]
	SplashNum			= 16,					-- Number of splashes[-]
	SplashSubNum		= 0,					-- Number of additional splashes[-]
	InitVelocitySub		= 17.5,					-- Initial velocity for additional splashes[Splatoon units/frame]
	SpreadVelocitySub	= Vector(0, 0, 3.5),	-- Initial velocity spread for additional splashes[Splatoon units/frame]
	SpreadSub			= 7,					-- Aim cone for additional splashes[deg]
	SplashPosWidth		= 8,					-- Initial position range for splashes {Splatoon units}
	MaxWidth			= 30,					-- Maximum width for painting ground[Splatoon units]
	MinWidth			= 13,					-- Minimum width for painting ground[Splatoon units]
	CollisionWidth		= 10,					-- Collision size for players[Splatoon units]
	EffectScale			= 2,					-- Hit effect modifier[-]
	EffectVelocityRate	= 1.4,					-- Hit effect modifier[-]
	MinDamageDist		= 170,					-- Traveling Z-distance to deal minimum damage[Splatoon units]
	MinDamageDistSub	= 80,					-- Same as above but for additional splashes[Splatoon units]
	DecreaseDamageDist	= 70,					-- Traveling Z-distance to start decreasing damage[Splatoon units]
	DecDamageDistSub	= 10,					-- Same as above but for additional splashes[Splatoon units]
	InkRadius			= 22,					-- Painting radius of splashes[Splatoon units]
	InkRadiusSub		= 18,					-- Same as above but for additional splashes[Splatoon units]
	MinRadius			= 22,					-- Minimum painting radius of splashes[Splatoon units]
	MinRadiusSub		= 15,					-- Same as above but for additional splashes[Splatoon units]
	MaxPaintDistance	= 10,					-- Maximum painting radius under this Z-distance[Splatoon units]
	MaxPaintDistSub		= 10,					-- Same as above but for additional splashes[Splatoon units]
	MinPaintDistance	= 200,					-- Minimum painting radius  over this Z-distance[Splatoon units]
	MinPaintDistSub		= 200,					-- Same as above but for additional splashes[Splatoon units]
	ColRadiusWorld		= 8,					-- Collision radius against the world[Splatoon units]
	ColRadiusWorldSub	= 9,					-- Same as above but for additional splashes[Splatoon units]
	ColRadiusPlayer		= 12,					-- Collision radius against players[Splatoon units]
	ColRadiusPlayerSub	= 9,					-- Same as above but for additional splashes[Splatoon units]
	Delay = {
		Reload			= 50,					-- Start reloading after firing weapon[frames]
		ReloadGround	= 20,					-- Start reloading after painting ground[frames]
		Straight		= 6,					-- Ink goes without gravity[frames]
		StraightSub		= 4,					-- Flying time for additional splashes[frames]
		SwingWait		= 45,					-- Waiting time to fire actual ink[frames]
		Fire			= 6,					-- Time to fire next[frames]
	},
})
