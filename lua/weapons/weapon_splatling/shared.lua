
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
	if ss.mp and CLIENT and not IsFirstTimePredicted() then return end
	for _, s in ipairs(self.SpinupSound) do s:Stop() end
	self.AimSound:Stop()
end

SWEP.SharedDeploy = SWEP.ResetCharge
SWEP.SharedHolster = SWEP.ResetCharge
function SWEP:AddPlaylist(p)
	table.insert(p, self.AimSound)
	for _, s in ipairs(self.SpinupSound) do table.insert(p, s) end
end

function SWEP:PlayChargeSound()
	if ss.mp and CLIENT and not IsFirstTimePredicted() then return end
	local prog = self:GetChargeProgress(CLIENT)
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
		self:PlayChargeSound()
		if prog == 0 then return end
		local EnoughInk = self:GetInk() >= prog * self.Primary.MaxTakeAmmo
		if not self.Owner:OnGround() or not EnoughInk then
			self:SetCharge(self:GetCharge() + FrameTime() * self.AirTimeFraction)
			if not (self.NotEnoughInk or EnoughInk) then
				self.NotEnoughInk = true
				ss.EmitSound(self.Owner, ss.TankEmpty)
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

local rand = "SplatoonSWEPs: Spread"
function SWEP:Move(ply, mv)
	if self:GetNWBool "ToggleADS" then
		if ply:KeyPressed(IN_USE) then
			self:SetADS(not self:GetADS())
		end
	else
		self:SetADS(ply:KeyDown(IN_USE))
	end
	
	if ply:OnGround() then
		if CurTime() - self:GetJump() < self.Primary.SpreadJumpDelay then
			self:SetJump(self:GetJump() - FrameTime() / 2)
		end
	end
	
	if CurTime() > self:GetAimTimer() and self.Owner:GetSkin() == ss.ChargingEyeSkin[self.Owner:GetModel()] then
		self:ResetSkin()
	end
	
	if self:GetFireInk() > 0 then
		if self:CheckCannotStandup() then return end
		if self:GetThrowing() then return end
		if CLIENT and (ss.sp or not self:IsMine()) then return end
		if self:GetNextPrimaryFire() > CurTime() then return end
		if SERVER and ss.mp then SuppressHostEvents(self.Owner) end
		
		local p = self.Primary
		local timescale = ss.GetTimeScale(self.Owner)
		local AlreadyAiming = CurTime() < self:GetAimTimer()
		local reloadtime = self.Primary.ReloadDelay / timescale
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay / timescale)
		self:SetAimTimer(CurTime() + p.AimDuration)
		self:SetFireInk(self:GetFireInk() - 1)
		self:SetInk(math.max(0, self:GetInk() - p.TakeAmmo))
		self:SetCooldown(math.max(self:GetCooldown(),
		CurTime() + math.min(p.Delay, p.CrouchDelay) / timescale))
		self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
		self.ReloadSchedule:SetLastCalled(CurTime() + reloadtime)
		
		local pos, dir = self:GetFirePosition()
		local right = self.Owner:GetRight()
		local ang = dir:Angle()
		local angle_initvelocity = Angle(ang)
		local rx, ry = self:GetSpread()
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
		
		local prog, InitVelocity = self:GetFireAt()
		local sgnv = math.Round(util.SharedRandom(rand, 0, 1, CurTime() * 7)) * 2 - 1
		local SelectIntervalV = self:GetBiasVelocity() > util.SharedRandom(rand, 0, 1, CurTime() * 8)
		local fracv = util.SharedRandom(rand,
			SelectIntervalV and self:GetBias() or 0,
			SelectIntervalV and 1 or self:GetBiasVelocity(), CurTime() * 9)
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
	else
		local p = self.Primary
		if ply:KeyDown(IN_ATTACK) or self:GetCharge() == math.huge then return end
		if CurTime() - self:GetCharge() < p.MinChargeTime then return end
		local prog, Duration = self:GetChargeProgress()
		if prog < self.MediumCharge then
			Duration = self.Primary.FireDuration[1] * prog
		else
			Duration = Lerp((prog - self.MediumCharge) / (1 - self.MediumCharge), self.Primary.FireDuration[1], self.Primary.FireDuration[2])
		end
		
		self:SetFireAt(prog)
		self:ResetCharge()
		self:SetFireInk(math.floor(Duration / self.Primary.Delay) + 1)
	end
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
