
include "shared.lua"

net.Receive("SplatoonSWEPs: Receive vertices info", function(len, ply)
	local self = net.ReadEntity()
	if not IsValid(self) or self.IMesh then return end
	local vert = net.ReadTable()
	self.Vertices = vert
end)

function ENT:Initialize()
	if not util.IsValidModel(self.FlyingModel) then
		chat.AddText("Splatoon SWEPs: Can't spawn ink!  Required model is not found!")
		return
	end
	
	self:SharedInit()
	self:SetInkColorProxy(VectorRand())
	self.IMaterial = Material("sprites/splatoonink.vmt")
	self.IMaterial:SetVector("$color", self:GetInkColorProxy())
end

function ENT:OnRemove()
	if IsValid(self.pr) then self.pr:Remove() end
	if self.IMesh then self.IMesh:Destroy() end
end

function ENT:Draw()
	if self:GetIsInk() then
		if not self.IMesh then
			if self.Vertices then
				self.IMesh = Mesh()
				self.IMesh:BuildFromTriangles(self.Vertices)
			end
		else
			debugoverlay.Line(self:GetPos(), self:GetPos() + Vector(0, 0, 200), 0.1, Color(0,255,0),true)
			render.SetMaterial(self.IMaterial)
			self.IMesh:Draw()
		--	mat:SetVector("$color", Vector(1, 1, 1))
		--	self:DrawModel()
		end
	else
		self:DrawModel()
	end
end
