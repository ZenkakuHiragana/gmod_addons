
if not IsMounted("ep2") then return end
--include "ai_translations.lua"
AddCSLuaFile()

SWEP.PrintName = "GreatZenkakuMan's Sandbox"
SWEP.Author = "GreatZenkakuMan"
SWEP.Purpose = "Weapon for development."

SWEP.Slot = 1
SWEP.SlotPos = 2

SWEP.Spawnable = true

SWEP.ViewModel = Model( "models/weapons/c_smg1.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_smg1.mdl" )
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.AdminOnly = true

game.AddParticles( "particles/hunter_flechette.pcf" )
game.AddParticles( "particles/hunter_projectile.pcf" )

local ShootSound = Sound( "NPC_Hunter.FlechetteShoot" )


function SWEP:Initialize()
	self:SetHoldType("shotgun")
	self.HoldType = "smg"
	self.ShootCount = 0
end

function SWEP:Deploy()
--	hook.Add("PostDrawTranslucentRenderables", "drawsurface" .. self.EntIndex(), function(writingdepth, sky)
--		for k,v in pairs(self.Surface) do
--			render.DrawLine(v.HitPos, v.HitPos + v.HitNormal * 100, Color(0,255,0,255),false)
--		end
--	end)
	return true
end

function SWEP:Think()
--	if SERVER then return end
--	for k,v in ipairs(self.Surface) do
--		render.DrawLine(v.HitPos, v.HitPos + v.HitNormal * 100, Color(0,255,0,255),false)
--		debugoverlay.Line(v.HitPos, v.HitPos + v.HitNormal * 100, 0.1, Color(0,255,0,255),false)
--	end
end

function SWEP:Holster()
	self.Surface = {}
--	hook.Remove("PostDrawTranslucentRenderables", "drawsurface" .. self.EntIndex())
	return true
end

function SWEP:Reload()
	self.Surface = {}
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.1)
	self:EmitSound(ShootSound)
	self:MuzzleFlash()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
--	ParticleEffectAttach("hunter_muzzle_flash", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("muzzle"))
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.05)
end

function SWEP:ShouldDropOnDie()
	return true
end

if SERVER then return end

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
