
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

local CvarEnabled = CreateConVar("sv_splatoonsweps_enabled",
"1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE},
SplatoonSWEPs.Text.CVarDescription.Enabled)
if CvarEnabled and not CvarEnabled:GetBool() then SplatoonSWEPs = nil return end
local collectgarbage, ipairs, pairs, ss = collectgarbage, ipairs, pairs, SplatoonSWEPs
for i = 1, 9 do
	local mask = {}
	local masktxt = file.Open("data/splatoonsweps/shot" .. tostring(i) .. ".txt", "rb", "GAME")
	mask.width = masktxt:ReadByte()
	mask.height = masktxt:ReadByte()
	for p = 1, mask.width * mask.height do
		mask[p] = masktxt:Read(1) == "1"
	end
	
	ss.InkShotMaterials[i] = mask
	masktxt:Close()
end

-- Arguments:
--   table vertices	| Vertices of face
--   Vector normal	| Normal of plane
--   number dist	| Distance from plane to origin
-- Returns:
--   Positive value | Face is in positive side of the plane
--   Negative value | Face is in negative side of the plane
--   0              | Face intersects with the plane
local PlaneThickness = 0.2
local function AcrossPlane(vertices, normal, dist)
	local sign
	for i, v in ipairs(vertices) do --for each vertices of face
		local dot = normal:Dot(v) - dist
		if math.abs(dot) > PlaneThickness then
			if sign and sign * dot < 0 then return 0 end
			sign = (sign or 0) + dot
		end
	end
	return sign or 0
end

-- Clears all ink in the world.
-- Sends a net message to clear ink on clientside.
function ss:ClearAllInk()
	net.Start "SplatoonSWEPs: Send ink cleanup"
	net.Send(ss.PlayersReady)
	
	ss.InkCounter, ss.InkQueue = 0, {}
	for node in ss:BSPPairsAll() do
		for i = 1, #node.Surfaces.InkCircles do
			node.Surfaces.InkCircles[i] = {}
		end
	end
	
	collectgarbage "collect"
end


function ss:FindLeaf(vertices, modelindex)
	local node = ss.Models[modelindex or 1]
	while node.Separator do
		local sign = AcrossPlane(vertices, node.Separator.normal, node.Separator.distance)
		if sign == 0 then return node end
		node = node.ChildNodes[sign > 0 and 1 or 2]
	end
	return node
end

-- Finds BSP nodes/leaves which includes the given face.
-- Use as an iterator function:
--   for nodes in SplatoonSWEPs:BSPPairs {table of vertices} ... end
-- Arguments:
--   table vertices		| Table of Vertices which represents the face.
--   number modelindex	| BSP tree index.  Optional.
-- Returns:
--   function			| An iterator function.
function ss:BSPPairs(vertices, modelindex)
	return function(queue, old)
		if old.Separator then
			local sign = AcrossPlane(vertices, old.Separator.normal, old.Separator.distance)
			if sign >= 0 then table.insert(queue, old.ChildNodes[1]) end
			if sign <= 0 then table.insert(queue, old.ChildNodes[2]) end
		end
		return table.remove(queue, 1)
	end, {ss.Models[modelindex or 1]}, {}
end

-- Returns an iterator function which covers all nodes in map BSP tree.
-- Argument:
--   number modelindex	| BSP tree index.  Optional.
-- Returning:
--   function			| An iterator function.
function ss:BSPPairsAll(modelindex)
	return function(queue, old)
		if old and old.ChildNodes then
			table.insert(queue, old.ChildNodes[1])
			table.insert(queue, old.ChildNodes[2])
		end
		return table.remove(queue, 1)
	end, {ss.Models[modelindex or 1]}
end

-- Calls notification.AddLegacy serverside.
-- Arguments:
--   string msg			| The message to display.
--   Player user		| The receiver.
--   number icon		| Notification icon.  Note that NOTIFY_Enums are only in clientside.
--   number duration	| The number of seconds to display the notification for.
function ss:SendError(msg, user, icon, duration)
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
		for node in ss:BSPPairsAll() do
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
	ss:ClearAllInk()
	ss:InitializeMoveEmulation(ply)
end)

hook.Add("PlayerDisconnected", "SplatoonSWEPs: Reset player's readiness", function(ply)
	table.RemoveByValue(ss.PlayersReady, ply)
end)

hook.Add("GetFallDamage", "SplatoonSWEPs: Inklings don't take fall damage.", function(ply, speed)
	return ss:IsValidInkling(ply) and 0 or nil
end)

hook.Add("EntityTakeDamage", "SplatoonSWEPs: Ink damage manager", function(ent, dmg)
	local atk = dmg:GetAttacker()
	if atk ~= game.GetWorld() and not (IsValid(atk) and ent:Health() > 0 and ss:IsValidInkling(atk)) then return end
	if atk.IsSplatoonProjectile then return true end
	local entweapon = ss:IsValidInkling(ent)
	if not entweapon then return end
	if entweapon.ColorCode == dmg:GetInflictor().ColorCode then return true end
	entweapon.HealSchedule:SetDelay(45 * ss.FrameToSec)
	if ent:IsPlayer() and IsValid(dmg:GetInflictor())
		and dmg:GetInflictor().IsSplatoonWeapon then
		net.Start "SplatoonSWEPs: Play damage sound"
		net.Send(ent)
	end
end)
