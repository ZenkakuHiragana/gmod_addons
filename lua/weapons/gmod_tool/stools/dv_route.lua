
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile()
local dvd = DecentVehicleDestination
local texts = dvd.Texts.Tools

TOOL.IsDecentVehicleTool = true
TOOL.Category = texts.Category
TOOL.Name = texts.Name
TOOL.Information = {
	{name = "info", stage = 0},
	{name = "left", stage = 0},
	{name = "left_1", stage = 1},
	{name = "right"},
}

TOOL.WaypointID = -1
TOOL.ClientConVar["bidirectional"] = 0
TOOL.ClientConVar["drawdistance"] = 6000
TOOL.ClientConVar["fuel"] = 0
TOOL.ClientConVar["group"] = 0
TOOL.ClientConVar["shouldblink"] = 0
TOOL.ClientConVar["showalways"] = 0
TOOL.ClientConVar["showpoints"] = 1
TOOL.ClientConVar["showupdates"] = 1
TOOL.ClientConVar["speed"] = 40
TOOL.ClientConVar["updateradius"] = 100
TOOL.ClientConVar["wait"] = 0

if CLIENT then
	language.Add("tool.dv_route.name", texts.PrintName)
	language.Add("tool.dv_route.desc", texts.Description)
	language.Add("tool.dv_route.0", texts.Instructions)
	language.Add("tool.dv_route.left", texts.Left[1])
	language.Add("tool.dv_route.left_1", texts.Left[2])
	language.Add("tool.dv_route.right", texts.Right[1])
end

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
		newpoint.SpeedLimit = speed * dvd.KmphToHUps
		newpoint.Group = group
		if dvd.Waypoints[oldpointID] then
			dvd.AddNeighbor(oldpointID, self.WaypointID)
			if bidirectional then
				dvd.AddNeighbor(self.WaypointID, oldpointID)
			end
		end
		
		undo.Create "Decent Vehicle Waypoint"
		undo.SetCustomUndoText(dvd.Texts.UndoText)
		undo.AddFunction(dvd.UndoWaypoint)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()
	elseif self:GetStage() == 0 or not (dvd.Waypoints[self.WaypointID] or IsValid(self.TrafficLight)) then
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
		local removed = false
		for id, undolist in pairs(undo.GetTable()) do
			for i, undotable in pairs(undolist) do
				if undotable.Name ~= "Decent Vehicle Waypoint" then continue end
				if undotable.Owner ~= self:GetOwner() then continue end
				undolist[i] = nil
				removed = true
				break
			end
			
			if removed then break end
		end
	end
	
	self:SetStage(0)
	return true
end

function TOOL:RightClick(trace)
	local fuel = self:GetClientNumber "fuel" > 0
	local group = self:GetClientNumber "group"
	local shouldblink = self:GetClientNumber "shouldblink" > 0
	local speed = self:GetClientNumber "speed"
	local wait = self:GetClientNumber "wait"
	local pos = trace.HitPos
	local waypoints = {}
	if self:GetOwner():KeyDown(IN_USE) then
		local RadiusSqr = self:GetClientNumber "updateradius"^2
		for i, w in ipairs(dvd.Waypoints) do
			if pos:DistToSqr(w.Target) > RadiusSqr then continue end
			table.insert(waypoints, i)
		end
	else
		waypoints = {select(2, dvd.GetNearestWaypoint(pos, dvd.WaypointSize))}
	end
	
	if #waypoints == 0 then return end
	for _, i in ipairs(waypoints) do
		local w = dvd.Waypoints[i]
		if not w then continue end
		w.FuelStation = fuel
		w.UseTurnLights = shouldblink
		w.WaitUntilNext = wait
		w.SpeedLimit = speed * dvd.KmphToHUps
		w.Group = group

		net.Start "Decent Vehicle: Send waypoint info"
		net.WriteUInt(i, 24)
		net.WriteUInt(w.Group, 16)
		net.WriteFloat(w.SpeedLimit)
		net.WriteFloat(w.WaitUntilNext)
		net.WriteBool(w.UseTurnLights)
		net.WriteBool(w.FuelStation)
		net.Broadcast()
	end
	
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
	if dvd.Texts.Version then
		local label = CPanel:Help(dvd.Texts.Version)
		label:SetTextColor(CPanel:GetSkin().Colours.Tree.Hover)
	end
	
	CPanel:Help(texts.DescriptionInMenu)
	CPanel:CheckBox(texts.ShowUpdates, "dv_route_showupdates"):SetToolTip(texts.ShowUpdatesHelp)
	CPanel:CheckBox(texts.DrawWaypoints, "dv_route_showpoints")
	CPanel:CheckBox(texts.AlwaysDrawWaypoints, "dv_route_showalways")
	CPanel:CheckBox(texts.Bidirectional, "dv_route_bidirectional"):SetToolTip(texts.BidirectionalHelp)
	CPanel:CheckBox(texts.UseTurnLights, "dv_route_shouldblink"):SetToolTip(texts.UseTurnLightsHelp)
	CPanel:CheckBox(texts.FuelStation, "dv_route_fuel"):SetToolTip(texts.FuelStationHelp)
	CPanel:NumSlider(texts.UpdateRadius, "dv_route_updateradius", 100, 400, 0):SetToolTip(texts.UpdateRadiusHelp)
	CPanel:NumSlider(texts.DrawDistance, "dv_route_drawdistance", 2000, 10000, 0):SetToolTip(texts.DrawDistanceHelp)
	CPanel:NumSlider(texts.WaypointGroup, "dv_route_group", 0, 20, 0):SetToolTip(texts.WaypointGroupHelp)
	CPanel:NumSlider(texts.WaitTime, "dv_route_wait", 0, 100, 2):SetToolTip(texts.WaitTimeHelp)
	CPanel:NumSlider(texts.MaxSpeed, "dv_route_speed", 5, 500, 0)
	
	if LocalPlayer():IsAdmin() then
		CPanel:Help ""
		local label = CPanel:Help(texts.ServerSettings)
		label:SetTextColor(CPanel:GetSkin().Colours.Tree.Hover)
		CPanel:CheckBox(texts.AutoLoad, "decentvehicle_autoload"):SetToolTip(texts.AutoLoadHelp)
		CPanel:CheckBox(texts.DriveSide, "decentvehicle_driveside")
		CPanel:CheckBox(texts.ShouldGoToRefuel, "decentvehicle_gotorefuel")
		CPanel:CheckBox(texts.LockVehicle, "decentvehicle_lock"):SetToolTip(texts.LockVehicleHelp)
		CPanel:NumSlider(texts.DetectionRange, "decentvehicle_detectionrange", 1, 64, 0)
		CPanel:NumSlider(texts.DetectionRangeELS, "decentvehicle_elsrange", 0, 1000, 0)
		
		local combobox, label = CPanel:ComboBox(texts.LightLevel.Title, "decentvehicle_turnonlights")
		combobox:SetSortItems(false)
		combobox:AddChoice(texts.LightLevel.None, 0)
		combobox:AddChoice(texts.LightLevel.Running, 1)
		combobox:AddChoice(texts.LightLevel.Headlights, 2)
		combobox:AddChoice(texts.LightLevel.All, 3)
		
		CPanel:Button(texts.Save, "dv_route_save")
		CPanel:Button(texts.Restore, "dv_route_load")
		CPanel:Button(texts.Delete, "dv_route_delete")
		CPanel:Button(texts.Generate, "dv_route_generate")
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
		texts.ShowInfo.ID .. tostring(waypointID),
		texts.ShowInfo.Group .. tostring(waypoint.Group),
		texts.ShowInfo.SpeedLimit .. tostring(math.Round(waypoint.SpeedLimit / dvd.KmphToHUps, 2)),
		texts.ShowInfo.WaitUntilNext .. tostring(math.Round(waypoint.WaitUntilNext, 2)),
		texts.ShowInfo.UseTurnLights .. (waypoint.UseTurnLights and "Yes" or "No"),
		texts.ShowInfo.FuelStation .. (waypoint.FuelStation and "Yes" or "No"),
	} do
		textpos.y = textpos.y + select(2, draw.SimpleTextOutlined(
		text, "CloseCaption_Normal", textpos.x, textpos.y, color_white,
		TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, color_black))
	end
end
