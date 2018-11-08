
-- This script stands for a framework of Decent Vehicle's waypoints.

DecentVehicleDestination = DecentVehicleDestination or {
	Waypoints = {},
	WaypointSize = 20,
}

local dvd = DecentVehicleDestination
-- The waypoints are held in normal table.
-- They're found by brute-force search.

util.AddNetworkString "Decent Vehicle: Add a waypoint"
util.AddNetworkString "Decent Vehicle: Remove a waypoint"
util.AddNetworkString "Decent Vehicle: Add a neighbor"
util.AddNetworkString "Decent Vehicle: Remove a neighbor"
hook.Add("PostCleanupMap", "Decent Vehicle: Clean up waypoints", function()
	dvd.Waypoints = {}
end)

function dvd.AddWaypoint(pos)
	local waypoint = {Target = pos, Neighbors = {}}
	table.insert(dvd.Waypoints, waypoint)
	net.Start "Decent Vehicle: Add a waypoint"
	net.WriteVector(pos)
	net.Broadcast()
	return waypoint
end

function dvd.RemoveWaypoint(id)
	if isvector(id) then id = select(2, dvd.GetNearestWaypoint(id)) end
	if not id then return end
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
	net.Start "Decent Vehicle: Remove a waypoint"
	net.WriteUInt(id, 24)
	net.Broadcast()
end

function dvd.UndoWaypoint(undoinfo)
	for i, w in SortedPairsByMemberValue(dvd.Waypoints, "Time", true) do
		if undoinfo.Owner == w.Owner then
			dvd.RemoveWaypoint(i)
			break
		end
	end
end

function dvd.GetNearestWaypoint(pos, radius)
	local mindist, waypoint, waypointID = radius and radius^2 or math.huge, nil, nil
	for i, w in ipairs(dvd.Waypoints) do
		local distance = w.Target:DistToSqr(pos)
		if distance < mindist then
			mindist, waypoint, waypointID = distance, w, i
		end
	end
	
	return waypoint, waypointID
end

function dvd.AddNeighbor(from, to)
	table.insert(assert(dvd.Waypoints[from], "Decent Vehicle: attempt to create a neighbor with invalid waypoint!").Neighbors, to)
	net.Start "Decent Vehicle: Add a neighbor"
	net.WriteUInt(from, 24)
	net.WriteUInt(to, 24)
	net.Broadcast()
end

function dvd.RemoveNeighbor(from, to)
	table.RemoveByValue(assert(dvd.Waypoints[from], "Decent Vehicle: attempt to remove a neighbor with invalid waypoint!").Neighbors, to)
	net.Start "Decent Vehicle: Remove a neighbor"
	net.WriteUInt(from, 24)
	net.WriteUInt(to, 24)
	net.Broadcast()
end
