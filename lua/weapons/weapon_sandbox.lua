
AddCSLuaFile()
local ShootSound = Sound "NPC_Hunter.FlechetteShoot"

SWEP.PrintName = "GreatZenkakuMan's Sandbox"
SWEP.Author = "GreatZenkakuMan"
SWEP.Contact = ""
SWEP.Purpose = "Weapon for development."
SWEP.Instructions = "Primary Attack: Do something nicely."
SWEP.AccurateCrosshair = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"

SWEP.Primary = istable(SWEP.Primary) and SWEP.Primary or {}
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary = istable(SWEP.Secondary) and SWEP.Secondary or {}
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	if SERVER then return end
	self.WepSelectIcon = surface.GetTextureID("weapons/swep")
end

function SWEP:Think()
end

--Predicted Hooks
function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	return true
end

function SWEP:Reload()
	self.Surface = {}
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	self:SetNextPrimaryFire(CurTime() + 0.1)
	self:EmitSound(ShootSound)
	self:MuzzleFlash()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	
	if IsFirstTimePredicted() then
		
	end
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end
	self:SetNextSecondaryFire(CurTime() + 0.5)
	self:EmitSound(ShootSound)
	self:MuzzleFlash()
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	
	if IsFirstTimePredicted() then
		
	end
end


if SERVER then
	function SWEP:ShouldDropOnDie()
		return true
	end
	return
end

function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
	local p, a = oldPos, ang
	local aim = self:GetOwner():GetEyeTraceNoCursor().Normal
	local muzzle = a:Forward()
	local b = vm:GetAttachment(vm:LookupAttachment("muzzle")).Pos
	debugoverlay.Line(b, b + aim * 200, 0.1, Color(0,255,0),true)
	debugoverlay.Line(b, b + muzzle * 200, 0.1, Color(255,255,0),true)
--	print(aim:Dot(muzzle))
	return p, a
end
