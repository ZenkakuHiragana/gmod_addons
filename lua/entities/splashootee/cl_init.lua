--[[
	Splashootee is a Splashooter's projectile.
	This prints orange ink if it hit a wall.
]]

include("shared.lua")
ENT.AutomaticFrameAdvance = true

function ENT:Initialize()
	
	local c = GetConVar("sv_splatoon_automatic_disappear")
	if c:GetFloat() > 0 then
		SafeRemoveEntityDelayed(self, c:GetFloat())
	end
	self:PhysicsInit(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	
	local a = big
	
	local s = self:Getscale()
	if s == Vector(0, 0, 0) then
		s = Vector(1, 1, 1)
	end
	local m = Matrix()
	m:Scale(s)
	self:EnableMatrix("RenderMultiply", m)
	return
	
	self:SetNWVector("hull", Vector(big, big, big) / 2)
end

function ENT:DrawTranslucent()
	if GetConVar("cl_splatoon_usedecal"):GetBool() and self:GetMoveType() == MOVETYPE_NONE then return end
	local c = self:GetColor()
	local len = GetConVar("cl_splatoon_drawdistance"):GetFloat() or 10000
	c.a = 255 - (self:GetPos() - LocalPlayer():GetPos()):LengthSqr() / len
	if c.a > 50 then
	--	if self:GetMaterial() == "phoenix_storms/fender_white" then
	--		self:DisableMatrix("RenderMultiply")
	--	end
		if self:GetMaterial() == "decals/inks/ink" .. self:Getink() then
			self:DisableMatrix("RenderMultiply")
		end
		self:SetColor(c)
		self.BaseClass.Draw(self)
	end
	
--	elseif false then
--		if self:GetNWBool("triggered", false) or self:GetMoveType() == MOVETYPE_NONE then
--			--self:DisableMatrix("RenderMultiply")
--			local a, h = self:GetNWVector("normal", Vector(0, 0, 0)), self:GetNWVector("hull", Vector(big, big, big)):Length() * 3
--			if a == Vector(0, 0, 0) then
--				a = -self:GetForward()
--			end
--			a = a:Angle()
--			a.p = a.p + 90
--			
--			local c = self:GetColor()
--			c.a = 255
--			
--			cam.Start3D2D(self:GetPos() - self:GetForward(), a, 1)
--			surface.SetDrawColor(c)
--			surface.SetMaterial(mat)
--			surface.DrawRect(-h / 2, -h / 2, h, h)
--		--	render.DrawQuadEasy(self:GetPos(), -self:GetForward(), 100, 100, Color(0, 255, 0, 255), CurTime() * 100)
--			cam.End3D2D()
--		else
--			if true then
--				self.BaseClass.Draw(self)
--			end
--		end
--	end
end
