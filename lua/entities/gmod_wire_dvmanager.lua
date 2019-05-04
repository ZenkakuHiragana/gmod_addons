
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

if not WireAddons then return end
AddCSLuaFile()
DEFINE_BASECLASS "base_wire_entity"
ENT.WireDebugName = "[DV] Waypoint Manager"
ENT.PrintName = "[DV] Waypoint Manager"
ENT.Author = "∩(≡＾ω＾≡)∩"
ENT.IsDVWireManager = true

local dvd = DecentVehicleDestination
function ENT:OnRemove()
	dvd.WireManagers[self] = nil
end

if CLIENT then
	function ENT:Initialize()
		dvd.WireManagers[self] = true
	end

	return
end

local IOList = {
	"Group #",
	"Is fuel station",
	"Speed limit",
	"Use turn lights",
	"Wait time",
}
function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:DrawShadow(false)
	self:SetNWInt("WaypointID", -1)
	self.Inputs = Wire_CreateInputs(self, IOList)
	self.Outputs = Wire_CreateOutputs(self, IOList)
	dvd.WireManagers[self] = true
end

function ENT:LinkEnt(e)
	if not isnumber(e) then return false end
	local w = dvd.Waypoints[e]
	if not w then return false end
	self:SetNWInt("WaypointID", e)
	self.waypointid = e
	self:ShowOutput()
	return true
end

function ENT:UnlinkEnt()
	self:SetNWInt("WaypointID", -1)
	self.waypointid = nil
	self:ShowOutput()
end

function ENT:Setup(waypointid)
	self:ShowOutput()
	if not isnumber(waypointid) then return end
	self.waypointid = waypointid
	self:SetNWInt("WaypointID", waypointid)
end

function ENT:OnRestore()
	self.BaseClass.OnRestore(self)
	self:SetNWInt("WaypointID", self.waypointid)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	local id = self:GetNWInt "WaypointID"
	if not isnumber(id) or id < 0 then return end
	local w = dvd.Waypoints[id]
	if not w then return end
	if iname == "Group #" then
		w.Group = math.floor(value)
	elseif iname == "Is fuel station" then
		w.FuelStation = value == 1
	elseif iname == "Speed limit" then
		w.SpeedLimit = value * dvd.KmphToHUps
	elseif iname == "Use turn lights" then
		w.UseTurnLights = value == 1
	elseif iname == "Wait time" then
		w.WaitUntilNext = value
	else
		return
	end

	self:ShowOutput()
	if player.GetCount() == 0 then return end
	net.Start "Decent Vehicle: Send waypoint info"
	net.WriteUInt(id, 24)
	net.WriteUInt(w.Group, 16)
	net.WriteFloat(w.SpeedLimit)
	net.WriteFloat(w.WaitUntilNext)
	net.WriteBool(w.UseTurnLights)
	net.WriteBool(w.FuelStation)
	net.Broadcast()
end

local Output = [[Linked to: #%d
Group = %d
Is fuel station = %s
Speed limit = %.2f km/s
Use turn lights = %s
Wait time = %.2f sec.]]
function ENT:ShowOutput()
	local i = self:GetNWInt "WaypointID"
	if not isnumber(i) or i < 0 then
		self:SetOverlayText "Not linked yet"
		return
	end

	local w = dvd.Waypoints[i]
	if not w then
		self:SetOverlayText "Linked to an invalid waypoint"
		return
	end

	self:SetOverlayText(Output:format(i, w.Group, tostring(w.FuelStation), w.SpeedLimit / dvd.KmphToHUps, tostring(w.UseTurnLights), w.WaitUntilNext))
	Wire_TriggerOutput(self, "Group #", w.Group)
	Wire_TriggerOutput(self, "Is fuel station", w.FuelStation)
	Wire_TriggerOutput(self, "Speed limit", w.SpeedLimit / dvd.KmphToHUps)
	Wire_TriggerOutput(self, "Use turn lights", w.UseTurnLights)
	Wire_TriggerOutput(self, "Wait time", w.WaitUntilNext)
end

duplicator.RegisterEntityClass("gmod_wire_dvmanager", WireLib.MakeWireEnt, "Data", "waypointid")

