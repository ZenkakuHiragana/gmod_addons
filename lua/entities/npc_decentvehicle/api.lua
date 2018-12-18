
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

local dvd = DecentVehicleDestination
function ENT:GetVehicleForward()
	if self.v.IsScar then
		return self.v:GetForward()
	elseif self.v.IsSimfphyscar then
		return self.v:LocalToWorldAngles(self.v.VehicleData.LocalAngForward):Forward()
	else
		return self.v:GetForward()
	end
end

function ENT:GetVehicleRight()
	if self.v.IsScar then
		return self.v:GetRight()
	elseif self.v.IsSimfphyscar then
		return self.v:LocalToWorldAngles(self.v.VehicleData.LocalAngForward):Right()
	else
		return self.v:GetRight()
	end
end

function ENT:GetVehicleUp()
	if self.v.IsScar then
		return self.v:GetUp()
	elseif self.v.IsSimfphyscar then
		return self.v:LocalToWorldAngles(self.v.VehicleData.LocalAngForward):Up()
	else
		return self.v:GetUp()
	end
end

function ENT:GetTraceFilter()
	local filter = {self, self.v}
	if self.v.IsScar then
		table.Add(filter, self.v.Seats)
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
	elseif VC then
		return self.v:VC_getStates().RunningLights
	end
end

function ENT:GetFogLights()
	if self.v.IsScar then
		return self.v:GetNWBool "HeadlightsOn"
	elseif self.v.IsSimfphyscar then
		return self.SimfphysFogLights
	elseif VC then
		return self.v:VC_getStates().FogLights
	end
end

function ENT:GetLights(highbeams)
	if self.v.IsScar then
		return self.v:GetNWBool "HeadlightsOn"
	elseif self.v.IsSimfphyscar then
		return Either(highbeams, self.v:GetLampsEnabled(), self.v:GetLightsEnabled())
	elseif VC then
		local states = self.v:VC_getStates()
		return Either(highbeams, states.HighBeams, states.LowBeams)
	end
end

function ENT:GetTurnLight(left)
	if self.v.IsScar then -- Does SCAR have turn lights?
	elseif self.v.IsSimfphyscar then
		return Either(left, self.TurnLightLeft, self.TurnLightRight)
	elseif VC then
		local states = self.v:VC_getStates()
		return Either(left, states.TurnLightLeft, states.TurnLightRight)
	end
end

function ENT:GetHazardLights()
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		return self.HazardLights
	elseif VC then
		return self.v:VC_getStates().HazardLights
	end
end

function ENT:GetELS()
	if self.v.IsScar then
		return self.v.SirenIsOn
	elseif self.v.IsSimfphyscar then
		return self.v:GetEMSEnabled()
	elseif VC then
		return self.v:VC_getELSLightsOn()
	end
end

function ENT:GetELSSound()
	if self.v.IsScar then
		return self.v.SirenSound and self.v.SirenSound:IsPlaying()
	elseif self.v.IsSimfphyscar then
		return self.v.ems and self.v.ems:IsPlaying()
	elseif VC then
		self.v:VC_getELSSoundOn()
	end
end

function ENT:GetHorn()
	if self.v.IsScar then
		return self.v.Horn:IsPlaying()
	elseif self.v.IsSimfphyscar then
		return self.v.HornKeyIsDown
	elseif VC then
		
	end
end

function ENT:GetEngineStarted()
	if self.v.IsScar then
		return self.v.IsOn
	elseif self.v.IsSimfphyscar then
		return self.v:EngineActive()
	else
		return self.v:IsEngineStarted()
	end
end

function ENT:SetRunningLights(on)
	if on == self:GetRunningLights() then return end
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		self.SimfphysRunningLights = on
		self.v:SetFogLightsEnabled(not on)
		numpad.Activate(self, KEY_V, false)
		self.keystate = nil
	elseif VC then
		self.v:VC_setRunningLights(on)
	end
end

function ENT:SetFogLights(on)
	if on == self:GetFogLights() then return end
	if self.v.IsScar then
	elseif self.v.IsSimfphyscar then
		self.SimfphysFogLights = on
		self.v:SetFogLightsEnabled(not on)
		numpad.Activate(self, KEY_V, false)
		self.keystate = nil
	elseif VC then
		self.v:VC_setFogLights(on)
	end
end

local function SCAREmulateKey(self, key, state, func, ...)
	local dummy = player.GetByID(1)
	local dummyinput = dummy.ScarSpecialKeyInput
	self.v.AIController = dummy
	dummy.ScarSpecialKeyInput = {[key] = state}
	if isfunction(func) then func(self.v, ...) end
	self.v.AIController = self
	dummy.ScarSpecialKeyInput = dummyinput
end

function ENT:SetLights(on, high)
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
		
		if on and high ~= self:GetLights(true) then
			self.v.LampsActivated = not high
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
	elseif VC then
		if on == self:GetLights(high) then return end
		if high then
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
	elseif VC then
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
	elseif VC then
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
	elseif VC then
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
	elseif VC then
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
	elseif VC then
		
	end
end

function ENT:SetEngineStarted(on)
	if on == self:GetEngineStarted() then return end
	if self.v.IsScar then
		if on then
			self.v:TurnOnCar()
		else
			self.v:TurnOffCar()
		end
	elseif self.v.IsSimfphyscar then
		self.v:SetActive(on)
		if on then
			self.v:StartEngine()
		else
			self.v:StopEngine()
		end
	else
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
