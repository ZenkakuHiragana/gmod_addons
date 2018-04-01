
--Shared library
local ss = SplatoonSWEPs
if not ss then return end
include "const.lua"
include "sound.lua"
include "text.lua"
include "weapons.lua"
include "npcusableweapons.lua"
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
		mins = mins - vector_up * .01, maxs = maxs,
		filter = filter,
		mask = MASK_SHOT_PORTAL,
	}
	
	t.mins = mins
	if not util.TraceHull(t).Hit then
		t.mask = MASK_SOLID
		local tr = util.TraceHull(t)
		if tr.Hit then
			return ent:OnGround() and ent:GetGroundEntity() or tr.Entity
		end
	end
end

--MOUSE1+LCtrl makes crouch, LCtrl+MOUSE1 makes primary attack.
hook.Add("KeyPress", "SplattonSWEPs: Detect controls", function(ply, button)
	local weapon = ss:IsValidInkling(ply)
	if not weapon then return end
	if button == IN_ATTACK then weapon.IsAttackDown = true end
	if weapon.IsAttackDown and button == IN_DUCK then weapon.CrouchPriority = true end
end)
hook.Add("KeyRelease", "SplatoonSWEPs: Detect controls", function(ply, button)
	local weapon = ss:IsValidInkling(ply)
	if not weapon then return end
	if button == IN_ATTACK then weapon.IsAttackDown = false end
	if button == IN_ATTACK or button == IN_DUCK then weapon.CrouchPriority = false end
end)

--Prevent crouching after firing.
hook.Add("SetupMove", "SplatoonSWEPs: Prevent owner from crouch", function(ply, mvd)
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local c = mvd:KeyDown(IN_DUCK)
	w.EnemyInkPreventCrouching = w.EnemyInkPreventCrouching and c and w:GetOnEnemyInk()
	if (not w.CrouchPriority and c and mvd:KeyDown(IN_ATTACK))
	or CurTime() < w:GetNextCrouchTime() or w.EnemyInkPreventCrouching then
		mvd:SetButtons(bit.band(mvd:GetButtons(), bit.bnot(IN_DUCK)))
	end
end)

local WALLCLIMB_KEYS = bit.bor(IN_JUMP, IN_FORWARD, IN_BACK)
local LIMIT_Z_DEG = math.cos(math.rad(180 - 30))
hook.Add("Move", "SplatoonSWEPs: Squid's movement", function(ply, mv)
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local maxspeed = mv:GetMaxSpeed() * (w.IsDisruptored and ss.DisruptoredSpeed or 1)
	local v = mv:GetVelocity() --Current velocity
	local speed = v:Length2D() --Horizontal speed
	local vz = v.z v.z = 0
	if w:GetInWallInk() and mv:KeyDown(WALLCLIMB_KEYS) then
		vz = math.max(math.abs(vz) * -.75, vz + math.min(
		12 + (mv:KeyPressed(IN_JUMP) and maxspeed / 4 or 0), maxspeed))
		if ply:OnGround() and (ply:GetEyeTraceNoCursor().Fraction
			< util.TraceLine(util.GetPlayerTrace(ply, -ply:GetAimVector())).Fraction)
			== mv:KeyDown(IN_FORWARD) then
			mv:AddKey(IN_JUMP)
		end
	end --Wall climbing
	
	if speed > maxspeed then --Limits horizontal speed
		v = v * maxspeed / speed
		speed = math.min(speed, maxspeed)
	end
	
	if w.OnOutOfInk then --Prevent wall-climb jump
		vz = math.min(vz, maxspeed * .8)
		w.OnOutOfInk = false
	end
	
	mv:SetVelocity(Vector(v.x, v.y, vz))
	if not w.IsSquid then return end --Squids can go through fences
	local friction = GetConVar "sv_friction":GetFloat()
	local accel = GetConVar(ply:OnGround() and
		"sv_accelerate" or "sv_airaccelerate"):GetFloat()
	local gravity = GetConVar "sv_gravity":GetFloat() * FrameTime()
	local direction = mv:GetMoveAngles()
	direction.p = 0 --Add X, Y component
	direction = direction:Forward() * mv:GetForwardSpeed()
			  + direction:Right() * mv:GetSideSpeed()
	direction = accel * direction * 1e-4 * maxspeed * FrameTime()
	v = v * math.max(0, 1 - friction / speed) + direction
	
	speed = v:Length()
	if speed > maxspeed then --X, Y speed cap
		v = v * maxspeed / speed
		speed = math.min(speed, maxspeed)
	end
	
	v.z = vz - gravity + (ply:OnGround() and --Z component
	mv:KeyPressed(IN_JUMP) and ply:GetJumpPower() or 0)
	
	local oldpos = mv:GetOrigin()
	local filter = {ply, w}
	local mins, maxs = ply:GetHullDuck()
	local t = {
		start = oldpos, endpos = oldpos + (v + ply:GetBaseVelocity()) * FrameTime(),
		mins = mins, maxs = maxs, filter = filter, mask = MASK_SHOT_PORTAL,
	}
	
	local onground, groundent = -1
	for i = 1, 4 do
		local tr = util.TraceHull(t)
		if not tr.Hit then break end
		local pull = tr.HitNormal * tr.HitNormal:Dot(tr.HitPos - t.endpos)
		local solidvec = t.endpos + pull - tr.HitPos
		solidvec:Normalize()
		v = solidvec * solidvec:Dot(v)
		t.endpos = t.endpos + pull
		if tr.HitNormal.z > onground then
			onground = tr.HitNormal.z
			groundent = tr.Entity
		end
	end
	local fence = ss:CheckFence(ply, oldpos, t.endpos, filter, mins, maxs)
	if CLIENT then
		debugoverlay.Box(oldpos, mins, maxs, .05, Color(0, 255, 0, 64))
		debugoverlay.Box(t.endpos, mins, maxs, .05, Color(0, 0, 255, 64))
		debugoverlay.Text(t.endpos, tostring(fence))
	end
	if fence then
		ply:SetMoveType(MOVETYPE_NOCLIP)
	elseif w.InFence and ply:GetMoveType() == MOVETYPE_NOCLIP then
		ply:SetMoveType(MOVETYPE_WALK)
	end
	
	w.InFence = tobool(fence)
	if not fence then return end --Player is in fence, then apply
	if onground < .70710678 then
		ply:SetGroundEntity()
		ply:RemoveFlags(FL_ONGROUND) --Can land on up to 45 deg slope
	else
		ply:SetGroundEntity(groundent)
		ply:AddFlags(FL_ONGROUND)
	end
	
	mv:SetVelocity(v)
	mv:SetOrigin(t.endpos)
	return true
end)

hook.Add("PlayerNoClip", "SplatoonSWEPs: Through fence", function(ply, desired)
	local w = ss:IsValidInkling(ply)
	if not (desired and w and w.IsSquid) then return end
	w.InFence = false
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
				local icon = "vgui/entities/" .. c
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
