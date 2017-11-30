
include "shared.lua"

function ENT:Initialize()
	if not util.IsValidModel(self.FlyingModel) then
		chat.AddText("Splatoon SWEPs: Can't spawn ink!  Required model is not found!")
		return
	end
	
	self:SharedInit()
end

function ENT:OnRemove()
	if self.IMesh then self.IMesh:Destroy() end
end

function ENT:Draw()
	if self:GetIsInk() then
	--	if not self.IMesh then
	--		if self.Vertices then
	--			self.IMesh = Mesh()
	--			self.IMesh:BuildFromTriangles(self.Vertices)
	--		end
	--	else
		--	debugoverlay.Line(self:GetPos(), self:GetPos() + Vector(0, 0, 200), 0.1, Color(0,255,0),true)
		--	render.SetMaterial(self.IMaterial)
		--	self.IMesh:Draw()
		--	mat:SetVector("$color", Vector(1, 1, 1))
		--	self:DrawModel()
			
		--	if not AABBAABB and self.Vertices then
		--		AABBAABB = self.Vertices
		--	end
	--	end
	else
		self:DrawModel()
	end
end
