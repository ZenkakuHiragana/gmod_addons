
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
	Waypoints = {},
	WaypointSize = 20,
}

-- Get direction vector from v1 to v2.
-- Arguments:
--   Vector v1	| The beginning point.
--   Vector v2	| The ending point.
-- Returning:
--   Vector dir	| Normalized vector of v1 - v2.
local dvd = DecentVehicleDestination
function dvd.GetDir(v1, v2)
	return (v1 - v2):GetNormalized()
end

-- Get angle between vector A and B.
-- Arguments:
--   Vector A	| The first vector.
--   Vector B	| The second vector.
-- Returning:
--   number ang	| The angle of two vectors.  The actual angle is math.acos(ang).
function dvd.GetAng(A, B)
	return A:GetNormalized():Dot(B:GetNormalized())
end

-- Get angle between vector AB and BC.
-- Arguments:
--   Vector A	| The beginning point.
--   Vector B	| The middle point.
--   Vector C	| The ending point.
-- Returning:
--   number ang	| The same as dvd.GetAng()
function dvd.GetAng3(A, B, C)
	return dvd.GetAng(B - A, C - B)
end

local function AddVehicle(t, class)
	list.Set("Vehicles", class, t)
end

AddVehicle({
	-- Required information
	Name = "Jeep",
	Model = "models/buggy.mdl",
	Class = "prop_vehicle_jeep_old",
	Category = "Chairs",

	-- Optional information
	Author = "GreatZenkakuMan",
	Information = "Test for DV control",

	KeyValues = {vehiclescript = "jeep_dv.txt"}
}, "DV test")
