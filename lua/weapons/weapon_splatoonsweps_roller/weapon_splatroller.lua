
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
	IsAutomatic			= false,	-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .09,		-- Ink consumption per fire[-]
	Damage				= .52,		-- Maximum damage[-]
	MinDamage			= .26,		-- Minimum damage[-]
	MoveSpeed			= 1.2,		-- Walk speed while painting the ground[Splatoon units/frame]
	Delay = {
		Reload			= 45,		-- Start reloading after firing weapon[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SwingWait		= 20,		-- Waiting time to fire actual ink[frames]
		Fire			= 6,		-- Time to fire next[frames]
	},
})
