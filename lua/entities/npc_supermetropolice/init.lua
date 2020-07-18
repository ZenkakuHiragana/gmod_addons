
AddCSLuaFile "cl_init.lua"
include "debug.lua"
include "shared.lua"
include "animation.lua"
include "conditions.lua"
include "movement.lua"
include "relationship.lua"
include "task.lua"
include "schedule.lua"
include "target.lua"
include "trace.lua"
include "weapon.lua"

ENT.HasLongRange = true
ENT.IsSuperMetropolice = true
ENT.MaxHealth = 40

local BULLET_NEAR_DISTANCE_SQR = 50^2
hook.Add("EntityFireBullets", "GreatZenkakuMan's Nextbot EntityFireBullets", function(ent, bullet)
	local dir = bullet.Dir:GetNormalized()
	local org = bullet.Src
	local length = bullet.Distance
	for i, self in ipairs(ents.FindByClass "npc_supermetropolice") do
		if self:HasValidEnemy(ent) then
			local org2 = self:WorldSpaceCenter()
			local dir2 = org2 - org
			if dir2:GetNormalized():Dot(dir) > 0.7 then
				local length2 = dir:Dot(dir2)
				local endpos = org + dir * math.min(length, length2)
				local radiussqr = org2:DistToSqr(endpos)
				if radiussqr < BULLET_NEAR_DISTANCE_SQR then
					self:SetCondition(self.Enum.Conditions.COND_BULLET_NEAR)
					self.Time.LastHearBullet = CurTime()
				end
			end
		end
	end
end)

function ENT:RunHook(prefix, ...)
	for name, func in pairs(self:GetTable()) do
		if name ~= prefix and name:StartWith(prefix) then
			func(self, ...)
		end
	end
end

function ENT:Initialize()
    self:SetModel "models/player/police.mdl"
	self:SetMaxHealth(self.MaxHealth)
	self:SetHealth(self:GetMaxHealth())
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:SetSolid(SOLID_BBOX)
	self:MakePhysicsObjectAShadow(true, true)
	self:SetCollisionBounds(self:GetMins(true), self:GetMaxs(true))
	self:DrawShadow(true)
	self.Time = {}
	self:RunHook "Initialize"
end

function ENT:OnInjured(d)
	self:RunHook("OnInjured", d)
	self.BaseClass.OnInjured(self, d)
end

function ENT:OnKilled(d)
	self:RunHook("OnKilled", d)
	self.BaseClass.OnKilled(self, d)
end

function ENT:OnOtherKilled(victim, d)
	self.BaseClass.OnOtherKilled(self, victim, d)
	if self:HasValidEnemy() then return end
	if self:Disposition(victim) ~= D_LI then return end
	self:SetEnemy(d:GetAttacker())
end

function ENT:OnLandOnGround(ent)
	self:RunHook("OnLandOnGround", ent)
end

function ENT:OnContact(ent)
	if not IsValid(ent) then return end
	local p = ent:GetPhysicsObject()
	if not IsValid(p) then return end
	p:ApplyForceOffset(self:GetForward() * 600, self:WorldSpaceCenter())
end

local function ShouldStopSchedule(self)
	return self:TaskFailed()
	or self.Schedule.ChangeSchedule
	or self.Schedule.CeaseSchedule
	or self:HasInterrupt()
end

local Benchmark = false
function ENT:RunTaskBatch(task)
	if Benchmark then
		util.TimerCycle()
		self:UpdateConditions()
		local max, str = util.TimerCycle(), "UpdateConditions"
		self:CheckCrouching()
		self:DoTask(task)
		local t = util.TimerCycle()
		if max < t then max, str = t, self.Schedule.CurrentTask end
		self:DoApproach()
		self:DoFaceTowards()
		self:UpdatePath()
		local t = util.TimerCycle()
		if max < t then max, str = t, "UpdatePath" end
		if max > 1 then self:print("Benchmark", max, str) end
		self:FixPath()
	else
		self:UpdateConditions()
		self:CheckCrouching()
		self:DoTask(task)
		self:DoApproach()
		self:DoFaceTowards()
		self:UpdatePath()
		self:FixPath()
		self:FireWeapon()
	end
end

function ENT:RunScheduleLoop()
	for _, task in ipairs(self.ScheduleList[self.Schedule.CurrentSchedule]) do
		self.Schedule.CurrentTask = isstring(task) and task or istable(task) and task[1] or ""
		self:print("TaskStart", self.Schedule.CurrentTask)
		self:OnTaskInitialize()
		while not self:TaskFinished() do
			if self.PlaySequence then
				self:PlaySequenceAndWait(self.PlaySequence)
				self:StartActivity(ACT_INVALID)
				self.PlaySequence = nil
			end

			self:FindEnemy()
			if self:HasValidEnemy() and self:Visible(self:GetEnemy()) then
				self:SetLastPosition(self:GetEnemy():GetPos())
				self.Time.LastEnemySeen = CurTime()
			end

			self:RunTaskBatch(task)
			self.PreviousPosition = self:GetPos()
			if ShouldStopSchedule(self) then return end

			coroutine.yield()
		end
	end
end

function ENT:Think() -- Change Pathfinder's face
	local c = self.Enum.Conditions
	local b = self:FindBodygroupByName "Screen"
	if b < 0 then return end
	if self:HasCondition(c.COND_CAN_RANGE_ATTACK1) then
		self:SetBodygroup(b, 1)
	else
		self:SetBodygroup(b, 0)
	end
end

function ENT:MainLoop()
	self:SelectNPCState()
	self.Schedule.CurrentSchedule = self:SelectSchedule(self.Schedule.NPCState)
	if self.Schedule.CurrentSchedule and self.ScheduleList[self.Schedule.CurrentSchedule] then
		self:OnScheduleInitialize()
		self:print("ScheduleStart", self.Schedule.CurrentSchedule)
		self:RunScheduleLoop()

		if self.Schedule.TaskFinalize then
			self.Schedule.CurrentTask = self.Schedule.TaskFinalize
			self:DoTask()
		end
	end
end

function ENT:DisabledMainLoop()
	if Entity(1):KeyDown(IN_ATTACK2) then
		self:ComputePath(Entity(1):GetEyeTrace().HitPos)
	end
	
	self:UpdateConditions()
	self:CheckCrouching()
	self:DoApproach()
	self:DoFaceTowards()
	self:UpdatePath()
	self:FixPath()
end

function ENT:RunBehaviour()
	local disabledAI = GetConVar "ai_disabled"
	while true do
		if not disabledAI:GetBool() then
			self:MainLoop()
		else
			self:DisabledMainLoop()
		end
		
		coroutine.yield()
    end
end

function ENT:BehaveUpdate(fInterval)
	if not self.BehaveThread then return end

	-- Give a silent warning to developers if RunBehaviour has returned
	if coroutine.status(self.BehaveThread) == "dead" then
		self.BehaveThread = nil
		print(self, "Warning: ENT:RunBehaviour() has finished executing")
		return
	end

	self:print("fInterval", fInterval)
	-- Continue RunBehaviour's execution
	local ok, message = coroutine.resume(self.BehaveThread)
	if ok then return end
	self.BehaveThread = nil
	ErrorNoHalt(self, " Error: ", message, "\n")
end
