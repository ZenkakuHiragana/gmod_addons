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
--	self:SetNoDraw(true)
	self:SetModel("models/headcrabclassic.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	
	if SERVER then
		for k, v in pairs(ents.FindInSphere(self:GetPos(), 10)) do
			if v:IsVehicle() and v:GetWheelCount() and not IsValid(v:GetDriver()) then
				self.v = v
				v:EnableEngine(true)
				v:StartEngine(true)
			end
		end
	
		if not IsValid(self.v) then SafeRemoveEntity(self) return end
		local e = EffectData()
		e:SetEntity(self.v)
		util.Effect("propspawn", e)
		
		self.moving = CurTime()
		
		if GetConVar("madvehicle_playmusic"):GetBool() and 
			#ents.FindByClass("npc_madvehicle") < 2 then
			self.loop = CreateSound(self.v, "madvehicle_music.wav")
			self.loop:SetSoundLevel(80)
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
	
	function ENT:OnRemove()
		if IsValid(self.v) and self.v:IsVehicle() and not IsValid(self.v:GetDriver()) then
			self.v:StartEngine(false)
			self.v:SetHandbrake(true)
			self.v:SetThrottle(0)
			self.v:SetSteering(0, 0)
			
			local e = EffectData()
			e:SetEntity(self.v)
			util.Effect("propspawn", e)
		end
		
		if self.loop then
			self.loop:Stop()
		end
	end
	
	function ENT:Validate(v)
		return IsValid(v) and v:GetClass() ~= "npc_madvehicle" and v:OnGround() and 
		(v:WorldSpaceCenter() - self.v:WorldSpaceCenter()):LengthSqr() < 4000000 and 
		(v:IsNPC() or v.Type == "nextbot" or (v:IsPlayer() and v:Alive() and not GetConVar("ai_ignoreplayers"):GetBool()))
	end
	
	function ENT:Think()
		if not IsValid(self.v) or not self.v:IsVehicle() or IsValid(self.v:GetDriver()) or self:WaterLevel() > 1 then
			SafeRemoveEntity(self)
		return end
		
		self:SetPos(self.v:WorldSpaceCenter())
		if not self:Validate(self.e) then
			self.v:SetThrottle(0)
			self.v:SetSteering(0, 0)
			local t = ents.FindInSphere(self.v:WorldSpaceCenter(), 4000)
			for k, v in pairs(t) do
				if self:Validate(v) then
					self.e = v
					self.moving = CurTime()
					break
				end
			end
		else
			if self.v:GetVelocity():LengthSqr() > 40000 then
				self.moving = CurTime()
			end
			
			if CurTime() > self.moving + 10 then
				SafeRemoveEntity(self)
				return
			end
			
			self.v:SetHandbrake(false)
			local dist = self.e:WorldSpaceCenter() - self.v:WorldSpaceCenter()
			local vect = dist:GetNormalized()
			local vectdot = vect:Dot(self.v:GetVelocity())
			local throttle = dist:Dot(self.v:GetForward()) > 0 and 1 or -1
			
			local right = vect:Cross(self.v:GetForward())
			local steer = right.z > 0 and right:Length()^0.8 or -(right:Length()^0.8)
			if math.abs(vectdot) > 0.12 and vectdot < 0 then
				steer = steer * -1
			end
			if (dist:Length2DSqr() < 250000 and vectdot < 0) or 
				(self.v:GetVelocity():LengthSqr() < 40000 and dist:Length2DSqr() < 20000) then
				throttle = -1
			end
			self.v:SetThrottle(throttle)
			
			local ph = self.v:GetPhysicsObject()
			if not (ph and IsValid(ph)) then return end
			if ph:GetAngleVelocity().y > 120 then return end
			if math.abs(steer) < 0.15 then steer = 0 end
			self.v:SetSteering(steer, 0)
		end
	end
end
