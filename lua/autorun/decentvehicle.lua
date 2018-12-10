
AddCSLuaFile()
DecentVehicleDestination = DecentVehicleDestination or {
	PID = {
		Throttle = {},
		Steering = {},
	},
	TLDuration = {33, 4, 40 + 3}, -- Sign duration of each light color, Green, Yellow, Red.
	TrafficLights = {
		{Time = CurTime() + 33, Light = 1}, -- Light pattern #1
		{Time = CurTime() + 40, Light = 3}, -- Light pattern #2
	},
	Version = {1, 0, 0},
	Waypoints = {},
	WaypointSize = 32,
}

-- Gets direction vector from v1 to v2.
-- Arguments:
--   Vector v1	| The beginning point.
--   Vector v2	| The ending point.
-- Returns:
--   Vector dir	| Normalized vector of v2 - v1.
local dvd = DecentVehicleDestination
function dvd.GetDir(v1, v2)
	return (v2 - v1):GetNormalized()
end

-- Gets angle between vector A and B.
-- Arguments:
--   Vector A	| The first vector.
--   Vector B	| The second vector.
-- Returns:
--   number ang	| The angle of two vectors.  The actual angle is math.acos(ang).
function dvd.GetAng(A, B)
	return A:GetNormalized():Dot(B:GetNormalized())
end

-- Gets angle between vector AB and BC.
-- Arguments:
--   Vector A	| The beginning point.
--   Vector B	| The middle point.
--   Vector C	| The ending point.
-- Returns:
--   number ang	| The same as dvd.GetAng()
function dvd.GetAng3(A, B, C)
	return dvd.GetAng(B - A, C - B)
end

-- Retrives the nearest waypoint to the given position.
-- Arguments:
--   Vector pos			| The position to find.
--   number radius		| Optional.  The maximum radius.
-- Returns:
--   table waypoint		| The found waypoint.  Can be nil.
--   number waypointID	| The ID of found waypoint.
function dvd.GetNearestWaypoint(pos, radius)
	if not isvector(pos) then return end
	local mindist, waypoint, waypointID = (radius or math.huge)^2
	for i, w in ipairs(dvd.Waypoints) do
		local distance = w.Target:DistToSqr(pos)
		if distance < mindist then
			mindist, waypoint, waypointID = distance, w, i
		end
	end
	
	return waypoint, waypointID
end
