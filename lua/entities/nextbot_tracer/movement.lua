
local ___DEBUG_DRAW_PATH = true
local ___DEBUG_DRAW_MOVEPOINT = true
local ___DEBUG_SHOW_PATHNAME = true

ENT.MaxYawRate = 250 --default: 250
ENT.Speed = {}
ENT.Speed.Run = 315						--approximately 6 m/s, player default: 200
ENT.Speed.RunSqr = ENT.Speed.Run^2
ENT.Speed.Walk = ENT.Speed.Run / 2		--player default: 60 
ENT.Speed.WalkSqr = ENT.Speed.Walk^2
ENT.Speed.Crouched = ENT.Speed.Run / 2	--player default: 60
ENT.Speed.CrouchedSqr = ENT.Speed.Crouched^2
ENT.Speed.Acceleration = 1600			--default: 400
ENT.Speed.Deceleration = 1600			--default: 400

function ENT:StartMove()
	if not isvector(self.Path.DesiredPosition) then return end
	self.Path.Main:Invalidate()
	self.Path.Main:Compute(self, self.Path.DesiredPosition)
end

function ENT:UpdatePosition()
	if not self.Path.Main:IsValid() then return end
	if ___DEBUG_DRAW_PATH then self.Path.Main:Draw() end
	self.Path.Main:Update(self)
	
	if self.loco:IsStuck() then
		self.Path.Main:Invalidate()
		self.Path.DesiredPosition = self:GetPos()
	end
	
	return self.Path.Main:IsValid()
end

function ENT:GotoRandomPosition(distance)
	local destination = Vector(distance or 700, 0, 0)
	destination:Rotate(Angle(0, math.Rand(-180, 180), 0))
	self.Path.DesiredPosition = destination
	local nav = navmesh.GetNearestNavArea(self.Path.DesiredPosition)
	if not nav or not self.loco:IsAreaTraversable(nav) then
		self.Path.DesiredPosition = self:GetPos()
	end
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
	local spots = navmesh.Find(self:GetPos(), self.Dist.FindSpots, self.loco:GetDeathDropHeight(), self.loco:GetStepHeight())
	local vResult, NearestDistance = vector_origin, (opt.nearest and math.huge or 0)
	local path = Path("Follow")
	for index, area in pairs(spots) do --Check NavAreas near the nextbot.
		if index > self.MaxNavAreas then break end --There're too many NavAreas, then break.
		if isfunction(opt.evaluation) and opt.evaluation(self, area, opt) or --Do a evaluate function.
			self.FindSpotDefaultParameters.evaluation(self, area, opt) then
			path:Invalidate()
			path:Compute(self, area:GetCenter()) --Calcuate the length to reach.
			if path:IsValid() then
				local length = path:GetLength() < NearestDistance
				if not opt.nearest then length = not length end
				if length then
					NearestDistance = path:GetLength()
					vResult = area:GetCenter()
					if ___DEBUG_DRAW_MOVEPOINT then
						debugoverlay.Line(area:GetCenter(), area:GetCenter() - vector_up * self.EyeHeight, 5, Color(0,255,0,255))
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
		if ___DEBUG_SHOW_PATHNAME then print("SpotType: " .. (opt or self.FindSpotDefaultParameters).spottype) end
		self.Path.DesiredPosition = pos
		return true
	end
end
