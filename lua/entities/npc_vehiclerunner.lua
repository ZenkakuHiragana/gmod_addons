list.Set("NPC", "npc_vehiclerunner", {
	Name = "Mad Vehicle",
	Class = "npc_vehiclerunner",
	Category = "GreatZenkakuMan's NPCs"
})
AddCSLuaFile("npc_vehiclerunner.lua")

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
	self:SetModel("models/headcrabclassic.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	
	if SERVER then
		for k, v in pairs(ents.FindInSphere(self:GetPos(), 10)) do
			if v:IsVehicle() and v:GetWheelCount() and v:IsEngineEnabled() and not IsValid(v:GetDriver()) then
				self.v = v
				v:StartEngine(true)
			end
		end
	
		if not IsValid(self.v) then SafeRemoveEntity(self) return end
		local e = EffectData()
		e:SetEntity(self.v)
		util.Effect("propspawn", e)
		
		self.moving = CurTime()
	--	self.v:AddCallback("PhysicsCollide", function(ent, data)
	--	end)
	
		self.loop = CreateSound(self.v, "madvehicle_music.mp3")
		self.loop:SetSoundLevel(100)
		self.loop:Play()
		self.looptime = CurTime()
	end
end

--For Half Life Renaissance Reconstructed
function ENT:GetNoTarget()
	return false
end

if SERVER then	
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
		timer.Remove("hippie" .. self:EntIndex())
		if self.loop then
			self.loop:Stop()
		end
	end
	
	function ENT:Validate(v)
		return IsValid(v) and v:GetClass() ~= "npc_vehiclerunner" and v:OnGround() and 
		(v:IsNPC() or (v:IsPlayer() and not GetConVar("ai_ignoreplayers"):GetBool()))
	end
	
	function ENT:Think()
		if CurTime() > self.looptime + 65.205 then
			self.looptime = CurTime()
			self.loop:Stop()
			self.loop:Play()
		end
		if not IsValid(self.v) or not self.v:IsVehicle() or IsValid(self.v:GetDriver()) then
			SafeRemoveEntity(self)
		return end
		
		self:SetPos(self.v:WorldSpaceCenter())
	--	self:NextThink(CurTime() + 1)
		if not self:Validate(self.e) then
			self.v:SetHandbrake(true)
			self.v:SetThrottle(0)
			self.v:SetSteering(0, 0)
			local t = ents.FindInSphere(self.v:WorldSpaceCenter(), 4096)
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
			local throttle = dist:Dot(self.v:GetForward()) > 0 and 1 or -1
			
			local right = vect:Cross(self.v:GetForward())
			local s1, s2 = right.z > 0 and right:LengthSqr()^0.5 or 0, right.z < 0 and -right:LengthSqr()^0.5 or 0
			if vect:Dot(self.v:GetVelocity()) < 0 then
				s1, s2 = s1 * -1, s2 * -1
			end
			if (dist:Length2DSqr() < 250000 and vect:Dot(self.v:GetVelocity()) < 0) or 
				(self.v:GetVelocity():LengthSqr() < 40000 and dist:Length2DSqr() < 20000) then
				throttle = -1
			--	s1, s2 = 1, 0
			end
			self.v:SetThrottle(throttle)
			self.v:SetSteering(s1, s2)
		end
	end
end
