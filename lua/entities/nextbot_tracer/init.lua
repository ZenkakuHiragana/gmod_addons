
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
ENT.Replacement[1](ENT)

----------------------------------------------{
--init.lua
--Root of the whole source code.
--Initialize function and RunBehaviour() are here.
----------------------------------------------}

--++Initializes++-----------------------------{

--Initializes recording data for recall ability.
function ENT:InitializeRecallInfo()
	for i = 1, self.RecallInfoSize do
		self.RecallInfo[i] = {
			health = self:Health(),
			pos = self:GetPos(),
			ang = self:GetAngles(),
			aim_yaw = self:GetPoseParameter("aim_yaw"),
			aim_pitch = self:GetPoseParameter("aim_pitch"),
		}
	end
end

--Defines around timers.
function ENT:InitializeTimers()
	self.Time = {}
	self.Time.ApproachingChecked = CurTime()	--For "EnemyApproaching" condition
	self.Time.Blink = CurTime()					--Blink cooldown
	self.Time.Damage = CurTime()				--Last time damage taken
	self.Time.FindEnemy = CurTime()				--Update enemy info
	self.Time.FindHealthKit = CurTime()			--Re-find health kit
	self.Time.Fire = CurTime()					--Fire primary weapon
	self.Time.HealthChecked = CurTime()			--For "CanRecall" condition
	self.Time.Melee = CurTime()					--Melee attack cooldown
	self.Time.Move = CurTime()					--Start moving to somewhere
	self.Time.Recall = CurTime()				--Recall cooldown
	self.Time.RecordRecallInfo = CurTime()		--I had better use timer.Create(), perhaps.
	self.Time.Reload = CurTime()				--Reloading
	self.Time.RepeatedDamage = CurTime()		--Flag as repeated damage
	self.Time.Schedule = CurTime()				--Begin a schedule
	self.Time.SearchPlayer = CurTime()			--Follow player automatically
	self.Time.SeeEnemy = CurTime()				--Last time the enemy seen
	self.Time.SetBehindEnemy = CurTime()		--Set an enemy behind me instead of current enemy
	self.Time.SpeakUnderstood = CurTime()		--Prevent spamming "Understood!"
	self.Time.Task = CurTime()					--Begin a task
	self.Time.Touch = CurTime()	 - 1			--On contact someone
	self.Time.VoiceMeleeFinalBlow = CurTime()	--Speak a final blow voice
	self.Time.VoiceOnFire = CurTime()			--Speak when on fire
	
	self.Time.ApproachingInterval = 0.5			--For "EnemyApproaching" condition
	self.Time.HealthCheckInterval = 2.5			--For "CanRecall" condition
	self.Time.RepeatedDamageDuration = 1.2		--If the nextbot has taken damage for this time, set "RepeatedDamage" condition.
	self.Time.ResetRepeatedDamage = 2.5			--Reset "RepeatedDamage" condition timer after several seconds.
end

function ENT:GetBoneHitBox(bonename)
	local hitbox, hitgroup = nil
	for group = 0, self:GetHitBoxGroupCount() - 1 do
		for box = 0, self:GetHitBoxCount(group) - 1 do
			if self:GetHitBoxBone(box, group) == self:LookupBone(bonename) then
				hitbox, hitgroup = box, group
			end
		end
		
		if hitbox then break end
	end
	
	return hitbox, hitgroup
end

--Defines some variables.
function ENT:InitializeVariables()
	self.Equipment = self:CreatePulsePistols() --Weapons info
	if not self.Equipment then return end
	self.EyeHeight = self:GetEye().Pos.z - self:GetPos().z
	self.DesiredSpeed = self.Speed.Run
	
	self.Act.Flinch.Back = self:GetSequenceActivity(
		self:LookupSequence("flinch_back_01"))
	self.Act.Flinch.Default = self:GetSequenceActivity(
		self:LookupSequence("flinch_01")) --flinch_01 or flinch_02
	self.Act.Flinch.ShoulderLeft = self:GetSequenceActivity(
		self:LookupSequence("flinch_shoulder_l"))
	self.Act.Flinch.ShoulderRight = self:GetSequenceActivity(
		self:LookupSequence("flinch_shoulder_r"))
	
	--We need hitbox bound to check headshots and flinch.
	self.HitBox, self.HitGroup = {}, {}
	self.HitBox.Head, self.HitGroup.Head = self:GetBoneHitBox(self.Bone.Head)
	self.HitBox.ShoulderLeft, self.HitGroup.ShoulderLeft = self:GetBoneHitBox(self.Bone.ShoulderLeft)
	self.HitBox.ShoulderRight, self.HitGroup.ShoulderRight = self:GetBoneHitBox(self.Bone.ShoulderRight)
	self.HitBox.Stomach, self.HitGroup.Stomach = self:GetBoneHitBox(self.Bone.Stomach)
	
	--Tracer's ability--------------
	self.BlinkRemaining = 3
	self.BlinkSoundLevel = 1
	
	self.RecallNextWrite = 1
	self.RecallInfo = {}
	self:InitializeRecallInfo()
	--------------------------------
	
	--Path finding------------------
	self.Path = {}
	self.Path.Chasing = Path("Follow") --I couldn't use "Chase" so I use "Follow" instead.
	self.Path.Chasing:SetMinLookAheadDistance(self.Dist.FollowPlayer)
	self.Path.Chasing:SetGoalTolerance(20)
	self.Path.Main = Path("Follow")
	self.Path.Main:SetMinLookAheadDistance(400)
	self.Path.Main:SetGoalTolerance(20)
	self.Path.DesiredPosition = self:GetPos() --Move to this position
	--------------------------------
	
	--Personal memories-------------
	self.Memory = {}
	self.Memory.Allies = {} --Broadcasting enemy info.
	self.Memory.ChaseTarget = nil --Following player who used Tracer.
	self.Memory.Crouch = false --Crouch flag.
	self.Memory.CrouchNav = false --Forced to crouch by navarea.
	self.Memory.DangerEntity = nil --An entity that I should run away from.
	self.Memory.Distance = 0 --Distance from myself to the enemy.
	self.Memory.Enemies = {} --Enemy pool.
	self.Memory.Enemy = nil --Target entity.
	self.Memory.EnemyAimVector = self:GetForward() --The enemy's looking at.
	self.Memory.EnemyPosition = self:GetEye().Pos --I know his last position I've seen.
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
	
	self.inpcIgnore = true
	return true
end

--Initializes this NPC.
local CheersLove_Time = CurTime()
local AllyTracerSpawn = CurTime()
function ENT:Initialize()
	if IsUselessModel(self.Model) then
		Msg("Can't spawn nextbot: Tracer playermodel is not found!")
		self:Remove()
		return
	end
	
	--So that we can see through breakable things.
	self.breakable_filter = ents.FindByClass("func_breakable")
	table.Add(self.breakable_filter, ents.FindByClass("func_breakable_surf"))
	table.insert(self.breakable_filter, self)
	
	--Shared functions
	self:SetModel(self.Model)
	self:SetHealth(self.HP.Init)
	self:AddFlags(bit.bor(FL_NPC, FL_OBJECT, FL_AIMTARGET, FL_FAKECLIENT))
	self:SetSolid(SOLID_BBOX)
	self:MakePhysicsObjectAShadow(true, true)
	
	--Server functions
	if not self:InitializeVariables() then
		Msg("Can't spawn pulse pistols!  Tracer has removed.")
		self:Remove()
		return
	end
	
	self:InitializeRelationship()
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
		self.TrailColor, true, 20, 0, 0.2, 0.1, "effects/blueblacklargebeam.vmt")
	self.Trail:DeleteOnRemove(self)
	
	--Cheers, love!  The cavalry's here!
	if self.Relationship[CLASS_PLAYER] == D_HT and CurTime() > CheersLove_Time then
		self:EmitSound("Nextbot_Tracer.OnSpawn")
		CheersLove_Time = CurTime() + math.Rand(15, 30)
	elseif self.Relationship[CLASS_PLAYER] ~= D_HT and CurTime() > AllyTracerSpawn then
		self:EmitSound("Nextbot_Tracer.OnSpawnAlly")
		AllyTracerSpawn = CurTime() + math.Rand(15, 30)
	end
end
----------------------------------------------}

--Main coroutine of behavior.
function ENT:RunBehaviour()
	while true do
		if not self:GetConVarBool("ai_disabled") then
			--Allies Tracer: Blue muzzle flash, Enemy Tracer: Red muzzle flash
			self.MuzzleFlashParticleName = "hunter_muzzle_flash" ..
				(self.Relationship[CLASS_PLAYER] == D_HT and "_red" or "")
			self.TrailColor = self.Relationship[CLASS_PLAYER] == D_HT and
				Color(255, 0, 0, 192) or Color(0, 128, 255, 192)
			self.Trail:SetKeyValue("rendercolor", tostring(self.TrailColor))
			
			--Get current schedule.
			local sched, progress = self:GetSchedule()
			if not istable(self.Schedule[sched]) then self:SetSchedule("Idle") end
			
			--Finding enemies and refresh enemy pool.
			if CurTime() > self.Time.FindEnemy then
				local nearestenemy = self:FindEnemy()
				if IsValid(nearestenemy) then self:SetEnemy(nearestenemy) end
				self.Time.FindEnemy = CurTime() + math.Rand(0.5, 1)
			end
			
			--For "EnemyApproaching" condition.
			if CurTime() > self.Time.ApproachingChecked then
				self.Time.ApproachingChecked = CurTime() + self.Time.ApproachingInterval
				self.State.Previous.ApproachingPos = self.Memory.EnemyPosition
			end
			
			--For "CanRecall" condition.
			if CurTime() > self.Time.HealthChecked then
				self.Time.HealthChecked = CurTime() + self.Time.HealthCheckInterval
				self.State.Previous.HealthForRecall = self:Health()
			end
			
			--Recoding my info for recall.
			if CurTime() > self.Time.RecordRecallInfo then
				self.RecallInfo[self.RecallNextWrite] = {
					health = self:Health(),
					pos = self:GetPos(),
					ang = self:GetAngles(),
					aim_yaw = self:GetPoseParameter("aim_yaw"),
					aim_pitch = self:GetPoseParameter("aim_pitch"),
				}
				
				self.RecallNextWrite = (self.RecallNextWrite % self.RecallInfoSize) + 1
				self.Time.RecordRecallInfo = CurTime() + self.RecallInterval
			end
			
			--Get a health kit.
			if self:Health() < self:GetMaxHealth() then
				for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(), 30)) do
					if self:Health() >= self:GetMaxHealth() then break end
					local c, h, s = v:GetClass(), 0, ""
					if c == "item_healthkit" then h = 250 s = "HealthKit.Touch"
					elseif c == "item_healthvial" then h = 75 s = "HealthVial.Touch" end
					if h > 0 then
						self:SetHealth(math.Clamp(self:Health() + h, 0, self:GetMaxHealth()))
						self:EmitSound(s)
						SafeRemoveEntity(v)
					end
				end
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
							self.State.FailReason = "NoReasonGiven"
							self.State.FailSchedule = nil
							self.State.InterruptCondition = nil
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
			
			for k, v in pairs(ents.FindInSphere(self:GetEye().Pos, 60)) do
				if string.find(v:GetClass(), "door") then
					v:Input("Open", self, self)
					v:Input("OpenAwayFrom", self, self, self:GetClass())
				end
			end
			
			self:UpdatePosition()
		end
		
		coroutine.yield()
	end
end
