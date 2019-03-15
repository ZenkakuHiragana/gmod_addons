
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_shooter"
SWEP.FlashDuration = .25

local rand = "SplatoonSWEPs: Spread"
local randsplash = "SplatoonSWEPs: SplashNum"
function SWEP:GetChargeProgress(ping)
	local timescale = ss.GetTimeScale(self.Owner)
	local frac = CurTime() - self:GetCharge() - self.Primary.MinChargeTime / timescale
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac	/ self.Primary.MaxChargeTime[2] * timescale, 0, 1)
end

function SWEP:GetInitVelocity(r)
	local p, v = self.Primary
	local prog = self:GetFireInk() > 0 and self:GetFireAt() or self:GetChargeProgress(CLIENT)
	if prog < self.MediumCharge then
		v = Lerp(prog / self.MediumCharge, p.MinVelocity, p.MediumVelocity)
	else
		v =  Lerp(prog - self.MediumCharge, p.MediumVelocity, p.InitVelocity)
	end

	if r then return v end
	local sgnv = math.Round(util.SharedRandom(rand, 0, 1, CurTime() * 7)) * 2 - 1
	local SelectIntervalV = self:GetBiasVelocity() > util.SharedRandom(rand, 0, 1, CurTime() * 8)
	local fracmin = SelectIntervalV and self:GetBias() or 0
	local fracmax = SelectIntervalV and 1 or self:GetBiasVelocity(), CurTime() * 9
	local frac = util.SharedRandom(rand, fracmin, fracmax)

	return v + sgnv * frac * p.SpreadVelocity * p.InitVelocity
end

function SWEP:GetRange()
	return self:GetInitVelocity(true) * (self.Primary.Straight + ss.ShooterDecreaseFrame / 2)
end

function SWEP:GetSpreadAmount()
	local sx, sy = self:GetBase().GetSpreadAmount(self)
	return sx, (self.Primary.Spread + sy) / 2
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
	self:SetFireInk(0)
	self.JumpPower = ss.InklingJumpPower
	if ss.mp and CLIENT and not IsFirstTimePredicted() then return end
	for _, s in ipairs(self.SpinupSound) do s:Stop() end
	self.AimSound:Stop()
end

SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p)
	table.insert(p, self.AimSound)
	if not self.SpinupSound then return end
	for _, s in ipairs(self.SpinupSound) do table.insert(p, s) end
end

function SWEP:PlayChargeSound()
	if ss.mp and CLIENT and not IsFirstTimePredicted() then return end
	local prog = self:GetChargeProgress()
	if prog == 1 then
		self.AimSound:Stop()
		self.SpinupSound[1]:Stop()
		self.SpinupSound[2]:Stop()
		self.SpinupSound[3]:Play()
	elseif prog > 0 then
		self.AimSound:PlayEx(.75, math.max(self.AimSound:GetPitch(), prog * 90 + 1))
		self.SpinupSound[3]:Stop()
		if prog < self.MediumCharge then
			self.SpinupSound[1]:PlayEx(1, math.max(self.SpinupSound[2]:GetPitch(), 100 + prog * 25))
			self.SpinupSound[2]:Stop()
			self.SpinupSound[2]:ChangePitch(1)
		else
			prog = (prog - self.MediumCharge) / (1 - self.MediumCharge)
			self.SpinupSound[2]:PlayEx(1, math.max(self.SpinupSound[2]:GetPitch(), 80 + prog * 20))
			self.SpinupSound[1]:Stop()
			self.SpinupSound[1]:ChangePitch(1)
		end
	end
end

function SWEP:SharedDeploy()
	self:SetSplashInitMul(1)
	self:GenerateSplashInitTable()
	self:ResetCharge()
end

function SWEP:SharedInit()
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.SpinupSound = {}
	self.SplashInitTable = {}
	for _, s in ipairs(self.ChargeSound) do table.insert(self.SpinupSound, CreateSound(self, s)) end
	self.AirTimeFraction = 1 - 1 / self.Primary.EmptyChargeMul
	self.MediumCharge = (self.Primary.MaxChargeTime[1] - self.Primary.MinChargeTime) / (self.Primary.MaxChargeTime[2] - self.Primary.MinChargeTime)
	self.SpinupEffectTime = CurTime()
	self:SetAimTimer(CurTime())
	self:SharedDeploy()
	self:AddSchedule(0, function()
		if CLIENT and not self:IsMine() then return end
		local e = EffectData()
		local prog = self:GetChargeProgress()
		e:SetEntity(self)
		if prog == 1 then
			if not self.FullChargeFlag then
				if not self:IsFirstTimePredicted() then return end
				if CurTime() < self.SpinupEffectTime then return end
				self.SpinupEffectTime = CurTime() + .2
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents(self.Owner) end
				e:SetScale(8)
				e:SetFlags(0)
				util.Effect("SplatoonSWEPsSplatlingSpinup", e)
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents() end
				return
			end

			if self:IsFirstTimePredicted() then
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents(self.Owner) end
				e:SetScale(25)
				e:SetFlags(1)
				util.Effect("SplatoonSWEPsSplatlingSpinup", e)
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents() end
			end

			if SERVER then return end
			self:EmitSound(ss.ChargerBeep, 75, 115)
			self.FullChargeFlag = false
			self.CrosshairFlashTime = CurTime() - self:Ping()
		elseif self.MediumCharge < prog and prog < 1 and not self.FullChargeFlag then
			if self:IsFirstTimePredicted() then
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents(self.Owner) end
				e:SetScale(12)
				e:SetFlags(0)
				util.Effect("SplatoonSWEPsSplatlingSpinup", e)
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents() end
			end

			if SERVER then return end
			self:EmitSound(ss.ChargerBeep)
			self.FullChargeFlag = true
			self.CrosshairFlashTime = CurTime() - .1 - self:Ping()
		end
	end)
end

function SWEP:SharedPrimaryAttack()
	if not IsValid(self.Owner) then return end
	if self:GetCharge() < math.huge then
		local prog = self:GetChargeProgress(CLIENT)
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, self.Primary.JumpPower)
		if prog > 0 then
			local EnoughInk = self:GetInk() >= prog * self.Primary.MaxTakeAmmo * ss.MaxInkAmount
			if not self.Owner:OnGround() or not EnoughInk then
				if EnoughInk or self:GetNWBool "canreloadstand" then
					self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
				else
					local timescale = ss.GetTimeScale(self.Owner)
					local elapsed = prog * self.Primary.MaxChargeTime[2] / timescale
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

	self.FullChargeFlag = false
	self.AimSound:PlayEx(0, 1)
	self.SpinupSound[1]:Play()
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetCharge(CurTime())
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
end

function SWEP:KeyPress(ply, key)
	if key == IN_JUMP then self:SetJump(CurTime()) end
	if not ss.KeyMaskFind[key] or key == IN_ATTACK then return end
	self:ResetCharge()
	self:SetCooldown(CurTime())
end

function SWEP:Move(ply)
	if ply:IsPlayer() then
		if self:GetNWBool "toggleads" then
			if ply:KeyPressed(IN_USE) then
				self:SetADS(not self:GetADS())
			end
		else
			self:SetADS(ply:KeyDown(IN_USE))
		end
	end

	if ply:OnGround() then
		if CurTime() - self:GetJump() < self.Primary.SpreadJumpDelay then
			self:SetJump(self:GetJump() - FrameTime() / 2)
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

	if self:GetFireInk() > 0 then
		if self:CheckCannotStandup() then return end
		if self:GetThrowing() then return end
		if CLIENT and (ss.sp or not self:IsMine()) then return end
		if self:GetNextPrimaryFire() > CurTime() then return end
		if ply:IsPlayer() and SERVER and ss.mp then SuppressHostEvents(ply) end

		local p = self.Primary
		local timescale = ss.GetTimeScale(ply)
		local reloadtime = self.Primary.ReloadDelay / timescale
		local AlreadyAiming = CurTime() < self:GetAimTimer()
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay / timescale)
		self:SetAimTimer(CurTime() + p.AimDuration)
		self:SetFireInk(self:GetFireInk() - 1)
		self:SetInk(math.max(0, self:GetInk() - self.TakeAmmo))
		self:SetCooldown(math.max(self:GetCooldown(),
		CurTime() + math.min(p.Delay, p.CrouchDelay) / timescale))
		self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
		self.ReloadSchedule:SetLastCalled(CurTime() + reloadtime)

		if CurTime() - self:GetJump() > p.SpreadJumpDelay then
			if not AlreadyAiming then self:SetBiasVelocity(0) end
			self:SetBiasVelocity(math.min(self:GetBiasVelocity() + p.SpreadBiasStep, p.SpreadBiasVelocity))
		end

		if self:IsFirstTimePredicted() then
			local e = EffectData()
			e:SetEntity(self)
			util.Effect("SplatoonSWEPsSplatlingMuzzleFlash", e,
			not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
		end

		self:CreateInk()
		if SERVER and ss.mp then SuppressHostEvents() end
	else
		local p = self.Primary
		if self:GetCharge() == math.huge then return end
		if ply:IsPlayer() and ply:KeyDown(IN_ATTACK) then return end
		if not ply:IsPlayer() and self:ShouldChargeWeapon() then return end
		if CurTime() - self:GetCharge() < p.MinChargeTime then return end
		local prog, Duration = self:GetChargeProgress()
		if prog < self.MediumCharge then
			Duration = self.Primary.FireDuration[1] * prog / self.MediumCharge
		else
			Duration = Lerp((prog - self.MediumCharge) / (1 - self.MediumCharge), self.Primary.FireDuration[1], self.Primary.FireDuration[2])
		end

		self:SetFireAt(prog)
		self:ResetCharge()
		self:SetFireInk(math.floor(Duration / self.Primary.Delay) + 1)
		self.TakeAmmo = p.MaxTakeAmmo * ss.MaxInkAmount * prog / self:GetFireInk()
	end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Bias")
	self:AddNetworkVar("Float", "BiasVelocity")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
	self:AddNetworkVar("Float", "Jump")
	self:AddNetworkVar("Int", "FireInk")
	self:AddNetworkVar("Int", "SplashInitMul")
end

function SWEP:CustomMoveSpeed()
	return self:GetFireInk() > 0 and self.Primary.MoveSpeed
	or self:GetCharge() < math.huge and Lerp(self:GetChargeProgress(),
	self.InklingSpeed, self.Primary.MoveSpeedCharge) or self.InklingSpeed
end

function SWEP:CustomActivity()
	local at = self:GetAimTimer()
	if CLIENT and self:IsCarriedByLocalPlayer() then at = at - self:Ping() end
	if CurTime() > at then return "crossbow" end
	local aimpos = select(3, self:GetFirePosition())
	return (aimpos == 3 or aimpos == 4) and "rpg" or "crossbow"
end

function SWEP:UpdateAnimation(ply, vel, max) end
