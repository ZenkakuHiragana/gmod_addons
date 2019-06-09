
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.PreSwingSound = "SplatoonSWEPs.RollerPreSwing"
SWEP.SwingSound = "SplatoonSWEPs.CarbonRollerSwing"
SWEP.SplashSound = "SplatoonSWEPs.RollerSplashLight"
SWEP.RollSound = ss.CarbonRollerRoll
SWEP.Special = "inkzooka"
SWEP.Sub = "burstbomb"
SWEP.Variations = {{
	Customized = true,
	Skin = 1,
	Special = "bombrush",
	Sub = "seeker",
	Suffix = "deco",
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= false,				-- false to semi-automatic
	Recoil				= .2,					-- Viewmodel recoil intensity[-]
	TakeAmmo			= .05,					-- Ink consumption per fire[-]
	TakeAmmoGround		= .001,					-- Ink consumption for painting ground[-]
	Damage				= 1.25,					-- Maximum damage[-]
	DamageSub			= 1.25,					-- Maximum damage of additional splashes[-]
	MinDamage			= .25,					-- Minimum damage[-]
	MinDamageSub		= .25,					-- Minimum damage of additional splashes[-]
	DamageGround		= .7,					-- Damage for running over a player[-]
	MoveSpeed			= 1.44,					-- Walk speed while painting the ground[Splatoon units/frame]
	InitVelocity		= 7,					-- Initial velocity of splashes base[Splatoon units/frame]
	SpreadVelocity		= Vector(.2286, 0, 2),	-- Initial velocity spread[Splatoon units/frame]
	Spread				= 1.8,					-- Aim cone[deg]
	SplashNum			= 10,					-- Number of splashes[-]
	SplashSubNum		= 0,					-- Number of additional splashes[-]
	InitVelocitySub		= 17.5,					-- Initial velocity for additional splashes[Splatoon units/frame]
	SpreadVelocitySub	= Vector(0, 0, 3.5),	-- Initial velocity spread for additional splashes[Splatoon units/frame]
	SpreadSub			= 7,					-- Aim cone for additional splashes[deg]
	SplashPosWidth		= 6,					-- Initial position range for splashes {Splatoon units}
	MaxWidth			= 22,					-- Maximum width for painting ground[Splatoon units]
	MinWidth			= 13,					-- Minimum width for painting ground[Splatoon units]
	CollisionWidth		= 10,					-- Collision size for players[Splatoon units]
	EffectScale			= 1,					-- Hit effect modifier[-]
	EffectVelocityRate	= 1,					-- Hit effect modifier[-]
	MinDamageDist		= 75,					-- Traveling Z-distance to deal minimum damage[Splatoon units]
	MinDamageDistSub	= 75,					-- Same as above but for additional splashes[Splatoon units]
	DecreaseDamageDist	= 30,					-- Traveling Z-distance to start decreasing damage[Splatoon units]
	DecDamageDistSub	= 30,					-- Same as above but for additional splashes[Splatoon units]
	InkRadius			= 20,					-- Painting radius of splashes[Splatoon units]
	InkRadiusSub		= 18,					-- Same as above but for additional splashes[Splatoon units]
	MinRadius			= 15,					-- Minimum painting radius of splashes[Splatoon units]
	MinRadiusSub		= 15,					-- Same as above but for additional splashes[Splatoon units]
	MaxPaintDistance	= 10,					-- Maximum painting radius under this Z-distance[Splatoon units]
	MaxPaintDistSub		= 10,					-- Same as above but for additional splashes[Splatoon units]
	MinPaintDistance	= 200,					-- Minimum painting radius  over this Z-distance[Splatoon units]
	MinPaintDistSub		= 200,					-- Same as above but for additional splashes[Splatoon units]
	ColRadiusWorld		= 5,					-- Collision radius against the world[Splatoon units]
	ColRadiusWorldSub	= 9,					-- Same as above but for additional splashes[Splatoon units]
	ColRadiusPlayer		= 7.5,					-- Collision radius against players[Splatoon units]
	ColRadiusPlayerSub	= 9,					-- Same as above but for additional splashes[Splatoon units]
	Delay = {
		Reload			= 40,					-- Start reloading after firing weapon[frames]
		ReloadGround	= 20,					-- Start reloading after painting ground[frames]
		Straight		= 3,					-- Ink goes without gravity[frames]
		StraightSub		= 4,					-- Flying time for additional splashes[frames]
		SwingWait		= 9,					-- Waiting time to fire actual ink[frames]
		Fire			= 6,					-- Time to fire next[frames]
	},
})
