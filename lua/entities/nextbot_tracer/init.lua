
AddCSLuaFile("shared.lua")
include("shared.lua")
include("weapon.lua")
include("movement.lua")
include("schedules.lua")

--++Hooks++-----------------------------------{
local classname = "nextbot_tracer"
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
--Argument: Entity v | The entity the nextbot came in contact with.
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
	
	self.Memory.Enemies[info:GetAttacker()] =
		{Pos = info:GetAttacker():GetPos(),
		 Distance = info:GetAttacker():GetPos():DistToSqr(self:GetPos()),
		 Forward = info:GetAttacker():GetForward()}
end

function ENT:OnRemove()	
	if IsValid(self.Equipment.Entity) then self.Equipment.Entity:Remove() end
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
----------------------------------------------}

--++Initializes++-----------------------------{
function ENT:InitializeTimers()
	self.Time = {}
	self.Time.SeeEnemy = CurTime()			--Can see the enemy
	self.Time.Fire = CurTime()				--Fire primary weapon
	self.Time.Move = CurTime()				--Start moving to somewhere
	self.Time.Reload = CurTime()			--Reloading
	self.Time.Damage = CurTime()			--Last time damage taken
	self.Time.DamageRepeatedly = CurTime()	--Flag as repeatedly damage
	self.Time.Schedule = CurTime()			--Begin a schedule
	self.Time.Task = CurTime()				--Begin a task
end

function ENT:InitializeVariables()
	self.Equipment = self:CreatePulsePistols() --Weapons info
	
	self.Path = {}
	self.Path.Main = Path("Follow")
	self.Path.DesiredPosition = self:GetPos() --Move to this position
	
	self:InitializeTimers()
	
	--Personal memories-------------
	self.Memory = {}
	self.Memory.Enemy = nil --Target entity.
	self.Memory.DangerEntity = nil --An entity that I should run away from.
	self.Memory.Distance = 0 --Distance from myself to the enemy.
	self.Memory.EnemyPosition = self:GetEye().Pos --I know his last position I've seen.
	self.Memory.Enemies = {} --Enemy pool
	self.Memory.Look = false --Look at the enemy
	--------------------------------
	
	--Conditions--------------------
	self:InitializeState()
	--------------------------------
end

function ENT:Initialize()
	self.breakable_filter = ents.FindByClass("func_breakable")
	table.Add(self.breakable_filter, ents.FindByClass("func_breakable_surf"))
	
	--Shared functions
	self:SetModel(self.Model)
	self:SetHealth(self.HP.Init)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:AddFlags(FL_AIMTARGET)
	self:SetSolid(SOLID_BBOX)
	self:MakePhysicsObjectAShadow(true, true)
	
	--Server functions
	self.Condition = {}
	self:SetUseType(SIMPLE_USE)
	self:SetMaxHealth(self.HP.Init)
	self:StartActivity(self.Act.Run)
	self.loco:SetDesiredSpeed(self.Speed.Run)
	self.loco:SetAcceleration(self.Speed.Acceleration)
	self.loco:SetDeceleration(self.Speed.Deceleration)
	self:InitializeVariables()
end
----------------------------------------------}


function ENT:RunBehaviour()
	while true do
		if not self:GetConVarBool("ai_disabled") then
			--Perform sensing.
			local nearestenemy, e = self:FindEnemy(), self:GetEnemy()
			if IsValid(nearestenemy) then
				self:SetEnemy(nearestenemy)
			end
			--Update enemy info
			self.Memory.Look = self:CanSee() --I have LOS of the enemy.
			self.Memory.Shoot = self:CanSee(self.Memory.EnemyPosition, --I can shoot the enemy.
				{start = self:GetMuzzle().Pos, shoot = true})
			
			if self.Memory.Look then
				--Update the position of current enemy
				self.Memory.EnemyPosition = self:GetTargetPos() --set the last position I saw
				self.Memory.Distance = self:GetRangeTo(self.Memory.EnemyPosition) --set the last distance I know
				self:SetLook(self.Memory.Shoot)
				self.Time.Saw = CurTime()
			end
			
			--Build conditions.
			self:RemoveAllConditions()
			self.Condition.Build(self, self.Memory.Enemy)
			
			--Choose a state.
			self.State.Build(self)
			
			--Select a new schedule
			local sched, progress = self:GetSchedule()
			if not istable(self.Schedule[sched]) or self:HasCondition("Done") then
				self:SetSchedule(self.Schedule.Build[self:GetState()](self))
			end
			
			if self.Memory.Shoot then
				self:FireWeapon()
			end
			
			--Do current schedule.
			if istable(self.Schedule[sched]) then --Current schedule is available, run task.
				for i = 1, 3 do
					sched, progress = self:GetSchedule()
					self.State.Task = self.Schedule[sched][progress]
					if istable(self.State.Task) then
						self.State.TaskParam = self.State.Task[2]
						self.State.Task = self.State.Task[1]
					else
						self.State.TaskParam = nil
					end
					
					local task, param, taskreturn, completed = self.State.Task, self.State.TaskParam, nil, nil
					if isfunction(self.Task[task]) then
						taskreturn = self.Task[task](self, param)
						completed = self.Task.IsCompleted(self)
						if completed then --Current task is completed, go to next task.
							if completed == "invalid" then
								self.State.Previous.FailSchedule = sched
								self.State.ScheduleProgress = #self.Schedule[sched] + 1
							else
								self.State.Previous.FailSchedule = nil
								self.State.ScheduleProgress = progress + 1
							end
							self.Time.Task = CurTime()
						end
						if not (completed and taskreturn) then break end
					end
				end
				
				for i, interrupt in ipairs(self.Schedule[sched].Interrupts) do
					if self:HasCondition(interrupt) then
						self.State.ScheduleProgress = #self.Schedule[sched] + 1
					end
				end
			end
			
			self.State.Previous.HaveEnemy = self.Memory.Enemy --For "EnemyDead" condition.
			self.State.Previous.Health = self:Health() --For "Light/HeavyDamage" condition.
			--For "PathFinished" condition.
			self.State.Previous.Path = self.Path.Main:IsValid() or self.Path.Approaching
			
			self:SetLocoAnimation()
			self:MoveBehaviour()
			if self.Memory.FaceEnemy then
				self.loco:FaceTowards(self.Memory.EnemyPosition)
				self.loco:FaceTowards(self.Memory.EnemyPosition)
				self:Aim(self.Memory.EnemyPosition)
			end
		end
		coroutine.yield()
	end
end

function ENT:RunBehaviour()
	while true do
		if not self:GetConVarBool("ai_disabled") then
			if not self.Path.Main:IsValid() then
				if CurTime() > self.Time.Move then
					self:GotoRandomPosition()
					self:StartMove()
				end
			elseif not self:UpdatePosition() then
				self.Time.Move = CurTime() + 3
			end
			
			self:PerformAnimation()
		end
		
		coroutine.yield()
	end
end
function ENT:PerformAnimation()
	--Pose parameter for locomotion
	local multiply = self:GetVelocity():LengthSqr() / self.Speed.RunSqr
	local move_vector = self:WorldToLocal(self:GetPos() + self:GetVelocity():GetNormalized())
	self:SetPoseParameter("move_x", move_vector.x * multiply)
	self:SetPoseParameter("move_y", move_vector.y * multiply)
	self:SetPoseParameter("vertical_velocity", move_vector.z * multiply)
	
	--Pose parameter for aiming
	
	--Set activity
	local velocity = self:GetVelocity():LengthSqr()
	local act = self.Act.Idle
	if velocity > self.Speed.WalkSqr then
		act = self.Act.Run
	elseif velocity > 0 then
		act = self.Act.Walk
	end
	self:SetActivity(act)
end

function ENT:SetActivity(a)
	if self:GetActivity() ~= a then self:StartActivity(a) end
end

function ENT:GetHand(isleft)
	local att = isleft and "anim_attachment_LH" or "anim_attachment_RH"
	return self:GetAttachment(self:LookupAttachment(att))
end
