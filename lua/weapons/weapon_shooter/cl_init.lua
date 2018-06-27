
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

--Custom functions executed before weapon model is drawn.
--  model | Weapon model(Clientside Entity)
--  bone_ent | Owner entity
--  pos, ang | Position and angle of weapon model
--  v | Viewmodel/Worldmodel element table
--  matrix | VMatrix for scaling
--When the weapon is fired, it slightly expands.  This is maximum time to get back to normal size.
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
	Vector(), --normal
	Vector(0, -20, 0), --left
	Vector(0, 0, -75), --top-right
	Vector(-15, -15, 15), --top-left
	Vector(0, -13.3, 0), --center
}
SWEP.IronSightsPos = {
	Vector(), --normal
	Vector(-20, -4, 0), --left
	Vector(), --top-right
	Vector(-20, -4, 8), --top-left
	Vector(-13.3, 0, -1), --center
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
	if ss:GetConVarBool "MoveViewmodel" and not self:Crouching() then
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

local dot = 1920 * 1080 / 8^2 --Measuring screenshot
local inner = 1920 * 1080 / 64^2 --Texture size / 2
local outer = 1920 * 1080 / 64^2 --Texture size / 2
local outerhitsize = 1920 * 1080 / 72^2 --Texture size / 2
local lines = 1920 * 1080 / 32^2 --Just a random value
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
		if w and w:GetColorCode() == self:GetColorCode() then
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
	
	--Hit cross pattern, background
	local lp = (1.4 - tr.Fraction) * outersize / 2 --line position
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
	
	--Outer circle
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
	
	--Hit cross pattern, foreground
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
	
	--Inner circle
	surface.SetMaterial(ss.Materials.Crosshair.Inner)
	surface.SetDrawColor(tr.Hit and color_white or color_nohit)
	s = math.ceil(math.sqrt(ScrW() * ScrH() / inner))
	surface.DrawTexturedRect(hit.x - s / 2, hit.y - s / 2, s, s)
	if splt2 and tr.Hit then
		surface.SetDrawColor(color_nohit)
		surface.DrawTexturedRect(through.x - s / 2, through.y - s / 2, s, s)
	end
	
	--Center circle
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

function SWEP:ClientPrimaryAttack(hasink)
	if not IsValid(self.Owner) then return end
	if not self.CrouchPriority or LocalPlayer() ~= self.Owner then
		self.InklingSpeed = self.Primary.MoveSpeed
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		if not self:GetOnEnemyInk() then self:SetPlayerSpeed(self.Primary.MoveSpeed) end
		if self:IsFirstTimePredicted() and hasink and self.Owner:IsPlayer() then
			local rnda = self.Primary.Recoil * -1
			local rndb = self.Primary.Recoil * math.Rand(-1, 1)
			self.ViewPunch = Angle(rnda, rndb, rnda)
		end
	end
	
	local pos, dir, armpos = self:GetFirePosition()
	local delay, lv = self.ShotDelay, self:GetLaggedMovementValue()
	self.ShotDelay = math.max(self.ShotDelay, CurTime() + self.Primary.CrouchDelay / lv)
	armpos = armpos == 3 or armpos == 4
	if self.Owner:IsPlayer() then self:SetHoldType(armpos and "rpg" or "crossbow") end
	if not self:IsFirstTimePredicted() then return end
	if not hasink then
		if self.Primary.TripleShotDelay then self.ShotDelay = CurTime() end
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
	
	self:EmitSound(self.ShootSound)
	self.ModifyWeaponSize = SysTime()
	self.PreviousInk = true
	if self.Owner == LocalPlayer() then
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
			TrailDelay = self.Primary.Delay / 2,
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
	DebugPoint(pos, 5, true)
	if not self.Primary.TripleShotDelay or self.TripleSchedule.done < 2 then return end
	self.ShotDelay = CurTime() + (self.Primary.Delay * 3 + self.Primary.TripleShotDelay) / lv
	if self.Owner ~= LocalPlayer() then return end
	self.TripleSchedule = self:AddSchedule(self.Primary.Delay, 2, self.PrimaryAttack)
end

function SWEP:ClientThink()
	if not self.Owner:IsPlayer() then return end
	if self:Crouching() then
		self:SetHoldType "melee2"
		self.WElements.weapon.bone = "ValveBiped.Bip01_R_Hand"
	end
	
	if self:GetAimTimer() < CurTime() then
		self.InklingSpeed = self:GetInklingSpeed()
		if not self:GetThrowing() then
			self:SetHoldType "passive"
			self.WElements.weapon.bone = "ValveBiped.Bip01_R_Hand"
		end
		
		if self:GetOnEnemyInk() or self:GetInInk() then return end
		self:SetPlayerSpeed(self.InklingSpeed)
	else
		local armpos = select(3, self:GetFirePosition())
		self:SetHoldType((armpos == 3 or armpos == 4) and "rpg" or "crossbow")
	end
end
