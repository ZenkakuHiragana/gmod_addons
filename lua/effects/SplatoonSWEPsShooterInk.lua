
local ss = SplatoonSWEPs
if not ss then return end

local InflateTime = 4 * ss.FrameToSec
local TrailLagTime = 20 * ss.FrameToSec
local invisiblemat = ss.Materials.Effects.Invisible
local mat = ss.Materials.Effects.Ink
local mdl = Model "models/props_junk/PopCan01a.mdl"
local filter1 = Material "splatoonsweps/effects/roller_ink"
local filter2 = Material "splatoonsweps/effects/roller_ink_filter"
local inksplash = Material "splatoonsweps/effects/muzzlesplash"
local inkring = Material "splatoonsweps/effects/inkring"
local inkring_alphatest = Material "splatoonsweps/effects/inkring_alphatest"
local inkmaterial = Material "splatoonsweps/splatoonink"
local normalmaterial = Material "splatoonsweps/splatoonink_normal"
local function AdvanceVertex(color, pos, normal, u, v, alpha)
	mesh.Color(unpack(color))
	mesh.Normal(normal)
	mesh.Position(pos)
	mesh.TexCoord(0, u, v)
	mesh.AdvanceVertex()
end

local function DrawMesh(MeshTable, color)
	mesh.Begin(MATERIAL_TRIANGLES, 12)
	for _, tri in pairs(MeshTable) do
		local n = (tri[3] - tri[1]):Cross(tri[2] - tri[1]):GetNormalized()
		AdvanceVertex(color, tri[1], n, .5, 0)
		AdvanceVertex(color, tri[2], n, 0, 1)
		AdvanceVertex(color, tri[3], n, 1, 1)
	end
	mesh.End()
end

function EFFECT:Init(e)
	self:SetModel(mdl)
	self:SetMaterial(invisiblemat)
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
	local IsSlosher = self.Weapon.IsSlosher
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
	local splitnum = not IsRoller and p.mSplashSplitNum or 1
	local straightframe = p.mStraightFrame
	local decreaseframe = ss.ShooterDecreaseFrame
	local drawradius = IsBlasterSphereSplashDrop and p.mSphereSplashDropDrawRadius or p.mDrawRadius
	if IsSlosher then
		local misc = e:GetAttachment()
		local bulletgroup = misc % 10
		local spawncount = math.floor(misc / 10)
		drawradius = 20
		straightframe = p.mBulletStraightFrame
		self.DrawSize = self.Weapon:GetDrawRadius(bulletgroup, spawncount) * 3
	elseif IsRoller then
		drawradius = IsRollerSubSplash and p.mSplashSubDrawRadius or p.mSplashDrawRadius
		straightframe = IsRollerSubSplash and p.mSplashSubStraightFrame or p.mSplashStraightFrame
		decreaseframe = ss.RollerDecreaseFrame
		self.DrawSize = p.mSplashPaintNearR
	elseif isdrop then
		straightframe = 0
		decreaseframe = 0
	elseif IsCharger then
		if self.Weapon.IsScoped then
			range = ss.Lerp3(prog, p.mMinDistance, p.mMaxDistanceScoped, p.mFullChargeDistanceScoped)
		else
			range = ss.Lerp3(prog, p.mMinDistance, p.mMaxDistance, p.mFullChargeDistance)
		end

		straightframe = range / speed
		decreaseframe = 0
	end

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
	self.IsRoller = IsRoller
	self.IsSlosher = IsSlosher
	self.Range = range
	self.Simulate = ss.SimulateBullet
	self.SplashCount = 0
	self.SplashColRadius = splashcolradius
	self.SplashInit = splashradius + splashinit * self.CreateSplashLength / splitnum

	self.Real = ss.MakeInkQueueStructure()
	self.Real.Data = table.Merge(ss.MakeProjectileStructure(), {
		DoDamage = not isdrop,
		InitPos = initpos,
		InitVel = initvel,
		IsCharger = IsCharger,
		IsRoller = IsRoller,
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
		IsRoller = IsRoller,
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
	if self.IsRoller or self.IsSlosher then
		local viewang = -LocalPlayer():GetViewEntity():GetAngles():Forward()
		self.Render = self.Render2
		self.FilterDU = math.random()
		self.FilterDV = math.random()
		self.FilterDU2 = math.random()
		self.FilterDV2 = math.random()
		self.Material = math.random() > 0.5 and inksplash or inkring
		self.Normal = (viewang + VectorRand() / 4):GetNormalized()
	end
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

-- Called when the effect should think, return false to kill the effect.
function EFFECT:Think()
	if not (IsValid(self.Weapon) and IsValid(self.Weapon.Owner)
	and ss.IsInWorld(self.Real.Trace.endpos)) then return false end
	for _, t in ipairs(self.Table) do self.Simulate(t) end
	local tr = util.TraceHull(self.Real.Trace)
	local lp = LocalPlayer()
	local la = Angle(0, lp:GetAngles().yaw, 0)
	local trlp = self.Weapon.Owner ~= LocalPlayer()
	local start, endpos = self.Real.Trace.start, self.Real.Trace.endpos
	if trlp then trlp = ss.TraceLocalPlayer(start, endpos - start) end
	if tr.HitWorld then self:HitEffect(tr) end
	self:SetPos(self.Apparent.Trace.endpos)
	self:SetAngles(self.Apparent.Data.Angle)
	self:DrawModel()
	self:CreateDrops(tr)
	if tr.Hit or trlp or not ss.IsInWorld(tr.HitPos) then return false end
	
	local ta = math.max(CurTime() - self.Apparent.InitTime, 0)
	local va = self.Apparent.Data.InitVel
	local tmax = self.Real.Data.StraightFrame
	local tend = ss.ShooterDecreaseFrame + ss.ShooterTermTime
	local frac = (ta - tmax) / tend
	self.Apparent.Data.Angle:Set(LerpAngle(math.Clamp(frac, 0, 1) / 2, va:Angle(), physenv.GetGravity():Angle()))

	if self.IsBlaster then
		return ta < self.Real.Parameters.mExplosionFrame
		or not self.Real.Parameters.mExplosionSleep
	end

	if not self.Weapon.IsRoller then
		local tt = math.max(CurTime() - self.Tail.InitTime, 0)
		local f = math.Clamp((tt - tmax) / TrailLagTime, 0, 0.825)
		self.Tail.Trace.endpos:Set(LerpVector(f, self.Tail.Trace.endpos, self.Apparent.Trace.endpos))
		if not self.IsDrop and tt == 0 then
			self.Tail.Data.InitPos = self.Weapon:GetMuzzlePosition()
			self.Tail.Data.InitDir = self.Weapon:GetAimVector()
			self.Tail.Data.InitVel = self.Tail.Data.InitDir * self.Tail.Data.InitSpeed
			self.Tail.Trace.endpos:Set(self.Tail.Data.InitPos)
		end
	end

	return true
end

function EFFECT:Render()
	local t = math.max(CurTime() - self.Real.InitTime, 0)
	if self.IsBlaster then
		local r = self.Real.Parameters.mCollisionRadiusNear / 2
		render.SetMaterial(mat)
		mat:SetVector("$color", self.ColorVector)
		render.DrawSphere(self.Apparent.Trace.endpos, r, 8, 8, self.Color)
		if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then
			mat:SetVector("$color", ss.vector_one)
			return
		end

		render.PushFlashlightMode(true) -- Ink lit by player's flashlight or a projected texture
		render.DrawSphere(self.Apparent.Trace.endpos, r, 8, 8, self.Color)
		render.PopFlashlightMode()
		mat:SetVector("$color", ss.vector_one)
		return
	end

	local sizeinflate = self.IsDrop and 1 or math.Clamp(t / InflateTime, 0, 1)
	local sizef = sizeinflate * self.DrawRadius
	local sizeb = sizef * .75
	local AppPos, AppAng = self:GetPos(), self:GetAngles()
    local TailPos, TailAng = self.Tail.Trace.endpos, self.Tail.Data.Angle
	if self.IsCharger then
		AppAng = (AppPos - TailPos):Angle()
		TailAng = Angle(AppAng)
	end

	local fore = AppPos + AppAng:Forward() * sizef
	local back = TailPos - TailAng:Forward() * sizeb
	local foreup, foreleft, foreright = Angle(AppAng), Angle(AppAng), Angle(AppAng)
	local backdown, backleft, backright = Angle(TailAng), Angle(TailAng), Angle(TailAng)
	local deg = CurTime() * self.Apparent.Data.InitSpeed / 10
	foreup:RotateAroundAxis(AppAng:Forward(), deg)
	foreleft:RotateAroundAxis(AppAng:Forward(), deg + 120)
	foreright:RotateAroundAxis(AppAng:Forward(), deg - 120)
	backdown:RotateAroundAxis(TailAng:Forward(), deg)
	backleft:RotateAroundAxis(TailAng:Forward(), deg - 120)
	backright:RotateAroundAxis(TailAng:Forward(), deg + 120)
	foreup = AppPos + foreup:Up() * sizef
	foreleft = AppPos + foreleft:Up() * sizef
	foreright = AppPos + foreright:Up() * sizef
	backdown = TailPos - backdown:Up() * sizeb
	backleft = TailPos - backleft:Up() * sizeb
	backright = TailPos - backright:Up() * sizeb
	local MeshTable = {
		{fore, foreleft, foreup},
		{fore, foreup, foreright},
		{fore, foreright, foreleft},
		{foreup, backleft, backright},
		{backleft, foreup, foreleft},
		{foreleft, backdown, backleft},
		{backdown, foreleft, foreright},
		{foreright, backright, backdown},
		{backright, foreright, foreup},
		{back, backleft, backdown},
		{back, backdown, backright},
		{back, backright, backleft},
	}

	render.SetMaterial(mat)
	mat:SetVector("$color", self.ColorVector)
	DrawMesh(MeshTable, self.ColorTable)
	if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then
		mat:SetVector("$color", ss.vector_one)
		return
	end

	render.PushFlashlightMode(true) -- Ink lit by player's flashlight or a projected texture
	DrawMesh(MeshTable, self.ColorTable)
	render.PopFlashlightMode()
	mat:SetVector("$color", ss.vector_one)
end

-- A render function for rollers' splash, slosher's projectile, etc.
local duration = 60 * ss.FrameToSec
function EFFECT:Render2()
	local rendertarget = ss.RenderTarget.InkSplash
	local rendermaterial = ss.RenderTarget.InkSplashMaterial
	local t = math.max(CurTime() - self.Real.InitTime, 0)
	local alpha = Lerp(math.EaseInOut(math.Clamp(t / duration, 0, 1), 0, 1), 0.01, 0.5)
	local pos, tailpos = self:GetPos(), self.Tail.Trace.endpos
	local ang, tailang = self:GetAngles(), self.Tail.Data.Angle
	render.PushRenderTarget(rendertarget)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	cam.Start2D()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(self.Material)
	surface.DrawTexturedRect(0, 0, 128, 128)
	render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD, BLEND_DST_ALPHA, BLEND_SRC_ALPHA, BLENDFUNC_ADD)
	surface.SetMaterial(filter1)
	surface.DrawTexturedRectUV(0, 0, 128, 128, self.FilterDU, self.FilterDV, 1 + self.FilterDU, 1 + self.FilterDV)
	surface.SetMaterial(filter2)
	surface.DrawTexturedRectUV(0, 0, 128, 128, self.FilterDU2, self.FilterDV2, 1 + self.FilterDU2, 1 + self.FilterDV2)
	render.OverrideBlend(false)
	cam.End2D()
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	rendermaterial:SetFloat("$alphatestreference", alpha)
	rendermaterial:Recompute()
	render.SetMaterial(rendermaterial)
	render.DrawQuadEasy(self:GetPos(), self.Normal, self.DrawSize, self.DrawSize, self.Color)
end

hook.Remove("HUDPaint", "HUDPaint_DrawABox")
