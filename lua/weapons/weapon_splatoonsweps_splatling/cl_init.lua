
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

local crosshairalpha = 64
local originalres = 1920 * 1080
local hitline, hitwidth = 50, 3
local line, linewidth = 16, 3
local texlinesize = 128 / 2
local texlinewidth = 8 / 2
SWEP.Crosshair = {
	color_circle = ColorAlpha(color_black, crosshairalpha),
	color_nohit = ColorAlpha(color_white, crosshairalpha),
	color_hit = ColorAlpha(color_white, 192),
	Dot = 5, HitLine = 20, HitWidth = 2, -- in pixel
	Inside1 = 40, Inside2 = 46, Outside1 = 56, Outside2 = 64,
	InsideColored = 60, OutsideColored = 70,
	InsideCenter = 44, OutsideCenter = 52,
	HitLineSize = 114,
}

local function Spin(self, vm, weapon, ply)
	if self:GetCharge() < math.huge or self:GetFireInk() > 0 then
		local sgn = self:GetNWBool "lefthand" and 1 or -1
		local prog = self:GetFireInk() > 0 and self:GetFireAt() or self:GetChargeProgress(true)
		local b = self:LookupBone "rotate_1" or 0
		local a = self:GetManipulateBoneAngles(b)
		local dy = RealFrameTime() * 60 / self.Parameters.mRepeatFrame * (prog + .1)
		a.y = a.y + sgn * dy
		self:ManipulateBoneAngles(b, a)
		if not IsValid(vm) then return end
		local b = vm:LookupBone "rotate_1" or 0
		local a = vm:GetManipulateBoneAngles(b)
		a.y = a.y + sgn * dy
		vm:ManipulateBoneAngles(b, a)
	end

	if not IsValid(vm) then return end
	function vm.GetInkColorProxy()
		return ss.ProtectedCall(self.GetInkColorProxy, self) or ss.vector_one
	end
end

SWEP.PreViewModelDrawn = Spin
SWEP.PreDrawWorldModel = Spin

function SWEP:ClientInit()
	self.CrosshairFlashTime = CurTime()
	self.MinChargeDeg = self.Parameters.mMinChargeFrame / self.Parameters.mFirstPeriodMaxChargeFrame * 360
	self:GetBase().ClientInit(self)
	self:AddSchedule(0, function()
		local e = EffectData()
		local prog = self:GetChargeProgress()
		e:SetEntity(self)
		if prog == 1 and self.FullChargeFlag then
			self.FullChargeFlag = false
			self.CrosshairFlashTime = CurTime() - self:Ping()
			if self:IsMine() then self:EmitSound(ss.ChargerBeep, 75, 115) end
		elseif self.MediumCharge < prog and prog < 1 and not self.FullChargeFlag then
			self.FullChargeFlag = true
			self.CrosshairFlashTime = CurTime() - .1 - self:Ping()
			if self:IsMine() then self:EmitSound(ss.ChargerBeep) end
		end

		if not self:IsFirstTimePredicted() then return end
		local prog_predicted = self:GetChargeProgress(self:IsMine())
		if prog_predicted == 1 then
			if self.FullChargeFlagPredicted then
				e:SetScale(30)
				e:SetFlags(0)
				util.Effect("SplatoonSWEPsSplatlingSpinup", e)
				self.FullChargeFlagPredicted = false
			elseif CurTime() > self.SpinupEffectTime then
				self.SpinupEffectTime = CurTime() + .2
				e:SetScale(9)
				e:SetFlags(1)
				util.Effect("SplatoonSWEPsSplatlingSpinup", e)
			end
		elseif self.MediumCharge < prog_predicted and prog_predicted < 1 then
			if self.FullChargeFlagPredicted then return end
			e:SetScale(17.5)
			e:SetFlags(0)
			util.Effect("SplatoonSWEPsSplatlingSpinup", e)
			self.FullChargeFlagPredicted = true
		end
	end)
end

function SWEP:GetArmPos()
	return (self:GetADS() or ss.GetOption "doomstyle") and 5 or 1
end

function SWEP:DisplayAmmo()
	if self:GetCharge() == math.huge then return 0 end
	return math.max(self:GetChargeProgress(true) * 100, 0)
end

function SWEP:DrawFourLines(t, spreadx, spready)
	local frac = t.Trace.Fraction
	local basecolor = color_white
	local pos, dir = t.pos, t.dir
	local w = t.Size.FourLine
	local h = t.Size.FourLineWidth
	local range = self:GetRange()
	local pitch = EyeAngles():Right()
	local yaw = pitch:Cross(dir)
	if t.IsSplatoon2 then
		frac, range = 1, self.Range
		dir = self:GetAimVector()
		pos = self:GetShootPos()
		if t.Trace.Hit then
			basecolor = self.Crosshair.color_nohit
		end
	end

	local linesize = t.Size.OutsideColored * (1.5 - frac)
	for i = 1, 4 do
		local rot = dir:Angle()
		local sgnx, sgny = i > 2 and 1 or -1, bit.band(i, 3) > 1 and 1 or -1
		rot:RotateAroundAxis(yaw, spreadx * sgnx)
		rot:RotateAroundAxis(pitch, spready * sgny)

		local endpos = pos + rot:Forward() * range * frac
		local hit = endpos:ToScreen()
		if hit.visible then
			hit.x = hit.x - linesize * sgnx * (t.HitEntity and .8 or 1)
			hit.y = hit.y - linesize * sgny * (t.HitEntity and .8 or 1)

			local dy = w / (2 * math.sqrt(2)) - h
			local dx = w / math.sqrt(2) - h
			for _, info in ipairs {
				{Color = basecolor, Material = ss.Materials.Crosshair.Line},
				{Color= ss.GetColor(self:GetNWInt "inkcolor"), Material = ss.Materials.Crosshair.LineColor},
			} do
				surface.SetDrawColor(info.Color)
				surface.SetMaterial(info.Material)
				surface.DrawTexturedRectRotated(hit.x, hit.y, w, h, 90 * i - 45)
				surface.DrawTexturedRectRotated(hit.x + sgnx * dx, hit.y - sgny * dy, w, h, 0)
				surface.DrawTexturedRectRotated(hit.x - sgnx * dy, hit.y + sgny * dx, w, h, 90)
				if not t.HitEntity then break end
			end
		end
	end
end

function SWEP:DrawHitCross(t) -- Hit cross pattern, foreground
	if not t.HitEntity then return end
	local p = self.Parameters
	local mul = 1.2
	local s = 10 * mul
	local w, h = t.Size.HitLine * mul, t.Size.HitWidth * mul
	local frac = 1 + p.mPaintNearDistance / p.mPaintFarDistance
	local lp = s + math.max(frac - (t.Distance / p.mPaintFarDistance)^.125, 0) * t.Size.ExpandHitLine -- Line position
	for mat, col in pairs {[""] = color_white, Color = ss.GetColor(self:GetNWInt "inkcolor")} do
		surface.SetMaterial(ss.Materials.Crosshair["Line" .. mat])
		surface.SetDrawColor(col)
		for i = 1, 4 do
			local dx, dy = lp * (i > 2 and 1 or -1), lp * (bit.band(i, 3) > 1 and 1 or -1)
			surface.DrawTexturedRectRotated(t.HitPosScreen.x + dx, t.HitPosScreen.y + dy, w, h, 90 * i + 45)
		end
	end
end

function SWEP:DrawChargeCircle(t)
	local p = self.Parameters
	local r = {t.Size.Outside1 / 2, t.Size.Outside2 / 2}
	local ri = {t.Size.Inside1 / 2, t.Size.Inside2 / 2}
	local prog = self:GetChargeProgress(true)
	if self:GetFireInk() > 0 then
		local frac = math.max(self:GetNextPrimaryFire() - CurTime() - self:Ping(), 0) / p.mRepeatFrame
		local max = {
			math.floor(p.mFirstPeriodMaxChargeShootingFrame / p.mRepeatFrame) + 1,
			math.floor(p.mSecondPeriodMaxChargeShootingFrame / p.mRepeatFrame) + 1,
		}

		prog = {
			math.Clamp((self:GetFireInk() + frac) / max[1], 0, 1) * 360,
			math.Clamp((self:GetFireInk() + frac - max[1]) / (max[2] - max[1]), 0, 1) * 360,
		}
	else
		prog = {
			math.min(prog / self.MediumCharge, 1) * (360 - self.MinChargeDeg),
			math.Clamp((prog - self.MediumCharge) / (1 - self.MediumCharge), 0, 1) * 360,
		}
		if prog[1] <= 0 then
			local frac = math.max(CurTime() - self:GetCharge() + self:Ping(), 0) / p.mFirstPeriodMaxChargeFrame
			prog[1] = math.Clamp(frac * ss.GetTimeScale(self.Owner), 0, 1) * 360
		else
			prog[1] = prog[1] + self.MinChargeDeg
		end
	end

	draw.NoTexture()
	surface.SetDrawColor(ColorAlpha(color_black, 192))
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r[1], r[1] - ri[1], 90, 450 - prog[1], 5)
	for i, color in ipairs {self.Crosshair.color_nohit, self.Crosshair.color_hit} do
		surface.SetDrawColor(color)
		ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r[i], r[i] - ri[i], 90 - prog[i], 90, 5)
	end
end

function SWEP:DrawColoredCircle(t)
	if not t.Trace.Hit then return end
	local r = t.Size.OutsideColored / 2
	local ri = t.Size.InsideColored / 2
	draw.NoTexture()
	surface.SetDrawColor(t.CrosshairColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, r + 1, r - ri)
end

local centerwidth = 2
function SWEP:DrawCenterDot(t) -- Center circle
	local s = t.Size.Dot / 2
	draw.NoTexture()
	if self:GetCharge() < math.huge or t.IsSplatoon2 and self:GetFireInk() > 0 then
		surface.SetDrawColor(self.Crosshair.color_circle)
		ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s + centerwidth)
		surface.SetDrawColor(self.Crosshair.color_nohit)
		ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s)

		if math.abs(t.EndPosScreen.x - t.HitPosScreen.x)
		+ math.abs(t.EndPosScreen.y - t.HitPosScreen.y) > 2 then
			local s = t.Size.OutsideCenter / 2
			surface.SetDrawColor(self.Crosshair.color_nohit)
			ss.DrawArc(t.EndPosScreen.x, t.EndPosScreen.y, s, s - t.Size.InsideCenter / 2)
		end
	end

	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s + centerwidth)
	surface.SetDrawColor(t.CrosshairColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s)
end

function SWEP:DrawCrosshairFlash(t)
	if CurTime() > self.CrosshairFlashTime + self.FlashDuration then return end
	local s = t.Size.OutsideColored * 2
	surface.SetMaterial(ss.Materials.Crosshair.Flash)
	surface.SetDrawColor(ColorAlpha(self:GetInkColor(), (self.CrosshairFlashTime + self.FlashDuration - CurTime()) / self.FlashDuration * 255))
	surface.DrawTexturedRect(t.HitPosScreen.x - s / 2, t.HitPosScreen.y - s / 2, s, s)
end

function SWEP:DrawCrosshair(x, y)
	if self:GetCharge() == math.huge and self:GetFireInk() == 0 then return end
	local t = self:SetupDrawCrosshair()
	t.EndPosScreen = (self:GetShootPos() + self:GetAimVector() * self.Range):ToScreen()
	t.CrosshairDarkColor = ColorAlpha(t.CrosshairColor, 192)
	t.CrosshairDarkColor.r, t.CrosshairDarkColor.g, t.CrosshairDarkColor.b
	= t.CrosshairDarkColor.r / 2, t.CrosshairDarkColor.g / 2, t.CrosshairDarkColor.b / 2
	self:DrawCenterDot(t)
	self:DrawColoredCircle(t)
	self:DrawChargeCircle(t)
	self:DrawHitCross(t)
	self:DrawFourLines(t, self:GetSpreadAmount())
	self:DrawCrosshairFlash(t)
	return true
end

function SWEP:SetupDrawCrosshair()
	local t = {Size = {}}
	t.CrosshairColor = ss.GetColor(ss.CrosshairColors[self:GetNWInt "inkcolor"])
	t.pos, t.dir = self:GetFirePosition()
	t.IsSplatoon2 = ss.GetOption "newstylecrosshair"
	local res = math.sqrt(ScrW() * ScrH() / originalres)
	for param, size in pairs {
		Dot = self.Crosshair.Dot,
		ExpandHitLine = self.Crosshair.HitLineSize,
		Inside1 = self.Crosshair.Inside1,
		Inside2 = self.Crosshair.Inside2,
		InsideColored = self.Crosshair.InsideColored,
		InsideCenter = self.Crosshair.InsideCenter,
		Outside1 = self.Crosshair.Outside1,
		Outside2 = self.Crosshair.Outside2,
		OutsideColored = self.Crosshair.OutsideColored,
		OutsideCenter = self.Crosshair.OutsideCenter,
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
