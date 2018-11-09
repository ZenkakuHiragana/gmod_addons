
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

local Height = vector_up * dvd.WaypointSize / 4
local WaypointMaterial = Material "sprites/sent_ball"
local LinkMaterial = Material "cable/blue_elec"
hook.Add("PostDrawTranslucentRenderables", "Decent Vehicle: Draw waypoints",
function(bDrawingDepth, bDrawingSkybox)
	if bDrawingSkybox or not GetConVar "dv_route_showpoints":GetBool() then return end
	for _, w in ipairs(dvd.Waypoints) do
		render.SetMaterial(WaypointMaterial)
		render.DrawSprite(w.Target + Height, dvd.WaypointSize, dvd.WaypointSize, color_white)
		render.SetMaterial(LinkMaterial)
		for _, n in ipairs(w.Neighbors) do
			local pos = dvd.Waypoints[n].Target
			local tex = w.Target:Distance(pos) / 100
			render.StartBeam(2)
			render.AddBeam(w.Target + Height, 20, 1 - CurTime() % 1, color_white)
			render.AddBeam(pos + Height, 20, 1 - CurTime() % 1 + tex, color_white)
			render.EndBeam()
		end
	end
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
