
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.IsRoller = true
SWEP.MODE = {READY = 0, ATTACK = 1, PAINT = 2}
SWEP.CollapseRollTime = 10 * ss.FrameToSec
SWEP.PreSwingTime = 10 * ss.FrameToSec
SWEP.SwingAnimTime = 10 * ss.FrameToSec
SWEP.SwingBackWait = 24 * ss.FrameToSec

function SWEP:AddPlaylist(p)
	p[#p + 1] = self.EmptyRollSound
	p[#p + 1] = self.RollingSound
end

local rand = "SplatoonSWEPs: Spread"
local randink = "SplatoonSWEPs: Shooter ink type"
local randsplash = "Splatoon SWEPs: SplashNum"
local randvel = "SplatoonSWEPs: Spread velocity"
function SWEP:GetInitVelocity(i, splashnum)
	local p = self.Parameters
	local degmax = p.mSplashDeg
	local frac = splashnum == 1 and 1 or (i - 1) / (splashnum - 1)
	local deg = (frac * 2 - 1) * degmax
	local sb = p.mSplashInitSpeedBase
	local sz = p.mSplashInitSpeedRandomZ
	local sx = p.mSplashInitSpeedRandomX
	local sy = p.mSplashInitVecYRate
	local forward = sb + util.SharedRandom(randvel, -sz, sz, i)
	local right = util.SharedRandom(randvel, -sx, sx, i * 2)
	local up = sb * sy
	return forward, right + deg, up
end

function SWEP:CreateInk(skipnum)
	local p = self.Parameters
	local dir = self:GetAimVector()
	local pos = self:GetShootPos()
	local right = self.Owner:GetRight()
	local splashnum = p.mSplashNum
	local width = p.mSplashPositionWidth
	local insiderate = p.mSplashInsideDamageRate
	local insidenum = math.floor(splashnum * insiderate)
	local IsLP = self:IsMine()
	if splashnum % 1 ~= insidenum % 1 then
		insidenum = insidenum - 1
	end

	local t, skiptable = {}, {}
	for i = 1, splashnum do
		table.insert(t, i)
	end

	for i = 1, skipnum do
		local k = math.floor(util.SharedRandom(randsplash, i, splashnum))
		t[i], t[k] = t[k], t[i]
	end

	for i = 1, skipnum do
		skiptable[t[i]] = true
	end

	table.Merge(self.Projectile, {
		Color = self:GetNWInt "inkcolor",
		ColRadiusEntity = p.mSplashCollisionRadiusForPlayer,
		ColRadiusWorld = p.mSplashCollisionRadiusForField,
		ID = CurTime() + self:EntIndex(),
		PaintFarDistance = p.mSplashPaintFarD,
		PaintFarRadius = p.mSplashPaintFarR,
		PaintNearDistance = p.mSplashPaintNearD,
		PaintNearRadius = p.mSplashPaintNearR,
		StraightFrame = p.mSplashStraightFrame,
	})
	
	local insidestart = (splashnum - insidenum) / 2
	local nextskip = 1
	for i = 1, splashnum do
		if nextskip < skipnum and skiptable[i] then
			nextskip = nextskip + 1
		else
			local ang = dir:Angle()
			local isoutside = i < insidestart or splashnum - i < insidestart
			local frac = splashnum == 1 and 1 or (i - 1) / (splashnum - 1)
			local dp = right * (frac * 2 - 1) * width
			local vf, vr, vu = self:GetInitVelocity(i, splashnum)
			table.Merge(self.Projectile, {
				DamageMax = isoutside and p.mSplashOutsideDamageMaxValue or p.mSplashDamageMaxValue,
				DamageMaxDistance = isoutside and p.mSplashOutsideDamageMaxDist or p.mSplashDamageMaxDist,
				DamageMin = isoutside and p.mSplashOutsideDamageMinValue or p.mSplashDamageMinValue,
				DamageMinDistance = isoutside and p.mSplashOutsideDamageMinDist or p.mSplashDamageMinDist,
				InitPos = pos + dp,
				InitVel = dir * vf + ang:Right() * vr + ang:Up() * vu,
				Type = util.SharedRandom(randink, 4, 9, CurTime() * i),
				Yaw = ang.yaw,
			})

			if self:IsFirstTimePredicted() then
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents(self.Owner) end
				local e = EffectData()
				e:SetAttachment(self.Projectile.SplashInit)
				e:SetColor(self.Projectile.Color)
				e:SetEntity(self)
				e:SetFlags(IsLP and 128 or 0)
				e:SetMagnitude(self.Projectile.ColRadiusWorld)
				e:SetOrigin(self.Projectile.InitPos)
				e:SetScale(self.Projectile.SplashNum)
				e:SetStart(self.Projectile.InitVel)
				util.Effect("SplatoonSWEPsShooterInk", e, true, self.IgnorePrediction)
				if ss.mp and SERVER and self.Owner:IsPlayer() then SuppressHostEvents() end
				ss.AddInk(p, self.Projectile)
			end
		end
	end
end

function SWEP:SharedInit()
	self.Bodygroup = table.Copy(self.Bodygroup or {})
	self.EmptyRollSound = CreateSound(self, ss.EmptyRoll)
	self.Projectile.IsRoller = true
	self.RollingSound = CreateSound(self, self.RollSound)
	self.RunoverExceptions = {}
	self:SetStartTime(CurTime())
	self:SetEndTime(CurTime())
	self:SetMode(self.MODE.READY)
	self:AddSchedule(0, function(self, schedule)
		self.Bodygroup[1] = self:GetInk() > 0 and 0 or 1
		if not self.IsHeroWeapon then return end
		self.Skin = self:GetNWInt "level"
	end)
end

function SWEP:SharedHolster()
	self:SetMode(self.MODE.READY)
end

function SWEP:SharedPrimaryAttack(able, auto)
	if not IsValid(self.Owner) then return end
	if self:GetMode() > self.MODE.READY then return end
	local p = self.Parameters
	self:SetMode(self.MODE.ATTACK)
	self:SetStartTime(CurTime())
	self:SetEndTime(CurTime() + p.mSwingLiftFrame)
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	if not self:IsFirstTimePredicted() then return end
	self:EmitSound(self.PreSwingSound)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "StartTime")
	self:AddNetworkVar("Float", "EndTime")
	self:AddNetworkVar("Float", "RunoverDelay")
	self:AddNetworkVar("Int", "Mode")
end

function SWEP:CustomActivity() return "melee2" end
function SWEP:Move(ply, mv)
	local p = self.Parameters
	local mode = self:GetMode()
	local keyrelease = not (ply:IsPlayer() and self:GetKey() == IN_ATTACK)
	if self.Owner:IsPlayer() and CurTime() < self:GetRunoverDelay() then
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
	end

	if mode == self.MODE.PAINT then
		if keyrelease and CurTime() > self:GetEndTime() + self.SwingBackWait then
			self.NotEnoughInk = false
			self:SetMode(self.MODE.READY)
			self:SetWeaponAnim(ACT_VM_IDLE)
			self:SetStartTime(CurTime())
			if self:IsFirstTimePredicted() then
				self:EmitSound "SplatoonSWEPs.RollerHolster"
			end
		end

		local s = self:GetInk() > 0 and self.RollingSound or self.EmptyRollSound
		local s2 = self:GetInk() > 0 and self.EmptyRollSound or self.RollingSound
		local v = ply:OnGround() and 1 or 0
		if ply:IsPlayer() then
			v = v * math.abs(ply:GetVelocity():Dot(ply:GetForward())) / ply:GetMaxSpeed()
		elseif ply:IsNPC() and isfunction(ply.IsMoving) then
			v = v * (ply:IsMoving() and 1 or 0)
		end
		
		s:ChangeVolume(v)
		s2:ChangeVolume(0)
		if v > 0 then
			self:SetReloadDelay(p.mInkRecoverCoreStop)
			self:SetCooldown(CurTime() + FrameTime())
			if self:GetInk() > 0 then
				local color = self:GetNWInt "inkcolor"
				local forward = self:GetForward()
				local inktype = util.SharedRandom(rand, 10, 12)
				local pos = self:GetShootPos()
				local width = Lerp(v, p.mCorePaintSlowMoveWidthHalf, p.mCorePaintWidthHalf) * .67
				local yaw = self:GetAimVector():Angle().yaw + 90
				local t = util.TraceLine {
					start = pos + forward * 45,
					endpos = pos + forward * 45 - vector_up * 80,
					filter = {self, self.Owner},
					mask = ss.SquidSolidMask,
				}
				self:SetInk(math.max(self:GetInk() - p.mInkConsumeCore, 0))
				ss.Paint(t.HitPos, t.HitNormal, width, color, yaw, inktype, .25, self.Owner, self.ClassName)

				local dir = self:GetRight()
				local radius = p.mCoreColRadius / 2
				local width = p.mCoreColWidthHalf
				local bounds = ss.vector_one * radius
				local center = t.HitPos + vector_up * radius
				local left = center - dir * width
				local right = center + dir * width
				local victims = ents.FindAlongRay(left, right, -bounds, bounds)
				local knockback = false
				local keys = {}
				for i, v in ipairs(victims) do
					if v ~= self.Owner then
						keys[v] = true
						local health = v:Health()
						if not self.RunoverExceptions[v] and health > 0 then
							local d = DamageInfo()
							local effectpos = center + dir * dir:Dot(v:GetPos() - center)
							if self:IsMine() then
								ss.CreateHitEffect(color, 0, effectpos, -forward)
							end
						
							print(v)
							if SERVER then
								d:SetDamage(p.mCoreDamage)
								d:SetDamageForce(forward)
								d:SetDamagePosition(effectpos)
								d:SetDamageType(DMG_GENERIC)
								d:SetMaxDamage(p.mCoreDamage)
								d:SetReportedPosition(effectpos)
								d:SetAttacker(self.Owner)
								d:SetInflictor(self)
								d:ScaleDamage(ss.ToHammerHealth)
								ss.ProtectedCall(v.TakeDamageInfo, v, d)
								knockback = knockback or v:Health() > 0
							else
								knockback = knockback or health > p.mCoreDamage * ss.ToHammerHealth
							end
						end
					end
				end

				self.RunoverExceptions = keys
				self.NotEnoughInkRoll = false
				if self.Owner:IsPlayer() and knockback then
					mv:SetVelocity(mv:GetVelocity() - forward * ss.InklingBaseSpeed * 10)
					self:SetRunoverDelay(CurTime() + ss.RollerRunoverStopFrame)
				end
			elseif (ss.sp or CLIENT) and not self.NotEnoughInkRoll then
				self.NotEnoughInkRoll = true
				ss.EmitSound(ply, ss.TankEmpty)
			end
		end
	else
		self.RollingSound:ChangeVolume(0)
		self.EmptyRollSound:ChangeVolume(0)
	end

	if mode ~= self.MODE.ATTACK then return end
	self:SetReloadDelay(p.mInkRecoverSplashStop)
	self:SetCooldown(CurTime() + FrameTime())

	if CurTime() < self:GetEndTime() then return end
	local frac = math.min(self:GetInk() / p.mInkConsumeSplash, 1)
	local splashnum = math.floor(frac * p.mSplashNum)
	local enoughink = self:GetInk() > p.mInkConsumeSplash
	self:SetInk(math.max(self:GetInk() - p.mInkConsumeSplash, 0))
	self:SetMode(self.MODE.PAINT)
	self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)

	if not self:IsFirstTimePredicted() then return end
	if enoughink or splashnum > 0 then
		self:EmitSound(self.SwingSound)
		self:EmitSound(self.SplashSound)
		self:CreateInk(p.mSplashNum - splashnum)
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
		return self.Parameters.mMoveSpeed
	end
end
