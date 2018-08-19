
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

-- Custom functions executed before weapon model is drawn.
--   model | Weapon model(Clientside Entity)
--   bone_ent | Owner entity
--   pos, ang | Position and angle of weapon model
--   v | Viewmodel/Worldmodel element table
--   matrix | VMatrix for scaling
-- When the weapon is fired, it slightly expands.  This is maximum time to get back to normal size.
local FireWeaponCooldown = .1
local FireWeaponMultiplier = 1
local function ExpandModel(self, vm)
	local fraction = FireWeaponCooldown - SysTime() + self.ModifyWeaponSize
	fraction = math.max(1, fraction * FireWeaponMultiplier + 1)
	local s = ss.vector_one * fraction
	self:ManipulateBoneScale(0, s)
	if not IsValid(vm) then return end
	vm:ManipulateBoneScale(vm:LookupBone "root_1", s)
	function vm.GetInkColorProxy() return self:GetInkColorProxy() end
end

SWEP.PreViewModelDrawn = ExpandModel
SWEP.PreDrawWorldModel = ExpandModel
SWEP.IronSightsAng = {
	Vector(), -- normal
	Vector(0, 0, 0), -- left
	Vector(0, 0, -60), -- top-right
	Vector(0, 0, 60), -- top-left
	Vector(0, 0, 0), -- center
}
SWEP.IronSightsPos = {
	Vector(), -- normal
	Vector(-12), -- left
	Vector(), -- top-right
	Vector(-12), -- top-left
	Vector(-6, 0, -2), -- center
}

local crosshairalpha = 64
local texdotsize = 32 / 4
local texringsize = 128 / 2
local texlinesize = 128 / 2
local texlinewidth = 8 / 2
local hitcrossbg = 4 -- in pixel
local hitouterbg = 3 -- in pixel
local originalres = 1920 * 1080
local hitline, hitwidth = 50, 3
local line, linewidth = 16, 3
local PaintFraction = 1 + ss.mPaintNearDistance / ss.mPaintFarDistance
SWEP.Crosshair = {
	color_circle = ColorAlpha(color_black, crosshairalpha),
	color_nohit = ColorAlpha(color_white, crosshairalpha),
	Dot = 7, HitLine = 50, HitWidth = 2, Inner = 35, -- in pixel
	Line = 8, LineWidth = 2, Middle = 44, Outer = 51, -- in pixel
	HitLineSize = 44,
}

function SWEP:ClientInit()
	self.oldpos = Vector()
	self.p, self.y, self.r = 0, 0, 0
	self.ModifyWeaponSize = SysTime() - 1
	self.ViewPunch = Angle()
	self.ViewPunchVel = Angle()
end

function SWEP:GetMuzzlePosition()
	local ent = self:IsTPS() and self or self.Owner:GetViewModel()
	local a = ent:GetAttachment(ent:LookupAttachment "muzzle")
	return a.Pos, a.Ang
end

function SWEP:GetCrosshairTrace(t)
	local tr = ss.SquidTrace
	tr.start, tr.endpos = t.pos, t.pos + t.dir * self:GetRange()
	tr.filter = {self, self.Owner}
	tr.maxs = ss.vector_one * self.Primary.ColRadius
	tr.mins = -tr.maxs
	
	t.Trace = util.TraceHull(tr)
	t.HitPosScreen = t.Trace.HitPos:ToScreen()
	t.HitEntity = IsValid(t.Trace.Entity) and t.Trace.Entity:Health() > 0
	t.Distance = t.Trace.HitPos:Distance(t.pos)
	if t.HitEntity then
		local w = ss.IsValidInkling(t.Trace.Entity)
		if w and ss.IsAlly(w, self) then
			t.HitEntity = false
		end
	end
end

function SWEP:DrawFourLines(t, spreadx, spready)
	local frac = t.Trace.Fraction
	local basecolor = t.IsSplatoon2 and t.Trace.Hit and self.Crosshair.color_nohit or color_white
	local pos, dir = t.pos, t.dir
	local lx, ly = t.HitPosScreen.x, t.HitPosScreen.y
	local w = t.Size.FourLine
	local h = t.Size.FourLineWidth
	local pitch = EyeAngles():Right()
	local yaw = pitch:Cross(dir)
	if t.IsSplatoon2 then
		frac, lx, ly = 1, t.AimPos.x, t.AimPos.y
		if t.Trace.Hit then
			dir = self.Owner:GetAimVector()
			pos = self.Owner:GetShootPos()
		end
	end
	
	local linesize = t.Size.Outer * (1.5 - frac)
	for i = 1, 4 do
		local rot = dir:Angle()
		local mx, my = i > 2 and 1 or -1, bit.band(i, 3) > 1 and 1 or -1
		rot:RotateAroundAxis(yaw, spreadx * mx)
		rot:RotateAroundAxis(pitch, spready * my)
		
		local endpos = pos + rot:Forward() * self:GetRange() * frac
		local hit = endpos:ToScreen()
		if not hit.visible then continue end
		hit.x = hit.x - linesize * mx * (t.HitEntity and .75 or 1)
		hit.y = hit.y - linesize * my * (t.HitEntity and .75 or 1)
		surface.SetDrawColor(basecolor)
		surface.SetMaterial(ss.Materials.Crosshair.Line)
		surface.DrawTexturedRectRotated(hit.x, hit.y, w, h, 90 * i - 45)
		
		if not t.HitEntity then continue end
		surface.SetDrawColor(self.Color)
		surface.SetMaterial(ss.Materials.Crosshair.LineColor)
		surface.DrawTexturedRectRotated(hit.x, hit.y, w, h, 90 * i - 45)
	end
end

function SWEP:DrawHitCrossBG(t) -- Hit cross pattern, background
	if not t.HitEntity then return end
	surface.SetMaterial(ss.Materials.Crosshair.Line)
	surface.SetDrawColor(color_black)
	local s = t.Size.Inner / 2
	local lp = s + math.max(PaintFraction - (t.Distance / ss.mPaintFarDistance)^.125, 0) * t.Size.ExpandHitLine -- line position
	local w, h = t.Size.HitLine + hitcrossbg, t.Size.HitWidth + hitcrossbg
	for i = 1, 4 do
		local dx, dy = lp * (i > 2 and 1 or -1), lp * (bit.band(i, 3) > 1 and 1 or -1)
		surface.DrawTexturedRectRotated(t.HitPosScreen.x + dx, t.HitPosScreen.y + dy, w, h, 90 * i + 45)
	end
end

function SWEP:DrawOuterCircle(t)
	local r = t.Size.Outer / 2
	local ri = t.Size.Inner / 2
	
	draw.NoTexture()
	if t.HitEntity then
		local rb = r + hitouterbg
		surface.SetDrawColor(color_black)
		ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, rb, rb - ri)
	end
	
	surface.SetDrawColor(t.Trace.Hit and t.CrosshairColor or self.Crosshair.color_circle)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r, r - ri)
	
	if not (t.IsSplatoon2 and t.Trace.Hit) then return end
	surface.SetDrawColor(self.Crosshair.color_circle)
	ss.DrawArc(t.AimPos.x, t.AimPos.y, r, r - ri)
end

function SWEP:DrawHitCross(t) -- Hit cross pattern, foreground
	if not t.HitEntity then return end
	local s = t.Size.Inner / 2
	local lp = s + math.max(PaintFraction - (t.Distance / ss.mPaintFarDistance)^.125, 0) * t.Size.ExpandHitLine -- line position
	for mat, col in pairs {[""] = color_white, Color = self.Color} do
		surface.SetMaterial(ss.Materials.Crosshair["Line" .. mat])
		surface.SetDrawColor(col)
		local w, h = t.Size.HitLine, t.Size.HitWidth
		for i = 1, 4 do
			local dx, dy = lp * (i > 2 and 1 or -1), lp * (bit.band(i, 3) > 1 and 1 or -1)
			surface.DrawTexturedRectRotated(t.HitPosScreen.x + dx, t.HitPosScreen.y + dy, w, h, 90 * i + 45)
		end
	end
end

function SWEP:DrawInnerCircle(t)
	local s = t.Size.Middle / 2
	local thickness = s - t.Size.Inner / 2 - 1
	draw.NoTexture()
	surface.SetDrawColor(t.Trace.Hit and color_white or self.Crosshair.color_nohit)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s, thickness)
	
	if not (t.IsSplatoon2 and t.Trace.Hit) then return end
	surface.SetDrawColor(self.Crosshair.color_nohit)
	ss.DrawArc(t.AimPos.x, t.AimPos.y, s, thickness)
end

function SWEP:DrawCenterDot(t) -- Center circle
	local s = t.Size.Dot / 2
	draw.NoTexture()
	surface.SetDrawColor(color_white)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s)
	
	if not (t.IsSplatoon2 and t.Trace.Hit) then return end
	surface.SetDrawColor(self.Crosshair.color_nohit)
	ss.DrawArc(t.AimPos.x, t.AimPos.y, s)
end

local swayspeed = .05
function SWEP:GetViewModelPosition(pos, ang)
	if not IsValid(self.Owner) then return pos, ang end
	
	local armpos = 1
	local ads = GetConVar "cl_splatoonsweps_doomstyle"
	if ads and ads:GetBool() then
		local da = self.IronSightsAng[5] or Vector() -- center
		ang:RotateAroundAxis(ang:Right(), da.x) -- pitch
		ang:RotateAroundAxis(ang:Up(), da.y) -- yaw
		ang:RotateAroundAxis(ang:Forward(), da.z) -- roll
		local dp = self.IronSightsPos[5] or Vector()
		return pos + dp.x * ang:Right() + dp.y * ang:Forward() + dp.z * ang:Up(), ang
	elseif ss.GetConVarBool "MoveViewmodel" and not self:Crouching() then
		local x, y = ScrW() / 2, ScrH() / 2
		if vgui.CursorVisible() then x, y = input.GetCursorPos() end
		armpos = select(3, self:GetFirePosition(self:GetRange() * gui.ScreenToVector(x, y), RenderAngles(), EyePos()))
	end
	
	if not self.IronSightsAng[armpos] then return pos, ang end
	local iang = self.IronSightsAng[armpos] or Vector()
	self.p = self.p + (iang.x - self.p) * swayspeed
	self.y = self.y + (iang.y - self.y) * swayspeed
	self.r = self.r + (iang.z - self.r) * swayspeed
	
	local da = Angle(ang)
	da:RotateAroundAxis(da:Right(), self.p)
	da:RotateAroundAxis(da:Up(), self.y)
	da:RotateAroundAxis(da:Forward(), self.r)
	
	local ipos = self.IronSightsPos[armpos] or Vector()
	local dpos = ipos.x * da:Right() + ipos.y * da:Forward() + ipos.z * da:Up()
	self.oldpos = self.oldpos + (dpos - self.oldpos) * swayspeed
	
	return pos + self.oldpos, da
end

function SWEP:SetupDrawCrosshair()
	local t = {Size = {}}
	t.CrosshairColor = ss.GetColor(ss.CrosshairColors[self.ColorCode])
	t.AimPos = (self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.Primary.Range):ToScreen()
	t.pos, t.dir = self:GetFirePosition()
	t.IsSplatoon2 = ss.GetConVarBool "NewStyleCrosshair"
	local res = math.sqrt(ScrW() * ScrH() / originalres)
	for param, size in pairs {
		Dot = self.Crosshair.Dot,
		ExpandHitLine = self.Crosshair.HitLineSize,
		Inner = self.Crosshair.Inner,
		Middle = self.Crosshair.Middle,
		Outer = self.Crosshair.Outer,
	} do
		t.Size[param] = math.ceil(size * res)
	end
	
	for param, size in pairs {
		HitLine = {texlinesize, self.Crosshair.HitLine, hitline},
		HitWidth = {texlinewidth, self.Crosshair.HitWidth, hitwidth},
		FourLine = {texlinesize, self.Crosshair.Line, line},
		FourLineWidth = {texlinewidth, self.Crosshair.LineWidth, linewidth},
	} do
		t.Size[param] = math.ceil(size[1] * res * size[2] / size[3])
	end
	
	self:GetCrosshairTrace(t)
	return t
end

function SWEP:DrawCrosshair(x, y, t)
	self:DrawFourLines(t, Lerp(self.Owner:GetVelocity().z * ss.SpreadJumpFraction, self.Primary.Spread, self.Primary.SpreadJump), ss.mDegRandomY)
	self:DrawHitCrossBG(t)
	self:DrawOuterCircle(t)
	self:DrawHitCross(t)
	self:DrawInnerCircle(t)
	self:DrawCenterDot(t)
	
	return true
end
