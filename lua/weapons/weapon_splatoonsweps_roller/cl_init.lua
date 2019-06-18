
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

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
local PaintNearDistance = SWEP.Primary.PaintNearDistance or ss.mPaintNearDistance
local PaintFraction = 1 + PaintNearDistance / ss.mPaintFarDistance

local Pitch = Angle(1, 0, 0)
local InitLerpTime = 5 * ss.FrameToSec
local LerpSpeed = 360 -- degs/sec
local Width = 75
local function AdjustRollerAngles(self, tracelength, traceheight, tracewidth, tracedown, vm)
	local target = vm or self
	local bone = vm and self.VMBones.Root or self.Bones.Root
	local oldang = target:GetManipulateBoneAngles(bone)
	local ownerang = Angle(0, self:GetAimVector():Angle().yaw, 0)
	local up = vector_up * traceheight
	local down = -vector_up * tracedown
	local forward = ownerang:Forward() * tracelength
	local right = ownerang:Right() * tracewidth / 2
	local l = {
		start = self:GetPos() + up,
		endpos = self:GetPos() + up + forward + right,
		filter = {self.Owner, self},
	}
	local r = {
		start = self:GetPos() + up,
		endpos = self:GetPos() + up + forward - right,
		filter = {self.Owner, self},
	}
	local trleft = util.TraceLine(l)
	local trright = util.TraceLine(r)
	l = {
		start = trleft.HitPos,
		endpos = trleft.HitPos + down,
		filter = {self.Owner, self},
	}
	r = {
		start = trright.HitPos,
		endpos = trright.HitPos + down,
		filter = {self.Owner, self},
	}
	trleft = util.TraceLine(l)
	trright = util.TraceLine(r)
	target:ManipulateBoneAngles(bone, angle_zero)
	target:SetupBones()

	local hitpos = (trleft.HitPos + trright.HitPos) / 2
	local bonemat = target:GetBoneMatrix(bone)
	if not bonemat then return end
	local bonepos = bonemat:GetTranslation()
	local dzp = bonepos.z - hitpos.z
	local dp = math.deg(math.asin(dzp / hitpos:Distance(bonepos)))
	local dzr = trleft.HitPos.z - trright.HitPos.z
	local dr = math.deg(math.atan2(dzr, tracewidth))
	local ang = Angle(dp - 90, ownerang.yaw)
	local step = LerpSpeed * RealFrameTime()
	ang:RotateAroundAxis(ang:Up(), dr)
	ang = select(2, WorldToLocal(vector_origin, ang, vector_origin, bonemat:GetAngles()))
	ang.p = math.Approach(oldang.p, ang.p, step)
	ang.y = math.Approach(oldang.y, ang.y, step)
	ang.r = math.Approach(oldang.r, ang.r, step)
	target:ManipulateBoneAngles(bone, ang)
end

local function RotateRoll(self, vm)
	if not self.Owner:OnGround() then return end
	local target = vm or self
	local bone = vm and self.VMBones.Roll or self.Bones.Roll
	local oldpos = self.RotateRollPos or self.Owner:GetPos()
	local oldang = target:GetManipulateBoneAngles(bone)
	local forward = Angle(0, self:GetAimVector():Angle().yaw, 0):Forward()
	local diameter = self.Primary.Diameter or 15
	local diff = self.Owner:GetPos() - oldpos
	local amount = forward:Dot(diff)
	local p = oldang.p + math.deg(amount / diameter)
	target:ManipulateBoneAngles(bone, math.NormalizeAngle(p) * Pitch)
	self.RotateRollPos = self.Owner:GetPos()
end

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
SWEP.Crosshair = {
	color_circle = ColorAlpha(color_black, crosshairalpha),
	color_nohit = ColorAlpha(color_white, crosshairalpha),
	Dot = 7, HitLine = 50, HitWidth = 2, Inner = 35, -- in pixel
	Line = 8, LineWidth = 2, Middle = 44, Outer = 51, -- in pixel
	HitLineSize = 44,
}

function SWEP:PreViewModelDrawn(vm, weapon, ply)
	self.VMBones = self.VMBones or {
		Neck = vm:LookupBone "neck_1",
		Roll = vm:LookupBone "roll_root_1" or self:LookupBone "roll_1",
		Root = vm:LookupBone "root_1",
	}
	function vm.GetInkColorProxy()
		return ss.ProtectedCall(self.GetInkColorProxy, self) or ss.vector_one
	end

	if self:GetMode() ~= self.MODE.PAINT then
		vm:ManipulateBoneAngles(self.VMBones.Root, angle_zero)
		return
	end

	local ping = self:IsMine() and self:Ping() or 0
	if CurTime() + ping < self:GetEndTime() then return end
	local h = self.Owner:OBBMaxs().z
	AdjustRollerAngles(self, 40, h / 2, Width, h * 2, vm)
	RotateRoll(self, vm)
end

function SWEP:PreDrawWorldModel(vm, weapon, ply)
	self.Bones = self.Bones or {
		Neck = self:LookupBone "neck_1",
		Roll = self:LookupBone "roll_root_1" or self:LookupBone "roll_1",
		Root = self:LookupBone "root_1",
	}

	-- Animate the neck
	local mode = self:GetMode()
	local ct = CurTime() + (self:IsMine() and self:Ping() or 0)
	local neck, start, duration, n1, n2 = 0, self:GetStartTime()
	if mode ~= self.MODE.PAINT then
		if mode == self.MODE.READY then
			duration = self.CollapseRollTime
			n1, n2 = 0, -90
		elseif mode == self.MODE.ATTACK then
			duration = self.PreSwingTime
			n1, n2 = -90, 0
		end

		local f = math.TimeFraction(start, start + duration, ct)
		neck = Lerp(math.EaseInOut(math.Clamp(f, 0, 1), .25, .25), n1, n2)
		self:ManipulateBoneAngles(self.Bones.Root, angle_zero)
	elseif ct > self:GetEndTime() then -- Adjust the angle
		local h = self.Owner:OBBMaxs().z
		AdjustRollerAngles(self, 75, h, Width, h * 3)
		RotateRoll(self)
	end

	self:ManipulateBoneAngles(self.Bones.Neck, Angle(0, 0, neck))
end

function SWEP:GetMuzzlePosition()
	local ent = self:IsTPS() and self or self:GetViewModel()
	local a = ent:GetAttachment(ent:LookupAttachment "roll")
	return a.Pos, a.Ang
end

function SWEP:GetCrosshairTrace(t)
	local range = self:GetRange(true)
	local tr = ss.SquidTrace
	tr.start, tr.endpos = t.pos, t.pos + t.dir * range
	tr.filter = {self, self.Owner}
	tr.maxs = ss.vector_one * self.Primary.ColRadius
	tr.mins = -tr.maxs

	t.Trace = util.TraceHull(tr)
	t.EndPosScreen = (self:GetShootPos() + self:GetAimVector() * range):ToScreen()
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
	spreadx = math.max(spreadx, spready) -- Stupid workaround for Blasters' crosshair
	local frac = t.Trace.Fraction
	local basecolor = t.IsSplatoon2 and t.Trace.Hit and self.Crosshair.color_nohit or color_white
	local pos, dir = t.pos, t.dir
	local w = t.Size.FourLine
	local h = t.Size.FourLineWidth
	local pitch = EyeAngles():Right()
	local yaw = pitch:Cross(dir)
	if t.IsSplatoon2 then
		frac = 1
		if t.Trace.Hit then
			dir = self:GetAimVector()
			pos = self:GetShootPos()
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
		surface.SetDrawColor(ss.GetColor(self:GetNWInt "inkcolor"))
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
		Color = ss.GetColor(self:GetNWInt "inkcolor")
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

local SwayTime = 12 * ss.FrameToSec
local LeftHandAlt = {2, 1, 4, 3, 5, 6}
function SWEP:GetViewModelPosition(pos, ang)
	local vm = self:GetViewModel()
	if not IsValid(vm) then return pos, ang end

	local ping = IsFirstTimePredicted() and self:Ping() or 0
	local ct = CurTime() - ping
	if not self.OldPos then
		self.ArmPos, self.ArmBegin = 1, ct
		self.BasePos, self.BaseAng = Vector(), Angle()
		self.OldPos, self.OldAng = self.BasePos, self.BaseAng
		return pos, ang
	end

	local armpos = self.OldArmPos
	if self:IsFirstTimePredicted() then
		self.OldArmPos = ss.GetOption "doomstyle" and 5 or 1
	end

	if self:GetNWBool "lefthand" then armpos = LeftHandAlt[armpos] or armpos end
	if not isangle(self.IronSightsAng[armpos]) then return pos, ang end
	if not isvector(self.IronSightsPos[armpos]) then return pos, ang end

	local DesiredFlip = self.IronSightsFlip[armpos]
	local relpos, relang = LocalToWorld(vector_origin, angle_zero, pos, ang)
	local SwayTime = self.SwayTime / ss.GetTimeScale(self.Owner)
	if self:IsFirstTimePredicted() and armpos ~= self.ArmPos then
		self.ArmPos, self.ArmBegin = armpos, ct
		self.BasePos, self.BaseAng = self.OldPos, self.OldAng
		self.TransitFlip = self.ViewModelFlip ~= DesiredFlip
	else
		armpos = self.ArmPos
	end

	local dt = ct - self.ArmBegin
	local f = math.Clamp(dt / SwayTime, 0, 1)
	if self.TransitFlip then
		f, armpos = f * 2, 5
		if self:IsFirstTimePredicted() and f >= 1 then
			f, self.ArmPos = 1, 5
			self.ViewModelFlip = DesiredFlip
			self.ViewModelFlip1 = DesiredFlip
			self.ViewModelFlip2 = DesiredFlip
		end
	end

	local pos = LerpVector(f, self.BasePos, self.IronSightsPos[armpos])
	local ang = LerpAngle(f, self.BaseAng, self.IronSightsAng[armpos])
	if self:IsFirstTimePredicted() then
		self.OldPos, self.OldAng = pos, ang
	end

	return LocalToWorld(self.OldPos, self.OldAng, relpos, relang)
end

function SWEP:SetupDrawCrosshair()
	do return end
	local t = {Size = {}}
	t.CrosshairColor = ss.GetColor(ss.CrosshairColors[self:GetNWInt "inkcolor"])
	t.pos, t.dir = self:GetFirePosition(true)
	t.IsSplatoon2 = ss.GetOption "newstylecrosshair"
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
	do return end
	self:DrawFourLines(t, self:GetSpreadAmount())
	self:DrawHitCrossBG(t)
	self:DrawOuterCircle(t)
	self:DrawHitCross(t)
	self:DrawInnerCircle(t)
	self:DrawCenterDot(t)

	return true
end
