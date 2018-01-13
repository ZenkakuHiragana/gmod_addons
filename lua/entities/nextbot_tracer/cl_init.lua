
include("shared.lua")
include("sounds.lua")
local classname = "nextbot_tracer"
killicon.AddAlias(classname, "weapon_pistol")
language.Add(classname, ENT.PrintName)

util.PrecacheModel(ENT.Model)

-- move_y				-1	1
-- move_x				-1	1
-- aim_yaw				-63.407917022705	71.206367492676
-- aim_pitch			-86.757820129395	82.842018127441
-- vertical_velocity	-1	1
-- vehicle_steer		-1	1
-- head_yaw				-75	75
-- head_pitch			-60	60
local aim_yaw_min, aim_yaw_max = -63.407917022705, 71.206367492676
local aim_pitch_min, aim_pitch_max = -86.757820129395, 82.842018127441
local head_yaw_min, head_yaw_max = -75, 75
local head_pitch_min, head_pitch_max = -60, 60
local parameter_movedivision = 8

hook.Add("EntityEmitSound", "NextbotHearsSound", function(t)
	if not IsValid(t.Entity) then return end
	for k, v in pairs(ents.FindByClass(classname)) do
		if t.Entity == v then return end
		if IsValid(v) and v.IsInitialized and v:IsHearingSound(t) then
			net.Start("NextbotHearsSound")
			net.WriteEntity(v)
			net.WriteTable(t)
			net.SendToServer()
		end
	end
end)

net.Receive("SetAimParameterRecall", function(len, ply)
	local bot = net.ReadEntity()
	if not IsValid(bot) or bot:GetClass() ~= classname then return end
	local aim_yaw = net.ReadFloat()
	local aim_pitch = net.ReadFloat()
	
	bot.aim_yaw, bot.aim_pitch = aim_yaw, aim_pitch
	bot:SetPoseParameter("aim_yaw", bot.aim_yaw)
	bot:SetPoseParameter("aim_pitch", bot.aim_pitch)
end)

net.Receive("Nextbot Tracer: No playermodel notification", function(...)
	notification.AddLegacy("Can't spawn nextbot: Tracer playermodel is not found!", NOTIFY_ERROR, 3.5)
end)

--Initializes this NPC.
function ENT:Initialize()
	--Shared functions
	self:SetModel(self.Model)
	self:SetHealth(self.HP.Init)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:AddFlags(FL_AIMTARGET)
	self:SetSolid(SOLID_BBOX)
	self:MakePhysicsObjectAShadow(true, true)
	
	local vector_default = self:GetEye().Pos + self:GetEye().Ang:Forward() * 400
	self.EyeHeight = self:GetEye().Pos.z - self:GetPos().z
	self.EyePosition = vector_default
	self.TimeEyeBlink = CurTime()
	self.TimeIdleLookat = CurTime()
	self.IdleLookatAim = vector_default
	self.IdleLookatEntity = NULL
	self.IdleLookatEye = vector_default
	self.IdleLookatHead = vector_default
	self.aim_yaw = 0
	self.aim_pitch = 0
	self.head_yaw = 0
	self.head_pitch = 0
	self:MoveEyeTarget(vector_default)
	
	self.IsInitialized = true
end

--This function sets the facing direction of the arms.
--Argument:
----Vector pos | the position to aim at.
function ENT:Aim(pos)
	local Ang = self:WorldToLocal(pos - vector_up * self.EyeHeight):Angle()
	Ang:Normalize()
	local y, p = Ang.yaw, Ang.pitch
	y = math.Clamp(y, aim_yaw_min, aim_yaw_max)
	p = math.Clamp(p, aim_pitch_min, aim_pitch_max)
	
	local dy, dp = y - self.aim_yaw, p - self.aim_pitch
	self.aim_yaw = self.aim_yaw + dy / parameter_movedivision
	self.aim_pitch = self.aim_pitch + dp / parameter_movedivision
	self:SetPoseParameter("aim_yaw", self.aim_yaw)
	self:SetPoseParameter("aim_pitch", self.aim_pitch)
end

--This function does as well as above but for head.
--Argument:
----Vector pos | the position to face at.
function ENT:FaceHead(pos)
	local Ang = self:WorldToLocal(pos - vector_up * self.EyeHeight):Angle()
	Ang:Normalize()
	local y, p = Ang.yaw, Ang.pitch
	y = math.Clamp(y, head_yaw_min, head_yaw_max)
	p = math.Clamp(p, head_pitch_min, head_pitch_max)
	
	local dy, dp = y - self.head_yaw, p - self.head_pitch
	self.head_yaw = self.head_yaw + dy / parameter_movedivision
	self.head_pitch = self.head_pitch + dp / parameter_movedivision
	self:SetPoseParameter("head_yaw", self.head_yaw)
	self:SetPoseParameter("head_pitch", self.head_pitch)
end

--For eyes.
--Argument:
----Vector pos | the position to look at.
function ENT:MoveEyeTarget(pos)
	local dir = (pos - self.EyePosition) / parameter_movedivision
	self.EyePosition = self.EyePosition + dir
	self:SetEyeTarget(self.EyePosition)
end

function ENT:Think()
	--Getting positions for aiming, rotating the head, and line of sight.
	local lookat = self:GetLookatAim()
	local lookat_eye = self.IdleLookatEye
	local lookat_head = self.IdleLookatHead
	local vector_default = self:GetEye().Pos + self:GetEye().Ang:Forward() * 400
	if self:GetLookatEnemy() then
		lookat_eye = lookat
		lookat_head = lookat
		self.IdleLookatEntity = nil
	else
		lookat = self:GetEye().Pos + self:GetForward() * 400
		if CurTime() > self.TimeIdleLookat then
			self.TimeIdleLookat = CurTime() + math.Rand(1.2, 4)
			self.IdleLookatHead = vector_default +
				self:GetRight() * math.Rand(-400, 400) + vector_up * math.Rand(-100, 100)
			self.IdleLookatEye = self.IdleLookatHead +
				self:GetRight() * math.Rand(-100, 100) + vector_up * math.Rand(-50, 50)
			
			local ent = ents.FindInSphere(self:GetEye().Pos, 400)
			if #ent > 0 then
				ent = ent[math.random(1, #ent)]
				if IsValid(ent) and ent ~= self and ent:GetParent() ~= self and ent ~= self.IdleLookatEntity then
					self.IdleLookatEntity = ent
					if self:WorldSpaceCenter():DistToSqr(ent:WorldSpaceCenter()) > 1600 and
						math.abs((ent:WorldSpaceCenter() - self:WorldSpaceCenter())
						:GetNormalized():Dot(self:GetUp())) < math.cos(math.rad(head_pitch_max)) then
						self.IdleLookatEye = ent:WorldSpaceCenter()
						self.IdleLookatHead = ent:WorldSpaceCenter()
					end
				else
					self.IdleLookatEntity = nil
				end
			end
		end
	end
	
	if self.Debug.LookatHead then
		debugoverlay.Sphere(lookat_head, 20, 0.1, Color(0, 255, 0, 255))
		debugoverlay.Sphere(self.IdleLookatHead, 20, 0.1, Color(255, 255, 0, 255))
		debugoverlay.Sphere(self.IdleLookatEye, 20, 0.1, Color(0, 255, 255, 255))
	end
	
	self:MoveEyeTarget(lookat_eye)
	self:FaceHead(lookat_head)
	self:Aim(lookat)
	self:InvalidateBoneCache()
	
	--Eye blink
	if CurTime() > self.TimeEyeBlink then
		local delta = CurTime() - self.TimeEyeBlink
		if delta < 0.05 then
			self:SetFlexWeight(self:GetFlexIDByName("blink"), delta * 20)
		elseif delta < 0.15 then
			delta = 1 - (delta - 0.05) * 10
			self:SetFlexWeight(self:GetFlexIDByName("blink"), delta^2)
		else
			self.TimeEyeBlink = CurTime() + math.Rand(1.15, 3.50)
			self:SetFlexWeight(self:GetFlexIDByName("blink"), 0)
		end
	end
end

function ENT:Draw()
	if not self:GetInvisibleFlag() then
		self:DrawModel()
	else
		self:DestroyShadow()
	end
end