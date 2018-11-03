list.Set("NPC", "npc_madvehicle", {
	Name = "Mad Vehicle",
	Class = "npc_madvehicle",
	Category = "GreatZenkakuMan's NPCs"
})
AddCSLuaFile("npc_madvehicle.lua")

ENT.Base = "base_entity"
ENT.Type = "ai"

ENT.PrintName = "Mad Vehicle"
ENT.Author = "Himajin Jichiku"
ENT.Contact = ""
ENT.Purpose = "Mad Vehicle."
ENT.Instruction = ""
ENT.Spawnable = false
ENT.Modelname = "models/props_wasteland/cargo_container01.mdl"

if SERVER then	
	--Setting ConVars.
	local TargetPlayer = CreateConVar("madvehicle_targetplayer", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets players.")
	local TargetNextbot = CreateConVar("madvehicle_targetnextbot", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets nextbots.")
	local TargetMilitary = CreateConVar("madvehicle_targetmilitary", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets military NPCs(Human grunts and assassins).")
	local TargetMetropolice = CreateConVar("madvehicle_targetmetropolice", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets metropolices and manhacks.")
	local TargetCombine = CreateConVar("madvehicle_targetcombine", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets combine forces.")
	local TargetCitizen = CreateConVar("madvehicle_targetcitizen", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets citizen characters.")
	local TargetZombie = CreateConVar("madvehicle_targetzombie", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets zombies.")
	local TargetAntlion = CreateConVar("madvehicle_targetantlion", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets antlions.")
	local TargetOther = CreateConVar("madvehicle_targetother", 1, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets NPCs who aren't affected by any other Mad Vehicle ConVars.")
	local TargetVehicle = CreateConVar("madvehicle_targetvehicle", 0, FCVAR_ARCHIVE, "Mad Vehicle: Whether or not Mad Vehicle targets other vehicles.")
	local EnemyRange = CreateConVar("madvehicle_enemyrange", 4500, FCVAR_ARCHIVE, "Mad Vehicle: Mad Vehicle targets an enemy within this range.")
	local DetectionRange = CreateConVar("madvehicle_detectionrange", 30, FCVAR_ARCHIVE, "Mad Vehicle: A vehicle within this distance will become mad.")
	local PlayMusic = CreateConVar("madvehicle_playmusic", 0, FCVAR_ARCHIVE, "Mad Vehicle: If 1, the vehicles play a music.")
	local DeleteOnStuck = CreateConVar("madvehicle_deleteonstuck", 10, FCVAR_ARCHIVE, "Mad Vehicle: Deletes Mad Vehicle if it gets stuck for the given seconds. 0 to disable.")
	local SoundLevel = CreateConVar("madvehicle_soundlevel", 85, FCVAR_ARCHIVE, "Mad Vehicle: The sound level of the music.")
	
	--Target NPC filter using NPC:Classify().
	local antlion_class = {
		[CLASS_ANTLION] = true,
	}
	local citizen_class = {
		[CLASS_NONE] = true,
		[CLASS_PLAYER] = true,
		[CLASS_PLAYER_ALLY] = true,
		[CLASS_PLAYER_ALLY_VITAL] = true,
		[CLASS_CITIZEN_PASSIVE] = true,
		[CLASS_CITIZEN_REBEL] = true,
		[CLASS_VORTIGAUNT] = true,
	}
	local combine_class = {
		[CLASS_COMBINE] = true,
		[CLASS_COMBINE_GUNSHIP] = true,
		[CLASS_SCANNER] = true,
		[CLASS_STALKER] = true,
		[CLASS_PROTOSNIPER] = true,
		[CLASS_HACKED_ROLLERMINE] = true,
		[CLASS_COMBINE_HUNTER] = true,
	}
	local military_class = {
		[CLASS_MILITARY] = true,
	}
	local police_class = {
		[CLASS_MANHACK] = true,
		[CLASS_METROPOLICE] = true,
	}
	local zombie_class = {
		[CLASS_HEADCRAB] = true,
		[CLASS_ZOMBIE] = true,
	}
	
	--Pass some ConVar settings.
	local function PassConVarFilter(v)
		if v:IsNPC() then
			local c = v:Classify()
			if antlion_class[c] then
				return TargetAntlion:GetBool()
			elseif citizen_class[c] then
				return TargetCitizen:GetBool()
			elseif combine_class[c] then
				return TargetCombine:GetBool()
			elseif police_class[c] then
				return TargetMetropolice:GetBool()
			elseif military_class[c] then
				return TargetMilitary:GetBool()
			elseif zombie_class[c] then
				return TargetZombie:GetBool()
			else
				return TargetOther:GetBool()
			end
		elseif v.Type == "nextbot" and TargetNextbot:GetBool() then
			return true
		elseif v:IsPlayer() and TargetPlayer:GetBool() then
			return true
		elseif v:IsVehicle() and TargetVehicle:GetBool() then
			return IsValid(v.MadVehicle)
			or v.IsScar and v:HasDriver()
			or isfunction(v.GetDriver) and IsValid(v:GetDriver())
		end
		
		return false
	end
	
	--Everyone hates Mad Vehicle.
	hook.Add("OnEntityCreated", "MadVehicleIsAlone!", function(e)
		if IsValid(e) and e:GetClass() ~= "npc_madvehicle" then
			local t = "MadVehicle_hate_" .. e:EntIndex()
			if isfunction(e.AddEntityRelationship) then
				timer.Create(t, 2, 0, function()
					if not IsValid(e) then timer.Remove(t) return end
					for k, v in pairs(ents.FindByClass("npc_madvehicle")) do
						if IsValid(v) then
							local relationship = PassConVarFilter(e) and D_HT or D_NU
							e:AddEntityRelationship(v, relationship, 0)
						end
					end
				end)
			end
		end
	end)
	
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
		
		if self.loop then --If it's playing the music, stop it.
			self.loop:Stop()
		end
	end
	
	--Find an enemy around.
	function ENT:TargetEnemy()
		local t = ents.FindInSphere(self.v:WorldSpaceCenter(), math.sqrt(self.TargetRange))
		local distance, nearest = math.huge, nil --The nearest enemy is the target.
		for k, v in pairs(t) do
			if self:Validate(v) then
				local d = v:WorldSpaceCenter():DistToSqr(self.v:WorldSpaceCenter())
				if distance > d then
					distance = d
					nearest = v
				end
			end
		end
		
		return nearest
	end
	
	--Validate the given entity.
	function ENT:Validate(v)
		local valid = 
			IsValid(v) and --Not a NULL entity.
			v.MadVehicle ~= self and --It's mad and not my vehicle
			v:GetClass() ~= "npc_madvehicle" and --Not me
			v:WorldSpaceCenter():DistToSqr(self.v:WorldSpaceCenter()) < self.TargetRange and --Within a distance.
			(v:IsNPC() or v:IsVehicle() or v.Type == "nextbot" or
			(v:IsPlayer() and v:Alive() and not GetConVar("ai_ignoreplayers"):GetBool()))
		if not valid then return false end
		
		--If the entity is flying, return false.
		local onground = util.QuickTrace(v:GetPos(), -vector_up * self.CollisionHeight, {v, self, self.v})
		if not onground.Hit then return false end
		
		return PassConVarFilter(v)
	end
	
	function ENT:Think()
		if not IsValid(self.v) or --The tied vehicle goes NULL.
			not self.v:IsVehicle() or --Somehow it become non-vehicle entity.
			IsValid(self.v:GetDriver()) or --it has an driver.
			self:WaterLevel() > 1 or --It fall into water.
			(self.v.IsScar and (self.v:IsDestroyed() or self.v.Fuel <= 0)) or --It's SCAR and destroyed or out of fuel.
			(self.v.IsSimfphyscar and (self.v:GetCurHealth() <= 0)) then --It's Simfphys Vehicle and destroyed.
			SafeRemoveEntity(self) --Then go back to normal.
		return end
		
		self:SetPos(self.v:GetPos() + vector_up * self.CollisionHeight)
		if not self:Validate(self.e) then --If it doesn't have an enemy.
			--Stop moving.
			if self.v.IsScar then
				self.v:GoNeutral()
				self.v:NotTurning()
				self.v:HandBrakeOn()
			elseif self.v.IsSimfphyscar then
				self.v:SetActive(true)
				self.v:StartEngine()
				self.v.PressedKeys = self.v.PressedKeys or {}
				self.v.PressedKeys["W"] = false
				self.v.PressedKeys["A"] = false
				self.v.PressedKeys["S"] = false
				self.v.PressedKeys["D"] = false
				self.v.PressedKeys["Shift"] = false
				self.v.PressedKeys["Space"] = true
			elseif isfunction(self.v.SetThrottle) and isfunction(self.v.SetSteering) and isfunction(self.v.SetHandbrake) then
				self.v:SetThrottle(0)
				self.v:SetSteering(0, 0)
				self.v:SetHandbrake(true)
			end
			
			local enemy = self:TargetEnemy() --Find an enemy.
			if IsValid(enemy) then
				self.e = enemy
				self.moving = CurTime()
			end
		else --It does.
			if self.v:GetVelocity():LengthSqr() > 40000 then --If it's moving, resets the stuck timer.
				self.moving = CurTime()
			end
			
			local timeout = GetConVar("madvehicle_deleteonstuck"):GetFloat()
			if timeout and timeout > 0 then
				if CurTime() > self.moving + timeout then --If it has got stuck for enough time.
					local enemy = self:TargetEnemy()
					if IsValid(enemy) and self.e ~= enemy then --Find a new enemy and reset the timer.
						self.e = enemy
						self.moving = CurTime()
					else --Go back to normal when no enemy is found.
						SafeRemoveEntity(self)
						return
					end
				end
			end
			
			--Drive the vehicle.
			--Set handbrake off.
			if self.v.IsScar then
				self.v:HandBrakeOff()
			elseif self.v.IsSimfphyscar then
				self.v:SetActive(true)
				self.v:StartEngine()
				self.v.PressedKeys = self.v.PressedKeys or {}
				self.v.PressedKeys["Space"] = false
			elseif isfunction(self.v.SetHandbrake) then
				self.v:SetHandbrake(false)
			end
			
			local forward = self.v.IsSimfphyscar and --Forward vector.
				self.v:LocalToWorldAngles(self.v.VehicleData.LocalAngForward):Forward() or self.v:GetForward()
			local dist = self.e:WorldSpaceCenter() - self.v:WorldSpaceCenter() --Distance between the vehicle and the enemy.
			local vect = dist:GetNormalized() --Enemy direction vector.
			local vectdot = vect:Dot(self.v:GetVelocity()) --Dot product, velocity and direction.
			local throttle = dist:Dot(forward) > 0 and 1 or -1 --Throttle depends on their positional relationship.
			local right = vect:Cross(forward) --The enemy is right side or not.
			local steer_amount = right:Length()^0.8 --Steering parameter.
			local steer = right.z > 0 and steer_amount or -steer_amount --Actual steering parameter.
			if vectdot < -0.12 then steer = steer * -1 end
			
			--If the vehicle is too close to the enemy or the vehicle shouldn't go backward, invert the throttle.
			if (dist:Length2DSqr() < 250000 and vectdot < 0) or 
				(self.v:GetVelocity():LengthSqr() < 40000 and dist:Length2DSqr() < 20000) then
				throttle = -1
			end
			--Set throttle.
			if self.v.IsScar then
				if throttle > 0 then
					self.v:GoForward(throttle)
				else
					self.v:GoBack(-throttle)
				end
			elseif self.v.IsSimfphyscar then
				self.v:SetActive(true)
				self.v:StartEngine()
				self.v.PressedKeys = self.v.PressedKeys or {}
				self.v.PressedKeys["Shift"] = false
				self.v.PressedKeys["W"] = throttle > 0
				self.v.PressedKeys["S"] = throttle <= 0
			elseif isfunction(self.v.SetThrottle) then
				self.v:SetThrottle(throttle)
			end
			
			--Set steering parameter.
			local ph = self.v:GetPhysicsObject()
			if not (ph and IsValid(ph)) then return end
			if ph:GetAngleVelocity().y > 120 then return end --If the vehicle is spinning, don't change.
			if math.abs(steer) < 0.15 then steer = 0 end --If direction is almost straight, set 0.
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
		end --if not self:Validate(self.e)
	end
	
	function ENT:Initialize()
		self:SetNoDraw(true)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetModel(self.Modelname)
		
		--Pick up a vehicle in the given sphere.
		local distance = DetectionRange:GetFloat()
		for k, v in pairs(ents.FindInSphere(self:GetPos(), distance)) do
			if v:IsVehicle() then
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
	
		if not IsValid(self.v) then SafeRemoveEntity(self) return end --When there's no vehicle, remove Mad Vehicle.
		local e = EffectData()
		e:SetEntity(self.v)
		util.Effect("propspawn", e) --Perform a spawn effect.
		
		local min, max = self.v:GetHitBoxBounds(0, 0) --NPCs aim at the top of the vehicle referred by hit box.
		if not isvector(max) then min, max = self.v:GetModelBounds() end --If getting hit box bounds is failed, get model bounds instead.
		if not isvector(max) then max = vector_up * math.random(80, 200) end --If even getting model bounds is failed, set a random value.
		self.moving = CurTime()
		self.TargetRange = EnemyRange:GetFloat()^2 --Target range is squared to prevent from doing sqrt()
		
		local tr = util.TraceHull({start = self.v:GetPos() + vector_up * max.z, 
			endpos = self.v:GetPos(), ignoreworld = true,
			mins = Vector(-16, -16, -1), maxs = Vector(16, 16, 1)})
		self.CollisionHeight = tr.HitPos.z - self.v:GetPos().z
		if self.CollisionHeight < 10 then self.CollisionHeight = max.z end
		self.v:DeleteOnRemove(self)
		
		if PlayMusic:GetBool() and 
			#ents.FindByClass("npc_madvehicle") < 2 then --Only one Mad Vehicle can play the music.
			self.loop = CreateSound(self, "madvehicle_music.wav")
			self.loop:SetSoundLevel(SoundLevel:GetInt())
			self.loop:Play()
		end
		
		for k, v in pairs(ents.GetAll()) do --Everyone hates Mad Vehicle.
			if IsValid(v) and isfunction(v.AddEntityRelationship) then
				local relationship = PassConVarFilter(v) and D_HT or D_NU
				v:AddEntityRelationship(self, relationship, 0) --But NPCs who aren't using relationship system don't.
			end
		end
	end
	
	function ENT:GetInfoNum(cvarname, default) --For Simfphys vehicles.
		return default
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
