
local ss = SplatoonSWEPs
if not ss then return end

local mdl = Model "models/props_junk/PopCan01a.mdl"
function EFFECT:Init(e)
	self:SetModel(mdl)
	self:SetMaterial(ss.Materials.Effects.Invisible)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	local c = e:GetColor()
	local f = e:GetFlags()
	local p = self.Weapon.Parameters
	local color = ss.GetColor(c)
	local colradius = e:GetMagnitude()
	local initpos = e:GetOrigin()
	local initvel = e:GetStart()
	local isdrop = bit.band(f, 1) > 0
	local IsLP = bit.band(f, 128) > 0
	local IsBlasterSphereSplashDrop = bit.band(f, 2) > 0
	local IsCharger = self.Weapon.IsCharger
	local IsRoller = self.Weapon.IsRoller
	local IsRollerSubSplash = bit.band(f, 4) > 0
	local ping = IsLP and self.Weapon:Ping() or 0
	local prog = e:GetScale() -- For chargers
	local splashinit = e:GetAttachment()
	local splashnum = e:GetScale()
	local pos, ang = self.Weapon:GetMuzzlePosition()
	local range = 0
	local speed = initvel:Length()
	local initdir = initvel:GetNormalized()
	local splashratio = IsCharger and Lerp(prog, p.mSplashDepthMinChargeScaleRateByWidth, p.mSplashDepthMaxChargeScaleRateByWidth)
	local splashrate = IsCharger and Lerp(prog, p.mSplashBetweenMaxSplashPaintRadiusRate, p.mSplashBetweenMinSplashPaintRadiusRate) or 0
	local splashradius = IsCharger and Lerp(prog, p.mPaintNearR_WeakRate, 1) * p.mMaxChargeSplashPaintRadius * splashratio or 0
	local splashlength = Either(IsCharger, splashrate * splashradius, p.mCreateSplashLength) or 0
	local splashcolradius = Either(IsCharger, colradius, p.mSplashColRadius)
	local splitnum = IsRoller and 1 or p.mSplashSplitNum
	local straightframe = p.mStraightFrame
	local drawradius = IsBlasterSphereSplashDrop and p.mSphereSplashDropDrawRadius or p.mDrawRadius
	if IsRoller then
		drawradius = IsRollerSubSplash and p.mSplashSubDrawRadius or p.mSplashDrawRadius
		straightframe = IsRollerSubSplash and p.mSplashSubStraightFrame or p.mSplashStraightFrame
	elseif isdrop then
		straightframe = 0
	elseif IsCharger then
		if self.Weapon.IsScoped then
			range = ss.Lerp3(prog, p.mMinDistance, p.mMaxDistanceScoped, p.mFullChargeDistanceScoped)
		else
			range = ss.Lerp3(prog, p.mMinDistance, p.mMaxDistance, p.mFullChargeDistance)
		end

		straightframe = range / speed
	end

	local decreaseframe = (isdrop or IsCharger) and 0 or ss.ShooterDecreaseFrame
	local fallingframe = straightframe + decreaseframe
	local destination = initpos + Either(IsCharger, initdir * range, initvel * fallingframe)
	local trailoffset = -initdir * splashlength * (IsBlasterSphereSplashDrop and 0 or 1)
	local apparentdir = (destination - pos):GetNormalized()
	local apparentrange = destination:Distance(pos)
	local apparentspeed = speed * apparentrange / range
	local apparentvel = Either(IsCharger, apparentdir * apparentspeed, (destination - pos) / fallingframe)

	self.Charge = prog
	self.Color = color
	self.ColorCode = c
	self.ColorTable = {color.r, color.g, color.b, 255}
	self.ColorVector = color:ToVector()
	self.ColRadius = colradius
	self.CreateSplashLength = splashlength
	self.CreateSplashNum = splashnum
	self.DrawRadius = drawradius
	self.IsBlaster = not isdrop and self.Weapon.IsBlaster
	self.IsCharger = IsCharger
	self.IsCarriedByLocalPlayer = self.Weapon:IsCarriedByLocalPlayer()
	self.IsDrop = isdrop
	self.Range = range
	self.Render = ss.Simulate.EFFECT_ShooterRender
	self.Simulate = ss.Simulate.Shooter
	self.SplashCount = 0
	self.SplashColRadius = splashcolradius
	self.SplashInit = splashradius + splashinit * self.CreateSplashLength / splitnum
	self.Think = ss.Simulate.EFFECT_ShooterThink

	self.Real = ss.MakeInkQueueStructure()
	self.Real.Data = table.Merge(ss.MakeProjectileStructure(), {
		DoDamage = not isdrop,
		InitPos = initpos,
		InitVel = initvel,
		IsCharger = IsCharger,
		StraightFrame = straightframe,
	})
	self.Real.InitTime = CurTime() - ping
	self.Real.IsCarriedByLocalPlayer = IsLP
	self.Real.Parameters = p
	self.Real.Trace.filter = self.Weapon.Owner
	self.Real.Trace.maxs:Mul(colradius)
	self.Real.Trace.mins:Mul(colradius)
	self.Real.Trace.endpos:Set(self.Real.Data.InitPos)
	self.Real.Data.InitDir = self.Real.Data.InitVel:GetNormalized()
	self.Real.Data.InitSpeed = self.Real.Data.InitVel:Length()

	self.Apparent = ss.MakeInkQueueStructure()
	self.Apparent.Data = table.Merge(ss.MakeProjectileStructure(), {
		DoDamage = not isdrop,
		Angle = ang,
		InitPos = pos,
		InitVel = apparentvel,
		IsCharger = IsCharger,
		StraightFrame = straightframe,
	})
	self.Apparent.InitTime = self.Real.InitTime
	self.Apparent.IsCarriedByLocalPlayer = self.Real.IsCarriedByLocalPlayer
	self.Apparent.Parameters = self.Real.Parameters
	self.Apparent.Trace.filter = self.Real.Trace.filter
	self.Apparent.Trace.maxs = self.Real.Trace.maxs
	self.Apparent.Trace.mins = self.Real.Trace.mins
	self.Apparent.Trace.endpos:Set(self.Apparent.Data.InitPos)
	self.Apparent.Data.InitDir = self.Apparent.Data.InitVel:GetNormalized()
	self.Apparent.Data.InitSpeed = self.Apparent.Data.InitVel:Length()
	
	if isdrop then
		self.Apparent.Data.Angle = self.Real.Data.InitDir:Angle()
		self.Apparent.Data.InitPos = self.Real.Data.InitPos
		self.Apparent.Data.InitSpeed = 0
		self.Apparent.Data.InitVel = vector_origin
		self.Apparent.Trace.endpos:Set(self.Apparent.Data.InitPos)
	end

	self.Tail = ss.MakeInkQueueStructure()
	self.Tail.Data = table.Copy(self.Apparent.Data)
	self.Tail.Data.InitPos = self.Tail.Data.InitPos + trailoffset
	self.Tail.InitTime = self.Real.InitTime + ss.ShooterTrailDelay
	self.Tail.IsCarriedByLocalPlayer = self.Real.IsCarriedByLocalPlayer
	self.Tail.Parameters = self.Real.Parameters
	self.Tail.Trace.filter = self.Real.Trace.filter
	self.Tail.Trace.maxs = self.Real.Trace.maxs
	self.Tail.Trace.mins = self.Real.Trace.mins
	self.Tail.Trace.endpos:Set(self.Tail.Data.InitPos)

	self.Table = {self.Real, self.Apparent, self.Tail}

	self:SetAngles(self.Apparent.Data.Angle)
	self:SetPos(self.Apparent.Data.InitPos)
end

function EFFECT:CreateDrops(tr) -- Creates ink drops
	if self.IsDrop then return end
	if not self.IsCharger and self.SplashCount >= self.CreateSplashNum then return end
	local e = EffectData()
	local app = self.Apparent.Data
	local dir = app.InitDir
	local init = app.InitPos
	local ischarger = self.IsCharger
	local len = tr.HitPos - init
	local nextlen = self.SplashCount * self.CreateSplashLength + self.SplashInit
	local num = self.CreateSplashNum
	local range = self.Range
	local realinit = self.Real.Data.InitVel

	len = ischarger and len:Length() or len:Length2D()
	if not ischarger then
		dir.z = 0 dir:Normalize()
	end

	while len >= nextlen and Either(ischarger, len < range, self.SplashCount < num) do
		local pos = init + dir * nextlen
		if not ischarger then
			pos.z = Lerp(nextlen / len, init.z, tr.HitPos.z)
		end
		
		e:SetAttachment(0)
		e:SetColor(self.ColorCode)
		e:SetEntity(self.Weapon)
		e:SetFlags(1)
		e:SetMagnitude(self.SplashColRadius)
		e:SetOrigin(pos)
		e:SetScale(ischarger and self.Charge or 0)
		e:SetStart(ischarger and realinit or vector_origin)
		util.Effect("SplatoonSWEPsShooterInk", e)
		nextlen = nextlen + self.CreateSplashLength
		self.SplashCount = self.SplashCount + 1
	end
end

function EFFECT:HitEffect(tr) -- World hit effect here
	local e = EffectData()
	e:SetAngles(tr.HitNormal:Angle())
	e:SetAttachment(6)
	e:SetColor(self.ColorCode)
	e:SetEntity(NULL)
	e:SetFlags(1)
	e:SetOrigin(tr.HitPos - tr.HitNormal * self.DrawRadius)
	e:SetRadius(self.DrawRadius * 5)
	e:SetScale(.4)
	util.Effect("SplatoonSWEPsMuzzleSplash", e)
end
