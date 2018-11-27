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
ENT.WaypointList = {} -- For navigation
ENT.SteeringInt = 0 -- Steering integration
ENT.SteeringOld = 0 -- Steering difference = (diff - self.SteeringOld) / FrameTime()
ENT.ThrottleInt = 0 -- Throttle integration
ENT.ThrottleOld = 0 -- Throttle difference = (diff - self.ThrottleOld) / FrameTime()
ENT.Prependicular = 0 -- If the next waypoint needs to turn quickly, this is close to 1.
ENT.WaitUntilNext = CurTime()

local KphToHUps = 1000 * 3.2808399 * 16 / 3600
local sPID = Vector(2.2, 0, .5) -- PID parameters of steering
local tPID = Vector(1, 0, 0) -- PID parameters of throttle
local dvd = DecentVehicleDestination
local DetectionRange = CreateConVar("decentvehicle_detectionrange", 30,
FCVAR_ARCHIVE, "Decent Vehicle: A vehicle within this distance will drive automatically.")

-- Get angle between vector A and B.
local function GetDeg(A, B)
	return A:GetNormalized():Dot(B:GetNormalized())
end

-- Get angle between vector AB and BC.
local function GetDeg3(A, B, C)
	return dvd.GetAng(B - A, C - B)
end

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
	throttle = math.Clamp(throttle, -1, 1)
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

function ENT:SetSteering(steering)
	steering = math.Clamp(steering, -1, 1)
	self.Steering = steering
	if self.v.IsScar then
		if steering > 0 then
			self.v:TurnRight(steering)
		elseif steering < 0 then
			self.v:TurnLeft(-steering)
		else
			self.v:NotTurning()
		end
	elseif self.v.IsSimfphyscar then
		local s = self.v:GetVehicleSteer()
		self.v:PlayerSteerVehicle(self, -math.min(steering, 0), math.max(steering, 0))
		self.v.PressedKeys.A = steering < -.01 and steering < s and s < 0
		self.v.PressedKeys.D = steering > .01 and 0 < s and s < steering
		
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
		self.v:SetSteering(steering, 0)
		
		if VC and self.Waypoint then
			local states = self.v:VC_getStates()
			if self.Waypoint.UseTurnLights then
				if steering >= .2 and not states.TurnLightRightOn then
					self.v:VC_setTurnLightRight(true)
					return
				elseif steering <= -.2 and not states.TurnLightLeftOn then
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

function ENT:IsDestroyed()
	if self.v.IsScar then
		return self.v:IsDestroyed()
	elseif self.v.IsSimfphyscar then
		return self.v:GetCurHealth() <= 0
	elseif VC and isfunction(self.v.VC_GetHealth) then
		return self.v:VC_GetHealth(false) <= 0
	end
end

function ENT:GetCurrentMaxSpeed()
	local destlength = self.Waypoint.Target:Distance(self.v:WorldSpaceCenter())
	local maxspeed = self.Waypoint.SpeedLimit
	if self.PrevWaypoint then
		local total = self.Waypoint.Target:Distance(self.PrevWaypoint.Target)
		local frac = (1 - destlength / total)^2
		if self.NextWaypoint then -- The speed limit is affected by connected waypoints
			maxspeed = Lerp(frac, maxspeed, self.NextWaypoint.SpeedLimit)
		end
		
		-- If the waypoint has a sharp corner, slow down
		maxspeed = maxspeed * Lerp(frac, 1, 1 - self.Prependicular)
	end
	
	-- If the vehicle is turning sharply, slow down
	maxspeed = maxspeed * math.max(.2, 1 - math.abs(self.Steering))
	return math.Clamp(maxspeed, 1, self.MaxSpeed)
end

function ENT:IsValidVehicle()
	if not IsValid(self.v) then return end -- The tied vehicle goes NULL.
	if not self.v:IsVehicle() then return end -- Somehow it become non-vehicle entity.
	if not self.v.DecentVehicle then return end -- Somehow it's a normal vehicle.
	if self ~= self.v.DecentVehicle then return end -- It has a different driver.
	if self.v:WaterLevel() > 1 then return end -- It falls into water.
	if self:IsDestroyed() then return end -- It is destroyed.
	return true
end

function ENT:ShouldStop()
	if not self.Waypoint then return true end
	if CurTime() < self.WaitUntilNext then return true end
	if not self.PrevWaypoint then return end
	if not self.PrevWaypoint.TrafficLight then return end
	if self.PrevWaypoint.TrafficLight:GetNWInt "DVTL_LightColor" == 3 then return true end
end

function ENT:StopDriving()
	self:SetHandbrake(true)
	self:SetThrottle(0)
	self:SetSteering(0)
	self.SteeringInt, self.SteeringOld = 0, 0
	self.ThrottleInt, self.ThrottleOld = 0, 0
	
	if self.Waypoint then return end
	local w = dvd.GetNearestWaypoint(self.v:GetPos())
	if not w then return end
	
	local nw = dvd.Waypoints[w.Neighbors[math.random(#w.Neighbors)] or -1]
	if not nw then return end
	
	self.Waypoint = table.remove(self.WaypointList, 1) or w
	self.NextWaypoint = table.remove(self.WaypointList, 1) or self.Waypoint == w and nw or nil
end

-- Drive the vehicle toward ENT.Waypoint.Target.
-- Returning:
--   bool arrived	| Has the vehicle arrived at the current destination.
function ENT:DriveToWaypoint()
	if not self.Waypoint then return end
	local sPID = dvd.PID.Steering[self.v:GetClass()] or sPID
	local tPID = dvd.PID.Throttle[self.v:GetClass()] or tPID
	local throttle = 1 -- The output throttle
	local steering = 0 -- The output steering
	local handbrake = false -- The output handbrake
	local targetpos = self.Waypoint.Target
	local forward = self:GetVehicleForward()
	local vehiclepos = self.v:WorldSpaceCenter()
	local velocity = self.v:GetVelocity()
	local currentspeed = velocity:Dot(forward)
	local dest = targetpos - vehiclepos
	local destlength = dest:Length()
	local todestination = dest:GetNormalized()
	local maxspeed = self:GetCurrentMaxSpeed()
	local relspeed = currentspeed / maxspeed
	local cross = todestination:Cross(forward)
	
	local steering_angle = math.asin(cross:Dot(self.v:GetUp())) / math.pi * 2
	local steering_differece = (steering_angle - self.SteeringOld) / FrameTime()
	self.SteeringInt = self.SteeringInt + steering_angle * FrameTime()
	self.SteeringOld = steering_angle
	steering = sPID.x * steering_angle + sPID.y * self.SteeringInt + sPID.z * steering_differece
	
	local speed_difference = maxspeed - currentspeed
	local throttle_difference = (speed_difference - self.ThrottleOld) / FrameTime()
	self.ThrottleInt = self.ThrottleInt + speed_difference * FrameTime()
	self.ThrottleOld = speed_difference
	throttle = tPID.x * speed_difference + tPID.y * self.ThrottleInt + tPID.z * throttle_difference
	
	-- Prevents from going backward
	local goback = forward:Dot(todestination)
	local velocitydot = dvd.GetAng(velocity, forward)
	if goback < 0 and destlength > self.MaxRevSpeed / 2 then
		throttle, steering = .2, steering > 0 and -1 or 1
	end
	
	-- Handbrake when intending to go backward and actually moving forward or vise-versa
	handbrake = goback * velocitydot < 0 
	
	self:SetHandbrake(handbrake)
	self:SetThrottle(throttle * (goback < 0 and -1 or 1))
	self:SetSteering(steering)
	
	return targetpos:Distance(vehiclepos) < math.max(self.v:BoundingRadius(), currentspeed * math.max(0, velocitydot) * .5)
end

function ENT:Think()
	self:NextThink(CurTime())
	if not self:IsValidVehicle() then SafeRemoveEntity(self) return end
	if self:ShouldStop() then self:StopDriving() return true end
	debugoverlay.Sphere(self.Waypoint.Target, 50, .1, Color(0, 255, 0))
	if not self:DriveToWaypoint() then return true end
	-- When it arrives at the current waypoint.
	self.WaitUntilNext = CurTime() + (self.Waypoint.WaitUntilNext or 0)
	self.PrevWaypoint = self.Waypoint
	self.Waypoint = self.NextWaypoint
	if self.Waypoint then
		self.NextWaypoint = table.remove(self.WaypointList, 1) or dvd.GetRandomNeighbor(self.Waypoint, self.v:GetPos())
	end
	
	self.Prependicular = 1
	if self.Waypoint and self.NextWaypoint and self.PrevWaypoint then
		self.Prependicular = 1 - dvd.GetAng3(self.PrevWaypoint.Target, self.Waypoint.Target, self.NextWaypoint.Target)
	end
	
	return true
end

function ENT:Initialize()
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
	
	self:SetParent(self.v)
	self:GetVehicleParams()
	self:SetNoDraw(true)
	self:SetMoveType(MOVETYPE_NONE)
	self.WaypointList = {}
	self.v:DeleteOnRemove(self)
	hook.Run("PlayerEnteredVehicle", self, self.v)
	
	-- A* pathfinding test
	timer.Simple(1, function()
		if not (IsValid(self) and IsValid(self.v)) then return end
		self.WaypointList = dvd.GetRouteVector(self.v:GetPos(), Entity(1):GetEyeTrace().HitPos)
		self.Waypoint, self.PrevWaypoint, self.NextWaypoint = nil
	end)
end

function ENT:OnRemove()
	if not (IsValid(self.v) and self.v:IsVehicle()) then return end
	self.v:DontDeleteOnRemove(self)
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
	return vehicle.DecentVehicle and role ~= 0 or nil
end)
