
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
	IsAutomatic			= false,	-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .2,		-- Ink consumption per fire[-]
	Damage				= .52,		-- Maximum damage[-]
	MinDamage			= .26,		-- Minimum damage[-]
	MoveSpeed			= .96,		-- Walk speed while painting the ground[Splatoon units/frame]
	Delay = {
		Reload			= 50,		-- Start reloading after firing weapon[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SwingWait		= 45,		-- Waiting time to fire actual ink[frames]
		Fire			= 6,		-- Time to fire next[frames]
	},
})
