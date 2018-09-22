
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
	self.IronSightsPos[6] = self.ScopePos
	self.IronSightsAng[6] = self.ScopeAng
	self.IronSightsFlip[6] = false
	self.BaseClass.BaseClass.ClientInit(self)
	
	if not self.Scoped then return end
	self.RTScope = GetRenderTarget(ss.RTName.RTScope, 512, 512)
	self:AddSchedule(0, function(self, sched)
		local vm = self.Owner:GetViewModel()
		if not IsValid(vm) then return end
		if self.RTScope and self:GetNWBool "UseRTScope" then
			self.RTName = self.RTName or vm:GetMaterials()[self.RTScopeNum] .. "rt"
			self.RTMaterial = self.RTMaterial or Material(self.RTName)
			self.RTMaterial:SetTexture("$basetexture", self.RTScope)
			self.RTAttachment = self.RTAttachment or vm:LookupAttachment "scope_end"
			if not self.RTAttachment then return end
			vm:SetSubMaterial(self.RTScopeNum - 1, self.RTName)
			
			local alpha = 1 - self:GetScopedProgress(true)
			render.PushRenderTarget(self.RTScope)
			render.RenderView {
				origin = vm:GetAttachment(self.RTAttachment).Pos,
				x = 0, y = 0, w = 512, h = 512, aspectratio = 1,
				fov = self.Primary.Scope.FOV / 2,
				drawviewmodel = false,
			}
			ss.ProtectedCall(self.HideRTScope, self, alpha)
			render.PopRenderTarget()
		else
			vm:SetSubMaterial(self.RTScopeNum - 1)
		end
	end)
	
	self:AddSchedule(0, function(self, sched)
		if not (self.Scoped and IsValid(self.Owner)) then return end
		self.Owner:SetNoDraw(
			self:IsMine() and
			self:GetScopedProgress() == 1 and
			not self:GetNWBool "UseRTScope")
	end)
end

function SWEP:DisplayAmmo()
	if self:GetCharge() == math.huge then return 0 end
	return math.max(self:GetChargeProgress(true) * 100, 0)
end

function SWEP:GetScopedSize()
	return 1 + (self:GetNWBool "UseRTScope" and self:IsTPS() and 0 or self:GetScopedProgress(true))
end

function SWEP:ClientPrimaryAttack() end
function SWEP:DrawFourLines(t) end
function SWEP:DrawOuterCircle(t)
	local scoped = self:GetScopedSize()
	local r = t.Size.Outer / 2 * scoped
	local ri = t.Size.Inner / 2 * scoped
	local rm = t.Size.Middle / 2 * scoped
	local time = math.max(CurTime() - self:GetCharge() + self:Ping(), 0)
	local prog = math.Clamp(time / self.Primary.MaxChargeTime, 0, 1) * 360
	
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
	ss.DrawArc(self.Cursor.x, self.Cursor.y, s + innerwidth, innerwidth)
end

function SWEP:DrawCenterDot(t) -- Center circle
	local scoped = self:GetScopedSize()
	local s = t.Size.Dot / 2 * scoped
	draw.NoTexture()
	if scoped < 2 then
		surface.SetDrawColor(self.Crosshair.color_circle)
		ss.DrawArc(self.Cursor.x, self.Cursor.y, s + innerwidth)
		surface.SetDrawColor(self.Crosshair.color_nohit)
		ss.DrawArc(self.Cursor.x, self.Cursor.y, s)
	end
	
	if not t.Trace.Hit then return end
	surface.SetDrawColor(t.CrosshairDarkColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s + innerwidth)
	surface.SetDrawColor(t.CrosshairColor)
	ss.DrawArc(t.HitPosScreen.x, t.HitPosScreen.y, s)
end

local MatScope = Material "gmod/scope"
local MatRefScope = Material "gmod/scope-refract"
local DebugRefract = Material "dev/reflectivity_10"
local DebugRefDefault = DebugRefract:GetFloat "$refractamount"
local MatRefDefault = MatRefScope:GetFloat "$refractamount"
function SWEP:RenderScreenspaceEffects()
	if not self.Scoped or self:GetNWBool "UseRTScope" then return end
	local prog = self:GetScopedProgress(true)
	if prog == 0 then return end
	local padding = surface.DrawTexturedRectUV
	local u, v = .115, 1
	local x, y = self.Cursor.x, self.Cursor.y
	local sx, sy = ScrH() * 4 / 3, ScrH()
	local ex, ey = x + sx / 2, y + sy / 2 -- End position of x, y
	x, y = x - sx / 2, y - sy / 2
	
	MatRefScope:SetFloat("$refractamount", prog * prog * MatRefDefault)
	for _, material in ipairs {MatRefScope, MatScope} do
	surface.SetDrawColor(ColorAlpha(color_black, prog * 255))
		surface.SetMaterial(material)
		surface.DrawTexturedRect(x, y, sx, sy)
		if x > 0 then padding(0, 0, x, ScrH(), 0, 0, u, v) end
		if ex < ScrW() then padding(ex, 0, ScrW() - ex, ScrH(), 0, 0, u, v) end
		if y > 0 then padding(x, 0, sx, y, 0, 0, u, v) end
		if ey < ScrH() then padding(x, ey, ScrW(), ScrH() - ey, 0, 0, u, v) end
	end
	
	MatRefScope:SetFloat("$refractamount", MatRefDefault)
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

function SWEP:TranslateFOV(fov)
	if not self.Scoped or self:GetNWBool "UseRTScope" then return end
	return Lerp(self:GetScopedProgress(true), fov, self.Primary.Scope.FOV)
end

function SWEP:PreViewModelDrawn(vm, weapon, ply)
	local base = self.BaseClass.BaseClass
	ss.ProtectedCall(base.PreViewModelDrawn, self, vm, weapon, ply)
	if self:GetNWBool "UseRTScope" then return end
	render.SetBlend((1 - self:GetScopedProgress(true))^2)
end

function SWEP:PostDrawViewModel(vm, weapon, ply)
	local base = self.BaseClass.BaseClass
	ss.ProtectedCall(base.PostDrawViewModel, self, vm, weapon, ply)
	if not self.Scoped then return end
	render.SetBlend(1)
end

function SWEP:PreDrawWorldModel()
	if not self.Scoped or self:GetNWBool "UseRTScope" then return end
	return self:GetScopedProgress(true) == 1
end

function SWEP:GetArmPos()
	local scope = self.Primary.Scope
	if self:GetADS() then
		self.SwayTime = self.TransitFlip and
		12 * ss.FrameToSec or scope.SwayTime / 2
		return 6
	end
	
	if not self.Scoped then return end
	local prog = self:GetChargeProgress(true)
	local timescale = ss.GetTimeScale(self.Owner)
	local SwayTime = self.SwayTime / timescale
	self.SwayTime = 12 * ss.FrameToSec
	if prog > scope.StartMove then
		if not self.TransitFlip then
			self.SwayTime = scope.SwayTime
		end
		
		if not self:GetNWBool "UseRTScope" then
			self.SwayTime = self.SwayTime / 2
		end
		
		local mul = self.Primary.EmptyChargeMul
		local f = (SysTime() - self.ArmBegin) / SwayTime
		if not self.Owner:OnGround() or self:GetInk() < prog * self.Primary.TakeAmmo then
			self.SwayTime = scope.SwayTime * mul
		end
		
		self.ArmBegin = SysTime() - f * self.SwayTime / timescale
		return 6
	end
end

function SWEP:CustomCalcView(ply, pos, ang, fov)
	if self:GetNWBool "UseRTScope" then return end
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
	local b = {ply:LookupBone "ValveBiped.Bip01_L_Forearm"}
	local bp, ba = {}, {}
	while #b > 0 do
		local m = ply:GetBoneMatrix(b[1])
		if not m then return end
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
