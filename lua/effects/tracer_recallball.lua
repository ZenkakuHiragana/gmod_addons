
local color_ally = Color(192, 255, 255)
local color_enemy = Color(255, 128, 128)

function EFFECT:Init(data)
	self:SetModel("models/effects/combineball.mdl")
	self:SetPos(data:GetOrigin())
	self:SetAngles(EyeAngles())
	self.Color = data:GetFlags() == 1 and color_enemy or color_ally
	self:SetColor(self.Color)
	self.Scale = 4
	self.Duration = 0.25
	self.Begin = CurTime()
	self:SetModelScale(self.Scale)
	
	local l = DynamicLight(self:EntIndex())
	l.Pos = self:GetPos()
	l.r, l.g, l.b = self.Color.r, self.Color.g, self.Color.b
	l.brightness = 2
	l.Decay = 1000
	l.Size = 256
	l.DieTime = CurTime() + self.Duration
end

function EFFECT:Think()
	return CurTime() < self.Begin + self.Duration
end

function EFFECT:Render()
	local scale = (self.Duration - CurTime() + self.Begin) / self.Duration * self.Scale
	self:SetModelScale(scale)
	self:SetAngles(EyeAngles())
	self:DrawModel()
end
