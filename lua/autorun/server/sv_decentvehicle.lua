
-- This script stands for a framework of Decent Vehicle's waypoints.

DecentVehicleDestination = DecentVehicleDestination or {
	TLDuration = {33, 4, 40 + 3}, -- Sign duration of each light color, Green, Yellow, Red.
	TrafficLights = {
		A = {Time = CurTime() + 33, Light = 1},   -- Light pattern A
		B = {Time = CurTime() + 40, Light = 3}, -- Light pattern B
	},
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
util.AddNetworkString "Decent Vehicle: Traffic light"
util.AddNetworkString "Decent Vehicle: Retrive waypoints"
hook.Add("PostCleanupMap", "Decent Vehicle: Clean up waypoints", function()
	dvd.Waypoints = {}
end)

hook.Add("InitPostEntity", "Decent Vehicle: Load waypoints", function()
	local path = "data/decentvehicle/" .. game.GetMap() .. ".txt"
	if not file.Exists(path, "GAME") then return end
	dvd.Waypoints = util.JSONToTable(util.Decompress(file.Read(path, true) or ""))
	for i, w in ipairs(dvd.Waypoints) do
		if w.TrafficLight then
			local trafficlight = ents.Create "dv_traffic_light"
			trafficlight:SetPos(w.TrafficLight.Pos)
			trafficlight:SetAngles(w.TrafficLight.Ang)
			trafficlight:Spawn()
			local ph = trafficlight:GetPhysicsObject()
			if IsValid(ph) then ph:Sleep() end
			w.TrafficLight = trafficlight
		end
	end
end)

hook.Add("Tick", "Decent Vehicle: Control traffic lights", function()
	for PatternName, TL in pairs(dvd.TrafficLights) do
		if CurTime() < TL.Time then continue end
		TL.Light = TL.Light % 3 + 1
		TL.Time = CurTime() + dvd.TLDuration[TL.Light]
	end
end)

concommand.Add("dv_route_save", function(ply)
	local path = "decentvehicle/"
	if not file.Exists(path, "DATA") then file.CreateDir(path) end
	path = path .. game.GetMap() .. ".txt"
	
	local save = {}
	for i, w in ipairs(dvd.Waypoints) do
		save[i] = table.Copy(w)
		if IsValid(w.TrafficLight) then
			save[i].TrafficLight = {
				Pos = w.TrafficLight:GetPos(),
				Ang = w.TrafficLight:GetAngles(),
			}
		else
			save[i].TrafficLight = nil
		end
	end
	
	file.Write(path, util.Compress(util.TableToJSON(save)))
	ply:SendLua "notification.AddLegacy(\"Decent Vehicle: Waypoints saved!\", NOTIFY_GENERIC, 5)"
end)

net.Receive("Decent Vehicle: Retrive waypoints", function(_, ply)
	local id = net.ReadUInt(24)
	net.Start "Decent Vehicle: Retrive waypoints"
	if id > #dvd.Waypoints then
		net.WriteUInt(0, 24)
		net.Send(ply)
		return
	end
	
	net.WriteUInt(id, 24)
	net.WriteVector(dvd.Waypoints[id].Target)
	net.WriteEntity(dvd.Waypoints[id].TrafficLight or NULL)
	net.WriteUInt(#dvd.Waypoints[id].Neighbors, 14)
	for i, n in ipairs(dvd.Waypoints[id].Neighbors) do
		net.WriteUInt(n, 24)
	end
	net.Send(ply)
end)

local function GetWaypointFromID(id)
	return assert(dvd.Waypoints[id], "Decent Vehicle: Waypoint is not found!")
end

-- Creates a new waypoint at given position.
-- The new ID is always #dvd.Waypoints.
-- Argument:
--   Vector pos		| The position of new waypoint.
-- Returning:
--   table waypoint	| Created waypoint.
function dvd.AddWaypoint(pos)
	local waypoint = {Target = pos, Neighbors = {}}
	table.insert(dvd.Waypoints, waypoint)
	net.Start "Decent Vehicle: Add a waypoint"
	net.WriteVector(pos)
	net.Broadcast()
	return waypoint
end

-- Removes a waypoint by ID.
-- Argument:
--   number id	| An unsigned number to remove.
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

-- Undo function that removes the most recent waypoint.
function dvd.UndoWaypoint(undoinfo)
	for i, w in SortedPairsByMemberValue(dvd.Waypoints, "Time", true) do
		if undoinfo.Owner == w.Owner then
			dvd.RemoveWaypoint(i)
			break
		end
	end
end

-- Retrives the nearest waypoint to the given position.
-- Arguments:
--   Vector pos			| The position to find.
--   number radius		| Optional.  The maximum radius.
-- Returnings:
--   table waypoint		| The found waypoint.  Can be nil.
--   number waypointID	| The ID of found waypoint.
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

-- Adds a link between two waypoints.
-- The link is one-way, one to another.
-- Arguments:
--   number from	| The waypoint ID the link starts from.
--   number to		| The waypoint ID connected to.
function dvd.AddNeighbor(from, to)
	table.insert(GetWaypointFromID(from).Neighbors, to)
	net.Start "Decent Vehicle: Add a neighbor"
	net.WriteUInt(from, 24)
	net.WriteUInt(to, 24)
	net.Broadcast()
end

-- Removes an existing link between two waypoints.
-- Does nothing if the given link is not found.
-- Arguments:
--   number from	| The waypoint ID the link starts from.
--   number to		| The waypoint ID connected to.
function dvd.RemoveNeighbor(from, to)
	table.RemoveByValue(GetWaypointFromID(from).Neighbors, to)
	net.Start "Decent Vehicle: Remove a neighbor"
	net.WriteUInt(from, 24)
	net.WriteUInt(to, 24)
	net.Broadcast()
end

-- Adds a link between a waypoint and a traffic light entity.
-- Arguments:
--   number id		| The waypoint ID.
--   Entity traffic	| The traffic light entity.  Giving nil to remove the link.
function dvd.AddTrafficLight(id, traffic)
	local waypoint = GetWaypointFromID(id)
	if not IsValid(traffic)
	or traffic:GetClass() ~= "dv_traffic_light"
	or waypoint.TrafficLight == traffic then
		traffic = nil
	end
	
	waypoint.TrafficLight = traffic
	net.Start "Decent Vehicle: Traffic light"
	net.WriteUInt(id, 24)
	net.WriteEntity(traffic or NULL)
	net.Broadcast()
end