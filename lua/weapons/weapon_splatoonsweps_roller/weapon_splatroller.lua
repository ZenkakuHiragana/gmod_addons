
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.PreSwingSound = "SplatoonSWEPs.RollerPreSwing"
SWEP.SwingSound = "SplatoonSWEPs.RollerSwing"
SWEP.SplashSound = "SplatoonSWEPs.RollerSplashLight"
SWEP.RollSound = ss.SplatRollerRoll
SWEP.Special = "killerwail"
SWEP.Sub = "suctionbomb"
SWEP.Variations = {
	{
		Customized = true,
		Bodygroup = {nil, 1},
		Special = "kraken",
		Sub = "squidbeakon",
		Suffix = "krakon",
	},
	{
		ClassName = "splatroller_corocoro",
		SheldonsPicks = true,
		Special = "inkzooka",
		Sub = "splashwall",
	},
	{
		ClassName = "heroroller",
		IsHeroWeapon = true,
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= false,				-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .09,					-- Ink consumption per fire[-]
	TakeAmmoGround		= .001,					-- Ink consumption for painting ground[-]
	Damage				= 1.25,					-- Maximum damage[-]
	DamageSub			= 1.25,					-- Maximum damage of additional splashes[-]
	MinDamage			= .25,					-- Minimum damage[-]
	MinDamageSub		= .25,					-- Minimum damage of additional splashes[-]
	DamageGround		= 1.4,					-- Damage for running over a player[-]
	MoveSpeed			= 1.2,					-- Walk speed while painting the ground[Splatoon units/frame]
	InitVelocity		= 8.2,					-- Initial velocity of splashes base[Splatoon units/sec]
	SpreadVelocity		= Vector(.4, 0, 3),		-- Initial velocity spread[Splatoon units/sec]
	Spread				= 2.2,					-- Aim cone[deg]
	SplashNum			= 12,					-- Number of splashes[-]
	SplashSubNum		= 0,					-- Number of additional splashes[-]
	InitVelocitySub		= 17.5,					-- Initial velocity for additional splashes[Splatoon units/sec]
	SpreadVelocitySub	= Vector(0, 0, 3.5),	-- Initial velocity spread for additional splashes[Splatoon units/sec]
	SpreadSub			= 7,					-- Aim cone for additional splashes[deg]
	SplashPosWidth		= 8,					-- Initial position range for splashes {Splatoon units}
	MaxWidth			= 26,					-- Maximum width for painting ground[Splatoon units]
	MinWidth			= 13,					-- Minimum width for painting ground[Splatoon units]
	CollisionWidth		= 10,					-- Collision size for players[Splatoon units]
	EffectScale			= 1.5,					-- Hit effect modifier[-]
	EffectVelocityRate	= 1.2,					-- Hit effect modifier[-]
	MinDamageDist		= 100,					-- Traveling Z-distance to deal minimum damage[Splatoon units]
	MinDamageDistSub	= 100,					-- Same as above but for additional splashes[Splatoon units]
	DecreaseDamageDist	= 45,					-- Traveling Z-distance to start decreasing damage[Splatoon units]
	DecDamageDistSub	= 45,					-- Same as above but for additional splashes[Splatoon units]
	InkRadius			= 20,					-- Painting radius of splashes[Splatoon units]
	InkRadiusSub		= 18,					-- Same as above but for additional splashes[Splatoon units]
	MinRadius			= 17,					-- Minimum painting radius of splashes[Splatoon units]
	MinRadiusSub		= 15,					-- Same as above but for additional splashes[Splatoon units]
	MaxPaintDistance	= 10,					-- Maximum painting radius under this Z-distance[Splatoon units]
	MaxPaintDistSub		= 10,					-- Same as above but for additional splashes[Splatoon units]
	MinPaintDistance	= 200,					-- Minimum painting radius  over this Z-distance[Splatoon units]
	MinPaintDistSub		= 200,					-- Same as above but for additional splashes[Splatoon units]
	ColRadiusWorld		= 6,					-- Collision radius against the world[Splatoon units]
	ColRadiusWorldSub	= 9,					-- Same as above but for additional splashes[Splatoon units]
	ColRadiusPlayer		= 8.5,					-- Collision radius against players[Splatoon units]
	ColRadiusPlayerSub	= 9,					-- Same as above but for additional splashes[Splatoon units]
	Delay = {
		Reload			= 45,					-- Start reloading after firing weapon[frames]
		ReloadGround	= 20,					-- Start reloading after painting ground[frames]
		Straight		= 4,					-- Ink goes without gravity[frames]
		StraightSub		= 4,					-- Flying time for additional splashes[frames]
		SwingWait		= 20,					-- Waiting time to fire actual ink[frames]
		Fire			= 6,					-- Time to fire next[frames]
	},
})
