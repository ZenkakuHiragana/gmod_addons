
AddCSLuaFile("shared.lua")
include("shared.lua")
include("weapon.lua")
include("targeting.lua")
include("movement.lua")
include("schedules.lua")

local classname = "nextbot_tracer"

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

--++Hooks++-----------------------------------{
hook.Add("OnEntityCreated", "NextbotIsAlone!", function(e)
	if IsValid(e) and e:GetClass() ~= classname and isfunction(e.AddEntityRelationship) then
		timer.Simple(2, function()
			if not IsValid(e) then return end
			for k, v in pairs(ents.FindByClass(classname)) do
				if IsValid(v) then e:AddEntityRelationship(v, D_HT, 1) end
			end
		end)
	end
end)

--Called when the nextbot touches another entity.
--Applies the physics damage.
--Argument:
----Entity v | The entity the nextbot came in contact with.
function ENT:OnContact(v)
	if not IsValid(v) then return end
	if v:IsPlayer() or v:IsNPC() or v.Type == "nextbot" then return end
	local p = v:GetPhysicsObject() if not IsValid(p) then return end
	local f = -p:GetVelocity()
	
	p:SetVelocityInstantaneous(vector_origin)
	p:ApplyForceCenter(f)
	
	local e, division = p:GetEnergy(), 2.0 * 10e+6 if e < division then return end
	if v:IsVehicle() then e = v:GetSpeed() * division end
	local d, attacker = DamageInfo(), v:GetPhysicsAttacker()
	if not IsValid(attacker) then attacker = v end
	d:SetAttacker(attacker)
	d:SetDamage(e / division)
	d:SetDamageForce(p:GetVelocity() / 2)
	d:SetDamagePosition(self:WorldSpaceCenter())
	d:SetDamageType(DMG_CRUSH)
	d:SetInflictor(v)
	d:SetMaxDamage(d:GetDamage())
	d:SetReportedPosition(p:GetMassCenter())
	
	self:TakeDamageInfo(d)
end

function ENT:OnInjured(info)
	--Damage doubles when take a headshot.
	local tr = util.QuickTrace(info:GetDamagePosition(), info:GetDamageForce())
	if tr.Entity == self and tr.HitGroup == HITGROUP_HEAD then info:ScaleDamage(2) end
	if CurTime() > self.Time.Damage + 3 then
		self.Time.DamageRepeated = CurTime()
	end
	self.Time.Damage = CurTime()
	if info:IsDamageType(DMG_BURN) or self:Validate(info:GetAttacker()) ~= 0 then return end
	
	self.Memory.Enemies[info:GetAttacker()] = {
		Pos = info:GetAttacker():GetPos(),
		Distance = info:GetAttacker():GetPos():DistToSqr(self:GetPos()),
		Forward = info:GetAttacker():GetForward()
	}
	
	local newenemy = self:FindEnemy()
	if newenemy then self:SetEnemy(newenemy) end
end

function ENT:OnRemove()	
	if IsValid(self.Equipment.Entity) then self.Equipment.Entity:Remove() end
	if IsValid(self.Trail) then self.Trail:Remove() end
end

function ENT:OnKilled(info)
	hook.Call("OnNPCKilled", GAMEMODE, self, info:GetAttacker(), info:GetInflictor())
	if IsValid() then
		local w = ents.Create(self.Weapon:GetClass())
		w:SetPos(self.Weapon:GetPos())
		w:SetAngles(self.Weapon:GetAngles())
		w:SetVelocity(self.Weapon:GetAbsVelocity())
		w:Spawn()
		self.Weapon:Remove()
	end
	self:BecomeRagdoll(info)
	self:OnRemove()
end

function ENT:OnNavAreaChanged(old, new)
	if new and new:IsValid() then
		self.Memory.CrouchNav = new:HasAttributes(NAV_MESH_CROUCH)
		self.Memory.WalkNav = new:HasAttributes(NAV_MESH_WALK)
		self.Memory.Jump = new:HasAttributes(NAV_MESH_JUMP)
	end
end
----------------------------------------------}

--++Initializes++-----------------------------{
function ENT:InitializeTimers()
	self.Time = {}
	self.Time.Blink = CurTime()				--Blink cooldown
	self.Time.Damage = CurTime()			--Last time damage taken
	self.Time.DamageRepeatedly = CurTime()	--Flag as repeatedly damage
	self.Time.Fire = CurTime()				--Fire primary weapon
	self.Time.Melee = CurTime()				--Melee attack cooldown
	self.Time.Move = CurTime()				--Start moving to somewhere
	self.Time.Reload = CurTime()			--Reloading
	self.Time.Schedule = CurTime()			--Begin a schedule
	self.Time.SeeEnemy = CurTime()			--Can see the enemy
	self.Time.Task = CurTime()				--Begin a task
end

function ENT:InitializeVariables()
	self.Equipment = self:CreatePulsePistols() --Weapons info
	self.EyeHeight = self:GetEye().Pos.z - self:GetPos().z
	self.BlinkRemaining = 3
	
	self.Path = {}
	self.Path.Main = Path("Follow")
	self.Path.DesiredPosition = self:GetPos() --Move to this position
	
	self:InitializeTimers()
	
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
	
	--Conditions--------------------
	self:InitializeState()
	--------------------------------
end

function ENT:Initialize()
	self.breakable_filter = ents.FindByClass("func_breakable")
	table.Add(self.breakable_filter, ents.FindByClass("func_breakable_surf"))
	table.insert(self.breakable_filter, self)
	
	--Shared functions
	self:SetModel(self.Model)
	self:SetHealth(self.HP.Init)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:AddFlags(FL_AIMTARGET)
	self:SetSolid(SOLID_BBOX)
	self:MakePhysicsObjectAShadow(true, true)
	
	--Server functions
	self:SetUseType(SIMPLE_USE)
	self:SetMaxHealth(self.HP.Init)
	self:StartActivity(self.Act.Run)
	self.loco:SetMaxYawRate(self.MaxYawRate)
	self.loco:SetDesiredSpeed(self.Speed.Run)
	self.loco:SetAcceleration(self.Speed.Acceleration)
	self.loco:SetDeceleration(self.Speed.Deceleration)
	self:InitializeVariables()
	
	self.Trail = util.SpriteTrail(self, self:LookupAttachment("chest"), 
		Color(0, 128, 255, 192), true, 20, 0, 0.1, 1/10, "effects/blueblacklargebeam.vmt")
	self.Trail:DeleteOnRemove(self)
end
----------------------------------------------}

function ENT:RunBehaviour()
	while true do
		if not self:GetConVarBool("ai_disabled") then
			local sched, progress = self:GetSchedule()
			if not istable(self.Schedule[sched]) then self:SetSchedule("Idle") end
			
			for i, interrupt in ipairs(self.Schedule[sched].Interrupts) do
				if isstring(interrupt) and self:HasCondition(interrupt) then
					self.State.ScheduleProgress = math.huge
				elseif istable(interrupt) and self:HasCondition(interrupt[1]) then
					self.State.ScheduleProgress = math.huge
					self.State.FailNextSchedule = interrupt[2]
				end
			end
			
			--Choose a state.
			self.State.Build(self)
			
			--Perform sensing.
			local nearestenemy, e = self:FindEnemy(), self:GetEnemy()
			if IsValid(nearestenemy) then self:SetEnemy(nearestenemy) end
			
			--Build conditions.
			self:BuildConditions(self:GetEnemy())
			
			--Update enemy info			
			if self:GetEnemy() and self.Memory.Look then
				--Update the position of current enemy
				self.Memory.EnemyAimVector = self:GetEnemyAimVector()
				self.Memory.EnemyPosition = self:GetEnemy():WorldSpaceCenter() --set the last position I saw
				self.Memory.Distance = self:GetRangeTo(self.Memory.EnemyPosition) --set the last distance I know
				self.Time.SeeEnemy = CurTime()
			end
			
			--Select a new schedule
			if self:HasCondition("Done") then
				if self.State.FailNextSchedule then
					self:SetSchedule(self.State.FailNextSchedule)
					self.State.FailNextSchedule = nil
				else
					self:SetSchedule(self.Schedule.Build[self:GetState()](self))
				end
			end
			
			--Do current schedule.
			for i = 1, 10 do --This should be: while true do
				--Pick up current task.
				sched, progress = self:GetSchedule()
				self.State.Task = self.Schedule[sched][progress]
				if istable(self.State.Task) then
					self.State.TaskParam = self.State.Task[2]
					self.State.Task = self.State.Task[1]
				else
					self.State.TaskParam = nil
				end
				
				if isfunction(self.Task[self.State.Task]) then
					local taskreturn = self.Task[self.State.Task](self, self.State.TaskParam)
					local completed = self.Task.IsCompleted(self)
					if completed then --Current task is completed, go to next task.
						if completed == "invalid" then --Task is failed
							self.State.Previous.FailSchedule = sched
							self.State.FailNextSchedule = self.Schedule[sched].FailSchedule
							self.State.ScheduleProgress = math.huge --Abort the schedule
							break
						else --Task acomplished
							self.State.Previous.FailSchedule = nil
							self.State.ScheduleProgress = self.State.ScheduleProgress + 1
						end
						self.Time.Task = CurTime()
					end
					--taskreturn == true and task is completed, go to next task.
					if not completed or not taskreturn then break end
				end
			end
			
			self.State.Previous.HaveEnemy = self:GetEnemy() --For "EnemyDead"
			self.State.Previous.Health = self:Health() --For "LightDamage", "HeavyDamage"
			self.State.Previous.Path = self.Path.Main:IsValid() or self.Path.Approaching --For "PathFinished"
			
			if self.Path.Main:IsValid() then self:UpdatePosition() end
			
			local y, p = self:PerformAnimation()
			if self.Memory.Look then
				self.loco:FaceTowards(self.Memory.EnemyPosition)
			end
		end
		
		coroutine.yield()
	end
end

function ENT:PerformAnimation()
	local speed = self.Speed.RunSqr
	
	--Set activity
	local velocity = self:GetVelocity():LengthSqr()
	local act = self.Act.Idle
	if self.Memory.CrouchNav or self.Memory.Crouch then
		self.loco:SetDesiredSpeed(self.Speed.Crouched)
		speed = self.Speed.CrouchedSqr
		if velocity > 0 then
			act = self.Act.WalkCrouch
		else
			act = self.Act.IdleCrouch
		end
	else
		self.loco:SetDesiredSpeed(self.Speed.Run)
		if not (self.Memory.WalkNav or self.Memory.Walk) and velocity > self.Speed.WalkSqr then
			act = self.Act.Run
		elseif velocity > 0 then
			act = self.Act.Walk
		end
	end
	
	self:SetActivity(act)
	
	--Pose parameter for locomotion
	local multiply = self:GetVelocity():LengthSqr() / speed
	local move_vector = self:WorldToLocal(self:GetPos() + self:GetVelocity():GetNormalized())
	self:SetPoseParameter("move_x", move_vector.x * multiply)
	self:SetPoseParameter("move_y", -move_vector.y * multiply)
	self:SetPoseParameter("vertical_velocity", move_vector.z * multiply)
	
	--Pose parameter for 
	local lookat = self:GetPos() + self:GetForward() + vector_up * self.EyeHeight
	if self.Memory.Look then
		lookat = self.Memory.EnemyPosition
		
		--Deal with eye angles.
		self:SetEyeTarget(lookat)
	else
		self:SetEyeTarget(self:GetEye().Pos + self:GetEye().Ang:Forward() * 100)
	end
	return self:Aim(lookat)
end

--Sets the given activity number, but does not restart the animation.
--Argument:
----number a | the activity number.
function ENT:SetActivity(a)
	if self:GetActivity() ~= a then self:StartActivity(a) end
end

--Returns a table about the hand.
--Argument:
----bool isleft | True if it is left hand.
function ENT:GetHand(isleft)
	local att = isleft and "anim_attachment_LH" or "anim_attachment_RH"
	return self:GetAttachment(self:LookupAttachment(att))
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
	self:SetPoseParameter("aim_yaw", read_yaw + dy / 10)
	self:SetPoseParameter("aim_pitch", read_pitch + dp / 10)
	return y, p
end