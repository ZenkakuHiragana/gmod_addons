
--Weapon information in default SWEP structure.
SWEP.PrintName = "Inkling base"
SWEP.Purpose = "Splat ink!"
SWEP.Instructions = 
[[Primary: Shoot ink.
Secondary: Use sub weapon.
Reload: Use special weapon.
Shift: Squid Beakon menu.
Crouch: Become squid.
]]
SWEP.Author = "GreatZenkakuMan"
SWEP.Category = "Splatoon SWEPs"
SWEP.Contact = "GitHub repository URL here."
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"

SWEP.AutoSwitchFrom = false
SWEP.AutoSwitchTo = false

SWEP.Primary = istable(SWEP.Primary) and SWEP.Primary or {}
SWEP.Primary.ClipSize = 100 --Clip size only for displaying.
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "AR2"
SWEP.Primary.Delay = 0.1 --Fire rate in seconds.
SWEP.Primary.Recoil = 0.2 --Viewmodel recoil intensity
SWEP.Primary.ReloadDelay = 30 --Start reloading after firing weapon in frames.
SWEP.Primary.TakeAmmo = 1 --Ink consumption per fire.
SWEP.Primary.PercentageRecoilAnimation = 0 --Play PLAYER_ATTACK1 animation frequency 0-1.
SWEP.Primary.CrouchCooldown = 10 --Can't crouch for some frames after firing.

SWEP.Secondary = istable(SWEP.Secondary) and SWEP.Secondary or {}
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "Ink"
SWEP.Secondary.Delay = 0.5
SWEP.Secondary.Recoil = 1.0
SWEP.Secondary.ReloadDelay = 30
SWEP.Secondary.TakeAmmo = 0.7 --Sub weapon consumption 0-1.
SWEP.Secondary.PercentageRecoilAnimation = 0.3
SWEP.Secondary.CrouchCooldown = 10
