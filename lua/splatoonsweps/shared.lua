
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

for i = 1, 9 do
	local mask = {}
	local masktxt = file.Open("data/splatoonsweps/shot" .. tostring(i) .. ".txt", "rb", "GAME")
	mask.width = masktxt:ReadByte()
	mask.height = masktxt:ReadByte()
	for p = 1, mask.width * mask.height do
		mask[p] = masktxt:Read(1) == "1"
	end
	
	ss.InkShotMaterials[i] = mask
	masktxt:Close()
end

include "const.lua"
include "movement.lua"
include "sound.lua"
include "text.lua"
include "weapons.lua"
cleanup.Register(ss.CleanupTypeInk)

-- Returns which sides the polygon specified by given vertices is.
-- Arguments:
--   table vertices	| Vertices of the face
--   Vector normal	| Normal of plane
--   number dist	| Distance from plane to origin
-- Returns:
--   Positive value | Face is in positive side of the plane
--   Negative value | Face is in negative side of the plane
--   0              | Face intersects with the plane
local PlaneThickness = 0.2
local function AcrossPlane(vertices, normal, dist)
	local sign
	for i, v in ipairs(vertices) do --for each vertices of face
		local dot = normal:Dot(v) - dist
		if math.abs(dot) > PlaneThickness then
			if sign and sign * dot < 0 then return 0 end
			sign = (sign or 0) + dot
		end
	end
	return sign or 0
end

-- Returns which node the polygon specified by given vertices is in.
-- Arguments:
--   table vertices    | Vertices of the face
--   number modelindex | BSP tree index.  Optional.
-- Returning:
--   table node        | The node which contains the face.
function ss.FindLeaf(vertices, modelindex)
	local node = ss.Models[modelindex or 1]
	while node.Separator do
		local sign = AcrossPlane(vertices, node.Separator.normal, node.Separator.distance)
		if sign == 0 then return node end
		node = node.ChildNodes[sign > 0 and 1 or 2]
	end
	return node
end

-- Finds BSP nodes/leaves which includes the given face.
-- Use as an iterator function:
--   for nodes in SplatoonSWEPs:BSPPairs {table of vertices} ... end
-- Arguments:
--   table vertices		| Table of Vertices which represents the face.
--   number modelindex	| BSP tree index.  Optional.
-- Returns:
--   function			| An iterator function.
function ss.BSPPairs(vertices, modelindex)
	return function(queue, old)
		if old.Separator then
			local sign = AcrossPlane(vertices, old.Separator.normal, old.Separator.distance)
			if sign >= 0 then table.insert(queue, old.ChildNodes[1]) end
			if sign <= 0 then table.insert(queue, old.ChildNodes[2]) end
		end
		return table.remove(queue, 1)
	end, {ss.Models[modelindex or 1]}, {}
end

-- Returns an iterator function which covers all nodes in map BSP tree.
-- Argument:
--   number modelindex	| BSP tree index.  Optional.
-- Returning:
--   function			| An iterator function.
function ss.BSPPairsAll(modelindex)
	return function(queue, old)
		if old and old.ChildNodes then
			table.insert(queue, old.ChildNodes[1])
			table.insert(queue, old.ChildNodes[2])
		end
		return table.remove(queue, 1)
	end, {ss.Models[modelindex or 1]}
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

-- Records a new ink to ink history.
-- Arguments:
--   table ink       | Ink history table. node.Surfaces.InkCircle or SequentialSurfaces.InkCircle
--   number sz       | Ink surface Z-position.
--   table newink    | A table which describes the new ink.
--     number angle  | Ink pattern angle in degrees.
--     table bounds  | Ink bounding box, {min.x, min.y, max.x, max.y}
--     number color  | Color code.
--     Vector pos    | Ink position in surface-related system.
--     number radius | Ink characteristic radius.
--     number ratio  | Ink aspect ratio.
--     number texid  | Ink pattern ID.
local MIN_BOUND_AREA = 64 -- minimum ink bounding box area
function ss.AddInkRectangle(ink, sz, newink)
	local nb, nr = newink.bounds, newink.ratio
	local n1, n2, n3, n4 = nb[1], nb[2], nb[3], nb[4] -- 1, 2 = min, 3, 4 = max
	for r, z in pairs(ink) do
		local bounds, lr = r.bounds, r.lastratio
		if not next(bounds) then
			if lr > .6 then
				ink[r] = nil
			else
				r.lastratio = lr + 1e-4
			end
		else
			for b in pairs(bounds) do
				local b1, b2, b3, b4 = b[1], b[2], b[3], b[4]
				if (b3 - b1) * (b4 - b2) < MIN_BOUND_AREA then r.bounds[b] = nil continue end
				if n1 > b3 or n3 < b1 or n2 > b4 or n4 < b2 then continue end
				r.lastratio, r.bounds[b] = nr
				local x, y = {n1, n3, b1, b3}, {n2, n4, b2, b4} table.sort(x) table.sort(y)
				local x1, x2, x3, x4, y1, y2, y3, y4
					= x[1], x[2], x[3], x[4], y[1], y[2], y[3], y[4]
				local t = {
					{x1, y1, x2, y2}, {x2, y1, x3, y2}, {x3, y1, x4, y2},
					{x1, y2, x2, y3}, {x2, y2, x3, y3}, {x3, y2, x4, y3},
					{x1, y3, x2, y4}, {x2, y3, x3, y4}, {x3, y3, x4, y4},
				}
				for i = 1, 9 do
					local c = t[i]
					local c1, c2, c3, c4 = c[1], c[2], c[3], c[4]
					r.bounds[c] = b1 < c3 and b3 > c1 and b2 < c4 and b4 > c2 and
						(n1 >= c3 or n3 <= c1 or n2 >= c4 or n4 <= c2) or nil
				end
			end
		end
	end
	
	newink.bounds = {[nb] = true}
	ink[newink] = sz
end

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
	c1 = isentity(c1) and c1.ColorCode or c1
	c2 = isentity(c2) and c2.ColorCode or c2
	local CVarFF = GetConVar "sv_splatoonsweps_ff"
	return not (CVarFF and CVarFF:GetBool()) and c1 == c2
end

-- Time to run EmitSound() is a little complicated.
-- Argument:
--   Entity ply    | Player to suppress.
function ss.ShouldSuppress(ply)
	if CLIENT or ss.sp then return end
	SuppressHostEvents(ply)
end

-- Time to run EmitSound() is a little complicated.
-- Argument:
--   Entity ent    | Entity to emit sound.
--   string track  | Sound to be played.
function ss.ShouldEmitSound(ent, track)
	if CLIENT or ss.sp then return end
	ent:EmitSound(track)
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
function ss.PlayerFootstep(w, ply, pos, foot, soundname, volume, filter)
	if SERVER and ss.mp then return end
	if ply:Crouching() and w.BecomeSquid and w:GetGroundColor() < 0 or
	not ply:Crouching() and w:GetGroundColor() >= 0 then
		ply:EmitSound "SplatoonSWEPs_Player.InkFootstep"
		return true
	end
	
	if not ply:Crouching() then return end
	return soundname:find "chainlink" and true or nil
end

if hostkey and hostfunc then
	hook.GetTable().PlayerFootstep[hostkey] = function(...)
		local mystep = ss.hook "PlayerFootstep" (...)
		local a, b, c, d, e, f = hostfunc(...)
		if a == true then
			return a, b, c, d, e, f
		else
			return mystep
		end
	end
else -- No footstep hook is there.
	hook.Add("PlayerFootstep", "SplatoonSWEPs: Ink footstep", ss.hook "PlayerFootstep")
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
local function RegisterWeapons()
	local ssEnabled = GetConVar "sv_splatoonsweps_enabled"
	if not ssEnabled or not ssEnabled:GetBool() then return end
	
	local oldSWEP = SWEP
	for base in pairs(weaponslot) do
		local LuaFolderPath = "weapons/" .. base
		for i, LuaFilePath in ipairs(file.Find(LuaFolderPath .. "/weapon_*.lua", "LUA")) do
			local ClassName = LuaFilePath:StripExtension()
			LuaFilePath = LuaFolderPath .. "/" .. LuaFilePath
			
			if SERVER then AddCSLuaFile(LuaFilePath) end
			SWEP = {
				Base = base,
				ClassName = ClassName,
				Folder = LuaFolderPath,
			}
			
			include(LuaFilePath)
			
			for _, v in ipairs(SWEP.Variations or {}) do
				v.Base = base
				v.Category = ss.Text.Category
				v.OriginalName = base
				v.PrintName = ss.Text.PrintNames[v.ClassName]
				v.Spawnable = true
				setmetatable(v, {__index = SWEP})
				weapons.Register(v, v.ClassName)
				list.Add("NPCUsableWeapons", {
					class = v.ClassName,
					title = ss.Text.PrintNames[v.ClassName],
				})
			end
			
			local name = SWEP.OriginalName or SWEP.ClassName
			SWEP.ModelPath = SWEP.ModelPath or "models/splatoonsweps/" .. name .. "/"
			SWEP.ViewModel = SWEP.ModelPath .. "c_viewmodel.mdl"
			SWEP.WorldModel = SWEP.ModelPath .. "w_right.mdl"
			SWEP.Category = ss.Text.Category
			SWEP.PrintName = ss.Text.PrintNames[SWEP.ClassName]
			SWEP.Spawnable = true
			SWEP.Slot = weaponslot[SWEP.Base]
			SWEP.SlotPos = i
				
			if CLIENT then
				local icon = "entities/" .. SWEP.ClassName
				if not file.Exists("materials/" .. icon .. ".vmt", "GAME") then
					icon = "weapons/swep"
				end
				
				if not killicon.Exists(SWEP.ClassName) then
					killicon.Add(SWEP.ClassName, icon, color_white) -- Weapon killicon
				end
				
				SWEP.WepSelectIcon = surface.GetTextureID(icon) -- Weapon select icon
			end
			
			if not SWEP.Slot then
				local BaseTable = weapons.Get(SWEP.Base)
				SWEP.Slot = BaseTable and BaseTable.Slot or 0
			end
			
			weapons.Register(SWEP, SWEP.ClassName)
			list.Add("NPCUsableWeapons", {
				class = SWEP.ClassName,
				title = SWEP.PrintName,
			})
		end
	end
	
	SWEP = oldSWEP
end

hook.Add("PreGamemodeLoaded", "SplatoonSWEPs: Set weapon printnames", RegisterWeapons)
cvars.AddChangeCallback("gmod_language", function(convar, old, new)
	CompileFile "splatoonsweps/text.lua" ()
end, "SplatoonSWEPs: OnLanguageChanged")

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

-- Inkling playermodels hull change fix
if not isfunction(FindMetaTable "Player".SplatoonOffsets) then return end
CreateConVar("splt_Colors", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Toggles skin/eye colors on Splatoon playermodels.")
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
