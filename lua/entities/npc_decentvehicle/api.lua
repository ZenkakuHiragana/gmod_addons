
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

local dvd = DecentVehicleDestination
local TurnonLights = CreateConVar("decentvehicle_turnonlights", 3, CVarFlags, dvd.Texts.CVars.TurnonLights)
local LIGHTLEVEL = {
	NONE = 0,
	RUNNING = 1,
	HEADLIGHTS = 2,
	ALL = 3,
}

function ENT:GetMaxSteeringAngle()
	if self.v.IsScar then
		return self.v.MaxSteerForce * 3 -- Obviously this is not actually steering angle
	elseif self.v.IsSimfphyscar then
		return self.v.VehicleData.steerangle
	else
		local mph = self.v:GetSpeed()
		if mph < self.SteeringSpeedFast then
			return Lerp((mph - self.SteeringSpeedSlow)
			/ (self.SteeringSpeedFast - self.SteeringSpeedSlow),
			self.SteeringAngleSlow, self.SteeringAngleFast)
		else
			return Lerp((mph - self.SteeringSpeedFast)
			/ (self.BoostSpeed - self.SteeringSpeedFast),
			self.SteeringAngleFast, self.SteeringAngleBoost)
		end
	end
end

function ENT:GetTraceFilter()
	local filter = {self, self.v}
	if self.v.IsScar then
		table.Add(filter, self.v.Seats or {})
		table.Add(filter, self.v.Wheels)
		table.Add(filter, self.v.StabilizerProp)
	elseif self.v.IsSimfphyscar then
		table.Add(filter, self.v.VehicleData.filter)
	else
		table.Add(filter, self.v:GetChildren())
	end
	
	return filter
end

function ENT:GetRunningLights()
	if self.v.IsScar then
		return self.v:GetNWBool "HeadlightsOn"
	elseif self.v.IsSimfphyscar then
		return self.SimfphysRunningLights
	elseif isfunction(self.v.VC_getStates) then
		local states = self.v:VC_getStates()
		return istable(states) and states.RunningLights
	end
end

function ENT:GetFogLights()
	if self.v.IsScar then
		return self.v:GetNWBool "HeadlightsOn"
	elseif self.v.IsSimfphyscar then
		return self.SimfphysFogLights
	elseif isfunction(self.v.VC_getStates) then
		local states = self.v:VC_getStates()
		return istable(states) and states.FogLights
	end
end

function ENT:GetLights(highbeams)
	if self.v.IsScar then
		return self.v:GetNWBool "HeadlightsOn"
	elseif self.v.IsSimfphyscar then
		return Either(highbeams, self.v:GetLampsEnabled(), self.v:GetLightsEnabled())
	elseif isfunction(self.v.VC_getStates) then
		local states = self.v:VC_getStates()
		return istable(states) and Either(highbeams, states.HighBeams, states.LowBeams)
	end
end

function ENT:GetTurnLight(left)
	if self.v.IsScar then -- Does SCAR have turn lights?
	elseif self.v.IsSimfphyscar then
		return Either(left, self.TurnLightLeft, self.TurnLightRight)
	elseif isfunction(self.v.VC_getStates) then
		local states = self.v:VC_getStates()
		return istable(states) and Either(left, states.TurnLightLeft, states.TurnLightRight)
	end
end

function ENT:GetHazardLights()
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		return self.HazardLights
	elseif isfunction(self.v.VC_getStates) then
		local states = self.v:VC_getStates()
		return istable(states) and states.HazardLights
	end
end

function ENT:GetELS(v)
	local vehicle = v or self.v
	if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
	if vehicle.IsScar then
		return vehicle.SirenIsOn
	elseif vehicle.IsSimfphyscar then
		return vehicle:GetEMSEnabled()
	elseif isfunction(vehicle.VC_getELSLightsOn) then
		return vehicle:VC_getELSLightsOn()
	end
end

function ENT:GetELSSound(v)
	local vehicle = v or self.v
	if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
	if vehicle.IsScar then
		return vehicle.SirenIsOn
	elseif vehicle.IsSimfphyscar then
		return vehicle.ems and vehicle.ems:IsPlaying()
	elseif isfunction(vehicle.VC_getELSSoundOn)
	and isfunction(vehicle.VC_getStates) then
		local states = vehicle:VC_getStates()
		return vehicle:VC_getELSSoundOn() or istable(states) and states.ELS_ManualOn
	end
end

function ENT:GetHorn(v)
	local vehicle = v or self.v
	if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
	if vehicle.IsScar then
		return vehicle.Horn:IsPlaying()
	elseif vehicle.IsSimfphyscar then
		return vehicle.HornKeyIsDown
	elseif isfunction(vehicle.VC_getStates) then
		local states = vehicle:VC_getStates()
		return istable(states) and states.HornOn
	end
end

function ENT:GetLocked(v)
	local vehicle = v or self.v
	if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
	if vehicle.IsScar then
		return vehicle:IsLocked()
	elseif vehicle.IsSimfphyscar then
		return vehicle.VehicleLocked
	else
		if isfunction(vehicle.VC_isLocked) then return vehicle:VC_isLocked() end
		return tonumber(vehicle:GetKeyValues().VehicleLocked) ~= 0
	end
end

function ENT:GetEngineStarted(v)
	local vehicle = v or self.v
	if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
	if vehicle.IsScar then
		return vehicle.IsOn
	elseif vehicle.IsSimfphyscar then
		return vehicle:EngineActive()
	else
		return vehicle:IsEngineStarted()
	end
end

function ENT:SetRunningLights(on)
	local lightlevel = TurnonLights:GetInt()
	on = on and lightlevel ~= LIGHTLEVEL.NONE
	if on == self:GetRunningLights() then return end
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		self.SimfphysRunningLights = on
		self.v:SetFogLightsEnabled(not on)
		numpad.Activate(self, KEY_V, false)
		self.keystate = nil
	elseif isfunction(self.v.VC_setRunningLights) then
		self.v:VC_setRunningLights(on)
	end
end

function ENT:SetFogLights(on)
	local lightlevel = TurnonLights:GetInt()
	on = on and lightlevel == LIGHTLEVEL.ALL
	if on == self:GetFogLights() then return end
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		self.SimfphysFogLights = on
		self.v:SetFogLightsEnabled(not on)
		numpad.Activate(self, KEY_V, false)
		self.keystate = nil
	elseif isfunction(self.v.VC_setFogLights) then
		self.v:VC_setFogLights(on)
	end
end

local function SCAREmulateKey(self, key, state, func, ...)
	local dummy = player.GetByID(1)
	local dummyinput = dummy.ScarSpecialKeyInput
	local controller = self.v.AIController
	self.v.AIController = dummy
	dummy.ScarSpecialKeyInput = {[key] = state}
	if isfunction(func) then func(self.v, ...) end
	self.v.AIController = controller
	dummy.ScarSpecialKeyInput = dummyinput
end

function ENT:SetLights(on, highbeams)
	local lightlevel = TurnonLights:GetInt()
	on = on and lightlevel >= LIGHTLEVEL.HEADLIGHTS
	if self.v.IsScar then
		if on == self:GetLights() then return end
		self.v.IncreaseFrontLightCol = not on
		SCAREmulateKey(self, "ToggleHeadlights", 3, self.v.UpdateLights)
	elseif self.v.IsSimfphyscar then
		local LightsActivated = self:GetLights()
		if on ~= LightsActivated then
			self.v.LightsActivated = not on
			self.v.KeyPressedTime = CurTime() - .23
			numpad.Deactivate(self, KEY_F, false)
		end
		
		if on and highbeams ~= self:GetLights(true) then
			self.v.LampsActivated = not highbeams
			self.v.KeyPressedTime = CurTime()
			self.v.NextLightCheck = CurTime()
			if LightsActivated then
				numpad.Deactivate(self, KEY_F, false)
			else
				timer.Simple(.05, function()
					if not (IsValid(self) and IsValid(self.v)) then return end
					numpad.Deactivate(self, KEY_F, false)
				end)
			end
		end
		
		self.keystate = nil
	elseif isfunction(self.v.VC_setHighBeams)
	and isfunction(self.v.VC_setLowBeams) then
		if on == self:GetLights(highbeams) then return end
		if highbeams then
			self.v:VC_setHighBeams(on)
		else
			self.v:VC_setLowBeams(on)
		end
	end
end

local SIMFPHYS = {OFF = 0, HAZARD = 1, LEFT = 2, RIGHT = 3}
function ENT:SetTurnLight(on, left)
	if on == self:GetTurnLight(left) then return end
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		net.Start "simfphys_turnsignal"
		net.WriteEntity(self.v)
		net.WriteInt(on and (left and SIMFPHYS.LEFT or SIMFPHYS.RIGHT) or SIMFPHYS.OFF, 32)
		net.Broadcast()
		self.TurnLightLeft = on and left
		self.TurnLightRight = on and not left
		self.HazardLights = false
	elseif isfunction(self.v.VC_setTurnLightLeft)
	and isfunction(self.v.VC_setTurnLightRight) then
		self.v:VC_setTurnLightLeft(on and left)
		self.v:VC_setTurnLightRight(on and not left)
	end
end

function ENT:SetHazardLights(on)
	if on == self:GetHazardLights() then return end
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		net.Start "simfphys_turnsignal"
		net.WriteEntity(self.v)
		net.WriteInt(on and SIMFPHYS.HAZARD or SIMFPHYS.OFF, 32)
		net.Broadcast()
		self.TurnLightLeft = false
		self.TurnLightRight = false
		self.HazardLights = true
	elseif isfunction(self.v.VC_setHazardLights) then
		self.v:VC_setHazardLights(on)
	end
end

function ENT:SetELS(on)
	if on == self:GetELS() then return end
	if self.v.IsScar then
		if self.v.SirenIsOn == nil then return end
		if not self.v.SirenSound then return end
		if on then self:SetHorn(false) end
		self.v.SirenIsOn = on
		self.v:SetNWBool("SirenIsOn", on)
		if on then
			self.v.SirenSound:Play()
		else
			self.v.SirenSound:Stop()	
		end
	elseif self.v.IsSimfphyscar then
		local dt = on and 0 or .5
		self.v.emson = not on
		self.v.KeyPressedTime = CurTime() - dt
		numpad.Deactivate(self, KEY_H, false)
	elseif isfunction(self.v.VC_setELSLights)
	and isfunction(self.v.VC_setELSSound) then
		self.v:VC_setELSLights(on)
		self.v:VC_setELSSound(on)
	end
end

function ENT:SetELSSound(on)
	if on == self:GetELSSound() then return end
	if self.v.IsScar then
		if not self.v.SirenSound then return end
		if on then
			self.v.SirenSound:Play()
		else
			self.v.SirenSound:Stop()
		end
	elseif self.v.IsSimfphyscar then
		if self.v.ems then
			if on and not self.v.ems:IsPlaying() then
				self.v.ems:Play()
			elseif not on and self.v.ems:IsPlaying() then
				self.v.ems:Stop()
			end
		end
	elseif isfunction(self.v.VC_setELSSound) then
		self.v:VC_setELSSound(on)
	end
end

function ENT:SetHorn(on)
	if on == self:GetHorn() then return end
	if self.v.IsScar then
		if on then
			self.v:HornOn()
		else
			self.v:HornOff()
		end
	elseif self.v.IsSimfphyscar then
		if on then
			numpad.Activate(self, KEY_H, false)
		else
			self.v.HornKeyIsDown = false
		end
	elseif isfunction(self.v.VC_getStates)
	and isfunction(self.v.VC_setStates) then
		local states = self.v:VC_getStates()
		if not istable(states) then return end
		states.HornOn = true
		self.v:VC_setStates(states)
	end
end

function ENT:SetLocked(locked)
	if locked == self:GetLocked() then return end
	if self.v.IsScar then
		if locked then
			self.v:Lock()
		else
			self.v:UnLock()
		end
	elseif self.v.IsSimfphyscar then
		if locked then
			self.v:Lock()
		else
			self.v:UnLock()
		end
	else
		for _, seat in pairs(self.v:GetChildren()) do -- For Sligwolf's vehicles
			if not (seat:IsVehicle() and seat.__SW_Vars) then continue end
			seat:Fire(locked and "Lock" or "Unlock")
		end
		
		if isfunction(self.v.VC_lock)
		and isfunction(self.v.VC_unLock) then
			if locked then
				self.v:VC_lock()
			else
				self.v:VC_unLock()
			end
		else
			self.v:Fire(locked and "Lock" or "Unlock")
		end
	end
end

function ENT:SetEngineStarted(on)
	if on == self:GetEngineStarted() then return end
	if self.v.IsScar then -- SCAR automatically starts the engine.
		self:SetLocked(not on)
		self.v.AIController = on and self or nil
		if not on then self.v:TurnOffCar() end
	elseif self.v.IsSimfphyscar then
		self.v:SetActive(on)
		if on then
			self.v:StartEngine()
		else
			self.v:StopEngine()
		end
	elseif isfunction(self.v.StartEngine) then
		self.v:StartEngine(on)
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
	elseif isfunction(self.v.SetSteering) then
		self.v:SetSteering(steering, 0)
	end
	
	local pose = self:GetPoseParameter "vehicle_steer" or 0
	self:SetPoseParameter("vehicle_steer", pose + (steering - pose) / 10)
end
