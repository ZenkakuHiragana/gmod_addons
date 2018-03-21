
--SplatoonSWEPs structure
--The core of new ink system.
CreateConVar("sv_splatoonsweps_enabled", "1",
{FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE},
"Enables or disables SplatoonSWEPs.")
if not GetConVar "sv_splatoonsweps_enabled":GetBool() then return end
SplatoonSWEPs = SplatoonSWEPs or {
	AreaBound = 0,
	AspectSum = 0,
	AspectSumX = 0,
	AspectSumY = 0,
	BSP = {},
	Displacements = {},
	Models = {},
	InkCounter = 0,
	InkShotMaterials = {},
}

include "autorun/splatoonsweps_shared.lua"
include "splatoonsweps_bsp.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_network.lua"

local ss = SplatoonSWEPs
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

function ss:ClearAllInk()
	BroadcastLua "SplatoonSWEPs:ClearAllInk()"
	self.InkCounter = 0
	for node in self:BSPPairsAll() do
		for i = 1, #node.Surfaces.InkCircles do
			node.Surfaces.InkCircles[i] = {}
		end
	end
end

--table vertices of face, Vector normal of plane, number distance from plane to origin
--returning positive -> face is in positive side of the plane
--returning negative -> face is in negative side of the plane
--returning 0 -> face intersects with the plane
local PlaneThickness = 0.2
function ss:AcrossPlane(vertices, normal, dist)
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

function ss:FindLeaf(vertices, modelindex)
	local node = self.Models[modelindex or 1]
	while node.Separator do
		local sign = self:AcrossPlane(vertices, node.Separator.normal, node.Separator.distance)
		if sign == 0 then return node end
		node = node.ChildNodes[sign > 0 and 1 or 2]
	end
	return node
end

-- table Vertices -> node/leaf it is in
function ss:BSPPairs(vertices, modelindex)
	return function(queue, old)
		if old.Separator then
			local sign = self:AcrossPlane(vertices, old.Separator.normal, old.Separator.distance)
			if sign >= 0 then table.insert(queue, old.ChildNodes[1]) end
			if sign <= 0 then table.insert(queue, old.ChildNodes[2]) end
		end
		return table.remove(queue, 1)
	end, {self.Models[modelindex or 1]}, {}
end

function ss:BSPPairsAll(modelindex)
	return function(queue, old)
		if old and old.ChildNodes then
			table.insert(queue, old.ChildNodes[1])
			table.insert(queue, old.ChildNodes[2])
		end
		return table.remove(queue, 1)
	end, {self.Models[modelindex or 1]}
end

function ss:SendError(msg, icon, duration, user)
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

hook.Add("InitPostEntity", "SplatoonSWEPs: Serverside Initialization", function()
	ss.BSP:Init()
	ss.BSP = nil
	collectgarbage "collect"
end)

hook.Add("GetFallDamage", "Inklings don't take fall damage.", function(ply, speed)
	if ss:IsValidInkling(ply) then return 0 end
end)

hook.Add("EntityTakeDamage", "SplatoonSWEPs: Ink damage manager", function(ent, dmg)
	local atk = dmg:GetAttacker()
	if atk.IsSplatoonProjectile then return true end
	if not (IsValid(dmg:GetInflictor()) and dmg:GetInflictor().IsSplatoonWeapon and ent:Health() > 0) then return end
	local entweapon = ss:IsValidInkling(ent)
	if entweapon then
		if entweapon.ColorCode == dmg:GetInflictor().ColorCode then return true end
		entweapon.HealSchedule:SetDelay(45 * ss.FrameToSec)
		net.Start "SplatoonSWEPs: Play damage sound"
		net.WriteUInt(1, 2)
		net.Send(ent)
	end
	
	net.Start "SplatoonSWEPs: Play damage sound"
	net.WriteUInt(dmg:GetDamage() < ss.ToHammerHealth and 2 or 3, 2)
	net.Send(atk)
end)

hook.Add("Tick", "SplatoonSWEPsDoInkCoroutines", function()
	local self = ss.InkManager
	if coroutine.status(self.DoCoroutines) == "dead" then return end
	local ok, message = coroutine.resume(self.DoCoroutines)
	if not ok then ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n") end
end)
