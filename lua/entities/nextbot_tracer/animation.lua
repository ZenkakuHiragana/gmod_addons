
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

--Plays a scene and sets a timer for preventing flex problem.
--Argument:
----string scene | Filepath to scene.
function ENT:SetScene(scene)
	if CurTime() > self.Time.PlayingScene then
		self.Time.PlayingScene = CurTime() + self:PlayScene(scene)
		return true
	end
	return false
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
	
	local read_yaw, read_pitch = self:GetPoseParameter("aim_yaw"), self:GetPoseParameter("aim_pitch")
	local dy, dp = y - read_yaw, p - read_pitch
	self:SetPoseParameter("aim_yaw", read_yaw + dy / parameter_movedivision)
	self:SetPoseParameter("aim_pitch", read_pitch + dp / parameter_movedivision)
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
	
	local read_yaw, read_pitch = self:GetPoseParameter("head_yaw"), self:GetPoseParameter("head_pitch")
	local dy, dp = y - read_yaw, p - read_pitch
	self:SetPoseParameter("head_yaw", read_yaw + dy / parameter_movedivision)
	self:SetPoseParameter("head_pitch", read_pitch + dp / parameter_movedivision)
end

--For eyes.
--Argument:
----Vector pos | the position to look at.
function ENT:MoveEyeTarget(pos)
	local dir = (pos - self.Memory.EyePosition) / parameter_movedivision
	self.Memory.EyePosition = self.Memory.EyePosition + dir
	self:SetEyeTarget(self.Memory.EyePosition)
end

function ENT:BodyUpdate()
	--Set activity
	local velocity = self.loco:GetVelocity():LengthSqr()
	local act = self.Act.Idle
	if not self.loco:IsOnGround() then
		act = self.Act.Jump
	elseif self.Memory.CrouchNav or self.Memory.Crouch then
		if not self.IsBlink then self.DesiredSpeed = self.Speed.Crouched end
		act = velocity > 0 and self.Act.WalkCrouch or self.Act.IdleCrouch
	else
		if not (self.Memory.WalkNav or self.Memory.Walk) then
			if not self.IsBlink then self.DesiredSpeed = self.Speed.Run end
			if velocity > self.Speed.WalkSqr then
				act = self.Act.Run
			elseif velocity > 0 then
				act = self.Act.Walk
			end
		else
			if not self.IsBlink then self.DesiredSpeed = self.Speed.Walk end
			act = self.Act.Walk
		end
	end
	if not self.IsBlink then self.loco:SetDesiredSpeed(self.DesiredSpeed) end
	if self:GetActivity() ~= act then self:StartActivity(act) end
	
	self:BodyMoveXY()
	
	--Pose parameter for aiming.
	local lookat = self:GetPos() + self:GetForward() * 400 + vector_up * self.EyeHeight
	local lookat_head = lookat
	local lookat_eye = lookat
	if self.Memory.Look then
		lookat = self.Memory.EnemyPosition
		lookat_head = self.Memory.EnemyPosition
		lookat_eye = self.Memory.EnemyPosition
	elseif CurTime() > self.Time.IdleLookat then
		self.Time.IdleLookat = CurTime() + math.Rand(1.2, 4)
		local ent = ents.FindInSphere(self:GetEye().Pos, 400)
		if #ent > 0 then
			lookat_head = lookat_head + self:GetRight() * math.Rand(-50, 50) + vector_up * math.Rand(-10, 10)
			lookat_eye = lookat_eye + self:GetRight() * math.Rand(-150, 150) + vector_up * math.Rand(-30, 30)
			ent = ent[math.random(1, #ent)]
			if IsValid(ent) and ent ~= self and ent ~= self.Equipment.Entity and
				ent ~= self.Trail and ent ~= self.Memory.IdleLastLookat and IsValid(ent:GetPhysicsObject()) then
				self.Memory.IdleLastLookat = ent
				lookat_head = ent:WorldSpaceCenter()
				lookat_eye = lookat_head
			else
				self.Memory.IdleLastLookat = nil
			end
			self.Memory.IdleLookatEye = lookat_eye
		end
		self.Memory.IdleLookat = lookat_head
	else
		lookat_head = self.Memory.IdleLookat
		lookat_eye = self.Memory.IdleLookatEye
	end
--	debugoverlay.Sphere(lookat_head, 20, 0.1, Color(0, 255, 0, 255))
	self:MoveEyeTarget(lookat_eye)
	self:FaceHead(lookat_head)
	self:Aim(lookat)
	
	--Eye blink
	if CurTime() > self.Time.PlayingScene then
		self:SetFlexWeight(self:GetFlexIDByName("mouth_sideways"), 0.5)
		self:SetFlexWeight(self:GetFlexIDByName("jaw_sideways"), 0.5)
		if CurTime() > self.Time.EyeBlink then
			local delta = CurTime() - self.Time.EyeBlink
			if delta < 0.05 then
				self:SetFlexWeight(self:GetFlexIDByName("blink"), delta * 10)
			elseif delta < 0.15 then
				delta = 1 - (delta - 0.1) * 5
				self:SetFlexWeight(self:GetFlexIDByName("blink"), delta^4)
			else
				self.Time.EyeBlink = CurTime() + math.Rand(1.15, 3.50)
				self:SetFlexWeight(self:GetFlexIDByName("blink"), 0)
			end
		end
	end

	if self.Memory.Look then self.loco:FaceTowards(self.Memory.EnemyPosition) end
	
	self:FrameAdvance()
end


