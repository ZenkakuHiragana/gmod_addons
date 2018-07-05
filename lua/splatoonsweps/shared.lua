
-- Shared library

local ss = SplatoonSWEPs
if not ss then return end
include "const.lua"
include "movement.lua"
include "sound.lua"
include "text.lua"
include "weapons.lua"
cleanup.Register(ss.CleanupTypeInk)

-- Compares each component and returns the smaller one.
-- Arguments:
--   Vector a, b	| Two vectors to compare.
-- Returning:
--   Vector			| A vector which contains the smaller components.
function ss:MinVector(a, b)
	return Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

-- Compares each component and returns the larger one.
-- Arguments:
--   Vector a, b	| Two vectors to compare.
-- Returning:
--   Vector			| A vector which contains the larger components.
function ss:MaxVector(a, b)
	return Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

-- Returns an AABB which contains all given points.
-- Arguments:
--   table vectors		| Table of vectors to make an AABB.
--   number minbound	| Minimum length of AABB.
-- Returns:
--   number mins, maxs	| An AABB represented by minimum and maximum vectors.
function ss:GetBoundingBox(vectors, minbound)
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	local bound = ss.vector_one * (minbound or 0)
	for _, v in ipairs(vectors) do
		mins = ss:MinVector(mins, v - bound)
		maxs = ss:MaxVector(maxs, v + bound)
	end
	return mins, maxs
end

-- Takes two AABBs and returns if they are colliding each other.
-- Arguments:
--   Vector mins1, maxs1	| The first AABB.
--   Vector mins2, maxs2	| The second AABB.
-- Returning:
--   bool					| Whether or not the two AABBs intersect each other.
function ss:CollisionAABB(mins1, maxs1, mins2, maxs2)
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
function ss:CollisionAABB2D(mins1, maxs1, mins2, maxs2)
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
function ss:To2D(source, orgpos, organg)
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
function ss:To3D(source, orgpos, organg)
	local localpos = Vector(0, source.x, source.y)
	return (LocalToWorld(localpos, angle_zero, orgpos, organg))
end

-- Short for Entity:NetworkVar().
-- A new function Entity:AddNetworkVar() is created to the given entity.
-- Argument:
--   Entity ent	| The entity to add to.
function ss:AddNetworkVar(ent)
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

-- Let the given entity use CurTime() based timer library.
-- Call it in the header, and put SplatoonSWEPs:ProcessSchedules() in ENT:Think().
-- Argument:
--   Entity ent	| The entity to be able to use timer library.
function ss:AddTimerFramework(ent)
	if ent.FunctionQueue then return end
	
	ss:AddNetworkVar(ent) -- Required to use Entity:AddNetworkSchedule()
	ent.FunctionQueue = {}
	
	-- Reset the interval of the schedule.
	-- Argument:
	--   number newdelay	| The new interval.
	local ScheduleFunc = {}
	local ScheduleMeta = {__index = ScheduleFunc}
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
	
	-- Set a time for SinceLastCalled()
	-- Argument:
	--   number newtime	| Relative to CurTime()
	function ScheduleFunc:SetLastCalled(newtime)
		if isstring(self.prevtime) then
			self.weapon["Set" .. self.prevtime](self.weapon, CurTime() + newtime)
		else
			self.prevtime = CurTime() + newtime
		end
	end
	
	-- Returns the time since the schedule has been last called.
	function ScheduleFunc:SinceLastCalled()
		return CurTime() - (isstring(self.prevtime) and
		self.weapon["Get" .. self.prevtime](self.weapon) or self.prevtime)
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
			done = 0,
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
		table.insert(self.FunctionQueue, schedule)
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
		table.insert(self.FunctionQueue, schedule)
		return schedule
	end
	
	-- Makes the registered functions run.  Put it in ENT:Think() for desired use.
	function ent:ProcessSchedules()
		for i, s in pairs(self.FunctionQueue) do
			if isstring(s.time) then
				if CurTime() > self["Get" .. s.time](self) then
					local remove = s.func(self, s)
					if remove then self.FunctionQueue[i] = nil end
					self["Set" .. s.prevtime](self, CurTime())
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

-- Short for checking isfunction()
-- Arguments:
--   function func	| The function to call safely.
--   vararg			| The arguments to give the function.
-- Returns:
--   vararg			| Returning values from the function.
function ss:ProtectedCall(func, ...)
	if isfunction(func) then return func(...) end
end

-- Checks if the given entity is a valid inkling (if it has a SplatoonSWEPs weapon).
-- Argument:
--   Entity ply		| The entity to be checked.  It is not always player.
-- Returning:
--   Entity			| The weapon the entity has.
--   nil			| The entity is not an inkling.
function ss:IsValidInkling(ply)
	if not IsValid(ply) then return end
	local w = ss:ProtectedCall(ply.GetActiveWeapon, ply)
	return IsValid(w) and w.IsSplatoonWeapon and not w:GetHolstering() and w or nil
end

-- Overriding footstep sound stops calling other PlayerFootstep hooks in other addons.
-- I decided to have one of their hook run my function.
local FootstepTrace = vector_up * -20
local hostkey, hostfunc, multisteps = hostkey, hostfunc, multisteps
for k, v in pairs(hook.GetTable().PlayerFootstep or {}) do
	if hostkey and hostfunc then multisteps = true break end
	if isstring(k) then hostkey, hostfunc = k, v end
end

-- This is my footstep hook.
local function PlayerFootstep(ply, pos, foot, soundname, volume, filter)
	local w = ss:IsValidInkling(ply)
	if not w or not game.SinglePlayer() and SERVER then return end
	if ply:Crouching() and w:GetBecomeSquid() and w:GetGroundColor() < 0 or
	not ply:Crouching() and w:GetGroundColor() >= 0 then
		ply:EmitSound "SplatoonSWEPs_Player.InkFootstep"
		return true
	end
	
	if not ply:Crouching() then return end
	return soundname:find "chainlink" and true or nil
end

if hostkey and hostfunc then
	hook.GetTable().PlayerFootstep[hostkey] = function(ply, pos, foot, sound, volume, filter)
		local mystep = PlayerFootstep(ply, pos, foot, sound, volume, filter)
		local a, b, c, d, e, f = hostfunc(ply, pos, foot, sound, volume, filter)
		if a == true then
			return a, b, c, d, e, f
		else
			return mystep
		end
	end
else -- No footstep hook is there.
	hook.Add("PlayerFootstep", "SplatoonSWEPs: Ink footstep", PlayerFootstep)
end

local weaponslot = {
	weapon_roller = 0,
	weapon_shooter = 1,
	weapon_blaster = 2,
	weapon_splatling = 3,
	weapon_charger = 4,
	weapon_scope = 4,
	weapon_slosher = 5,
}
hook.Add("PreGamemodeLoaded", "SplatoonSWEPs: Set weapon printnames", function()
	local ssEnabled = GetConVar "sv_splatoonsweps_enabled"
	if not ssEnabled or not ssEnabled:GetBool() then return end
	local weaponlist = list.GetForEdit "Weapon"
	for loop = 1, 2 do
		for i, c in ipairs(ss.WeaponClassNames) do
			for _, weapon in ipairs {weapons.GetStored(c), weaponlist[c]} do
				for _, v in ipairs(weapon.Variations or {}) do
					v.Base = c
					weapons.Register(v, v.ClassName)
				end
				
				weapon.Category = ss.Text.Category
				weapon.PrintName = ss.Text.PrintNames[c]
				weapon.Spawnable = true
				weapon.Slot = weaponslot[weapon.Base]
				weapon.SlotPos = i
				weapon.Variations = nil
				
				if CLIENT then
					local icon = "entities/" .. c
					if not file.Exists("materials/" .. icon .. ".vmt", "GAME") then
						icon = "weapons/swep"
					end
					if not killicon.Exists(c) then
						killicon.Add(c, icon, color_white) -- Weapon killicon
					end
					
					weapon.WepSelectIcon = surface.GetTextureID(icon) -- Weapon select icon
				end
				
				if not weapon.Slot then
					local base = weapons.Get(weapon.Base)
					weapon.Slot = base and base.Slot or 0
				end
			end
			
			if loop == 2 and weapons.Get(c) then -- Adds to NPC weapon list
				list.Add("NPCUsableWeapons", {class = c, title = ss.Text.PrintNames[c]})
			end
		end
	end
end)

-- Inkling playermodels hull change fix
if not isfunction(FindMetaTable "Player".SplatoonOffsets) then return end
if SERVER then
	hook.Remove("KeyPress", "splt_KeyPress")
	hook.Remove("PlayerSpawn", "splt_Spawn")
	hook.Remove("PlayerDeath", "splt_OnDeath")
	hook.Add("PlayerSpawn", "SplatoonSWEPs: Fix PM change", function(ply)
		ply:SetSubMaterial()
	end)
else
	hook.Remove("Tick", "splt_Offsets_cl")
end

local width = 16
hook.Add("Tick", "SplatoonSWEPs: Fix playermodel hull change", function()
	for _, p in ipairs(player.GetAll()) do
		local is = ss.CheckSplatoonPlayermodels[p:GetModel()]
		if not p:Alive() then ss.PlayerHullChanged[p] = nil continue end
		if is and GetConVar "splt_EditScale":GetInt() ~= 0 and ss.PlayerHullChanged[p] ~= true then
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
