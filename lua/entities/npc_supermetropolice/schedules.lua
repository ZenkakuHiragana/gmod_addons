--[[
	Unused nextbot AI that uses schedule system like HL2 NPCs.
]]

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

local HEIGHT_STAND, HEIGHT_MOVE, HEIGHT_LOWERCOVER, HEIGHT_COVER, HEIGHT_CROUCH = 1, 2, 3, 4, 5

--++Conditions++----------------{
local COND_NO_CUSTOM_INTERRUPTS = 70
local COND_LOW_SECONDARY_AMMO = COND_NO_CUSTOM_INTERRUPTS + 1
local COND_RELOAD_FINISHED = COND_NO_CUSTOM_INTERRUPTS + 2
local COND_PATH_FINISHED = COND_NO_CUSTOM_INTERRUPTS + 3
local COND_SCHEDULE_DONE = COND_NO_CUSTOM_INTERRUPTS + 4
--Nextbot conditions
ENT.Condition = {
	"BehindEnemy", --An enemy is behind me.
	"CanMeleeAttack", --I can swing my baton.
	"CanPrimaryAttack", --The enemy is in enough range and ready to fire.
	"CanSecondaryAttack", --The enemy is in close range and ready to fire.
	"Done", --Schedule is done.
	"EnemyDead", --Current enemy is dead and I have no enemy for now.
	"EnemyFacingMe", --The enemy is facing me.
	"EnemyOccluded", --The enemy is occluded.
	"EnemyTooFar", --The enemy is out of range, I need to draw near.
	"EnemyUnreachable", --The enemy position is unreachable for me.
	"HeavyDamage", --I've just taken a heavy damage.
	"HaveEnemyLOS", --I can see the enemy.
	"LightDamage", --I've just taken a light damage.
	"LostEnemy", --I've lost the enemy.
	"LowPrimaryAmmo", --I have low primary ammo.
	"LowSecondaryAmmo", --I have low secondary ammo.
	"MobbedByEnemies", --I'm mobbed by enemies.
	"NearDanger", --Dangerous things is near me.
	"NewEnemy", --I found a new enemy.
	"NoPrimaryAmmo", --I have no primary ammo and need to reload.
	"NoSecondaryAmmo", --I have no secondary ammo and need to reload.
	"PathFinished", --I've just finished moving.
	"ReloadFinished", --I've just finished reloading.
	"RepeatedDamage", --I take a damage repeatedly.
}
for i, v in ipairs(ENT.Condition) do
	ENT.Condition[v] = i
	ENT.Condition[i] = nil
end

--Builds some conditions of the nextbot.
--Compare e and PreviousMemory to set "EnemyDead" condition.
function ENT.Condition.Build(self, e)
	local c = {} --list of conditions
	
	c.NewEnemy = self.State.Previous.HaveEnemy ~= e --I got new enemy.
	c.LostEnemy = tobool(not e and self.State.Previous.HaveEnemy) --I had an enemy previous tick.
	c.EnemyDead = c.LostEnemy or (IsValid(e) and e:Health() <= 0) --An enemy with 0 health.
	if IsValid(e) then
		c.EnemyFacingMe = (self:GetEye().Pos --the enemy is facing me.
		 - self.Memory.EnemyPosition):GetNormalized():Dot(e:GetForward()) > 0.85
		c.EnemyTooFar = self.Memory.Distance >= self.FarDistance --the enemy is too far.
		local n = navmesh.Find(self.Memory.EnemyPosition, self.MeleeDistance,
			self.loco:GetDeathDropHeight(), self.loco:GetStepHeight())
		for k, v in pairs(n) do
			if self.loco:IsAreaTraversable(v) then n = true break end
		end
		c.EnemyUnreachable = not isbool(n) --the enemy position is unreachable.
		
		if self.Memory.Shoot then--and self:GetAimVector():Dot(self:GetForward()) > 0.7 then
			c.CanPrimaryAttack = --if I'm enough to fire primary weapon
			self.Memory.Distance < self.FarDistance and
			self.Memory.Distance >= self.NearDistance and
			self.Primary.Ammo > 0 and
			CurTime() > self.Time.Fired
			c.CanSecondaryAttack = --if I'm enough to fire secondary weapon
			self.Memory.Distance < self.NearDistance and
			self.Memory.Distance >= self.MeleeDistance and
			self.Secondary.Ammo > 0 and
			CurTime() > self.Time.Fired
			c.CanMeleeAttack = self.Memory.Distance < self.MeleeDistance --enemy is too close, beat it
		end
		c.HaveEnemyLOS = self.Memory.Look --I have LOS of the enemy.
		c.EnemyOccluded = not self.Memory.Look --I can't see the enemy.
	end
	
	for enemy in pairs(self.Memory.Enemies) do
		local tp = self:GetTargetPos(false, enemy)
		if self:CanSee(tp) and (self:GetEye().Pos - tp):GetNormalized():Dot(self:GetForward()) > 0.7 then
			c.BehindEnemy = true
			break
		end
	end
	
	--Checking weapon ammunition.
	c.NoPrimaryAmmo = self.Primary.Ammo <= 0
	c.NoSecondaryAmmo = self.Secondary.Ammo <= 0
	c.ReloadFinished = math.abs(CurTime() - self.Time.Reload) < 0.1
	c.LowPrimaryAmmo = self.Primary.Ammo > 0 and self.Primary.Ammo < self.Primary.Clip / 3
	c.LowSecondaryAmmo = self.Secondary.Ammo > 0 and self.Secondary.Ammo < self.Secondary.Clip / 3
	
	--Set if current schedule is done.
	c.Done = self.State.ScheduleProgress > #self.Schedule[self:GetSchedule()]
	c.PathFinished = self.State.Previous.Path and not (self.Path.Main:IsValid() or self.Path.Approaching)
	
	--Around my health.
	c.LightDamage = self.State.Previous.Health - self:Health() > 1
	c.HeavyDamage = self.State.Previous.Health - self:Health() > self:GetMaxHealth() / 5
	c.RepeatedDamage = self.Time.Damage - self.Time.DamageRepeated > 0.8
	if c.RepeatedDamage then self.Time.DamageRepeated = CurTime() end
	
	--Get dangerous things.
	local d, ent = self.State.GetDanger(self)
	if d then
		c.NearDanger = true
		self.Memory.DangerEntity = ent
	end
	
	--Build conditions
	for i, v in pairs(c) do
		self:AddCondition(i, v)
	end
end
--------------------------------}
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
--------------------------------}
--++Schedules++-----------------{
--Nextbot schedules
--Usage:
--function Init(self) | Initializes the schedule.
--Table Interrupts | Defines interrupt functions.
----"<ConditionName>"
--string List of TaskNames
ENT.Schedule = {
Add = function(self, key, init, interrupts, tasks)
	self[key] = {}
	if isfunction(init) then
		self[key].Init = init
	else
		interrupts, tasks = init, interrupts
	end
	self[key].Interrupts = interrupts
	if istable(tasks) then table.Add(self[key], tasks) end
end}

--Determine what schedule should do.
ENT.Schedule.Build = {
	[NPC_STATE_IDLE] = function(self)
		--Sometimes look behind the nextbot.
		if CurTime() > self.Time.LookBack and self:XorRand() < 0.5 then
			self.Time.LookBack = CurTime() + 10
			return "TurnBack"
		else --Just wander around.
			return "Idle"
		end
	end,
	[NPC_STATE_ALERT] = function(self)
		--TODO: Patrol around and hear the world.
		--Also can receive other squad mate's radio.
		return "PatrolAround"
	end,
	[NPC_STATE_COMBAT] = function(self)
		--Main combat schedule.
		local sched = "TakeCover"
		--The enemy is enough close, deploy my baton.
		if self:HasCondition("CanMeleeAttack") then
			sched = "SwingBaton"
		--I have low/no ammo, reload.
		elseif self:HasCondition("NoPrimaryAmmo") or
			self:HasCondition("NoSecondaryAmmo") or
			(self:XorRand() < 0.3 and
			(self:HasCondition("LowPrimaryAmmo") or
			self:HasCondition("LowSecondaryAmmo")))then
			sched = "HideAndReload"
		--I've taken damage and feel dangerous, flee.
		elseif self:HasCondition("NearDanger") or
			self:HasCondition("HeavyDamage") or
			self:HasCondition("RepeatedDamage") or
			(self:Health() < self:GetMaxHealth() / 2 and
			self:HasCondition("LightDamage")) then
			sched = "Escape"
		--I think an enemy is behind me, turn my head back.
		elseif self:HasCondition("BehindEnemy") then
			sched = "TurnBack"
		--Enemy is occluded and past enough time, throw.
		elseif self:HasCondition("EnemyOccluded") and
			CurTime() > self.Time.Saw + 3 and
			self.Memory.Distance > self.NearDistance / 2 and
			CurTime() > self.Time.Threw then
			sched = "ThrowGrenade"
		--The enemy is not visible, chase it.
		elseif not self.Memory.Shoot or self:HasCondition("EnemyOccluded") then
			sched = "AppearUntilSee"
		else
			local d = 10
			local l, r = util.TraceLine({
				start = self:GetEye().Pos - self:GetRight() * d,
				endpos = self.Memory.EnemyPosition,
				filter = self.Sensor.breakable_filter,
				mask = MASK_SHOT,
			}), util.TraceLine({
				start = self:GetEye().Pos + self:GetRight() * d,
				endpos = self.Memory.EnemyPosition,
				filter = self.Sensor.breakable_filter,
				mask = MASK_SHOT,
			})
		--	debugoverlay.Line(l.StartPos, l.HitPos)
		--	debugoverlay.Line(r.StartPos, r.HitPos)
			--Hide if additional traces hit the enemy.
			if l.HitPos:DistToSqr(self.Memory.EnemyPosition) < 100e+2 and
				r.HitPos:DistToSqr(self.Memory.EnemyPosition) < 100e+2 then
				sched = "TakeCover"
			--The enemy notices me, and I can attack, fire.
			elseif self:HasCondition("EnemyFacingMe") or 
				self:HasCondition("CanPrimaryAttack") or
				self:HasCondition("CanSecondaryAttack") then
				sched = "RangeAttack"
			--Go to enemy position.
			else
				sched = "Advance"
			end
		end
		return sched
	end,
}

--==Idle==----------------------{
ENT.Schedule:Add(
	"Idle", function(self)
		self.Task.Variable = self:XorRand(40, 55)
	end,{
	"NearDanger",
	"NewEnemy",
	"LightDamage",
	"HeavyDamage",
	"ReceiveEnemyInfo",
},{
	"InvalidatePath",
	"MaintainWeapons",
	"SetFaceEnemy",
	"WalkRandom",
	"WaitForMovement",
	{"Wait", {func = function(self, opt)
		local time = opt.time or 2
		self:SetPoseParameter("head_yaw", --Rotate the head.
			math.sin((self.Time.Task + time - CurTime())
			/ time * 2 * math.pi) * self.Task.Variable)
	end}},
	"Reload",
	"Reload",
})
--------------------------------}
--==PatrolAround==--------------{
ENT.Schedule:Add(
	"PatrolAround", {
	"NearDanger",
	"NewEnemy",
	"HaveEnemyLOS",
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"CanMeleeAttack",
	"LightDamage",
	"HeavyDamage",
	"ReceiveEnemyInfo",
},{
	"SetFaceEnemy",
	"InvalidatePath",
	{"Wait", {time = 0.7}},
	"SetFaceEnemy",
	{"WalkRandom", {distance = 350}},
	"Reload",
	"WaitForMovement",
})
--------------------------------}
--==Advance==-------------------{
ENT.Schedule:Add(
	"Advance", {
	"LightDamage",
	"HeavyDamage",
	"RepeatedDamage",
	"CanSecondaryAttack",
	"CanMeleeAttack",
	"NewEnemy",
	"EnemyDead",
	"MobbedByEnemies",
},{
	"InvalidatePath",
	"MaintainWeapons",
	{"SetFaceEnemy", true},
	"Advance",
	"SetCoverFireAnim",
	{"WaitForMovement", {"FireWeapon"}}
})	
--------------------------------}
--==Escape==--------------------{
ENT.Schedule:Add(
	"Escape", {
	"NewEnemy",
	"HeavyDamage",
	"EnemyDead",
	"EnemyOccluded",
},{
	"InvalidatePath",
	"MaintainWeapons",
	{"SetFaceEnemy", true},
	"Escape",
	{"Wait", {time = 1.2, func = DoTaskList, "FireWeapon"}},
})
--==TakeCover==-----------------{
ENT.Schedule:Add(
	"TakeCover", {
	"HeavyDamage",
	"NewEnemy",
	"EnemyDead",
	"CanMeleeAttack",
},{
	"InvalidatePath",
	"MaintainWeapons",
	{"SetFaceEnemy", true},
	"SetCoverFireAnim",
	"SearchCover",
	{"Wait", {time = 3.5, func = DoTaskList, "FireWeapon"}},
})
--------------------------------}
--==RangeAttack==---------------{
ENT.Schedule:Add(
	"RangeAttack", {
	"NearDanger",
	"NoPrimaryAmmo",
	"NoSecondaryAmmo",
	"LowPrimaryAmmo",
	"LowSecondaryAmmo",
	"EnemyDead",
	"EnemyOccluded",
},{
	"InvalidatePath",
	{"SetFaceEnemy", true},
	"SetCoverFireAnim",
	"MaintainWeapons",
	"FireWeapon",
})
--------------------------------}
--==AppearUntilSee==------------{
ENT.Schedule:Add(
	"AppearUntilSee", {
	"NearDanger",
--	"HaveEnemyLOS",
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"CanMeleeAttack",
	"EnemyDead",
	"NewEnemy",
},{
	"InvalidatePath",
	"MaintainWeapons",
	"Appear",
	"SetCoverFireAnim",
	"WaitForMovement",
})
--------------------------------}
--==HideAndReload==-------------{
ENT.Schedule:Add(
	"HideAndReload", {
	"NearDanger",
	"NewEnemy",
	"ReloadFinished",
},{
	"InvalidatePath",
	"MaintainWeapons",
	"Escape",
	{"WaitForMovement", {
	"Reload",
	"FireWeapon",}},
	"Reload",
})
--------------------------------}
--==SwingBaton==----------------{
ENT.Schedule:Add(
	"SwingBaton", {
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"EnemyDead",
	"EnemyOccluded",
	"EnemyUnreachable",
	"HeavyDamage",
	"LostEnemy",
	"NewEnemy",
	"RepeatedDamage",
},{
	"InvalidatePath",
	{"SetFaceEnemy", true},
	{"MaintainWeapons", true},
	"SwingBaton",
})
--------------------------------}
--==ThrowGrenade==--------------{
ENT.Schedule:Add(
	"ThrowGrenade", {
	"NearDanger",
},{
	"InvalidatePath",
	{"SetFaceEnemy", true},
	"MaintainWeapons",
	"TaskThrowGrenade",
})
--------------------------------}
--==TurnBack==------------------{
ENT.Schedule:Add(
	"TurnBack", function(self)
		self.Task.Variable = (self:XorRand() < 0.5) and 1 or -1
	end, {
	"NearDanger",
	"LightDamage",
	"HeavyDamage",
	"MobbedByEnemies",
	"CanPrimaryAttack",
	"CanSecondaryAttack",
	"CanMeleeAttack",
},{
	"MaintainWeapons",
	{"Wait", {time = 1.5, func = function(self)
		local fraction = math.sin(((self.Time.Task + 1.5 - CurTime()) / 1.5) * math.pi) * self.Task.Variable	
		self:SetPoseParameter("body_yaw", fraction * 30) --Rotate the body.
		self:SetPoseParameter("spine_yaw", fraction * 30) --Rotate the spine.
		self:SetPoseParameter("head_yaw", fraction * 60) --Rotate the head.
	end}},
	{"Wait", {time = 0.4}},
})
--------------------------------}
--------------------------------}
