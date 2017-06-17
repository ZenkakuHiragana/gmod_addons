
if ( !IsMounted( "ep2" ) ) then return end
include "ai_translations.lua"

AddCSLuaFile()

SWEP.PrintName = "Surface Paint (Test)"
SWEP.Author = "GreatZenkakuMan"
SWEP.Purpose = "primary attack to paint surface."

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

SWEP.Surface = {}

function SWEP:Initialize()
	self:SetHoldType( "smg" )
	self.HoldType = "smg"
	self.ShootCount = 0
end

function SWEP:Deploy()
--	hook.Add("PostDrawTranslucentRenderables", "drawsurface" .. self.EntIndex(), function(writingdepth, sky)
--		for k,v in pairs(self.Surface) do
--			render.DrawLine(v.HitPos, v.HitPos + v.HitNormal * 100, Color(0,255,0,255),false)
--		end
--	end)
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
	self:SetNextPrimaryFire(CurTime() + 0.05)
	local tr = self.Owner:GetEyeTrace()
	if not tr.HitWorld then return end
	self:EmitSound(ShootSound)
	
	local deletelist = {}
	for k,v in pairs(self.Surface) do
		if v.ColorName ~= "Cyan" and (v.HitPos - tr.HitPos):LengthSqr() < 400 then
			table.insert(deletelist, k)
		end
	end
	
	for k,v in pairs(deletelist) do
		table.remove(self.Surface, v)
	end
	
	table.insert(self.Surface, {
		HitPos = tr.HitPos,
		HitNormal = tr.HitNormal,
		ColorName = "Cyan"
	})
	
	RunConsoleCommand("r_cleardecals")
	local times = 0
	timer.Create("spray" .. self:EntIndex(), 0, (#self.Surface / 200) + 1, function()
		print(#self.Surface, times)
		for i = 200 * times, 200 * (times + 1) do
			local k = i + 1
			if k > #self.Surface then k = #self.Surface end
			local v = self.Surface[k]
			util.Decal("Ink" .. v.ColorName, v.HitPos + v.HitNormal, v.HitPos - v.HitNormal)
			if i > #self.Surface then break end
		end
		times = times + 1
	end)
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.05)
	local tr = self.Owner:GetEyeTrace()
	if not tr.HitWorld then return end
	self:EmitSound(ShootSound)
	
	local deletelist = {}
	for k,v in pairs(self.Surface) do
		if v.ColorName ~= "Orange" and (v.HitPos - tr.HitPos):LengthSqr() < 400 then
			table.insert(deletelist, k)
		end
	end
	
	for k,v in pairs(deletelist) do
		table.remove(self.Surface, v)
	end
	
	table.insert(self.Surface, {
		HitPos = tr.HitPos,
		HitNormal = tr.HitNormal,
		ColorName = "Orange"
	})
	
	RunConsoleCommand("r_cleardecals")
	local times = 0
	timer.Create("spray2" .. self:EntIndex(), 0, (#self.Surface / 200) + 1, function()
		print(#self.Surface, times)
		for i = 200 * times, 200 * (times + 1) do
			local k = i + 1
			if k > #self.Surface then k = #self.Surface end
			local v = self.Surface[k]
			util.Decal("Ink" .. v.ColorName, v.HitPos + v.HitNormal, v.HitPos - v.HitNormal)
			if i > #self.Surface then break end
		end
		times = times + 1
	end)
end

function SWEP:ShouldDropOnDie()
	return true
end
