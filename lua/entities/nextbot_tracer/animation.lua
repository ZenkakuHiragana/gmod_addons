
--Plays a scene and sets a timer for preventing flex problem.
--Argument:
----string scene | Filepath to scene.
--function ENT:SetScene(scene)
--	if CurTime() > self:GetTimePlayingScene() then
--		self:SetTimePlayingScene(CurTime() + self:PlayScene(scene))
--		return true
--	end
--	return false
--end

function ENT:BodyUpdate()
	--Set activity
	local velocity = self.loco:GetVelocity():LengthSqr()
	local act = self.Act.Idle
	if not self.loco:IsOnGround() then
		if self:WaterLevel() > 1 then
			act = self:GetVelocity():LengthSqr() > self.Speed.WalkSqr and self.Act.Swim or self.Act.SwimIdle
		else
			act = self.Act.Jump
		end
	elseif self.Memory.CrouchNav or self.Memory.Crouch then
		self.DesiredSpeed = self.Speed.Crouched
		act = velocity > 0 and self.Act.WalkCrouch or self.Act.IdleCrouch
	else
		if not (self.Memory.WalkNav or self.Memory.Walk) then
			self.DesiredSpeed = self.Speed.Run
			if velocity > self.Speed.WalkSqr then
				act = self.Act.Run
			elseif velocity > 0 then
				act = self.Act.Walk
			end
		else
			self.DesiredSpeed = self.Speed.Walk
			act = self.Act.Walk
		end
	end
	
	self:SetPoseParameter("move_x", 1)
	self.loco:SetDesiredSpeed(self.DesiredSpeed)
	self.loco:SetAcceleration(self.Speed.Acceleration)
	self.loco:SetDeceleration(self.Speed.Deceleration)
	if self:GetActivity() ~= act then self:StartActivity(act) end
	
	--Pose parameter for aiming.
	self:SetLookatEnemy(tobool(self:GetEnemy()))
	self:SetLookatAim(self.Memory.EnemyPosition)

	if self.Memory.Look then self.loco:FaceTowards(self.Memory.EnemyPosition) end
	
	self:BodyMoveXY()
end


