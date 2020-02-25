
-- Shared library

local ss = SplatoonSWEPs
if not ss then return end

function ss.hook(func)
	if isstring(func) then
		return function(ply, ...)
			local w = ss.IsValidInkling(ply or CLIENT and LocalPlayer() or nil)
			if w then return ss[func](w, ply, ...) end
		end
	else
		return function(ply, ...)
			local w = ss.IsValidInkling(ply or CLIENT and LocalPlayer() or nil)
			if w then return func(w, ply, ...) end
		end
	end
end

-- Faster table.remove() function from stack overflow
-- https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
function ss.tableremovefunc(t, toremove)
    local k = 1
    for i = 1, #t do
        if toremove(t[i]) then
			t[i] = nil
		else -- Move i's kept value to k's position, if it's not already there.
            if i ~= k then t[k], t[i] = t[i] end
            k = k + 1 -- Increment position of where we'll place the next kept value.
        end
    end

    return t
end

function ss.tableremove(t, removal)
    local k = 1
    for i = 1, #t do
        if i == removal then
            t[i] = nil
        else -- Move i's kept value to k's position, if it's not already there.
            if i ~= k then t[k], t[i] = t[i] end
            k = k + 1 -- Increment position of where we'll place the next kept value.
        end
    end

    return t
end

-- Even faster than table.remove() and this removes the first element.
function ss.tablepop(t)
	local zero, one = t[0], t[1]
    for i = 1, #t do
        t[i - 1], t[i] = t[i]
    end

	t[0] = zero
    return one
end

-- Faster than table.insert() and this inserts an element at the beginning.
function ss.tablepush(t, v)
    local n = #t
    for i = n, 1, -1 do
        t[i + 1], t[i] = t[i]
    end

	t[1] = v
end

-- Each surface should have these fields.
function ss.CreateSurfaceStructure()
	return CLIENT and {} or {
		Angles = {},
		Areas = {},
		Bounds = {},
		DefaultAngles = {},
		Indices = {},
		InkCircles = {},
		Maxs = {},
		Mins = {},
		Normals = {},
		Origins = {},
		Vertices = {},
	}
end

-- There is an annoying limitation on util.JSONToTable(),
-- which is that the amount of a table is up to 15000.
-- Therefore, GMOD can't save/restore a table if #source > 15000.
-- This function sanitises a table with a large amount of data.
-- Argument:
--   table source | A table containing a large amount of data.
-- Returning:
--   table        | A nested table.  Each element has up to 15000 data.
function ss.AvoidJSONLimit(source)
	local s = {}
	for chunk = 1, math.ceil(#source / 15000) do
		local t = {}
		for i = 1, 15000 do
			local index = (chunk - 1) * 15000 + i
			if index > #source then break end
			t[#t + 1] = source[index]
		end

		s[chunk] = t
	end

	return s
end

-- Restores a table saved with ss.AvoidJSONLimit().
-- Argument:
--   table source | A nested table made by ss.AvoidJSONLimit().
-- Returning:
--   table        | A sequential table.
function ss.RestoreJSONLimit(source)
	local s = {}
	for _, chunk in ipairs(source) do
		for _, v in ipairs(chunk) do s[#s + 1] = v end
	end

	return s
end

-- Finds AABB-tree nodes/leaves which includes the given AABB.
-- Use as an iterator function:
--   for nodes in SplatoonSWEPs:SearchAABB(AABB) do ... end
-- Arguments:
--   table AABB | {mins = Vector(), maxs = Vector()}
-- Returns:
--   table      | A sequential table.
function ss.SearchAABB(AABB, normal)
	local function recursive(a)
		local t = {}
		if a.SurfIndices then
			for _, i in ipairs(a.SurfIndices) do
				local a = ss.SurfaceArray[i]
				if a.Normal:Dot(normal) > ss.MAX_COS_DEG_DIFF then
					if ss.CollisionAABB(a.AABB.mins, a.AABB.maxs, AABB.mins, AABB.maxs) then
						t[#t + 1] = a
					end
				end
			end
		else
			local l = ss.AABBTree[a.Children[1]]
			local r = ss.AABBTree[a.Children[2]]
			if l and ss.CollisionAABB(l.AABB.mins, l.AABB.maxs, AABB.mins, AABB.maxs) then
				table.Add(t, recursive(l))
			end

			if r and ss.CollisionAABB(r.AABB.mins, r.AABB.maxs, AABB.mins, AABB.maxs) then
				table.Add(t, recursive(r))
			end
		end

		return t
	end

	return ipairs(recursive(ss.AABBTree[1]))
end

-- Compares each component and returns the smaller one.
-- Arguments:
--   Vector a, b	| Two vectors to compare.
-- Returning:
--   Vector			| A vector which contains the smaller components.
function ss.MinVector(a, b)
	return Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

-- Compares each component and returns the larger one.
-- Arguments:
--   Vector a, b	| Two vectors to compare.
-- Returning:
--   Vector			| A vector which contains the larger components.
function ss.MaxVector(a, b)
	return Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

-- Returns an AABB which contains all given points.
-- Arguments:
--   table vectors		| Table of vectors to make an AABB.
--   number minbound	| Minimum length of AABB.
-- Returns:
--   number mins, maxs	| An AABB represented by minimum and maximum vectors.
function ss.GetBoundingBox(vectors, minbound)
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	local bound = ss.vector_one * (minbound or 0)
	for _, v in ipairs(vectors) do
		mins = ss.MinVector(mins, v - bound)
		maxs = ss.MaxVector(maxs, v + bound)
	end
	return mins, maxs
end

-- Takes two AABBs and returns if they are colliding each other.
-- Arguments:
--   Vector mins1, maxs1	| The first AABB.
--   Vector mins2, maxs2	| The second AABB.
-- Returning:
--   bool					| Whether or not the two AABBs intersect each other.
function ss.CollisionAABB(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y and
			mins1.z < maxs2.z and maxs1.z > mins2.z
end

-- Basically same as SplatoonSWEPs:CollisionAABB(), but ignores Z-component.
-- Arguments:
--   Vector mins1, maxs1	| The first AABB.
--   Vector mins2, maxs2	| The second AABB.
-- Returning:
--   bool					| Whether or not the two AABBs intersect each other.
function ss.CollisionAABB2D(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y
end

-- Short for WorldToLocal()
-- Arguments:
--   Vector source	| A 3D vector to be converted into 2D space.
--   Vector orgpos	| The origin of new 2D system.
--   Angle organg	| The angle of new 2D system.
-- Returning:
--   Vector			| A converted 2D vector.
function ss.To2D(source, orgpos, organg)
	local localpos = WorldToLocal(source, angle_zero, orgpos, organg)
	return Vector(localpos.y, localpos.z, 0)
end

-- Short for LocalToWorld()
-- Arguments:
--   Vector source	| A 2D vector to be converted into 3D space.
--   Vector orgpos	| The origin of 2D system in world coordinates.
--   Angle organg	| The angle of 2D system relative to the world.
-- Returning:
--   Vector			| A converted 3D vector.
function ss.To3D(source, orgpos, organg)
	local localpos = Vector(0, source.x, source.y)
	return (LocalToWorld(localpos, angle_zero, orgpos, organg))
end

-- util.IsInWorld() only exists in serverside.
-- This is shared version of it.
-- Argument:
--   Vector pos		| A vector to test.
-- Returning:
--   bool			| The given vector is in world or not.
function ss.IsInWorld(pos)
	return math.abs(pos.x) < 16384 and math.abs(pos.y) < 16384 and math.abs(pos.z) < 16384
end

-- For Charger's interpolation.
-- Arguments:
--   number frac	| Fraction.
--   number min 	| Minimum value.
--   number max 	| Maximum value.
--   number full	| An optional value returned when frac == 1.
-- Returning:
--   number			| Interpolated value.
function ss.Lerp3(frac, min, max, full)
	return frac < 1 and Lerp(frac, min, max) or full or max
end

-- Short for checking isfunction()
-- Arguments:
--   function func	| The function to call safely.
--   vararg			| The arguments to give the function.
-- Returns:
--   vararg			| Returning values from the function.
function ss.ProtectedCall(func, ...)
	if isfunction(func) then return func(...) end
end

-- Checks if the given entity is a valid inkling (if it has a SplatoonSWEPs weapon).
-- Argument:
--   Entity ply		| The entity to be checked.  It is not always player.
-- Returning:
--   Entity			| The weapon the entity has.
--   nil			| The entity is not an inkling.
function ss.IsValidInkling(ply)
	if not IsValid(ply) then return end
	local w = ss.ProtectedCall(ply.GetActiveWeapon, ply)
	return IsValid(w) and w.IsSplatoonWeapon and not w:GetHolstering() and w or nil
end

-- Checks if the given two colors are the same, considering FF setting.
-- Arguments:
--   number c1, c2 | The colors to be compared.  Can also be Splatoon weapons.
-- Returning:
--   bool          | The colors are the same.
function ss.IsAlly(c1, c2)
	if isentity(c1) and IsValid(c1) and isentity(c2) and IsValid(c2) and c1 == c2 then
		return not ss.GetOption "weapon_splatoonsweps_blaster_base" "hurtowner"
	end

	c1 = isentity(c1) and IsValid(c1) and c1:GetNWInt "inkcolor" or c1
	c2 = isentity(c2) and IsValid(c2) and c2:GetNWInt "inkcolor" or c2
	return not ss.GetOption "ff" and c1 == c2
end

-- Get player timescale.
-- Argument:
--   Entity ply    | Optional.
-- Returning:
--   number scale  | The game timescale.
local host_timescale = GetConVar "host_timescale"
function ss.GetTimeScale(ply)
	return IsValid(ply) and ply:IsPlayer() and ply:GetLaggedMovementValue() or 1
end

-- Play a sound that can be heard only one player.
-- Arguments:
--   Player ply			| The player who can hear it.
--   string soundName	| The sound to play.
function ss.EmitSound(ply, soundName, soundLevel, pitchPercent, volume, channel)
	if not (IsValid(ply) and ply:IsPlayer()) then return end
	if SERVER and ss.mp then
		net.Start "SplatoonSWEPs: Send a sound"
		net.WriteString(soundName)
		net.WriteUInt(soundLevel or 75, 9)
		net.WriteUInt(pitchPercent or 100, 8)
		net.WriteFloat(volume or 1)
		net.WriteUInt((channel or CHAN_AUTO) + 1, 8)
		net.Send(ply)
	elseif CLIENT and IsFirstTimePredicted() or ss.sp then
		ply:EmitSound(soundName, soundLevel, pitchPercent, volume, channel)
	end
end

-- Play a sound properly in a weapon predicted hook.
-- Arguments:
--   Player ply | The owner of the weapon.
--   Entity ent | The weapon.
--   vararg     | The arguments of Entity:EmitSound()
function ss.EmitSoundPredicted(ply, ent, ...)
	ss.SuppressHostEventsMP(ply)
	ent:EmitSound(...)
	ss.EndSuppressHostEventsMP(ply)
end

function ss.SuppressHostEventsMP(ply)
	if ss.sp or CLIENT then return end
	if IsValid(ply) and ply:IsPlayer() then
		SuppressHostEvents(ply)
	end
end

function ss.EndSuppressHostEventsMP(ply)
	if ss.sp or CLIENT then return end
	if IsValid(ply) and ply:IsPlayer() then
		SuppressHostEvents(NULL)
	end
end

-- The function names of EffectData() don't make sense, renaming.
do local e = EffectData()
	ss.GetEffectSplash = e.GetAngles -- Angle(SplashColRadius, SplashDrawRadius, SplashLength)
	ss.SetEffectSplash = e.SetAngles
	ss.GetEffectColor = e.GetColor
	ss.SetEffectColor = e.SetColor
	ss.GetEffectColRadius = e.GetRadius
	ss.SetEffectColRadius = e.SetRadius
	ss.GetEffectDrawRadius = e.GetMagnitude
	ss.SetEffectDrawRadius = e.SetMagnitude
	ss.GetEffectEntity = e.GetEntity
	ss.SetEffectEntity = e.SetEntity
	ss.GetEffectInitPos = e.GetOrigin
	ss.SetEffectInitPos = e.SetOrigin
	ss.GetEffectInitVel = e.GetStart
	ss.SetEffectInitVel = e.SetStart
	ss.GetEffectSplashInitRate = e.GetNormal
	ss.SetEffectSplashInitRate = e.SetNormal
	ss.GetEffectSplashNum = e.GetSurfaceProp
	ss.SetEffectSplashNum = e.SetSurfaceProp
	ss.GetEffectStraightFrame = e.GetScale
	ss.SetEffectStraightFrame = e.SetScale
	ss.GetEffectFlags = e.GetFlags
	function ss.SetEffectFlags(eff, weapon, flags)
		if isnumber(weapon) and not flags then
			flags, weapon = weapon
		end

		flags = flags or 0
		if IsValid(weapon) then
			local IsLP = CLIENT and weapon:IsCarriedByLocalPlayer()
			flags = flags + (IsLP and 128 or 0)
		end

		eff:SetFlags(flags)
	end

	-- Dispatch an effect properly in a weapon predicted hook.
	-- Arguments:
	--   Player ply        | The owner of the weapon
	--   vararg            | Arguments of util.Effect()
	function ss.UtilEffectPredicted(ply, ...)
		ss.SuppressHostEventsMP(ply)
		util.Effect(...)
		ss.EndSuppressHostEventsMP(ply)
	end
end

include "debug.lua"
include "text.lua"
include "convars.lua"
include "inkmanager.lua"
include "movement.lua"
include "sound.lua"
include "trajectory.lua"
include "weapons.lua"
include "weaponregistration.lua"

-- Short for Entity:NetworkVar().
-- A new function Entity:AddNetworkVar() is created to the given entity.
-- Argument:
--   Entity ent	| The entity to add to.
function ss.AddNetworkVar(ent)
	if ent.NetworkSlot then return end
	ent.NetworkSlot = {
		String = -1, Bool = -1, Float = -1, Int = -1,
		Vector = -1, Angle = -1, Entity = -1,
	}

	-- Returns how many network slots the entity uses.
	-- Argument:
	--   string typeof	| The type to inspect.
	-- Returning:
	--   number			| The number of slots the entity uses.
	function ent:GetLastSlot(typeof) return self.NetworkSlot[typeof] end

	-- Adds a new network variable to the entity.
	-- Arguments:
	--   string typeof	| The variable type.  Same as Entity:NetworkVar().
	--   string name	| The variable name.
	-- Returning:
	--   number			| A new assigned slot.
	function ent:AddNetworkVar(typeof, name)
		assert(self.NetworkSlot[typeof] < 31, "SplatoonSWEPs: Tried to use too many network variables!")
		self.NetworkSlot[typeof] = self.NetworkSlot[typeof] + 1
		self:NetworkVar(typeof, self.NetworkSlot[typeof], name)
		return self.NetworkSlot[typeof]
	end
end

-- Lets the given entity use CurTime() based timer library.
-- Call it in the header, and put SplatoonSWEPs:ProcessSchedules() in ENT:Think().
-- Argument:
--   Entity ent	| The entity to be able to use timer library.
function ss.AddTimerFramework(ent)
	if ent.FunctionQueue then return end

	ss.AddNetworkVar(ent) -- Required to use Entity:AddNetworkSchedule()
	ent.FunctionQueue = {}

	-- Sets how many this schedule has done.
	-- Argument:
	--   number done | The new counter.
	local ScheduleFunc = {}
	local ScheduleMeta = {__index = ScheduleFunc}
	function ScheduleFunc:SetDone(done)
		if isstring(self.done) then
			self.weapon["Set" .. self.done](self.weapon, done)
		else
			self.done = done
		end
	end

	-- Returns the current counter value.
	function ScheduleFunc:GetDone()
		return isstring(self.done) and self.weapon["Get" .. self.done](self.weapon) or self.done
	end

	-- Resets the interval of the schedule.
	-- Argument:
	--   number newdelay	| The new interval.
	function ScheduleFunc:SetDelay(newdelay)
		if isstring(self.delay) then
			self.weapon["Set" .. self.delay](self.weapon, newdelay)
		else
			self.delay = newdelay
		end

		if isstring(self.prevtime) then
			self.weapon["Set" .. self.prevtime](self.weapon, CurTime())
		else
			self.prevtime = CurTime()
		end

		if isstring(self.time) then
			self.weapon["Set" .. self.time](self.weapon, CurTime() + newdelay)
		else
			self.time = CurTime() + newdelay
		end
	end

	-- Returns the current interval of the schedule.
	function ScheduleFunc:GetDelay()
		return isstring(self.delay) and self.weapon["Get" .. self.delay](self.weapon) or self.delay
	end

	-- Sets a time for SinceLastCalled()
	-- Argument:
	--   number newtime	| Relative to CurTime()
	function ScheduleFunc:SetLastCalled(newtime)
		if isstring(self.prevtime) then
			self.weapon["Set" .. self.prevtime](self.weapon, CurTime() - newtime)
		else
			self.prevtime = CurTime() - newtime
		end
	end

	-- Returns the time since the schedule has been last called.
	function ScheduleFunc:SinceLastCalled()
		if isstring(self.prevtime) then
			return CurTime() - self.weapon["Get" .. self.prevtime](self.weapon)
		else
			return CurTime() - self.prevtime
		end
	end

	-- Adds an syncronized schedule.
	-- Arguments:
	--   number delay	| How long the function should be ran in seconds.
	--   				| Use 0 to have the function run every time ENT:Think() called.
	--   function func	| The function to run after the specified delay.
	-- Returning:
	--   table			| The created schedule object.
	function ent:AddNetworkSchedule(delay, func)
		local schedule = setmetatable({
			func = func,
			weapon = self,
		}, ScheduleMeta)
		schedule.delay = "TimerDelay" .. tostring(self:GetLastSlot "Float")
		self:AddNetworkVar("Float", schedule.delay)
		self["Set" .. schedule.delay](self, delay)
		schedule.prevtime = "TimerPrevious" .. tostring(self:GetLastSlot "Float")
		self:AddNetworkVar("Float", schedule.prevtime)
		self["Set" .. schedule.prevtime](self, CurTime())
		schedule.time = "Timer" .. tostring(self:GetLastSlot "Float")
		self:AddNetworkVar("Float", schedule.time)
		self["Set" .. schedule.time](self, CurTime())
		schedule.done = "Done" .. tostring(self:GetLastSlot "Int")
		self:AddNetworkVar("Int", schedule.done)
		self["Set" .. schedule.done](self, 0)
		self.FunctionQueue[#self.FunctionQueue + 1] = schedule
		return schedule
	end

	-- Adds an schedule.
	-- Arguments:
	--   number delay	| How long the function should be ran in seconds.
	--   				| Use 0 to have the function run every time ENT:Think() called.
	--   number numcall	| The number of times to repeat.  Set to nil or 0 for infinite schedule.
	--   function func	| The function to run.  Returning true in it to have the schedule stop.
	-- Returning:
	--   table			| The created schedule object.
	function ent:AddSchedule(delay, numcall, func)
		local schedule = setmetatable({
			delay = delay,
			done = 0,
			func = func or numcall,
			numcall = func and numcall or 0,
			time = CurTime() + delay,
			prevtime = CurTime(),
			weapon = self,
		}, ScheduleMeta)
		self.FunctionQueue[#self.FunctionQueue + 1] = schedule
		return schedule
	end

	-- Makes the registered functions run.  Put it in ENT:Think() for desired use.
	function ent:ProcessSchedules()
		for i, s in pairs(self.FunctionQueue) do
			if isstring(s.time) then
				if CurTime() > self["Get" .. s.time](self) then
					local remove = s.func(self, s)
					self["Set" .. s.prevtime](self, CurTime())
					self["Set" .. s.time](self, CurTime() + self["Get" .. s.delay](self))
					self["Set" .. s.done](self, self["Get" .. s.done](self) + 1)
					if remove then self["Set" .. s.done](self, 2^16 - 1) end
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

-- ss.GetMaxHealth() - Get inkling's desired maximum health
-- ss.GetMaxInkAmount() - Get the maximum amount of an ink tank.
local gain = ss.GetOption "gain"
function ss.GetMaxHealth() return gain "maxhealth" end
function ss.GetMaxInkAmount() return gain "inkamount" end

-- Play footstep sound of ink.
function ss.PlayerFootstep(w, ply, pos, foot, soundName, volume, filter)
	if SERVER and ss.mp then return end
	if ply:Crouching() and w:GetNWBool "becomesquid" and w:GetGroundColor() < 0
	or not ply:Crouching() and w:GetGroundColor() >= 0 then
		ply:EmitSound "SplatoonSWEPs_Player.InkFootstep"
		return true
	end

	if not ply:Crouching() then return end
	return soundName:find "chainlink" and true or nil
end

function ss.UpdateAnimation(w, ply, velocity, maxseqspeed)
	ss.ProtectedCall(w.UpdateAnimation, w, ply, velocity, maxseqspeed)

	if not w:GetThrowing() then return end

	ply:AnimSetGestureWeight(GESTURE_SLOT_ATTACK_AND_RELOAD, 1)

	local f = (CurTime() - w:GetThrowAnimTime()) / ss.SubWeaponThrowTime
	if CLIENT and w:IsCarriedByLocalPlayer() then
		f = f + LocalPlayer():Ping() / 1000 / ss.SubWeaponThrowTime
	end

	if 0 <= f and f <= 1 then
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD,
		ply:SelectWeightedSequence(ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE),
		f * .55, true)
	end
end

function ss.KeyPress(self, ply, key)
	if ss.KeyMaskFind[key] then
		self.LastKeyDown[key] = CurTime()
		self:SetKey(key)
		if CurTime() > self:GetCooldown() then
			self:SetThrowing(self:GetThrowing() and key == IN_ATTACK2)
		end
	end

	ss.ProtectedCall(self.KeyPress, self, ply, key)
end

function ss.KeyRelease(self, ply, key)
	if CurTime() < self:GetNextSecondaryFire() then return end
	local keytable, keytime = {}, {}
	for _, k in ipairs(ss.KeyMask) do
		local t = self.LastKeyDown[k] or 0
		if self.Owner:KeyDown(k) then keytime[#keytime + 1] = t end
		keytable[t] = k -- [Last time key down] = key
	end

	self:SetKey(keytable[math.max(0, unpack(keytime))] or 0)
	ss.ProtectedCall(self.KeyRelease, self, ply, key)

	if not ss.KeyMaskFind[key] then return end
	if not (self:GetThrowing() and key == IN_ATTACK2) then return end
	self:AddSchedule(ss.SubWeaponThrowTime, 1, function() self:SetThrowing(false) end)

	local time = CurTime() + ss.SubWeaponThrowTime
	self:SetCooldown(time)
	self:SetThrowAnimTime(CurTime())
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)
	self:SetWeaponAnim(ss.ViewModel.Throw)

	local hasink = self:GetInk() > 0
	local able = hasink and self:CheckCanStandup()
	ss.ProtectedCall(self.SharedSecondaryAttack, self, able)
	ss.ProtectedCall(Either(SERVER, self.ServerSecondaryAttack, self.ClientSecondaryAttack), self, able)
end

function ss.OnPlayerHitGround(self, ply, inWater, onFloater, speed)
	if not self:GetInInk() then return end
	if not self:IsFirstTimePredicted() then return end
	local e = EffectData()
	local f = (speed - 100) / 600
	local t = util.QuickTrace(ply:GetPos(), -vector_up * 16384, {self, ply})
	e:SetAngles(t.HitNormal:Angle())
	e:SetAttachment(10)
	e:SetColor(self:GetNWInt "inkcolor")
	e:SetEntity(self)
	e:SetFlags((f > .5 and 7 or 3) + (CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0))
	e:SetOrigin(t.HitPos)
	e:SetRadius(Lerp(f, 25, 50))
	e:SetScale(.5)
	util.Effect("SplatoonSWEPsMuzzleSplash", e, true)
end

hook.Add("PlayerFootstep", "SplatoonSWEPs: Ink footstep", ss.hook "PlayerFootstep")
hook.Add("UpdateAnimation", "SplatoonSWEPs: Adjust TPS animation speed", ss.hook "UpdateAnimation")
hook.Add("KeyPress", "SplatoonSWEPs: Check a valid key", ss.hook "KeyPress")
hook.Add("KeyRelease", "SplatoonSWEPs: Throw sub weapon", ss.hook "KeyRelease")
hook.Add("OnPlayerHitGround", "SplatoonSWEPs: Play diving sound", ss.hook "OnPlayerHitGround")

cvars.AddChangeCallback("gmod_language", function(convar, old, new)
	CompileFile "splatoonsweps/text.lua" ()
end, "SplatoonSWEPs: OnLanguageChanged")

if ss.GetOption "enabled" then
	cleanup.Register(ss.CleanupTypeInk)
end

local nest = nil
for hookname in pairs {CalcMainActivity = true, TranslateActivity = true} do
	hook.Add(hookname, "SplatoonSWEPs: Crouch anim in fence", ss.hook(function(w, ply, ...)
		if nest then nest = nil return end
		if not ply:Crouching() then return end
		if not w:GetInFence() then return end
		nest, ply.m_bWasNoclipping = true
		ply:SetMoveType(MOVETYPE_WALK)
		local res1, res2 = gamemode.Call(hookname, ply, ...)
		ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
		ply:SetMoveType(MOVETYPE_NOCLIP)
		return res1, res2
	end))
end

concommand.Add("-splatoonsweps_reset_camera", function(ply) end, nil, ss.Text.CVars.ResetCamera)
concommand.Add("+splatoonsweps_reset_camera", function(ply)
	ss.PlayerShouldResetCamera[ply] = true
end, nil, ss.Text.CVars.ResetCamera)

------------------------------------------
--			!!!WORKAROUND!!!			--
--	This should be removed after		--
--	Adv. Colour Tool fixed the bug!!	--
------------------------------------------
local AdvancedColourToolLoaded
= file.Exists("weapons/gmod_tool/stools/adv_colour.lua", "LUA")
local AdvancedColourToolReplacedSetSubMaterial
= AdvancedColourToolLoaded and FindMetaTable "Entity"._OldSetSubMaterial
if AdvancedColourToolReplacedSetSubMaterial then
	function ss.SetSubMaterial_ShouldBeRemoved(ent, ...)
		ent:_OldSetSubMaterial(...)
	end
else
	function ss.SetSubMaterial_ShouldBeRemoved(ent, ...)
		ent:SetSubMaterial(...)
	end
end
------------------------------------------
--			!!!WORKAROUND!!!			--
------------------------------------------


-- Inkling playermodels hull change fix
if not isfunction(FindMetaTable "Player".SplatoonOffsets) then return end
CreateConVar("splt_Colors", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Toggles skin/eye colors on Splatoon playermodels.")
if SERVER then
	hook.Remove("KeyPress", "splt_KeyPress")
	hook.Remove("PlayerSpawn", "splt_Spawn")
	hook.Remove("PlayerDeath", "splt_OnDeath")
	hook.Add("PlayerSpawn", "SplatoonSWEPs: Fix PM change", function(ply)
		ss.SetSubMaterial_ShouldBeRemoved(ply)
	end)
else
	hook.Remove("Tick", "splt_Offsets_cl")
end

local width = 16
local splt_EditScale = GetConVar "splt_EditScale"
hook.Add("Tick", "SplatoonSWEPs: Fix playermodel hull change", function()
	for _, p in ipairs(player.GetAll()) do
		local is = ss.DrLilRobotPlayermodels[p:GetModel()]
		if not p:Alive() then
			ss.PlayerHullChanged[p] = nil
		elseif is and splt_EditScale:GetInt() ~= 0 and ss.PlayerHullChanged[p] ~= true then
			p:SetViewOffset(Vector(0, 0, 42))
			p:SetViewOffsetDucked(Vector(0, 0, 28))
			p:SetHull(Vector(-width, -width, 0), Vector(width, width, 53))
			p:SetHullDuck(Vector(-width, -width, 0), Vector(width, width, 33))
			ss.PlayerHullChanged[p] = true
		elseif not is and ss.PlayerHullChanged[p] ~= false then
			p:DefaultOffsets()
			ss.PlayerHullChanged[p] = false
		end
	end
end)
