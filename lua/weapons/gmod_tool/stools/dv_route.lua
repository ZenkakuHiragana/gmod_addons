
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

TOOL.Category = "GreatZenkakuMan's tools"
TOOL.Name = "Decent Vehicle Waypoint Tool"
TOOL.Information = {
	{name = "info", stage = 0},
	{name = "left", stage = 0},
	{name = "left_1", stage = 1},
	{name = "right"},
}

TOOL.WaypointID = -1
TOOL.ClientConVar["bidirectional"] = 0
TOOL.ClientConVar["fuel"] = 0
TOOL.ClientConVar["group"] = 0
TOOL.ClientConVar["shouldblink"] = 0
TOOL.ClientConVar["showpoints"] = 1
TOOL.ClientConVar["speed"] = 40
TOOL.ClientConVar["wait"] = 0

TOOL.ClientConVar["showupdates"] = 1

if CLIENT then
	language.Add("tool.dv_route.name", "Decent Vehicle route maker")
	language.Add("tool.dv_route.desc", "Create your own routes for vehicles!")
	language.Add("tool.dv_route.0", "Select a waypoint or a traffic light to link.  Select a vehicle driven by a Decent Vehicle to assign its waypoint group.")
	language.Add("tool.dv_route.left", "Left click to create a new waypoint.")
	language.Add("tool.dv_route.left_1", "Select another waypoint you want to link to.  Select the same waypoint to remove it.")
	language.Add("tool.dv_route.load", "Restore waypoints")
	language.Add("tool.dv_route.right", "Update waypoint.")
	
	language.Add("tool.dv_route.bidirectional", "Bi-directional link")
	language.Add("tool.dv_route.bidirectional.help", "Connect bi-directional link automatically.")
	language.Add("tool.dv_route.fuel", "Fuel station")
	language.Add("tool.dv_route.fuel.help", "Decent Vehicles will go here to refuel its car.")
	language.Add("tool.dv_route.group", "Waypoint group")
	language.Add("tool.dv_route.group.help", 
	[[You can force Decent Vehicles to run along specified group of waypoints.
	0 means all vehicles can go there.]])
	language.Add("tool.dv_route.save", "Save waypoints")
	language.Add("tool.dv_route.shouldblink", "Use turn signals")
	language.Add("tool.dv_route.shouldblink.help", "Decent Vehicles will use turn signals when they go to the waypoint.")
	language.Add("tool.dv_route.showpoints", "Draw waypoints")
	language.Add("tool.dv_route.showupdates", "Notify the latest updates")
	language.Add("tool.dv_route.showupdates.help", "Some notifications are shown when this addon is updated.")
	language.Add("tool.dv_route.speed", "Max speed [km/h]")
	language.Add("tool.dv_route.wait", "Wait time [seconds]")
	language.Add("tool.dv_route.wait.help", "After Decent Vehicles reached the waypoint, they wait for this seconds.")
end

local KmphToHUps = 1000 * 3.2808399 * 16 / 3600
local dvd = DecentVehicleDestination
function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local bidirectional = self:GetClientNumber "bidirectional" > 0
	local fuel = self:GetClientNumber "fuel" > 0
	local group = self:GetClientNumber "group"
	local shouldblink = self:GetClientNumber "shouldblink" > 0
	local speed = self:GetClientNumber "speed"
	local wait = self:GetClientNumber "wait"
	local pos = trace.HitPos
	local waypoint, waypointID = dvd.GetNearestWaypoint(pos, dvd.WaypointSize)
	if IsValid(trace.Entity) then
		if trace.Entity.IsDVTrafficLight then
			self.TrafficLight = trace.Entity
			self.WaypointID = -1
			self:SetStage(1)
			return true
		elseif trace.Entity.DecentVehicle then
			trace.Entity.DecentVehicle.Group = group
			return true
		end
	end
	
	if not waypoint then
		local oldpointID = self.WaypointID
		local newpoint = dvd.AddWaypoint(pos)
		self.WaypointID = #dvd.Waypoints
		dvd.AddTrafficLight(self.WaypointID, self.TrafficLight)
		newpoint.Owner = self:GetOwner()
		newpoint.Time = CurTime()
		newpoint.FuelStation = fuel
		newpoint.UseTurnLights = shouldblink
		newpoint.WaitUntilNext = wait
		newpoint.SpeedLimit = speed * KmphToHUps
		newpoint.Group = group
		if dvd.Waypoints[oldpointID] then
			dvd.AddNeighbor(oldpointID, self.WaypointID)
			if bidirectional then
				dvd.AddNeighbor(self.WaypointID, oldpointID)
			end
		end
		
		undo.Create "Decent Vehicle Waypoint"
		undo.SetCustomUndoText "Undone Decent Vehicle's waypoint."
		undo.AddFunction(dvd.UndoWaypoint)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()
	elseif self:GetStage() == 0 or not dvd.Waypoints[self.WaypointID] then
		self.WaypointID = waypointID
		self.TrafficLight = nil
		self:SetStage(1)
		return true
	elseif self.WaypointID ~= waypointID then
		if self.TrafficLight then
			dvd.AddTrafficLight(waypointID, self.TrafficLight)
		end
		
		if self.WaypointID > -1 then
			if table.HasValue(dvd.Waypoints[self.WaypointID].Neighbors, waypointID) then
				dvd.RemoveNeighbor(self.WaypointID, waypointID)
				if bidirectional then
					dvd.RemoveNeighbor(waypointID, self.WaypointID)
				end
			else
				dvd.AddNeighbor(self.WaypointID, waypointID)
				if bidirectional then
					dvd.AddNeighbor(waypointID, self.WaypointID)
				end
			end
		end
		
		self.WaypointID = -1
		self.TrafficLight = nil
	elseif self.WaypointID > -1 then
		dvd.RemoveWaypoint(self.WaypointID)
		self.WaypointID = -1
		self.TrafficLight = nil
	end
	
	self:SetStage(0)
	dvd.RefreshDupe()
	return true
end

function TOOL:RightClick(trace)
	local fuel = self:GetClientNumber "fuel" > 0
	local group = self:GetClientNumber "group"
	local shouldblink = self:GetClientNumber "shouldblink" > 0
	local speed = self:GetClientNumber "speed"
	local wait = self:GetClientNumber "wait"
	local pos = trace.HitPos
	local waypoint = dvd.GetNearestWaypoint(pos, dvd.WaypointSize)
	if not waypoint then return end
	if CLIENT then return true end
	
	waypoint.FuelStation = fuel
	waypoint.UseTurnLights = shouldblink
	waypoint.WaitUntilNext = wait
	waypoint.SpeedLimit = speed * KmphToHUps
	waypoint.Group = group
	
	self:SetStage(0)
	return true
end

local ConVarsDefault = TOOL:BuildConVarList()
local ConVarsList = table.GetKeys(ConVarsDefault)
function TOOL.BuildCPanel(CPanel)
	local ControlPresets = vgui.Create("ControlPresets", CPanel)
	ControlPresets:SetPreset "decentvehicle"
	ControlPresets:AddOption("#preset.default", ConVarsDefault)
	for k, v in pairs(ConVarsList) do
		ControlPresets:AddConVar(v)
	end
	
	CPanel:AddItem(ControlPresets)
	CPanel:Help "Create routes for Decent Vehicles."
	CPanel:CheckBox("#tool.dv_route.showupdates", "dv_route_showupdates"):SetToolTip "#tool.dv_route.showupdates.help"
	CPanel:CheckBox("#tool.dv_route.showpoints", "dv_route_showpoints")
	CPanel:CheckBox("#tool.dv_route.shouldblink", "dv_route_shouldblink"):SetToolTip "#tool.dv_route.shouldblink.help"
	CPanel:CheckBox("#tool.dv_route.bidirectional", "dv_route_bidirectional"):SetToolTip "#tool.dv_route.bidirectional.help"
	CPanel:CheckBox("#tool.dv_route.fuel", "dv_route_fuel"):SetToolTip "#tool.dv_route.fuel.help"
	CPanel:NumSlider("#tool.dv_route.group", "dv_route_group", 0, 20, 0):SetToolTip "#tool.dv_route.group.help"
	CPanel:NumSlider("#tool.dv_route.wait", "dv_route_wait", 0, 100, 2):SetToolTip "#tool.dv_route.wait.help"
	CPanel:NumSlider("#tool.dv_route.speed", "dv_route_speed", 5, 100, 0)
	
	if LocalPlayer():IsAdmin() then
		CPanel:Help ""
		CPanel:Help ""
		CPanel:ControlHelp "Server settings"
		CPanel:NumSlider("Detection range", "decentvehicle_detectionrange", 1, 64, 0)
		
		local combobox, label = CPanel:ComboBox("Light level", "decentvehicle_turnonlights")
		combobox:SetSortItems(false)
		combobox:AddChoice("No light", 0)
		combobox:AddChoice("Only running lights", 1)
		combobox:AddChoice("Running lights and headlights", 2)
		combobox:AddChoice("Full lights", 3)
		
		CPanel:Button("#tool.dv_route.save", "dv_route_save")
		CPanel:Help ""
		CPanel:Button("#tool.dv_route.load", "dv_route_load")
	end
	
	CPanel:InvalidateLayout()
end

if SERVER then return end
function TOOL:DrawHUD()
	if self:GetClientNumber "showpoints" == 0 then return end
	local pos = LocalPlayer():GetEyeTrace().HitPos
	local waypoint, waypointID = dvd.GetNearestWaypoint(pos, dvd.WaypointSize)
	if not waypoint then return end
	net.Start "Decent Vehicle: Send waypoint info"
	net.WriteUInt(waypointID, 24)
	net.SendToServer()
	
	if not waypoint.SpeedLimit then return end
	local textpos = pos:ToScreen()
	for _, text in ipairs {
		"ID: " .. tostring(waypointID),
		"Group: " .. tostring(waypoint.Group),
		"Speed limit [km/h]: " .. tostring(math.Round(waypoint.SpeedLimit / KmphToHUps, 2)),
		"Wait until next [sec]: " .. tostring(math.Round(waypoint.WaitUntilNext, 2)),
		"Use turn lights: " .. (waypoint.UseTurnLights and "Yes" or "No"),
		"Is fuel station: " .. (waypoint.FuelStation and "Yes" or "No"),
	} do
		textpos.y = textpos.y + select(2, draw.SimpleTextOutlined(
		text, "CloseCaption_Normal", textpos.x, textpos.y, color_white,
		TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, color_black))
	end
end
