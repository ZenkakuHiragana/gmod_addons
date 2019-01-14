
local dvd = DecentVehicleDestination
if not dvd then return end
dvd.DVPolice_WantedTable = {} -- global table of wanted vehicles

AddCSLuaFile()
ENT.Base = "npc_decentvehicle"
ENT.PrintName = dvd.Texts.npc_dvpolice
ENT.DV_Police = true -- Adding your identifier will be good.
ENT.Model = {
	"models/player/police.mdl",
	"models/player/police_fem.mdl",
}
ENT.Preference = { -- Some preferences for the behavior of the base AI.
    DoTrace = true, -- Whether or not it does some traces
    GiveWay = true, -- Whether or not it gives way for vehicles with ELS
    GiveWayTime = 5, -- Time to reset the offset for giving way
    GobackDuration = 0.7, -- Duration of going back on stuck
    GobackTime = 10, -- Time to start going back on stuck
    LockVehicle = true, -- Whether or not it allows other players to get in
    LockVehicleDependsOnCVar = false, -- Whether or not LockVehicle depends on CVar
    ShouldGoback = true, -- Whether or not it should go backward on stuck
    StopAtTL = true, -- Whether or not it stops at traffic lights with red sign
    StopEmergency = true, -- Whether or not it stops on crash
    StopEmergencyDuration = 5, -- Duration of stopping on crash
    StopEmergencyDurationDependsOnCVar = true, -- Same as LockVehicle, but for StopEmergencyDuration
    TraceMaxBound = 64, -- Maximum hull size of trace: max = Vector(1, 1, 1) * this value, min = -max
    TraceMinLength = 200, -- Minimum trace length in hammer units
    WaitUntilNext = true, -- Whether or not it waits on WaitUntilNext
}

list.Set("NPC", "npc_dvpolice", {
	Name = ENT.PrintName,
	Class = "npc_dvpolice",
	Category = "GreatZenkakuMan's NPCs",
})

if CLIENT then return end
local color_green = Color(0, 255, 0)
local ChangeCode = dvd.CVars.Police.ChangeCode

--[[ 
arguments:
1: Entity ent - entity to check
2: boolean turn(optional) - if true, then generate new waypoint and generate new route, else only generate new route
]]
function ENT:DVPolice_GenerateWaypoint(ent, turn)
	turn = turn or false
	assert(IsEntity(ent), string.format("Entity expected, got %s.", tostring(ent)))
	assert(isbool(turn), string.format("Bool expected, got %s.", tostring(turn)))
	
	local move_ok = self:GetMoveDirection(ent)
	local is_opposite, foundwp, wpside, back, neighbor = self:GetOppositeLine()
	local tg_nearest =  dvd.GetNearestWaypoint(ent:GetPos())
	if move_ok or turn then -- if moving towards us
		if tg_nearest == foundwp then
			self.Waypoint = foundwp
		elseif tg_nearest == neighbor then
			self.Waypoint = neighbor
		else
			self.Waypoint = neighbor
		end
		
		debugoverlay.Sphere(self.Waypoint.Target, 50, 1, color_green, true)
	end
	
	if not table.HasValue(self.WaypointList,tg_nearest) then
		table.insert(self.WaypointList, tg_nearest)
		debugoverlay.Sphere(tg_nearest.Target, 30, 1, color_green, true)
	end

	timer.Simple(.2, function() -- idk why, but first it need to wait before get route
		if not self.PreferencesSetUpped then
			self.Preference.StopAtTL = false -- don't stop at traffic light
			self.Preference.GiveWay = false -- don't give way
			self.Preference.StopEmergency = false -- don't stop after crash
			self.Preference.WaitUntilNext = false -- don't stop at specefid waypoints

			table.insert(dvd.DVPolice_WantedTable, self.DVPolice_LastTarget)
			self.PreferencesSetUpped = true
		end
		
		if not self:GetELS() then 
			self.DVPolice_Code = 1
			self:SetELS(true) -- set ELS on

			if self.v:GetClass() == "prop_vehicle_jeep"
			and VC and isfunction(VC.ELS_Lht_SetCode) then
				VC.ELS_Lht_SetCode(self.v, nil, nil, 1)
			end
		end
		
		if not self:GetELSSound() then
			self.DVPolice_Code = 1
			self:SetELSSound(true) -- and set ELS sound on
			if self.v:GetClass() == "prop_vehicle_jeep"
			and VC and isfunction(VC.ELS_Snd_SetCode) then
				VC.ELS_Snd_SetCode(self.v, nil, nil, 1)
			end
		end
		
		hook.Run("Decent Police: Chasing", self, ent)
	end)
end

function ENT:GetCurrentMaxSpeed()
	local limit = self.Waypoint.SpeedLimit
	self.Waypoint.SpeedLimit = limit * 10
	local base = self.BaseClass.GetCurrentMaxSpeed(self)
	self.Waypoint.SpeedLimit = limit
	
	return base
end

function ENT:TargetStopped()
	if not IsValid(self.DVPolice_Target) then return end
	local speed = math.Round(self.DVPolice_Target:GetVelocity():Length() * 0.09144, 0)
	return speed < 0.5
end

function ENT:ShouldStop()
	if IsValid(self.DVPolice_Target) and self.Trace.Entity == self.DVPolice_Target then -- if target in trace
		local speed = math.Round(self.DVPolice_Target:GetVelocity():Length() * 0.09144, 0)
		if self.DVPolice_Code and self.DVPolice_Code >= 2 and not self:TargetStopped() then -- if chase code 2 and target not stopped
			-- aka, do PIT maneuver
			return false
		elseif self:TargetStopped() then
			self:SetELSSound(false)
			if not self.ChangedCode and VC
			and isfunction(VC.ELS_Lht_SetCode) then
				if dvd.DriveSide == dvd.DRIVESIDE_RIGHT then -- if drive side right
					VC.ELS_Lht_SetCode(self.v, nil, nil, 10)
				else
					VC.ELS_Lht_SetCode(self.v, nil, nil, 12)
				end
				self.DVPolice_ChangedCode = true
			end
			
			self.StopByTrace = 0
			timer.Simple(math.random(10, 20), function()
				table.RemoveByValue(dvd.DVPolice_WantedTable, self.DVPolice_Target) 
				self.DVPolice_Target = nil
			end)
			
			return true
		end
	end
	
	if self.StopHere then
		if dvd.GetNearestWaypoint(self:GetPos()) == self.StopHere then
			return true
		end
	end
	
	return self.BaseClass.ShouldStop(self)
end

--[[
Determines is line in left/right(depends of driving side) = opposite line

retruns - boolean is opposite, if not exsits neighbor then returns nil
table foundwp - waypoint with that was checked
Vector wpside - position from what was checked
Vector back - position from what was 100% checked
table neighbor - foundwp's neighbor that was used for checking too
]]
function ENT:GetOppositeLine()
	local is_opposite = false

	local wpside
	local foundwp

	if dvd.DriveSide == dvd.DRIVESIDE_RIGHT then -- if drive side right
		wpside = self:LocalToWorld(Vector(0, 250, 0), Angle(0, 0, 0))
	else
		wpside = self:LocalToWorld(Vector(0, -300, 0), Angle(0, 0, 0))
	end

	foundwp = dvd.GetNearestWaypoint(wpside)
	local back = self:LocalToWorld(Vector(-400, 0, 0), Angle(0, 0, 0))
	debugoverlay.Line(self.v:GetPos(), wpside, .05, Color(0, 0, 255), true)
	debugoverlay.Line(self.v:GetPos(), back, .05, Color(0, 0, 255), true)
	debugoverlay.Sphere(foundwp.Target, 64, .1, Color(0, 0, 255, 100), true)
	if foundwp.Neighbors[1] then
		debugoverlay.Sphere(dvd.Waypoints[foundwp.Neighbors[1]].Target, 54, .5, Color(255, 0, 0, 100), true)
		
		local neighbor = dvd.Waypoints[foundwp.Neighbors[1]]
		is_opposite = neighbor.Target:Distance(back) < foundwp.Target:Distance(back)
		return is_opposite, foundwp, wpside, back, neighbor
	else
		return nil
	end
end

function ENT:CarCollide(data)
	if data.Speed < 200 or not data.HitEntity:IsVehicle() then return end
	local TimeToStopEmergency = GetConVar "decentvehicle_timetostopemergency"
	self.Emergency = CurTime() + (self.EmergencyDuration or TimeToStopEmergency:GetFloat())
end

--[[
Determines move direction of given entity

arguments:
1: Entity ent - entity to check

returns: 
1: boolean - true - driving on it's lane, false - driving on the opposite lane, nil - no vehicle
]]

function ENT:GetMoveDirection(ent)
	assert(IsEntity(ent), string.format("Entity expected, got %s.", tostring(ent)))
	assert(ent:IsVehicle(), string.format("Trying call 'GetMoveDirection' to not vehicle. Got: %s.", tostring(ent)))
	assert(ent:GetClass() ~= "prop_vehicle_prisoner_pod", string.format("Trying call 'GetMoveDirection' to seat. Got: %s.", tostring(ent)))
	local is_opposite, foundedwp, lookside, lookback, neighbor = self:GetOppositeLine()
	local move_ok, attposf, attposr
	if ent.IsSimfphyscar then
		if not ent.CustomWheels then
			attposf = ent:GetAttachment(ent:LookupAttachment "wheel_fl").Pos
			attposr = ent:GetAttachment(ent:LookupAttachment "wheel_rl").Pos
		else
			local wheels = ent.Wheels
			attposf = wheels[1]:GetPos()
			attposr = wheels[3]:GetPos()
		end
	elseif ent.IsScar then
		local wheels = ent.Wheels
		attposf = wheels[1]:GetPos()
		attposr = wheels[3]:GetPos()
	elseif ent:GetClass() == "prop_vehicle_jeep" then
		attposf = ent:GetAttachment(ent:LookupAttachment "wheel_fl").Pos
		attposr = ent:GetAttachment(ent:LookupAttachment "wheel_rl").Pos
	end
	
	if is_opposite then
		for k, v in pairs(ents.FindInSphere(lookside, 175)) do
			debugoverlay.Sphere(lookside, 175, .1, Color(200, 10, 255, 1), true)
			if v ~= ent then continue end
			move_ok = attposf:Distance(neighbor.Target) < attposr:Distance(neighbor.Target)
		end
	end
	
	return move_ok
end

function ENT:IsTargetInBack(ent)
	if not ent then return end -- is located in back
	return self:GetVehicleForward():Dot(ent:GetPos() - self.v:WorldSpaceCenter()) < 0
end

function ENT:Think()
	if self.DVPolice_Target and self:TargetStopped() and self.Trace.Entity == self.DVPolice_Target then
		self.Waypoint = dvd.GetNearestWaypoint(self.DVPolice_Target:GetPos())
	end
	
	if not self.v.ELSCycleChanged then -- for VCMod
		self.v.ELSCycleChanged = true
		if self.v:GetClass() == "prop_vehicle_jeep" and VC
		and isfunction(self.v.VC_setELSLightsCycle)
		and isfunction(VC.ELS_Lht_SetCode)
		and isfunction(VC.ELS_Snd_SetCode) then
			VC.ELS_Lht_SetCode(self.v, nil, nil, 1)
			VC.ELS_Snd_SetCode(self.v, nil, nil, 1)
			self.DVPolice_Code = 1
			self:SetELS(false)
			self:SetELSSound(false)
 		end
	end
	
	if not IsValid(self.DVPolice_Target) then -- if we don't have target
		if not self.Waypoint then
			self.WaypointList = {}
			self.NextWaypoint = nil
			self:FindFirstWaypoint()
		end
		
		if self:GetELS() then -- and ELS enabled
			self.WaypointList = {}
			self.NextWaypoint = nil
			self:FindFirstWaypoint()
			self:SetELS(false) -- then disable it
			self:SetELSSound(false) -- and it
			self.Preference.StopAtTL = true -- again be polite
			self.Preference.GiveWay = true -- very polite
			self.Preference.StopEmergency = true -- so damn polite stop after crash
			self.Preference.WaitUntilNext = true -- you so.fuckin.precios.when you. stop at specefid waypoints
			self.PreferencesSetUpped = false
			if self.v:GetClass() == "prop_vehicle_jeep" and VC
			and isfunction(self.v.VC_setELSLightsCycle)
			and isfunction(VC.ELS_Lht_SetCode)
			and isfunction(VC.ELS_Snd_SetCode) then
				VC.ELS_Lht_SetCode(self.v, nil, nil, 1)
				VC.ELS_Snd_SetCode(self.v, nil, nil, 1)
				self.DVPolice_Code = 1
				self:SetELS(false)
				self:SetELSSound(false)
				self.v.ELSCycleChanged = true
	 		end
			
			hook.Run("Decent Police: Calmed", self)
		end
	elseif not IsValid(self.DVPolice_Target) then -- "wh9t the g0in on wh3r3 is m9 t9rg3t" (if target not is valid)
		self.DVPolice_Target = nil -- "ak th3n n3v3r mind" (forgot it)
		self:FindFirstWaypoint()
		hook.Run("Decent Police: Reset Target", self)
	elseif self:GetPos():DistToSqr(self.DVPolice_Target:GetPos()) > 36000000 then -- If target too far
		self.DVPolice_LastTarget = self.DVPolice_Target -- don't chase anymore, but remember this guy
		hook.Run("Decent Police: Added wanted list", self, self.DVPolice_Target)
		local route = dvd.GetRouteVector(self.v:GetPos(), self.DVPolice_Target:GetPos(), self.Group)

		if route then
			self.WaypointList = route -- go to the last known pos
		else
			self:FindFirstWaypoint()
		end
		
		if self.v:GetClass() == "prop_vehicle_jeep"
		and VC and not self:TargetStopped()
		and isfunction(VC.ELS_Lht_SetCode)
		and isfunction(VC.ELS_Snd_SetCode) then
			VC.ELS_Lht_SetCode(self.v, nil, nil, 1) -- change code
			VC.ELS_Snd_SetCode(self.v, nil, nil, 1) -- change code
			self.DVPolice_Code = 1
		end
		
		self.DVPolice_Target = nil -- and clean up target
	else
		local tg_speed = math.Round(self.DVPolice_Target:GetVelocity():Length() * 0.09144, 0)
		if not self:TargetStopped() then
			self:DVPolice_GenerateWaypoint(self.DVPolice_Target, self:IsTargetInBack(self.DVPolice_Target))
		end

		timer.Simple(ChangeCode:GetInt(), function() -- if chasing for 2 mins
			if IsValid(self) and not self:TargetStopped() and
			(self.DVPolice_Target == self.DVPolice_LastTarget
			or not self.DVPolice_LastTarget and self.DVPolice_Target) then
				if self.v:GetClass() == "prop_vehicle_jeep" and VC
				and isfunction(VC.ELS_Lht_SetCode)
				and isfunction(VC.ELS_Snd_SetCode) then
					VC.ELS_Lht_SetCode(self.v, nil, nil, 2) -- change code
					VC.ELS_Snd_SetCode(self.v, nil, nil, 2) -- change code
					self.DVPolice_Code = 2
				end
			end
		end)
	end
	
	for k, ent in pairs(ents.FindInSphere(self.v:GetPos(), 800)) do
		if self.DVPolice_Target or self:TargetStopped() then continue end 
		if not ent:IsVehicle() then continue end
		if ent:GetClass() == "prop_vehicle_prisoner_pod" then continue end
		if ent == self.v then continue end
		if self:IsTargetInBack(ent) then continue end -- don't look back
		
		hook.Run("Decent Police: Detected vehicle", self, ent)
		debugoverlay.Line(self:GetPos(), ent:GetPos(), .1, Color(0, 0, 255))
		
		for k, wanted in pairs(dvd.DVPolice_WantedTable) do -- bad idea
			if ent ~= wanted then continue end
			self.DVPolice_Target = ent
			hook.Run("Decent Police: Detected wanted vehicle", self, ent)
			self:DVPolice_GenerateWaypoint(ent, false)
		end
		
		if math.Round(dvd.GetNearestWaypoint(self.v:GetPos()).SpeedLimit * 0.09144) + 20 < math.Round(ent:GetVelocity():Length() * 0.09144) then
			self.DVPolice_Target = ent
			self:DVPolice_GenerateWaypoint(ent, false)
		end
	end
	
	return self.BaseClass.Think(self)
end
