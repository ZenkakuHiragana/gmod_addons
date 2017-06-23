
--Copied from propspawn.lua

local col = Color(192, 255, 255)

function EFFECT:Init(data)
	self:SetModel("models/effects/combineball.mdl")
	self:SetPos(data:GetOrigin())
	self:SetColor(col)
	self.Scale = 4
	self.Duration = 0.25
	self.Begin = CurTime()
	self:SetModelScale(self.Scale)
	
	local l = DynamicLight(self:EntIndex())
	l.Pos = self:GetPos()
	l.r, l.g, l.b = col.r, col.g, col.b
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
