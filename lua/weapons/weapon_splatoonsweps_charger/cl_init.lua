
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

local crosshairalpha = 64
SWEP.Crosshair = {
	color_circle = ColorAlpha(color_black, crosshairalpha),
	color_nohit = ColorAlpha(color_white, crosshairalpha),
	color_hit = ColorAlpha(color_white, 192),
	Dot = 5, HitLine = 20, HitWidth = 2, -- in pixel
	Inner = 26, Middle = 34, Outer = 38, -- in pixel
	HitLineSize = 114,
}

function SWEP:ClientInit()
	self.CrosshairFlashTime = CurTime()
	self.MinChargeDeg = self.Parameters.mMinChargeFrame / self.Parameters.mMaxChargeFrame * 360
	self.IronSightsPos[6] = self.ScopePos
	self.IronSightsAng[6] = self.ScopeAng
	self.IronSightsFlip[6] = false
	self:GetBase().ClientInit(self)

	if not self.Scoped then return end
	self.RTScope = GetRenderTarget(ss.RenderTarget.Name.RTScope, 512, 512)
	self:AddSchedule(0, function(self, sched)
		if not (self.Scoped and IsValid(self.Owner)) then return end
		self.Owner:SetNoDraw(
			self:IsMine() and
			self:GetScopedProgress() == 1 and
			not self:GetNWBool "usertscope")
	end)
end

function SWEP:Holster()
	self:GetBase().Holster(self)
	if not self.RTScope then return end
	local vm = self:GetViewModel()
	if not IsValid(vm) then return end
	ss.SetSubMaterial_ShouldBeRemoved(vm, self.RTScopeNum - 1)
end

function SWEP:DisplayAmmo()
	if self:GetCharge() == math.huge then return 0 end
	return math.max(self:GetChargeProgress(true) * 100, 0)
end

function SWEP:GetScopedSize()
	return 1 + (self:GetNWBool "usertscope" and self:IsTPS() and 0 or self:GetScopedProgress(true))
end

function SWEP:DrawFourLines(t) end
function SWEP:DrawOuterCircle(t)
	local scoped = self:GetScopedSize()
	local r = t.Size.Outer / 2 * scoped
	local ri = t.Size.Inner / 2 * scoped
	local rm = t.Size.Middle / 2 * scoped
	local prog = self:GetChargeProgress(true)
	if prog == 0 then
		prog = math.Clamp(
			math.max(CurTime() - self:GetCharge() + self:Ping(), 0)
			/ self.Parameters.mMaxChargeFrame * ss.GetTimeScale(self.Owner),
			0, 1) * 360
	else
		prog = prog * (360 - self.MinChargeDeg) + self.MinChargeDeg
	end

	draw.NoTexture()
	surface.SetDrawColor(ColorAlpha(color_black, 192))
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - ri, 90, 450 - prog, 5)
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - rm, 90, 450 - prog, 5)
	surface.SetDrawColor(self.Crosshair.color_hit)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - ri, 90 - prog, 90, 5)

	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r + 1, r - rm)
end

local innerwidth = 2
function SWEP:DrawInnerCircle(t)
	local scoped = self:GetScopedSize()
	local s = t.Size.Inner / 2 * scoped
	if scoped == 2 then return end
	draw.NoTexture()
	surface.SetDrawColor(self.Crosshair.color_nohit)
	ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s + innerwidth, innerwidth)
end

function SWEP:DrawCenterDot(t) -- Center circle
	local scoped = self:GetScopedSize()
	local s = t.Size.Dot / 2 * scoped
	draw.NoTexture()
	if scoped < 2 then
		surface.SetDrawColor(self.Crosshair.color_circle)
		ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s + innerwidth)
		surface.SetDrawColor(self.Crosshair.color_nohit)
		ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s)
	end

	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s + innerwidth)
	surface.SetDrawColor(t.CrosshairColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s)
end

function SWEP:DrawCrosshairFlash(t)
	if not self.FullChargeFlag or CurTime() > self.CrosshairFlashTime + self.FlashDuration then return end
	local s = t.Size.Outer * self:GetScopedSize() * 2
	surface.SetMaterial(ss.Materials.Crosshair.Flash)
	surface.SetDrawColor(ColorAlpha(self:GetInkColor(), (self.CrosshairFlashTime + self.FlashDuration - CurTime()) / self.FlashDuration * 128))
	surface.DrawTexturedRect(t.HitPosScreen.x - s / 2, t.HitPosScreen.y - s / 2, s, s)
end

local MatScope = Material "gmod/scope"
local MatRefScope = Material "gmod/scope-refract"
local MatRefDefault = MatRefScope:GetFloat "$refractamount" or 0 -- Null in DXLevel 80
function SWEP:RenderScreenspaceEffects()
	if not self.Scoped or self:GetNWBool "usertscope" then return end
	local prog = self:GetScopedProgress(true)
	if prog == 0 then return end
	local padding = surface.DrawTexturedRectUV
	local u, v = .115, 1
	local x, y = self.Cursor.x, self.Cursor.y
	local sx, sy = math.ceil(ScrH() * 4 / 3), ScrH()
	local ex, ey = math.ceil(x + sx / 2), math.ceil(y + sy / 2) -- End position of x, y
	x, y = math.floor(x - sx / 2), math.floor(y - sy / 2)

	MatRefScope:SetFloat("$refractamount", prog * prog * MatRefDefault)
	render.UpdateRefractTexture()
	for _, material in ipairs {MatRefScope, MatScope} do
		surface.SetDrawColor(ColorAlpha(color_black, prog * 255))
		surface.SetMaterial(material)
		surface.DrawTexturedRect(x, y - 1, sx, sy + 1)
		if x > 0 then padding(-1, -1, x + 1, ScrH() + 1, 0, 0, u, v) end
		if ex < ScrW() then padding(ex - 1, -1, ScrW() - ex + 1, ScrH() + 1, 0, 0, u, v) end
		if y > 0 then padding(x, -1, sx, y + 1, 0, 0, u, v) end
		if ey < ScrH() then padding(x, ey - 1, ScrW(), ScrH() - ey + 1, 0, 0, u, v) end
	end

	MatRefScope:SetFloat("$refractamount", MatRefDefault)
end

function SWEP:DrawCrosshair(x, y)
	if self:GetCharge() == math.huge then return end
	local t = self:SetupDrawCrosshair()
	local p = self.Parameters
	local dist = self.Scoped and p.mFullChargeDistanceScoped or p.mFullChargeDistance
	t.EndPosScreen = (self:GetShootPos() + self:GetAimVector() * dist):ToScreen()
	t.CrosshairDarkColor = ColorAlpha(t.CrosshairColor, 192)
	t.CrosshairDarkColor.r, t.CrosshairDarkColor.g, t.CrosshairDarkColor.b
	= t.CrosshairDarkColor.r / 2, t.CrosshairDarkColor.g / 2, t.CrosshairDarkColor.b / 2
	self:DrawCenterDot(t)
	self:DrawInnerCircle(t)
	self:DrawOuterCircle(t)
	self:DrawHitCrossBG(t)
	self:DrawHitCross(t)
	self:DrawCrosshairFlash(t)
	return true
end

function SWEP:TranslateFOV(fov)
	if not self.Scoped or self:GetNWBool "usertscope" then return end
	return Lerp(self:GetScopedProgress(true), fov, self.Parameters.mSniperCameraFovy)
end

function SWEP:PreViewModelDrawn(vm, weapon, ply)
	ss.ProtectedCall(self:GetBase().PreViewModelDrawn, self, vm, weapon, ply)
	if not self.Scoped or self:GetNWBool "usertscope" then return end
	render.SetBlend((1 - self:GetScopedProgress(true))^2)
end

function SWEP:PostDrawViewModel(vm, weapon, ply)
	ss.ProtectedCall(self:GetBase().PostDrawViewModel, self, vm, weapon, ply)
	if not self.Scoped then return end
	render.SetBlend(1)

	-- Entity:GetAttachment() for viewmodel returns incorrect value in singleplayer.
	if ss.mp then return end
	self.RTAttachment = self.RTAttachment or vm:LookupAttachment "scope_end"
	if self.RTAttachment then
		self.ScopeOrigin = vm:GetAttachment(self.RTAttachment).Pos
	end
end

function SWEP:PreDrawWorldModel()
	if not self.Scoped or self:GetNWBool "usertscope" then return end
	return self:GetScopedProgress(true) == 1
end

function SWEP:GetArmPos()
	local p = self.Parameters
	local startmove = p.mSniperCameraMoveStartChargeRate
	local endmove = p.mSniperCameraMoveEndChargeRate
	local swaytime = (endmove - startmove) * p.mMaxChargeFrame / 2
	local prog = self:GetChargeProgress(true)
	if not self:GetADS() then return end
	if not self.Scoped then
		self.SwayTime = 12 * ss.FrameToSec
	elseif prog < startmove then
		self.SwayTime = self.TransitFlip and 12 * ss.FrameToSec or swaytime
	end

	return 6
end

function SWEP:CustomCalcView(ply, pos, ang, fov)
	if not self.Scoped then return end
	if self:GetNWBool "usertscope" then return end
	if not (self:IsTPS() and self:IsMine()) then return end
	local p, a = self:GetFirePosition()
	local frac = self:GetScopedProgress(true)
	pos:Set(LerpVector(frac, pos, p))
	ang:Set(LerpAngle(frac, ang, a:Angle()))
	self:SetNoDraw(frac == 1)
end

-- Manipulate player arms to adjust position.  Need to rework.
local delta = {crossbow = 0, rpg = 2}
local deltahand = {rpg = Vector(-10, 5, 5)}
function SWEP:ManipulatePlayer(ply)
	local b = {ply:LookupBone "ValveBiped.Bip01_L_Forearm"}
	local bp, ba = {}, {}
	while #b > 0 do
		local m = ply:GetBoneMatrix(b[1])
		if not m then return end
		local pi = ply:GetBoneParent(b[1])
		local pm = ply:GetBoneMatrix(pi)
		bp[b[1]], ba[b[1]] = WorldToLocal(m:GetTranslation(), m:GetAngles(), pm:GetTranslation(), pm:GetAngles())
		for i, c in ipairs(ply:GetChildBones(b[1])) do
			b[#b + 1] = c
		end
		ss.tablepop(b)
	end

	b = {ply:LookupBone "ValveBiped.Bip01_L_Forearm"}
	while #b > 0 do
		if ply:GetBoneName(b[1]) == "ValveBiped.Bip01_L_Forearm" then
			ba[b[1]]:RotateAroundAxis(vector_up, delta[self.HoldType] or 0)
		elseif ply:GetBoneName(b[1]) == "ValveBiped.Bip01_L_Hand" then
			ba[b[1]]:RotateAroundAxis(Vector(1), (deltahand[self.HoldType] or vector_origin).x)
			ba[b[1]]:RotateAroundAxis(Vector(0, 1), (deltahand[self.HoldType] or vector_origin).y)
			ba[b[1]]:RotateAroundAxis(vector_up, (deltahand[self.HoldType] or vector_origin).z)
		end

		local pi = ply:GetBoneParent(b[1])
		local pm = ply:GetBoneMatrix(pi)
		ply:SetBonePosition(b[1], LocalToWorld(bp[b[1]], ba[b[1]], pm:GetTranslation(), pm:GetAngles()))
		for i, c in ipairs(ply:GetChildBones(b[1])) do
			b[#b + 1] = c
		end
		ss.tablepop(b)
	end
end
