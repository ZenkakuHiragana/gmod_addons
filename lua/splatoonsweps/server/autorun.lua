
-- Serverside SplatoonSWEPs structure

SplatoonSWEPs = SplatoonSWEPs or {
	AreaBound = 0,
	AspectSum = 0,
	AspectSumX = 0,
	AspectSumY = 0,
	BSP = {},
	Displacements = {},
	Models = {},
	NoCollide = {},
	NumInkEntities = 0,
	InkCounter = 0,
	InkQueue = {},
	InkShotMaterials = {},
	PlayerHullChanged = {},
	PlayersReady = {},
}

include "bsp.lua"
include "splatoonsweps/const.lua"
include "inkmanager.lua"
include "network.lua"
include "splatoonsweps/shared.lua"
include "splatoonsweps/text.lua"

local ss = SplatoonSWEPs
local CVarFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
local CVarEnabled = CreateConVar("sv_splatoonsweps_enabled", "1", CVarFlags, ss.Text.CVarDescription.Enabled)
if CVarEnabled and not CVarEnabled:GetBool() then SplatoonSWEPs = nil return end
CreateConVar("sv_splatoonsweps_ff", "0", CVarFlags, ss.Text.CVarDescription.FF)
concommand.Add("sv_splatoonsweps_clear", function(ply, cmd, args, argstr)
	if not IsValid(ply) and game.IsDedicated() or IsValid(ply) and ply:IsAdmin() then
		ss.ClearAllInk()
	end
end, nil, ss.Text.CVarDescription.Clear, FCVAR_SERVER_CAN_EXECUTE)

-- Clears all ink in the world.
-- Sends a net message to clear ink on clientside.
function ss.ClearAllInk()
	net.Start "SplatoonSWEPs: Send ink cleanup"
	net.Send(ss.PlayersReady)
	
	ss.InkCounter, ss.InkQueue = 0, {}
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
	if user and not user:IsPlayer() then return end
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

-- Parse the map and store the result to txt, then send it to the client.
hook.Add("PostCleanupMap", "SplatoonSWEPs: Cleanup all ink", ss.ClearAllInk)
hook.Add("InitPostEntity", "SplatoonSWEPs: Serverside Initialization", function()
	ss.BSP:Init() --Parse the map
	ss.BSP = nil
	collectgarbage "collect"
	local path = "splatoonsweps/" .. game.GetMap() .. ".txt"
	local data = file.Open(path, "rb", "DATA")
	local mapCRC = tonumber(util.CRC(file.Read("maps/" .. game.GetMap() .. ".bsp", true) or "")) or 0
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
			if power ~= math.floor(power) then
				ErrorNoHalt "SplatoonSWEPs: Displacement power isn't an integer!"
				continue
			end
			
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

hook.Add("PlayerDisconnected", "SplatoonSWEPs: Reset player's readiness", function(ply)
	table.RemoveByValue(ss.PlayersReady, ply)
end)

hook.Add("GetFallDamage", "SplatoonSWEPs: Inklings don't take fall damage.", function(ply, speed)
	return ss.IsValidInkling(ply) and 0 or nil
end)

hook.Add("EntityTakeDamage", "SplatoonSWEPs: Ink damage manager", function(ent, dmg)
	if ent:Health() <= 0 then return end
	local entweapon = ss.IsValidInkling(ent)
	if not entweapon then return end
	local atk = dmg:GetAttacker()
	local inf = dmg:GetInflictor()
	if not (IsValid(atk) and inf.IsSplatoonWeapon) then return end
	if ss.IsAlly(entweapon, inf) then return true end
	entweapon.HealSchedule:SetDelay(45 * ss.FrameToSec)
	if ent:IsPlayer() then
		net.Start "SplatoonSWEPs: Play damage sound"
		net.Send(ent)
	end
end)
