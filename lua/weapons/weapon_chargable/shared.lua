
local ss = SplatoonSWEPs
if not ss then return end

SWEP.Base = "weapon_shooter"
SWEP.PrintName = "Chargable base"
SWEP.Spawnable = true

SWEP.ShootSound = "SplatoonSWEPs.SplatCharger"
SWEP.ShootSound2 = "SplatoonSWEPs.SplatChargerFull"
SWEP.WeaponModelName = "models/props_splatoon/weapons/primaries/splat_charger/splat_charger.mdl"
ss:SetViewModelMods(SWEP, {
	["ValveBiped.Bip01_L_Clavicle"] = {pos = Vector(2, 1, 2)},
	["ValveBiped.Bip01_L_Finger0"] = {angle = Angle(10, -3, 0)},
	["ValveBiped.Bip01_L_Finger02"] = {angle = Angle(0, 15, 0)},
	["ValveBiped.Bip01_L_Finger1"] = {angle = Angle(-35, -10, 0)},
	["ValveBiped.Bip01_L_Finger2"] = {angle = Angle(-23, -20, 0)},
	["ValveBiped.Bip01_L_Finger3"] = {angle = Angle(-10, -23, 0)},
	["ValveBiped.Bip01_L_Finger4"] = {angle = Angle(0, -20, 0)},
	["ValveBiped.Bip01_L_Hand"] = {angle = Angle(1, 20, 0)},
	["ValveBiped.Bip01_Spine4"] = {
		pos = Vector(-2.5, -4, 0),
		angle = Angle(0, -10, 0),
	},
})

ss:SetViewModel(SWEP, {
	pos = Vector(3.8, -23.8, -7),
	angle = Angle(10, 80, 90),
	size = Vector(0.5, 0.5, 0.5),
})

ss:SetWorldModel(SWEP, {
	pos = Vector(4.5, 1.5, 0),
	angle = Angle(-173, -173.5, -5),
})

SWEP.Base = "weapon_charger"
ss:SetPrimary(SWEP, {
	MuzzlePosition				= Vector(54.5, 0, 4.6),	-- Thirdperson muzzle position in local coord.[Hammer units]
	MinRange					= 90,					-- Minimum distance [Splatoon units]
	MaxRange					= 250,					-- Maximum distance before fully charged [Splatoon units]
	FullRange					= 250,					-- Distance when fully charged [Splatoon units]
	EmptyChargeMul				= 3,					-- When ink tank is empty, charging time increases by N times.
	MinVelocity					= 12,					-- Initial velocity at minimum charge[Splatoon units/frame]
	MaxVelocity					= 48,					-- Initial velocity at maximum charge[Splatoon units/frame]
	MinDamage					= .40000001,			-- Minimum damage[-]
	MaxDamage					= 1,					-- Maximum damage before fully chaged[-]
	MinColRadius				= 1,					-- Minimum collision radius[Splatoon units]
	MaxColRadius				= 1,					-- Maximum collision radius[Splatoon units]
	FullDamage					= 1.60000002,			-- Damage at maximum charge[-]
	TakeAmmo					= .18000001,			-- Ink consumption per full charged shot[-]
	MoveSpeed					= .2,					-- Walk speed while fully charged[Splatoon units/frame]
	JumpMul						= .69999999,			-- Jump power multiplier when fully charged[-]
	MaxChargeSplashPaintRadius	= 18.5,					-- Painting radius at maximum charge[Splatoon units]
	Delay = {
		Aim						= 20,					-- Change hold type[frames]
		Reload					= 20,					-- Start reloading after firing weapon[frames]
		Crouch					= 6,					-- Cannot crouch for some frames after firing[frames]
		MinCharge				= 8,					-- Time between pressing MOUSE1 and beginning of charge[frames]
		MaxCharge				= 60,					-- Time between pressing MOUSE1 and being fully charged[frames]
	},
})
SWEP.Base = "weapon_shooter"
function SWEP:GetRange()
	local frac = self:GetChargeProgress(true)
	return frac < 1 and Lerp(frac, self.Primary.MinRange, self.Primary.MaxRange) or self.Primary.Range
end

function SWEP:GetChargeProgress(ping)
	local frac = CurTime() - self:GetCharge() - self.Primary.MinChargeTime
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac	/ (self.Primary.MaxChargeTime - self.Primary.MinChargeTime), 0, 1)
end

function SWEP:ResetCharge()
	self:SetCharge(math.huge)
	self:SetChargeFlag(false)
	self.JumpPower = ss.InklingJumpPower
	
	if SERVER or not self:IsFirstTimePredicted() then return end
	self.AimSound:Stop()
end

function SWEP:AddPlaylist(p) table.insert(p, self.AimSound) end
function SWEP:SharedInit()
	self.gap = self.Primary.MinChargeTime / self.Primary.MaxChargeTime
	self:SetAimTimer(CurTime())
	self:SetCharge(math.huge)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ChargeFlag")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Charge")
end

function SWEP:CustomMoveSpeed()
	return self:CheckButtons(IN_ATTACK) and Lerp(self:GetChargeProgress(),
	self.InklingSpeed, self.Primary.MoveSpeed) or self.InklingSpeeda
end

function SWEP:SharedPrimaryAttack()
	if not self:CheckButtons(IN_ATTACK) then return end
	if self:IsFirstTimePredicted() and CurTime() < self.Cooldown then return end
	if self:GetChargeFlag() then return end
	if self:GetCharge() < math.huge then return end
	if SERVER then
		self:SetCharge(CurTime())
		self:SetChargeFlag(true)
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		ss:ShouldEmitSound(self, "SplatoonSWEPs.ChargerPreFire")
	elseif not game.SinglePlayer() and self.Owner == LocalPlayer() then
		self:SetCharge(CurTime())
		self:SetChargeFlag(true)
		self:SetAimTimer(math.max(self:GetAimTimer(), CurTime() + self.Primary.AimDuration))
	end
	
	if SERVER and game.SinglePlayer() or CLIENT and self.Owner == LocalPlayer() then
		self:EmitSound "SplatoonSWEPs.ChargerPreFire"
	end
end

function SWEP:SharedThink()
	if self:IsMine() and not self:GetChargeFlag() then return end
	local time = CurTime() + self.Primary.AimDuration
	local prog = self:GetChargeProgress()
	if self:GetChargeFlag() then
		self:SetAimTimer(time)
		self.Cooldown = CurTime() + self.Primary.MinChargeTime
	end
	
	self.JumpPower = Lerp(prog, ss.InklingJumpPower, self.Primary.JumpPower)
	
	if not self:IsMine() then
		local fire = self.PrevChargeFlag and not self:GetThrowing()
		self.PrevChargeFlag = self:GetChargeFlag()
		if self:GetChargeFlag() then self.PrevCharge = prog return end
		if fire then prog = self.PrevCharge end
	end
	
	if CLIENT and self:IsFirstTimePredicted() then
		if 0 < prog and prog < 1 then
			self.AimSound:Play()
			self.AimSound:ChangeVolume(1)
			self.AimSound:ChangePitch((self.gap - prog * self.gap + prog) * 100)
		else
			self.AimSound:Stop()
		end
		
		if self.Owner == LocalPlayer() and self.PrevCharge < 1 and prog == 1 then
			surface.PlaySound(ss.ChargerBeep)
		end
		
		self.PrevCharge = prog
	end
	
	if prog == 0 then return end
	if self.Owner:KeyDown(IN_ATTACK) then
		self:CheckButtons()
		if self.ValidKey == IN_ATTACK then return end
		if self.ValidKey > 0 then
			self:ResetCharge()
			self.Cooldown = 0
			return
		end
	end
	
	local ShootSound = prog > .75 and self.ShootSound2 or self.ShootSound
	local pitch = 100 + (prog > .75 and 15 or 0)
	ss:ShouldSuppress(self.Owner)
	self:ResetCharge()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	if SERVER then
		self:EmitSound(ShootSound)
	elseif not game.SinglePlayer() and IsFirstTimePredicted() then
		self:EmitSound(ShootSound, 80, pitch - prog * 20)
	end
	
	local hasink = self:GetInk() > 0
	local able = hasink and not self:CheckCannotStandup()
	ss:ShouldSuppress()
end
