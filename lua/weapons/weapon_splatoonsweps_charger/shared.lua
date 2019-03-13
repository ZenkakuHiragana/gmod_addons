
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_shooter"
SWEP.FlashDuration = .25

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
	return self:GetLerp(self:GetChargeProgress(),
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
	return math.Clamp(frac / self.Primary.MaxChargeTime * timescale, 0, 1)
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
	if ss.ChargingEyeSkin[self.Owner:GetModel()] then
		local skin = 0
		if self:GetNWInt "playermodel" == ss.PLAYER.NOCHANGE then
			skin = CLIENT and
			GetConVar "cl_playerskin":GetInt() or
			self.BackupPlayerInfo.Playermodel.Skin
		end

		if self.Owner:GetSkin() == skin then return end
		self.Owner:SetSkin(skin)
	elseif ss.TwilightPlayermodels[self.Owner:GetModel()] then
		local l = self.Owner:GetFlexIDByName "Blink_L"
		local r = self.Owner:GetFlexIDByName "Blink_R"
		if l then self.Owner:SetFlexWeight(l, 0) end
		if r then self.Owner:SetFlexWeight(r, 0) end
	end
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
	if not (ss.sp and SERVER and not self.Owner:IsPlayer()) and 0 < prog and prog < 1 then
		self.AimSound:PlayEx(1, math.max(self.AimSound:GetPitch(), prog * 99 + 1))
	else
		self.AimSound:Stop()
		self.AimSound:ChangePitch(1)
	end
end

function SWEP:SharedInit()
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.AirTimeFraction = 1 - 1 / self.Primary.EmptyChargeMul
	self:SetAimTimer(CurTime())
	self:ResetCharge()
	self:AddSchedule(0, function()
		local prog = self:GetChargeProgress()
		if prog == 1 and not self.FullChargeFlag then
			if CLIENT then
				self.CrosshairFlashTime = CurTime() - self:Ping()
				ss.EmitSound(self.Owner, ss.ChargerBeep)
			end

			self.FullChargeFlag = true
			if self.Scoped and self:IsMine() and not (CLIENT and self:IsTPS() and self:GetNWBool "usertscope") then return end
			if SERVER and self.Owner:IsPlayer() then SuppressHostEvents(self.Owner) end
			local e = EffectData()
			e:SetEntity(self)
			e:SetFlags(0)
			util.Effect("SplatoonSWEPsMuzzleFlash", e)
			if SERVER and self.Owner:IsPlayer() then SuppressHostEvents() end

			return
		end

		self.FullChargeFlag = prog == 1
	end)
end

function SWEP:SharedPrimaryAttack()
	if not IsValid(self.Owner) then return end
	if self:GetCharge() < math.huge then
		local prog = self:GetChargeProgress(CLIENT)
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, self.Primary.JumpPower)
		if prog > 0 then
			local EnoughInk = self:GetInk() >= prog * self:GetTakeAmmo()
			if not self.Owner:OnGround() or not EnoughInk then
				if EnoughInk or self:GetNWBool "canreloadstand" then
					self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
				else
					local timescale = ss.GetTimeScale(self.Owner)
					local elapsed = prog * self.Primary.MaxChargeTime / timescale
					local min = self.Primary.MinChargeTime / timescale
					local ping = CLIENT and self:Ping() or 0
					self:SetCharge(CurTime() + FrameTime() - elapsed - min + ping)
				end

				if (ss.sp or CLIENT) and not (self.NotEnoughInk or EnoughInk) then
					self.NotEnoughInk = true
					ss.EmitSound(self.Owner, ss.TankEmpty)
				end
			end
		end

		self:PlayChargeSound()
		return
	end

	if CurTime() > self:GetAimTimer() then
		self:SetSplashInitMul(0)
	end

	self.FullChargeFlag = false
	self.AimSound:PlayEx(0, 1)
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetCharge(CurTime() + self.Primary.MinFreezeTime)
	self:SetWeaponAnim(ACT_VM_IDLE)

	local skin = ss.ChargingEyeSkin[self.Owner:GetModel()]
	if skin and self.Owner:GetSkin() ~= skin then
		self.Owner:SetSkin(skin)
	elseif ss.TwilightPlayermodels[self.Owner:GetModel()] then
		local l = self.Owner:GetFlexIDByName "Blink_L"
		local r = self.Owner:GetFlexIDByName "Blink_R"
		if l then self.Owner:SetFlexWeight(l, .3) end
		if r then self.Owner:SetFlexWeight(r, 1) end
	end

	if not self:IsFirstTimePredicted() then return end
	local e = EffectData() e:SetEntity(self)
	util.Effect("SplatoonSWEPsChargerLaser", e, true,
	not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
	self:EmitSound "SplatoonSWEPs.ChargerPreFire"
end

function SWEP:KeyPress(ply, key)
	if not ss.KeyMaskFind[key] or key == IN_ATTACK then return end
	self:ResetCharge()
	self:SetCooldown(CurTime())
end

function SWEP:Move(ply)
	local p = self.Primary
	local prog = self:GetChargeProgress()
	if ply:IsPlayer() then
		if self:GetNWBool "toggleads" then
			if ply:KeyPressed(IN_USE) then
				self:SetADS(not self:GetADS())
			end
		else
			self:SetADS(ply:KeyDown(IN_USE))
		end
	end

	if CurTime() > self:GetAimTimer() then
		local f = ply:GetFlexIDByName "Blink_R"
		if ply:GetSkin() == ss.ChargingEyeSkin[ply:GetModel()]
		or ss.TwilightPlayermodels[ply:GetModel()]
		and f and ply:GetFlexWeight(f) == 1 then
			self:ResetSkin()
		end
	end

	if self:GetCharge() == math.huge then return end
	if ply:IsPlayer() and ply:KeyDown(IN_ATTACK) then return end
	if not ply:IsPlayer() and self:ShouldChargeWeapon() then return end
	if CurTime() - self:GetCharge() < p.MinChargeTime then return end
	if ply:IsPlayer() and SERVER and ss.mp then SuppressHostEvents(ply) end
	local inkprog = math.max(p.MinChargeTime / p.MaxChargeTime, prog)
	local ShootSound = prog > .75 and self.ShootSound2 or self.ShootSound
	local pitch = 100 + (prog > .75 and 15 or 0) - prog * 20
	local pos, dir = self:GetFirePosition()
	local ang = dir:Angle()
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
		e:SetColor(self:GetNWInt "inkcolor")
		e:SetEntity(self)
		e:SetFlags(CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0)
		e:SetOrigin(pos)
		e:SetScale(self.Range)
		e:SetStart(self.InitVelocity)
		e:SetRadius(0)
		e:SetMagnitude(prog)
		util.Effect("SplatoonSWEPsChargerInk", e)
		ss.AddInk(ply, pos, ss.GetDropType())
	end

	self:EmitSound(ShootSound, 80, pitch)
	self:SetCooldown(CurTime() + p.MaxFreezeTime)
	self:SetFireAt(prog)
	self:SetInk(math.max(0, self:GetInk() - inkprog * self:GetTakeAmmo()))
	self:SetSplashInitMul(self:GetSplashInitMul() + 1)
	self:ResetCharge()
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:ResetSequence "fire"

	if not ply:IsPlayer() then return end
	ply:SetAnimation(PLAYER_ATTACK1)
	if SERVER and ss.mp then SuppressHostEvents() end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
	self:AddNetworkVar("Int", "SplashInitMul")
	if not self.Scoped then return end

	local getads = self.GetADS
	local scope = self.Primary.Scope
	function self:GetADS(org)
		if org then return getads(self) end
		return getads(self) or self:GetChargeProgress() > scope.StartMove
	end
end

function SWEP:CustomMoveSpeed()
	return self:GetKey() == IN_ATTACK and Lerp(self:GetChargeProgress(),
	self.InklingSpeed, self.Primary.MoveSpeed) or self.InklingSpeed
end

function SWEP:GetAnimWeight()
	return (self:GetFireAt() + .5) / 1.5
end
