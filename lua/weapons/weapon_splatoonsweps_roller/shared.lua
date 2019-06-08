
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.MODE = {READY = 0, ATTACK = 1, PAINT = 2}
SWEP.CollapseRollTime = 10 * ss.FrameToSec
SWEP.PreSwingTime = 10 * ss.FrameToSec
SWEP.SwingAnimTime = 10 * ss.FrameToSec
SWEP.SwingBackWait = 20 * ss.FrameToSec

function SWEP:AddPlaylist(p)
	p[#p + 1] = self.EmptyRollSound
	p[#p + 1] = self.RollingSound
end

local rand = "SplatoonSWEPs: Spread"
local randvel = "SplatoonSWEPs: Spread velocity"
local randink = "SplatoonSWEPs: Shooter ink type"
function SWEP:GetSpread(seed)
	local seed = seed or CurTime()
	local DegRandX, DegRandY = self.Primary.Spread, ss.mDegRandomY
	local sgnx = math.Round(util.SharedRandom(rand, 0, 1, seed)) * 2 - 1
	local sgny = math.Round(util.SharedRandom(rand, 0, 1, seed * 2)) * 2 - 1
	local fracx = util.SharedRandom(rand, 0, 1, seed * 3)
	local fracy = util.SharedRandom(rand, 0, 1, seed * 4)
	local rx = sgnx * fracx * DegRandX
	local ry = sgny * fracy * DegRandY
	return rx, ry
end

function SWEP:GetInitVelocity(seed)
	local seed = seed or CurTime()
	local p = self.Primary
	local s = p.SpreadVelocity
	local forward = p.InitVelocity + util.SharedRandom(randvel, -s.z, s.z, seed)
	local right = util.SharedRandom(randvel, -s.x, s.x, seed * 2)
	local up = forward * util.SharedRandom(randvel, -s.y, s.y, seed * 3)
	return forward, right, up
end

function SWEP:SetReloadDelay(delay)
	local reloadtime = delay / ss.GetTimeScale(ply)
	self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
	self.ReloadSchedule:SetLastCalled(CurTime() + reloadtime)
	self:SetCooldown(CurTime() + FrameTime())
end

function SWEP:CreateInk()
	local p = self.Primary
	local dir = self:GetAimVector()
	local pos = self:GetShootPos()
	local right = self.Owner:GetRight()
	for i = 1, p.SplashNum do
		local ang = dir:Angle()
		local rx, ry = self:GetSpread(i)
		local vf, vr, vu = self:GetInitVelocity(i)
		local dp = p.SplashPosWidth
		ang:RotateAroundAxis(right:Cross(dir), rx)
		ang:RotateAroundAxis(right, ry)
		dp = right * util.SharedRandom("Splatoon SWEPs: Roller width", -dp, dp, i)
		self.InitVelocity = ang:Forward() * vf + ang:Right() * vr + ang:Up() * vu
		self.InitAngle = ang.yaw

		if self:IsFirstTimePredicted() then
			if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents(self.Owner) end
			local e = EffectData()
			e:SetAttachment(0)
			e:SetAngles(ang)
			e:SetColor(self:GetNWInt "inkcolor")
			e:SetEntity(self)
			e:SetFlags(CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0)
			e:SetMagnitude(self.EffectRadius or ss.mColRadius)
			e:SetOrigin(pos + dp)
			e:SetScale(0)
			e:SetStart(self.InitVelocity)
			util.Effect("SplatoonSWEPsShooterInk", e, true,
			not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
			if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents() end
			ss.AddInk(self.Owner, pos + dp, util.SharedRandom(randink, 4, 9))
		end
	end

	if not self:IsFirstTimePredicted() then return end
	local rnda = p.Recoil * -1
	local rndb = p.Recoil * math.Rand(-1, 1)
	self.ViewPunch = Angle(rnda, rndb, rnda)
end

function SWEP:SharedInit()
	self.EmptyRollSound = CreateSound(self, ss.EmptyRoll)
	self.RollingSound = CreateSound(self, self.RollSound)
	self:SetStartTime(CurTime())
	self:SetEndTime(CurTime())
	self:SetMode(self.MODE.READY)
end

function SWEP:SharedPrimaryAttack(able, auto)
	if not IsValid(self.Owner) then return end
	if self:GetMode() > self.MODE.READY then return end
	local p = self.Primary
	local timescale = ss.GetTimeScale(self.Owner)
	self:SetMode(self.MODE.ATTACK)
	self:SetStartTime(CurTime())
	self:SetEndTime(CurTime() + p.SwingWaitTime)
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	if not self:IsFirstTimePredicted() then return end
	self:EmitSound(self.PreSwingSound)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "StartTime")
	self:AddNetworkVar("Float", "EndTime")
	self:AddNetworkVar("Float", "PaintGroundTime")
	self:AddNetworkVar("Int", "Mode")
end

function SWEP:CustomActivity() return "melee2" end
function SWEP:Move(ply, mv)
	local p = self.Primary
	local mode = self:GetMode()
	local enoughink = self:GetInk() > self:GetTakeAmmo()
	local keyrelease = not (ply:IsPlayer() and self:GetKey() == IN_ATTACK)
	if mode == self.MODE.PAINT then
		if keyrelease and CurTime() > self:GetEndTime() + self.SwingBackWait then
			self.NotEnoughInk = false
			self:SetMode(self.MODE.READY)
			self:SetWeaponAnim(ACT_VM_IDLE)
			self:SetStartTime(CurTime())
			self:SetNextPrimaryFire(CurTime() + p.Delay)
			if self:IsFirstTimePredicted() then
				self:EmitSound "SplatoonSWEPs.RollerHolster"
			end
		end

		local s = self:GetInk() > 0 and self.RollingSound or self.EmptyRollSound
		local s2 = self:GetInk() > 0 and self.EmptyRollSound or self.RollingSound
		local v = ply:OnGround() and 1 or 0
		if ply:IsPlayer() then
			v = v * math.abs(mv:GetForwardSpeed()) / ply:GetMaxSpeed()
		elseif ply:IsNPC() and isfunction(ply.IsMoving) then
			v = v * (ply:IsMoving() and 1 or 0)
		end

		s:ChangeVolume(v)
		s2:ChangeVolume(0)
		if v > 0 then
			self:SetReloadDelay(p.ReloadDelayGround)
			if self:GetInk() > 0 then
				local pos = self:GetShootPos()
				local dir = self:GetForward()
				local width = Lerp(v, p.MinWidth, p.MaxWidth)
				local inktype = util.SharedRandom(rand, 10, 12)
				local t = util.TraceLine {
					start = pos + dir * 45,
					endpos = pos + dir * 45 - vector_up * 80,
					filter = {self, self.Owner},
					mask = ss.SquidSolidMask,
				}
				self:SetInk(math.max(self:GetInk() - p.TakeAmmoGround, 0))
				ss.Paint(t.HitPos, t.HitNormal, width * .67, self:GetNWInt "inkcolor", self:GetAimVector():Angle().yaw + 90, inktype, .25, self.Owner, self.ClassName)
			end
		end
	else
		self.RollingSound:ChangeVolume(0)
		self.EmptyRollSound:ChangeVolume(0)
	end

	if mode ~= self.MODE.ATTACK then return end
	self:SetReloadDelay(p.ReloadDelay)
	if CurTime() < self:GetEndTime() then return end
	self:SetInk(math.max(self:GetInk() - self:GetTakeAmmo(), 0))
	self:SetMode(self.MODE.PAINT)
	self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)

	if not self:IsFirstTimePredicted() then return end
	if enoughink then
		self:EmitSound(self.SwingSound)
		self:EmitSound(self.SplashSound)
		self:CreateInk()
	end

	if (ss.sp or CLIENT) and not (self.NotEnoughInk or enoughink) then
		self.NotEnoughInk = true
		ss.EmitSound(ply, ss.TankEmpty)
	end
end

function SWEP:UpdateAnimation(ply, velocity, maxseqspeed)
	local mode = self:GetMode()
	local ct = CurTime() + (self:IsMine() and self:Ping() or 0)
	local start, duration, c1, c2
	if mode == self.MODE.READY then
		return
	elseif mode == self.MODE.ATTACK then
		start = self:GetStartTime()
		duration = self.PreSwingTime
		c1, c2 = 0, .3
	else
		start = self:GetEndTime()
		duration = self.SwingAnimTime
		c1, c2 = .3, .6125
	end

	local f = math.TimeFraction(start, start + duration, ct)
	local cycle = Lerp(math.EaseInOut(math.Clamp(f, 0, 1), 0, 1), c1, c2)
	ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, ply:SelectWeightedSequence(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2), cycle, true)
end

function SWEP:CustomMoveSpeed()
	if self:GetMode() == self.MODE.PAINT and self.Owner:OnGround() then
		return self.Primary.MoveSpeed
	end
end
