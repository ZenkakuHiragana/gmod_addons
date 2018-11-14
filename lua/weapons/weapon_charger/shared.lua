
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"

function SWEP:GetLerp(frac, min, max, full)
	return frac < 1 and Lerp(frac, min, max) or full or max
end

function SWEP:GetColRadius()
	return self:GetLerp(self:GetChargeProgress(CLIENT),
	self.Primary.MinColRadius, self.Primary.ColRadius)
end

function SWEP:GetDamage()
	local p = self.Primary
	local ChargeFrame = p.MaxChargeTime * ss.SecToFrame
	local frac = math.floor(self:GetChargeProgress(CLIENT) * ChargeFrame) / ChargeFrame
	return self:GetLerp(frac, p.MinDamage, p.MaxDamage, p.Damage)
end

function SWEP:GetRange()
	return self:GetLerp(self:GetChargeProgress(CLIENT),
	self.Primary.MinRange, self.Primary.MaxRange, self.Primary.Range)
end

function SWEP:GetInkVelocity()
	return self:GetLerp(self:GetChargeProgress(),
	self.Primary.MinVelocity, self.Primary.MaxVelocity, self.Primary.InitVelocity)
end

function SWEP:GetChargeProgress(ping)
	local timescale = ss.GetTimeScale(self.Owner)
	local frac = CurTime() - self:GetCharge() - self.Primary.MinChargeTime / timescale
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac	/ self.Primary.MaxChargeTime * timescale, 0, 1)
end

function SWEP:GetScopedProgress(ping)
	if not self.Scoped then return 0 end
	if CLIENT and GetViewEntity() ~= self.Owner then return 0 end
	local prog = self:GetChargeProgress(ping)
	local scope = self.Primary.Scope
	if prog < scope.StartMove then return 0 end
	return math.Clamp((prog - scope.StartMove)
		/ (scope.EndMove - scope.StartMove), 0, 1)
end

function SWEP:ResetSkin()
	if not ss.ChargingEyeSkin[self.Owner:GetModel()] then return end
	
	local skin = 0
	if self:GetNWInt "PMID" == ss.PLAYER.NOCHANGE then
		skin = CLIENT and
		GetConVar "cl_playerskin":GetInt() or
		self.BackupPlayerInfo.Playermodel.Skin
	end
	
	if self.Owner:GetSkin() == skin then return end
	self.Owner:SetSkin(skin)
end

function SWEP:ResetCharge()
	self:SetCharge(math.huge)
	self.FullChargeFlag = false
	self.NotEnoughInk = false
	self.JumpPower = ss.InklingJumpPower
	if ss.mp and SERVER then return end
	self.AimSound:Stop()
	self.AimSound:ChangePitch(1)
end

SWEP.SharedDeploy = SWEP.ResetCharge
SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p) table.insert(p, self.AimSound) end
function SWEP:PlayChargeSound()
	if ss.mp and (SERVER or not IsFirstTimePredicted()) then return end
	local prog = self:GetChargeProgress()
	if 0 < prog and prog < 1 then
		self.AimSound:PlayEx(1, math.max(self.AimSound:GetPitch(), prog * 99 + 1))
	else
		self.AimSound:Stop()
		self.AimSound:ChangePitch(1)
		if prog == 1 and not self.FullChargeFlag then
			ss.EmitSound(self.Owner, ss.ChargerBeep)
			self.FullChargeFlag = true
		end
	end
end

function SWEP:SharedInit()
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.AirTimeFraction = 1 - 1 / self.Primary.EmptyChargeMul
	self:SetAimTimer(CurTime())
	self:ResetCharge()
end

function SWEP:SharedPrimaryAttack()
	if not IsValid(self.Owner) then return end
	if self:GetCharge() < math.huge then
		local prog = self:GetChargeProgress()
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, self.Primary.JumpPower)
		self:PlayChargeSound()
		if prog == 0 then return end
		local EnoughInk = self:GetInk() >= prog * self.Primary.TakeAmmo
		if not self.Owner:OnGround() or not EnoughInk then
			self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
			if (ss.sp or CLIENT) and not (self.NotEnoughInk or EnoughInk) then
				self.NotEnoughInk = true
				ss.EmitSound(self.Owner, ss.TankEmpty)
			end
		end
		
		return
	end
	
	if CurTime() > self:GetAimTimer() then
		self:SetSplashInitMul(0)
	end
	
	self.FullChargeFlag = false
	self.AimSound:PlayEx(0, 1)
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetCharge(CurTime() + self.Primary.MinFreezeTime)
	self:SendWeaponAnim(ACT_VM_IDLE)
	
	local skin = ss.ChargingEyeSkin[self.Owner:GetModel()]
	if skin and self.Owner:GetSkin() ~= skin then
		self.Owner:SetSkin(skin)
	end
	
	if not self:IsFirstTimePredicted() then return end
	local e = EffectData() e:SetEntity(self)
	util.Effect("SplatoonSWEPsChargerLaser", e)
	self:EmitSound "SplatoonSWEPs.ChargerPreFire"
end

function SWEP:KeyPress(ply, key)
	if not ss.KeyMaskFind[key] or key == IN_ATTACK then return end
	self:ResetCharge()
	self:SetCooldown(CurTime())
end

function SWEP:Move(ply, mv)
	local p = self.Primary
	local prog = self:GetChargeProgress(CLIENT)
	if self:GetNWBool "ToggleADS" then
		if ply:KeyPressed(IN_USE) then
			self:SetADS(not self:GetADS())
		end
	else
		self:SetADS(ply:KeyDown(IN_USE))
	end
	
	if CurTime() > self:GetAimTimer() and self.Owner:GetSkin() == ss.ChargingEyeSkin[self.Owner:GetModel()] then
		self:ResetSkin()
	end
	
	if ply:KeyDown(IN_ATTACK) or self:GetCharge() == math.huge then return end
	if CurTime() - self:GetCharge() < p.MinChargeTime then return end
	if SERVER and ss.mp then SuppressHostEvents(ply) end
	local inkprog = math.max(p.MinChargeTime / p.MaxChargeTime, prog)
	local ShootSound = prog > .75 and self.ShootSound2 or self.ShootSound
	local pitch = 100 + (prog > .75 and 15 or 0) - prog * 20
	local pos, dir = self:GetFirePosition()
	local ang = dir:Angle()
	ang.yaw = self.Owner:GetAimVector():Angle().yaw
	self.SplashInit = self:GetSplashInitMul() % p.SplashPatterns * (1 - prog)
	self.Range = self:GetRange()
	self.InitVelocity = dir * self:GetInkVelocity()
	self.InitAngle = ang.yaw
	if self:IsFirstTimePredicted() then
		local rnda = p.Recoil * -1
		local rndb = p.Recoil * math.Rand(-1, 1)
		self.ViewPunch = Angle(rnda, rndb, rnda)
		self.ModifyWeaponSize = SysTime()
		
		local e = EffectData()
		e:SetAttachment(self.SplashInit)
		e:SetAngles(ang)
		e:SetColor(self:GetNWInt "ColorCode")
		e:SetEntity(self)
		e:SetFlags(CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0)
		e:SetOrigin(pos)
		e:SetScale(self.Range)
		e:SetStart(self.InitVelocity)
		e:SetRadius(0)
		e:SetMagnitude(prog)
		util.Effect("SplatoonSWEPsShooterInk", e)
		ss.AddInk(ply, pos, ss.GetDropType())
	end
	
	self:EmitSound(ShootSound, 80, pitch)
	self:SetCooldown(CurTime() + p.MaxFreezeTime)
	self:SetFireAt(prog)
	self:SetInk(math.max(0, self:GetInk() - inkprog * p.TakeAmmo))
	self:SetSplashInitMul(self:GetSplashInitMul() + 1)
	self:ResetCharge()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:ResetSequence "fire"
	ply:SetAnimation(PLAYER_ATTACK1)
	if SERVER and ss.mp then SuppressHostEvents() end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
	self:AddNetworkVar("Int", "SplashInitMul")
end

function SWEP:CustomMoveSpeed()
	return self:GetKey() == IN_ATTACK and Lerp(self:GetChargeProgress(),
	self.InklingSpeed, self.Primary.MoveSpeed) or self.InklingSpeed
end

function SWEP:GetAnimWeight()
	return (self:GetFireAt() + .5) / 1.5
end
