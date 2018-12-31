
-- This is an example for adding your custom AI to Decent Vehicle.
local dvd = DecentVehicleDestination

AddCSLuaFile()
ENT.Base = "npc_decentvehicle"
ENT.PrintName = "Learning Vehicle (β)"
ENT.IsLearningVehicle = true -- Adding your identifier will be good.
ENT.Model = "models/player/gman_high.mdl" -- Your driver models here.
-- ENT.Model = { -- It can be a table of paths.  Decent Vehicle will select one of them.
	-- "path/to/model1.mdl",
	-- "path/to/model2.mdl",
-- }
ENT.Preference = { -- Some preferences for the behavior of the base AI.
	GiveWay = true,
	StopAtTL = true,
	DoTrace = true,
	LockVehicle = false,
	LockVehicleDependsOnCVar = true,
}

-- Uncomment this when you add it to the NPC list
-- list.Set("NPC", "npc_learningvehicle", {
	-- Name = ENT.PrintName,
	-- Class = "npc_learningvehicle",
	-- Category = "GreatZenkakuMan's NPCs",
-- })

if CLIENT then return end

-- Add your functions here
function ENT:DoSomething()
end

-- Override the base functions here
function ENT:DriveToWaypoint()
	do return self.BaseClass.DriveToWaypoint(self) end
end
