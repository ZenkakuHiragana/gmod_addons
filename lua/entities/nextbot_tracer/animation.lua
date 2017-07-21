
--Plays a flinch gesture.
--Arguments:
----CTakeDamageInfo info | Damage info given by NEXTBOT:OnInjured()
function ENT:PerformFlinch(info)
	local act = self.Act.Flinch.Default
	if info:GetDamageForce():GetNormalized():Dot(self:GetForward()) > math.cos(math.rad(33.75)) then
		act = self.Act.Flinch.Back
	elseif self:WithinHitBox(info:GetDamagePosition(),
		self.HitBox.Head, self.HitGroup.Head, self.Bone.Head) then
		act = self.Act.Flinch.Head
	elseif self:WithinHitBox(info:GetDamagePosition(),
		self.HitBox.ShoulderLeft, self.HitGroup.ShoulderLeft, self.Bone.ShoulderLeft) then
		act = self.Act.Flinch.ShoulderLeft
	elseif self:WithinHitBox(info:GetDamagePosition(),
		self.HitBox.ShoulderRight, self.HitGroup.ShoulderRight, self.Bone.ShoulderRight) then
		act = self.Act.Flinch.ShoulderRight
	elseif self:WithinHitBox(info:GetDamagePosition(),
		self.HitBox.Stomach, self.HitGroup.Stomach, self.Bone.Stomach) then
		act = self.Act.Flinch.Stomach
	elseif tobool(bit.band(info:GetDamageType(), bit.bor(DMG_CRUSH, DMG_VEHICLE, DMG_PHYSGUN))) then
		act = self.Act.Flinch.Physics
	end
	
	if not self:IsPlayingGesture(act) then
		self:AddGesture(act)
	end
end

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
		elseif velocity > 0 then
			self.DesiredSpeed = self.Speed.Walk
			act = self.Act.Walk
		end
	end
	
	self.loco:SetDesiredSpeed(self.DesiredSpeed)
	self.loco:SetAcceleration(self.Speed.Acceleration)
	self.loco:SetDeceleration(self.Speed.Deceleration)
	if self:GetActivity() ~= act then self:StartActivity(act) end
	
	--Pose parameter for aiming.
	self:SetLookatEnemy(tobool(self:GetEnemy()))
	self:SetLookatAim(self.Memory.EnemyPosition)

	if self.Memory.Look then
		self.loco:FaceTowards(self.Memory.EnemyPosition)
	elseif self.loco:GetVelocity():LengthSqr() > 0 then
		self.loco:FaceTowards(self:GetPos() + self.loco:GetVelocity())
	end
	
	self:BodyMoveXY()
end


