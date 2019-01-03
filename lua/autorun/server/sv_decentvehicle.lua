
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

-- This script stands for a framework of Decent Vehicle's waypoints.

include "autorun/decentvehicle.lua"
resource.AddWorkshop "1587455087"

-- Waypoints are held in normal table.
-- They're found by brute-force search.
local dvd = DecentVehicleDestination
local HULLS = 10
local MAX_NODES = 1500
local NODE_VERSION_NUMBER = 37
local Exceptions = {Target = true, TrafficLight = true}
local function GetWaypointFromID(id)
	return assert(dvd.Waypoints[id], dvd.Texts.Errors.WaypointNotFound)
end

local function ClearUndoList()
	for id, undolist in pairs(undo.GetTable()) do
		for i, undotable in pairs(undolist) do
			if undotable.Name ~= "Decent Vehicle Waypoint" then continue end
			undolist[i] = nil
		end
	end
end

local function ConfirmSaveRestore(ply, save)
	net.Start "Decent Vehicle: Save and restore"
	net.WriteUInt(save, dvd.POPUPWINDOW.BITS)
	net.Send(ply)
end

local function WriteWaypoint(id)
	local waypoint = GetWaypointFromID(id)
	net.WriteUInt(id, 24)
	net.WriteVector(waypoint.Target)
	net.WriteEntity(waypoint.TrafficLight or NULL)
	net.WriteUInt(#waypoint.Neighbors, 14)
	for i, n in ipairs(waypoint.Neighbors) do
		net.WriteUInt(n, 24)
	end
end

local function OverwriteWaypoints(source)
	if source == dvd then return end
	local side = GetConVar "decentvehicle_driveside"
	if side then side:SetInt(source.DriveSide) end
	dvd.DriveSide = source.DriveSide
	ClearUndoList()
	table.Empty(dvd.Waypoints)
	net.Start "Decent Vehicle: Clear waypoints"
	net.Broadcast()
	
	for i, t in ipairs(ents.GetAll()) do
		if t.IsDVTrafficLight then t:Remove() end
	end
	
	for i, w in ipairs(source) do
		local new = dvd.AddWaypoint(w.Target)
		for key, value in pairs(w) do
			if Exceptions[key] then continue end
			new[key] = value
		end
	end
	
	for i, t in ipairs(source.TrafficLights) do
		local traffic = ents.Create(t.ClassName)
		if not IsValid(traffic) then continue end
		traffic:SetPos(t.Pos)
		traffic:SetAngles(t.Ang)
		traffic:Spawn()
		traffic:SetPattern(t.Pattern)
		traffic.Waypoints = t.Waypoints
		for i, id in ipairs(t.Waypoints) do
			if not dvd.Waypoints[id] then continue end
			dvd.Waypoints[id].TrafficLight = traffic
		end
		
		local p = traffic:GetPhysicsObject()
		if IsValid(p) then p:Sleep() end
	end
	
	hook.Run("Decent Vehicle: OnLoadWaypoints", source)
	
	if #dvd.Waypoints == 0 then return end
	net.Start "Decent Vehicle: Retrive waypoints"
	WriteWaypoint(1)
	net.Broadcast()
end

local function ParseAIN()
	local path = string.format("maps/graphs/%s.ain", game.GetMap())
	local f = file.Open(path, "rb", "GAME")
	if not f then return end
	
	local node_version = f:ReadLong()
	local map_version = f:ReadLong()
	local numNodes = f:ReadLong()
	local nodegraph = {
		node_version = node_version,
		map_version = map_version,
	}
	
	assert(node_version == NODE_VERSION_NUMBER, "Decent Vehicle: Unknown graph file.")
	assert(0 <= numNodes and numNodes <= MAX_NODES, "Decent Vehicle: Graph file has an unexpected amount of nodes")
	
	local nodes = {}
	for i = 1, numNodes do
		local x = f:ReadFloat()
		local y = f:ReadFloat()
		local z = f:ReadFloat()
		local yaw = f:ReadFloat()
		local v = Vector(x, y, z)
		local flOffsets = {}
		for i = 1, HULLS do
			flOffsets[i] = f:ReadFloat()
		end
		
		local nodetype = f:ReadByte()
		local nodeinfo = f:ReadUShort()
		local zone = f:ReadShort()
		local node = {
			pos = v,
			yaw = yaw,
			offset = flOffsets,
			type = nodetype,
			info = nodeinfo,
			zone = zone,
			neighbor = {},
			numneighbors = 0,
			link = {},
			numlinks = 0
		}
		
		table.insert(nodes, node)
	end
	
	local numLinks = f:ReadLong()
	local links = {}
	for i = 1, numLinks do
		local link = {}
		local srcID = f:ReadShort()
		local destID = f:ReadShort()
		local nodesrc = assert(nodes[srcID + 1], "Decent Vehicle: Unknown source node")
		local nodedest = assert(nodes[destID + 1], "Decent Vehicle: Unknown destination node")
		table.insert(nodesrc. neighbor, nodedest)
		nodesrc.numneighbors = nodesrc.numneighbors + 1
		
		table.insert(nodesrc.link, link)
		nodesrc.numlinks = nodesrc.numlinks + 1
		link.src, link.srcID = nodesrc, srcID + 1
		
		table.insert(nodedest.neighbor, nodesrc)
		nodedest.numneighbors = nodedest.numneighbors + 1
		
		table.insert(nodedest.link, link)
		nodedest.numlinks = nodedest.numlinks + 1
		link.dest, link.destID = nodedest, destID + 1
		
		link.move = {}
		for i = 1, HULLS do
			link.move[i] = f:ReadByte()
		end
		
		table.insert(links, link)
	end
	
	local lookup = {}
	for i = 1, numNodes do
		table.insert(lookup, f:ReadLong())
	end
	
	f:Close()
	nodegraph.nodes = nodes
	nodegraph.links = links
	nodegraph.lookup = lookup
	return nodegraph
end

local KmphToHUps = 1000 * 3.2808399 * 16 / 3600
local function GenerateWaypoints()
	dvd.Nodegraph = dvd.Nodegraph or ParseAIN()
	ClearUndoList()
	table.Empty(dvd.Waypoints)
	net.Start "Decent Vehicle: Clear waypoints"
	net.Broadcast()
	
	local owner = player.GetByID(1)
	local speed = GetConVar "dv_route_speed":GetFloat() * KmphToHUps
	local time = CurTime()
	local map = {}
	for i, n in ipairs(dvd.Nodegraph.nodes) do
		if n.type ~= 2 then continue end
		table.insert(dvd.Waypoints, {
			FuelStation = false,
			Group = 0,
			Neighbors = {},
			Owner = owner,
			SpeedLimit = speed,
			Target = util.QuickTrace(n.pos + vector_up * dvd.WaypointSize, -vector_up * 32768).HitPos,
			Time = time,
			TrafficLight = nil,
			UseTurnLights = false,
			WaitUntilNext = 0,
		})
		
		map[i] = #dvd.Waypoints
	end
	
	for i, link in ipairs(dvd.Nodegraph.links) do
		if link.move[HULL_LARGE_CENTERED + 1] ~= 1 then continue end
		local d, s = map[link.destID], map[link.srcID]
		if dvd.Waypoints[d] and dvd.Waypoints[s] then
			table.insert(dvd.Waypoints[s].Neighbors, d)
			table.insert(dvd.Waypoints[d].Neighbors, s)
		end
	end
	
	if #dvd.Waypoints == 0 then return end
	net.Start "Decent Vehicle: Retrive waypoints"
	WriteWaypoint(1)
	net.Broadcast()
end

util.AddNetworkString "Decent Vehicle: Add a waypoint"
util.AddNetworkString "Decent Vehicle: Remove a waypoint"
util.AddNetworkString "Decent Vehicle: Add a neighbor"
util.AddNetworkString "Decent Vehicle: Remove a neighbor"
util.AddNetworkString "Decent Vehicle: Traffic light"
util.AddNetworkString "Decent Vehicle: Retrive waypoints"
util.AddNetworkString "Decent Vehicle: Send waypoint info"
util.AddNetworkString "Decent Vehicle: Clear waypoints"
util.AddNetworkString "Decent Vehicle: Save and restore"
hook.Add("PostCleanupMap", "Decent Vehicle: Clean up waypoints", function()
	dvd.Waypoints = {}
	ClearUndoList()
end)

hook.Add("InitPostEntity", "Decent Vehicle: Load waypoints", function()
	dvd.SaveEntity = ents.Create "env_dv_save"
	dvd.SaveEntity:Spawn()
end)

hook.Add("Tick", "Decent Vehicle: Control traffic lights", function()
	for PatternName, TL in pairs(dvd.TrafficLights) do
		if CurTime() < TL.Time then continue end
		TL.Light = TL.Light % 3 + 1
		TL.Time = CurTime() + dvd.TLDuration[TL.Light]
	end
end)

concommand.Add("dv_route_save", function(ply) ConfirmSaveRestore(ply, dvd.POPUPWINDOW.SAVE) end)
concommand.Add("dv_route_load", function(ply) ConfirmSaveRestore(ply, dvd.POPUPWINDOW.LOAD) end)
concommand.Add("dv_route_delete", function(ply) ConfirmSaveRestore(ply, dvd.POPUPWINDOW.DELETE) end)
concommand.Add("dv_route_generate", function(ply) ConfirmSaveRestore(ply, dvd.POPUPWINDOW.GENERATE) end)
saverestore.AddSaveHook("Decent Vehicle", function(save)
	saverestore.WriteTable(dvd.GetSaveTable(), save)
end)

saverestore.AddRestoreHook("Decent Vehicle", function(restore)
	OverwriteWaypoints(saverestore.ReadTable(restore))
	for id, undolist in pairs(undo.GetTable()) do
		for i, undotable in pairs(undolist) do
			if undotable.Name ~= "Decent Vehicle Waypoint" then continue end
			undolist[i].Functions[1] = {dvd.UndoWaypoint, {}}
		end
	end
end)

duplicator.RegisterEntityModifier("Decent Vehicle: Save waypoints", function(ply, ent, data)
	OverwriteWaypoints(data)
	dvd.SaveEntity = ent
end)

net.Receive("Decent Vehicle: Retrive waypoints", function(_, ply)
	local id = net.ReadUInt(24)
	net.Start "Decent Vehicle: Retrive waypoints"
	if id > #dvd.Waypoints then
		net.WriteUInt(0, 24)
		net.Send(ply)
		return
	end
	
	WriteWaypoint(id)
	net.Send(ply)
end)

net.Receive("Decent Vehicle: Send waypoint info", function(_, ply)
	local id = net.ReadUInt(24)
	local waypoint = dvd.Waypoints[id]
	if not waypoint then return end
	net.Start "Decent Vehicle: Send waypoint info"
	net.WriteUInt(id, 24)
	net.WriteUInt(waypoint.Group, 16)
	net.WriteFloat(waypoint.SpeedLimit)
	net.WriteFloat(waypoint.WaitUntilNext)
	net.WriteBool(waypoint.UseTurnLights)
	net.WriteBool(waypoint.FuelStation)
	net.Send(ply)
end)

net.Receive("Decent Vehicle: Save and restore", function(_, ply)
	if not ply:IsAdmin() then return end
	local save = net.ReadUInt(dvd.POPUPWINDOW.BITS)
	local dir = "decentvehicle/"
	local path = dir .. game.GetMap()
	local pngpath = "data/" .. path .. ".png"
	local txtpath = "data/" .. path .. ".txt"
	local scriptpath = "scripts/vehicles/" .. path .. ".txt"
	if save == dvd.POPUPWINDOW.SAVE then
		if not file.Exists(dir, "DATA") then file.CreateDir(dir) end
		file.Write(path .. ".txt", util.Compress(util.TableToJSON(dvd.GetSaveTable())))
	elseif save == dvd.POPUPWINDOW.LOAD then
		if file.Exists(txtpath, "GAME") then
			OverwriteWaypoints(util.JSONToTable(util.Decompress(file.Read(txtpath, "GAME") or "")))
		elseif file.Exists(scriptpath, "GAME") then
			OverwriteWaypoints(util.JSONToTable(util.Decompress(file.Read(scriptpath, "GAME") or "")))
		elseif file.Exists(pngpath, "GAME") then -- Backward compatibility
			OverwriteWaypoints(util.JSONToTable(util.Decompress(file.Read(pngpath, "GAME") or "")))
		end
	elseif save == dvd.POPUPWINDOW.DELETE then
		file.Delete(path .. ".png")
		file.Delete(path .. ".txt")
	elseif save == dvd.POPUPWINDOW.GENERATE then
		GenerateWaypoints()
	end
end)

-- Gets a table that contains all waypoints information.
-- Returns:
--   table save		| A table for saving waypoints.
function dvd.GetSaveTable()
	local save = {TrafficLights = {}}
	for i, w in ipairs(dvd.Waypoints) do
		save[i] = table.Copy(w)
		save[i].TrafficLight = nil
	end
	
	for i, t in ipairs(ents.GetAll()) do
		if not t.IsDVTrafficLight then continue end
		if not istable(t.Waypoints) then continue end
		table.insert(save.TrafficLights, {
			Waypoints = table.Copy(t.Waypoints),
			Pattern = t:GetPattern(),
			Pos = t:GetPos(),
			Ang = t:GetAngles(),
			ClassName = t:GetClass(),
		})
	end
	
	save.DriveSide = dvd.DriveSide
	hook.Run("Decent Vehicle: OnSaveWaypoints", save)
	return save
end

-- Creates a new waypoint at given position.
-- The new ID is always #dvd.Waypoints.
-- Argument:
--   Vector pos		| The position of new waypoint.
-- Returns:
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
			return
		end
	end
end

-- Gets all fuel station points in the map.
-- Returns:
--   table fuelstations	| A sequential table contains all fuel stations.
--   table fuelIDs		| A sequential table contains all IDs of fuel station.
function dvd.GetFuelStations()
	local fuelstations, fuelIDs = {}, {}
	for i, w in ipairs(dvd.Waypoints) do
		if not w.FuelStation then continue end
		table.insert(fuelstations, w)
		table.insert(fuelIDs, i)
	end
	
	return fuelstations, fuelIDs
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

-- Checks if the given waypoint is available for the specified group.
-- Arguments:
--   number id		| The waypoint ID.
--   number group	| Waypoint group to check.
function dvd.WaypointAvailable(id, group)
	local waypoint = GetWaypointFromID(id)
	return waypoint.Group == 0 or waypoint.Group == group
end

-- Adds a link between a waypoint and a traffic light entity.
-- Arguments:
--   number id		| The waypoint ID.
--   Entity traffic	| The traffic light entity.  Giving nil to remove the link.
function dvd.AddTrafficLight(id, traffic)
	local waypoint = GetWaypointFromID(id)
	if not IsValid(traffic) then traffic = nil end
	if traffic then
		if not traffic.IsDVTrafficLight then return end
		if waypoint.TrafficLight ~= traffic then
			table.insert(traffic.Waypoints, id)
			if IsValid(waypoint.TrafficLight) then
				table.RemoveByValue(waypoint.TrafficLight.Waypoints, id)
			end
		else
			table.RemoveByValue(traffic.Waypoints, id)
			traffic = nil
		end
	end
	
	waypoint.TrafficLight = traffic
	net.Start "Decent Vehicle: Traffic light"
	net.WriteUInt(id, 24)
	net.WriteEntity(traffic or NULL)
	net.Broadcast()
end

-- Gets a waypoint connected from the given randomly.
-- Argument:
--   table waypoint		| The given waypoint.
--   function filter	| If specified, removes waypoints which make it return false.
-- Returns:
--   table waypoint | The connected waypoint.
function dvd.GetRandomNeighbor(waypoint, filter)
	if not waypoint.Neighbors then return end
	
	local suggestion = {}
	for i, n in ipairs(waypoint.Neighbors) do
		local w = GetWaypointFromID(n)
		if not w then continue end
		if not (isfunction(filter) and filter(waypoint, n)) then continue end
		table.insert(suggestion, w)
	end
	
	return suggestion[math.random(#suggestion)]
end

-- Retrives a table of waypoints that represents the route
-- from start to one of the destination in endpos.
-- Using A* pathfinding algorithm.
-- Arguments:
--   number start	| The beginning waypoint ID.
--   table endpos	| A table of destination waypoint IDs. {[ID] = true}
--   number group	| Optional, specify a waypoint group here.
-- Returns:
--   table route	| List of waypoints.  start is the last, endpos is the first.
function dvd.GetRoute(start, endpos, group)
	if not (isnumber(start) and istable(endpos)) then return end
	group = group or 0
	
	local nodes, opens = {}, {}
	local function CreateNode(id)
		nodes[id] = {
			estimate = 0,
			closed = nil,
			cost = 0,
			id = id,
			parent = nil,
			score = 0,
		}
		
		return nodes[id]
	end
	
	local function EstimateCost(node)
		node = GetWaypointFromID(node.id).Target
		local cost = math.huge
		for id in pairs(endpos) do
			cost = math.min(cost, node:Distance(GetWaypointFromID(id).Target))
		end
		
		return cost
	end
	
	local function AddToOpenList(node, parent)
		if parent then
			local nodepos = GetWaypointFromID(node.id).Target
			local parentpos = GetWaypointFromID(parent.id).Target
			local cost = parentpos:Distance(nodepos)
			local grandpa = parent.parent
			if grandpa then -- Angle between waypoints is considered as cost
				local gppos = GetWaypointFromID(grandpa.id).Target
				cost = cost --* (2 - dvd.GetAng3(gppos, parentpos, nodepos))
			end
			
			node.cost = parent.cost + cost
		end
		
		node.closed = false
		node.estimate = EstimateCost(node)
		node.parent = parent
		node.score = node.estimate + node.cost
		
		-- Open list is binary heap
		table.insert(opens, node.id)
		local i = #opens
		local p = math.floor(i / 2)
		while i > 0 and p > 0 and nodes[opens[i]].score < nodes[opens[p]].score do
			opens[i], opens[p] = opens[p], opens[i]
			i, p = p, math.floor(p / 2)
		end
	end
	
	start = CreateNode(start)
	for id in pairs(endpos) do
		endpos[id] = CreateNode(id)
	end
	
	AddToOpenList(start)
	while #opens > 0 do
		local current = opens[1] -- Pop a node which has minimum cost.
		opens[1] = opens[#opens]
		opens[#opens] = nil
		
		local i = 1 -- Down-heap on the open list
		while i <= #opens do
			local c = i * 2
			if not opens[c] then break end
			c = c + (opens[c + 1] and nodes[opens[c]].score > nodes[opens[c + 1]].score and 1 or 0)
			if nodes[opens[c]].score >= nodes[opens[i]].score then break end
			opens[i], opens[c] = opens[c], opens[i]
			i = c
		end
		
		if nodes[current].closed then continue end
		if endpos[current] then
			current = nodes[current]
			local route = {}
			while current.parent do
				debugoverlay.Sphere(GetWaypointFromID(current.id).Target, 30, 5, Color(0, 255, 0))
				debugoverlay.SweptBox(GetWaypointFromID(current.parent.id).Target, GetWaypointFromID(current.id).Target, Vector(-10, -10, -10), Vector(10, 10, 10), angle_zero, 5, Color(0, 255, 0))
				table.insert(route, (GetWaypointFromID(current.id)))
				current = current.parent
			end
			
			return route
		end
		
		nodes[current].closed = true
		for i, n in ipairs(GetWaypointFromID(nodes[current].id).Neighbors) do
			if nodes[n] and nodes[n].closed ~= nil then continue end
			if not dvd.WaypointAvailable(n, group) then continue end
			AddToOpenList(nodes[n] or CreateNode(n), nodes[current])
		end
	end
end

-- Retrives a table of waypoints that represents the route
-- from start to one of the destination in endpos.
-- Arguments:
--   Vector start	| The beginning position.
--   table endpos	| A table of Vectors that represent destinations.  Can also be a Vector.
--   number group	| Optional, specify a waypoint group here.
-- Returns:
--   table route	| The same as returning value of dvd.GetRoute()
function dvd.GetRouteVector(start, endpos, group)
	if isvector(endpos) then endpos = {endpos} end
	if not (isvector(start) and istable(endpos)) then return end
	local endpostable = {}
	for _, p in ipairs(endpos) do
		local id = select(2, dvd.GetNearestWaypoint(p))
		if not id then continue end
		endpostable[id] = true
	end
	
	return dvd.GetRoute(select(2, dvd.GetNearestWaypoint(start)), endpostable, group)
end

hook.Run "Decent Vehicle: PostInitialize"
