include "shared.lua"

local material = Material "sprites/light_ignorez"
local Colors = {Color(0, 255, 0), Color(255, 191, 0), Color(255, 0, 0)}
local SpritePos = {-11.2, 0, 11.2}
function ENT:DrawTranslucent()
	self:DrawModel()
	
	local color = self:GetNWInt "DVTL_LightColor"
	self.SpriteColor = Colors[color]
	self.SpritePos = SpritePos[color]
	
	local LightPos = self:GetPos() + self:GetForward() * -2 + self:GetUp() * self.SpritePos
	local dlight = DynamicLight(self:EntIndex())
	if not dlight then return true end
	dlight.pos = LightPos
	dlight.r = self.SpriteColor.r
	dlight.g = self.SpriteColor.g
	dlight.b = self.SpriteColor.b
	dlight.brightness = 2
	dlight.decay = 0
	dlight.size = 128
	dlight.dietime = CurTime() + 1
	
	if util.TraceLine {
		start = EyePos(),
		endpos = LightPos,
		filter = {self, LocalPlayer()},
		mask = MASK_VISIBLE_AND_NPCS,
	} .Hit then return end
	
	local ViewNormal = self:GetPos() - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	
	local ViewDot = ViewNormal:Dot(self:GetForward())
	if ViewDot < 0 then return end
	
	local Visible = util.PixelVisible(LightPos, 16, self.PixVis)
	if (Visible or 0) < 5e-3 then return end

	local Size = math.Clamp(Distance * Visible * ViewDot * 2, 48, 128)
	local Alpha = math.Clamp((1000 - math.Clamp(Distance, 32, 800)) * Visible * ViewDot, 0, 100)
	render.SetMaterial(material)
	render.DrawSprite(LightPos, Size, Size,  ColorAlpha(self.SpriteColor, Alpha))
	render.DrawSprite(LightPos, Size * .2, Size * .2, ColorAlpha(color_white, Alpha))
end

function ENT:Initialize()
	self:SetPattern(1)
	self:SetNWInt("DVTL_LightColor", 1)
	self.PixVis = util.GetPixelVisibleHandle()
end

function ENT:OnRemove()
	local dlight = DynamicLight(self:EntIndex())
	if not dlight then return end
	dlight.dietime = CurTime()
	dlight.brightness = 0
end
