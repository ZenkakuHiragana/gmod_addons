
AddCSLuaFile()
ENT.Base = "npc_decentvehicle"
ENT.PrintName = "Learning Vehicle (β)"
ENT.Model = "models/player/gman_high.mdl"

local dvd = DecentVehicleDestination
list.Set("NPC", "npc_learningvehicle", {
	Name = ENT.PrintName,
	Class = "npc_learningvehicle",
	Category = "GreatZenkakuMan's NPCs",
})

if CLIENT then return end
function ENT:GetSteeringSpeed()
	if self.v.IsScar then
		return self.v.SteerResponse
	elseif self.v.IsSimfphyscar then
		return self:GetSteerSpeed()
	else
		local mph = self.v:GetSpeed()
		if mph < self.SteeringSpeedSlow then
			return self.SteeringRateSlow
		elseif mph < self.SteeringSpeedFast then
			return self.SteeringRateFast
		else
			return self.SteeringRateFast *
			self.SteeringParams.boostSteeringRateFactor
		end
	end
end

function ENT:GetSteeringFromYawRate(yawrate)
	if self.v.IsScar then
		local ref = math.abs(yawrate)
		local sign = yawrate == 0 and 0 or yawrate / ref
		local p = self.v:GetPhysicsObject()
		local right = self:GetVehicleRight()
		local min, max = 0, self.v.MaxSteerForce
		local mid = (min + max) / 2
		local offsset = Vector()
		for _, w in ipairs(self.v.TurningWheels) do
			if not IsValid(w) then continue end
			offset:Add(w.Pos)
		end
		
		offset:Mul(1 / self.v.NrOfTurningWheels)
		
		local loop = 0
		repeat
			local calc_min = select(2, p:CalculateVelocityOffset(right * min, offset))
			local calc_max = select(2, p:CalculateVelocityOffset(right * max, offset))
			if (calc_min.y - ref) * (calc_max.y - ref) > 0 then return sign end
			local calc_mid = select(2, p:CalculateVelocityOffset(right * mid, offset))
			if (calc_mid.y - ref) == 0 or math.abs(max - min) < 1e-10 then
				break
			elseif (calc_min.y - ref) * (calc_mid.y - ref) > 0 then
				min = mid
			else
				max = mid
			end
			
			mid = (min + max) / 2
			loop = loop + 1
		until loop > 52 or calc_min.y * calc_max.y 
		return mid / self.v.MaxSteerForce * sign
	elseif self.v.IsSimfphyscar then
		local v = self.v:GetVelocity():Dot(self:GetVehicleForward())
		local sign = yawrate == 0 and 0 or yawrate / math.abs(yawrate)
		local ref = math.deg(math.atan2(self.WheelBase * yawrate, math.max(1e-15, v)))
		local max = self.v.VehicleData.steerangle
		return -sign * (ref ~= ref and 1 or math.abs(ref / max))
	else
		local v = self.v:GetVelocity():Dot(self:GetVehicleForward())
		local sign = yawrate == 0 and 0 or yawrate / math.abs(yawrate)
		local ref = math.deg(math.atan2(self.WheelBase * yawrate, math.max(1e-15, v))) -- Reference steering degrees
		local exp = self.SteeringExponent ~= 0 and 1 / self.SteeringExponent or 1
		local max = self.SteeringAngleSlow
		local mph = self.v:GetSpeed()
		if mph < self.SteeringSpeedFast then
			max = Lerp((mph - self.SteeringSpeedSlow)
			/ (self.SteeringSpeedFast - self.SteeringSpeedSlow),
			self.SteeringAngleSlow, self.SteeringAngleFast)
		else
			max = Lerp((mph - self.SteeringSpeedFast)
			/ (self.BoostSpeed - self.SteeringSpeedFast),
			self.SteeringAngleFast, self.SteeringAngleBoost)
		end
		
		return -sign * (ref ~= ref and 1 or math.abs(ref / max)^exp)
	end
end

function ENT:DriveToWaypoint()
	do return self.BaseClass.DriveToWaypoint(self) end
	
	-- Rear wheel position feedback by https://myenigma.hatenablog.com/entry/2017/06/20/090853
	local angle_gain, dist_gain = 1, 1
	local startpos = self.PrevWaypoint and self.PrevWaypoint.Target or vehiclepos
	local way_direction = dvd.GetDir(startpos, targetpos)
	local diff_ang = math.acos(math.Clamp(way_direction:Dot(forward), -1, 1))
	local diff_len = way_direction:Cross(vehiclepos - startpos):Dot(self:GetVehicleUp())
	local currentyawrate = self.v:GetPhysicsObject():GetAngleVelocity().z
	local curvature = currentyawrate / currentspeed
	if curvature ~= curvature then curvature = 0 end
	local ref_yawrate = (velocitydot * curvature * math.cos(diff_ang)) / (1 - curvature * diff_len)
	- angle_gain * currentspeed * diff_ang - dist_gain * velocitydot * math.sin(diff_ang) * diff_len / diff_ang
	
	local yawrate_differece = (ref_yawrate - self.YawRateOld) / FrameTime()
	self.YawRateInt = self.YawRateInt + ref_yawrate * FrameTime()
	self.YawRateOld = ref_yawrate
	local desired_yawrate = sPID.x * ref_yawrate + sPID.y * self.YawRateInt + sPID.z * yawrate_differece
	-- steering = self:GetSteeringFromYawRate(desired_yawrate)
	print(desired_yawrate, self:GetSteeringFromYawRate(desired_yawrate))
end
