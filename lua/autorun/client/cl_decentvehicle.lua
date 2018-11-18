
-- This script stands for a framework of Decent Vehicle's waypoints.

include "autorun/decentvehicle.lua"

local dvd = DecentVehicleDestination
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
	dvd.Waypoints = {}
end)

hook.Add("InitPostEntity", "Decent Vehicle: Load waypoints", function()
	net.Start "Decent Vehicle: Retrive waypoints"
	net.WriteUInt(1, 24)
	net.SendToServer()
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

-- Retrives the nearest waypoint to the given position.
-- Arguments:
--   Vector pos			| The position to find.
--   number radius		| Optional.  The maximum radius.
-- Returnings:
--   table waypoint		| The found waypoint.  Can be nil.
--   number waypointID	| The ID of found waypoint.
function dvd.GetNearestWaypoint(pos, radius)
	local mindist, waypoint, waypointID = radius or math.huge, nil, nil
	for i, w in ipairs(dvd.Waypoints) do
		local distance = w.Target:DistToSqr(pos)
		if distance < mindist then
			mindist, waypoint, waypointID = distance, w, i
		end
	end
	
	return waypoint, waypointID
end
