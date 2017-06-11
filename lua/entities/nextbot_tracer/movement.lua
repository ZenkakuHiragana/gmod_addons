
ENT.Speed = {}
ENT.Speed.Run = 315						--approximately 6 m/s, player default: 200
ENT.Speed.RunSqr = ENT.Speed.Run^2
ENT.Speed.Walk = ENT.Speed.Run / 2		--player default: 60 
ENT.Speed.WalkSqr = ENT.Speed.Walk^2
ENT.Speed.Crouched = ENT.Speed.Run / 2	--player default: 60
ENT.Speed.CrouchedSqr = ENT.Speed.Crouched^2
ENT.Speed.Acceleration = 800			--default: 400
ENT.Speed.Deceleration = 800			--default: 400

function ENT:StartMove()
	if not isvector(self.Path.DesiredPosition) then return end
	self.Path.Main:Invalidate()
	self.Path.Main:Compute(self, self.Path.DesiredPosition)
end

function ENT:UpdatePosition()
	self.Path.Main:Update(self)
	
	if self.loco:IsStuck() then
		self.Path.Main:Invalidate()
		self.Path.DesiredPosition = self:GetPos()
	end
	
	return self.Path.Main:IsValid()
end

function ENT:GotoRandomPosition()
	local destination = Vector(700, 0, 0)
	destination:Rotate(Angle(0, math.Rand(-180, 180), 0))
	self.Path.DesiredPosition = destination
	local nav = navmesh.GetNearestNavArea(self.Path.DesiredPosition)
	if not nav or not self.loco:IsAreaTraversable(nav) then
		self.Path.DesiredPosition = self:GetPos()
	end
end