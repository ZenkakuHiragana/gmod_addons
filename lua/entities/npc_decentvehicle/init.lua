AddCSLuaFile "cl_init.lua"
AddCSLuaFile "shared.lua"
AddCSLuaFile "playermeta.lua"
include "shared.lua"
include "playermeta.lua"

ENT.Throttle = 0
ENT.Steering = 0
ENT.HandBrake = false
ENT.Waypoint = nil
ENT.NextWaypoint = nil
ENT.PrevWaypoint = nil
ENT.RecentSpeed = 0
ENT.RecentSpeedHistory = {}
ENT.RecentSpeedIndex = 1
ENT.RecentSteer = 0
ENT.RecentSteerHistory = {}
ENT.RecentSteerIndex = 1
ENT.Prependicular = 0
ENT.WaitUntilNext = CurTime()

local dvd = DecentVehicleDestination
local RecentCount = 20
local DetectionRange = CreateConVar("decentvehicle_detectionrange", 30,
FCVAR_ARCHIVE, "Decent Vehicle: A vehicle within this distance will drive automatically.")

function ENT:GetVehicleForward()
	if self.v.IsScar then
		return self.v:GetForward()
	elseif self.v.IsSimfphyscar then
		return self.v:LocalToWorldAngles(self.v.VehicleData.LocalAngForward):Forward()
	else
		return self.v:GetForward()
	end
end

function ENT:SetHandbrake(brake)
	self.HandBrake = brake
	if self.v.IsScar then
		if brake then
			self.v:HandBrakeOn()
		else
			self.v:HandBrakeOff()
		end
	elseif self.v.IsSimfphyscar then
		self.v.PressedKeys.Space = brake
	elseif isfunction(self.v.SetHandbrake) then
		self.v:SetHandbrake(brake)
	end
end

function ENT:SetThrottle(throttle)
	self.Throttle = throttle
	if self.v.IsScar then
		if throttle > 0 then
			self.v:GoForward(throttle)
		elseif throttle < 0 then
			self.v:GoBack(-throttle)
		else
			self.v:GoNeutral()
		end
	elseif self.v.IsSimfphyscar then
		self.v.PressedKeys.W = throttle > .01
		self.v.PressedKeys.S = throttle < -.01
	elseif isfunction(self.v.SetThrottle) then
		self.v:SetThrottle(throttle)
	end
end

function ENT:SetSteering(steer)
	self.Steering = steer
	if self.v.IsScar then
		if steer > 0 then
			self.v:TurnRight(steer)
		elseif steer < 0 then
			self.v:TurnLeft(-steer)
		else
			self.v:NotTurning()
		end
	elseif self.v.IsSimfphyscar then
		local s = self.v:GetVehicleSteer()
		self.v:PlayerSteerVehicle(self, -math.min(steer, 0), math.max(steer, 0))
		self.v.PressedKeys.A = steer < -.01 and steer < s and s < 0
		self.v.PressedKeys.D = steer > .01 and 0 < s and s < steer
		
		if self.Waypoint then
			if self.Waypoint.UseTurnLights then
				if s >= .5 and not self.v.Light_R then
					net.Start "simfphys_turnsignal"
					net.WriteEntity(self.v)
					net.WriteInt(3, 32)
					net.Broadcast()
					self.v.Light_R = true
					return
				elseif s <= -.5 and not self.v.Light_L then
					net.Start "simfphys_turnsignal"
					net.WriteEntity(self.v)
					net.WriteInt(2, 32)
					net.Broadcast()
					self.v.Light_L = true
					return
				end
			end
			
			net.Start "simfphys_turnsignal"
			net.WriteEntity(self.v)
			net.WriteInt(0, 32)
			net.Broadcast()
			self.v.Light_R = nil
			self.v.Light_L = nil
		end
	elseif isfunction(self.v.SetSteering) then
		self.v:SetSteering(steer, 0)
		
		if VC and self.Waypoint then
			local states = self.v:VC_getStates()
			if self.Waypoint.UseTurnLights then
				if self.RecentSteer >= .2 and not states.TurnLightRightOn then
					self.v:VC_setTurnLightRight(true)
					return
				elseif self.RecentSteer <= -.2 and not states.TurnLightLeftOn then
					self.v:VC_setTurnLightLeft(true)
					return
				end
			end
			
			if states.TurnLightRightOn then
				self.v:VC_setTurnLightRight(false)
			end
			
			if states.TurnLightLeftOn then
				self.v:VC_setTurnLightLeft(false)
			end
		end
	end
end

function ENT:GetDriverPos()
	if self.v.IsScar then
		local seat = self.v.Seats[1]
		return seat:GetPos(), seat:GetAngles() + Angle(0, 90, 0)
	elseif self.v.IsSimfphyscar then
		local seat = self.v.DriverSeat
		return seat:GetPos(), seat:GetAngles() + Angle(0, 90, 0)
	else
		local att = self.v:LookupAttachment "vehicle_feet_passenger0"
		if not att then return end
		att = self.v:GetAttachment(att)
		return att.Pos, att.Ang
	end
end

function ENT:GetVehicleParams()
	if self.v.IsScar then
		self.BrakePower = self.v.BreakForce / 1000
		self.MaxSpeed = self.v.MaxSpeed
		self.MaxRevSpeed = self.v.ReverseMaxSpeed
		self.MaxSteeringAngle = self.v.SteerForce
	elseif self.v.IsSimfphyscar then
		self.BrakePower = self.v:GetBrakePower()
		self.MaxSpeed = self.v.Mass * self.v.Efficiency * self.v.PeakTorque / self.v.MaxGrip
		self.MaxRevSpeed = self.MaxSpeed * math.abs(math.min(unpack(self.v.Gears)) / math.max(unpack(self.v.Gears)))
		self.MaxSteeringAngle = self.v.VehicleData.steerangle
	elseif isfunction(self.v.GetVehicleParams) then
		local params = self.v:GetVehicleParams()
		local axles = params.axles
		local engine = params.engine
		local steering = params.steering
		self.BrakePower = 0
		for _, axle in ipairs(axles) do
			self.BrakePower = self.BrakePower + axle.brakeFactor
		end
		
		self.MaxSpeed = engine.maxSpeed or 100
		self.MaxRevSpeed = engine.maxRevSpeed or 100
		self.MaxSteeringAngle = steering.degreesSlow or 45
	end
	
	print("Brake Power: ", self.BrakePower)
	print("Max Speed: ", self.MaxSpeed)
	print("Max Reverse Speed: ", self.MaxRevSpeed)
	print("Max Steering Angle: ", self.MaxSteeringAngle)
end

function ENT:GetNextWaypoint()
	local suggestion = {}
	for i, n in ipairs(self.Waypoint.Neighbors) do
		local w = dvd.Waypoints[n]	
		if w and (self.Waypoint.Target - self.v:GetPos()):Dot(w.Target - self.Waypoint.Target) > 0 then
			table.insert(suggestion, dvd.Waypoints[n])
		end
	end
	
	return suggestion[math.random(#suggestion)]
end

function ENT:Think()
	if not IsValid(self.v) or -- The tied vehicle goes NULL.
		not self.v:IsVehicle() or -- Somehow it become non-vehicle entity.
		not self.v.DecentVehicle or -- Somehow it's a normal vehicle.
		-- self.v:GetDriver() ~= self.v.DecentVehicle or -- It has an driver.
		self:WaterLevel() > 1 or -- It fall into water.
		(self.v.IsScar and (self.v:IsDestroyed() or self.v.Fuel <= 0)) or -- It's SCAR and destroyed or out of fuel.
		(self.v.IsSimfphyscar and (self.v:GetCurHealth() <= 0)) or -- It's Simfphys Vehicle and destroyed.
		(VC and self.v:GetClass() == "prop_vehicle_jeep" and self.v:VC_GetHealth(false) < 1) then -- VCMod adds health system to vehicles.
		SafeRemoveEntity(self) -- Then go back to normal.
		return
	end
	
	local velocity = self.v:GetVelocity()
	local speed = self.RecentSpeed / self.MaxSpeed
	local steer = 0
	local currentspeed = velocity:Length()
	if not self.Waypoint or CurTime() < self.WaitUntilNext
	or (self.PrevWaypoint and self.PrevWaypoint.TrafficLight
	and self.PrevWaypoint.TrafficLight:GetNWInt "DVTL_LightColor" == 3) then
		-- Stop moving.
		self:SetHandbrake(true)
		self:SetThrottle(0)
		self:SetSteering(0)
		
		if not self.Waypoint then
			local Nearest = dvd.GetNearestWaypoint(self:GetPos())
			if Nearest then
				local NextWaypoint = dvd.Waypoints[Nearest.Neighbors[math.random(#Nearest.Neighbors)] or -1]
				if NextWaypoint then
					self.Waypoint = Nearest
					self.NextWaypoint = NextWaypoint
				end
			end
		end
	else
		local ph = self.v:GetPhysicsObject()
		if not IsValid(ph) then return end
		
		-- Drive the vehicle.
		local forward = self:GetVehicleForward()
		local dist = self.Waypoint.Target - self.v:WorldSpaceCenter() -- Distance between the vehicle and the destination.
		local distLength2D = dist:Length2D()
		local dir = dist:GetNormalized() -- Direction vector of the destination.
		local orientation = dir:Dot(forward)
		local throttle = orientation > 0 and 1 or -1 -- Throttle depends on their positional relationship.
		local limit = self.Waypoint.SpeedLimit
		limit = (limit + (self.NextWaypoint and self.NextWaypoint.SpeedLimit or limit)) / 2
		limit = math.min(self.MaxSpeed, limit)
		
		local handbrake = distLength2D < self.RecentSpeed / limit * self.Prependicular * orientation / self.BrakePower
		if self.Waypoint.TrafficLight
		and self.Waypoint.TrafficLight:GetNWInt "DVTL_LightColor" > 1 then
			limit = limit / 2
		end
		
		throttle = throttle * (1 - currentspeed / limit)
		if distLength2D < self.MaxSpeed * 5
		and currentspeed / limit * self.Prependicular * orientation > .5 then
			throttle = 0
		end
		
		if handbrake and speed > .1 then
			throttle = velocity:Dot(forward) < 0 and 1 or -1
		end
		
		-- Set steering parameter.
		local right = dir:Cross(forward) -- The destination is right side or not.
		local dirdot = dir:Dot(velocity)
		local steer_amount = right:Length()^.8 -- Steering parameter.
		steer = right.z > 0 and steer_amount or -steer_amount --Actual steering parameter.
		if speed > .05 and dirdot < -.12 then
			steer = steer * -1
		end
		
		if math.abs(orientation) < .1
		or orientation < 0
		and distLength2D > self.MaxRevSpeed then
			steer, throttle = right.z > 0 and -1 or 1, -.5
		end
		
		self:SetHandbrake(handbrake)
		self:SetThrottle(throttle)
		if ph:GetAngleVelocity().y < 120 then -- If the vehicle is spinning, don't change.
			self:SetSteering(steer)
		end
		
		print(
		"Throttle: " .. math.Round(throttle, 1),
		"Steering: " .. math.Round(steer, 1),
		"HandBrake: " .. tostring(handbrake),
		"Speed: " .. math.Round(self.RecentSpeed, 1))
		debugoverlay.Sphere(self.Waypoint.Target, 50, .2, Color(0, 255, 0))
		if distLength2D < math.max(self.v:BoundingRadius(), self.RecentSpeed * math.max(0, velocity:GetNormalized():Dot(forward)) * .5) then
			self.WaitUntilNext = CurTime() + (self.Waypoint.WaitUntilNext or 0)
			self.PrevWaypoint = self.Waypoint
			self.Waypoint = self.NextWaypoint
			if self.Waypoint then
				self.NextWaypoint = self:GetNextWaypoint()
			end
		end
	end
	
	self.RecentSpeedHistory[self.RecentSpeedIndex] = currentspeed
	self.RecentSpeedIndex = self.RecentSpeedIndex % RecentCount + 1
	self.RecentSteerHistory[self.RecentSteerIndex] = steer
	self.RecentSteerIndex = self.RecentSteerIndex % RecentCount + 1
	self.RecentSpeed, self.RecentSteer = 0, 0
	for i = 1, #self.RecentSpeedHistory do
		self.RecentSpeed = self.RecentSpeed + self.RecentSpeedHistory[i]
	end
	
	for i = 1, #self.RecentSteerHistory do
		self.RecentSteer = self.RecentSteer + self.RecentSteerHistory[i]
	end
	
	self.RecentSpeed = self.RecentSpeed / #self.RecentSpeedHistory	
	self.RecentSteer = self.RecentSteer / #self.RecentSteerHistory
	self.Prependicular = 1 - (self.PrevWaypoint and self.Waypoint and self.NextWaypoint and
	(self.Waypoint.Target - self.PrevWaypoint.Target):GetNormalized():Dot((self.NextWaypoint.Target - self.Waypoint.Target):GetNormalized()) or 0)
end

function ENT:Initialize()
	self:SetModel(self.Modelname)
	self:SetMoveType(MOVETYPE_NONE)
	self:PhysicsInit(SOLID_BBOX)
	self.RecentSpeedHistory = {}
	
	-- Pick up a vehicle in the given sphere.
	local distance = DetectionRange:GetFloat()
	for k, v in pairs(ents.FindInSphere(self:GetPos(), distance)) do
		if v:IsVehicle() and not v.DecentVehicle then
			if v.IsScar then -- If it's a SCAR.
				if not v:HasDriver() then -- If driver's seat is empty.
					self.v = v
					self.OldSpecialThink = v.SpecialThink
					v.AIController = self
					v.SpecialThink = function() end -- Tanks or something sometimes make errors so disable thinking.
					v.DecentVehicle = self
				end
			elseif v.IsSimfphyscar and v:IsInitialized() then -- If it's a Simfphys Vehicle.
				if not IsValid(v:GetDriver()) then -- Fortunately, Simfphys Vehicles can use GetDriver()
					self.v = v
					v.DecentVehicle = self
					v.RemoteDriver = self
				end
			elseif isfunction(v.EnableEngine) and isfunction(v.StartEngine) then -- Normal vehicles should use these functions. (SCAR and Simfphys cannot.)
				if isfunction(v.GetWheelCount) and v:GetWheelCount() and not IsValid(v:GetDriver()) then
					self.v = v
					v:EnableEngine(true)
					v:StartEngine(true)
					v.DecentVehicle = self
				end
			end
		end
	end
	
	if not IsValid(self.v) then SafeRemoveEntity(self) return end
	
	local e = EffectData()
	e:SetEntity(self.v)
	util.Effect("propspawn", e) -- Perform a spawn effect.
	
	local seatpos, seatang = self:GetDriverPos()
	self:SetSequence "drive_jeep"
	self:SetPos(seatpos)
	self:SetAngles(seatang)
	self:SetParent(self.v)
	
	local min, max = self.v:GetHitBoxBounds(0, 0) -- NPCs aim at the top of the vehicle referred by hit box.
	if not isvector(max) then min, max = self.v:GetModelBounds() end -- If getting hit box bounds is failed, get model bounds instead.
	if not isvector(max) then max = vector_up * math.random(80, 200) end -- If even getting model bounds is failed, set a random value.
	self.moving = CurTime()
	
	local tr = util.TraceHull({start = self.v:GetPos() + vector_up * max.z, 
		endpos = self.v:GetPos(), ignoreworld = true,
		mins = Vector(-16, -16, -1), maxs = Vector(16, 16, 1)})
	self.CollisionHeight = tr.HitPos.z - self.v:GetPos().z
	if self.CollisionHeight < 10 then self.CollisionHeight = max.z end
	self.v:DeleteOnRemove(self)
	
	self:GetVehicleParams()
	hook.Run("PlayerEnteredVehicle", self, self.v)
end

function ENT:OnRemove()
	if not (IsValid(self.v) and self.v:IsVehicle()) then return end
	self.v.DecentVehicle = nil
	if self.v.IsScar then -- If the vehicle is SCAR.
		self.v.AIController = nil
		self.v.SpecialThink, self.OldSpecialThink = self.OldSpecialThink or self.v.SpecialThink
		self.v.GetDriver, self.v.OldGetDriver = self.v.OldGetDriver or self.v.GetDriver
		if not self.v:HasDriver() then -- If there's no driver, stop the engine.
			self.v:TurnOffCar()
			self.v:HandBrakeOn()
			self.v:GoNeutral()
			self.v:NotTurning()
		end
	elseif self.v.IsSimfphyscar then -- The vehicle is Simfphys Vehicle.
		self.v.RemoteDriver = nil
		self.v:SetActive(false)
		self.v:StopEngine()
		
		self.v.PressedKeys.W = false
		self.v.PressedKeys.A = false
		self.v.PressedKeys.S = false
		self.v.PressedKeys.D = false
		self.v.PressedKeys.Shift = false
		self.v.PressedKeys.Space = false
		
		self.v.Light_R = false
		self.v.Light_L = false
		net.Start "simfphys_turnsignal"
		net.WriteEntity(self.v)
		net.WriteInt(0, 32)
		net.Broadcast()
	elseif not IsValid(self.v:GetDriver()) and -- The vehicle is normal vehicle.
		isfunction(self.v.StartEngine) and isfunction(self.v.SetHandbrake) and 
		isfunction(self.v.SetThrottle) and isfunction(self.v.SetSteering) then
		self.v:StartEngine(false) -- Reset states.
		self.v:SetHandbrake(true)
		self.v:SetThrottle(0)
		self.v:SetSteering(0, 0)
	end
	
	local e = EffectData()
	e:SetEntity(self.v)
	util.Effect("propspawn", e) -- Perform a spawn effect.
	
	hook.Run("PlayerLeaveVehicle", self, self.v)
end

hook.Add("CanPlayerEnterVehicle", "Decent Vehicle: Occupy the driver seat", function(ply, vehicle, role)
	if not vehicle.DecentVehicle then return end
	return role ~= 0
end)
