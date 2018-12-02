
TOOL.Category = "GreatZenkakuMan's tools"
TOOL.Name = "Decent Vehicle route maker"
TOOL.Information = {
	{name = "left", stage = 0},
	{name = "left_1", stage = 1},
	{name = "right"},
}

TOOL.WaypointID = -1
TOOL.ClientConVar["bidirectional"] = 0
TOOL.ClientConVar["shouldblink"] = 0
TOOL.ClientConVar["showpoints"] = 1
TOOL.ClientConVar["speed"] = 40
TOOL.ClientConVar["wait"] = 0

if CLIENT then
	language.Add("tool.dv_route.name", "Decent Vehicle route maker")
	language.Add("tool.dv_route.desc", "Create your own routes for vehicles!")
	language.Add("tool.dv_route.left", "Create new waypoint or select a waypoint/traffic light to link.")
	language.Add("tool.dv_route.left_1", "Select another waypoint you want to link to.  Select the same waypoint to remove it.")
	language.Add("tool.dv_route.right", "Update waypoint.")
	
	language.Add("tool.dv_route.bidirectional", "Bi-directional link")
	language.Add("tool.dv_route.bidirectional.help", "If you create a new waypoint, connect bi-directional link automatically.")
	language.Add("tool.dv_route.save", "Save waypoints")
	language.Add("tool.dv_route.shouldblink", "Use turn signals")
	language.Add("tool.dv_route.shouldblink.help", "If checked, Decent Vehicles will use turn signals when they go to the waypoint.")
	language.Add("tool.dv_route.showpoints", "Draw waypoints")
	language.Add("tool.dv_route.speed", "Max speed [km/h]")
	language.Add("tool.dv_route.wait", "Wait time [seconds]")
	language.Add("tool.dv_route.wait.help", "After Decent Vehicles reached the waypoint, they wait for this seconds.")
end

local KilometerPerHourToHammerUnitsPerSecond = 1000 * 3.2808399 * 16 / 3600
local dvd = DecentVehicleDestination
function TOOL:LeftClick(trace)
	if CLIENT then return end
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "dv_traffic_light" then
		self.TrafficLight = trace.Entity
		self.WaypointID = -1
		self:SetStage(1)
		return true
	end
	
	local bidirectional = self:GetClientNumber "bidirectional" > 0
	local shouldblink = self:GetClientNumber "shouldblink"
	local speed = self:GetClientNumber "speed"
	local wait = self:GetClientNumber "wait"
	local pos = trace.HitPos
	local waypoint, waypointID = dvd.GetNearestWaypoint(pos, dvd.WaypointSize)
	if not waypoint then
		local oldpointID = self.WaypointID
		local newpoint = dvd.AddWaypoint(pos)
		self.WaypointID = #dvd.Waypoints
		dvd.AddTrafficLight(self.WaypointID, self.TrafficLight)
		newpoint.Owner = self:GetOwner()
		newpoint.Time = CurTime()
		newpoint.UseTurnLights = shouldblink > 0
		newpoint.WaitUntilNext = wait
		newpoint.SpeedLimit = speed * KilometerPerHourToHammerUnitsPerSecond
		if dvd.Waypoints[oldpointID] then
			dvd.AddNeighbor(oldpointID, self.WaypointID)
			if bidirectional then
				dvd.AddNeighbor(self.WaypointID, oldpointID)
			end
		end
		
		undo.Create "Waypoint"
		undo.SetCustomUndoText "Undone Decent Vehicle's waypoint."
		undo.AddFunction(dvd.UndoWaypoint)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()
	elseif self:GetStage() == 0 then
		self.WaypointID = waypointID
		self.TrafficLight = nil
		self:SetStage(1)
		return true
	elseif self.WaypointID ~= waypointID then
		dvd.AddTrafficLight(waypointID, self.TrafficLight)
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
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return end
	local shouldblink = self:GetClientNumber("shouldblink", 0)
	local wait = self:GetClientNumber("wait", 0)
	local speed = self:GetClientNumber("speed", 0)
	local pos = trace.HitPos
	local waypoint = dvd.GetNearestWaypoint(pos, dvd.WaypointSize)
	if not waypoint then return end
	
	waypoint.UseTurnLights = shouldblink > 0
	waypoint.WaitUntilNext = wait
	waypoint.SpeedLimit = speed * KilometerPerHourToHammerUnitsPerSecond
	
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
	CPanel:CheckBox("#tool.dv_route.showpoints", "dv_route_showpoints")
	CPanel:CheckBox("#tool.dv_route.shouldblink", "dv_route_shouldblink"):SetToolTip "#tool.dv_route.shouldblink.help"
	CPanel:CheckBox("#tool.dv_route.bidirectional", "dv_route_bidirectional"):SetToolTip "#tool.dv_route.bidirectional.help"
	CPanel:NumSlider("#tool.dv_route.wait", "dv_route_wait", 0, 100, 2):SetToolTip "#tool.dv_route.wait.help"
	CPanel:NumSlider("#tool.dv_route.speed", "dv_route_speed", 5, 100, 0)
	CPanel:Button("#tool.dv_route.save", "dv_route_save")
	CPanel:InvalidateLayout()
end
