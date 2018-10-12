
--Weapon information in default SWEP structure.
local ss = SplatoonSWEPs
if not ss then return end

if CLIENT then
	SWEP.Author = ss.Text.Author
	SWEP.BobScale = 1
	SWEP.BounceWeaponIcon = true
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
	SWEP.DrawWeaponInfoBox = true
	SWEP.Instructions = ss.Text.Instructions
	SWEP.Purpose = ss.Text.Purpose
	SWEP.RenderGroup = RENDERGROUP_OPAQUE
	SWEP.SpeechBubbleLid = surface.GetTextureID "gui/speech_lid"
	SWEP.SwayScale = 1
	SWEP.UseHands = true
	SWEP.ViewModelFOV = 62
else
	SWEP.AutoSwitchFrom = false
	SWEP.AutoSwitchTo = false
	SWEP.Weight = 1
end

SWEP.PrintName = "Inkling base"
SWEP.Spawnable = false
SWEP.HoldType = "crossbow"
SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.IsSplatoonWeapon = true
SWEP.m_WeaponDeploySpeed = 2
ss.SetPrimary(SWEP, {
	Recoil				= .2,	--Viewmodel recoil intensity
	TakeAmmo			= .01,	--Ink consumption per fire[-].
	Delay = {
		Fire			= 6,	--Fire rate in frames.
		Reload			= 30,	--Start reloading after firing weapon[frames].
		Crouch			= 10,	--Can't crouch for some frames after firing.
	},
})

ss.SetSecondary(SWEP, {
	IsAutomatic			= true,
	Recoil				= .2,
	TakeAmmo			= .7,	 --Sub weapon consumption[-].
	Delay = {
		Fire			= 30,
		Reload			= 40,
		Crouch			= 30,
	},
})
