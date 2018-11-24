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
ENT.SteeringInt = 0 -- Steering integration
ENT.SteeringOld = 0 -- Steering difference = (diff - self.SteerDiff) / FrameTime()
ENT.ThrottleInt = 0
ENT.ThrottleOld = 0
ENT.Prependicular = 0
ENT.WaitUntilNext = CurTime()

local KphToHUps = 1000 * 3.2808399 * 16 / 3600
local sPID = Vector(1.5, .2, .2) -- PID parameters of steering
local tPID = Vector(1, 0, 0) -- PID parameters of throttle
local dvd = DecentVehicleDestination
local DetectionRange = CreateConVar("decentvehicle_detectionrange", 30,
FCVAR_ARCHIVE, "Decent Vehicle: A vehicle within this distance will drive automatically.")

local function GetDiffNormal(v1, v2)
	return (v1 - v2):GetNormalized()
end

-- Get angle between vector AB and vector BC.
local function GetDeg(A, B, C)
	return GetDiffNormal(B, A):Dot(GetDiffNormal(C, B))
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
	self:NextThink(CurTime())
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
	
	if not self.Waypoint or CurTime() < self.WaitUntilNext
	or (self.PrevWaypoint and self.PrevWaypoint.TrafficLight
	and self.PrevWaypoint.TrafficLight:GetNWInt "DVTL_LightColor" == 3) then
		-- Stop moving.
		self:SetHandbrake(true)
		self:SetThrottle(0)
		self:SetSteering(0)
		self.SteeringInt, self.SteeringOld = 0, 0
		self.ThrottleInt, self.ThrottleOld = 0, 0
		
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
	else -- Drive the vehicle.
		local ph = self.v:GetPhysicsObject()
		if not IsValid(ph) then return end
		local sPID = dvd.PID.Steering[self.v:GetClass()] or sPID
		local tPID = dvd.PID.Throttle[self.v:GetClass()] or tPID
		local throttle = 1 -- The output throttle
		local steering = 0 -- The output steering
		local handbrake = false -- The output handbrake
		local velocity = self.v:GetVelocity()
		local currentspeed = velocity:Length()
		local vehiclepos = self.v:WorldSpaceCenter()
		local forward = self:GetVehicleForward()
		local dest = self.Waypoint.Target - vehiclepos
		local destlength = dest:Length()
		local todestination = dest:GetNormalized()
		local maxspeed = self.Waypoint.SpeedLimit
		if self.PrevWaypoint then
			local total = self.Waypoint.Target:Distance(self.PrevWaypoint.Target)
			local frac = (1 - destlength / total)^2
			if self.NextWaypoint then
				maxspeed = Lerp(frac, maxspeed, self.NextWaypoint.SpeedLimit)
			end
			
			maxspeed = maxspeed * Lerp(frac, 1, 1 - self.Prependicular)
		end
		
		maxspeed = math.min(maxspeed, self.MaxSpeed)
		local relspeed = currentspeed / maxspeed
		local cross = todestination:Cross(forward)
		local steering_dot = cross:Dot(self.v:GetUp())
		local steering_differece = (steering_dot - self.SteeringOld) / FrameTime()
		self.SteeringInt = self.SteeringInt + steering_dot * FrameTime()
		self.SteeringOld = steering_dot
		steering = sPID.x * steering_dot + sPID.y * self.SteeringInt + sPID.z * steering_differece
		
		local speed_difference = maxspeed - currentspeed
		local throttle_difference = (speed_difference - self.ThrottleOld) / FrameTime()
		self.ThrottleInt = self.ThrottleInt + speed_difference * FrameTime()
		self.ThrottleOld = speed_difference
		throttle = tPID.x * speed_difference + tPID.y * self.ThrottleInt + tPID.z * throttle_difference
		
		local goback = forward:Dot(todestination) < 0 and -1 or 1
		if goback < 0 and destlength > self.MaxRevSpeed then
			throttle, steering = .5, math.abs(steering) > .1 and (steering > 0 and -1 or 1) or 0
		end
		
		self:SetHandbrake(handbrake)
		self:SetThrottle(throttle * goback)
		self:SetSteering(steering)
		
		print("Throttle", math.Round(throttle, 3), "Steering", math.Round(steering, 3), "Max speed", math.Round(maxspeed / KphToHUps, 3), "Relative speed", math.Round(currentspeed / maxspeed, 5))
		debugoverlay.Sphere(self.Waypoint.Target, 50, .2, Color(0, 255, 0))
		
		if self.Waypoint.Target:Distance(vehiclepos) < math.max(self.v:BoundingRadius(),
		currentspeed * math.max(0, velocity:GetNormalized():Dot(forward)) * .5) then
			self.WaitUntilNext = CurTime() + (self.Waypoint.WaitUntilNext or 0)
			self.PrevWaypoint = self.Waypoint
			self.Waypoint = self.NextWaypoint
			if self.Waypoint then
				self.NextWaypoint = self:GetNextWaypoint()
			end
		end
	end
	
	self.Prependicular = 1
	if self.PrevWaypoint and self.Waypoint and self.NextWaypoint then
		self.Prependicular = 1 - GetDeg(self.PrevWaypoint.Target, self.Waypoint.Target, self.NextWaypoint.Target)
	end
	
	return true
end

function ENT:Initialize()
	self:SetModel(self.Modelname)
	self:SetMoveType(MOVETYPE_NONE)
	self:PhysicsInit(SOLID_BBOX)
	
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
