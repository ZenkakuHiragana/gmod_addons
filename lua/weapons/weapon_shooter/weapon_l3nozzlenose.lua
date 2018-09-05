
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ShootSound = "SplatoonSWEPs.L-3"
SWEP.Sub = "disruptor"
SWEP.Special = "killerwail"
SWEP.Variations = {{
	ClassName = "weapon_l3nozzlenose_d",
	Sub = "burstbomb",
	Special = "kraken",
	Bodygroup = {[0] = 1},
}}

ss.SetPrimary(SWEP, {
	IsAutomatic			= false,	-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .01,		-- Ink consumption per fire[-]
	Damage				= .29,		-- Maximum damage[-]
	MinDamage			= .145,		-- Minimum damage[-]
	InkRadius			= 22,		-- Painting radius[Splatoon units]
	MinRadius			= 22,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 15,		-- Painting radius[Splatoon units]
	SplashPatterns		= 10,		-- Paint patterns[-]
	SplashNum			= 1.5,		-- Number of splashes[-]
	SplashInterval		= 116,		-- Make an interval on each splash[Splatoon units]
	Spread				= 1,		-- Aim cone[deg]
	SpreadJump			= 6,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random component[deg]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .5,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = { -- Crouch delay, Nozzlenose cooldown: mRepeatFrame * 3 + mTripleShotSpan)
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 4,		-- Fire rate[frames]
		TripleShot		= 8,		-- Nozzlenose cooldown[frames]
		Reload			= 25,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 5,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
