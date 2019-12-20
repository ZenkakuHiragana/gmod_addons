
local ss = SplatoonSWEPs
if not ss then return end

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
local RenderFuncs = {
	weapon_splatoonsweps_roller = "Render2",
	weapon_splatoonsweps_slosher_base = "RenderBoth",
	weapon_splatoonsweps_sloshingmachine = "Render1",
	weapon_splatoonsweps_sloshingmachine_neo = "Render1",
}

local OrdinalNumbers = {"First", "Second", "Third"}
function EFFECT:Init(e)
	self:SetModel(mdl)
	self:SetMaterial(invisiblemat)
	local Weapon = ss.GetEffectEntity()
	if not IsValid(Weapon) then return end
	if not IsValid(Weapon.Owner) then return end
	local Owner = Weapon.Owner
	local ApparentPos, ApparentAng = Weapon:GetMuzzlePosition()
	local p = Weapon.Parameters
	local f = ss.GetEffectFlags()
	local AirResist = Weapon.Projectile.AirResist
	local ColorID = ss.GetEffectColor()
	local ColorValue = ss.GetColor(ColorID)
	local ColRadius = ss.GetEffectColRadius()
	local Gravity = Weapon.Projectile.Gravity
	local InitPos = ss.GetEffectInitPos()
	local InitVel = ss.GetEffectInitVel()
	local InitDir = InitVel:GetNormalized()
	local InitSpeed = InitVel:Length()
	local IsDrop = bit.band(f, 1) > 0
	local IsBlasterSphereSplashDrop = bit.band(f, 2) > 0
	local IsRollerSubSplash = bit.band(f, 4) > 0
	local IsLP = bit.band(f, 128) > 0 -- IsCarriedByLocalPlayer
	local IsBlaster = Weapon.IsBlaster
	local IsCharger = Weapon.IsCharger
	local IsRoller = Weapon.IsRoller
	local IsSlosher = Weapon.IsSlosher
	local Order = OrdinalNumbers[BulletGroup]
	local Ping = IsLP and Weapon:Ping() or 0
	local Splash = ss.GetEffectSplash()
	local SplashColRadius = Splash.x
	local SplashInitRate = Splash.y
	local SplashLength = Splash.z
	local SplashNum = ss.GetEffectSplashNum()
	local StraightFrame = ss.GetEffectStraightFrame()
	local DrawRadius = ss.GetEffectDrawRadius()
	local RenderFunc = RenderFuncs[Weapon.ClassName] or RenderFuncs[Weapon.Base] or "Render1"
	if IsSlosher then DrawRadius = DrawRadius / 3 end
	if IsCharger then
		SplashNum = math.huge
	elseif IsDrop then
		RenderFunc = "Render1"
		SplashLength = 0
	end
	
	self.Real = ss.MakeInkQueueStructure()
	self.Real.Data = table.Merge(ss.MakeProjectileStructure(), {
		AirResist = Weapon.Projectile.AirResist,
		Color = ColorID,
		ColRadiusEntity = ColRadius,
		ColRadiusWorld = ColRadius,
		DoDamage = not IsDrop,
		Gravity = Weapon.Projectile.Gravity,
		InitPos = InitPos,
		InitVel = InitVel,
		SplashColRadius = SplashColRadius,
		SplashInitRate = SplashInitRate,
		SplashLength = SplashLength,
		SplashNum = SplashNum,
		StraightFrame = StraightFrame,
		Weapon = Weapon,
	})
	self.Real.InitTime = CurTime() - Ping
	self.Real.IsCarriedByLocalPlayer = IsLP
	self.Real.Parameters = p
	self.Real.Trace.filter = Owner
	self.Real.Trace.maxs:Mul(ColRadius)
	self.Real.Trace.mins:Mul(ColRadius)
	self.Real.Trace.endpos:Set(self.Real.Data.InitPos)
	self.Real.Data.InitDir = self.Real.Data.InitVel:GetNormalized()
	self.Real.Data.InitSpeed = self.Real.Data.InitVel:Length()

	local Destination = InitPos + ss.GetBulletPos(InitVel, StraightFrame, AirResist, Gravity, StraightFrame)
	local ApparentOffset = Destination - ApparentPos
	local ApparentVel = ApparentOffset / StraightFrame
	self.Apparent = ss.MakeInkQueueStructure()
	self.Apparent.Data = table.Merge(ss.MakeProjectileStructure(), {
		AirResist = Weapon.Projectile.AirResist,
		Color = ColorID,
		ColRadiusEntity = ColRadius,
		ColRadiusWorld = ColRadius,
		DoDamage = not IsDrop,
		Gravity = Weapon.Projectile.Gravity,
		InitPos = ApparentPos,
		InitVel = ApparentVel,
		SplashColRadius = SplashColRadius,
		SplashInitRate = SplashInitRate,
		SplashLength = SplashLength,
		SplashNum = SplashNum,
		StraightFrame = StraightFrame,
		Weapon = Weapon,
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
	
	if IsDrop then
		self.Apparent.Data.InitPos = self.Real.Data.InitPos
		self.Apparent.Data.InitSpeed = 0
		self.Apparent.Data.InitVel = vector_origin
		self.Apparent.Trace.endpos:Set(self.Apparent.Data.InitPos)
	end

	local TrailOffset = InitDir * SplashLength
	self.Tail = ss.MakeInkQueueStructure()
	self.Tail.Data = table.Copy(self.Apparent.Data)
	if not IsBlasterSphereSplashDrop then
		self.Tail.Data.InitPos = self.Tail.Data.InitPos + TrailOffset
	end

	self.Tail.InitTime = self.Real.InitTime + ss.ShooterTrailDelay
	self.Tail.IsCarriedByLocalPlayer = self.Real.IsCarriedByLocalPlayer
	self.Tail.Parameters = self.Real.Parameters
	self.Tail.Trace.filter = self.Real.Trace.filter
	self.Tail.Trace.maxs = self.Real.Trace.maxs
	self.Tail.Trace.mins = self.Real.Trace.mins
	self.Tail.Trace.endpos:Set(self.Tail.Data.InitPos)

	self.Color = ColorValue
	self.ColorVector = ColorValue:ToVector()
	self.DrawRadius = DrawRadius
	self.IsBlaster = not IsDrop and IsBlaster
	self.IsDrop = IsDrop
	self.IsSlosher = IsSlosher
	self.Render = self[RenderFunc]
	self.Simulate = ss.AdvanceBullet
	self.Table = {self.Real, self.Apparent, self.Tail}
	self:SetPos(self.Apparent.Data.InitPos)

	if not (IsRoller or IsSlosher) then return end
	local viewang = -LocalPlayer():GetViewEntity():GetAngles():Forward()
	self.FilterDU = math.random()
	self.FilterDV = math.random()
	self.FilterDU2 = math.random()
	self.FilterDV2 = math.random()
	self.Material = math.random() > 0.5 and inksplash or inkring
	self.Normal = (viewang + VectorRand() / 4):GetNormalized()
end

function EFFECT:HitEffect(tr) -- World hit effect here
	local e = EffectData()
	e:SetAngles(tr.HitNormal:Angle())
	e:SetAttachment(6)
	e:SetColor(self.Real.Data.Color)
	e:SetEntity(NULL)
	e:SetFlags(1)
	e:SetOrigin(tr.HitPos - tr.HitNormal * self.DrawRadius)
	e:SetRadius(self.DrawRadius * 5)
	e:SetScale(.4)
	util.Effect("SplatoonSWEPsMuzzleSplash", e)
end

-- Called when the effect should think, return false to kill the effect.
function EFFECT:Think()
	local Weapon = self.Real.Data.Weapon
	if not IsValid(Weapon) then return false end
	if not IsValid(Weapon.Owner) then return false end
	if not ss.IsInWorld(self.Real.Trace.endpos) then return false end
	for _, t in ipairs(self.Table) do self.Simulate(t) end
	local tr = util.TraceHull(self.Real.Trace)
	local lp = LocalPlayer()
	local la = Angle(0, lp:GetAngles().yaw, 0)
	local trlp = Weapon.Owner ~= LocalPlayer()
	local start, endpos = self.Real.Trace.start, self.Real.Trace.endpos
	if trlp then trlp = ss.TraceLocalPlayer(start, endpos - start) end
	if tr.HitWorld then self:HitEffect(tr) end
	if tr.Hit or trlp then return false end
	ss.DoDropSplashes(self.Apparent, true)
	self:SetPos(self.Apparent.Trace.endpos)
	self:DrawModel()
	
	local ta = math.max(CurTime() - self.Apparent.InitTime, 0)
	local tmax = self.Real.Data.StraightFrame
	if self.IsBlaster then
		return ta < self.Real.Parameters.mExplosionFrame
		or not self.Real.Parameters.mExplosionSleep
	end

	if Weapon.IsRoller then return true end
	local tt = math.max(CurTime() - self.Tail.InitTime, 0)
	if self.IsDrop or tt > 0 then
		local f = math.Clamp((tt - tmax) / TrailLagTime, 0, 0.825)
		self.Tail.Trace.endpos:Set(LerpVector(f, self.Tail.Trace.endpos, self.Apparent.Trace.endpos))
		return true
	end

	self.Tail.Data.InitPos = Weapon:GetMuzzlePosition() -- Stick the tail to the muzzle
	self.Tail.Data.InitDir = Weapon:GetAimVector()
	self.Tail.Data.InitVel = self.Tail.Data.InitDir * self.Tail.Data.InitSpeed
	self.Tail.Trace.endpos:Set(self.Tail.Data.InitPos)
	return true
end

local cable = Material "splatoonsweps/crosshair/line"
local cabletip = Material "splatoonsweps/crosshair/dot"
function EFFECT:Render1()
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

	local sizetip = self.DrawRadius * 0.8
	local AppPos = self.Apparent.Trace.endpos
    local TailPos = self.Tail.Trace.endpos
	render.SetMaterial(cable)
	render.DrawBeam(AppPos, TailPos, self.DrawRadius, 0.3, 0.7, self.Color)
	render.SetMaterial(cabletip)
	render.DrawSprite(AppPos, sizetip, sizetip, self.Color)
	render.DrawSprite(TailPos, sizetip, sizetip, self.Color)
end

-- A render function for roller, slosher, etc.
local duration = 60 * ss.FrameToSec
function EFFECT:Render2()
	local radius = self.DrawRadius * 5
	local rendertarget = ss.RenderTarget.InkSplash
	local rendermaterial = ss.RenderTarget.InkSplashMaterial
	local t = math.max(CurTime() - self.Real.InitTime, 0) * (self.IsSlosher and 0 or 1)
	local alpha = Lerp(math.EaseInOut(math.Clamp(t / duration, 0, 1), 0, 1), 0.01, 0.5)
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
	render.DrawQuadEasy(self:GetPos(), self.Normal, radius, radius, self.Color)
end

function EFFECT:RenderBoth()
	self:Render1()
	self:Render2()
end
