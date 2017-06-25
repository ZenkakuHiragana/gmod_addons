
ENT.Speed = {}
ENT.Speed.Run = 315						--approximately 6 m/s, player default: 200
ENT.Speed.RunSqr = ENT.Speed.Run^2
ENT.Speed.Walk = ENT.Speed.Run / 2		--player default: 60 
ENT.Speed.WalkSqr = ENT.Speed.Walk^2
ENT.Speed.Crouched = ENT.Speed.Run / 2	--player default: 60
ENT.Speed.CrouchedSqr = ENT.Speed.Crouched^2
ENT.Speed.Acceleration = 5000			--default: 400
ENT.Speed.Deceleration = 5000			--default: 400

function ENT:StartMove()
	if not isvector(self.Path.DesiredPosition) then return end
	self.Path.Main:Invalidate()
	self.Path.Main:Compute(self, self.Path.DesiredPosition)
end

function ENT:UpdatePosition()
	if not self.Path.Main:IsValid() then return end
	if self.Debug.DrawPath then self.Path.Main:Draw() end
	
	if self.Path.Main:GetAge() > 8 then self.Path.Main:Compute(self, self.Path.DesiredPosition) end
	
	local seg = self.Path.Main:GetCurrentGoal()
	if seg then
		self.Memory.Jump = seg.area:HasAttributes(NAV_MESH_JUMP) or seg.type == 2
	end
	
	self.Path.Main:Update(self)
	
	if self.Memory.Jump then self.loco:Jump() end
	
	return self.Path.Main:IsValid()
end

function ENT:GotoRandomPosition(distance)
	local destination = Vector(distance or 700, 0, 0)
	destination:Rotate(Angle(0, math.Rand(-180, 180), 0))
	self.Path.DesiredPosition = self:GetPos() + destination
end

function ENT:GotoRandomDirection(dir, deg, dist)
	local destination = dir * (dist or 700)
	destination:Rotate(Angle(0, math.Rand(-deg, deg), 0))
	self.Path.DesiredPosition = self:GetPos() + destination
end

ENT.FindSpotDefaultParameters = {
	spottype = "Appear",
	see = true,
	nearest = true,
	evaluation = function(self, area, opt)
		local valid = self:CanSee(self.Memory.EnemyPosition, {start = area:GetCenter() + vector_up * self.EyeHeight})
		if not opt.see then valid = not valid end
		return valid
	end
}
function ENT:FindSpecifiedSpot(opt)
	local opt = istable(opt) and opt or self.FindSpotDefaultParameters
	local pos = vector_origin
	local range = opt.range or self.Dist.FindSpots
	local spots = navmesh.Find(self:GetPos(), range, self.loco:GetDeathDropHeight(), self.loco:GetStepHeight())
	local vResult, NearestDistance = vector_origin, (opt.nearest and math.huge or 0)
	local path = Path("Follow")
	for index, area in pairs(spots) do --Check NavAreas near the nextbot.
		if index > self.MaxNavAreas then break end --There're too many NavAreas, then break.
		if isfunction(opt.evaluation) and opt.evaluation(self, area, opt) or --Do a evaluate function.
			self.FindSpotDefaultParameters.evaluation(self, area, opt) then
			pos = area:GetRandomPoint()
			path:Invalidate()
			path:Compute(self, pos) --Calcuate the length to reach.
			if path:IsValid() then
				local length = opt.nearest and path:GetLength() < NearestDistance or path:GetLength() > NearestDistance
				if length then
					NearestDistance = path:GetLength()
					vResult = pos
					if self.Debug.DrawMoveSuggestions then
						debugoverlay.Line(pos, pos - vector_up * 400, 5, Color(0,255,0,255), true)
					end
				end
			end
		end
	end
	
	if vResult ~= vector_origin then
		return vResult
	end
end

function ENT:SetDesiredPosition(opt)
	local pos = self:FindSpecifiedSpot(opt)
	if isvector(pos) then
		if self.Debug.WritePathName then
			print("SpotType: " .. (opt or self.FindSpotDefaultParameters).spottype)
		end
		self.Path.DesiredPosition = pos
		return true
	end
end
