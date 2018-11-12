
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"

function SWEP:GetChargeProgress(ping)
	local timescale = ss.GetTimeScale(self.Owner)
	local frac = CurTime() - self:GetCharge() - self.Primary.MinChargeTime / timescale
	if ping then frac = frac + self:Ping() end
	return math.Clamp(frac	/ self.Primary.MaxChargeTime[2] * timescale, 0, 1)
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
	self:SetFullChargeFlag(false)
	self:SetFireInk(0)
	self.JumpPower = ss.InklingJumpPower
	if ss.mp and SERVER then return end
	for _, s in ipairs(self.SpinupSound) do s:Stop() end
	self.AimSound:Stop()
	self.AimSound:ChangePitch(1)
end

SWEP.SharedDeploy = SWEP.ResetCharge
SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p)
	table.insert(p, self.AimSound)
	for _, s in ipairs(self.SpinupSound) do table.insert(p, s) end
end

function SWEP:PlayChargeSound()
	local prog = self:GetChargeProgress()
	if prog == 1 then
		self.AimSound:Stop()
		self.SpinupSound[1]:Stop()
		self.SpinupSound[2]:Stop()
		self.SpinupSound[3]:Play()
		self.BeepSound:PlayEx(1, 115)
	elseif prog > 0 then
		self.AimSound:PlayEx(.75, math.max(self.AimSound:GetPitch(), prog * 90 + 1))
		self.SpinupSound[3]:Stop()
		if prog < self.MediumCharge then
			self.SpinupSound[1]:PlayEx(1, math.max(self.SpinupSound[2]:GetPitch(), 100 + prog * 25))
			self.SpinupSound[2]:Stop()
			self.SpinupSound[2]:ChangePitch(1)
		else
			prog = (prog - self.MediumCharge) / (1 - self.MediumCharge)
			self.BeepSound:PlayEx(1, 100)
			self.SpinupSound[2]:PlayEx(1, math.max(self.SpinupSound[2]:GetPitch(), 80 + prog * 20))
			self.SpinupSound[1]:Stop()
			self.SpinupSound[1]:ChangePitch(1)
		end
	end
end

function SWEP:SharedInit()
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.BeepSound = CreateSound(self, ss.ChargerBeep)
	self.SpinupSound = {}
	for _, s in ipairs(self.ChargeSound) do table.insert(self.SpinupSound, CreateSound(self, s)) end
	self.AirTimeFraction = 1 - 1 / self.Primary.EmptyChargeMul
	self.MediumCharge = (self.Primary.MaxChargeTime[1] - self.Primary.MinChargeTime) / (self.Primary.MaxChargeTime[2] - self.Primary.MinChargeTime)
	self:SetAimTimer(CurTime())
	self:ResetCharge()
end

function SWEP:SharedPrimaryAttack()
	if not IsValid(self.Owner) then return end
	if self:GetCharge() < math.huge then
		local prog = self:GetChargeProgress()
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		self.JumpPower = Lerp(prog, ss.InklingJumpPower, self.Primary.JumpPower)
		if ss.sp or CLIENT and self:IsFirstTimePredicted() then self:PlayChargeSound() end
		if prog == 0 then return end
		local EnoughInk = self:GetInk() >= prog * self.Primary.MaxTakeAmmo
		if not self.Owner:OnGround() or not EnoughInk then
			self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
			if not (self.NotEnoughInk or EnoughInk) then
				self.NotEnoughInk = true
				if CLIENT then
					if ss.mp then
						if IsFirstTimePredicted() and self:IsCarriedByLocalPlayer() then
							surface.PlaySound(ss.TankEmpty)
						end
					else
						self.Owner:SendLua "surface.PlaySound(SplatoonSWEPs.TankEmpty)"
					end
				end
			end
		end
		
		if prog == 1 then
			self:SetFullChargeFlag(false)
		elseif prog > self.MediumCharge and not self:GetFullChargeFlag() then
			self:SetFullChargeFlag(true)
		end
		
		return
	end
	
	self.AimSound:PlayEx(0, 1)
	self.SpinupSound[1]:Play()
	self:SetAimTimer(CurTime() + self.Primary.AimDuration)
	self:SetCharge(CurTime())
	self:SetFullChargeFlag(false)
	self:SendWeaponAnim(ACT_VM_IDLE)
	
	local skin = ss.ChargingEyeSkin[self.Owner:GetModel()]
	if skin and self.Owner:GetSkin() ~= skin then
		self.Owner:SetSkin(skin)
	end
end

function SWEP:KeyPress(ply, key)
	if key == IN_JUMP then self:SetJump(CurTime()) end
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
	-- print(self:GetSpreadJumpFraction())
	if ply:OnGround() then
		if CurTime() - self:GetJump() < self.Primary.SpreadJumpDelay then
			self:SetJump(self:GetJump() - FrameTime() / 2)
		end
	end
	
	if CurTime() > self:GetAimTimer() and self.Owner:GetSkin() == ss.ChargingEyeSkin[self.Owner:GetModel()] then
		self:ResetSkin()
	end
	
	if ply:KeyDown(IN_ATTACK) or self:GetCharge() == math.huge then return end
	if CurTime() - self:GetCharge() < p.MinChargeTime then return end
	local Duration
	if prog < self.MediumCharge then
		Duration = self.Primary.FireDuration[1] * prog
	else
		Duration = Lerp((prog - self.MediumCharge) / (1 - self.MediumCharge), self.Primary.FireDuration[1], self.Primary.FireDuration[2])
	end
	
	self:SetFireAt(prog)
	self:ResetCharge()
	self:SetFireInk(math.floor(Duration / self.Primary.Delay) + 1)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Bool", "FullChargeFlag")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Bias")
	self:AddNetworkVar("Float", "BiasVelocity")
	self:AddNetworkVar("Float", "Charge")
	self:AddNetworkVar("Float", "FireAt")
	self:AddNetworkVar("Float", "Jump")
	self:AddNetworkVar("Int", "FireInk")
	self:AddNetworkVar("Int", "SplashInitMul")
	
	local rand = "SplatoonSWEPs: Spread"
	self.FireSplatling = self:AddNetworkSchedule(0, function(self, schedule)
		if self:GetFireInk() == 0 then return end
		if self:GetHolstering() then return end
		if self:CheckCannotStandup() then return end
		if self:GetThrowing() then return end
		if ss.sp and CLIENT then return end
		if self:GetNextPrimaryFire() > CurTime() then return end
		if not IsValid(self.Owner) then return end
		if SERVER and ss.mp then SuppressHostEvents(self.Owner) end
		
		local p = self.Primary
		local timescale = ss.GetTimeScale(self.Owner)
		local AlreadyAiming = CurTime() < self:GetAimTimer()
		local reloadtime = self.Primary.ReloadDelay / timescale
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay / timescale)
		self:SetAimTimer(CurTime() + p.AimDuration)
		self:SetInk(math.max(0, self:GetInk() - p.TakeAmmo))
		self:SetFireInk(self:GetFireInk() - 1)
		self:SetCooldown(math.max(self:GetCooldown(),
		CurTime() + math.min(p.Delay, p.CrouchDelay) / timescale))
		self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
		self.ReloadSchedule:SetLastCalled(CurTime() + reloadtime)
		
		local pos, dir = self:GetFirePosition()
		local right = self.Owner:GetRight()
		local ang = dir:Angle()
		local angle_initvelocity = Angle(ang)
		local DegRandX, DegRandY = self:GetSpread()
		if self:GetAimTimer() < 1 then
			self:SetBias(p.SpreadBiasJump)
		else
			if not AlreadyAiming then
				self:SetBias(0)
				self:SetBiasVelocity(0)
			end
			
			self:SetBias(math.min(self:GetBias() + p.SpreadBiasStep, p.SpreadBias))
			self:SetBiasVelocity(math.min(self:GetBiasVelocity() + p.SpreadBiasStep, p.SpreadBiasVelocity))
		end
		
		local sgnx = math.Round(util.SharedRandom(rand, 0, 1, CurTime())) * 2 - 1
		local sgny = math.Round(util.SharedRandom(rand, 0, 1, CurTime() * 2)) * 2 - 1
		local sgnv = math.Round(util.SharedRandom(rand, 0, 1, CurTime() * 3)) * 2 - 1
		local SelectIntervalX = self:GetBias() > util.SharedRandom(rand, 0, 1, CurTime() * 4)
		local SelectIntervalY = self:GetBias() > util.SharedRandom(rand, 0, 1, CurTime() * 5)
		local SelectIntervalV = self:GetBiasVelocity() > util.SharedRandom(rand, 0, 1, CurTime() * 6)
		local fracx = util.SharedRandom(rand,
			SelectIntervalX and self:GetBias() or 0,
			SelectIntervalX and 1 or self:GetBias(), CurTime() * 7)
		local fracy = util.SharedRandom(rand,
			SelectIntervalY and self:GetBias() or 0,
			SelectIntervalY and 1 or self:GetBias(), CurTime() * 8)
		local fracv = util.SharedRandom(rand,
			SelectIntervalV and self:GetBias() or 0,
			SelectIntervalV and 1 or self:GetBiasVelocity(), CurTime() * 9)
		local rx = sgnx * fracx * DegRandX
		local ry = sgny * fracy * DegRandY
		local prog, InitVelocity = self:GetFireAt()
		if prog < self.MediumCharge then
			InitVelocity = Lerp(prog, p.MinVelocity, p.MediumVelocity)
		else
			InitVelocity = Lerp(prog - self.MediumCharge, p.MediumVelocity, p.InitVelocity)
		end
		
		ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
		angle_initvelocity:RotateAroundAxis(right:Cross(dir), rx)
		angle_initvelocity:RotateAroundAxis(right, ry)
		InitVelocity = InitVelocity + sgnv * fracv * p.SpreadVelocity * p.InitVelocity
		self.InitVelocity = angle_initvelocity:Forward() * InitVelocity
		self.InitAngle = angle_initvelocity.yaw
		self.SplashInit = self:GetSplashInitMul() % p.SplashPatterns
		self.SplashNum = math.floor(p.SplashNum) + math.Round(util.SharedRandom("SplatoonSWEPs: SplashNum", 0, 1))
		self:SetSplashInitMul(self:GetSplashInitMul() + 1)
		self:ResetSequence "fire"
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		self:EmitSound(self.ShootSound)
		if self:IsFirstTimePredicted() then
			local rnda = p.Recoil * -1
			local rndb = p.Recoil * math.Rand(-1, 1)
			self.ViewPunch = Angle(rnda, rndb, rnda)
			
			local e = EffectData()
			e:SetAttachment(self.SplashInit)
			e:SetAngles(angle_initvelocity)
			e:SetColor(self:GetNWInt "ColorCode")
			e:SetEntity(self)
			e:SetFlags(CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0)
			e:SetOrigin(pos)
			e:SetScale(self.SplashNum)
			e:SetStart(self.InitVelocity)
			util.Effect("SplatoonSWEPsShooterInk", e)
			ss.AddInk(self.Owner, pos, util.SharedRandom("SplatoonSWEPs: Shooter ink type", 4, 9))
		end
		
		if SERVER and ss.mp then SuppressHostEvents() end
	end)
end

function SWEP:CustomMoveSpeed()
	return self:GetFireInk() > 0 and self.Primary.MoveSpeed
	or self:GetCharge() < math.huge and Lerp(self:GetChargeProgress(),
	self.InklingSpeed, self.Primary.MoveSpeedCharge) or self.InklingSpeed
end

function SWEP:GetAnimWeight()
	return (self:GetFireAt() + .5) / 1.5
end

function SWEP:CustomActivity()
	local at = self:GetAimTimer()
	if CLIENT and self:IsCarriedByLocalPlayer() then at = at - self:Ping() end
	if CurTime() > at then return "crossbow" end
	local aimpos = select(3, self:GetFirePosition())
	aimpos = (aimpos == 3 or aimpos == 4) and "rpg" or "crossbow"
	return (self:GetADS() or self.Scoped
	and self:GetChargeProgress(CLIENT) > self.Primary.Scope.StartMove)
	and not ss.ChargingEyeSkin[self.Owner:GetModel()]
	and "ar2" or aimpos
end
