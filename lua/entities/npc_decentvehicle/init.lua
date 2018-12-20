
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile "cl_init.lua"
AddCSLuaFile "shared.lua"
AddCSLuaFile "playermeta.lua"
include "shared.lua"
include "playermeta.lua"
include "api.lua"

ENT.sPID = Vector(4, 0, 0) -- PID parameters for steering
ENT.tPID = Vector(1, 0, 0) -- PID parameters for throttle
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
ENT.RefuelThreshold = .25 -- If the fuel is less than this fraction, the vehicle finds a fuel station.
ENT.MaxSpeedCoefficient = 1 -- Multiplying this on the maximum speed of the vehicle.
ENT.UseLeftTurnLight = false -- Which turn light the vehicle should turn on.
ENT.Emergency = CurTime()

-- Extra variables for traces.
ENT.InsideRoute = 0
ENT.StopByTrace = CurTime()
ENT.NextReleaseBrake = CurTime()

local dvd = DecentVehicleDestination
local vector_one = Vector(1, 1, 1)
local KmphToHUps = 1000 * 3.2808399 * 16 / 3600
local KmphToHUpsSqr = KmphToHUps^2
local TraceMax = 64
local TraceMinLength = 200
local TraceMinLengthSqr = TraceMinLength^2
local TraceThreshold = 10
local TraceHeightGap = 20 -- The distance between ground and the bottom of the trace
local GobackTime = 10 -- The time to start to go backward by the trace.
local GobackDuration = 0.7 -- The duration of going backward by the trace.
local VCModFixedAroundNPCDriver = false -- This is a stupid solution.
local NightSkyTextureList = {
	sky_borealis01 = true,
	sky_day01_09 = true,
	sky_day02_09 = true,
}

local CVarFlags = {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED}
local TimeToStopEmergency = CreateConVar("decentvehicle_timetostopemergency", 5,
CVarFlags, "Decent Vehicle: Time to turn off hazard lights in seconds.")
local ShouldGoToRefuel = CreateConVar("decentvehicle_gotorefuel", 1,
CVarFlags, "Decent Vehicle: 1: Go to a fuel station to refuel.  0: Refuel automatically.")
local DetectionRange = CreateConVar("decentvehicle_detectionrange", 30,
CVarFlags, "Decent Vehicle: A vehicle within this distance will drive automatically.")
local DetectELS = CreateConVar("decentvehicle_elsrange", 300,
CVarFlags, "Decent Vehicle: Detection range of finding cars with ELS to give way.")
local DriveSide = CreateConVar("decentvehicle_driveside", 0,
CVarFlags, [[Decent Vehicle: Determines which side of road Decent Vehicles think.
0: Right (Europe, America, etc.)
1: Left (UK, Australia, etc.)]])

local function GetNight()
	if StormFox then return StormFox.IsNight() end
	local skyname = GetConVar "sv_skyname" :GetString()
	return NightSkyTextureList[skyname]
	or tobool(skyname:lower():find "night")
end

local function GetFogInfo()
	local FogEditor = ents.FindByClass "edit_fog"
	for i, f in ipairs(FogEditor) do
		if istable(FogEditor) or FogEditor:EntIndex() < f:EntIndex() then
			FogEditor = f
		end
	end
	
	if IsValid(FogEditor) then return true, FogEditor:GetFogEnd() end
	if not StormFox then
		local FogController = ents.FindByClass "env_fog_controller"
		for i, f in ipairs(FogController) do
			if istable(FogController) or FogController:EntIndex() < f:EntIndex() then
				FogController = f
			end
		end
		
		if not IsValid(FogController) then return false, 0 end
		local keyvalues = FogController:GetKeyValues()
		return keyvalues.fogenable > 0, keyvalues.fogend
	end
	
	local enabled = GetConVar "sf_enablefog"
	return enabled and enabled:GetBool()
	and StormFox.GetWeather() == "Fog", StormFox.GetData "Fogend"
end

function ENT:CarCollide(data)
	self = self.v and self or self.DecentVehicle
	if not self then return end
	if data.Speed > 200 and not data.HitEntity:IsPlayer() then
		self.Emergency = CurTime() + (self.EmergencyDuration or TimeToStopEmergency:GetFloat())
	end
	
	hook.Run("Decent Vehicle: OnCollide", self, data)
end

function ENT:EstimateAccel()
	local accel = 0
	if self.v.IsScar then
		local phys = self.v:GetPhysicsObject()
		local velVec = phys:GetVelocity()
		local vel = velVec:Length()
		local dir = velVec:Dot(self:GetForward())
		local force = 1
		if self.v.DriveStatus == 1 then -- Brake or forward
			if dir < 0 and vel > 40 then -- BRAKE
				force = self.v.BreakForce
			elseif self.v.IsOn and vel < self.v.MaxSpeed and self.v:HasFuel() then -- FORWARD
				force = self.v.Acceleration
			end
		else -- Brake or reverse
			if dir > vel * .9 and vel > 10 then -- BRAKE
				force = self.v.BreakForce * 1.5
			elseif self.v.IsOn and vel < self.v.ReverseMaxSpeed and self.v:HasFuel() then -- REVERSE
				force = self.v.ReverseForce		
			end
		end
		
		accel = math.max(force * self.v.WheelTorqTraction, 1)
	elseif self.v.IsSimfphyscar then
		accel = self.v:GetMaxTorque() * 2 - math.Clamp(self.v.ForwardSpeed, -self.v.Brake, self.v.Brake)
	else
		local forward = self.v:GetForward()
		local gearratio = self.GearRatio[self.v:GetOperatingParams().gear + 1]
		local numwheels = self.v:GetWheelCount()
		local wheelangvelocity = 0
		local wheeldirvelocity = 0
		local damping, rotdamping = 0, 0
		for i = 0, numwheels - 1 do
			local w = self.v:GetWheel(i)
			wheelangvelocity = wheelangvelocity + math.rad(math.abs(w:GetAngleVelocity().x)) / numwheels
			wheeldirvelocity = wheeldirvelocity + w:GetVelocity():Dot(forward) / numwheels
		end
		
		for i, a in ipairs(self.v:GetVehicleParams().axles) do
			damping = damping + a.wheels_damping * wheeldirvelocity / a.wheels_mass
			rotdamping = rotdamping + a.wheels_rotdamping * wheelangvelocity
		end
		
		accel = 552 * (self.HorsePower * self.AxleRatio * gearratio - rotdamping * math.sqrt(2))
		* self.WheelCoefficient / self.Mass - damping * math.sqrt(2) + physenv.GetGravity():Dot(forward)
	end
	
	return hook.Run("Decent Vehicle: EstimateAccel", self, accel) or accel
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
		local body = params.body
		local engine = params.engine
		local steering = params.steering
		self.BrakePower = 0
		self.AxleFactor = 0
		self.Mass = body.massOverride
		self.WheelRadius = 0
		local minr, maxr = math.huge, -math.huge
		for _, axle in ipairs(axles) do
			self.BrakePower = self.BrakePower + axle.brakeFactor
			self.AxleFactor = self.AxleFactor + axle.torqueFactor / axle.wheels_radius
			self.Mass = self.Mass + axle.wheels_mass * params.wheelsPerAxle
			self.WheelRadius = self.WheelRadius + axle.wheels_radius / #axles
			minr, maxr = math.min(minr, axle.wheels_radius), math.max(maxr, axle.wheels_radius)
		end
		
		self.WheelRatio = minr / maxr
		self.WheelCoefficient = 1 / math.sqrt(self.WheelRadius * self.WheelRatio)
		self.MaxSpeed = engine.maxSpeed or 100
		self.MaxRevSpeed = engine.maxRevSpeed or 100
		self.MaxSteeringAngle = steering.degreesSlow or 45
		self.HorsePower = engine.horsepower
		self.GearCount = engine.gearCount
		self.GearRatio = engine.gearRatio
		self.AxleRatio = engine.axleRatio
	end
	
	print("Brake Power: ", self.BrakePower)
	print("Max Speed: ", self.MaxSpeed)
	print("Max Reverse Speed: ", self.MaxRevSpeed)
	print("Max Steering Angle: ", self.MaxSteeringAngle)
end

function ENT:GetVehiclePrefix()
	if self.v.IsScar then
		return "SCAR_"
	elseif self.v.IsSimfphyscar then
		return "Simfphys_"
	else
		return "Source_"
	end
end

function ENT:GetVehicleIdentifier()
	local id = ""
	if self.v.IsScar then
		id = self.v:GetClass()
	elseif self.v.IsSimfphyscar then
		id = self.v:GetModel()
	else
		id = self.v:GetModel()
	end
	
	return self:GetVehiclePrefix() .. id
end

function ENT:AttachModel()
	local seat = self.v
 	if self.v.IsScar then
 		seat = self.v.Seats and self.v.Seats[1]
 	elseif self.v.IsSimfphyscar then
		seat = self.v.DriverSeat
 	end
	
	if not IsValid(seat) then return end
	local a = seat:LookupAttachment "vehicle_driver_eyes"
	local att = seat:GetAttachment(assert(a, "Decent Vehicle: attachment vehicle_feet_passenger0 is not found!"))
	local delta = dvd.SeatPos[self:GetVehicleIdentifier()]or dvd.SeatPos[self:GetVehiclePrefix()] or Vector(-8, 0, -32)
	local seatang = seat:WorldToLocalAngles(att.Ang)
	local seatpos = seat:WorldToLocal(att.Pos
	+ att.Ang:Forward() * delta.x + att.Ang:Right() * delta.y + att.Ang:Up() * delta.z)
	self:SetModel(istable(self.Model) and self.Model[math.random(#self.Model)]
	or self.Model or dvd.DefaultDriverModel[math.random(#dvd.DefaultDriverModel)])
	self:SetSequence "drive_jeep"
	self:SetParent(seat)
	self:SetSeat(seat)
	self:SetSeatPos(seatpos)
	self:SetSeatAng(seatang)
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
		maxspeed = maxspeed * Lerp(frac, 1, 1 - self.Prependicular * .9)
		
		if self.Waypoint.TrafficLight and self.Waypoint.TrafficLight:GetNWInt "DVTL_LightColor" == 3 then
			maxspeed = maxspeed * (1 - frac)
		end
	end
	
	maxspeed = maxspeed * Either(self.TraceWaypoint and self.TraceWaypoint.Hit, 1, (self.InsideRoute + 1.1) / 2)
	maxspeed = maxspeed * math.Clamp(self.MaxSpeedCoefficient, 0, 1)
	return hook.Run("Decent Vehicle: GetCurrentMaxSpeed", self, maxspeed)
	or math.Clamp(maxspeed, 1, self.MaxSpeed)
end

function ENT:IsValidVehicle()
	if not IsValid(self.v) then return end -- The tied vehicle goes NULL.
	if not self.v:IsVehicle() then return end -- Somehow it become non-vehicle entity.
	if not self.v.DecentVehicle then return end -- Somehow it's a normal vehicle.
	if not IsValid(self:GetSeat()) then return end -- It couldn't find the driver seat.
	if self ~= self.v.DecentVehicle then return end -- It has a different driver.
	if self.v:WaterLevel() > 1 then return end -- It falls into water.
	if self:IsDestroyed() then return end -- It is destroyed.
	return true
end

function ENT:AtTrafficLight()
	if self.FormLine then return true end
	if not self.PrevWaypoint then return end
	if not self.PrevWaypoint.TrafficLight then return end
	if self:GetVehicleForward():Dot(self.PrevWaypoint.Target - self.v:WorldSpaceCenter()) < 0 then return end
	if self.PrevWaypoint.TrafficLight:GetNWInt "DVTL_LightColor" == 3 then return true end
end

function ENT:ShouldStopGoingback()
	if self.FormLine then return end
	if IsValid(self.TraceBack.Entity) or self.TraceBack.HitWorld
	and self.TraceBack.HitNormal:Dot(vector_up) < .7 then
		self.StopByTrace = CurTime() + FrameTime() -- Reset going back timer
		return true
	end
	
	local ent = self.Trace.Entity
	if not (IsValid(ent) and ent.DecentVehicle) then return end
	
	ent = ent.DecentVehicle
	if ent:GetELS() then return true end
	if CurTime() > ent.WaitUntilNext then return end
	if CurTime() > ent.Emergency then return end
	return true
end

function ENT:ShouldStop()
	if not self.Waypoint then return true end
	if CurTime() < self.WaitUntilNext then return true end
	if CurTime() < self.Emergency then return true end
	if CurTime() > self.StopByTrace and CurTime() < self.StopByTrace + GobackTime then return true end
	if self:AtTrafficLight() then return true end
end

function ENT:ShouldRefuel()
	if self.v.IsScar then
		return self.v:GetFuelPercent() < self.RefuelThreshold
	elseif self.v.IsSimfphyscar then
		return self.v:GetFuel() / self.v:GetMaxFuel() < self.RefuelThreshold
	elseif VC then
		return self.v:VC_fuelGet(false) / self.v:VC_fuelGetMax() < self.RefuelThreshold
	end
end

function ENT:Refuel()
	hook.Run("Decent Vehicle: OnRefuel", self)
	if self.v.IsScar then
		self.v:Refuel()
	elseif self.v.IsSimfphyscar then
		self.v:SetFuel(self.v:GetMaxFuel())
	elseif VC then
		self.v:VC_fuelSet(self.v:VC_fuelGetMax())
	end
end

function ENT:FindFuelStation()
	local routes = select(2, dvd.GetFuelStations())
	local destinations = {}
	for i, id in ipairs(routes) do
		destinations[id] = true
	end
	
	local route = dvd.GetRoute(select(2, dvd.GetNearestWaypoint(self.Waypoint.Target)), destinations, self.Group)
	if not route then return end
	
	self.WaypointList = route
	return true
end

function ENT:FindRoute(routetype)
	if #self.WaypointList > 0 then return end
	if not isfunction(self["Find" .. routetype]) then return end
	if not self["Find" .. routetype](self) then return end
	self.NextWaypoint = table.remove(self.WaypointList)
end

function ENT:StopDriving()
	hook.Run("Decent Vehicle: StopDriving", self)
	self:SetHandbrake(true)
	self:SetThrottle(0)
	self:SetSteering(0)
	self.SteeringInt, self.SteeringOld = 0, 0
	self.ThrottleInt, self.ThrottleOld = 0, 0
	if IsValid(self.NPCDriver) then
		self.NPCDriver:SetSaveValue("m_vecDesiredPosition", vector_origin)
		self.NPCDriver:SetSaveValue("m_vecDesiredPosition", vector_origin)
	end
end

-- Drive the vehicle toward ENT.Waypoint.Target.
-- Returns:
--   bool arrived	| Has the vehicle arrived at the current destination.
function ENT:DriveToWaypoint()
	if not self.Waypoint then return end
	local sPID = dvd.PID.Steering[self:GetVehicleIdentifier()] or self.sPID
	local tPID = dvd.PID.Throttle[self:GetVehicleIdentifier()] or self.tPID
	local throttle = 1 -- The output throttle
	local steering = 0 -- The output steering
	local handbrake = false -- The output handbrake
	local targetpos = self.Waypoint.Target
	local forward = self:GetVehicleForward()
	local vehiclepos = self.v:WorldSpaceCenter()
	local velocity = self.v:GetVelocity()
	local velocitydot = velocity:Dot(forward)
	local currentspeed = math.abs(velocitydot)
	local dest = targetpos - vehiclepos
	local destlength = dest:Length()
	local todestination = dest:GetNormalized()
	local maxspeed = self:GetCurrentMaxSpeed()
	local relspeed = currentspeed / maxspeed
	local cross = todestination:Cross(forward)
	
	local steering_angle = math.asin(cross:Dot(self:GetVehicleUp())) / math.pi * 2
	local steering_differece = (steering_angle - self.SteeringOld) / FrameTime()
	self.SteeringInt = self.SteeringInt + steering_angle * FrameTime()
	self.SteeringOld = steering_angle
	steering = sPID.x * steering_angle + sPID.y * self.SteeringInt + sPID.z * steering_differece
	
	local estimateaccel = math.abs(self:EstimateAccel())
	local speed_difference = maxspeed - currentspeed
	local throttle_difference = (speed_difference - self.ThrottleOld) / FrameTime()
	self.ThrottleInt = self.ThrottleInt + speed_difference * FrameTime()
	self.ThrottleOld = speed_difference
	throttle = tPID.x * speed_difference + tPID.y * self.ThrottleInt + tPID.z * throttle_difference
	
	-- Prevents from going backward
	local goback = forward:Dot(todestination)
	local approach = velocity:Dot(todestination) / velocity:Length()
	-- Handbrake when intending to go backward and actually moving forward or vise-versa
	goback = math.abs(goback) > .1 and goback < 0 and -1 or 1
	handbrake = currentspeed > 10 and goback * velocitydot < 0 or currentspeed > math.max(100, maxspeed * .2) and math.abs(approach) < .5
	
	if goback < 0 then
		steering = steering > 0 and -1 or 1
	elseif handbrake and not (self.v.IsScar or self.v.IsSimfphyscar) then
		steering = -steering
	end
	
	local GobackByTrace = CurTime() - self.StopByTrace - GobackTime
	if not self:ShouldStopGoingback() and 0 < GobackByTrace and GobackByTrace < GobackDuration then
		goback = -1
		handbrake = false
		steering = -steering
	else
		if GobackByTrace > GobackDuration then
			self.StopByTrace = CurTime() + FrameTime() -- Reset going back timer
		end
	
		if not (self.v.IsScar or self.v.IsSimfphyscar) and velocitydot * goback * throttle < 0 then
			throttle = 0 -- The solution of the brake issue.
		end
	end
	
	if IsValid(self.NPCDriver) then
		local desiredvelocity = todestination * maxspeed
		self.NPCDriver:SetSaveValue("m_vecDesiredPosition", self.Waypoint.Target)
		self.NPCDriver:SetSaveValue("m_vecDesiredVelocity", desiredvelocity)
	end
	
	self:SetHandbrake(handbrake)
	self:SetThrottle(math.Clamp(throttle / estimateaccel, -1, 1) * goback)
	self:SetSteering(steering)
	
	debugoverlay.Sphere(self.Waypoint.Target, 50, .1, Color(0, 255, 0))
	
	hook.Run("Decent Vehicle: Drive", self)
	return targetpos:Distance(vehiclepos) < math.max(self.v:BoundingRadius(), math.max(0, velocitydot) * self.Prependicular)
end

function ENT:DoLights()
	local fogenabled, fogend = GetFogInfo()
	local fog = fogenabled and fogend < 5000
	self:SetRunningLights(self:GetEngineStarted())
	self:SetLights(GetNight() or fog, fog)
	self:SetFogLights(fog)
	self:SetTurnLight(self.Waypoint and self.Waypoint.UseTurnLights or false, self.UseLeftTurnLight)
	self:SetHazardLights(CurTime() < self.Emergency)
end

function ENT:DoTrace()
	if not self.Waypoint then return end
	local prevwaypoint = self.PrevWaypoint
	local nextwaypoint = self.NextWaypoint
	local filter = self:GetTraceFilter()
	local forward = self:GetVehicleForward()
	local up = self:GetVehicleUp()
	local vehiclepos = self.v:WorldSpaceCenter()
	local velocity = self.v:GetVelocity()
	local tracedir = Vector(velocity)
	if velocity:LengthSqr() > TraceMinLengthSqr then
		tracedir:Normalize()
	else
		tracedir = forward
	end
	
	local velocitydot = velocity:Dot(tracedir)
	local currentspeed = math.abs(velocitydot)
	self.TraceLength = CurTime() > self.StopByTrace and self.TraceLength or math.max(TraceMinLength, currentspeed)
	local kmph = currentspeed / KmphToHUps
	local TraceGround = util.QuickTrace(vehiclepos, -vector_up * 32768, filter)
	local groundpos = TraceGround.HitPos
	local height = (vehiclepos.z - groundpos.z) / math.sqrt(2)
	local maxs = vector_one * math.min(TraceMax, height)
	local mins = -maxs
	local start = groundpos + vector_up * (height + TraceHeightGap)
	
	local tr = {
		start = start,
		endpos = start + tracedir * self.TraceLength,
		maxs = maxs, mins = mins,
		filter = filter,
	}
	self.Trace = util.TraceHull(tr)
	debugoverlay.SweptBox(tr.start, tr.endpos,
	tr.mins, tr.maxs, angle_zero, .05, Color(0, 255, 0))
	
	local trback = {
		start = start,
		endpos = start - tracedir * self.TraceLength / 2,
		maxs = maxs, mins = mins,
		filter = filter,
	}
	self.TraceBack = util.TraceHull(trback)
	debugoverlay.SweptBox(trback.start, trback.endpos,
	trback.mins, trback.maxs, angle_zero, .05, Color(255, 255, 0))
	
	local ent = self.Trace.Entity
	local waypointpos = nextwaypoint and nextwaypoint.Target or self.Waypoint and self.Waypoint.Target
	if waypointpos then
		local trwaypoint = {
			start = start,
			endpos = waypointpos + vector_up * (height + TraceHeightGap),
			maxs = maxs, mins = mins,
			filter = filter,
		}
		self.TraceWaypoint = util.TraceHull(trwaypoint)
		debugoverlay.SweptBox(trwaypoint.start, trwaypoint.endpos,
		trwaypoint.mins, trwaypoint.maxs, angle_zero, .05, Color(0, 255, 255))
	end
	
	if prevwaypoint and nextwaypoint then
		local direction = dvd.GetDir(prevwaypoint.Target, self.Waypoint.Target)
		self.InsideRoute = direction:Cross(dvd.GetDir(prevwaypoint.Target, nextwaypoint.Target))
		:Dot(direction:Cross(dvd.GetDir(prevwaypoint.Target, vehiclepos)))
	end
	
	if not IsValid(ent) or self.Trace.HitWorld and self.Trace.HitNormal:Dot(vector_up) > .7 then
		if CurTime() < self.StopByTrace + GobackTime then
			self.StopByTrace = CurTime() + .1
		end
		
		self.FormLine = false
	else
		local dv = ent.DecentVehicle
		self.FormLine = dv and dv:AtTrafficLight()
		
		if dv and dv.Trace and dv.Trace.Entity == self.v and dv:EntIndex() < self:EntIndex() then
			self.StopByTrace = CurTime() + .1
		end
	end
	
	debugoverlay.SweptBox(tr.start, self.Trace.HitPos, tr.mins, tr.maxs, angle_zero, .05)
	
	hook.Run("Decent Vehicle: Trace", self, ent)
end

function ENT:DoGiveWay()
    for k, ent in pairs(ents.FindInSphere(self:GetPos(), DetectELS:GetInt())) do
		if ent == self.v then continue end
		local side = self:GetVehicleRight():Dot(ent:GetPos() - self.v:WorldSpaceCenter())
		local els = ent.IsScar and ent.SirenIsOn
		or ent.IsSimfphyscar and ent:GetEMSEnabled()
		or VC and (ent:VC_getELSLightsOn() or ent:VC_getELSSoundOn() or ent:VC_getStates().ELS_ManualOn)

		if not els then continue end
		if DriveSide:GetBool() then continue end
		if side < 0 then
			self:SetSteering(.5)
			self:SetThrottle(0)
			 timer.Simple(.5, function()
				if not IsValid(self) then return end
				if not IsValid(ent) then return end
				if not els then return end
				self:SetHandbrake(true)
			 end)
		else
			self:SetHandbrake(true)
		end
    end
end

function ENT:FindFirstWaypoint()
	if self.Waypoint then return end
	if #self.WaypointList > 0 then
		self.Waypoint = table.remove(self.WaypointList)
		self.NextWaypoint = table.remove(self.WaypointList)
		return
	end
	
	local pos = self.v:GetPos()
	self.Waypoint = dvd.GetNearestWaypoint(pos, self.Group)
	if not self.Waypoint then return end
	
	self.NextWaypoint = dvd.GetRandomNeighbor(self.Waypoint, pos, self.Group)
	if not self.NextWaypoint and self.Waypoint.Target:Distance(pos) < self.v:BoundingRadius() then
		self.Waypoint = nil
	end
end

function ENT:SetupNextWaypoint()
	self.WaitUntilNext = CurTime() + (self.Waypoint.WaitUntilNext or 0)
	if self.NextWaypoint and self.NextWaypoint.UseTurnLights then
		local prevpos = self.v:WorldSpaceCenter()
		if self.PrevWaypoint then prevpos = self.PrevWaypoint.Target end
		self.UseLeftTurnLight = (self.Waypoint.Target - prevpos):Cross(
		self.NextWaypoint.Target - self.Waypoint.Target):Dot(self:GetVehicleUp()) > 0
	end
	
	self.PrevWaypoint, self.Waypoint = self.Waypoint, self.NextWaypoint
	if not self.Waypoint then return end
	self.NextWaypoint = table.remove(self.WaypointList) or dvd.GetRandomNeighbor(self.Waypoint, self.v:GetPos(), self.Group)
	self.Prependicular = 0
	if self.NextWaypoint and self.PrevWaypoint then
		self.Prependicular = 1 - dvd.GetAng3(self.PrevWaypoint.Target, self.Waypoint.Target, self.NextWaypoint.Target)
	end
end

function ENT:Think()
	if not self:IsValidVehicle() then SafeRemoveEntity(self) return end
	if self:ShouldStop() then
		self:StopDriving()
		self:FindFirstWaypoint()
	elseif self:DriveToWaypoint() then -- When it arrives at the current waypoint.
		hook.Run("Decent Vehicle: OnReachedWaypoint", self)
		if self.Waypoint.FuelStation then self:Refuel() end
		
		self:SetupNextWaypoint()
	elseif self:ShouldRefuel() then
		if ShouldGoToRefuel:GetBool() then
			self:FindRoute "FuelStation"
		else
			self:Refuel()
		end
	end
	
	self:DoGiveWay()
	self:DoTrace()
	self:DoLights()
	self:NextThink(CurTime())
	self:SetPos(self:GetSeat():LocalToWorld(self:GetSeatPos()))
	self:SetAngles(self:GetSeat():LocalToWorldAngles(self:GetSeatAng()))
	return true
end

function ENT:Initialize()
	-- Pick up a vehicle in the given sphere.
	local mindistance, vehicle = math.huge
	for k, v in pairs(ents.FindInSphere(self:GetPos(), DetectionRange:GetFloat())) do
		if not v:IsVehicle() then continue end
		local d = self:GetPos():DistToSqr(v:GetPos())
		if d > mindistance then continue end
		mindistance, vehicle = d, v
	end
	
	if not IsValid(vehicle) then SafeRemoveEntity(self) return end
	
	self.v = vehicle
	local locked = self:GetLocked()
	self.v = nil
	
	if locked then SafeRemoveEntity(self) return end
	if vehicle.DecentVehicle then
		SafeRemoveEntity(self)
		SafeRemoveEntity(vehicle.DecentVehicle)
		vehicle.DecentVehicle = nil
		return
	end
	
	if vehicle.IsScar and not vehicle:HasDriver() then
		self.v, vehicle.DecentVehicle = vehicle, self
		self.OldSpecialThink = self.v.SpecialThink
		self.v.AIController = self
		self.v.SpecialThink = function() end -- Tanks or something sometimes make errors so disable thinking.
	elseif vehicle.IsSimfphyscar and vehicle:IsInitialized() and not IsValid(vehicle:GetDriver()) then
		self.v, vehicle.DecentVehicle = vehicle, self
		self.HeadLightsID = numpad.OnUp(self, KEY_F, "k_lgts", self.v, false)
		self.FogLightsID = numpad.OnDown(self, KEY_V, "k_flgts", self.v, true)
		self.ELSID = numpad.OnUp(self, KEY_H, "k_hrn", self.v, false)
		self.HornID = numpad.OnDown(self, KEY_H, "k_hrn", self.v, true)
		self.v.RemoteDriver = self
		
		self.OldPhysicsCollide = self.v.PhysicsCollide
		function self.v.PhysicsCollide(...)
			self.CarCollide(...)
			return self.OldPhysicsCollide(...)
		end
	elseif isfunction(vehicle.GetWheelCount) and vehicle:GetWheelCount() -- Not a chair
	and isfunction(vehicle.IsEngineEnabled) and vehicle:IsEngineEnabled() -- Engine is not locked
	and not IsValid(vehicle:GetDriver()) then
		self.v, vehicle.DecentVehicle = vehicle, self
		self.OnCollideCallback = self.v:AddCallback("PhysicsCollide", self.CarCollide)
		
		if not VC or VCModFixedAroundNPCDriver then
			local oldname = self.v:GetName()
			self.v:SetName "decentvehicle"
			self.NPCDriver = ents.Create "npc_vehicledriver"
			self.NPCDriver:Spawn()
			self.NPCDriver:SetKeyValue("Vehicle", "decentvehicle")
			self.NPCDriver:Activate()
			self.NPCDriver:Fire "StartForward"
			self.NPCDriver:Fire("SetDriversMaxSpeed", "100")
			self.NPCDriver:Fire("SetDriversMinSpeed", "0")
			self.NPCDriver.InVehicle = self.InVehicle
			function self.NPCDriver.KeyDown(_, key)
				return key == IN_FORWARD and self.Throttle > 0
				or key == IN_BACK and self.Throttle < 0
				or key == IN_MOVELEFT and self.Steering < 0
				or key == IN_MOVERIGHT and self.Steering > 0
				or key == IN_JUMP and self.HandBrake
				or false
			end
			self.v:SetName(oldname or "")
		end
	end
	
	if not IsValid(self.v) then SafeRemoveEntity(self) return end
	
	local e = EffectData()
	e:SetEntity(self.v)
	util.Effect("propspawn", e) -- Perform a spawn effect.
	self.WaypointList = {}
	self:AttachModel()
	self:GetVehicleParams()
	self:PhysicsInitShadow()
	self:DrawShadow(false)
	self:SetEngineStarted(true)
	self.v:DeleteOnRemove(self)
	self:SetELS(true)
end

function ENT:OnRemove()
	if not IsValid(self.v) then return end
	self.v:DontDeleteOnRemove(self)
	self.v.DecentVehicle = nil
	self:SetHandbrake(false)
	self:SetSteering(0)
	self:SetThrottle(0)
	self:SetRunningLights(false)
	self:SetFogLights(false)
	self:SetLights(false, false)
	self:SetLights(false, true)
	self:SetHazardLights(false)
	self:SetTurnLight(false, false)
	self:SetTurnLight(false, true)
	self:SetELS(false)
	self:SetELSSound(false)
	self:SetHorn(false)
	self:SetEngineStarted(false)
	self:SetLocked(false)
	
	if self.v.IsScar then -- If the vehicle is SCAR.
		self.v.AIController = nil
		self.v.SpecialThink, self.OldSpecialThink = self.OldSpecialThink
	elseif self.v.IsSimfphyscar then -- The vehicle is Simfphys Vehicle.
		self.v.PhysicsCollide, self.OldPhysicsCollide = self.OldPhysicsCollide
		self.v.RemoteDriver = nil
		self.v.PressedKeys.W = false
		self.v.PressedKeys.A = false
		self.v.PressedKeys.S = false
		self.v.PressedKeys.D = false
		self.v.PressedKeys.Space = false
		
		numpad.Remove(self.HeadLightsID)
		numpad.Remove(self.FogLightsID)
		numpad.Remove(self.ELSID)
		numpad.Remove(self.HornID)
	else
		self.v:RemoveCallback("PhysicsCollide", self.OnCollideCallback)
		if IsValid(self.NPCDriver) then
			self.NPCDriver:Fire "Stop"
			SafeRemoveEntity(self.NPCDriver)
		end
	end
	
	local e = EffectData()
	e:SetEntity(self.v)
	util.Effect("propspawn", e) -- Perform a spawn effect.
end

if not VC then return end -- WORKAROUND!!!
hook.Add("CanPlayerEnterVehicle", "Decent Vehicle: VCMod is not compatible with npc_vehicledriver", function(ply, vehicle, role)
	if vehicle.DecentVehicle and role == 1 then return false end
end)