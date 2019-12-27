
local ss = SplatoonSWEPs
if not ss then return end

local TrailLagTime = 20 * ss.FrameToSec
local ApparentMergeTime = 10 * ss.FrameToSec
local invisiblemat = ss.Materials.Effects.Invisible
local mat = ss.Materials.Effects.Ink
local mdl = Model "models/props_junk/PopCan01a.mdl"
local filter1 = Material "splatoonsweps/effects/roller_ink"
local filter2 = Material "splatoonsweps/effects/roller_ink_filter"
local inksplash = Material "splatoonsweps/effects/muzzlesplash"
local inkring = Material "splatoonsweps/effects/inkring"
local RenderFuncs = {
	weapon_splatoonsweps_blaster_base = "RenderBlaster",
	weapon_splatoonsweps_roller = "RenderSplash",
	weapon_splatoonsweps_slosher_base = "RenderSlosher",
	weapon_splatoonsweps_sloshingmachine = "RenderSloshingMachine",
	weapon_splatoonsweps_sloshingmachine_neo = "RenderSloshingMachine",
}

local OrdinalNumbers = {"First", "Second", "Third"}
function EFFECT:Init(e)
	self:SetModel(mdl)
	self:SetMaterial(invisiblemat)
	local Weapon = ss.GetEffectEntity(e)
	if not IsValid(Weapon) then return end
	if not IsValid(Weapon.Owner) then return end
	local Owner = Weapon.Owner
	local AirResist = Weapon.Projectile.AirResist
	local ApparentPos, ApparentAng = Weapon:GetMuzzlePosition()
	local p = Weapon.Parameters
	local f = ss.GetEffectFlags(e)
	local AirResist = Weapon.Projectile.AirResist
	local ColorID = ss.GetEffectColor(e)
	local ColorValue = ss.GetColor(ColorID)
	local ColRadius = ss.GetEffectColRadius(e)
	local Gravity = Weapon.Projectile.Gravity
	local InitPos = ss.GetEffectInitPos(e)
	local InitVel = ss.GetEffectInitVel(e)
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
	local Splash = ss.GetEffectSplash(e)
	local SplashColRadius = Splash.pitch
	local SplashDrawRadius = Splash.yaw
	local SplashInitRate = ss.GetEffectSplashInitRate(e).x
	local SplashLength = Splash.roll
	local SplashNum = ss.GetEffectSplashNum(e)
	local StraightFrame = ss.GetEffectStraightFrame(e)
	local DrawRadius = ss.GetEffectDrawRadius(e)
	local RenderFunc = RenderFuncs[Weapon.ClassName] or RenderFuncs[Weapon.Base] or "RenderGeneral"
	if IsSlosher then DrawRadius = DrawRadius / 3 end
	if IsCharger then SplashNum = math.huge end
	if IsDrop then
		AirResist = 1
		ApparentPos = InitPos
		Gravity = 1 * ss.ToHammerUnitsPerSec2
		RenderFunc = "RenderGeneral"
	end
	
	self.Ink = ss.MakeInkQueueStructure()
	self.Ink.Data = table.Merge(ss.MakeProjectileStructure(), {
		AirResist = AirResist,
		Color = ColorID,
		ColRadiusEntity = ColRadius,
		ColRadiusWorld = ColRadius,
		DoDamage = not IsDrop,
		Gravity = Gravity,
		InitPos = InitPos,
		InitVel = InitVel,
		SplashColRadius = SplashColRadius,
		SplashDrawRadius = SplashDrawRadius,
		SplashInitRate = SplashInitRate,
		SplashLength = SplashLength,
		SplashNum = SplashNum,
		StraightFrame = StraightFrame,
		Weapon = Weapon,
	})
	self.Ink.InitTime = CurTime() - Ping
	self.Ink.IsCarriedByLocalPlayer = IsLP
	self.Ink.Parameters = p
	self.Ink.Trace.filter = Owner
	self.Ink.Trace.maxs:Mul(ColRadius)
	self.Ink.Trace.mins:Mul(ColRadius)
	self.Ink.Trace.endpos:Set(self.Ink.Data.InitPos)
	self.Ink.Data.InitDir = self.Ink.Data.InitVel:GetNormalized()
	self.Ink.Data.InitSpeed = self.Ink.Data.InitVel:Length()

	self.Color = ColorValue
	self.ColorVector = ColorValue:ToVector()
	self.DrawRadius = DrawRadius
	self.IsBlaster = not IsDrop and IsBlaster
	self.IsCharger = IsCharger
	self.IsDrop = IsDrop
	self.IsSlosher = IsSlosher
	self.Render = self[RenderFunc]

	self.ApparentInitPos = ApparentPos
	self.TrailPos = ApparentPos
	self.TrailInitPos = ApparentPos
	self:SetPos(ApparentPos)

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
	e:SetColor(self.Ink.Data.Color)
	e:SetEntity(NULL)
	e:SetFlags(1)
	e:SetOrigin(tr.HitPos - tr.HitNormal * self.DrawRadius)
	e:SetRadius(self.DrawRadius * 5)
	e:SetScale(.4)
	util.Effect("SplatoonSWEPsMuzzleSplash", e)
end

-- Called when the effect should think, return false to kill the effect.
function EFFECT:Think()
	if not self.Ink then return false end
	if not self.Ink.Data then return false end
	local Weapon = self.Ink.Data.Weapon
	if not IsValid(Weapon) then return false end
	if not IsValid(Weapon.Owner) then return false end
	if Weapon.Owner:GetActiveWeapon() ~= Weapon then return false end
	if not ss.IsInWorld(self.Ink.Trace.endpos) then return false end
	ss.AdvanceBullet(self.Ink)

	-- Check collision agains local player
	local tr = util.TraceHull(self.Ink.Trace)
	local lp = LocalPlayer()
	local la = Angle(0, lp:GetAngles().yaw, 0)
	local trlp = Weapon.Owner ~= LocalPlayer()
	local start, endpos = self.Ink.Trace.start, self.Ink.Trace.endpos
	if trlp then trlp = ss.TraceLocalPlayer(start, endpos - start) end
	if tr.HitWorld then self:HitEffect(tr) end
	if tr.Hit or trlp then return false end

	local t0 = self.Ink.InitTime
	local t = math.max(CurTime() - t0, 0)
	local initpos = self.Ink.Data.InitPos
	local offset = endpos - initpos
	self:SetPos(LerpVector(math.min(t / ApparentMergeTime, 1), self.ApparentInitPos + offset, endpos))
	self:DrawModel()
	ss.DoDropSplashes(self.Ink, true)
	
	if self.IsBlaster then
		local p = self.Ink.Parameters
		return t < p.mExplosionFrame or not p.mExplosionSleep
	end

	if Weapon.IsRoller then return true end
	
	local tt = math.max(CurTime() - t0 - ss.ShooterTrailDelay, 0)
	if self.IsDrop or tt > 0 then
		local tmax = self.Ink.Data.StraightFrame
		local d = self.Ink.Data
		local f = math.Clamp((tt - tmax) / TrailLagTime, 0, 0.8)
		local p = ss.GetBulletPos(d.InitVel, d.StraightFrame, d.AirResist, d.Gravity, tt + f * ss.ShooterTrailDelay)
		self.TrailPos = LerpVector(f, self.TrailInitPos, initpos) + p
		if self.IsDrop and (self.IsCharger or self.IsSlosher) then
			self.TrailPos:Add(d.InitDir * d.SplashLength / 4)
		end

		return true
	end

	self.TrailPos = Weapon:GetMuzzlePosition() -- Stick the tail to the muzzle
	self.TrailInitPos = self.TrailPos
	return true
end

local cable = Material "splatoonsweps/crosshair/line"
local cabletip = Material "splatoonsweps/crosshair/dot"
function EFFECT:RenderGeneral()
	local sizetip = self.DrawRadius * 0.8
	local AppPos = self:GetPos()
    local TailPos = self.TrailPos
	render.SetMaterial(cabletip)
	render.DrawSprite(TailPos, sizetip, sizetip, self.Color)
	render.DrawSprite(AppPos, sizetip, sizetip, self.Color)
	render.SetMaterial(cable)
	render.DrawBeam(AppPos, TailPos, self.DrawRadius, 0.3, 0.7, self.Color)
end

-- A render function for roller, slosher, etc.
local duration = 60 * ss.FrameToSec
function EFFECT:RenderSplash()
	local radius = self.DrawRadius * 5
	local rendertarget = ss.RenderTarget.InkSplash
	local rendermaterial = ss.RenderTarget.InkSplashMaterial
	local t = math.max(CurTime() - self.Ink.InitTime, 0) * (self.IsSlosher and 0 or 1)
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

function EFFECT:RenderBlaster() -- Blaster bullet
	local t = math.max(CurTime() - self.Ink.InitTime, 0)
	render.SetMaterial(mat)
	mat:SetVector("$color", self.ColorVector)
	render.DrawSphere(self:GetPos(), self.DrawRadius, 8, 8, self.Color)
	if LocalPlayer():FlashlightIsOn() or #ents.FindByClass "*projectedtexture*" > 0 then
		render.PushFlashlightMode(true) -- Ink lit by player's flashlight or a projected texture
		render.DrawSphere(self:GetPos(), r, 8, 8, self.Color)
		render.PopFlashlightMode()
	end
end

function EFFECT:RenderSlosher()
	self:RenderGeneral()
	self:RenderSplash()
end

function EFFECT:RenderSloshingMachine()
	if self.DrawRadius == 0 then return end
	local ang = (self:GetPos() - self.TrailPos):Angle()
	ang:RotateAroundAxis(ang:Up(), 45)
	ang:RotateAroundAxis(ang:Right(), 45)
	mat:SetVector("$color", self.ColorVector)
	render.SetMaterial(mat)
	render.DrawBox(self:GetPos(), ang, ss.vector_one * -10, ss.vector_one * 10, self.Color)
	self:RenderGeneral()
end
