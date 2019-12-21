
local ss = SplatoonSWEPs
if not ss then return end

local rand = "SplatoonSWEPs: Spread"
local randink = "SplatoonSWEPs: Shooter ink type"
local randsplash = "Splatoon SWEPs: SplashNum"
local randvel = "SplatoonSWEPs: Spread velocity"
local function EndSwing(self)
	self.NotEnoughInk = false
	self:SetIsSecondSwing(false)
	self:SetMode(self.MODE.READY)
	self:SetWeaponAnim(ACT_VM_IDLE)
	self:SetMousePressedTime(CurTime())
	self.RollSound:ChangeVolume(0)
	self.EmptyRollSound:ChangeVolume(0)
	if self.IsBrush then
		self:SetSwingCount(self.SwingCountInit)
		return
	end

	if not self:IsFirstTimePredicted() then return end
	ss.EmitSoundPredicted(self.Owner, self, "SplatoonSWEPs.RollerHolster")
end

local function PlaySwingSound(self, enoughink)
	if enoughink then
		ss.EmitSoundPredicted(self.Owner, self, self.SplashSound)
		if not self.SwingSound then return end
		ss.EmitSoundPredicted(self.Owner, self, self.SwingSound)
	else
		self:EmitSound "SplatoonSWEPs.EmptySwing"
		if self.NotEnoughInk then return end
		if ss.mp and SERVER then return end
		self.NotEnoughInk = true
		ss.EmitSound(self.Owner, ss.TankEmpty)
	end
end

local TraceLookStart = 20
local TraceLookAhead = 45
local TraceDown = 70
local TraceUp = 8
local function GetRollerTrace(self)
	local forward = self:GetForward()
	local pos = self:GetPos()
	return util.TraceLine {
		start = pos + forward * TraceLookStart + vector_up * TraceUp,
		endpos = pos + forward * TraceLookAhead - vector_up * TraceDown,
		filter = {self, self.Owner},
		mask = ss.SquidSolidMask,
	}
end

local function DoRollingEffect(self, velocity)
	if CurTime() < self:GetNextRollingEffectTime() then return end
	local delay = self.IsBrush and self.RunningEffectDelay or self.RollingEffectDelay
	self:SetNextRollingEffectTime(CurTime() + delay)
	if not self:IsFirstTimePredicted() then return end
	local e = EffectData()
	e:SetEntity(self)
	e:SetFlags(self.IsBrush and 1 or 0)
	e:SetRadius(velocity)
	ss.UtilEffectPredicted(self.Owner, "SplatoonSWEPsRollerRolling", e, true, self.IgnorePrediction)
end

local function DoRunover(self, t, mv)
	local p = self.Parameters
	local color = self:GetNWInt "inkcolor"
	local forward = self:GetForward()
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
	local function dealdamage(i, v)
		if v == self.Owner then return end
		keys[v] = true
		if self.RunoverExceptions[v] then return end
		if v:Health() == 0 then return end
		
		local effectpos = center + dir * dir:Dot(v:GetPos() - center)
		if self:IsMine() then
			ss.CreateHitEffect(color, 0, effectpos, -forward)
		end
	
		if SERVER then
			local d = DamageInfo()
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
			knockback = knockback or v:Health() > p.mCoreDamage * ss.ToHammerHealth
		end
	end

	for i, v in ipairs(victims) do dealdamage(i, v) end
	self.RunoverExceptions = keys
	if not self.Owner:IsPlayer() then return end
	if not knockback then return end
	mv:SetVelocity(mv:GetVelocity() - self:GetForward() * ss.InklingBaseSpeed * 10)
	self:SetRunoverDelay(CurTime() + ss.RollerRunoverStopFrame)
end

SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.IsRoller = true
SWEP.MODE = {READY = 0, ATTACK = 1, ATTACK2 = 2, PAINT = 4}
SWEP.CollapseRollTime = 10 * ss.FrameToSec
SWEP.PreSwingTime = 10 * ss.FrameToSec
SWEP.SwingAnimTime = 10 * ss.FrameToSec
SWEP.SwingBackWait = 24 * ss.FrameToSec
SWEP.RollingEffectDelay = 12 * ss.FrameToSec
SWEP.RunningEffectDelay = 6 * ss.FrameToSec

function SWEP:AddPlaylist(p)
	p[#p + 1] = self.EmptyRollSound
	p[#p + 1] = self.RollSound
end

function SWEP:GetVelocitySpread(issub)
	local p = self.Parameters
	if issub then
		return p.mSplashSubInitSpeedBase,
			   p.mSplashSubInitSpeedRandomZ,
			   p.mSplashSubInitSpeedRandomX,
			   p.mSplashSubInitVecYRate,
			   p.mSplashSubDeg
	else
		return p.mSplashInitSpeedBase,
			   p.mSplashInitSpeedRandomZ,
			   p.mSplashInitSpeedRandomX,
			   p.mSplashInitVecYRate,
			   p.mSplashDeg
	end
end

function SWEP:GetStraightFrame(issub)
	local p = self.Parameters
	if issub then
		return p.mSplashSubStraightFrame
	else
		return p.mSplashStraightFrame
	end
end

function SWEP:GetDrawRadius(issub)
	local p = self.Parameters
	if issub then
		return p.mSplashSubDrawRadius
	else
		return p.mSplashDrawRadius
	end
end

function SWEP:GetCollisionRadii(issub)
	local p = self.Parameters
	if issub then
		return p.mSplashSubCollisionRadiusForPlayer,
			   p.mSplashSubCollisionRadiusForField
	else
		return p.mSplashCollisionRadiusForPlayer,
			   p.mSplashCollisionRadiusForField
	end
end

function SWEP:GetPaintParameters(issub)
	local p = self.Parameters
	if issub then
		return p.mSplashSubPaintNearD,
			   p.mSplashSubPaintNearR,
			   p.mSplashSubPaintFarD,
			   p.mSplashSubPaintFarR
	else
		return p.mSplashPaintNearD,
			   p.mSplashPaintNearR,
			   p.mSplashPaintFarD,
			   p.mSplashPaintFarR
	end
end

function SWEP:GetDamageParameters(t)
	local p = self.Parameters
	if t == "sub" then
		return p.mSplashSubDamageMaxValue,
			   p.mSplashSubDamageMaxDist,
			   p.mSplashSubDamageMinValue,
			   p.mSplashSubDamageMinDist,
			   p.mSplashSubDamageRateBias
	elseif t == "outside" then
		return p.mSplashOutsideDamageMaxValue,
			   p.mSplashOutsideDamageMaxDist,
			   p.mSplashOutsideDamageMinValue,
			   p.mSplashOutsideDamageMinDist,
			   p.mSplashDamageRateBias
	else
		return p.mSplashDamageMaxValue,
			   p.mSplashDamageMaxDist,
			   p.mSplashDamageMinValue,
			   p.mSplashDamageMinDist,
			   p.mSplashDamageRateBias
	end
end

function SWEP:GetInitVelocity(i, splashnum, sb, sz, sx, sy, degmax)
	local p = self.Parameters
	local frac = splashnum == 1 and 1 or (i - 1) / (splashnum - 1)
	local deg = (frac * 2 - 1) * degmax
	local forward = sb + util.SharedRandom(randvel, -sz, sz, i)
	local right = util.SharedRandom(randvel, -sx, sx, i * 2)
	local up = sb * sy
	return forward, right + deg, up
end

function SWEP:CreateInk(createnum)
	local p = self.Parameters
	local dir = self:GetAimVector()
	local pos = self:GetShootPos()
	local right = self.Owner:GetRight()
	local splashnum = p.mSplashNum
	local skipnum = splashnum - createnum
	local width = p.mSplashPositionWidth
	local insiderate = p.mSplashInsideDamageRate
	local insidenum = math.floor(splashnum * insiderate)
	local randomorder, skiptable = {}, {}
	local ang = dir:Angle()
	local angoffset = p.mPaintBrushRotYDegree
	local angsign = self:GetIsSecondSwing() and 1 or -1
	local insidestart = (splashnum - insidenum) / 2
	local nextskip = 1
	local function SpawnInk(self, i, t)
		if not self:IsFirstTimePredicted() then return end
		local issub = t == "sub"
		local isoutside = i < insidestart or splashnum - i < insidestart
		if isoutside and not issub then t = "outside" end
		local frac = splashnum == 1 and 1 or (i - 1) / (splashnum - 1)
		local dp = right * (frac * 2 - 1) * width
		local vf, vr, vu = self:GetInitVelocity(i, splashnum, self:GetVelocitySpread(issub))
		local initvelocity = ang:Forward() * vf + ang:Right() * vr + ang:Up() * vu
		local yaw = initvelocity:Angle().yaw
		local dmax, dmaxdist, dmin, dmindist = self:GetDamageParameters(t)
		local pfd, pfr, pnd, pnr = self:GetPaintParameters(issub)
		local colent, colworld = self:GetCollisionRadii(issub)
		local str = self:GetStraightFrame(issub)
		local aperturefreeframe = issub -- Unknown parameter, unused for now
		and p.mSplashSubCoverApertureFreeFrame
		or p.mSplashCoverApertureFreeFrame
		
		if initvelocity.x == 0 and initvelocity.y == 0 then yaw = ang.yaw end
		table.Merge(self.Projectile, {
			InitPos = pos + dp,
			InitVel = initvelocity,
			Type = util.SharedRandom(randink, 4, 9, CurTime() * i),
			Yaw = yaw,

			ColRadiusEntity = colent,
			ColRadiusWorld = colworld,
			DamageMax = dmax,
			DamageMaxDistance = dmaxdist,
			DamageMin = dmin,
			DamageMinDistance = dmindist,
			PaintFarDistance = pfd,
			PaintFarRadius = pfr,
			PaintNearDistance = pnd,
			PaintNearRadius = pnr,
			StraightFrame = str,
		})
	
		local e = EffectData()
		ss.SetEffectColor(e, self.Projectile.Color)
		ss.SetEffectColRadius(e, self.Projectile.ColRadiusWorld)
		ss.SetEffectDrawRadius(e, self:GetDrawRadius(issub))
		ss.SetEffectEntity(e, self)
		ss.SetEffectFlags(e, self)
		ss.SetEffectInitPos(e, self.Projectile.InitPos)
		ss.SetEffectInitVel(e, self.Projectile.InitVel)
		ss.SetEffectSplash(e, Angle(self.Projectile.SplashColRadius, p.mDropSplashDrawRadius, self.Projectile.SplashLength))
		ss.SetEffectSplashInitRate(e, Vector(self.Projectile.SplashInitRate))
		ss.SetEffectSplashNum(e, self.Projectile.SplashNum)
		ss.SetEffectStraightFrame(e, self.Projectile.StraightFrame)
		ss.UtilEffectPredicted(self.Owner, "SplatoonSWEPsShooterInk", e, true, self.IgnorePrediction)
		ss.AddInk(p, self.Projectile)
	end

	if splashnum % 1 ~= insidenum % 1 then
		insidenum = insidenum - 1
	end

	for i = 1, splashnum do
		randomorder[i] = i
	end

	for i = 1, splashnum do
		local k = math.Round(util.SharedRandom(randsplash, i, splashnum))
		randomorder[i], randomorder[k] = randomorder[k], randomorder[i]
	end

	for i = 1, skipnum do
		skiptable[randomorder[i]] = true
	end

	if self:GetNWBool "lefthand" then angsign = -angsign end
	ang:RotateAroundAxis(ang:Up(), angoffset * angsign)
	self.Projectile.Color = self:GetNWInt "inkcolor"
	self.Projectile.ID = CurTime() + self:EntIndex()
	for i = 1, splashnum do
		if nextskip < skipnum and skiptable[i] then
			nextskip = nextskip + 1
		else
			SpawnInk(self, i)
		end
	end

	if skipnum > 0 then return end
	for i = 1, p.mSplashSubNum do
		SpawnInk(self, randomorder[i], "sub")
	end
end

function SWEP:SharedInit()
	local p = self.Parameters
	self.SwingCountInit = p.mPaintBrushNearestBulletLoopNum - p.mPaintBrushNearestBulletOrderNum
	self.Bodygroup = table.Copy(self.Bodygroup or {})
	self.IsBrush = self.Parameters.mPaintBrushType
	self.RollSound = CreateSound(self, self.RollSoundName)
	self.EmptyRollSound = CreateSound(self, self.IsBrush and ss.EmptyRun or ss.EmptyRoll)
	self.RunoverExceptions = {}
	self:SetIsSecondSwing(false)
	self:SetMousePressedTime(CurTime())
	self:SetSwingStartTime(CurTime())
	self:SetNextRollingEffectTime(CurTime())
	self:SetMode(self.MODE.READY)
	self:AddSchedule(0, function(self, schedule)
		if self.IsBrush then return end
		self.Bodygroup[1] = self:GetInk() > 0 and 0 or 1
		if not self.IsHeroWeapon then return end
		self.Skin = self:GetNWInt "level"
	end)

	table.Merge(self.Projectile, {
		AirResist = 0.15,
		Gravity = 0.15 * ss.ToHammerUnitsPerSec2,
		PaintRatioNearDistance = 25 * ss.ToHammerUnits,
	})
end

function SWEP:SharedDeploy()
	if not self.IsBrush then return end
	self:SetIsSecondSwing(false)
	self:SetMousePressedTime(CurTime())
	self:SetSwingStartTime(CurTime())
	self:SetNextRollingEffectTime(CurTime())
	self:SetMode(self.MODE.READY)
	self:SetSwingCount(self.SwingCountInit)
end

function SWEP:SharedHolster()
	self.NotEnoughInk = false
	self:SetIsSecondSwing(false)
	self:SetMode(self.MODE.READY)
end

function SWEP:SharedPrimaryAttack(able, auto)
	local anim = ACT_VM_PRIMARYATTACK
	local mode = self:GetMode()
	local p = self.Parameters
	if mode == self.MODE.PAINT then return end
	if mode == self.MODE.ATTACK then return end
	local swingdelay = self.IsBrush and 4 or 0
	local issecond = self.IsBrush and self:GetIsSecondSwing()
	if issecond then anim = ACT_VM_SECONDARYATTACK end

	self:SetMode(self.MODE.ATTACK)
	self:SetMousePressedTime(CurTime())
	self:SetSwingStartTime(CurTime() + p.mSwingLiftFrame)
	self:SetIsSecondSwingAnim(self:GetIsSecondSwing())
	self:SetWeaponAnim(anim)
	if not (self.IsBrush or issecond) then
		self.Owner:SetAnimation(PLAYER_ATTACK1)
	end

	if self.IsBrush then
		-- This is needed in multiplayer to predict muzzle effects.
		self:ResetSequence(issecond and "fire2" or "fire")

		if not self:GetNWBool "dropatfeet" then return end
		local p = self.Parameters
		if self:GetInk() < p.mInkConsumeSplash then return end
		local count = self:GetSwingCount() + 1
		if count >= p.mPaintBrushNearestBulletLoopNum then
			local dropdata = ss.MakeProjectileStructure()
			table.Merge(dropdata, {
				Color = self:GetNWInt "inkcolor",
				DoDamage = false,
				InitPos = self:GetShootPos(),
				PaintFarDistance = 0,
				PaintFarRadius = p.mPaintBrushNearestBulletRadius,
				PaintNearDistance = 0,
				PaintNearRadius = p.mPaintBrushNearestBulletRadius,
				Weapon = self,
				Yaw = self:GetAimVector():Angle().yaw,
			})
			
			ss.AddInk(p, dropdata)
			count = 0
		end

		self:SetSwingCount(count)
		return
	end

	if not self:IsFirstTimePredicted() then return end
	self:EmitSound(self.PreSwingSound)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "IsSecondSwing")
	self:AddNetworkVar("Bool", "IsSecondSwingAnim")
	self:AddNetworkVar("Float", "MousePressedTime")
	self:AddNetworkVar("Float", "SwingStartTime")
	self:AddNetworkVar("Float", "SwingEndTime")
	self:AddNetworkVar("Float", "NextRollingEffectTime")
	self:AddNetworkVar("Float", "RunoverDelay")
	self:AddNetworkVar("Int", "Mode")
	self:AddNetworkVar("Int", "SwingCount")
end

function SWEP:Move(ply, mv)
	local p = self.Parameters
	local mode = self:GetMode()
	local keyrelease = not (ply:IsPlayer() and self:GetKey() == IN_ATTACK)
	if self.Owner:IsPlayer() and CurTime() < self:GetRunoverDelay() then
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
	end

	if mode == self.MODE.PAINT then
		if keyrelease and CurTime() > self:GetSwingStartTime() + self.SwingBackWait then
			EndSwing(self)
			return
		end

		local soundplay, soundstop = self.RollSound, self.EmptyRollSound
		local velocity = 1
		if ply:IsPlayer() then
			velocity = math.abs(ply:GetVelocity():Dot(ply:GetForward())) / ply:GetMaxSpeed()
		elseif ply:IsNPC() and isfunction(ply.IsMoving) then
			velocity = ply:IsMoving() and 1 or 0
		end

		if ply:OnGround() and self:GetInk() == 0 then
			soundplay, soundstop = soundstop, soundplay
		end

		soundplay:ChangeVolume(velocity * (ply:OnGround() and 1 or 0))
		soundstop:ChangeVolume(0)
		
		if velocity < 0.01 then return end
		self:SetReloadDelay(p.mInkRecoverCoreStop)

		if not ply:OnGround() then return end
		if self:GetInk() == 0 then
			if ss.mp and SERVER then return end
			if self.NotEnoughInkRoll then return end
			self.NotEnoughInkRoll = true
			ss.EmitSound(ply, ss.TankEmpty)
			return
		end
		
		local color = self:GetNWInt "inkcolor"
		local inktype = util.SharedRandom(rand, 10, 12)
		local widthmul = self.IsBrush and 1 or 0.67 -- This should be removed, I guess.
		local width = Lerp(velocity, p.mCorePaintSlowMoveWidthHalf, p.mCorePaintWidthHalf) * widthmul
		local yaw = self:GetAimVector():Angle().yaw + 90
		local t = GetRollerTrace(self)
		ss.Paint(t.HitPos, t.HitNormal, width, color, yaw, inktype, .25, self.Owner, self.ClassName)

		DoRollingEffect(self, velocity)
		DoRunover(self, t, mv)
		self.NotEnoughInkRoll = false

		local inkconsumerate = FrameTime() / ss.FrameToSec
		local inkconsume = p.mInkConsumeCore * inkconsumerate
		self:SetInk(math.max(self:GetInk() - inkconsume, 0))
		return
	end

	if mode == self.MODE.READY then return end
	self:SetReloadDelay(p.mInkRecoverSplashStop)

	if mode == self.MODE.ATTACK then
		self:SetCooldown(CurTime() + FrameTime())
		if CurTime() < self:GetSwingStartTime() then return end
		local frac = math.min(self:GetInk() / p.mInkConsumeSplash, 1)
		local splashnum = math.floor(frac * p.mSplashNum)
		local enoughink = self:GetInk() > p.mInkConsumeSplash
		self:SetInk(math.max(self:GetInk() - p.mInkConsumeSplash, 0))

		if self.IsBrush then
			self.NotEnoughInk = false
			self.Primary.Automatic = self:GetNWBool "automaticbrush"
			self:SetMode(self.MODE.ATTACK2)
			self:SetCooldown(CurTime() + p.mPaintBrushSwingRepeatFrame)
			self:SetSwingEndTime(CurTime() + self.SwingBackWait)
			self:SetIsSecondSwing(not self:GetIsSecondSwing())
		else
			self:SetMode(self.MODE.PAINT)
			self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)
			self:ResetSequence "fire2" -- This is needed in multiplayer to predict muzzle effects.
		end

		if not self:IsFirstTimePredicted() then return end
		PlaySwingSound(self, enoughink)
		if not enoughink and splashnum == 0 then return end
		self:CreateInk(splashnum)
		return	
	end

	if CurTime() < self:GetSwingEndTime() then
		if self.Primary.Automatic then return end
		self.Primary.Automatic = keyrelease
		return
	end

	if keyrelease then
		EndSwing(self)
	else
		self:SetMode(self.MODE.PAINT)
		self:SetWeaponAnim(ACT_VM_HITCENTER)
	end
end

function SWEP:CustomActivity() return "melee2" end
function SWEP:UpdateAnimation(ply, velocity, maxseqspeed)
	local mode = self:GetMode()
	local ct = CurTime() + (self:IsMine() and self:Ping() or 0)
	local start, duration, c1, c2
	if mode == self.MODE.READY then return end
	if mode == self.MODE.ATTACK or mode == self.MODE.ATTACK2 then
		if self.IsBrush then
			start = self:GetMousePressedTime()
			duration = self.PreSwingTime
			c1, c2 = .3, .6125
			if self:GetIsSecondSwingAnim() then
				c1, c2 = c2, c1
			end
		else
			start = self:GetMousePressedTime()
			duration = self.PreSwingTime
			c1, c2 = 0, .3
		end
	else
		start = self:GetSwingStartTime()
		duration = self.SwingAnimTime
		c1, c2 = .3, .6125
		if self:GetIsSecondSwingAnim() then
			start = self:GetSwingEndTime()
		end
	end
	
	local f = math.TimeFraction(start, start + duration, ct)
	local cycle = Lerp(math.EaseInOut(math.Clamp(f, 0, 1), 0, 1), c1, c2)
	ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, ply:SelectWeightedSequence(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2), cycle, true)
end

function SWEP:CustomMoveSpeed()
	if self:GetMode() == self.MODE.ATTACK or self:GetMode() == self.MODE.ATTACK2 then
		return self:GetInklingSpeed() / 2
	end

	if self:GetMode() ~= self.MODE.PAINT then return end
	if not self.Owner:OnGround() then return end
	if self:GetInk() > 0 then
		return self.Parameters.mMoveSpeed
	end

	-- return self.Parameters.mSlowMoveSpeed -- Disabled for now
end
