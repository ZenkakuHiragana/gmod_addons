
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
