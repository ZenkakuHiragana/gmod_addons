
function SWEP:FrameToSec(f) return f / 60 end
function SWEP:SecToFrame(s) return s * 60 end

local FunctionQueue = {}
local ScheduleFunc = {}
local ScheduleMeta = {__index = ScheduleFunc}
function ScheduleFunc:SetDelay(newdelay)
	self.prevtime = CurTime()
	if isstring(self.time) then
		self.weapon["Set" .. self.delay](self.weapon, newdelay)
		self.weapon["Set" .. self.time](self.weapon, CurTime() + newdelay)
	else
		self.delay = newdelay
		self.time = CurTime() + newdelay
	end
end

function ScheduleFunc:SinceLastCalled()
	return CurTime() - self.prevtime
end

function SWEP:AddNetworkSchedule(delay, func)
	local schedule = setmetatable({
		done = 0,
		func = func,
		prevtime = CurTime(),
		weapon = self,
	}, ScheduleMeta)
	schedule.time = "Timer" .. tostring(self:GetLastSlot "Float")
	self:AddNetworkVar("Float", schedule.time)
	self["Set" .. schedule.time](self, CurTime())
	schedule.delay = "TimerDelay" .. tostring(self:GetLastSlot "Float")
	self:AddNetworkVar("Float", schedule.delay)
	self["Set" .. schedule.delay](self, delay)
	table.insert(FunctionQueue, schedule)
	return schedule
end

function SWEP:AddSchedule(delay, numcall, func)
	local schedule = setmetatable({
		delay = delay,
		done = 0,
		func = func or numcall,
		numcall = func and numcall or 0,
		time = CurTime() + delay,
		prevtime = CurTime(),
		weapon = self,
	}, ScheduleMeta)
	table.insert(FunctionQueue, schedule)
	return schedule
end

function SWEP:ProcessSchedules()
	for i, s in pairs(FunctionQueue) do
		if isstring(s.time) then
			if CurTime() > self["Get" .. s.time](self) then
				s.func(self, s)
				s.prevtime = CurTime()
				self["Set" .. s.time](self, CurTime() + self["Get" .. s.delay](self))
			end
		elseif CurTime() > s.time then
			local remove = s.func(self, s)
			s.prevtime = CurTime()
			s.time = CurTime() + s.delay
			if s.numcall > 0 then
				s.done = s.done + 1
				remove = remove or s.done >= s.numcall
			end
			
			if remove then FunctionQueue[i] = nil end
		end
	end
end
