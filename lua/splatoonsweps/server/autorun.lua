
-- Serverside SplatoonSWEPs structure

SplatoonSWEPs = SplatoonSWEPs or {
	AreaBound = 0,
	AspectSum = 0,
	AspectSumX = 0,
	AspectSumY = 0,
	BSP = {},
	CrosshairColors = {},
	Displacements = {},
	Models = {},
	NoCollide = {},
	NumInkEntities = 0,
	InkColors = {},
	InkQueue = {},
	InkShotMaterials = {},
	PaintSchedule = {},
	PlayerHullChanged = {},
	PlayerID = {},
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

	ss.InkQueue, ss.PaintSchedule = {}, {}
	for node in ss.BSPPairsAll() do
		for i = 1, #node.Surfaces.InkCircles do
			node.Surfaces.InkCircles[i] = {}
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
function ss.GetNPCInkColor(n)
	if not IsValid(n) then return 1 end
	return 1
end

-- Parse the map and store the result to txt, then send it to the client.
hook.Add("PostCleanupMap", "SplatoonSWEPs: Cleanup all ink", ss.ClearAllInk)
hook.Add("InitPostEntity", "SplatoonSWEPs: Serverside Initialization", function()
	-- This needs due to a really annoying bug (GitHub/garrysmod-issues #1495)
	SetGlobalBool("SplatoonSWEPs: IsDedicated", game.IsDedicated())

	ss.BSP:Init() --Parse the map
	ss.BSP = nil
	collectgarbage "collect"
	local path = string.format("splatoonsweps/%s.txt", game.GetMap())
	local data = file.Open(path, "rb", "DATA")
	local mapCRC = tonumber(util.CRC(file.Read(string.format("maps/%s.bsp", game.GetMap()), true) or "")) or 0
	if not file.Exists("splatoonsweps", "DATA") then file.CreateDir "splatoonsweps" end
	if not data or data:Size() < 4 or data:ReadULong() ~= mapCRC then --First 4 bytes are map CRC.
		file.Write(path, "") --Create an empty file
		if data then data:Close() end
		data = file.Open(path, "wb", "DATA")
		data:WriteULong(ss.NumSurfaces)
		data:WriteUShort(table.Count(ss.Displacements))
		data:WriteDouble(ss.AreaBound)
		data:WriteDouble(ss.AspectSum)
		data:WriteDouble(ss.AspectSumX)
		data:WriteDouble(ss.AspectSumY)
		for node in ss.BSPPairsAll() do
			local surf = node.Surfaces
			for i, index in ipairs(surf.Indices) do
				data:WriteULong(math.abs(index))
				data:WriteFloat(surf.Angles[i].pitch)
				data:WriteFloat(surf.Angles[i].yaw)
				data:WriteFloat(surf.Angles[i].roll)
				data:WriteFloat(surf.Areas[i])
				data:WriteFloat(surf.Bounds[i].x)
				data:WriteFloat(surf.Bounds[i].y)
				data:WriteFloat(surf.Bounds[i].z)
				data:WriteFloat(surf.Normals[i].x)
				data:WriteFloat(surf.Normals[i].y)
				data:WriteFloat(surf.Normals[i].z)
				data:WriteFloat(surf.Origins[i].x)
				data:WriteFloat(surf.Origins[i].y)
				data:WriteFloat(surf.Origins[i].z)
				data:WriteUShort(#surf.Vertices[i])
				for k, v in ipairs(surf.Vertices[i]) do
					data:WriteFloat(v.x)
					data:WriteFloat(v.y)
					data:WriteFloat(v.z)
				end
			end
		end

		for i, disp in pairs(ss.Displacements) do
			local power = math.log(math.sqrt(#disp + 1) - 1, 2) - 1 --1, 2, 3

			data:WriteUShort(i)
			data:WriteByte(power)
			data:WriteUShort(#disp)
			for k = 0, #disp do
				local v = disp[k]
				data:WriteFloat(v.pos.x)
				data:WriteFloat(v.pos.y)
				data:WriteFloat(v.pos.z)
				data:WriteFloat(v.vec.x)
				data:WriteFloat(v.vec.y)
				data:WriteFloat(v.vec.z)
				data:WriteFloat(v.dist)
			end
		end

		data:Close() --data = map info converted into binary data
		local write = util.Compress(file.Read(path)) --write = compressed data
		file.Delete(path) --Remove the file temporarily
		file.Write(path, "") --Create an empty file again
		data = file.Open(path, "wb", "DATA")
		data:WriteULong(mapCRC)
		for c in write:gmatch "." do data:WriteByte(c:byte()) end
		data:Close() --data = map CRC + compressed data
	end

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
	table.RemoveByValue(ss.PlayersReady, ply)
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

hook.Add("GetFallDamage", "SplatoonSWEPs: Inklings don't take fall damage.", function(ply, speed)
	return ss.IsValidInkling(ply) and 0 or nil
end)

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
