
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
local FireWeaponCooldown = 6 * ss.FrameToSec
local FireWeaponMultiplier = 1
local function ExpandModel(self, vm, weapon, ply)
	local fraction = FireWeaponCooldown - SysTime() + self.ModifyWeaponSize
	fraction = math.max(1, fraction * FireWeaponMultiplier + 1)
	local s = ss.vector_one * fraction
	self:ManipulateBoneScale(self:LookupBone "root_1" or 0, s)
	if not IsValid(vm) then return end
	if self.ViewModelFlip then s.y = -s.y end
	vm:ManipulateBoneScale(vm:LookupBone "root_1" or 0, s)
	function vm.GetInkColorProxy()
		return ss.ProtectedCall(self.GetInkColorProxy, self) or ss.vector_one
	end
end

SWEP.PreViewModelDrawn = ExpandModel
SWEP.PreDrawWorldModel = ExpandModel
SWEP.SwayTime = 12 * ss.FrameToSec
SWEP.IronSightsAng = {
	Angle(), -- right
	Angle(), -- left
	Angle(0, 0, -60), -- top-right
	Angle(0, 0, -60), -- top-left
	Angle(), -- center
}
SWEP.IronSightsPos = {
	Vector(), -- right
	Vector(), -- left
	Vector(), -- top-right
	Vector(), -- top-left
	Vector(0, 6, -2), -- center
}
SWEP.IronSightsFlip = {
	false,
	true,
	false,
	true,
	false,
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
	self.ArmPos, self.ArmBegin = nil, nil
	self.BasePos, self.BaseAng = nil, nil
	self.OldPos, self.OldAng = nil, nil
	self.TransitFlip = false
	self.ModifyWeaponSize = SysTime() - 1
	self.ViewPunch = Angle()
	self.ViewPunchVel = Angle()
	if not (self.ADSAngOffset and self.ADSOffset) then return end
	self.IronSightsAng[6] = self.IronSightsAng[5] + self.ADSAngOffset
	self.IronSightsPos[6] = self.IronSightsPos[5] + self.ADSOffset
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
	t.EndPosScreen = (self.Owner:GetShootPos() + self.Owner:GetAimVector() * self:GetRange()):ToScreen()
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
		frac, lx, ly = 1, self.Cursor.x, self.Cursor.y
		if t.Trace.Hit then
			dir = self.Owner:GetAimVector()
			pos = self.Owner:GetShootPos()
		end
	end
	
	local linesize = t.Size.Outer * (1.5 - frac)
	for i = 1, 4 do
		local rot = dir:Angle()
		local sgnx, sgny = i > 2 and 1 or -1, bit.band(i, 3) > 1 and 1 or -1
		rot:RotateAroundAxis(yaw, spreadx * sgnx)
		rot:RotateAroundAxis(pitch, spready * sgny)
		
		local endpos = pos + rot:Forward() * self:GetRange() * frac
		local hit = endpos:ToScreen()
		if not hit.visible then continue end
		hit.x = hit.x - linesize * sgnx * (t.HitEntity and .75 or 1)
		hit.y = hit.y - linesize * sgny * (t.HitEntity and .75 or 1)
		surface.SetDrawColor(basecolor)
		surface.SetMaterial(ss.Materials.Crosshair.Line)
		surface.DrawTexturedRectRotated(hit.x, hit.y, w, h, 90 * i - 45)
		
		if not t.HitEntity then continue end
		surface.SetDrawColor(ss.GetColor(self:GetNWInt "ColorCode"))
		surface.SetMaterial(ss.Materials.Crosshair.LineColor)
		surface.DrawTexturedRectRotated(hit.x, hit.y, w, h, 90 * i - 45)
	end
end

function SWEP:DrawHitCrossBG(t) -- Hit cross pattern, background
	if not t.HitEntity then return end
	surface.SetMaterial(ss.Materials.Crosshair.Line)
	surface.SetDrawColor(color_black)
	local mul = ss.ProtectedCall(self.GetScopedSize, self) or 1
	local s = t.Size.Inner / 2 * mul
	local lp = s + math.max(PaintFraction - (t.Distance
	/ ss.mPaintFarDistance)^.125, 0) * t.Size.ExpandHitLine -- Line position
	local w, h = t.Size.HitLine * mul + hitcrossbg, t.Size.HitWidth * mul + hitcrossbg
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
	ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, r, r - ri)
end

function SWEP:DrawHitCross(t) -- Hit cross pattern, foreground
	if not t.HitEntity then return end
	local mul = ss.ProtectedCall(self.GetScopedSize, self) or 1
	local s = t.Size.Inner / 2 * mul
	local w, h = t.Size.HitLine * mul, t.Size.HitWidth * mul
	local lp = s + math.max(PaintFraction - (t.Distance
	/ ss.mPaintFarDistance)^.125, 0) * t.Size.ExpandHitLine -- Line position
	for mat, col in pairs {
		[""] = color_white,
		Color = ss.GetColor(self:GetNWInt "ColorCode")
	} do
		surface.SetMaterial(ss.Materials.Crosshair["Line" .. mat])
		surface.SetDrawColor(col)
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
	ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s, thickness)
end

function SWEP:DrawCenterDot(t) -- Center circle
	local s = t.Size.Dot / 2
	draw.NoTexture()
	surface.SetDrawColor(color_white)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s)
	
	if not (t.IsSplatoon2 and t.Trace.Hit) then return end
	surface.SetDrawColor(self.Crosshair.color_nohit)
	ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s)
end

function SWEP:GetArmPos()
	if self:GetADS() then
		self.IronSightsFlip[6] = self.ViewModelFlip
		return 6
	end
end

local SwayTime = 12 * ss.FrameToSec
local SouthpawAlt = {2, 1, 4, 3, 5, 6}
function SWEP:GetViewModelPosition(pos, ang)
	if not IsValid(self.Owner) then return pos, ang end
	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return pos, ang end
	if not self.OldPos then
		self.ArmPos, self.ArmBegin = 1, SysTime()
		self.BasePos, self.BaseAng = Vector(), Angle()
		self.OldPos, self.OldAng = self.BasePos, self.BaseAng
		return pos, ang
	end
	
	local armpos = ss.ProtectedCall(self.GetArmPos, self)
	if self:GetThrowing() then
		armpos = 1
	elseif not armpos then
		if ss.GetOption "DoomStyle" then
			armpos = 5
		elseif ss.GetOption "MoveViewmodel" and not self:Crouching() then
			if not self.Cursor then return pos, ang end
			local x, y = self.Cursor.x, self.Cursor.y
			armpos = select(3, self:GetFirePosition())
		else
			armpos = 1
		end
	end
	
	if self:GetNWBool "Southpaw" then
		armpos = SouthpawAlt[armpos] or armpos
	end
	
	if not isangle(self.IronSightsAng[armpos]) then return pos, ang end
	if not isvector(self.IronSightsPos[armpos]) then return pos, ang end
	
	local DesiredFlip = self.IronSightsFlip[armpos]
	if armpos ~= self.ArmPos then
		self.ArmPos, self.ArmBegin = armpos, SysTime()
		self.BasePos, self.BaseAng = self.OldPos, self.OldAng
		self.TransitFlip = self.ViewModelFlip ~= DesiredFlip
	end
	
	local relpos, relang = LocalToWorld(vector_origin, angle_zero, pos, ang)
	local SwayTime = self.SwayTime / ss.GetTimeScale(self.Owner)
	local f = math.Clamp((SysTime() - self.ArmBegin) / SwayTime, 0, 1)
	if self.TransitFlip then
		if f > .5 then
			f, self.ArmPos = .5, 5
			self.ViewModelFlip = DesiredFlip
		end
		
		f, armpos = f * 2, 5
	end
	
	self.OldPos = LerpVector(f, self.BasePos, self.IronSightsPos[armpos])
	self.OldAng = LerpAngle(f, self.BaseAng, self.IronSightsAng[armpos])
	
	return LocalToWorld(self.OldPos, self.OldAng, relpos, relang)
end

function SWEP:SetupDrawCrosshair()
	local t = {Size = {}}
	t.CrosshairColor = ss.GetColor(ss.CrosshairColors[self:GetNWInt "ColorCode"])
	t.pos, t.dir = self:GetFirePosition()
	t.IsSplatoon2 = ss.GetOption "NewStyleCrosshair"
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
	self:DrawFourLines(t, self:GetSpreadAmount())
	self:DrawHitCrossBG(t)
	self:DrawOuterCircle(t)
	self:DrawHitCross(t)
	self:DrawInnerCircle(t)
	self:DrawCenterDot(t)
	
	return true
end
