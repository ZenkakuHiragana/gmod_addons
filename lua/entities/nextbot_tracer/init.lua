
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("npcmeta.lua")
include("animation.lua")
include("hook.lua")
include("movement.lua")
include("schedules.lua")
include("targeting.lua")
include("weapon.lua")
include("sounds.lua")

----------------------------------------------{
--init.lua
--Root of the whole source code.
--Initialize function and RunBehaviour() are here.
----------------------------------------------}

--++Initializes++-----------------------------{
--Defines around timers.
function ENT:InitializeTimers()
	self.Time = {}
	self.Time.ApproachingChecked = CurTime()	--For "EnemyApproaching" condition
	self.Time.Blink = CurTime()					--Blink cooldown
	self.Time.Damage = CurTime()				--Last time damage taken
	self.Time.Fire = CurTime()					--Fire primary weapon
	self.Time.Melee = CurTime()					--Melee attack cooldown
	self.Time.Move = CurTime()					--Start moving to somewhere
	self.Time.Reload = CurTime()				--Reloading
	self.Time.RepeatedDamage = CurTime()		--Flag as repeated damage
	self.Time.Schedule = CurTime()				--Begin a schedule
	self.Time.SeeEnemy = CurTime()				--Last time the enemy seen
	self.Time.Task = CurTime()					--Begin a task
	self.Time.Touch = CurTime()	 - 1			--On contact someone
	
	self.Time.ApproachingInterval = 0.5			--For "EnemyApproaching" condition
	self.Time.RepeatedDamageDuration = 0.8		--If the nextbot has taken damage for this time, set "RepeatedDamage" condition.
	self.Time.ResetRepeatedDamage = 3			--Reset "RepeatedDamage" condition timer after several seconds.
end

--Defines some variables.
function ENT:InitializeVariables()
	self.Equipment = self:CreatePulsePistols() --Weapons info
	self.EyeHeight = self:GetEye().Pos.z - self:GetPos().z
	self.DesiredSpeed = self.Speed.Run
	
	--Tracer's ability--------------
	self.BlinkRemaining = 3
	self.BlinkSoundLevel = 1
	--------------------------------
	
	--Path finding------------------
	self.Path = {}
	self.Path.Main = Path("Follow")
	self.Path.Main:SetMinLookAheadDistance(400)
	self.Path.Main:SetGoalTolerance(20)
	self.Path.DesiredPosition = self:GetPos() --Move to this position
	--------------------------------
	
	--Personal memories-------------
	self.Memory = {}
	self.Memory.Crouch = false --Crouch flag.
	self.Memory.CrouchNav = false --Forced to crouch by navarea.
	self.Memory.Enemies = {} --Enemy pool.
	self.Memory.Enemy = nil --Target entity.
	self.Memory.EnemyAimVector = self:GetForward() --The enemy's looking at.
	self.Memory.EnemyPosition = self:GetEye().Pos --I know his last position I've seen.
	self.Memory.DangerEntity = nil --An entity that I should run away from.
	self.Memory.Distance = 0 --Distance from myself to the enemy.
	self.Memory.Jump = false --Should jump or not.
	self.Memory.Look = false --Should look at the enemy or not.
	self.Memory.Walk = false --Walk for surpressing footsteps.
	self.Memory.WalkNav = false --Forced to walk by navarea.
	--------------------------------
	
	--Timers------------------------
	self:InitializeTimers()
	--------------------------------
	
	--Conditions--------------------
	self:InitializeState()
	--------------------------------
end

--Initializes this NPC.
local CheersLove_Time = CurTime()
function ENT:Initialize()
	--So that we can see through breakable things.
	self.breakable_filter = ents.FindByClass("func_breakable")
	table.Add(self.breakable_filter, ents.FindByClass("func_breakable_surf"))
	table.insert(self.breakable_filter, self)
	
	--Shared functions
	self:SetModel(self.Model)
--	self:SetFlexWeight(self:GetFlexIDByName("mouth_sideways"), 0.5)
--	self:SetFlexWeight(self:GetFlexIDByName("jaw_sideways"), 0.5)
	self:SetHealth(self.HP.Init)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:AddFlags(FL_AIMTARGET)
	self:SetSolid(SOLID_BBOX)
	self:MakePhysicsObjectAShadow(true, true)
	
	--Server functions
	self:InitializeVariables()
	self:SetUseType(SIMPLE_USE)
	self:SetMaxHealth(self.HP.Init)
	self:StartActivity(self.Act.Idle)
	self.loco:SetStepHeight(self.StepHeight)
	self.loco:SetMaxYawRate(self.MaxYawRate)
	self.loco:SetDesiredSpeed(self.DesiredSpeed)
	self.loco:SetAcceleration(self.Speed.Acceleration)
	self.loco:SetDeceleration(self.Speed.Deceleration)
	
	--SpriteTrail on the back
	self.Trail = util.SpriteTrail(self, self:LookupAttachment("chest"), 
		Color(0, 128, 255, 192), true, 20, 0, 0.1, 0.1, "effects/blueblacklargebeam.vmt")
	self.Trail:DeleteOnRemove(self)
	
	--Cheers, love!  The cavalry's here!
	if CurTime() > CheersLove_Time then
		self:SetScene("scenes/nextbot_tracer_onspawn.vcd")
		CheersLove_Time = CurTime() + math.Rand(15, 30)
	end
end
----------------------------------------------}

--Main coroutine of behavior.
function ENT:RunBehaviour()
	while true do
		if not self:GetConVarBool("ai_disabled") then
			local sched, progress = self:GetSchedule()
			if not istable(self.Schedule[sched]) then self:SetSchedule("Idle") end
			
			--Perform sensing.
			local nearestenemy, e = self:FindEnemy(), self:GetEnemy()
			if IsValid(nearestenemy) then self:SetEnemy(nearestenemy) end
			
			--For "EnemyApproaching" condition.
			if CurTime() + self.Time.ApproachingInterval > 
				self.Time.ApproachingChecked then
				self.Time.ApproachingChecked = CurTime()
				self.State.Previous.ApproachingPos = self.Memory.EnemyPosition
			end
			
			self:UpdateEnemyMemory() --Update enemy info.
			self:BuildConditions(self:GetEnemy()) --Build conditions.
			
			--Stop current schedule if it has an interrupt condition.
			for i, interrupt in ipairs(self.Schedule[sched].Interrupts) do
				local intr = istable(interrupt) and interrupt[1] or interrupt
				if self:HasCondition(intr) then
					self.State.FailReason = self.FailReason.InterruptByCondition
					if istable(interrupt) then self.State.FailSchedule = interrupt[2] end
					self.State.InterruptCondition = intr
					self.State.ScheduleProgress = math.huge
					break
				end
			end
			
			self.State.Build(self) --Choose a NPC state.
			if self:HasCondition("Done") then --Select a new schedule.
				self:SetSchedule(self.State.FailSchedule or --If there's FailSchedule, do it.
				self.Schedule.Build[self:GetState()](self))
				self.State.FailSchedule = nil
			end
			
			--Do current schedule.
			for i = 1, 10 do --This should be: while true do
				sched, progress = self:GetSchedule() --Pick up current task.
				self:SetTask(self.Schedule[sched][progress])
				if isfunction(self.Task[self.State.Task]) then
					local taskreturn = self.Task[self.State.Task](self, self.State.TaskParam)
					local completed = self.Task.IsCompleted(self)
					if CurTime() > self.Time.Task + 10 or completed then --Current task is completed, go to next task.
						self.Task.Clear(self)
						if completed == "invalid" then --Task is failed.
							self.State.ScheduleProgress = math.huge --Abort the schedule.
							break
						end
						--Task acomplished.
						self.Time.Task = CurTime()
						self.State.ScheduleProgress = self.State.ScheduleProgress + 1
						if self.State.ScheduleProgress > #self.Schedule[sched] then
							break
						end
					end
					--taskreturn == true and task is completed, go to next task.
					if not (completed and taskreturn) then break end
				end
			end
			
			self.State.Previous.HaveEnemy = self:GetEnemy() --For "EnemyDead"
			self.State.Previous.Health = self:Health() --For "LightDamage", "HeavyDamage"
			self.State.Previous.Path = self.Path.Main:IsValid() or self.Path.Approaching --For "PathFinished"
			
			if self.Path.Main:IsValid() then self:UpdatePosition() end
			
			for k, v in pairs(ents.FindInSphere(self:GetEye().Pos, 60)) do
				if string.find(v:GetClass(), "door") then
					v:Input("Open", self, self)
					v:Input("OpenAwayFrom", self, self, self:GetClass())
					constraint.NoCollide(self, v, 0, 0)
				end
			end
		end
		coroutine.wait(0.1)
		coroutine.yield()
	end
end

-- function ENT:RunBehaviour()
	-- self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	-- self:StartActivity(ACT_HL2MP_WALK_DUEL)
	-- self:AddGesture(ACT_HL2MP_WALK_DUEL, false)
	-- self:SetPoseParameter("move_x", -1)
	-- self:SetPoseParameter("vertical_velocity", -1)
	-- self:AddGestureSequence(self:LookupSequence("shotgun_pump"))
	-- while true do
		-- self:PlaySequenceAndWait("taunt_laugh")
		-- self:MoveToPos(self:GetPos() + self:GetForward() * 300)
		-- coroutine.yield()
	-- end
-- end
