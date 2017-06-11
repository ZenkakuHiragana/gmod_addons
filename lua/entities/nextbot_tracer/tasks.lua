
local HEIGHT_STAND, HEIGHT_MOVE, HEIGHT_LOWERCOVER, HEIGHT_COVER, HEIGHT_CROUCH = 1, 2, 3, 4, 5

--Sets current task.
function ENT:SetTask(t, tp)
	if not istable(self.Task[t]) then return end
	self.State.Task = t
	self.State.TaskParam = tp
	return true
end

--Gets current task.
function ENT:GetTask()
	return self.State.Task, self.State.TaskParam
end

--++Tasks++---------------------{
--Nextbot tasks
--Usage:
--function ENT.Task.<TaskName>(self, arg)
--any arg | Argument which is given by schedule.
--Returning true to do a next task in the same tick,
ENT.Task = {}
function ENT.Task.IsCompleted(self)	
	local done = self.State.TaskDone
	self.State.TaskDone = nil
	return done
end
--Call when to go to next task.
function ENT.Task.Complete(self)
	self.State.TaskDone = true
	return true
end
--Call when task is failed.
function ENT.Task.Fail(self)
	self.State.TaskDone = "invalid"
	return "invalid"
end

--MaintainWeapons: deal with my weapons.
function ENT.Task.MaintainWeapons(self, baton)
	local e = self:GetEnemy()
	if e then
		if baton then
			self:Give()
		else
			self:Give(self.Memory.Distance >= self.NearDistance)
		end
	elseif self:GetActiveWeapon() then
		self:GetActiveWeapon():Remove()
	end
	self.Task.Complete(self)
end

--Wait: wait a while and rotate the head.
--Argument: Table opt | options.
----number time | time to wait.
----function func(self, opt) | function while waiting.
function ENT.Task.Wait(self, opt)
	local opt = opt or {time = 2, func = nil}
	local time = opt.time or 2
	if isfunction(opt.func) then
		opt.func(self, opt)
	end
	if CurTime() > self.Time.Task + time then
		self.Task.Complete(self)
	end
end

--WaitForMovement: wait until the current path is finished.
--Argument: Table opt | options.
----function func(self, opt) | function to do.
function ENT.Task.WaitForMovement(self, opt)
	local opt = istable(opt) and opt or {func = nil}
	local func = isfunction(opt.func) and opt.func or DoTaskList
	func(self, opt)
	if not self.Path.Main:IsValid() then
		self.Task.Complete(self)
	end
end

--SetFaceEnemy: set flag of facing enemy.
--Argument: Bool bLooking | Flag.
function ENT.Task.SetFaceEnemy(self, bLooking)
	self.Memory.FaceEnemy = bLooking
	return self.Task.Complete(self)
end

--FireWeapon: wrapper function of self:FireWeapon()
function ENT.Task.FireWeapon(self)
--	self:FireWeapon()
	self.Task.Complete(self)
end

--SetCoverFireAnim: set cover animation for firing.
function ENT.Task.SetCoverFireAnim(self)
	self.Task.Complete(self)
	if not self:GetActiveWeapon() then
		return
	end
	local FilterTable = table.Copy(self.Sensor.breakable_filter)
	table.insert(FilterTable, self:GetActiveWeapon())
	local tr = util.TraceLine({
		start = self:WorldSpaceCenter(),
		endpos = self.Memory.EnemyPosition,
		filter = FilterTable,
		mask = MASK_SHOT,
	})
	if not tr.StartSolid and not tr.HitWorld and
		tr.HitPos:DistToSqr(self.Memory.EnemyPosition) < 100e+2 then
		return
	end
	tr.HitPos.z = self:GetPos().z
	local height = util.TraceLine({
		start = tr.HitPos - tr.HitNormal + vector_up * self.Height.Eye[HEIGHT_STAND],
		endpos = tr.HitPos - tr.HitNormal,
		filter = FilterTable,
		mask = MASK_SHOT,
	})
	local wh = height.HitPos.z - self:GetPos().z
	local mz = self.Equipment.IsPrimary and
		self.Height.Muzzle.Primary or self.Height.Muzzle.Secondary
	local anim = "SMGcover"
	if self.Equipment.IsPrimary then
		if mz[HEIGHT_LOWERCOVER] > wh and wh > mz[HEIGHT_MOVE] / 2 then
			self.StandPistol = ACT_RANGE_AIM_PISTOL_LOW
		else
			self.StandPistol = ACT_IDLE_ANGRY_PISTOL
		end
	else
		if not self.Path.Main:IsValid() and mz[HEIGHT_COVER] > wh and wh > mz[HEIGHT_LOWERCOVER] then
			self:SetSequence("SMGcover")
		elseif mz[HEIGHT_LOWERCOVER] > wh and wh > mz[HEIGHT_STAND] then
			self.StandRifle = ACT_RANGE_AIM_SMG1_LOW
		else
			self.StandRifle = ACT_IDLE_ANGRY_SMG1
		end
	end
	return
end

--Reload: wrapper function of self:Reload()
function ENT.Task.Reload(self)
	self:Reload()
	self.Task.Complete(self)
end

--Advance: wrapper function of self:Advance()
function ENT.Task.Advance(self)
	if not self.Path.Main:IsValid() then
		self:Advance()
		if self.Path.Main:IsValid() then
			self.Task.Complete(self)
		else
			self.Task.Fail(self)
		end
	end
end

--Appear: wrapper function of self:Appear()
function ENT.Task.Appear(self, wait)
	if not self.Path.Main:IsValid() then
		self:Appear()
		if self.Path.Main:IsValid() then
			self.Task.Complete(self)
		else
			self.Task.Fail(self)
		end
	end
end

--Escape: wrapper function of self:Escape()
function ENT.Task.Escape(self, opt)
	if not self.Path.Main:IsValid() then
		local opt = istable(opt) and opt or {}
		self:Escape(IsValid(opt.ent) and opt.ent or self.State.Previous.HaveEnemy, opt.far, opt.overwrite)
		if self.Path.Main:IsValid() then
			self.Task.Complete(self)
		else
			self.Task.Fail(self)
		end
	end
end

--SearchCover: wrapper function of self:SearchCover()
function ENT.Task.SearchCover(self)
	if not self.Path.Main:IsValid() then
		self:SearchCover()
		if self.Path.Main:IsValid() then
			self.Task.Complete(self)
		else
			self.Task.Fail(self)
		end
	end
end

--WalkRandom: walk around random position.
--number distance | walking distance.
--bool gonext | do not wait for arrival.
function ENT.Task.WalkRandom(self, opt)
	local opt = opt or {distance = 200}
	local distance = opt.distance or 200
	if not self.Path.Main:IsValid() then
		for i = 1, 3 do
			local distance = isnumber(distance) and distance or 200
			local vec = Vector(self:XorRand(-1, 1), self:XorRand(-1, 1), 0) * distance
			if vec:LengthSqr() > 100e+2 then
				self.Path.Main:Invalidate()
				self:StartMove(self:GetPos() + vec, {movetype = "idle"})
			end
			if self.Path.Main:IsValid() and
				self.Path.Main:GetLength() < distance * 2 then break end
		end
		if not opt.wait then self.Task.Complete(self) end
	end
end

--RecomputePath: recompute the current path.
function ENT.Task.RecomputePath(self)
	if self.Path.Main:IsValid() then
		self.Path.Main:Compute(self, self.Path.Goal)
	end
	self.Task.Complete(self)
end

--InvalidatePath: invalidate the current path.
function ENT.Task.InvalidatePath(self)
	self:ClearPath()
	return self.Task.Complete(self)
end

--SwingBaton: deploy a stunstick and swing.
function ENT.Task.SwingBaton(self)
	if self.Memory.Distance < self.MeleeDistance * 0.7 then
		self.Path.Approaching = false
		timer.Simple(0.45 / (self.TrueSniper and 2 or 1), function()
			if IsValid(self) and IsValid(self.Weapon) and IsValid(self:GetEnemy())
				and self:GetRangeTo(self:GetTargetPos()) < self.MeleeDistance then
				local d = DamageInfo()
				d:SetAttacker(self)
				d:SetDamage(40)
				d:SetDamageForce(self:GetForward())
				d:SetDamagePosition(self:GetEnemy():WorldSpaceCenter())
				d:SetDamageType(DMG_DISSOLVE)
				d:SetInflictor(self.Weapon)
				d:SetMaxDamage(d:GetDamage())
				self:GetEnemy():TakeDamageInfo(d)
				self.Weapon:EmitSound("Weapon_StunStick.Melee_Hit")
			end
		end)
		self.Weapon:EmitSound("Weapon_StunStick.Swing")
		self:PlaySequenceAndWait("swing", self.TrueSniper and 2 or 1)
		self.Task.Complete(self)
	else
		if CurTime() > self.Time.Task + 1 then
			self.Task.Complete(self)
		else
			self.Path.Approaching = true
			self.loco:FaceTowards(self.Memory.EnemyPosition)
			self.loco:Approach(self.Memory.EnemyPosition, 10)
		end
	end
end

--TaskThrowGrenade: wrapper function of self:Throw()
function ENT.Task.TaskThrowGrenade(self)
	self:Throw()
	self.Time.Threw = CurTime() + 7
	self.Task.Complete(self)
end