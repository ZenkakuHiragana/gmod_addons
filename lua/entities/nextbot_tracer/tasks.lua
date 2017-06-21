
local HEIGHT_STAND, HEIGHT_MOVE, HEIGHT_LOWERCOVER, HEIGHT_COVER, HEIGHT_CROUCH = 1, 2, 3, 4, 5

--Sets current task.
function ENT:SetTask(t)
	self.State.Task = t
	self.State.TaskParam = nil
	if istable(self.State.Task) then
		self.State.TaskParam = self.State.Task[2]
		self.State.Task = self.State.Task[1]
	end
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
	local taskstate = self.Task.IsCompleted(self)
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
	self.State.TaskDone = taskstate
end

--++Tasks++---------------------{
--Nextbot tasks
--Usage:
--function ENT.Task.<TaskName>(self, arg)
--any arg | Argument which is given by schedule.
--Returning true to do a next task in the same tick,
ENT.Task = {}
function ENT.Task.IsCompleted(self)
	return self.State.TaskDone
end
--Call when the current task is finished.
function ENT.Task.Clear(self)
	self.State.TaskDone = nil
end
--Call when to go to next task.
function ENT.Task.Complete(self)
	self.State.TaskDone = true
	return true
end
--Call when task is failed.
function ENT.Task.Fail(self, reason)
	self.State.FailReason = isstring(reason) and reason or "NoReasonGiven"
	self.State.TaskDone = "invalid"
	return "invalid"
end

--SetFailSchedule: set an alternative schedule when the current task is failed.
--Argument:
----string alt | the alternative schedule.  can be nil.
function ENT.Task.SetFailSchedule(self, alt)
	self.State.FailSchedule = alt
	return self.Task.Complete(self)
end

--Wait: wait a while and rotate the head.
--Argument: Table opt | options.
----number time | time to wait.
----function func(self, opt) | function while waiting.
function ENT.Task.Wait(self, opt)
	local opt = istable(opt) and opt or {time = 2, func = nil}
	local func = isfunction(opt.func) and opt.func or DoTaskList
	local time = opt.time or 2
	if not isnumber(time) and isnumber(self.State.TaskVariable) then
		time = self.State.TaskVariable
	end
	
	func(self, opt)
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
		return self.Task.Complete(self)
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
	timer.Simple(0.2, function()
		if not IsValid(self) or not self:GetEnemy() then return end
		if self:WorldSpaceCenter():DistToSqr(self:GetEnemy():WorldSpaceCenter()) > self.Dist.MeleeSqr then return end
		if self:GetAimVector(self:GetEnemy():WorldSpaceCenter()):Dot(self:GetForward()) > math.cos(math.rad(60)) then
			self:GetEnemy():TakeDamage(30, self, self)
		end
	end)
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
	return self.Task.Complete(self)
end

--Appear: wrapper function of self:Appear()
function ENT.Task.Appear(self, wait)
	if self:SetDesiredPosition() then
		return self.Task.Complete(self)
	else
		self.Task.Fail(self)
	end
end

--MakeDistance: Make a distance from the enemy.
function ENT.Task.MakeDistance(self, distance)
	if self:SetDesiredPosition({
		spottype = "MakeDistance", see = true,
		nearest = false, range = self.Dist.FindSpots / 5}) then
		return self.Task.Complete(self)
	else
		self.Task.Fail(self)
	end
end

--Escape: search a position that takes a cover from the enemy.
function ENT.Task.Escape(self, opt)
	local opt = opt or {}
	if self:SetDesiredPosition({spottype = "Escape", see = false, nearest = true}) then
		if opt.nearby then
			local path = Path("Follow")
			path:Compute(self, self.Path.DesiredPosition)
			if path:GetLength() > self.Dist.Blink * 3 then
				self.Task.Fail(self, self.FailReason.InvalidPath)
			end
		end
		return self.Task.Complete(self)
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

--SetRunFromEnemy: decide a random position but run away.
function ENT.Task.SetRunFromEnemy(self, opt)
	local opt = istable(opt) and opt or {}
	self:GotoRandomDirection(-self:GetAimVector(), opt.deg or 50, opt.dist)
	self.Task.Complete(self)
end

--SetRunIntoEnemy: decide a random position but approach.
function ENT.Task.SetRunIntoEnemy(self, opt)
	local opt = istable(opt) and opt or {}
	self:GotoRandomDirection(self:GetAimVector(), opt.deg or 50, opt.dist)
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

--TurnBackToWall: turn my back to the wall.
function ENT.Task.TurnBackToWall(self)
	local mins, maxs = self:GetCollisionBounds()
	local tr = util.TraceHull({
		start = self:GetPos() + vector_up * self.StepHeight,
		endpos = self:GetPos() + vector_up * self.StepHeight + self:GetForward() * 100,
		mins = mins, maxs = maxs, filter = {self, self.Equipment.Entity}
	})
	if tr.Hit then
		self.loco:FaceTowards(self:GetPos() + tr.HitNormal * 20)
	else
		self.Task.Complete(self)
	end
end

--SetBlinkDirection: Sets the position after using blink.
--Argument:
----string mode | Blink mode: "TowardEnemy", "Dodge"
function ENT.Task.SetBlinkDirection(self, mode)
	if self.BlinkRemaining <= 0 or CurTime() < self.Time.Blink then
		self.Time.Blink = CurTime() + 1
		return self.Task.Fail(self)
	end
	
	local mode = isstring(mode) and mode or "TowardEnemy"
	local dir = vector_origin
	local aim = self:GetAimVector()
	aim.z = 0
	aim:Normalize()
	if mode == "TowardEnemy" then
		dir = aim
		local path = Path("Follow")
		path:Compute(self, self.Memory.EnemyPosition)
		if path:IsValid() then
			local seg = path:FirstSegment()
			if seg then dir = seg.forward end
		end
	elseif mode == "FromEnemy" then
		dir = -aim
	elseif mode == "Sidestep" then
		aim:Rotate(Angle(0, -90, 0))
		
		if self.Debug.BlinkDestination then
			debugoverlay.Line(self:GetPos(), self:GetPos() + aim * self.Dist.Blink, 5, Color(255,255,0,255),true)
			debugoverlay.Sphere(self:GetPos() + dir * self.Dist.Blink, 50, 2, Color(0,255,0,255), true)
		end
		
		local mins, maxs = self:GetCollisionBounds()
		local tr = {
			start = self:WorldSpaceCenter(), 
			endpos = self:WorldSpaceCenter() + aim * self.Dist.Blink,
			mins = mins, maxs = maxs, mask = MASK_NPCSOLID_BRUSHONLY, filter = self,
		}
		local right = util.TraceHull(tr)
		tr.endpos = self:WorldSpaceCenter() - aim * self.Dist.Blink
		local left = util.TraceHull(tr)
		
		if right.Hit and left.Hit then
			dir = right.Fraction > left.Fraction and aim or -aim
		elseif right.Hit then
			dir = -aim
		elseif left.Hit then
			dir = aim
		else
			dir = math.random() > 0.5 and aim or -aim
		end
	end
	
	self.Memory.BlinkDirection = dir
	
	if self.Debug.BlinkDestination then
		debugoverlay.Line(self:GetPos(), self:GetPos() + dir * self.Dist.Blink, 5, Color(0,255,0,255),true)
		debugoverlay.Sphere(self:GetPos() + dir * self.Dist.Blink, 20, 2, Color(0,255,0,255), true)
	end
	
	return self.Task.Complete(self)
end

--Blink: Teleport to self.Memory.BlinkDirection.
function ENT.Task.Blink(self)
	self:PlayBlink()
	
	local destination = self:GetPos() + self.Memory.BlinkDirection * self.Dist.Blink
	local tracedestination = destination + vector_up * self.StepHeight
	local contents = bit.bor(CONTENTS_EMPTY, CONTENTS_WATER, CONTENTS_TESTFOGVOLUME, CONTENTS_TRANSLUCENT)
	local mins, maxs = self:GetCollisionBounds()
	local traceStructure = {
		start = self:GetPos() + vector_up * self.StepHeight, endpos = tracedestination,
		mins = mins, maxs = maxs, filter = {self, self.Equipment.Entity},
	}
	local straightTrace = util.TraceHull(traceStructure)
	if self.Debug.BlinkTraces then
		debugoverlay.Box(traceStructure.start, traceStructure.mins, traceStructure.maxs, 2)
		debugoverlay.Box(traceStructure.endpos, traceStructure.mins, traceStructure.maxs, 2)
	end
	local verticalTrace, verticalStartZ = {}, traceStructure.start.z
	for i = 1, 20 do
		if straightTrace.Hit and math.abs(straightTrace.HitNormal:Dot(vector_up)) > math.cos(math.rad(45)) then
			traceStructure.start = straightTrace.HitPos
			verticalStartZ = traceStructure.start.z
			traceStructure.endpos = straightTrace.HitPos + vector_up * 100000
			verticalTrace = util.TraceHull(traceStructure)
			if self.Debug.BlinkTraces then
				debugoverlay.Box(traceStructure.start, traceStructure.mins, traceStructure.maxs, 2, Color(0,255,0))
				debugoverlay.Box(traceStructure.endpos, traceStructure.mins, traceStructure.maxs, 2, Color(0,255,0))
			end
			
			traceStructure.start = verticalTrace.HitPos
			traceStructure.endpos = tracedestination
			traceStructure.endpos.z = verticalTrace.HitPos.z
			straightTrace = util.TraceHull(traceStructure)
			
			if self.Debug.BlinkTraces then
				debugoverlay.Box(traceStructure.start, traceStructure.mins, traceStructure.maxs, 2)
				debugoverlay.Box(traceStructure.endpos, traceStructure.mins, traceStructure.maxs, 2)
			end
		else
			traceStructure.start = straightTrace.HitPos
			traceStructure.endpos = straightTrace.HitPos
			traceStructure.endpos.z = verticalStartZ
			verticalTrace = util.TraceHull(traceStructure)
			destination = verticalTrace.HitPos
			
			if self.Debug.BlinkTraces then
				debugoverlay.Box(traceStructure.start, traceStructure.mins, traceStructure.maxs, 2, Color(255,255,0))
				debugoverlay.Box(traceStructure.endpos, traceStructure.mins, traceStructure.maxs, 2, Color(255,255,0))
			end
			break
		end
		coroutine.yield()
	end
--	destination = destination + vector_up * self.StepHeight
	
	if self.Debug.BlinkDestination then debugoverlay.Sphere(destination, 20, 5, Color(0, 255, 0), true) end
	if util.IsInWorld(destination) then
		self.Trail:SetKeyValue("LifeTime", 0.6)
	--	local trail = util.SpriteTrail(self, self:LookupAttachment("chest"), 
		--	Color(0, 128, 255, 192), true, 40, 0, 1.2, 0.1, "effects/blueblacklargebeam.vmt")
		self:SetPos(destination)
		local blinktimer = "BlinkTrailRollback" .. self:EntIndex()
		local timerfunc = timer.Exists(blinktimer) and timer.Adjust or timer.Create
		timerfunc(blinktimer, 0.3, 1, function()
			if not IsValid(self) or not IsValid(self.Trail) then return end
			self.Trail:SetKeyValue("LifeTime", 0.1)
		end)
	--	SafeRemoveEntityDelayed(trail, 1.2)
		self.Time.Blink = CurTime() + 0.2
		self.BlinkRemaining = self.BlinkRemaining - 1
		timer.Simple(3, function()
			if not IsValid(self) then return end
			self.BlinkRemaining = self.BlinkRemaining + 1
		end)
		return self.Task.Complete(self)
	else
		self.Time.Blink = CurTime() + 1
		return self.Task.Fail(self)
	end
end