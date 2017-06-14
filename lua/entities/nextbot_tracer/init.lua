
AddCSLuaFile("shared.lua")
include("shared.lua")
include("weapon.lua")
include("targeting.lua")
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
end

function ENT:OnRemove()	
	if IsValid(self.Equipment.Entity) then self.Equipment.Entity:Remove() end
	timer.Remove("BlinkRecover" .. self:EntIndex())
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
	self.Time.Melee = CurTime()				--Melee attack cooldown
	self.Time.Reload = CurTime()			--Reloading
	self.Time.Damage = CurTime()			--Last time damage taken
	self.Time.DamageRepeatedly = CurTime()	--Flag as repeatedly damage
	self.Time.Schedule = CurTime()			--Begin a schedule
	self.Time.Task = CurTime()				--Begin a task
	self.Time.Blink = CurTime()				--Blink cooldown
end

function ENT:InitializeVariables()
	self.Equipment = self:CreatePulsePistols() --Weapons info
	self.EyeHeight = self:GetEye().Pos.z - self:GetPos().z
	
	self.BlinkRemaining = 3
	timer.Create("BlinkRecover" .. self:EntIndex(), 5, 0, function()
		if not IsValid(self) or self.BlinkRemaining > 2 then return end
		self.BlinkRemaining = self.BlinkRemaining + 1
	end)
	
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
	self.Memory.EnemyAimVector = self:GetForward() --The enemy's looking at.
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
end
----------------------------------------------}

function ENT:RunBehaviour()
	while true do
		if not self:GetConVarBool("ai_disabled") then
			local sched, progress = self:GetSchedule()
			if not istable(self.Schedule[sched]) then self:SetSchedule("Idle") end
			
			for i, interrupt in ipairs(self.Schedule[sched].Interrupts) do
				if self:HasCondition(interrupt) then
					self.State.ScheduleProgress = math.huge
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
				self:SetSchedule(self.Schedule.Build[self:GetState()](self))
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
			
			self:PerformAnimation()
			
			if self.Memory.Look then
				self.loco:SetMaxYawRate(self.MaxYawRate * 5)
				self.loco:FaceTowards(self.Memory.EnemyPosition)
				self.loco:SetMaxYawRate(self.MaxYawRate)
			end
		end
		
		coroutine.yield()
	end
end

function ENT:PerformAnimation()
	--Pose parameter for locomotion
	local multiply = self:GetVelocity():LengthSqr() / self.Speed.RunSqr
	local move_vector = self:WorldToLocal(self:GetPos() + self:GetVelocity():GetNormalized())
	self:SetPoseParameter("move_x", move_vector.x * multiply)
	self:SetPoseParameter("move_y", -move_vector.y * multiply)
	self:SetPoseParameter("vertical_velocity", move_vector.z * multiply)
	
	--Pose parameter for 
	if self.Memory.FaceEnemy then
		self:Aim(self.Memory.EnemyPosition)
	end
	
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
	--Then converts it to a vector on the entity and makes it an angle ("local angle")
	local yawAng = self:WorldToLocal(pos):Angle()
	
	--Same thing as above but this gets the pitch angle.
	--Since the turret's pitch axis and the turret's yaw axis are seperate I need to do this seperately.
	local pAng = pos - self:LocalToWorld((yawAng:Forward() * 8) + Vector(0, 0, 50))
	local pAng = self:WorldToLocal(self:GetPos() + pAng):Angle()

	--y = Yaw. This is a number between 0-360.
	--p = Pitch. This is a number between 0-360.
	local y, p = yawAng.y, pAng.p
	local min, max = self:GetPoseParameterRange("")
	--min, max = Minimum value and maximum value of pose parameter, "aim_yaw", "aim_pitch".
	
	--Numbers from 0 to 360 don't work with the pose parameters, so I need to make it a number from -180 to 180
	math.Remap(y, 0, 360, -180, 180)
	math.Remap(p, 0, 360, -180, 180)
	if y >= 180 then y = y - 360 end
	if p >= 180 then p = p - 360 end
	if math.abs(y) > 60 then return false end
	if 56.203525543213 < p or p < -86.324005126953 then return false end
	--Returns yaw and pitch as numbers between -180 and 180
	
	if not y then return false end
	self:SetPoseParameter("aim_yaw", y)
	self:SetPoseParameter("aim_pitch", p)
end