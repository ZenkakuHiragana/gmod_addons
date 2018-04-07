
--Shared library
local ss = SplatoonSWEPs
if not ss then return end
include "const.lua"
include "movement.lua"
include "sound.lua"
include "text.lua"
include "weapons.lua"

ss.AreaBound = ss.AreaBound or 0
ss.AspectSum = ss.AspectSum or 0
ss.AspectSumX = ss.AspectSumX or 0
ss.AspectSumY = ss.AspectSumY or 0
ss.Displacements = ss.Displacements or {}
cleanup.Register(ss.CleanupTypeInk)
function ss:MinVector(a, b)
	local c = Vector()
	c.x = math.min(a.x, b.x)
	c.y = math.min(a.y, b.y)
	c.z = math.min(a.z, b.z)
	return c
end

function ss:MaxVector(a, b)
	local c = Vector()
	c.x = math.max(a.x, b.x)
	c.y = math.max(a.y, b.y)
	c.z = math.max(a.z, b.z)
	return c
end

--number miminum boundary size, table of Vectors
--returning AABB(mins, maxs)
function ss:GetBoundingBox(vectors, minbound)
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	local bound = self.vector_one * (minbound or 0)
	for _, v in ipairs(vectors) do
		mins = self:MinVector(mins, v - bound)
		maxs = self:MaxVector(maxs, v + bound)
	end
	return mins, maxs
end

--Vector AABB1(mins, maxs), Vector AABB2(mins, maxs) in world coordinates
--returning boolean, whether or not two AABBs intersect together
function ss:CollisionAABB(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y and
			mins1.z < maxs2.z and maxs1.z > mins2.z
end

--Vector AABB1(mins, maxs), Vector AABB2(mins, maxs) in world coordinates
--returning boolean, whether or not two AABBs intersect together
function ss:CollisionAABB2D(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y
end

--Vector(x, y, z), Vector new system origin, Angle new system angle
--returning localized Vector(x, y, 0)
function ss:To2D(source, orgpos, organg)
	local localpos = WorldToLocal(source, angle_zero, orgpos, organg)
	return Vector(localpos.y, localpos.z, 0)
end

--Vector(x, y, 0), Vector system origin in world coordinates, Angle system angle
--returning Vector(x, y, z)
function ss:To3D(source, orgpos, organg)
	local localpos = Vector(0, source.x, source.y)
	return (LocalToWorld(localpos, angle_zero, orgpos, organg))
end

function ss:AddTimerFramework(ent)
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

	function ent:AddNetworkSchedule(delay, func)
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

	function ent:ProcessSchedules()
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

function ss:AddNetworkVar(ent)
	ent.NetworkSlot = {
		String = -1, Bool = -1, Float = -1, Int = -1,
		Vector = -1, Angle = -1, Entity = -1,
	}
	
	function ent:GetLastSlot(typeof) return self.NetworkSlot[typeof] end
	function ent:AddNetworkVar(typeof, name)
		assert(self.NetworkSlot[typeof] < 31, "SplatoonSWEPs: Tried to use too many network vars!")
		self.NetworkSlot[typeof] = self.NetworkSlot[typeof] + 1
		self:NetworkVar(typeof, self.NetworkSlot[typeof], name)
		return self.NetworkSlot[typeof]
	end
end

function ss:IsValidInkling(ply)
	if not (IsValid(ply) and isfunction(ply.GetActiveWeapon)) then return end
	local weapon = ply:GetActiveWeapon()
	return IsValid(weapon) and weapon.IsSplatoonWeapon and not weapon:GetHolstering() and weapon or nil
end

function ss:CheckFence(ent, pos, endpos, filter, mins, maxs)
	local t = {
		start = pos, endpos = endpos,
		mins = mins, maxs = maxs,
		filter = filter,
		mask = MASK_SHOT_PORTAL,
	}
	
	t.mins = mins
	if not util.TraceHull(t).Hit then
		t.mask = MASK_SOLID
		local tr = util.TraceHull(t)
		if tr.Hit and tr.Entity ~= NULL then
			return tr.Entity
		end
	end
end

--MOUSE1+LCtrl makes crouch, LCtrl+MOUSE1 makes primary attack.
hook.Add("KeyPress", "SplattonSWEPs: Detect controls", function(ply, button)
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local attack = bit.band(button, IN_ATTACK) ~= 0
	local duck = bit.band(button, IN_DUCK) ~= 0
	w.IsAttackDown = w.IsAttackDown or attack
	w.CrouchPriority = w.CrouchPriority or w.IsAttackDown and duck
end)
hook.Add("KeyRelease", "SplatoonSWEPs: Detect controls", function(ply, button)
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local attack = bit.band(button, IN_ATTACK) ~= 0
	local duck = bit.band(button, IN_DUCK) ~= 0
	w.IsAttackDown = w.IsAttackDown and not attack
	w.CrouchPriority = w.CrouchPriority and not (attack or duck)
end)

--Prevent crouching after firing.
hook.Add("SetupMove", "SplatoonSWEPs: Prevent owner from crouch", function(ply, mv, cm)
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local c = mv:KeyDown(IN_DUCK)
	w.EnemyInkPreventCrouching = w.EnemyInkPreventCrouching and c and w:GetOnEnemyInk()
	if (not w.CrouchPriority and c and mv:KeyDown(IN_ATTACK))
	or CurTime() < w:GetNextCrouchTime() or w.EnemyInkPreventCrouching then
		mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_DUCK)))
		cm:RemoveKey(IN_DUCK)
	end
end)

--Overriding footstep sound stops calling other addons' PlayerFootstep hook.
--I decide to replace one of their hook with my function built.
local FootstepTrace = vector_up * -20
local hostkey, hostfunc, multisteps = hostkey, hostfunc, multisteps
for k, v in pairs(hook.GetTable().PlayerFootstep or {}) do
	if hostkey and hostfunc then multisteps = true break end
	if isstring(k) then hostkey, hostfunc = k, v end
end

local function PlayerFootstep(ply, pos, foot, sound, volume, filter)
	if not (IsValid(ply) and isfunction(ply.GetActiveWeapon)) then return end
	local weapon = ply:GetActiveWeapon()
	local IsSplatoonWeapon = IsValid(weapon) and weapon.IsSplatoonWeapon and not weapon:GetHolstering()
	if ((IsSplatoonWeapon and weapon:GetGroundColor() >= 0) or (SERVER and
	ss:GetSurfaceColor(util.QuickTrace(ply:GetPos(), FootstepTrace, ply)))) then
		if not (IsSplatoonWeapon and weapon:GetInInk()) and (SERVER or ply ~= LocalPlayer()) then
			ply:EmitSound "SplatoonSWEPs_Player.InkFootstep"
		end
		return true
	end
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
else
	hook.Add("PlayerFootstep", "SplatoonSWEPs: Ink footstep", PlayerFootstep)
end

--Inklings with the same ink color will not collide
local bound = ss.vector_one * 5
hook.Add("ShouldCollide", "SplatoonSWEPs: Ink go through fences", function(ent1, ent2)
	local w1, w2 = ss:IsValidInkling(ent1), ss:IsValidInkling(ent2)
	if w1 and w2 then return w1:GetInkColorProxy() ~= w2:GetInkColorProxy() end
end)

hook.Add("PhysgunPickup", "SplatoonSWEPs: Ink cannot be grabbed", function(ply, ent)
	if ent.IsSplatoonProjectile then return false end
end)

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
	local weaponlist = list.GetForEdit "Weapon"
	for i, c in ipairs(ss.WeaponClassNames) do
		for _, weapon in ipairs {weapons.GetStored(c), weaponlist[c]} do
			weapon.Category = ss.Text.Category
			weapon.PrintName = ss.Text.PrintNames[c]
			weapon.Spawnable = true
			weapon.Slot = weaponslot[weapon.Base] or 0
			weapon.SlotPos = i
			if CLIENT then
				local icon = "entities/" .. c
				if not file.Exists("materials/" .. icon .. ".vmt", "GAME") then icon = "weapons/swep" end
				weapon.WepSelectIcon = surface.GetTextureID(icon)
			end
		end
		
		if weapons.Get(c) then
			list.Add("NPCUsableWeapons", {class = c, title = ss.Text.PrintNames[c]})
		end
	end
end)

if not isfunction(FindMetaTable "Player".SplatoonOffsets) then return end
if SERVER then
	hook.Remove("KeyPress", "splt_KeyPress")
	hook.Remove("PlayerSpawn", "splt_Spawn")
	hook.Remove("PlayerDeath", "splt_OnDeath")
else
	hook.Remove("Tick", "splt_Offsets_cl")
end

ss.CheckSplatoonPlayermodels = {
	["models/drlilrobot/splatoon/ply/marie.mdl"] = true,
	["models/drlilrobot/splatoon/ply/callie.mdl"] = true,
	["models/drlilrobot/splatoon/ply/inkling_boy.mdl"] = true,
	["models/drlilrobot/splatoon/ply/inkling_girl.mdl"] = true,
	["models/drlilrobot/splatoon/ply/octoling.mdl"] = true,
}

hook.Add("PlayerSpawn", "SplatoonSWEPs: Fix PM change", function(ply)
	ply.IsSplatoonPlayermodel = nil
end)
hook.Add("Tick", "SplatoonSWEPs: Fix playermodel hull change", function()
	for _, p in ipairs(player.GetAll()) do
		local is = ss.CheckSplatoonPlayermodels[p:GetModel()]
		if is and p.IsSplatoonPlayermodel ~= true and GetConVar "splt_EditScale":GetInt() == 1 then
			p:SetViewOffset(Vector(0, 0, 42))
			p:SetViewOffsetDucked(Vector(0, 0, 28))
			p:SetHull(Vector(-13, -13, 0), Vector(13, 13, 53))
			p:SetHullDuck(Vector(-13, -13, 0), Vector(13, 13, 33))
			p.IsSplatoonPlayermodel = true
		elseif not is and p.IsSplatoonPlayermodel ~= false then
			p:DefaultOffsets()
			p.IsSplatoonPlayermodel = false
		end
	end
end)
