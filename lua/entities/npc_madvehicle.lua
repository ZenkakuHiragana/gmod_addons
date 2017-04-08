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

function ENT:Initialize()
	self:SetNoDraw(true)
	self:SetModel("models/props_wasteland/cargo_container01.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	
	if SERVER then
		for k, v in pairs(ents.FindInSphere(self:GetPos(), 10)) do
			if v:IsVehicle() then
				if v.IsScar then
					if not v:HasDriver() then
						self.v = v
						self.v.HasDriver = function() return true end
						v:StartCar()
					end
				else
					if v:GetWheelCount() and not IsValid(v:GetDriver()) then
						self.v = v
						v:EnableEngine(true)
						v:StartEngine(true)
					end
				end
			end
		end
	
		if not IsValid(self.v) then SafeRemoveEntity(self) return end
		local e = EffectData()
		e:SetEntity(self.v)
		util.Effect("propspawn", e)
		
		self.moving = CurTime()
		local min, max = self.v:GetHitBoxBounds(0, 0)
		self.collision_length = max.z
		
		if GetConVar("madvehicle_playmusic"):GetBool() and 
			#ents.FindByClass("npc_madvehicle") < 2 then
			self.loop = CreateSound(self.v, "madvehicle_music.wav")
			self.loop:SetSoundLevel(85)
			self.loop:Play()
		end
		
		for k, v in pairs(ents.GetAll()) do
			if IsValid(v) and isfunction(v.AddEntityRelationship) then
				v:AddEntityRelationship(self, D_HT, 0)
			end
		end
	end
end

--For Half Life Renaissance Reconstructed
function ENT:GetNoTarget()
	return false
end

if SERVER then	
	CreateConVar("madvehicle_playmusic", 0, FCVAR_ARCHIVE, "Mad Vehicle: If 1, the vehicles play a music.")
	CreateConVar("madvehicle_deleteonstuck", 10, FCVAR_ARCHIVE, "Mad Vehicle: Deletes Mad Vehicle if it gets stuck for the given seconds. 0 to disable.")
	
	hook.Add("OnEntityCreated", "MadVehicleIsAlone!", function(e)
		if IsValid(e) and e:GetClass() ~= "npc_madvehicle" then
			local t = "MadVehicle_hate_" .. e:EntIndex()
			if isfunction(e.AddEntityRelationship) then
				timer.Create(t, 2, 0, function()
					if not IsValid(e) then timer.Remove(t) return end
					for k, v in pairs(ents.FindByClass("npc_madvehicle")) do
						if IsValid(v) then
							e:AddEntityRelationship(v, D_HT, 0)
						end
					end
				end)
			end
		end
	end)
	
	function ENT:OnRemove()
		if IsValid(self.v) and self.v:IsVehicle() then
			if self.v.IsScar then
				self.v:TurnOffCar()
				self.v:HandBrakeOn()
				self.v:GoNeutral()
				self.v:NotTurning()
				self.v.HasDriver = self.v.BaseClass.HasDriver
			elseif not IsValid(self.v:GetDriver()) then
				self.v:StartEngine(false)
				self.v:SetHandbrake(true)
				self.v:SetThrottle(0)
				self.v:SetSteering(0, 0)
			end
			
			local e = EffectData()
			e:SetEntity(self.v)
			util.Effect("propspawn", e)
		end
		
		if self.loop then
			self.loop:Stop()
		end
	end
	
	function ENT:TargetEnemy()
		local t = ents.FindInSphere(self.v:WorldSpaceCenter(), 4000)
		local distance, nearest = math.huge, nil --Targets the nearest enemy.
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
	
	function ENT:Validate(v)
		return IsValid(v) and v:GetClass() ~= "npc_madvehicle" and v:OnGround() and 
		(v:WorldSpaceCenter() - self.v:WorldSpaceCenter()):LengthSqr() < 4000000 and 
		(v:IsNPC() or v.Type == "nextbot" or (v:IsPlayer() and v:Alive() and not GetConVar("ai_ignoreplayers"):GetBool()))
	end
	
	function ENT:Think()
		if not IsValid(self.v) or not self.v:IsVehicle() or 
			IsValid(self.v:GetDriver()) or self:WaterLevel() > 1 or
			(self.v.IsScar and (self.v:IsDestroyed() or self.v.Fuel <= 0)) then
			SafeRemoveEntity(self)
		return end
		
		self:SetPos(self.v:GetPos() + vector_up * self.collision_length)
		if not self:Validate(self.e) then
			if self.v.IsScar then
				self.v:GoNeutral()
				self.v:NotTurning()
			else
				self.v:SetThrottle(0)
				self.v:SetSteering(0, 0)
			end
			
			local enemy = self:TargetEnemy()
			if IsValid(enemy) then
				self.e = enemy
				self.moving = CurTime()
			end
		else
			if self.v:GetVelocity():LengthSqr() > 40000 then
				self.moving = CurTime()
			end
			
			local timeout = GetConVar("madvehicle_deleteonstuck"):GetFloat()
			if timeout and timeout > 0 then
				if CurTime() > self.moving + timeout then
					local enemy = self:TargetEnemy()
					if IsValid(enemy) and self.e ~= enemy then
						self.e = enemy
						self.moving = CurTime()
					else
						SafeRemoveEntity(self)
						return
					end
				end
			end
			
			if self.v.IsScar then
				self.v:HandBrakeOff()
			else
				self.v:SetHandbrake(false)
			end
			local forward = self.v.IsScar and self.v:GetForward() or self.v:GetForward()
			local dist = self.e:WorldSpaceCenter() - self.v:WorldSpaceCenter()
			local vect = dist:GetNormalized()
			local vectdot = vect:Dot(self.v:GetVelocity())
			local throttle = dist:Dot(forward) > 0 and 1 or -1
			local right = vect:Cross(forward)
			local steer_amount = right:Length()^0.8
			local steer = right.z > 0 and steer_amount or -steer_amount
			if math.abs(vectdot) > 0.12 and vectdot < 0 then
				steer = steer * -1
			end
			if (dist:Length2DSqr() < 250000 and vectdot < 0) or 
				(self.v:GetVelocity():LengthSqr() < 40000 and dist:Length2DSqr() < 20000) then
				throttle = -1
			end
			if self.v.IsScar then
				if throttle > 0 then
					self.v:GoForward(throttle)
				else
					self.v:GoBack(-throttle)
				end
			else
				self.v:SetThrottle(throttle)
			end
			
			local ph = self.v:GetPhysicsObject()
			if not (ph and IsValid(ph)) then return end
			if ph:GetAngleVelocity().y > 120 then return end
			if math.abs(steer) < 0.15 then steer = 0 end
			if self.v.IsScar then
				if steer > 0 then
					self.v:TurnRight(steer)
				elseif steer < 0 then
					self.v:TurnLeft(-steer)
				else
					self.v:NotTurning()
				end
			else
				self.v:SetSteering(steer, 0)
			end
		end
	end
end
