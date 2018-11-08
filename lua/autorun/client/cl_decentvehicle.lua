
-- This script stands for a framework of Decent Vehicle's waypoints.

DecentVehicleDestination = DecentVehicleDestination or {
	Waypoints = {},
	WaypointSize = 20,
}

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

hook.Add("PostCleanupMap", "Decent Vehicle: Clean up waypoints", function()
	dvd.Waypoints = {}
end)

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
