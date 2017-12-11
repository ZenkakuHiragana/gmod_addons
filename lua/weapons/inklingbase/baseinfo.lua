
--Weapon information in default SWEP structure.
if CLIENT then
	SWEP.Author = "GreatZenkakuMan"
	SWEP.Category = "Splatoon SWEPs"
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
	SWEP.Instructions = 
	[[Primary: Shoot ink.
Secondary: Use sub weapon.
Reload: Use special weapon.
Shift: Squid Beakon menu.
Crouch: Become squid.
	]]
	SWEP.Purpose = "Splat ink!"
	SWEP.RenderGroup = RENDERGROUP_TRANSLUCENT
	-- SWEP.SpeechBubbleLid = surface.GetTextureID "gui/speech_lid"
	SWEP.UseHands = true
	SWEP.ViewModelFOV = 62
else
	SWEP.AutoSwitchFrom = false
	SWEP.AutoSwitchTo = false
end

SWEP.HoldType = "crossbow"
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
function SWEP:SetWeaponInfo(info)
	self.Slot = info.Slot or 1
	self.SlotPos = info.SlotPos or 2
	self.m_WeaponDeploySpeed = info.DeploySpeed or 5
	local p = istable(self.Primary) and self.Primary or {}
	p.ClipSize = 100 --Clip size only for displaying.
	p.DefaultClip = 100
	p.Automatic = true
	p.Ammo = "Ink"
	p.Delay = self:FrameToSec(info.Primary.Delay.Fire or 6)
	p.Recoil = info.Primary.Recoil or 0.2
	p.ReloadDelay = self:FrameToSec(info.Primary.Delay.Reload or 30)
	p.TakeAmmo = (info.Primary.TakeAmmo or 1) / 100 * SplatoonSWEPs.MaxInkAmount
	p.PercentageRecoilAnimation = (info.Primary.PercentageRecoilAnimation or 0) / 100
	p.CrouchCooldown = self:FrameToSec(info.Primary.CrouchCooldown or 10)
	self.Primary = p
	
	local s = istable(self.Secondary) and self.Secondary or {}
	s.ClipSize = -1
	s.DefaultClip = -1
	s.Automatic = false
	s.Ammo = "Ink"
	s.Delay = self:FrameToSec(info.Secondary.Delay.Fire or 6)
	s.Recoil = info.Secondary.Recoil or 0.2
	s.ReloadDelay = self:FrameToSec(info.Secondary.Delay.Reload or 30)
	s.TakeAmmo = (info.Secondary.TakeAmmo or 70) / 100 * SplatoonSWEPs.MaxInkAmount
	s.PercentageRecoilAnimation = (info.Secondary.PercentageRecoilAnimation or 30) / 100
	s.CrouchCooldown = self:FrameToSec(info.Secondary.CrouchCooldown or 10)
	self.Secondary = s
	
	if CLIENT then self.PrintName = info.name or "Inkling base" end
end

SWEP.IsSplatoonWeapon = true
SWEP:SetWeaponInfo {
	Name				= "Inkling base",
	Slot				= 1,
	SlotPos				= 2,
	DeploySpeed			= 5,
	Primary = {
		Recoil							= 0.2,	--Viewmodel recoil intensity
		Delay = {
			Fire						= 6,	--Fire rate in frames.
			Reload						= 30,	--Start reloading after firing weapon[frames].
			TakeAmmo					= 1,	--Ink consumption per fire[%].
			PercentageRecoilAnimation	= 0,	--Play PLAYER_ATTACK1 animation frequency[%].
			CrouchCooldown				= 10,	--Can't crouch for some frames after firing.
		},
	},
	Secondary = {
		Recoil							= 0.2,
		Delay = {
			Fire						= 30,
			Reload						= 30,
			TakeAmmo					= 70,	 --Sub weapon consumption[%].
			PercentageRecoilAnimation	= 30,
			CrouchCooldown				= 10,
		},
	},
}
