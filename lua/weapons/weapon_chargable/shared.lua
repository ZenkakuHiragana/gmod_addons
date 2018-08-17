
local ss = SplatoonSWEPs
if not ss then return end

SWEP.Base = "weapon_shooter"
SWEP.PrintName = "Chargable base"
SWEP.Spawnable = true

SWEP.ShootSound = "SplatoonSWEPs.SplatCharger"
SWEP.ShootSound2 = "SplatoonSWEPs.SplatChargerFull"
SWEP.WElements = SWEP.WElements or {}
SWEP.VElements = SWEP.VElements or {}
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/splat_charger/splat_charger.mdl"
SWEP.ModelPath = "models/splatoonsweps/weapon_splatcharger/"
SWEP.ViewModel = SWEP.ModelPath .. "c_viewmodel.mdl"
SWEP.WorldModel = SWEP.ModelPath .. "w_right.mdl"

SWEP.Base = "weapon_charger"
ss.SetPrimary(SWEP, {
	MuzzlePosition				= Vector(54.72, 0, 4.55),	-- Thirdperson muzzle position in local coord.[Hammer units]
	MinRange					= 90,						-- Minimum distance [Splatoon units]
	MaxRange					= 250,						-- Maximum distance before fully charged [Splatoon units]
	FullRange					= 250,						-- Distance when fully charged [Splatoon units]
	EmptyChargeMul				= 3,						-- When ink tank is empty, charging time increases by N times.
	MinVelocity					= 12,						-- Initial velocity at minimum charge[Splatoon units/frame]
	MaxVelocity					= 48,						-- Initial velocity at maximum charge[Splatoon units/frame]
	MinDamage					= .40000001,				-- Minimum damage[-]
	MaxDamage					= 1,						-- Maximum damage before fully chaged[-]
	MinColRadius				= 1,						-- Minimum collision radius[Splatoon units]
	MaxColRadius				= 1,						-- Maximum collision radius[Splatoon units]
	FullDamage					= 1.60000002,				-- Damage at maximum charge[-]
	TakeAmmo					= .18000001,				-- Ink consumption per full charged shot[-]
	MoveSpeed					= .2,						-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul						= .69999999,				-- Jump power multiplier when fully charged[-]
	MaxChargeSplashPaintRadius	= 18.5,						-- Painting radius at maximum charge[Splatoon units]
	Delay = {
		Aim						= 20,						-- Change hold type[frames]
		Reload					= 20,						-- Start reloading after firing weapon[frames]
		Crouch					= 6,						-- Cannot crouch for some frames after firing[frames]
		MinCharge				= 8,						-- Time between pressing MOUSE1 and beginning of charge[frames]
		MaxCharge				= 60,						-- Time between pressing MOUSE1 and being fully charged[frames]
	},
})
SWEP.Base = "weapon_shooter"

local function GetLerp(frac, min, max, full)
	return frac < 1 and Lerp(frac, min, max) or full or max
end

function SWEP:GetColRadius()
	return GetLerp(self:GetChargeProgress(), self.Primary.MinColRadius, self.Primary.ColRadius)
end

function SWEP:GetRange()
	return GetLerp(self:GetChargeProgress(true), self.Primary.MinRange, self.Primary.MaxRange, self.Primary.Range)
end

function SWEP:GetInkVelocity()
	return GetLerp(self:GetChargeProgress(), self.Primary.MinVelocity, self.Primary.MaxVelocity, self.Primary.InitVelocity)
end

function SWEP:GetChargeProgress(ping)
	local frac = CurTime() - self:GetCharge() - self.Primary.MinChargeTime
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac	/ (self.Primary.MaxChargeTime - self.Primary.MinChargeTime), 0, 1)
end

function SWEP:ResetCharge()
	self:SetCharge(math.huge)
	self:SetFullChargeFlag(false)
	self.JumpPower = ss.InklingJumpPower
	if ss.mp and SERVER then return end
	self.AimSound:Stop()
end

SWEP.SharedDeploy = SWEP.ResetCharge
SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p) table.insert(p, self.AimSound) end
function SWEP:PlayChargeSound()
	local prog = self:GetChargeProgress()
	if 0 < prog and prog < 1 then
		self.AimSound:PlayEx(1, math.max(self.AimSound:GetPitch(), (self.gap - prog * self.gap + prog) * 100))
	else
		self.AimSound:Stop()
		self.AimSound:ChangePitch(self.gap * 100)
		if prog == 1 and not self:GetFullChargeFlag() then
			if ss.mp and CLIENT then
				surface.PlaySound(ss.ChargerBeep)
			else
				self.Owner:SendLua "surface.PlaySound(SplatoonSWEPs.ChargerBeep)"
			end
		end
	end
end

function SWEP:SharedInit()
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.AirTimeFraction = 1 - 1 / self.Primary.EmptyChargeMul
	self.gap = self.Primary.MinChargeTime / self.Primary.MaxChargeTime
	self:SetAimTimer(CurTime())
	self:SetCharge(math.huge)
	self:SetFullChargeFlag(false)
end

function SWEP:SharedPrimaryAttack()
	if not IsValid(self.Owner) then return end
	if self:GetCharge() < math.huge then
		local prog = self:GetChargeProgress()
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, self.Primary.JumpPower)
		if ss.sp or CLIENT and self:IsFirstTimePredicted() then self:PlayChargeSound() end
		if prog == 0 then return end
		if not self.Owner:OnGround() then
			self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
		end
		
		if prog == 1 and not self:GetFullChargeFlag() then
			self:SetFullChargeFlag(true)
		end
		
		return
	end
	
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetCharge(CurTime())
	self:SetFullChargeFlag(false)
	
	if not self:IsFirstTimePredicted() then return end
	local e = EffectData() e:SetEntity(self)
	util.Effect("SplatoonSWEPsChargerLaser", e)
	self:EmitSound "SplatoonSWEPs.ChargerPreFire"
end

function SWEP:SharedThink()
	if self:GetCharge() == math.huge or self:GetKey() ~= IN_ATTACK then return end
	
end

function SWEP:KeyPress(ply, key)
	if key == IN_ATTACK then return end
	self:ResetCharge()
	self:SetCooldown(CurTime())
end

function SWEP:KeyRelease(ply, key)
	if key ~= IN_ATTACK or self:GetCharge() == math.huge then return end
	local prog = self:GetChargeProgress()
	local ShootSound = prog > .75 and self.ShootSound2 or self.ShootSound
	local pitch = 100 + (prog > .75 and 15 or 0)
	if SERVER then self:SpawnInk() end
	self:EmitSound(ShootSound, 80, pitch - prog * 20)
	self:SetCooldown(CurTime() + self.Primary.MinChargeTime)
	self:SetFireAt(prog)
	self:ResetCharge()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:ResetSequence "fire"
	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "FullChargeFlag")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
end

function SWEP:CustomMoveSpeed()
	return self:GetKey() == IN_ATTACK and Lerp(self:GetChargeProgress(),
	self.InklingSpeed, self.Primary.MoveSpeed) or self.InklingSpeed
end
