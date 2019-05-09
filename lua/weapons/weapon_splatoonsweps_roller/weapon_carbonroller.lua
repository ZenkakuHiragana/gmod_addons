
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
	IsAutomatic			= false,	-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .05,		-- Ink consumption per swing[-]
	Damage				= .52,		-- Maximum damage[-]
	MinDamage			= .26,		-- Minimum damage[-]
	MoveSpeed			= 1.44,		-- Walk speed while painting the ground[Splatoon units/frame]
	Delay = {
		Reload			= 40,		-- Start reloading after firing weapon[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SwingWait		= 9,		-- Waiting time to fire actual ink[frames]
		Fire			= 6,		-- Time to fire next[frames]
	},
})
