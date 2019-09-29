
local ss = SplatoonSWEPs
if not ss then return end

local rand = "SplatoonSWEPs: Spread"
local randink = "SplatoonSWEPs: Shooter ink type"
local randsplash = "Splatoon SWEPs: SplashNum"
local randvel = "SplatoonSWEPs: Spread velocity"
local function EndSwing(self)
	self:SetIsSecondSwing(false)
	self:SetMode(self.MODE.READY)
	self:SetWeaponAnim(ACT_VM_IDLE)
	self:SetMousePressedTime(CurTime())
	if self.IsBrush or not self:IsFirstTimePredicted() then return end
	self:EmitSound "SplatoonSWEPs.RollerHolster"
end

local function PlaySwingSound(self, enoughink)
	if enoughink then
		if self.SwingSound then
			self:EmitSound(self.SwingSound)
		end
	else
		self:EmitSound "SplatoonSWEPs.EmptySwing"
	end

	self:EmitSound(self.SplashSound)
end

SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.IsRoller = true
SWEP.MODE = {READY = 0, ATTACK = 1, ATTACK2 = 2, PAINT = 4}
SWEP.CollapseRollTime = 10 * ss.FrameToSec
SWEP.PreSwingTime = 10 * ss.FrameToSec
SWEP.SwingAnimTime = 10 * ss.FrameToSec
SWEP.SwingBackWait = 24 * ss.FrameToSec
SWEP.RollingEffectDelay = 12 * ss.FrameToSec

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

function SWEP:GetMiscParameters(issub)
	local p = self.Parameters
	if issub then
		return p.mSplashSubStraightFrame,
			   p.mSplashSubCollisionRadiusForField,
			   p.mSplashSubCollisionRadiusForPlayer,
			   p.mSplashSubCoverApertureFreeFrame
	else
		return p.mSplashStraightFrame,
			   p.mSplashCollisionRadiusForField,
			   p.mSplashCollisionRadiusForPlayer,
			   p.mSplashCoverApertureFreeFrame
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
		return p.mSplashSubDamageMaxDist,
			   p.mSplashSubDamageMinDist,
			   p.mSplashSubDamageMaxValue,
			   p.mSplashSubDamageMinValue,
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

function SWEP:GetInitVelocity(i, splashnum, sb, sz, sx, sy)
	local p = self.Parameters
	local degmax = p.mSplashDeg
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
	local IsLP = CLIENT and self:IsCarriedByLocalPlayer()
	if splashnum % 1 ~= insidenum % 1 then
		insidenum = insidenum - 1
	end

	local randomorder, skiptable = {}, {}
	for i = 1, splashnum do
		table.insert(randomorder, i)
	end

	for i = 1, splashnum do
		local k = math.Round(util.SharedRandom(randsplash, i, splashnum))
		randomorder[i], randomorder[k] = randomorder[k], randomorder[i]
	end

	for i = 1, skipnum do
		skiptable[randomorder[i]] = true
	end

	table.Merge(self.Projectile, {
		Color = self:GetNWInt "inkcolor",
		ID = CurTime() + self:EntIndex(),
	})
	
	local ang = dir:Angle()
	local angoffset = p.mPaintBrushRotYDegree
	local angsign = self:GetIsSecondSwing() and 1 or -1
	local insidestart = (splashnum - insidenum) / 2
	local nextskip = 1
	ang:RotateAroundAxis(ang:Up(), angoffset * angsign)

	local function SpawnInk(self, i, t)
		if not self:IsFirstTimePredicted() then return end
		local issub = t == "sub"
		local isoutside = i < insidestart or splashnum - i < insidestart
		if isoutside and not issub then t = "outside" end
		local frac = splashnum == 1 and 1 or (i - 1) / (splashnum - 1)
		local dp = right * (frac * 2 - 1) * width
		local vf, vr, vu = self:GetInitVelocity(i, splashnum, self:GetVelocitySpread(issub))
		local dmax, dmaxdist, dmin, dmindist = self:GetDamageParameters(t)
		local pfd, pfr, pnd, pnr = self:GetPaintParameters(issub)
		local str, colent, colworld = self:GetMiscParameters(issub)
		table.Merge(self.Projectile, {
			InitPos = pos + dp,
			InitVel = ang:Forward() * vf + ang:Right() * vr + ang:Up() * vu,
			Type = util.SharedRandom(randink, 4, 9, CurTime() * i),
			Yaw = ang.yaw,

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
	
		ss.AddInk(p, self.Projectile)
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
	end

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
	self.Bodygroup = table.Copy(self.Bodygroup or {})
	self.IsBrush = self.Parameters.mPaintBrushType
	self.Projectile.IsRoller = true
	self.RollSound = CreateSound(self, self.RollSoundName)
	self.EmptyRollSound = CreateSound(self, self.IsBrush and ss.EmptyRun or ss.EmptyRoll)
	self.RunoverExceptions = {}
	self:SetMousePressedTime(CurTime())
	self:SetSwingStartTime(CurTime())
	self:SetNextRollingEffectTime(CurTime())
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
	local anim = ACT_VM_PRIMARYATTACK
	local mode = self:GetMode()
	local p = self.Parameters
	if mode == self.MODE.PAINT then return end
	if mode == self.MODE.ATTACK then return end
	if self:GetIsSecondSwing() then
		anim = ACT_VM_SECONDARYATTACK
	end

	self:SetMode(self.MODE.ATTACK)
	self:SetMousePressedTime(CurTime())
	self:SetSwingStartTime(CurTime() + p.mSwingLiftFrame)
	self:SetWeaponAnim(anim)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	if self.IsBrush then return end
	if not self:IsFirstTimePredicted() then return end
	self:EmitSound(self.PreSwingSound)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "IsSecondSwing")
	self:AddNetworkVar("Float", "MousePressedTime")
	self:AddNetworkVar("Float", "SwingStartTime")
	self:AddNetworkVar("Float", "SwingEndTime")
	self:AddNetworkVar("Float", "NextRollingEffectTime")
	self:AddNetworkVar("Float", "RunoverDelay")
	self:AddNetworkVar("Int", "Mode")
end

function SWEP:CustomActivity() return "melee2" end
function SWEP:Move(ply, mv)
	self.Primary.Automatic = false

	local p = self.Parameters
	local mode = self:GetMode()
	local keyrelease = not (ply:IsPlayer() and self:GetKey() == IN_ATTACK)
	if self.Owner:IsPlayer() and CurTime() < self:GetRunoverDelay() then
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
	end

	if mode == self.MODE.PAINT then
		if keyrelease and CurTime() > self:GetSwingStartTime() + self.SwingBackWait then
			self.NotEnoughInk = false
			EndSwing(self)
		end
	
		local s = self:GetInk() > 0 and self.RollSound or self.EmptyRollSound
		local s2 = self:GetInk() > 0 and self.EmptyRollSound or self.RollSound
		local v = ply:OnGround() and 1 or 0
		if ply:IsPlayer() then
			v = v * math.abs(ply:GetVelocity():Dot(ply:GetForward())) / ply:GetMaxSpeed()
		elseif ply:IsNPC() and isfunction(ply.IsMoving) then
			v = v * (ply:IsMoving() and 1 or 0)
		end
		
		s:ChangeVolume(v)
		s2:ChangeVolume(0)
		if v == 0 then return end
		self:SetReloadDelay(p.mInkRecoverCoreStop)
		self:SetCooldown(CurTime() + FrameTime())
		if self:GetInk() > 0 then
			local color = self:GetNWInt "inkcolor"
			local forward = self:GetForward()
			local inktype = util.SharedRandom(rand, 10, 12)
			local pos = self:GetShootPos()
			local widthmul = self.IsBrush and 1 or 0.67 -- This should be removed, I guess.
			local width = Lerp(v, p.mCorePaintSlowMoveWidthHalf, p.mCorePaintWidthHalf) * widthmul
			local yaw = self:GetAimVector():Angle().yaw + 90
			local t = util.TraceLine {
				start = pos + forward * 45,
				endpos = pos + forward * 45 - vector_up * 80,
				filter = {self, self.Owner},
				mask = ss.SquidSolidMask,
			}
			self:SetInk(math.max(self:GetInk() - p.mInkConsumeCore, 0))
			ss.Paint(t.HitPos, t.HitNormal, width, color, yaw, inktype, .25, self.Owner, self.ClassName)
	
			if CurTime() > self:GetNextRollingEffectTime() then
				self:SetNextRollingEffectTime(CurTime() + self.RollingEffectDelay)
				if self:IsFirstTimePredicted() then
					if ss.mp and SERVER then SuppressHostEvents(self.Owner) end
					local name = self.IsBrush and "SplatoonSWEPsRollerRolling" or "SplatoonSWEPsRollerRolling"
					local e = EffectData()
					e:SetEntity(self)
					e:SetRadius(v)
					if not self.IsBrush then -- Remove this after making the effect for brushes!
						util.Effect(name, e, true, self.IgnorePrediction)
					end
	
					if ss.mp and SERVER then SuppressHostEvents(NULL) end
				end
			end
	
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

		return
	end

	self.RollSound:ChangeVolume(0)
	self.EmptyRollSound:ChangeVolume(0)
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
			self:SetMode(self.MODE.ATTACK2)
			self:SetCooldown(CurTime() + p.mPaintBrushSwingRepeatFrame)
			self:SetSwingEndTime(CurTime() + self.SwingBackWait)
			self:SetIsSecondSwing(not self:GetIsSecondSwing())
		else
			self:SetMode(self.MODE.PAINT)
			self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)
			self:ResetSequence "fire2" -- This is needed in multiplayer to prevent delaying muzzle effects.
		end

		if not self:IsFirstTimePredicted() then return end
		if enoughink or splashnum > 0 then
			PlaySwingSound(self, enoughink)
			self:CreateInk(splashnum)
		end

		if (ss.sp or CLIENT) and not (self.NotEnoughInk or enoughink) then
			self.NotEnoughInk = true
			ss.EmitSound(ply, ss.TankEmpty)
		end
	elseif CurTime() < self:GetSwingEndTime() then
		return
	elseif keyrelease then
		EndSwing(self)
	else
		self:SetMode(self.MODE.PAINT)
		self:SetWeaponAnim(ACT_VM_HITCENTER)
	end
end

function SWEP:UpdateAnimation(ply, velocity, maxseqspeed)
	local mode = self:GetMode()
	local ct = CurTime() + (self:IsMine() and self:Ping() or 0)
	local start, duration, c1, c2
	if mode == self.MODE.READY then
		return
	elseif mode == self.MODE.ATTACK then
		start = self:GetMousePressedTime()
		duration = self.PreSwingTime
		c1, c2 = 0, .3
	elseif mode == self.MODE.ATTACK2 then
		start = self:GetMousePressedTime()
		duration = self.PreSwingTime
		c1, c2 = 3, 0.6125
	else
		start = self:GetSwingStartTime()
		duration = self.SwingAnimTime
		c1, c2 = .3, .6125
	end

	local f = math.TimeFraction(start, start + duration, ct)
	local cycle = Lerp(math.EaseInOut(math.Clamp(f, 0, 1), 0, 1), c1, c2)
	ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, ply:SelectWeightedSequence(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2), cycle, true)
end

function SWEP:CustomMoveSpeed()
	if self:GetMode() ~= self.MODE.PAINT then return end
	if not self.Owner:OnGround() then return end
	if self:GetInk() > 0 then
		return self.Parameters.mMoveSpeed
	end

	-- return self.Parameters.mSlowMoveSpeed -- Disabled for now
end
