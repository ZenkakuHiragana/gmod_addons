
--Copied from propspawn.lua

local mat_ally = Material("models/spawn_effect_blue")
local mat_enemy = Material("models/spawn_effect_red")

function EFFECT:Init(data)
	
	-- This is how long the spawn effect
	-- takes from start to finish.
	self.Time = 0.5
	self.LifeTime = CurTime() + self.Time
	
	local ent = data:GetEntity()
	
	if not (IsValid(ent) and ent:GetModel()) then return end
	self.ParentEntity = ent
	self:SetModel(ent:GetModel())
	self.Material = data:GetFlags() == 1 and mat_enemy or mat_ally
	self:SetPos(ent:GetPos())
	self:SetAngles(ent:GetAngles())
	self:SetParent(ent)
	
	self.ParentEntity.RenderOverride = self.RenderParent
	self.ParentEntity.SpawnEffect = self
end

function EFFECT:Think()
	if not IsValid(self.ParentEntity) then return false end
	
	local PPos = self.ParentEntity:GetPos()
	self:SetPos(PPos + (EyePos() - PPos):GetNormalized())
	
	if self.LifeTime > CurTime() then return true end
	
	self.ParentEntity.RenderOverride = nil
	self.ParentEntity.SpawnEffect = nil
	return false
end

function EFFECT:Render() end

function EFFECT:RenderOverlay(entity)
	
	local Fraction = (self.LifeTime - CurTime()) / self.Time
	local ColFrac = (Fraction - self.Time) * 2
	
	Fraction = math.Clamp(Fraction, 0, 1)
	ColFrac = math.Clamp(ColFrac, 0, 1)
	
	-- Change our model's alpha so the texture will fade out
	self:SetColor(Color(255, 255, 255, 1 + 254 * (Fraction)))
	
	-- Place the camera a tiny bit closer to the entity.
	-- It will draw a big bigger and we will skip any z buffer problems
	local EyeNormal = entity:GetPos() - EyePos()
	local Distance = EyeNormal:Length()
	EyeNormal:Normalize()
	
	local bClipping = self:StartClip(entity, 2)
	local Pos = EyePos() + EyeNormal * Distance * 0.01
	cam.Start3D(Pos, EyeAngles())
		render.MaterialOverride(self.Material)
			entity:DrawModel()
		render.MaterialOverride(0)
	cam.End3D()
	render.PopCustomClipPlane()
	render.EnableClipping(bClipping)
end

function EFFECT:RenderParent()
	self.SpawnEffect:RenderOverlay(self)
	
	local bClipping = self.SpawnEffect:StartClip(self, 1)
	self:DrawModel()
	render.PopCustomClipPlane()
	render.EnableClipping(bClipping)
end

function EFFECT:StartClip( model, spd )
	local mn, mx = model:GetRenderBounds()
	local Up = (mx - mn):GetNormalized()
	local Bottom = model:GetPos() + mn
	local Top = model:GetPos() + mx
	
	local Fraction = (self.LifeTime - CurTime()) / self.Time
	Fraction = math.Clamp(Fraction / spd, 0, 1)
	
	local Lerped = LerpVector(Fraction, Bottom, Top)
	
	local normal = Up
	local distance = normal:Dot(Lerped)
	
	local bEnabled = render.EnableClipping(true)
	render.PushCustomClipPlane(normal, distance)
	
	return bEnabled
end
