
--SplatoonSWEPs structure
--The core of new ink system.

SplatoonSWEPs = SplatoonSWEPs or {
	Models = {},
	InkCounter = 0,
}
include "autorun/splatoonsweps_shared.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_network.lua"

function SplatoonSWEPs:ClearAllInk()
	BroadcastLua "SplatoonSWEPs:ClearAllInk()"
	SplatoonSWEPs.InkCounter = 0
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
function SplatoonSWEPs:AcrossPlane(vertices, normal, dist)
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

function SplatoonSWEPs:FindLeaf(vertices, modelindex)
	local node = self.Models[modelindex or 1]
	while node.Separator do
		local sign = self:AcrossPlane(vertices, node.Separator.normal, node.Separator.distance)
		if sign == 0 then return node end
		node = node.ChildNodes[sign > 0 and 1 or 2]
	end
	return node
end

-- table Vertices -> node/leaf it is in
function SplatoonSWEPs:BSPPairs(vertices, modelindex)
	return function(queue, old)
		if old.Separator then
			local sign = SplatoonSWEPs:AcrossPlane(vertices, old.Separator.normal, old.Separator.distance)
			if sign >= 0 then table.insert(queue, old.ChildNodes[1]) end
			if sign <= 0 then table.insert(queue, old.ChildNodes[2]) end
		end
		return table.remove(queue, 1)
	end, {self.Models[modelindex or 1]}, {}
end

function SplatoonSWEPs:BSPPairsAll(modelindex)
	return function(queue, old)
		if old and old.ChildNodes then
			table.insert(queue, old.ChildNodes[1])
			table.insert(queue, old.ChildNodes[2])
		end
		return table.remove(queue, 1)
	end, {self.Models[modelindex or 1]}
end

function SplatoonSWEPs:SendError(msg, icon, duration, user)
	net.Start "SplatoonSWEPs: Send an error message"
	net.WriteString(msg)
	net.WriteUInt(icon, SplatoonSWEPs.SEND_ERROR_NOTIFY_BITS)
	net.WriteUInt(duration, SplatoonSWEPs.SEND_ERROR_DURATION_BITS)
	if user then
		net.Send(user)
	else
		net.Broadcast()
	end
end

hook.Add("InitPostEntity", "SplatoonSWEPs: Serverside Initialization", function()
	local self = SplatoonSWEPs
	self.BSP:Init()
	self.BSP = nil
	collectgarbage "collect"
end)

hook.Add("GetFallDamage", "Inklings don't take fall damage.", function(ply, speed)
	if SplatoonSWEPs:IsValidInkling(ply) then return 0 end
end)

hook.Add("EntityTakeDamage", "SplatoonSWEPs: Ink damage manager", function(ent, dmg)
	if not (IsValid(dmg:GetInflictor()) and dmg:GetInflictor().IsSplatoonWeapon and ent:Health() > 0) then return end
	local atk = dmg:GetAttacker()
	if atk.IsSplatoonProjectile then return true end
	if SplatoonSWEPs:IsValidInkling(ent) then
		if ent:GetActiveWeapon().ColorCode == dmg:GetInflictor().ColorCode then return true end
		net.Start "SplatoonSWEPs: Play damage sound"
		net.WriteString "TakeDamage"
		net.Send(ent)
	end
	
	net.Start "SplatoonSWEPs: Play damage sound"
	net.WriteString("DealDamage" .. (dmg:GetDamage() >= 100 and "Critical" or ""))
	net.Send(atk)
end)
