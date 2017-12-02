
--SplatoonSWEPs structure
--The core of new ink system.

SplatoonSWEPs = SplatoonSWEPs or {
	Models = {},
	SortedSurfaces = {},
	Surfaces = {Area = 0, AreaBound = 0, LongestEdge = 0},
}
AddCSLuaFile "../splatoonsweps_shared.lua"
AddCSLuaFile "../splatoonsweps_bsp.lua"
AddCSLuaFile "../splatoonsweps_const.lua"
include "../splatoonsweps_shared.lua"
include "../splatoonsweps_bsp.lua"
include "../splatoonsweps_const.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_network.lua"

function SplatoonSWEPs:ClearAllInk()
	BroadcastLua "SplatoonSWEPs:ClearAllInk()"
end

local function Initialize()
	local self = SplatoonSWEPs
	self.BSP:Init()
	self.BSP = nil
	self:InitSortSurfaces()
end

hook.Add("InitPostEntity", "SplatoonSWEPs: Serverside Initialization", Initialize)
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
