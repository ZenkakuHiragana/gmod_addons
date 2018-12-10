
-- This script stands for a framework of Decent Vehicle's waypoints.

include "autorun/decentvehicle.lua"

local dvd = DecentVehicleDestination
local OldVersionNotify = "Decent Vehicle: This is an old version.  Check for updates!"
local function NotifyUpdate(d)
	if not d then return end
	local showupdates = GetConVar "dv_route_showupdates"
	if not (showupdates and showupdates:GetBool()) then return end
	d.description = [[Version 1.0.0
]] .. d.description
	local versioncheck = "decentvehicle_version.txt"
	local checkedversion = file.Read(versioncheck) or 0
	local header = d.description:match "Version[^%c]+" or ""
	local version = string.Explode(".", header:sub(8):Trim())
	PrintTable(version)
	if version[1] and tonumber(version[1]) > dvd.Version[1]
	or version[2] and tonumber(version[2]) > dvd.Version[2]
	or version[3] and tonumber(version[3]) > dvd.Version[3] then
		notification.AddLegacy(OldVersionNotify, NOTIFY_ERROR, 15)
	elseif tonumber(checkedversion) < d.updated then
		notification.AddLegacy("Decent Vehicle " .. header, NOTIFY_GENERIC, 18)
		
		local i = 0
		for update in d.description:gmatch "%[%*%][^%c]+" do
			timer.Simple(3 * i, function()
				if not showupdates:GetBool() then return end
				notification.AddLegacy(update:sub(4), NOTIFY_UNDO, 6)
			end)
			
			i = i + 1
		end
		
		file.Write(versioncheck, tostring(d.updated))
	end
end

-- The waypoints are held in normal table.
-- They're found by brute-force search.

net.Receive("Decent Vehicle: Add a waypoint", function()
	local pos = net.ReadVector()
	local waypoint = {Target = pos, Neighbors = {}}
	table.insert(dvd.Waypoints, waypoint)
end)

net.Receive("Decent Vehicle: Remove a waypoint", function()
	local id = net.ReadUInt(24)
	for _, w in ipairs(dvd.Waypoints) do
		local Neighbors = {}
		for _, n in ipairs(w.Neighbors) do
			if n > id then
				table.insert(Neighbors, n - 1)
			elseif n < id then
				table.insert(Neighbors, n)
			end
		end
		
		w.Neighbors = Neighbors
	end
	
	table.remove(dvd.Waypoints, id)
end)

net.Receive("Decent Vehicle: Add a neighbor", function()
	local from = net.ReadUInt(24)
	local to = net.ReadUInt(24)
	table.insert(dvd.Waypoints[from].Neighbors, to)
end)

net.Receive("Decent Vehicle: Remove a neighbor", function()
	local from = net.ReadUInt(24)
	local to = net.ReadUInt(24)
	table.RemoveByValue(dvd.Waypoints[from].Neighbors, to)
end)

net.Receive("Decent Vehicle: Traffic light", function()
	local id = net.ReadUInt(24)
	local traffic = net.ReadEntity()
	dvd.Waypoints[id].TrafficLight = Either(IsValid(traffic), traffic, nil)
end)

hook.Add("PostCleanupMap", "Decent Vehicle: Clean up waypoints", function()
	table.Empty(dvd.Waypoints)
end)

hook.Add("InitPostEntity", "Decent Vehicle: Load waypoints", function()
	net.Start "Decent Vehicle: Retrive waypoints"
	net.WriteUInt(1, 24)
	net.SendToServer()
	
	steamworks.FileInfo("1582693384", NotifyUpdate)
end)

net.Receive("Decent Vehicle: Retrive waypoints", function()
	local id = net.ReadUInt(24)
	if id < 1 then return end
	local pos = net.ReadVector()
	local traffic = net.ReadEntity()
	if not IsValid(traffic) then traffic = nil end
	local num = net.ReadUInt(14)
	local neighbors = {}
	for i = 1, num do
		table.insert(neighbors, net.ReadUInt(24))
	end
	
	dvd.Waypoints[id] = {
		Target = pos,
		TrafficLight = traffic,
		Neighbors = neighbors,
	}
	
	net.Start "Decent Vehicle: Retrive waypoints"
	net.WriteUInt(id + 1, 24)
	net.SendToServer()
end)

net.Receive("Decent Vehicle: Send waypoint info", function()
	local id = net.ReadUInt(24)
	local waypoint = dvd.Waypoints[id]
	if not waypoint then return end
	waypoint.Group = net.ReadUInt(16)
	waypoint.SpeedLimit = net.ReadFloat()
	waypoint.WaitUntilNext = net.ReadFloat()
	waypoint.UseTurnLights = net.ReadBool()
	waypoint.FuelStation = net.ReadBool()
end)

local Height = vector_up * dvd.WaypointSize / 4
local WaypointMaterial = Material "sprites/sent_ball"
local LinkMaterial = Material "cable/blue_elec"
local TrafficMaterial = Material "cable/redlaser"
hook.Add("PostDrawTranslucentRenderables", "Decent Vehicle: Draw waypoints",
function(bDrawingDepth, bDrawingSkybox)
	if bDrawingSkybox or not GetConVar "dv_route_showpoints":GetBool() then return end
	for _, w in ipairs(dvd.Waypoints) do
		render.SetMaterial(WaypointMaterial)
		render.DrawSprite(w.Target + Height, dvd.WaypointSize, dvd.WaypointSize, color_white)
		render.SetMaterial(LinkMaterial)
		for _, n in ipairs(w.Neighbors) do
			if dvd.Waypoints[n] then
				local pos = dvd.Waypoints[n].Target
				local tex = w.Target:Distance(pos) / 100
				local texbase = 1 - CurTime() % 1
				render.DrawBeam(w.Target + Height, pos + Height, 20, texbase, texbase + tex, color_white)
			end
		end
		
		if IsValid(w.TrafficLight) then
			local pos = w.TrafficLight:GetPos()
			local tex = w.Target:Distance(pos) / 100
			render.SetMaterial(TrafficMaterial)
			render.DrawBeam(w.Target + Height, pos, 20, 0, tex, color_white)
		end
	end
end)
