
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

--Do a list of functions.
--Argument: Table t | list of functions.
--function | (function, argument) | taskname | (taskname, argument)
local function DoTaskList(self, l)
	if not istable(l) then return end
	for i, t in ipairs(l) do
		if isfunction(t) then
			if t(self) then break end
		elseif isstring(t) then
			if self.Task[t](self) then return end
		elseif istable(t) then
			if isfunction(t[1]) then
				if t[1](self, t[2]) then break end
			elseif isstring(t[1]) then
				if self.Task[t[1]](self, t[2]) then break end
			end
		end
	end
	self.State.TaskDone = nil
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

--Wait: wait a while and rotate the head.
--Argument: Table opt | options.
----number time | time to wait.
----function func(self, opt) | function while waiting.
function ENT.Task.Wait(self, opt)
	local opt = istable(opt) and opt or {time = 2, func = nil}
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
	self.Memory.Look = bLooking
	return self.Task.Complete(self)
end

--MeleeAttack: do a melee attack.
function ENT.Task.MeleeAttack(self)
	if CurTime() < self.Time.Melee then self.Task.Fail(self) return end
	if not self:GetEnemy() then self.Task.Fail(self) return end
	self:AddGesture(self.Act.Melee)
	self:GetEnemy():TakeDamage(30, self, self)
	self.Time.Melee = CurTime() + 1.1
	self.Task.Complete(self)
end

--FireWeapon: wrapper function of self:FireWeapon()
function ENT.Task.FireWeapon(self)
	self.Equipment.Fire(self, self.Equipment.Entity)
	self.Task.Complete(self)
end

--Reload: wrapper function of self:Reload()
function ENT.Task.Reload(self)
	self:ReloadWeapon()
	self.Task.Complete(self)
end

--Advance: wrapper function of self:Advance()
function ENT.Task.Advance(self)
	self.Path.DesiredPosition = self.Memory.EnemyPosition
	self.Task.Complete(self)
end

--Appear: wrapper function of self:Appear()
function ENT.Task.Appear(self, wait)
	if self:SetDesiredPosition() then
		self.Task.Complete(self)
	else
		self.Task.Fail(self)
	end
end

--Escape: wrapper function of self:EscapeFromEnemy()
function ENT.Task.Escape(self, opt)
	if self:SetDesiredPosition({spottype = "Escape", see = false, nearest = true}) then
		self.Task.Complete(self)
	else
		self.Task.Fail(self)
	end
end

--SetRandomPosition: walk around random position.
function ENT.Task.SetRandomPosition(self, opt)
	local opt = istable(opt) and opt or {}
	self:GotoRandomPosition(opt.dist)
	self.Task.Complete(self)
end

--RecomputePath: recompute the current path.
function ENT.Task.RecomputePath(self)
	if self.Path.Main:IsValid() then
		self.Path.Main:Compute(self, self.Path.DesiredPosition)
	end
	self.Task.Complete(self)
end

--InvalidatePath: invalidate the current path.
function ENT.Task.InvalidatePath(self)
	self.Path.Main:Invalidate()
	return self.Task.Complete(self)
end

--StartMove: start moving toward self.Path.DesiredPosition
function ENT.Task.StartMove(self)
	self:StartMove()
	return self.Task.Complete(self)
end

--SetBlinkPosition: Sets the position after using blink.
--Argument:
----string mode | Blink mode: "TowardEnemy", "Dodge"
function ENT.Task.SetBlinkPosition(self, mode)
	if not isstring(mode) or CurTime() < self.Time.Blink then
		self.Memory.BlinkPosition = nil
		self.Task.Complete(self)
		return
	elseif self.BlinkRemaining <= 0 then
		self.Task.Fail(self)
		return
	end
	if mode == "TowardEnemy" then
		local pos = self:WorldSpaceCenter() + (self.Memory.EnemyPosition
			- self:WorldSpaceCenter()):GetNormalized() * self.Dist.Blink
		local tr = util.TraceHull({
			start = self:WorldSpaceCenter(), 
			endpos = pos,
			maxs = self:OBBMaxs(), mins = self:OBBMins(),
			mask = MASK_NPCSOLID_BRUSHONLY,
			filter = self,
		})
		if tr.Hit then
			pos = tr.HitPos
		end
		
		self.Memory.BlinkPosition = pos
		debugoverlay.Line(pos, pos + vector_up * 100, 2, Color(0,255,0,255))
	end
	
	self.Task.Complete(self)
end

--Blink: Teleport to self.Memory.BlinkPosition.
function ENT.Task.Blink(self)
	if not isvector(self.Memory.BlinkPosition) or
		self.Memory.BlinkPosition:DistToSqr(self:GetPos()) > self.Dist.BlinkSqr * 1.02 then
		self.Task.Fail(self)
		return
	end
	
	local trace = util.SpriteTrail(self, self:LookupAttachment("chest"), 
		Color(0, 128, 255, 192), true, 20, 0, 0.5, 1/10, "effects/blueblacklargebeam.vmt")
	local tr = util.QuickTrace(self.Memory.BlinkPosition + vector_up * self.Dist.Blink, 
		-vector_up * (self.Dist.Blink + self:OBBMaxs().z / 2), self)
	
	self:SetPos(tr.HitPos)
	SafeRemoveEntityDelayed(trace, 0.5)
	self.Time.Blink = CurTime() + 0.2
	self.BlinkRemaining = self.BlinkRemaining - 1
	self.Task.Complete(self)
end
