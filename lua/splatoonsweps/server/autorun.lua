
--SplatoonSWEPs structure
--The core of new ink system.
CreateConVar("sv_splatoonsweps_enabled", "1",
{FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE},
"Enables or disables SplatoonSWEPs.")
if not GetConVar "sv_splatoonsweps_enabled":GetBool() then return end
SplatoonSWEPs = SplatoonSWEPs or {
	BSP = {},
	Models = {},
	NoCollide = {},
	InkCounter = 0,
	InkShotMaterials = {},
	PlayersReady = {},
}

local ss = SplatoonSWEPs
local abs, collectgarbage, insert, ipairs, pairs, remove
= math.abs, collectgarbage, table.insert, ipairs, pairs, table.remove
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

--table vertices of face, Vector normal of plane, number distance from plane to origin
--returning positive -> face is in positive side of the plane
--returning negative -> face is in negative side of the plane
--returning 0 -> face intersects with the plane
local PlaneThickness = 0.2
local function AcrossPlane(self, vertices, normal, dist)
	local sign
	for i, v in ipairs(vertices) do --for each vertices of face
		local dot = normal:Dot(v) - dist
		if abs(dot) > PlaneThickness then
			if sign and sign * dot < 0 then return 0 end
			sign = (sign or 0) + dot
		end
	end
	return sign or 0
end

function ss:ClearAllInk()
	net.Start "SplatoonSWEPs: Send ink cleanup"
	net.Send(ss.PlayersReady)
	
	ss.InkCounter = 0
	for node in ss:BSPPairsAll() do
		for i = 1, #node.Surfaces.InkCircles do
			node.Surfaces.InkCircles[i] = {}
		end
	end
	collectgarbage "collect"
end

function ss:FindLeaf(vertices, modelindex)
	local node = self.Models[modelindex or 1]
	while node.Separator do
		local sign = AcrossPlane(ss, vertices, node.Separator.normal, node.Separator.distance)
		if sign == 0 then return node end
		node = node.ChildNodes[sign > 0 and 1 or 2]
	end
	return node
end

-- table Vertices -> node/leaf it is in
function ss:BSPPairs(vertices, modelindex)
	return function(queue, old)
		if old.Separator then
			local sign = AcrossPlane(ss, vertices, old.Separator.normal, old.Separator.distance)
			if sign >= 0 then insert(queue, old.ChildNodes[1]) end
			if sign <= 0 then insert(queue, old.ChildNodes[2]) end
		end
		return remove(queue, 1)
	end, {self.Models[modelindex or 1]}, {}
end

function ss:BSPPairsAll(modelindex)
	return function(queue, old)
		if old and old.ChildNodes then
			insert(queue, old.ChildNodes[1])
			insert(queue, old.ChildNodes[2])
		end
		return remove(queue, 1)
	end, {self.Models[modelindex or 1]}
end

function ss:SendError(msg, icon, duration, user)
	if not user:IsPlayer() then return end
	net.Start "SplatoonSWEPs: Send an error message"
	net.WriteString(msg)
	net.WriteUInt(icon, self.SEND_ERROR_NOTIFY_BITS)
	net.WriteUInt(duration, self.SEND_ERROR_DURATION_BITS)
	if user then
		net.Send(user)
	else
		net.Broadcast()
	end
end

function ss:MakeNoCollide(src, tar, NoCollideTable)
	if not (IsValid(src) and tar and tar ~= NULL) then return end
	NoCollideTable = NoCollideTable or ss.NoCollide[src]
	if not NoCollideTable or IsValid(NoCollideTable[tar]) then return end
	local ps, pt = src:GetPhysicsObject(), tar:GetPhysicsObject()
	if not (IsValid(ps) and IsValid(pt)) then return end
	local nocol = ents.Create "logic_collision_pair"
	nocol:SetKeyValue("startdisabled", 1)
	nocol:SetPhysConstraintObjects(ps, pt)
	nocol:Spawn()
	nocol:Activate()
	nocol:Input "DisableCollisions"
	NoCollideTable[tar] = nocol
end

function ss:RemoveNoCollide(src, tar, NoCollideTable)
	if not IsValid(src) then return end
	NoCollideTable = NoCollideTable or ss.NoCollide[src]
	if not NoCollideTable then return end
	local n = NoCollideTable[tar or game.GetWorld()]
	if not IsValid(n) then return end
	n:Input "EnableCollisions"
	n:Remove()
end

ss.AcrossPlane = AcrossPlane
include "splatoonsweps/shared.lua"
include "bsp.lua"
include "inkmanager.lua"
include "network.lua"

hook.Add("InitPostEntity", "SplatoonSWEPs: Serverside Initialization", function()
	ss.BSP:Init()
	ss.BSP = nil
	collectgarbage "collect"
	local path = "splatoonsweps/" .. game.GetMap() .. ".txt"
	local data = file.Open(path, "rb", "DATA")
	local mapCRC = tonumber(util.CRC(file.Read("maps/" .. game.GetMap() .. ".bsp", true) or "")) or 0
	if not file.Exists("splatoonsweps", "DATA") then file.CreateDir "splatoonsweps" end
	if not data or data:Size() < 4 or data:ReadULong() ~= mapCRC then
		file.Write(path, "")
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
				data:WriteULong(abs(index))
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
			assert(power % 1 == 0)
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
		
		data:Close()
		local write = util.Compress(file.Read(path))
		file.Delete(path)
		file.Write(path, "")
		data = file.Open(path, "wb", "DATA")
		data:WriteULong(mapCRC)
		for c in write:gmatch "." do data:WriteByte(c:byte()) end
		data:Close()
	end
	
	resource.AddSingleFile("data/" .. path)
end)

hook.Add("PlayerInitialSpawn", "SplatoonSWEPs: Joining players make ink vanish", function(ply)
	if ply:IsBot() then return end
	ss:ClearAllInk()
end)

hook.Add("PlayerDisconnected", "SplatoonSWEPs: Reset player's readiness", function(ply)
	table.RemoveByValue(ss.PlayersReady, ply)
end)

hook.Add("GetFallDamage", "SplatoonSWEPs: Inklings don't take fall damage.", function(ply, speed)
	if ss:IsValidInkling(ply) then return 0 end
end)

hook.Add("EntityTakeDamage", "SplatoonSWEPs: Ink damage manager", function(ent, dmg)
	local atk = dmg:GetAttacker()
	if atk ~= game.GetWorld() and not (IsValid(atk) and ent:Health() > 0 and ss:IsValidInkling(atk)) then return end
	if atk.IsSplatoonProjectile then return true end
	local entweapon = ss:IsValidInkling(ent)
	if entweapon then
		if entweapon.ColorCode == dmg:GetInflictor().ColorCode then return true end
		entweapon.HealSchedule:SetDelay(45 * ss.FrameToSec)
		if ent:IsPlayer() and IsValid(dmg:GetInflictor())
			and dmg:GetInflictor().IsSplatoonWeapon then
			net.Start "SplatoonSWEPs: Play damage sound"
			net.WriteUInt(1, 2)
			net.Send(ent)
		end
	end
	
	if not atk:IsPlayer() then return end
	net.Start "SplatoonSWEPs: Play damage sound"
	net.WriteUInt(dmg:GetDamage() < ss.ToHammerHealth and 2 or 3, 2)
	net.Send(atk)
end)

hook.Add("Tick", "SplatoonSWEPs: Do ink coroutines", function()
	local self = ss.InkManager
	if coroutine.status(self.DoCoroutines) == "dead" then return end
	local ok, message = coroutine.resume(self.DoCoroutines)
	if not ok then ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n") end
end)

hook.Add("PostCleanupMap", "SplatoonSWEPs: Cleanup all ink", ss.ClearAllInk)
hook.Add("PlayerInitialSpawn", "SplatoonSWEPs: Bots compatibility", function(ply)
	if not ply:IsBot() then return end
	ss:InitializeMoveEmulation(ply)
end)
