
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

local dot = 1920 * 1080 / 8^2 --Measuring screenshot
local inner = 1920 * 1080 / 64^2 --Texture size / 2
local outer = 1920 * 1080 / 64^2 --Texture size / 2
local lines = 1920 * 1080 / 6^2 --Just a random value
local color_circle = Color(0, 0, 0, 64)
local color_nohit = Color(255, 255, 255, 64)
function SWEP:DoDrawCrosshair(x, y)
	if not ss:GetConVarBool "DrawCrosshair" then return end
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(ss.Materials.Crosshair.Dot)
	
	--Center circle
	local s = math.ceil(math.sqrt(ScrW() * ScrH() / dot))
	surface.DrawTexturedRect(x - s / 2, y - s / 2, s, s)
	
	--Surrounding circle
	local color = ss:GetColor(ss.CrosshairColors[self.ColorCode])
	local pos = self.Owner:GetShootPos()
	local dp = self:GetFirePosition()
	local len = self.Primary.InitVelocity * (self.Primary.Straight + 2.5 * ss.FrameToSec)
	local dir = self.Owner:EyeAngles():Forward()
	local t = {
		start = pos + dp, endpos = pos + dp + dir * len,
		filter = {self, self.Owner}, mask = MASK_SHOT,
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		mins = -ss.vector_one * self.Primary.ColRadius,
		maxs = ss.vector_one * self.Primary.ColRadius,
	}
	--Outer circle
	local tr = util.TraceHull(t)
	surface.SetDrawColor(tr.Hit and color or color_circle)
	surface.SetMaterial(ss.Materials.Crosshair.Outer)
	local outersize = math.ceil(math.sqrt(ScrW() * ScrH() / outer))
	surface.DrawTexturedRect(x - outersize / 2, y - outersize / 2, outersize, outersize)
	
	--Inner circle
	surface.SetDrawColor(tr.Hit and color_white or color_nohit)
	surface.SetMaterial(ss.Materials.Crosshair.Inner)
	s = math.ceil(math.sqrt(ScrW() * ScrH() / inner))
	surface.DrawTexturedRect(x - s / 2, y - s / 2, s, s)
	
	--Four lines around
	outersize = outersize / 2
	s = math.ceil(math.sqrt(ScrW() * ScrH() / lines))
	local pitch = self.Owner:GetRight()
	local yaw = pitch:Cross(dir)
	local jumpfactor = math.Clamp(self.Owner:GetVelocity().z, 0, 32)
	local spreadx = math.Remap(jumpfactor, 0, 32, self.Primary.Spread, self.Primary.SpreadJump)
	for _, d in ipairs {
		{a = -spreadx, p = ss.mDegRandomY, x = {-1, 1}, y = {-1, 1}},
		{a = spreadx, p = ss.mDegRandomY, x = {1, -1}, y = {-1, 1}},
		{a = -spreadx, p = -ss.mDegRandomY, x = {1, -1}, y = {-1, 1}},
		{a = spreadx, p = -ss.mDegRandomY, x = {-1, 1}, y = {-1, 1}},
	} do
		local rot = dir:Angle()
		rot:RotateAroundAxis(yaw, d.a)
		rot:RotateAroundAxis(pitch, d.p)
		t.start, t.endpos = pos, pos + rot:Forward() * len
		tr = util.TraceHull(t)
		cam.Start3D(pos, dir:Angle())
		local v = tr.HitPos:ToScreen()
		cam.End3D()
		if v.visible then
			local dx, dy = v.x - ScrW() / 2, v.y - ScrH() / 2
			if math.abs(dx) < outersize then
				v.x = x + outersize * (dx > 0 and 1 or -1)
			end if math.abs(dy) < outersize then
				v.y = y + outersize * (dy > 0 and 1 or -1)
			end
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawLine(v.x + s * d.x[1], v.y + s * d.y[1], v.x + s * d.x[2], v.y + s * d.y[2])
			surface.DrawLine(v.x + s * d.x[1] - 1, v.y + s * d.y[1], v.x + s * d.x[2] - 1, v.y + s * d.y[2])
			surface.DrawLine(v.x + s * d.x[1], v.y + s * d.y[1] - 1, v.x + s * d.x[2], v.y + s * d.y[2] - 1)
		end
	end
	return true
end
