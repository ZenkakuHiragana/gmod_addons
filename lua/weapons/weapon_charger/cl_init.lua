
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
	self.IronSightsPos[6] = self.Primary.Scope.Pos
	self.IronSightsAng[6] = self.Primary.Scope.Ang
	self.IronSightsFlip[6] = false
	self.BaseClass.BaseClass.ClientInit(self)
end

function SWEP:DisplayAmmo()
	if self:GetCharge() == math.huge then return 0 end
	return math.max(self:GetChargeProgress(true) * 100, 0)
end

local FOV = GetConVar "fov_desired"
function SWEP:GetScopedSize()
	return 1 + self:GetScopedProgress(true)
end

function SWEP:ClientPrimaryAttack() end
function SWEP:DrawFourLines(t) end
function SWEP:DrawOuterCircle(t)
	local scoped = self:GetScopedSize()
	local r = t.Size.Outer / 2 * scoped
	local ri = t.Size.Inner / 2 * scoped
	local rm = t.Size.Middle / 2 * scoped
	local prog = self:GetChargeProgress(true) * 360
	
	draw.NoTexture()
	surface.SetDrawColor(ColorAlpha(color_black, 192))
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - ri, 90, 450 - prog, 5)
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - rm, 90, 450 - prog, 5)
	surface.SetDrawColor(self.Crosshair.color_hit)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - ri, 90 - prog, 90, 5)
	
	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - rm)
end

local innerwidth = 2
function SWEP:DrawInnerCircle(t)
	local scoped = self:GetScopedSize()
	local s = t.Size.Inner / 2 * scoped
	if scoped == 2 and t.Trace.Hit then return end
	draw.NoTexture()
	surface.SetDrawColor(self.Crosshair.color_nohit)
	ss.DrawArc(t.AimPos.x, t.AimPos.y, s + innerwidth, innerwidth)
end

function SWEP:DrawCenterDot(t) -- Center circle
	local scoped = self:GetScopedSize()
	local s = t.Size.Dot / 2 * scoped
	if scoped < 2 then
		draw.NoTexture()
		surface.SetDrawColor(self.Crosshair.color_circle)
		ss.DrawArc(t.AimPos.x, t.AimPos.y, s + innerwidth)
		surface.SetDrawColor(self.Crosshair.color_nohit)
		ss.DrawArc(t.AimPos.x, t.AimPos.y, s)
	end
	
	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s + innerwidth)
	surface.SetDrawColor(t.CrosshairColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s)
end

function SWEP:DrawCrosshair(x, y, t)
	if self:GetCharge() == math.huge then return end
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

function SWEP:PreViewModelDrawn(vm, weapon, ply)
	render.SetBlend((1 - self:GetScopedProgress(true))^2)
end

function SWEP:PostDrawViewModel(vm, weapon, ply)
	if not self.Scoped then return end
	render.SetBlend(1)
end

function SWEP:GetArmPos()
	if not self.Scoped then return end
	if self.Owner:KeyDown(IN_USE) then return 6 end
	local prog = self:GetChargeProgress(true)
	local scope = self.Primary.Scope
	local timescale = ss.GetTimeScale(self.Owner)
	local SwayTime = self.SwayTime / timescale
	self.SwayTime = 12 * ss.FrameToSec
	if prog > scope.StartMove then
		self.IronSightsFlip[6] = self.ViewModelFlip
		self.SwayTime = scope.SwayTime / 2
		local mul = self.Primary.EmptyChargeMul
		local f = (SysTime() - self.ArmBegin) / SwayTime
		if not self.Owner:OnGround() or self:GetInk() < prog * self.Primary.TakeAmmo then
			self.SwayTime = scope.SwayTime * mul
		end
		
		self.ArmBegin = SysTime() - f * self.SwayTime / timescale
		return 6
	end
end

local MatScope = Material "gmod/scope"
local MatRefScope = Material "gmod/scope-refract"
local DebugRefract = Material "dev/reflectivity_10"
local DebugRefDefault = DebugRefract:GetFloat "$refractamount"
local MatRefDefault = MatRefScope:GetFloat "$refractamount"
function SWEP:RenderScreenspaceEffects()
	if not self.Scoped then return end
	local prog = self:GetScopedProgress(true)
	if prog == 0 then return end
	
	MatRefScope:SetFloat("$refractamount", prog * prog * MatRefDefault)
	local sy = math.min(ScrW(), ScrH())
	local sx = sy * 4 / 3
	local x, y = math.max(0, (ScrW() - sx)) / 2, math.max(0, (ScrH() - sy)) / 2
	local rest = sx * x / sy * 6
	surface.SetDrawColor(ColorAlpha(color_black, prog * 255))
	surface.SetMaterial(MatRefScope)
	surface.DrawTexturedRect(x, y, sx, sy)
	surface.DrawTexturedRect(x - rest, 0, rest, ScrH())
	surface.DrawTexturedRect(x + sx, 0, rest, ScrH())
	surface.SetMaterial(MatScope)
	surface.DrawTexturedRect(x, y, sx, sy)
	surface.DrawTexturedRect(x - rest, 0, rest, ScrH())
	surface.DrawTexturedRect(x + sx, 0, rest, ScrH())
	MatRefScope:SetFloat("$refractamount", MatRefDefault)
end

function SWEP:CustomCalcView(ply, pos, ang, fov)
	if not (self.Scoped and self:IsTPS() and self:IsMine()) then return end
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
	if self:IsMine() and self:GetScopedProgress() == 1 then render.SetBlend(0) end
	
	local b = {ply:LookupBone "ValveBiped.Bip01_L_Forearm"}
	local bp, ba = {}, {}
	while #b > 0 do
		local m = ply:GetBoneMatrix(b[1])
		local pi = ply:GetBoneParent(b[1])
		local pm = ply:GetBoneMatrix(pi)
		bp[b[1]], ba[b[1]] = WorldToLocal(m:GetTranslation(), m:GetAngles(), pm:GetTranslation(), pm:GetAngles())
		for i, c in ipairs(ply:GetChildBones(b[1])) do
			table.insert(b, c)
		end
		table.remove(b, 1)
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
			table.insert(b, c)
		end
		table.remove(b, 1)
	end
end
