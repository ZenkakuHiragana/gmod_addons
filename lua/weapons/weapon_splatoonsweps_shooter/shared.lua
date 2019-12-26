
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.IsShooter = true
SWEP.HeroColor = {ss.GetColor(8), ss.GetColor(11), ss.GetColor(2), ss.GetColor(5)}

local FirePosition = 10
local rand = "SplatoonSWEPs: Spread"
local randsplash = "SplatoonSWEPs: SplashNum"
local randinktype = "SplatoonSWEPs: Shooter ink type"
function SWEP:GetRange() return self.Range end
function SWEP:GetInitVelocity() return self.Parameters.mInitVel end
function SWEP:GetFirePosition(ping)
	if not IsValid(self.Owner) then return self:GetPos(), self:GetForward(), 0 end
	local aim = self:GetAimVector() * self:GetRange(ping)
	local ang = aim:Angle()
	local shootpos = self:GetShootPos()
	local col = ss.vector_one * self.Parameters.mColRadius
	local dy = FirePosition * (self:GetNWBool "lefthand" and -1 or 1)
	local dp = -Vector(0, dy, FirePosition) dp:Rotate(ang)
	local t = ss.SquidTrace
	t.start, t.endpos = shootpos, shootpos + aim
	t.mins, t.maxs = -col, col
	t.filter = {self, self.Owner}
	for _, e in pairs(ents.FindAlongRay(t.start, t.endpos, t.mins * 5, t.maxs * 5)) do
		local w = ss.IsValidInkling(e)
		if w and ss.IsAlly(w, self) then
			t.filter = {self, self.Owner, e, w}
		end
	end

	local tr = util.TraceLine(t)
	local trhull = util.TraceHull(t)
	local pos = shootpos + dp
	local min = {dir = 1, dist = math.huge, pos = pos}

	t.start, t.endpos = pos, tr.HitPos
	local trtest = util.TraceHull(t)
	if self:GetNWBool "avoidwalls" and tr.HitPos:DistToSqr(shootpos) > trtest.HitPos:DistToSqr(pos) * 9 then
		for dir, negate in ipairs {false, "y", "z", "yz", 0} do -- right, left, up
			if negate then
				if negate == 0 then
					dp = vector_up * -FirePosition
					pos = shootpos
				else
					dp = -Vector(0, dy, FirePosition)
					for i = 1, negate:len() do
						local s = negate:sub(i, i)
						dp[s] = -dp[s]
					end
					dp:Rotate(ang)
					pos = shootpos + dp
				end

				t.start = pos
				trtest = util.TraceHull(t)
			end
			
			if not trtest.StartSolid then
				local dist = math.floor(trtest.HitPos:DistToSqr(tr.HitPos))
				if dist < min.dist then
					min.dir, min.dist, min.pos = dir, dist, pos
				end
			end
		end
	end

	return min.pos, (tr.HitPos - min.pos):GetNormalized(), min.dir
end

function SWEP:GetSpreadJumpFraction()
	local frac = CurTime() - self:GetJump()
	if CLIENT then frac = frac + self:Ping() end
	return math.Clamp(frac / self.Parameters.mDegJumpBiasFrame, 0, 1)
end

function SWEP:GetSpreadAmount()
	return Lerp(self:GetSpreadJumpFraction(),
	self.Parameters.mDegJumpRandom, self.Parameters.mDegRandom), ss.mDegRandomY
end

function SWEP:GenerateSplashInitTable()
	local n, t = self.Parameters.mSplashSplitNum, self.SplashInitTable
	local step = self.Parameters.mTripleShotSpan and 3 or 1
	for i = 0, n - 1 do t[i + 1] = i * step % n end
	for i = 1, n do
		local k = math.floor(util.SharedRandom(randsplash, i, n))
		t[i], t[k] = t[k], t[i]
	end
end

function SWEP:SharedInit()
	self.SplashInitTable = {} -- A random permutation table for splash init
	self:SetAimTimer(CurTime())
	self:SetNextPlayEmpty(CurTime())
	self:SetSplashInitMul(1)

	local p = self.Parameters
	table.Merge(self.Projectile, {
		AirResist = 0.75,
		ColRadiusEntity = p.mColRadius,
		ColRadiusWorld = p.mColRadius,
		DamageMax = p.mDamageMax,
		DamageMaxDistance = p.mGuideCheckCollisionFrame,
		DamageMin = p.mDamageMin,
		DamageMinDistance = p.mDamageMinFrame,
		Gravity = 1 * ss.ToHammerUnitsPerSec2,
		PaintFarDistance = p.mPaintFarDistance,
		PaintFarRadius = p.mPaintFarRadius,
		PaintNearDistance = p.mPaintNearDistance,
		PaintNearRadius = p.mPaintNearRadius,
		SplashColRadius = p.mSplashColRadius,
		SplashLength = p.mCreateSplashLength,
		SplashPaintRadius = p.mSplashPaintRadius,
		StraightFrame = p.mStraightFrame,
	})
end

function SWEP:SharedDeploy()
	self:SetSplashInitMul(1)
	self:GenerateSplashInitTable()
	if self.Parameters.mTripleShotSpan > 0 then
		self.TripleSchedule:SetDone(0)
	end
end

function SWEP:GetSpread()
	local DegRandX, DegRandY = self:GetSpreadAmount()
	local sgnx = math.Round(util.SharedRandom(rand, 0, 1, CurTime())) * 2 - 1
	local sgny = math.Round(util.SharedRandom(rand, 0, 1, CurTime() * 2)) * 2 - 1
	local SelectIntervalX = self:GetBias() > util.SharedRandom(rand, 0, 1, CurTime() * 3)
	local SelectIntervalY = self:GetBias() > util.SharedRandom(rand, 0, 1, CurTime() * 4)
	local fracx = util.SharedRandom(rand,
		SelectIntervalX and self:GetBias() or 0,
		SelectIntervalX and 1 or self:GetBias(), CurTime() * 5)
	local fracy = util.SharedRandom(rand,
		SelectIntervalY and self:GetBias() or 0,
		SelectIntervalY and 1 or self:GetBias(), CurTime() * 6)
	local rx = sgnx * fracx * DegRandX
	local ry = sgny * fracy * DegRandY

	return rx, ry
end

function SWEP:CreateInk()
	local p = self.Parameters
	local pos, dir = self:GetFirePosition()
	local right = self.Owner:GetRight()
	local ang = dir:Angle()
	local rx, ry = self:GetSpread()
	local splashnum = math.floor(p.mCreateSplashNum)
	local AlreadyAiming = CurTime() < self:GetAimTimer()
	if CurTime() - self:GetJump() < p.mDegJumpBiasFrame then
		self:SetBias(p.mDegJumpBias)
	else
		if not AlreadyAiming then self:SetBias(0) end
		self:SetBias(math.min(self:GetBias() + p.mDegBiasKf, p.mDegBias))
	end

	if util.SharedRandom(randsplash, 0, 1) < p.mCreateSplashNum % 1 then
		splashnum = splashnum + 1
	end

	ang:RotateAroundAxis(right:Cross(dir), rx)
	ang:RotateAroundAxis(right, ry)
	table.Merge(self.Projectile, {
		Color = self:GetNWInt "inkcolor",
		ID = CurTime() + self:EntIndex(),
		InitPos = pos,
		InitVel = ang:Forward() * self:GetInitVelocity(),
		SplashInitRate = self.SplashInitTable[self:GetSplashInitMul()] / p.mSplashSplitNum,
		SplashNum = splashnum,
		Type = util.SharedRandom(randinktype, 4, 9),
		Yaw = ang.yaw,
	})

	self:SetSplashInitMul(self:GetSplashInitMul() + 1)
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	ss.EmitSoundPredicted(self.Owner, self, self.ShootSound)
	ss.SuppressHostEventsMP(self.Owner)
	self:ResetSequence "fire" -- This is needed in multiplayer to prevent delaying muzzle effects.
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	ss.EndSuppressHostEventsMP(self.Owner)

	if self:GetSplashInitMul() > p.mSplashSplitNum then
		self:SetSplashInitMul(1)
		self:GenerateSplashInitTable()
	end

	if self:IsFirstTimePredicted() then
		local Recoil = 0.2
		local rnda = Recoil * -1
		local rndb = Recoil * math.Rand(-1, 1)
		self.ViewPunch = Angle(rnda, rndb, rnda)
		
		local e = EffectData()
		ss.SetEffectColor(e, self.Projectile.Color)
		ss.SetEffectColRadius(e, self.Projectile.ColRadiusWorld)
		ss.SetEffectDrawRadius(e, self.IsBlaster and p.mSphereSplashDropDrawRadius or p.mDrawRadius)
		ss.SetEffectEntity(e, self)
		ss.SetEffectFlags(e, self)
		ss.SetEffectInitPos(e, self.Projectile.InitPos)
		ss.SetEffectInitVel(e, self.Projectile.InitVel)
		ss.SetEffectSplash(e, Angle(self.Projectile.SplashColRadius, p.mSplashDrawRadius, self.Projectile.SplashLength))
		ss.SetEffectSplashInitRate(e, Vector(self.Projectile.SplashInitRate))
		ss.SetEffectSplashNum(e, self.Projectile.SplashNum)
		ss.SetEffectStraightFrame(e, self.Projectile.StraightFrame)
		ss.UtilEffectPredicted(self.Owner, "SplatoonSWEPsShooterInk", e, true, self.IgnorePrediction)
		ss.AddInk(p, self.Projectile)
	end
end

function SWEP:PlayEmptySound()
	local nextempty = self.Parameters.mRepeatFrame * 2 / ss.GetTimeScale(self.Owner)
	if self:GetPreviousHasInk() then
		if ss.sp or CLIENT and IsFirstTimePredicted() then
			self.Owner:EmitSound(ss.TankEmpty)
		end

		self:SetNextPlayEmpty(CurTime() + nextempty)
		self:SetPreviousHasInk(false)
		self.PreviousHasInk = false
	elseif CurTime() > self:GetNextPlayEmpty() then
		self:EmitSound "SplatoonSWEPs.EmptyShot"
		self:SetNextPlayEmpty(CurTime() + nextempty)
	end
end

function SWEP:SharedPrimaryAttack(able, auto)
	if not IsValid(self.Owner) then return end
	local p = self.Parameters
	local ts = ss.GetTimeScale(self.Owner)
	self:SetNextPrimaryFire(CurTime() + p.mRepeatFrame / ts)
	self:SetInk(math.max(0, self:GetInk() - p.mInkConsume))
	self:SetReloadDelay(p.mInkRecoverStop)
	self:SetCooldown(math.max(self:GetCooldown(),
	CurTime() + math.min(p.mRepeatFrame, ss.CrouchDelay) / ts))

	if not able then
		if p.mTripleShotSpan > 0 then self:SetCooldown(CurTime()) end
		self:SetAimTimer(CurTime() + ss.AimDuration)
		self:PlayEmptySound()
		return
	end

	self:CreateInk()
	self:SetPreviousHasInk(true)
	self:SetAimTimer(CurTime() + ss.AimDuration)
	if self:IsFirstTimePredicted() then self.ModifyWeaponSize = SysTime() end
	if p.mTripleShotSpan > 0 then
		local d = self.TripleSchedule:GetDone()
		if d == 1 or d == 2 then return end
		self:SetCooldown(CurTime() + (p.mRepeatFrame * 2 + p.mTripleShotSpan) / ts)
		self:SetAimTimer(self:GetCooldown())
		self.TripleSchedule:SetDone(1)
	end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Bool", "PreviousHasInk")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Bias")
	self:AddNetworkVar("Float", "Jump")
	self:AddNetworkVar("Float", "NextPlayEmpty")
	self:AddNetworkVar("Int", "SplashInitMul")

	if self.Parameters.mTripleShotSpan > 0 then
		self.TripleSchedule = self:AddNetworkSchedule(0, function(self, schedule)
			if schedule:GetDone() == 1 or schedule:GetDone() == 2 then
				if self:GetNextPrimaryFire() > CurTime() then
					schedule:SetDone(schedule:GetDone() - 1)
				else
					self:PrimaryAttack(true)
				end

				return
			end

			schedule:SetDone(3)
		end)
		self.TripleSchedule:SetDone(3)
	end
end

function SWEP:CustomActivity()
	local at = self:GetAimTimer()
	if CLIENT and self:IsCarriedByLocalPlayer() then at = at - self:Ping() end
	if CurTime() > at then return end

	local aimpos = select(3, self:GetFirePosition())
	aimpos = (aimpos == 3 or aimpos == 4) and "rpg" or "crossbow"

	local m = self.Owner:GetModel()
	local aim = self:GetADS() and not (ss.DrLilRobotPlayermodels[m] or ss.TwilightPlayermodels[m])
	return aim and "ar2" or aimpos
end

function SWEP:CustomMoveSpeed()
	if CurTime() > self:GetAimTimer() then return end
	return self.Parameters.mMoveSpeed
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

	if not ply:OnGround() then return end
	if CurTime() - self:GetJump() < self.Parameters.mDegJumpBiasFrame then
		self:SetJump(self:GetJump() - FrameTime() / 2)
	end
end

function SWEP:KeyPress(ply, key)
	if key == IN_JUMP then self:SetJump(CurTime()) end
end

function SWEP:GetAnimWeight()
	return (self.Parameters.mRepeatFrame + .5) / 1.5
end

function SWEP:UpdateAnimation(ply, vel, max)
	ply:AnimSetGestureWeight(GESTURE_SLOT_ATTACK_AND_RELOAD, self:GetAnimWeight())
end
