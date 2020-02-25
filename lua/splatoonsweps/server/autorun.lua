
-- Serverside SplatoonSWEPs structure

SplatoonSWEPs = SplatoonSWEPs or {
	AreaBound = 0,
	AspectSum = 0,
	AspectSumX = 0,
	AspectSumY = 0,
	CrosshairColors = {},
	LastHitID = {},
	NoCollide = {},
	NumInkEntities = 0,
	InkColors = {},
	InkQueue = {},
	InkShotMaterials = {},
	PaintSchedule = {},
	PlayerHullChanged = {},
	PlayerID = {},
	PlayerShouldResetCamera = {},
	PlayersReady = {},
	RenderTarget = {},
	WeaponRecord = {},
}

include "splatoonsweps/const.lua"
include "splatoonsweps/shared.lua"
include "network.lua"
include "bsp.lua"

local ss = SplatoonSWEPs
if not ss.GetOption "enabled" then
	for h, t in pairs(hook.GetTable()) do
		for name, func in pairs(t) do
			if ss.ProtectedCall(name.find, name, "SplatoonSWEPs") then
				hook.Remove(h, name)
			end
		end
	end

	table.Empty(SplatoonSWEPs)
	SplatoonSWEPs = nil
	return
end

concommand.Add("sv_splatoonsweps_clear", function(ply, cmd, args, argstr)
	if not IsValid(ply) and game.IsDedicated() or IsValid(ply) and ply:IsAdmin() then
		ss.ClearAllInk()
	end
end, nil, ss.Text.CVars.Clear, FCVAR_SERVER_CAN_EXECUTE)

-- Clears all ink in the world.
-- Sends a net message to clear ink on clientside.
function ss.ClearAllInk()
	net.Start "SplatoonSWEPs: Send ink cleanup"
	net.Send(ss.PlayersReady)
	table.Empty(ss.InkQueue)
	table.Empty(ss.PaintSchedule)
	for _, s in ipairs(ss.SurfaceArray) do
		for i, v in pairs(s.InkSurfaces) do
			table.Empty(v)
		end
	end

	collectgarbage "collect"
end

-- Calls notification.AddLegacy serverside.
-- Arguments:
--   string msg			| The message to display.
--   Player user		| The receiver.
--   number icon		| Notification icon.  Note that NOTIFY_Enums are only in clientside.
--   number duration	| The number of seconds to display the notification for.
function ss.SendError(msg, user, icon, duration)
	if IsValid(user) and not user:IsPlayer() then return end
	if not user and player.GetCount() == 0 then return end
	net.Start "SplatoonSWEPs: Send an error message"
	net.WriteUInt(icon or 1, ss.SEND_ERROR_NOTIFY_BITS)
	net.WriteUInt(duration or 8, ss.SEND_ERROR_DURATION_BITS)
	net.WriteString(msg)
	if user then
		net.Send(user)
	else
		net.Broadcast()
	end
end

-- Gets an ink color for the given NPC, considering its faction.
-- Argument:
--   Entity n			| The NPC
-- Returnings:
--   number color		| The ink color for the given NPC.
local NPCFactions = {
	[CLASS_NONE] = "others",
	[CLASS_PLAYER] = "player",
	[CLASS_PLAYER_ALLY] = "citizen",
	[CLASS_PLAYER_ALLY_VITAL] = "citizen",
	[CLASS_ANTLION] = "antlion",
	[CLASS_BARNACLE] = "barnacle",
	[CLASS_BULLSEYE] = "others",
	[CLASS_CITIZEN_PASSIVE] = "citizen",
	[CLASS_CITIZEN_REBEL] = "citizen",
	[CLASS_COMBINE] = "combine",
	[CLASS_COMBINE_GUNSHIP] = "combine",
	[CLASS_CONSCRIPT] = "others",
	[CLASS_HEADCRAB] = "zombie",
	[CLASS_MANHACK] = "combine",
	[CLASS_METROPOLICE] = "combine",
	[CLASS_MILITARY] = "military",
	[CLASS_SCANNER] = "combine",
	[CLASS_STALKER] = "combine",
	[CLASS_VORTIGAUNT] = "citizen",
	[CLASS_ZOMBIE] = "zombie",
	[CLASS_PROTOSNIPER] = "combine",
	[CLASS_MISSILE] = "others",
	[CLASS_FLARE] = "others",
	[CLASS_EARTH_FAUNA] = "others",
	[CLASS_HACKED_ROLLERMINE] = "citizen",
	[CLASS_COMBINE_HUNTER] = "combine",
	[CLASS_MACHINE] = "military",
	[CLASS_HUMAN_PASSIVE] = "citizen",
	[CLASS_HUMAN_MILITARY] = "military",
	[CLASS_ALIEN_MILITARY] = "alien",
	[CLASS_ALIEN_MONSTER] = "alien",
	[CLASS_ALIEN_PREY] = "zombie",
	[CLASS_ALIEN_PREDATOR] = "alien",
	[CLASS_INSECT] = "others",
	[CLASS_PLAYER_BIOWEAPON] = "player",
	[CLASS_ALIEN_BIOWEAPON] = "alien",
}
function ss.GetNPCInkColor(n)
	if not IsValid(n) then return 1 end
	if not isfunction(n.Classify) then
		return n.SplatoonSWEPsInkColor or 1
	end

	local class = n:Classify()
	local cvar = ss.GetOption "npcinkcolor"
	local colors = {
		citizen = cvar "citizen",
		combine = cvar "combine",
		military = cvar "military",
		zombie = cvar "zombie",
		antlion = cvar "antlion",
		alien = cvar "alien",
		barnacle = cvar "barnacle",
		player = ss.GetOption "inkcolor",
		others = cvar "others",
	}
	return colors[NPCFactions[class]] or colors.others or 1
end

function ss.GetFallDamage(self, ply, speed)
	if ss.GetOption "takefalldamage" then return end
	return 0
end

-- Parse the map and store the result to txt, then send it to the client.
hook.Add("PostCleanupMap", "SplatoonSWEPs: Cleanup all ink", ss.ClearAllInk)
hook.Add("InitPostEntity", "SplatoonSWEPs: Serverside Initialization", function()
	local path = ("splatoonsweps/%s.txt"):format(game.GetMap())
	local pathbsp = ("maps/%s.bsp"):format(game.GetMap())
	local data = util.JSONToTable(file.Read(path) or "") or {}
	local mapCRC = tonumber(util.CRC(file.Read(pathbsp, true)))
	if not file.Exists("splatoonsweps", "DATA") then file.CreateDir "splatoonsweps" end
	if data.MapCRC ~= mapCRC then
		include "splatoonsweps/server/buildsurfaces.lua"
		data.MapCRC = mapCRC
		data.AABBTree = ss.AvoidJSONLimit(ss.AABBTree)
		data.SurfaceArray = ss.AvoidJSONLimit(ss.SurfaceArray)
		data.UVInfo = {
			AreaBound = ss.AreaBound,
			AspectSum = ss.AspectSum,
			AspectSumX = ss.AspectSumX,
			AspectSumY = ss.AspectSumY,
		}

		file.Write(path, util.Compress(util.TableToJSON(data)))
	else
		ss.AABBTree = ss.RestoreJSONLimit(data.AABBTree)
		ss.SurfaceArray = ss.RestoreJSONLimit(data.SurfaceArray)
	end

	-- This is needed due to a really annoying bug (GitHub/garrysmod-issues #1495)
	SetGlobalBool("SplatoonSWEPs: IsDedicated", game.IsDedicated())
	SetGlobalString("SplatoonSWEPs: Ink map CRC", util.CRC(file.Read(path))) -- CRC check clientside
	resource.AddSingleFile("data/" .. path)
end)

hook.Add("PlayerInitialSpawn", "SplatoonSWEPs: Add a player", function(ply)
	if ply:IsBot() then return end
	ss.ClearAllInk()
	ss.InitializeMoveEmulation(ply)
end)

hook.Add("PlayerAuthed", "SplatoonSWEPs: Store player ID", function(ply, id)
	if ss.IsGameInProgress then
		ply:Kick "Splatoon SWEPs: The game is in progress"
		return
	end

	ss.PlayerID[ply] = id
end)

local function SavePlayerData(ply)
	ss.tableremovefunc(ss.PlayersReady, function(v) return v == ply end)
	if not ss.WeaponRecord[ply] then return end
	local id = ss.PlayerID[ply]
	if not id then return end
	local record = "splatoonsweps/record/" .. id .. ".txt"
	if not file.Exists("data/splatoonsweps/record", "GAME") then
		file.CreateDir "splatoonsweps/record"
	end
	file.Write(record, util.TableToJSON(ss.WeaponRecord[ply], true))

	ss.PlayerID[ply] = nil
	ss.WeaponRecord[ply] = nil
end

hook.Add("PlayerDisconnected", "SplatoonSWEPs: Reset player's readiness", SavePlayerData)
hook.Add("ShutDown", "SplatoonSWEPs: Save player data", function()
	for k, v in ipairs(player.GetAll()) do
		SavePlayerData(v)
	end
end)

hook.Add("GetFallDamage", "SplatoonSWEPs: Inklings don't take fall damage.", ss.hook "GetFallDamage")
hook.Add("EntityTakeDamage", "SplatoonSWEPs: Ink damage manager", function(ent, dmg)
	if ent:Health() <= 0 then return end
	local w = ss.IsValidInkling(ent)
	local a = dmg:GetAttacker()
	local i = dmg:GetInflictor()
	if w then w.HealSchedule:SetDelay(ss.HealDelay) end
	if not (IsValid(a) and i.IsSplatoonWeapon) then return end
	if ss.IsAlly(w, i) then return true end
	if not ent:IsPlayer() then return end
	net.Start "SplatoonSWEPs: Play damage sound"
	net.Send(ent)
end)
