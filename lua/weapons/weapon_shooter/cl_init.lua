
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
	local fraction = (FireWeaponCooldown - CurTime() + self:GetModifyWeaponSize()) * FireWeaponMultiplier
	matrix:Scale(SplatoonSWEPs.vector_one * math.max(1, fraction + 1))
end
SWEP.PreDrawWorldModel, SWEP.PreViewModelDrawn = ExpandModel, ExpandModel
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
end

function SWEP:GetViewModelPosition(pos, ang)
	if not IsValid(self.Owner) then return pos, ang end
	
	local _, _, armpos = self:GetFirePosition()
	if not ss:GetConVarBool "MoveViewmodel" or self.Owner:Crouching() then armpos = 1 end
	local iang = self.IronSightsAng[armpos] or Vector()
	self.p = self.p + (iang.x - self.p) * .1
	self.y = self.y + (iang.y - self.y) * .1
	self.r = self.r + (iang.z - self.r) * .1
	
	local dang = Angle(ang)
	dang:RotateAroundAxis(dang:Right(), self.p)
	dang:RotateAroundAxis(dang:Up(), self.y)
	dang:RotateAroundAxis(dang:Forward(), self.r)
	
	local ipos = self.IronSightsPos[armpos] or Vector()
	local dpos = ipos.x * dang:Right() + ipos.y * dang:Forward() + ipos.z * dang:Up()
	self.oldpos = self.oldpos + (dpos - self.oldpos) * .1
	
	return pos + self.oldpos, dang
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
	local color = ss:GetColor(ss.CrosshairColors[self.ColorCode])
	local inkcolor = ss:GetColor(self.ColorCode)
	local pos, dir = self:GetFirePosition()
	local throughpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.Primary.Range
	local t = {
		start = pos, endpos = pos + dir * self.Primary.Range,
		filter = {self, self.Owner}, mask = ss.SquidSolidMask,
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		mins = -ss.vector_one * self.Primary.ColRadius,
		maxs = ss.vector_one * self.Primary.ColRadius,
	}
	
	local tr = util.TraceHull(t)
	local hitentity = IsValid(tr.Entity) and tr.Entity:Health() > 0
	local outersize = math.ceil(math.sqrt(ScrW() * ScrH() / outer))
	if hitentity then
		local w = ss:IsValidInkling(tr.Entity)
		if w and w.ColorCode == self.ColorCode then
			hitentity = false
		end
	end
	
	cam.Start3D()
	local hit = tr.HitPos:ToScreen()
	local through = throughpos:ToScreen()
	cam.End3D()
	
	-- Four lines around
	local frac = tr.Fraction
	local basecolor = splt2 and tr.Hit and color_nohit or color_white
	local lx, ly = hit.x, hit.y
	local w = math.ceil(math.sqrt(ScrW() * ScrH() / lines))
	local h = math.ceil(w / 16)
	local pitch = self.Owner:GetRight()
	local yaw = pitch:Cross(dir)
	local spreadx = math.Remap(math.Clamp(self.Owner:GetVelocity().z
	* ss.SpreadJumpCoefficient, 0, ss.SpreadJumpMaxVelocity),
	0, ss.SpreadJumpMaxVelocity, self.Primary.Spread, self.Primary.SpreadJump)
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
		
		cam.Start3D()
		local endpos = pos + rot:Forward() * self.Primary.Range * frac
		local hit = endpos:ToScreen()
		cam.End3D()
		
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
