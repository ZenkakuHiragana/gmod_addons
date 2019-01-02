
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile()
DecentVehicleDestination = DecentVehicleDestination or {
	DriverAnimation = {
		["Source_models/airboat.mdl"] = "drive_airboat",
		["Source_models/sligwolf/motorbike/motorbike.mdl"] = "drive_airboat",
		["Source_models/sligwolf/tank/sw_tank_leo.mdl"] = "sit_rollercoaster",
		["SCAR_sent_sakarias_car_yamahayfz450"] = "drive_airboat",
		["Simfphys_models/monowheel.mdl"] = "drive_airboat",
	},
	DriveSide = 1,
	DRIVESIDE_LEFT = 1,
	DRIVESIDE_RIGHT = 0,
	DefaultDriverModel = {
		"models/player/group01/female_01.mdl",
		"models/player/group01/female_02.mdl",
		"models/player/group01/female_03.mdl",
		"models/player/group01/female_04.mdl",
		"models/player/group01/female_05.mdl",
		"models/player/group01/female_06.mdl",
		"models/player/group01/male_01.mdl",
		"models/player/group01/male_02.mdl",
		"models/player/group01/male_03.mdl",
		"models/player/group01/male_04.mdl",
		"models/player/group01/male_05.mdl",
		"models/player/group01/male_06.mdl",
		"models/player/group01/male_07.mdl",
		"models/player/group01/male_08.mdl",
		"models/player/group01/male_09.mdl",
		"models/player/group02/male_02.mdl",
		"models/player/group02/male_04.mdl",
		"models/player/group02/male_06.mdl",
		"models/player/group02/male_08.mdl",
		"models/player/group03/female_01.mdl",
		"models/player/group03/female_02.mdl",
		"models/player/group03/female_03.mdl",
		"models/player/group03/female_04.mdl",
		"models/player/group03/female_05.mdl",
		"models/player/group03/female_06.mdl",
		"models/player/group03/male_01.mdl",
		"models/player/group03/male_02.mdl",
		"models/player/group03/male_03.mdl",
		"models/player/group03/male_04.mdl",
		"models/player/group03/male_05.mdl",
		"models/player/group03/male_06.mdl",
		"models/player/group03/male_07.mdl",
		"models/player/group03/male_08.mdl",
		"models/player/group03/male_09.mdl",
	},
	PID = {
		Throttle = {},
		Steering = {},
	},
	SeatPos = {
		["Source_models/airboat.mdl"] = Vector(0, 0, -29),
		["Source_models/vehicle.mdl"] = Vector(-8, 0, -24),
		["Source_models/sligwolf/motorbike/motorbike.mdl"] = Vector(2, 0, -30),
		["Simfphys_"] = Vector(2, 0, -28),
	},
	TLDuration = {33, 4, 40 + 3}, -- Sign duration of each light color, Green, Yellow, Red.
	TrafficLights = {
		{Time = CurTime() + 33, Light = 1}, -- Light pattern #1
		{Time = CurTime() + 40, Light = 3}, -- Light pattern #2
	},
	Version = {1, 0, 3}, -- Major version, Minor version, Revision
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
--   number filter		| Optional.  The maximum radius.  Can also be a function.
-- Returns:
--   table waypoint		| The found waypoint.  Can be nil.
--   number waypointID	| The ID of found waypoint.
function dvd.GetNearestWaypoint(pos, filter)
	if not isvector(pos) then return end
	local r = not isfunction(filter) and filter or math.huge
	local mindistance, waypoint, waypointID = r^2
	for i, w in ipairs(dvd.Waypoints) do
		local distance = w.Target:DistToSqr(pos)
		if distance < mindistance and (not isfunction(filter)
		or filter(i, waypointID, mindistance)) then
			mindistance, waypoint, waypointID = distance, w, i
		end
	end
	
	return waypoint, waypointID
end

local lang = GetConVar "gmod_language":GetString()
local function ReadTexts(convar, old, new)
	dvd.Texts = {}
	
	local directories = select(2, file.Find("decentvehicle/*", "LUA"))
	for _, dir in ipairs(directories) do
		if SERVER then -- We need to run AddCSLuaFile() for all languages.
			local path = "decentvehicle/" .. dir .. "/"
			local files = file.Find(path .. "*.lua", "LUA")
			for _, f in ipairs(files) do
				AddCSLuaFile(path .. f)
			end
		end
		
		local path = "decentvehicle/" .. dir .. "/" .. new .. ".lua"
		local exists = file.Exists(path, "LUA")
		if exists then
			local text = include(path)
			for k, v in pairs(text or {}) do
				dvd.Texts[k] = v
			end
		end
		
		path = "decentvehicle/" .. dir .. "/en.lua"
		exists = file.Exists(path, "LUA")
		if exists then
			local text = include(path)
			for k, v in pairs(text or {}) do
				if dvd.Texts[k] then continue end
				dvd.Texts[k] = v
			end
		end
	end
end

ReadTexts("gmod_language", lang, lang)
cvars.AddChangeCallback("gmod_language", ReadTexts, "Decent Vehicle: OnLanguageChanged")
