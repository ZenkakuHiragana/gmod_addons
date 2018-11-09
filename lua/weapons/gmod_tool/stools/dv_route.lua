
TOOL.Category = "GreatZenkakuMan's tools"
TOOL.Name = "Decent Vehicle route maker"
TOOL.Information = {
	{name = "left", stage = 0},
	{name = "left_1", stage = 1},
	{name = "right"},
}

TOOL.WaypointID = nil
TOOL.ClientConVar["wait"] = 0
TOOL.ClientConVar["speed"] = 40
TOOL.ClientConVar["shouldblink"] = 0
TOOL.ClientConVar["showpoints"] = 1

if CLIENT then
	language.Add("tool.dv_route.name", "Decent Vehicle route maker")
	language.Add("tool.dv_route.desc", "Create your own routes for vehicles!")
	language.Add("tool.dv_route.left", "Create new waypoint or select a waypoint to link.")
	language.Add("tool.dv_route.left_1", "Select another waypoint you want to link to.  Select the same waypoint to remove it.")
	language.Add("tool.dv_route.right", "Update waypoint")
	
	language.Add("tool.dv_route.wait", "Wait time [seconds]")
	language.Add("tool.dv_route.shouldblink", "Should use turn signal?")
	language.Add("tool.dv_route.speed", "Max speed [km/h]")
	language.Add("tool.dv_route.showpoints", "Draw waypoints.")
end

local KilometerPerHourToHammerUnitsPerSecond = 1000 * 3.2808399 * 16 / 3600
local dvd = DecentVehicleDestination
function TOOL:LeftClick(trace)
	if CLIENT then return end
	local shouldblink = self:GetClientNumber("shouldblink", 0)
	local wait = self:GetClientNumber("wait", 0)
	local speed = self:GetClientNumber("speed", 0)
	local pos = trace.HitPos
	local waypoint, waypointID = dvd.GetNearestWaypoint(pos, dvd.WaypointSize)
	if not waypoint then
		local newpoint = dvd.AddWaypoint(pos)
		newpoint.Owner = self:GetOwner()
		newpoint.Time = CurTime()
		newpoint.UseTurnLights = shouldblink > 0
		newpoint.WaitUntilNext = wait
		newpoint.SpeedLimit = speed * KilometerPerHourToHammerUnitsPerSecond
		if dvd.Waypoints[self.WaypointID] then
			dvd.AddNeighbor(self.WaypointID, #dvd.Waypoints)
		end
		
		self.WaypointID = #dvd.Waypoints
		undo.Create "Waypoint"
		undo.SetCustomUndoText "Undone Decent Vehicle's waypoint."
		undo.AddFunction(dvd.UndoWaypoint)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()
	elseif self:GetStage() == 0 then
		self.WaypointID = waypointID
		self:SetStage(1)
		return true
	elseif self.WaypointID ~= waypointID then
		if table.HasValue(dvd.Waypoints[self.WaypointID].Neighbors, waypointID) then
			dvd.RemoveNeighbor(self.WaypointID, waypointID)
		else
			dvd.AddNeighbor(self.WaypointID, waypointID)
		end
		
		self.WaypointID = nil
	else
		dvd.RemoveWaypoint(self.WaypointID)
		self.WaypointID = nil
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

function TOOL.BuildCPanel(panel)
	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "decentvehicle", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )
	panel:AddControl("Header", { Text = "", Description = "Create route for driver." })

	panel:AddControl("CheckBox", {
		Label = "#tool.dv_route.shouldblink",
		Type = "int",
		Min = "0",
		Max = "1",
		Command = "dv_route_shouldblink"
	})

	panel:AddControl("CheckBox", {
		Label = "#tool.dv_route.showpoints",
		Type = "int",
		Min = "0",
		Max = "1",
		Command = "dv_route_showpoints"
	})
	
	panel:AddControl("Slider", {
		Label = "#tool.dv_route.wait",
		Type = "int",
		Min = "0",
		Max = "100",
		Command = "dv_route_wait"
	})
	
	panel:AddControl("Slider", {
		Label = "#tool.dv_route.speed",
		Type = "int",
		Min = "5",
		Max = "100",
		Command = "dv_route_speed"
	})
end
