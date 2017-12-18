
--Shared library
if not SplatoonSWEPs then return end

--number miminum boundary size, table of Vectors
--returning AABB(mins, maxs)
function SplatoonSWEPs:GetBoundingBox(minbound, vectors)
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	for _, v in ipairs(vectors) do
		mins.x = math.min(mins.x, v.x - minbound)
		mins.y = math.min(mins.y, v.y - minbound)
		mins.z = math.min(mins.z, v.z - minbound)
		maxs.x = math.max(maxs.x, v.x + minbound)
		maxs.y = math.max(maxs.y, v.y + minbound)
		maxs.z = math.max(maxs.z, v.z + minbound)
	end
	return mins, maxs
end

--Vector AABB1(mins, maxs), Vector AABB2(mins, maxs) in world coordinates
--returning boolean, whether or not two AABBs intersect together
function SplatoonSWEPs:CollisionAABB(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y and
			mins1.z < maxs2.z and maxs1.z > mins2.z
end

--Vector AABB1(mins, maxs), Vector AABB2(mins, maxs) in world coordinates
--returning boolean, whether or not two AABBs intersect together
function SplatoonSWEPs:CollisionAABB2D(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y
end

--Vector(x, y, z), Vector new system origin, Angle new system angle
--returning localized Vector(x, y, 0)
function SplatoonSWEPs:To2D(source, orgpos, organg)
	local localpos = WorldToLocal(source, angle_zero, orgpos, organg)
	return Vector(localpos.y, localpos.z, 0)
end

--Vector(x, y, 0), Vector system origin in world coordinates, Angle system angle
--returning Vector(x, y, z)
function SplatoonSWEPs:To3D(source, orgpos, organg)
	local localpos = Vector(0, source.x, source.y)
	return (LocalToWorld(localpos, angle_zero, orgpos, organg))
end

function SplatoonSWEPs:AddTimerFramework(dest)
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

	function dest:AddNetworkSchedule(delay, func)
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
		table.insert(self.FunctionQueue, schedule)
		return schedule
	end

	function dest:AddSchedule(delay, numcall, func)
		local schedule = setmetatable({
			delay = delay,
			done = 0,
			func = func or numcall,
			numcall = func and numcall or 0,
			time = CurTime() + delay,
			prevtime = CurTime(),
			weapon = self,
		}, ScheduleMeta)
		table.insert(self.FunctionQueue, schedule)
		return schedule
	end

	function dest:ProcessSchedules()
		for i, s in pairs(self.FunctionQueue) do
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
				
				if remove then self.FunctionQueue[i] = nil end
			end
		end
	end
end

function SplatoonSWEPs:FrameToSec(f) return f / 60 end
function SplatoonSWEPs:SecToFrame(s) return s * 60 end
function SplatoonSWEPs.SetPrimary(self, info)
	local p = istable(self.Primary) and self.Primary or {}
	p.ClipSize = 100 --Clip size only for displaying.
	p.DefaultClip = 100
	p.Automatic = true
	p.Ammo = "Ink"
	p.Delay = SplatoonSWEPs:FrameToSec(info.Delay.Fire or 6)
	p.Recoil = info.Recoil or 0.2
	p.ReloadDelay = SplatoonSWEPs:FrameToSec(info.Delay.Reload or 30)
	p.TakeAmmo = (info.TakeAmmo or 1) / 100 * SplatoonSWEPs.MaxInkAmount
	p.PlayAnimPercent = (info.PlayAnimPercent or 0) / 100
	p.CrouchDelay = SplatoonSWEPs:FrameToSec(info.Delay.Crouch or 10)
	self.Primary = p
	if isfunction(self.CustomPrimary) then return self:CustomPrimary(p, info) end
end

function SplatoonSWEPs.SetSecondary(self, info)
	local s = istable(self.Secondary) and self.Secondary or {}
	s.ClipSize = -1
	s.DefaultClip = -1
	s.Automatic = false
	s.Ammo = "Ink"
	s.Delay = SplatoonSWEPs:FrameToSec(info.Delay.Fire or 6)
	s.Recoil = info.Recoil or 0.2
	s.ReloadDelay = SplatoonSWEPs:FrameToSec(info.Delay.Reload or 30)
	s.TakeAmmo = (info.TakeAmmo or 70) / 100 * SplatoonSWEPs.MaxInkAmount
	s.PlayAnimPercent = (info.PlayAnimPercent or 30) / 100
	s.CrouchDelay = SplatoonSWEPs:FrameToSec(info.Delay.Crouch or 10)
	self.Secondary = s
	if isfunction(self.CustomSecondary) then return self:CustomSecondary(s, info) end
end
