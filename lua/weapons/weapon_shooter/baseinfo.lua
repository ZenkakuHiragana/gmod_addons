
--Weapon information in default SWEP structure.
SWEP.PrintName = "Splattershot Test"
SWEP.Purpose = "Weapon for development."
SWEP.Instructions = "Primary Attack: Do something nicely."
SWEP.Author = "GreatZenkakuMan"
SWEP.Category = "Other"
SWEP.Contact = ""
SWEP.AccurateCrosshair = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"

SWEP.Primary = istable(SWEP.Primary) and SWEP.Primary or {}
SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "AR2"
SWEP.Primary.Recoil = 0.2

SWEP.Secondary = istable(SWEP.Secondary) and SWEP.Secondary or {}
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "Ink"