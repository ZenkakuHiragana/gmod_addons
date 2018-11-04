AddCSLuaFile()
list.Set("NPC", "npc_decentvehicle", {
	Name = "Decent Vehicle",
	Class = "npc_decentvehicle",
	Category = "GreatZenkakuMan's NPCs"
})

DecentVehicleDestination = nil

ENT.Base = "base_entity"
ENT.Type = "ai"

ENT.PrintName = "Decent Vehicle"
ENT.Author = "Himajin Jichiku"
ENT.Contact = ""
ENT.Purpose = "Decent Vehicle."
ENT.Instruction = ""
ENT.Spawnable = false
ENT.Modelname = "models/props_wasteland/cargo_container01.mdl"

if SERVER then
	local DetectionRange = CreateConVar("madvehicle_detectionrange", 30, FCVAR_ARCHIVE, "Mad Vehicle: A vehicle within this distance will become mad.")
	local DeleteOnStuck = CreateConVar("madvehicle_deleteonstuck", 10, FCVAR_ARCHIVE, "Mad Vehicle: Deletes Mad Vehicle if it gets stuck for the given seconds. 0 to disable.")
	
	function ENT:OnRemove()
		--By undoing, driiving, diving in water, or getting stuck, and the vehicle is remaining.
		if IsValid(self.v) and self.v:IsVehicle() then
			self.v.MadVehicle = nil
			if self.v.IsScar then --If the vehicle is SCAR.
				self.v.HasDriver = self.v.BaseClass.HasDriver --Restore some functions.
				self.v.SpecialThink = self.v.BaseClass.SpecialThink
				if not self.v:HasDriver() then --If there's no driver, stop the engine.
					self.v:TurnOffCar()
					self.v:HandBrakeOn()
					self.v:GoNeutral()
					self.v:NotTurning()
				end
			elseif self.v.IsSimfphyscar then --The vehicle is Simfphys Vehicle.
				self.v.GetDriver = self.v.OldGetDriver or self.v.GetDriver
				if not IsValid(self.v:GetDriver()) then --If there's no driver, stop the engine.
					self.v:SetActive(false)
					self.v:StopEngine()
				end
				self.v.PressedKeys = self.v.PressedKeys or {} --Reset key states.
				self.v.PressedKeys["W"] = false
				self.v.PressedKeys["A"] = false
				self.v.PressedKeys["S"] = false
				self.v.PressedKeys["D"] = false
				self.v.PressedKeys["Shift"] = false
				self.v.PressedKeys["Space"] = false
			elseif not IsValid(self.v:GetDriver()) and --The vehicle is normal vehicle.
				isfunction(self.v.StartEngine) and isfunction(self.v.SetHandbrake) and 
				isfunction(self.v.SetThrottle) and isfunction(self.v.SetSteering) then
				self.v.GetDriver = self.v.OldGetDriver or self.v.GetDriver
				self.v:StartEngine(false) --Reset states.
				self.v:SetHandbrake(true)
				self.v:SetThrottle(0)
				self.v:SetSteering(0, 0)
			end
			
			local e = EffectData()
			e:SetEntity(self.v)
			util.Effect("propspawn", e) --Perform a spawn effect.
		end
	end
	
	function ENT:SetHandbrake(status)
		if self.v.IsScar then
			if status then
				self.v:HandBrakeOn()
			else
				self.v:HandBrakeOff()
			end
		elseif self.v.IsSimfphyscar then
			self.v:SetActive(true)
			self.v:StartEngine()
			self.v.PressedKeys = self.v.PressedKeys or {}
			self.v.PressedKeys["Space"] = status
		elseif isfunction(self.v.SetHandbrake) then
			self.v:SetHandbrake(status)
		end
	end
	
	function ENT:SetThrottle(throttle)
		if self.v.IsScar then
			if throttle > 0 then
				self.v:GoForward(throttle)
			elseif throttle < 0 then
				self.v:GoBack(-throttle)
			else
				self.v:GoNeutral()
			end
		elseif self.v.IsSimfphyscar then
			self.v:SetActive(true)
			self.v:StartEngine()
			self.v.PressedKeys = self.v.PressedKeys or {}
			self.v.PressedKeys["Shift"] = false
			self.v.PressedKeys["W"] = throttle > 0
			self.v.PressedKeys["S"] = throttle < 0
		elseif isfunction(self.v.SetThrottle) then
			self.v:SetThrottle(throttle)
		end
	end
	
	function ENT:SetSteering(steer)
		if self.v.IsScar then
			if steer > 0 then
				self.v:TurnRight(steer)
			elseif steer < 0 then
				self.v:TurnLeft(-steer)
			else
				self.v:NotTurning()
			end
		elseif self.v.IsSimfphyscar then
			self.v:SetActive(true)
			self.v:StartEngine()
			self.v:PlayerSteerVehicle(self, steer < 0 and -steer or 0, steer > 0 and steer or 0)
		elseif isfunction(self.v.SetSteering) then
			self.v:SetSteering(steer, 0)
		end
	end
	
	function ENT:Think()
		if not IsValid(self.v) or --The tied vehicle goes NULL.
			not self.v:IsVehicle() or --Somehow it become non-vehicle entity.
			not self.v.MadVehicle or --Somehow it's not mad.
			IsValid(self.v:GetDriver()) or --It has an driver.
			self:WaterLevel() > 1 or --It fall into water.
			(self.v.IsScar and (self.v:IsDestroyed() or self.v.Fuel <= 0)) or --It's SCAR and destroyed or out of fuel.
			(self.v.IsSimfphyscar and (self.v:GetCurHealth() <= 0)) or --It's Simfphys Vehicle and destroyed.
			(VC and self.v:GetClass() == "prop_vehicle_jeep" and self.v:VC_GetHealth(false) < 1) then -- VCMod adds health system to vehicles.
			SafeRemoveEntity(self) --Then go back to normal.
			return
		end
		
		self:SetPos(self.v:GetPos() + vector_up * self.CollisionHeight)
		if not DecentVehicleDestination or DecentVehicleDestination:Distance(self:GetPos()) < 100 then --If it doesn't have an enemy.
			--Stop moving.
			self:SetHandbrake(true)
			self:SetThrottle(0)
			self:SetSteering(0)
		else --It does.
			if self.v:GetVelocity():LengthSqr() > 40000 then --If it's moving, resets the stuck timer.
				self.moving = CurTime()
			end
			
			local timeout = GetConVar("madvehicle_deleteonstuck"):GetFloat()
			if timeout and timeout > 0 then
				if CurTime() > self.moving + timeout then --If it has got stuck for enough time.
					SafeRemoveEntity(self)
					return
				end
			end
			
			--Drive the vehicle.
			local forward = self.v.IsSimfphyscar and --Forward vector.
				self.v:LocalToWorldAngles(self.v.VehicleData.LocalAngForward):Forward() or self.v:GetForward()
			local dist = DecentVehicleDestination - self.v:WorldSpaceCenter() --Distance between the vehicle and the enemy.
			local vect = dist:GetNormalized() --Enemy direction vector.
			local vectdot = vect:Dot(self.v:GetVelocity()) --Dot product, velocity and direction.
			local throttle = dist:Dot(forward) > 0 and 1 or -1 --Throttle depends on their positional relationship.
			local right = vect:Cross(forward) --The enemy is right side or not.
			local steer_amount = right:Length()^0.8 --Steering parameter.
			local steer = right.z > 0 and steer_amount or -steer_amount --Actual steering parameter.
			if vectdot < -0.12 then steer = steer * -1 end
			
			--If the vehicle is too close to the enemy or the vehicle shouldn't go backward, invert the throttle.
			-- if (dist:Length2DSqr() < 250000 and vectdot < 0) then
				-- throttle = throttle * -1
			-- end
			
			-- throttle = throttle * math.Clamp(dist:Length2D() / (self.v:GetSpeed() * 100 + 1), 0, 1)
			
			self:SetHandbrake(false)
			if dist:Length2D() * .8 < self.v:GetVelocity():Length() + 50 then
				throttle = 0
				if dist:Length2D() < self.v:GetVelocity():Length() then
					self:SetHandbrake(true)
				end
			end
			print(throttle, dist:Length2D(), self.v:GetVelocity():Length())
			
			--Set steering parameter.
			local ph = self.v:GetPhysicsObject()
			if not (ph and IsValid(ph)) then return end
			if ph:GetAngleVelocity().y > 120 then return end --If the vehicle is spinning, don't change.
			if math.abs(steer) < 0.15 then steer = 0 end --If direction is almost straight, set 0.
			self:SetThrottle(throttle)
			self:SetSteering(steer)
		end
	end
	
	function ENT:Initialize()
		self:SetNoDraw(true)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetModel(self.Modelname)
		
		--Pick up a vehicle in the given sphere.
		local distance = DetectionRange:GetFloat()
		for k, v in pairs(ents.FindInSphere(self:GetPos(), distance)) do
			if v:IsVehicle() and not v.MadVehicle then
				if v.IsScar then --If it's a SCAR.
					if not v:HasDriver() then --If driver's seat is empty.
						self.v = v
						v.HasDriver = function() return true end --SCAR script assumes there's a driver.
						v.SpecialThink = function() end --Tanks or something sometimes make errors so disable thinking.
						v:StartCar()
						v.MadVehicle = self
					end
				elseif v.IsSimfphyscar and v:IsInitialized() then --If it's a Simfphys Vehicle.
					if not IsValid(v:GetDriver()) then --Fortunately, Simfphys Vehicles can use GetDriver()
						self.v = v
						v:SetActive(true)
						v:StartEngine()
						v.MadVehicle = self
					end
				elseif isfunction(v.EnableEngine) and isfunction(v.StartEngine) then --Normal vehicles should use these functions. (SCAR and Simfphys cannot.)
					if isfunction(v.GetWheelCount) and v:GetWheelCount() and not IsValid(v:GetDriver()) then
						self.v = v
						v:EnableEngine(true)
						v:StartEngine(true)
						v.MadVehicle = self
					end
				end
			end
		end
	
		if not IsValid(self.v) then --When there's no vehicle, remove Decent Vehicle.
			DecentVehicleDestination = self:GetPos() --Set a destination.
			BroadcastLua "notification.AddLegacy(\"Global Decent Vehicle's destination has been set!\", NOTIFY_GENERIC, 3)"
			SafeRemoveEntity(self)
			return
		end
		
		local e = EffectData()
		e:SetEntity(self.v)
		util.Effect("propspawn", e) --Perform a spawn effect.
		
		local min, max = self.v:GetHitBoxBounds(0, 0) --NPCs aim at the top of the vehicle referred by hit box.
		if not isvector(max) then min, max = self.v:GetModelBounds() end --If getting hit box bounds is failed, get model bounds instead.
		if not isvector(max) then max = vector_up * math.random(80, 200) end --If even getting model bounds is failed, set a random value.
		self.moving = CurTime()
		
		local tr = util.TraceHull({start = self.v:GetPos() + vector_up * max.z, 
			endpos = self.v:GetPos(), ignoreworld = true,
			mins = Vector(-16, -16, -1), maxs = Vector(16, 16, 1)})
		self.CollisionHeight = tr.HitPos.z - self.v:GetPos().z
		if self.CollisionHeight < 10 then self.CollisionHeight = max.z end
		self.v:DeleteOnRemove(self)
	end
else --if CLIENT
	function ENT:Initialize()
		self:SetNoDraw(true)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetModel(self.Modelname)
	end
end --if SERVER

--For Half Life Renaissance Reconstructed
function ENT:GetNoTarget()
	return false
end

--For Simfphys Vehicles
function ENT:GetInfoNum(key, default)
	if key == "cl_simfphys_ctenable" then return 1 --returns the default value
	elseif key == "cl_simfphys_ctmul" then return 0.7 --because there's a little weird code in
	elseif key == "cl_simfphys_ctang" then return 15 --Simfphys:PlayerSteerVehicle()
	elseif isnumber(default) then return default end
	return 0
end

hook.Add("Tick", "Decent Vehicle's destination", function()
	if not DecentVehicleDestination then return end
	debugoverlay.Cross(DecentVehicleDestination, 20, .1, Color(0, 255, 0), true)
	debugoverlay.Line(DecentVehicleDestination, DecentVehicleDestination + vector_up * 100, .1, Color(0, 255, 0), true)
end)
