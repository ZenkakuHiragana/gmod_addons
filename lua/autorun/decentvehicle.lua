
-- This script stands for a framework of Decent Vehicle's waypoints.
local TestingOldway = true
if TestingOldway then
	hook.Add("Tick", "Decent Vehicle's destination", function()
		if not DecentVehicleDestination then return end
		debugoverlay.Cross(DecentVehicleDestination, 20, .1, Color(0, 255, 0), true)
		debugoverlay.Line(DecentVehicleDestination, DecentVehicleDestination + vector_up * 100, .1, Color(0, 255, 0), true)
	end)
	
	return
end

DecentVehicleDestination = DecentVehicleDestination or {
	Waypoints = {},
}

local dvd = DecentVehicleDestination
function dvd:AddWaypoint(pos)
	table.insert(dvd.Waypoints, {Target = pos})
end

function dvd:GetNearestWaypoint(pos)
	
end
