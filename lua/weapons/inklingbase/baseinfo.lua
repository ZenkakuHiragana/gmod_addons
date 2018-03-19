
--Weapon information in default SWEP structure.
if CLIENT then
	SWEP.Author = "GreatZenkakuMan"
	SWEP.BobScale = 1
	SWEP.BounceWeaponIcon = true
	SWEP.Category = "Splatoon SWEPs"
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
	SWEP.DrawWeaponInfoBox = true
	SWEP.Instructions = 
	[[Primary: Shoot ink.
Secondary: Use sub weapon.
Reload: Use special weapon.
Shift: Squid Beakon menu.
Crouch: Become squid.
	]]
	SWEP.PrintName = "Inkling base"
	SWEP.Purpose = "Splat ink!"
	SWEP.RenderGroup = RENDERGROUP_TRANSLUCENT
	SWEP.Spawnable = false
	SWEP.SpeechBubbleLid = surface.GetTextureID "gui/speech_lid"
	SWEP.SwayScale = 1
	SWEP.UseHands = true
	SWEP.ViewModelFOV = 62
else
	SWEP.AutoSwitchFrom = false
	SWEP.AutoSwitchTo = false
	SWEP.Weight = 1
end

SWEP.HoldType = "crossbow"
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.IsSplatoonWeapon = true
SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.m_WeaponDeploySpeed = 5
SplatoonSWEPs:SetPrimary(SWEP, {
	Recoil				= .2,	--Viewmodel recoil intensity
	TakeAmmo			= .01,	--Ink consumption per fire[-].
	PlayAnimPercent		= 0,	--Play PLAYER_ATTACK1 animation frequency[%].
	Delay = {
		Fire			= 6,	--Fire rate in frames.
		Reload			= 30,	--Start reloading after firing weapon[frames].
		Crouch			= 10,	--Can't crouch for some frames after firing.
	},
})

SplatoonSWEPs:SetSecondary(SWEP, {
	Recoil				= .2,
	TakeAmmo			= .7,	 --Sub weapon consumption[-].
	PlayAnimPercent		= 30,
	Delay = {
		Fire			= 30,
		Reload			= 30,
		Crouch			= 10,
	},
})
