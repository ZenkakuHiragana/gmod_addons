
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

return {
	CVars = {
		AutoLoad = "Decent Vehicle: Whether or not Decent Vehicle automatically loads waypoints on startup.",
		DetectionRange = "Decent Vehicle: A vehicle within this distance will drive automatically.",
		DetectionRangeELS = "Decent Vehicle: Detection range of finding cars with ELS to give way.",
		DriveSide = [[Decent Vehicle: Determines which side of road Decent Vehicles think.
0: Right (Europe, America, etc.)
1: Left (UK, Australia, etc.)]],
		ForceHeadlights = "Decent Vehicle: Forces Decent Vehicle to enable headlights.",
		LockVehicle = "Decent Vehicle: Whether or not Decent Vehicle prevents players from getting in.",
		ShouldGoToRefuel = "Decent Vehicle: 1: Go to a fuel station to refuel.  0: Refuel automatically.",
		TimeToStopEmergency = "Decent Vehicle: Time to turn off hazard lights in seconds.",
		TurnOnLights = [[Decent Vehicle: The level of using lights.
0: Disabled
1: Only use running lights
2: Use running lights and headlights
3: Use all lights]],
	},
	DeletedWaypoints = "Decent Vehicle: Waypoints are deleted!",
	Errors = {
		AttachmentNotFound = "Decent Vehicle: attachment vehicle_feet_passenger0 is not found!",
		WaypointNotFound = "Decent Vehicle: Waypoint is not found!",
	},
	GeneratedWaypoints = "Decent Vehicle: Waypoints are generated!",
	LoadedWaypoints = "Decent Vehicle: Waypoints are restored!",
	OldVersionNotify = "Decent Vehicle: This is an old version.  Check for updates!",
	OnDelete = "You are about to DELETE the waypoints.",
	OnGenerate = "You are about to GENERATE the waypoints.",
	OnLoad = "You are about to LOAD the waypoints.",
	OnSave = "You are about to SAVE the waypoints.",
	SavedWaypoints = "Decent Vehicle: Waypoints are saved!",
	SaveLoad_Cancel = "Cancel",
	SaveLoad_OK = "OK",
	Tools = {
		AlwaysDrawWaypoints = "Always draw waypoints",
		AutoLoad = "Load waypoints on startup",
		AutoLoadHelp = "If checked, Decent Vehicle will automatically load waypoints when the map is loaded.",
		Bidirectional = "Bi-directional link",
		BidirectionalHelp = "Connect bi-directional link automatically.",
		Category = "GreatZenkakuMan's tools",
		Delete = "Delete waypoints",
		Description = "Create your own routes for vehicles!",
		DescriptionInMenu = "Create routes for Decent Vehicles.",
		DetectionRange = "Detection range for spawning",
		DetectionRangeELS = "Detection range for finding cars with ELS",
		DrawDistance = "Draw distance",
		DrawDistanceHelp = "The maximum distance to draw waypoints.",
		DrawWaypoints = "Draw waypoints",
		DriveSide = "Is left side of the road",
		ForceHeadlights = "Force headlights",
		ForceHeadlightsHelp = "Forces Decent Vehicle to enable headlights.",
		FuelStation = "Fuel station",
		FuelStationHelp = "Decent Vehicles will go here to refuel its car.",
		Generate = "Generate waypoints",
		Instructions = "Select a waypoint or a traffic light to link.  Select a vehicle driven by a Decent Vehicle to assign its waypoint group.",
		Left = {
			"Create a new waypoint.",
			"Select another waypoint you want to link to.  Select the same waypoint to remove it.",
		},
		LightLevel = {
			All = "Full lights",
			Headlights = "Running lights and headlights",
			None = "No light",
			Running = "Only running lights",
			Title = "Light level",
		},
		LockVehicle = "Lock vehicle",
		LockVehicleHelp = "If checked, Decent Vehicle prevents other players from getting in.",
		MaxSpeed = "Max speed [km/h]",
		Name = "Decent Vehicle Waypoint Tool",
		PrintName = "Decent Vehicle Waypoint Tool",
		Restore = "Restore waypoints",
		Right = {"Update waypoint."},
		Save = "Save waypoints",
		ServerSettings = "Server settings",
		ShouldGoToRefuel = "Should go finding a fuel station",
		ShowInfo = {
			FuelStation = "Is fuel station: ",
			Group = "Group: ",
			ID = "ID: ",
			SpeedLimit = "Speed limit [km/h]: ",
			UseTurnLights = "Use turn lights: ",
			WaitUntilNext = "Wait until next [seconds]: ",
		},
		ShowUpdates = "Notify the latest updates",
		ShowUpdatesHelp = "If checked, some notifications are shown when this addon is updated.",
		UpdateRadius = "Update radius",
		UpdateRadiusHelp = "Waypoints in this radius will be updated at a time when you press E + Right click.",
		UseTurnLights = "Use turn signals",
		UseTurnLightsHelp = "Decent Vehicles will use turn signals when they go to the waypoint.",
		WaitTime = "Wait time [seconds]",
		WaitTimeHelp = "After Decent Vehicles reached the waypoint, they wait for this seconds.",
		WaypointGroup = "Waypoint group",
		WaypointGroupHelp = [[You can force Decent Vehicles to run along specified group of waypoints.
0 means all vehicles can go there.]],
	},
	UndoText = "Undone Decent Vehicle's waypoint",
	WireSupport = {
		ToolDesc = "Provides some data of Decent Vehicle's waypoints for use with the wire system.",
		ToolName = "[DV] Wire Waypoint Manager",
	},
}
