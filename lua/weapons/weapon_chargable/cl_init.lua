
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

local crosshairalpha = 64
local dotbg = 2 -- in pixel
SWEP.Crosshair = {
	color_circle = ColorAlpha(color_black, crosshairalpha),
	color_nohit = ColorAlpha(color_white, crosshairalpha),
	color_hit = ColorAlpha(color_white, 192), 
	Dot = 5, HitLine = 20, HitWidth = 2, -- in pixel
	Inner = 26, Middle = 34, Outer = 38, -- in pixel
	HitLineSize = 114,
}

function SWEP:ClientInit()
	self.PrevCharge = 0
	self.AimSound = CreateSound(self, ss.ChargerAim)
	self.BaseClass.ClientInit(self)
end

function SWEP:DisplayAmmo()
	if not self:GetChargeFlag() then return 0 end
	return math.max(self:GetChargeProgress(true) * 100, 0)
end

function SWEP:ClientPrimaryAttack() end
function SWEP:DrawFourLines(t) end
function SWEP:DrawOuterCircle(t)
	local r = t.Size.Outer / 2
	local ri = t.Size.Inner / 2
	local rm = t.Size.Middle / 2
	local prog = self:GetChargeProgress(true) * 360
	
	draw.NoTexture()
	surface.SetDrawColor(ColorAlpha(color_black, 192))
	ss:DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - ri, 90, 450 - prog, 5)
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss:DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - rm, 90, 450 - prog, 5)
	surface.SetDrawColor(self.Crosshair.color_hit)
	ss:DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - ri, 90 - prog, 90, 5)
	
	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairColor)
	ss:DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - rm)
end

local innerwidth = 2
function SWEP:DrawInnerCircle(t)
	local s = t.Size.Inner / 2
	draw.NoTexture()
	surface.SetDrawColor(self.Crosshair.color_nohit)
	ss:DrawArc(t.AimPos.x, t.AimPos.y, s + innerwidth, innerwidth)
end

function SWEP:DrawCenterDot(t) -- Center circle
	local s = t.Size.Dot / 2
	draw.NoTexture()
	surface.SetDrawColor(self.Crosshair.color_circle)
	ss:DrawArc(t.AimPos.x, t.AimPos.y, s + innerwidth)
	surface.SetDrawColor(self.Crosshair.color_nohit)
	ss:DrawArc(t.AimPos.x, t.AimPos.y, s)
	
	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss:DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s + innerwidth)
	surface.SetDrawColor(t.CrosshairColor)
	ss:DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s)
end

function SWEP:DrawCrosshair(x, y, t)
	if not self:GetChargeFlag() then return end
	t.CrosshairDarkColor = ColorAlpha(t.CrosshairColor, 192)
	t.CrosshairDarkColor.r, t.CrosshairDarkColor.g, t.CrosshairDarkColor.b
	= t.CrosshairDarkColor.r / 2, t.CrosshairDarkColor.g / 2, t.CrosshairDarkColor.b / 2
	self:DrawCenterDot(t)
	self:DrawInnerCircle(t)
	self:DrawOuterCircle(t)
	self:DrawHitCrossBG(t)
	self:DrawHitCross(t)
	return true
end
