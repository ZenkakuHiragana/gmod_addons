
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.HeroColor = {ss.GetColor(8), ss.GetColor(11), ss.GetColor(2), ss.GetColor(5)}

local FirePosition = 10
local rand = "SplatoonSWEPs: Spread"
local randsplash = "SplatoonSWEPs: SplashNum"
function SWEP:GetRange() return self.Primary.Range end
function SWEP:GetInitVelocity() return self.Primary.InitVelocity end
function SWEP:GetFirePosition(aim, ang, shootpos)
	if not IsValid(self.Owner) then return self:GetPos(), self:GetForward(), 0 end
	if not aim then
		local aimvector = self:GetAimVector()
		if CLIENT and self:IsMine() then
			aimvector = self.Owner:GetAimVector()
		end

		aim = self:GetRange() * aimvector
	end

	ang = ang or aim:Angle()
	shootpos = shootpos or ss.ProtectedCall(self.Owner.GetShootPos, self.Owner) or self.Owner:WorldSpaceCenter()

	local col = ss.vector_one * self.Primary.ColRadius
	local dy = FirePosition * (self:GetNWBool "lefthand" and -1 or 1)
	local dp = -Vector(0, dy, FirePosition) dp:Rotate(ang)
	local t = ss.SquidTrace
	t.start, t.endpos = shootpos, shootpos + aim
	t.mins, t.maxs = -col, col
	t.filter = {self, self.Owner}
	for _, e in pairs(ents.FindAlongRay(t.start, t.endpos, t.mins * 5, t.maxs * 5)) do
		local w = ss.IsValidInkling(e)
		if not w or ss.IsAlly(w, self) then continue end
		table.insert(t.filter, e)
		table.insert(t.filter, w)
	end

	local tr = util.TraceLine(t)
	local trhull = util.TraceHull(t)
	local pos = shootpos + dp
	local min = {dir = 1, dist = math.huge, pos = pos}

	t.start, t.endpos = pos, tr.HitPos
	local trtest = util.TraceHull(t)
	if self:GetNWBool "avoidwalls" and tr.HitPos:DistToSqr(shootpos) > trtest.HitPos:DistToSqr(pos) * 9 then
		for dir, negate in ipairs {false, "y", "z", "yz", 0} do --right, left, up
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

			if trtest.StartSolid then continue end
			local dist = math.floor(trtest.HitPos:DistToSqr(tr.HitPos))
			if dist < min.dist then min.dir, min.dist, min.pos = dir, dist, pos end
		end
	end

	return min.pos, (tr.HitPos - min.pos):GetNormalized(), min.dir
end

function SWEP:GetSpreadJumpFraction()
	local frac = CurTime() - self:GetJump()
	if CLIENT then frac = frac + self:Ping() end
	return math.Clamp(frac / self.Primary.SpreadJumpDelay, 0, 1)
end

function SWEP:GetSpreadAmount()
	return Lerp(self:GetSpreadJumpFraction(),
	self.Primary.SpreadJump, self.Primary.Spread),
	ss.mDegRandomY
end

function SWEP:GenerateSplashInitTable()
	local n, t = self.Primary.SplashPatterns, self.SplashInitTable
	for i = 0, n - 1 do t[i + 1] = (i * (self.Primary.TripleShotDelay and 3 or 1)) % n end
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
end

function SWEP:SharedDeploy()
	self:SetSplashInitMul(1)
	self:GenerateSplashInitTable()
	if not self.Primary.TripleShotDelay then return end
	self.TripleSchedule:SetDone(0)
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
	local p = self.Primary
	local pos, dir = self:GetFirePosition()
	local right = self.Owner:GetRight()
	local ang = dir:Angle()
	local rx, ry = self:GetSpread()
	local AlreadyAiming = CurTime() < self:GetAimTimer()
	if CurTime() - self:GetJump() < p.SpreadJumpDelay then
		self:SetBias(p.SpreadBiasJump)
	else
		if not AlreadyAiming then self:SetBias(0) end
		self:SetBias(math.min(self:GetBias() + p.SpreadBiasStep, p.SpreadBias))
	end

	ang:RotateAroundAxis(right:Cross(dir), rx)
	ang:RotateAroundAxis(right, ry)
	self.InitVelocity = ang:Forward() * self:GetInitVelocity()
	self.InitAngle = ang.yaw
	self.SplashInit = self.SplashInitTable[self:GetSplashInitMul()]
	self.SplashNum = math.floor(p.SplashNum) + (util.SharedRandom(randsplash, 0, 1) < p.SplashNum % 1 and 1 or 0)
	self:SetSplashInitMul(self:GetSplashInitMul() + 1)
	self:ResetSequence "fire"
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:EmitSound(self.ShootSound)
	if self:GetSplashInitMul() > p.SplashPatterns then
		self:SetSplashInitMul(1)
		self:GenerateSplashInitTable()
	end

	if self:IsFirstTimePredicted() then
		local rnda = p.Recoil * -1
		local rndb = p.Recoil * math.Rand(-1, 1)
		self.ViewPunch = Angle(rnda, rndb, rnda)

		if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents(self.Owner) end
		local e = EffectData()
		e:SetAttachment(self.SplashInit)
		e:SetAngles(ang)
		e:SetColor(self:GetNWInt "inkcolor")
		e:SetEntity(self)
		e:SetFlags((CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0) + (self.IsBlaster and 2 or 0))
		e:SetMagnitude(self.EffectRadius or ss.mColRadius)
		e:SetOrigin(pos)
		e:SetScale(self.SplashNum)
		e:SetStart(self.InitVelocity)
		util.Effect("SplatoonSWEPsShooterInk", e, true,
		not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
		if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents() end
		ss.AddInk(self.Owner, pos, util.SharedRandom("SplatoonSWEPs: Shooter ink type", 4, 9))
	end
end

function SWEP:PlayEmptySound()
	local p = self.Primary
	local timescale = ss.GetTimeScale(self.Owner)
	if p.TripleShotDelay then self:SetCooldown(CurTime()) end
	if self:GetPreviousHasInk() then
		if CLIENT and IsFirstTimePredicted() or ss.sp then
			self.Owner:EmitSound(ss.TankEmpty)
		end

		self:SetNextPlayEmpty(CurTime() + p.Delay * 2 / timescale)
		self:SetPreviousHasInk(false)
		self.PreviousHasInk = false
	elseif CurTime() > self:GetNextPlayEmpty() then
		self:EmitSound "SplatoonSWEPs.EmptyShot"
		self:SetNextPlayEmpty(CurTime() + p.Delay * 2 / timescale)
	end
end

function SWEP:SharedPrimaryAttack(able, auto)
	if not IsValid(self.Owner) then return end
	local p = self.Primary
	local timescale = ss.GetTimeScale(self.Owner)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay / timescale)
	self:SetInk(math.max(0, self:GetInk() - self:GetTakeAmmo()))
	self:SetCooldown(math.max(self:GetCooldown(),
	CurTime() + math.min(p.Delay, p.CrouchDelay) / timescale))

	if not able then
		self:SetAimTimer(CurTime() + p.AimDuration)
		self:PlayEmptySound()
		return
	end

	self:CreateInk()
	self:SetPreviousHasInk(true)
	self:SetAimTimer(CurTime() + p.AimDuration)
	if self:IsFirstTimePredicted() then self.ModifyWeaponSize = SysTime() end
	if not p.TripleShotDelay then return end
	local d = self.TripleSchedule:GetDone()
	if d == 1 or d == 2 then return end
	self:SetCooldown(CurTime() + (p.Delay * 2 + p.TripleShotDelay) / timescale)
	self:SetAimTimer(self:GetCooldown())
	self.TripleSchedule:SetDone(1)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Bool", "PreviousHasInk")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Bias")
	self:AddNetworkVar("Float", "Jump")
	self:AddNetworkVar("Float", "NextPlayEmpty")
	self:AddNetworkVar("Int", "SplashInitMul")

	if not self.Primary.TripleShotDelay then return end
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
	return CurTime() < self:GetAimTimer() and self.Primary.MoveSpeed or nil
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
	if CurTime() - self:GetJump() < self.Primary.SpreadJumpDelay then
		self:SetJump(self:GetJump() - FrameTime() / 2)
	end
end

function SWEP:KeyPress(ply, key)
	if key == IN_JUMP then self:SetJump(CurTime()) end
end

function SWEP:GetAnimWeight()
	return (self.Primary.Delay + .5) / 1.5
end

function SWEP:UpdateAnimation(ply, vel, max)
	ply:AnimSetGestureWeight(GESTURE_SLOT_ATTACK_AND_RELOAD, self:GetAnimWeight())
end
