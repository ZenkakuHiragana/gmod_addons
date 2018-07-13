
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
local FireWeaponCooldown = 0.1
local FireWeaponMultiplier = 1
local function ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
	if v.inktank then return end
	local fraction = (FireWeaponCooldown - SysTime() + self.ModifyWeaponSize) * FireWeaponMultiplier
	matrix:Scale(ss.vector_one * math.max(1, fraction + 1))
end

SWEP.PreDrawWorldModel = ExpandModel
SWEP.PreViewModelDrawn = ExpandModel
SWEP.IronSightsAng = {
	Vector(), -- normal
	Vector(0, -20, 0), -- left
	Vector(0, 0, -75), -- top-right
	Vector(-15, -15, 15), -- top-left
	Vector(0, -13.3, 0), -- center
}
SWEP.IronSightsPos = {
	Vector(), -- normal
	Vector(-20, -4, 0), -- left
	Vector(), -- top-right
	Vector(-20, -4, 8), -- top-left
	Vector(-13.3, 0, -1), -- center
}

function SWEP:ClientInit()
	self.oldpos = Vector()
	self.p, self.y, self.r = 0, 0, 0
	self.ModifyWeaponSize = SysTime() - 1
	self.ViewPunch = Angle()
	self.ViewPunchVel = Angle()
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
	elseif ss:GetConVarBool "MoveViewmodel" and not self:Crouching() then
		local x, y = ScrW() / 2, ScrH() / 2
		if vgui.CursorVisible() then x, y = input.GetCursorPos() end
		armpos = select(3, self:GetFirePosition(self.Primary.Range * gui.ScreenToVector(x, y), RenderAngles(), EyePos()))
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

local dot = 1920 * 1080 / 8^2 -- Measuring screenshot
local inner = 1920 * 1080 / 64^2 -- Texture size / 2
local outer = 1920 * 1080 / 64^2 -- Texture size / 2
local outerhitsize = 1920 * 1080 / 72^2 -- Texture size / 2
local lines = 1920 * 1080 / 32^2 -- Just a random value
local color_circle = Color(0, 0, 0, 64)
local color_nohit = Color(255, 255, 255, 64)
function SWEP:DoDrawCrosshair(x, y)
	if not ss:GetConVarBool "DrawCrosshair" then return end
	if vgui.CursorVisible() then x, y = input.GetCursorPos() end
	
	local splt2 = ss:GetConVarBool "NewStyleCrosshair"
	local color = ss:GetColor(ss.CrosshairColors[self:GetColorCode()])
	local inkcolor = ss:GetColor(self:GetColorCode())
	local pos, dir = self:GetFirePosition()
	local throughpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.Primary.Range
	local through = throughpos:ToScreen()
	local t = ss.SquidTrace
	t.start, t.endpos = pos, pos + dir * self.Primary.Range
	t.filter = {self, self.Owner}
	t.maxs = ss.vector_one * self.Primary.ColRadius
	t.mins = -t.maxs
	
	local tr = util.TraceHull(t)
	local hit = tr.HitPos:ToScreen()
	local hitentity = IsValid(tr.Entity) and tr.Entity:Health() > 0
	local outersize = math.ceil(math.sqrt(ScrW() * ScrH() / outer))
	if hitentity then
		local w = ss:IsValidInkling(tr.Entity)
		if w and ss:IsAlly(w, self) then
			hitentity = false
		end
	end
	
	-- Four lines around
	local frac = tr.Fraction
	local basecolor = splt2 and tr.Hit and color_nohit or color_white
	local lx, ly = hit.x, hit.y
	local w = math.ceil(math.sqrt(ScrW() * ScrH() / lines))
	local h = math.ceil(w / 16)
	local pitch = EyeAngles():Right()
	local yaw = pitch:Cross(dir)
	local spreadx = Lerp(self.Owner:GetVelocity().z * ss.SpreadJumpCoefficient
	/ ss.SpreadJumpMaxVelocity, self.Primary.Spread, self.Primary.SpreadJump)
	if splt2 then
		frac = 1
		lx, ly = through.x, through.y
		if tr.Hit then
			dir = self.Owner:GetAimVector()
			pos = self.Owner:GetShootPos()
		end
	end
	
	local linesize = outersize * (1.5 - frac)
	for i = 1, 4 do
		local rot = dir:Angle()
		local mx, my = i > 2 and 1 or -1, bit.band(i, 3) > 1 and 1 or -1
		rot:RotateAroundAxis(yaw, spreadx * mx)
		rot:RotateAroundAxis(pitch, ss.mDegRandomY * my)
		
		local endpos = pos + rot:Forward() * self.Primary.Range * frac
		local hit = endpos:ToScreen()
		if not hit.visible then continue end
		hit.x = hit.x - linesize * mx * (hitentity and .75 or 1)
		hit.y = hit.y - linesize * my * (hitentity and .75 or 1)
		surface.SetDrawColor(basecolor)
		surface.SetMaterial(ss.Materials.Crosshair.Line)
		surface.DrawTexturedRectRotated(hit.x, hit.y, w, h, 90 * i - 45)
		
		if not hitentity then continue end
		surface.SetDrawColor(inkcolor)
		surface.SetMaterial(ss.Materials.Crosshair.LineColor)
		surface.DrawTexturedRectRotated(hit.x, hit.y, w, h, 90 * i - 45)
	end
	
	-- Hit cross pattern, background
	local lp = (1.4 - tr.Fraction) * outersize / 2 -- line position
	if hitentity then
		surface.SetMaterial(ss.Materials.Crosshair.Line)
		surface.SetDrawColor(color_black)
		local w = outersize * .8 + 8
		local h = math.ceil(w / 8) + 2
		for i = 1, 4 do
			local dx, dy = lp * (i > 2 and 1 or -1), lp * (bit.band(i, 3) > 1 and 1 or -1)
			surface.DrawTexturedRectRotated(hit.x + dx, hit.y + dy, w, h, 90 * i + 45)
		end
	end
	
	-- Outer circle
	surface.SetMaterial(ss.Materials.Crosshair.Outer)
	if hitentity then
		local outersizehit = math.ceil(math.sqrt(ScrW() * ScrH() / outerhitsize))
		surface.SetDrawColor(color_black)
		surface.DrawTexturedRect(hit.x - outersizehit / 2, hit.y - outersizehit / 2, outersizehit, outersizehit)
	end
	
	surface.SetDrawColor(tr.Hit and color or color_circle)
	surface.DrawTexturedRect(hit.x - outersize / 2, hit.y - outersize / 2, outersize, outersize)
	if splt2 and tr.Hit then
		surface.SetDrawColor(color_circle)
		surface.DrawTexturedRect(through.x - outersize / 2, through.y - outersize / 2, outersize, outersize)
	end
	
	-- Hit cross pattern, foreground
	if hitentity then
		for mat, col in pairs {[""] = color_white, Color = inkcolor} do
			surface.SetMaterial(ss.Materials.Crosshair["Line" .. mat])
			surface.SetDrawColor(col)
			local w = outersize * .8
			local h = math.floor(w / 16)
			for i = 1, 4 do
				local dx, dy = lp * (i > 2 and 1 or -1), lp * (bit.band(i, 3) > 1 and 1 or -1)
				surface.DrawTexturedRectRotated(hit.x + dx, hit.y + dy, w, h, 90 * i + 45)
			end
		end
	end
	
	-- Inner circle
	surface.SetMaterial(ss.Materials.Crosshair.Inner)
	surface.SetDrawColor(tr.Hit and color_white or color_nohit)
	s = math.ceil(math.sqrt(ScrW() * ScrH() / inner))
	surface.DrawTexturedRect(hit.x - s / 2, hit.y - s / 2, s, s)
	if splt2 and tr.Hit then
		surface.SetDrawColor(color_nohit)
		surface.DrawTexturedRect(through.x - s / 2, through.y - s / 2, s, s)
	end
	
	-- Center circle
	local s = math.ceil(math.sqrt(ScrW() * ScrH() / dot))
	surface.SetMaterial(ss.Materials.Crosshair.Dot)
	surface.SetDrawColor(color_white)
	surface.DrawTexturedRect(hit.x - s / 2, hit.y - s / 2, s, s)
	if splt2 and tr.Hit then
		surface.SetDrawColor(color_nohit)
		surface.DrawTexturedRect(through.x - s / 2, through.y - s / 2, s, s)
	end
	
	return true
end

function SWEP:ClientPrimaryAttack(hasink, auto)
	if not IsValid(self.Owner) then return end
	local pos, dir = self:GetFirePosition()
	local delay, lv = self.Cooldown, self:GetLaggedMovementValue()
	if not game.SinglePlayer() then
		self:SetAimTimer(math.max(self:GetAimTimer(), CurTime() + self.Primary.AimDuration))
		if self:IsFirstTimePredicted() or self:CheckButtons(IN_ATTACK) then
			self:SetInk(math.max(0, self:GetInk() - self.Primary.TakeAmmo))
		end
	end
	
	if not self:IsFirstTimePredicted() then return end
	if not hasink then
		if self.Primary.TripleShotDelay then self.Cooldown = CurTime() end
		if self.Owner == LocalPlayer() and self.PreviousInk then
			surface.PlaySound(ss.TankEmpty)
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
			self.PreviousInk = false
		elseif CurTime() > self.NextPlayEmpty then
			self:EmitSound "SplatoonSWEPs.EmptyShot"
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
		end
		
		return
	end
	
	if self.Owner:IsPlayer() then
		local rnda = self.Primary.Recoil * -1
		local rndb = self.Primary.Recoil * math.Rand(-1, 1)
		self.ViewPunch = Angle(rnda, rndb, rnda)
	end
	
	local right = self.Owner:GetRight()
	local ang = dir:Angle()
	local angle_initvelocity = Angle(ang)
	local DegRandomX = util.SharedRandom("SplatoonSWEPs: Spread", -self.Primary.SpreadBias, self.Primary.SpreadBias)
	+ Lerp(self.Owner:GetVelocity().z * ss.SpreadJumpFraction, self.Primary.Spread, self.Primary.SpreadJump)
	local rx = util.SharedRandom("SplatoonSWEPs: Spread", -DegRandomX, DegRandomX, CurTime() * 1e4)
	local ry = util.SharedRandom("SplatoonSWEPs: Spread", -ss.mDegRandomY, ss.mDegRandomY, CurTime() * 1e3)
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	angle_initvelocity:RotateAroundAxis(right:Cross(dir), rx)
	angle_initvelocity:RotateAroundAxis(right, ry)
	local initvelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	
	self.Owner:MuzzleFlash()
	self.ModifyWeaponSize = SysTime()
	self.PreviousInk = true
	self.Cooldown = math.max(self.Cooldown, CurTime()
	+ math.min(self.Primary.Delay, self.Primary.CrouchDelay) / lv)
	if self.Owner == LocalPlayer() or game.SinglePlayer() and not self.Owner:IsPlayer() then
		self:EmitSound(self.ShootSound)
	end
	
	if self.Owner == LocalPlayer() and not game.SinglePlayer() then
		ss.InkTraces[{
			Appearance = {
				InitPos = pos,
				Pos = pos,
				Speed = self.Primary.InitVelocity,
				TrailPos = pos,
				Velocity = initvelocity,
			},
			Color = ss:GetColor(self:GetColorCode()),
			ColorCode = self:GetColorCode(),
			InitPos = pos,
			InitTime = CurTime() - self:Ping(),
			Speed = self.Primary.InitVelocity,
			Straight = self.Primary.Straight,
			TrailDelay = ss.ShooterTrailDelay,
			TrailTime = RealTime(),
			Velocity = initvelocity,
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			filter = self.Owner,
			mask = ss.SquidSolidMask,
			maxs = ss.vector_one * ss.mColRadius,
			mins = -ss.vector_one * ss.mColRadius,
			start = pos,
		}] = true
	end
	
	if game.SinglePlayer() or not self.Primary.TripleShotDelay or self.TripleSchedule.done < 2 then return end
	self.Cooldown = CurTime() + (self.Primary.Delay * 2 + self.Primary.TripleShotDelay) / lv
	self:SetAimTimer(self.Cooldown)
	if self.Owner ~= LocalPlayer() then return end
	self.TripleSchedule = self:AddSchedule(self.Primary.Delay, 2, self.PrimaryAttack)
end
