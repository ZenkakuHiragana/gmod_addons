
--SplatoonSWEPs structure
--The core of new ink system.

SplatoonSWEPs = SplatoonSWEPs or {
	Models = {},
	SortedSurfaces = {},
}
include "autorun/splatoonsweps_shared.lua"
include "autorun/splatoonsweps_bsp.lua"
include "autorun/splatoonsweps_const.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_network.lua"

function SplatoonSWEPs:ClearAllInk()
	BroadcastLua "SplatoonSWEPs:ClearAllInk()"
	for _, f in ipairs(self.SortedSurfaces) do
		f.InkCounter = 0
		f.InkCircles = {}
	end
end

local function Initialize()
	local self = SplatoonSWEPs
	self.BSP:Init()
	self.BSP = nil
	self:InitSortSurfaces()
	self.InkDamageInfo = DamageInfo()
	self.InkDamageInfo:SetAttacker(game.GetWorld())
	self.InkDamageInfo:SetDamage(1)
	self.InkDamageInfo:SetDamageForce(vector_origin)
	self.InkDamageInfo:SetDamagePosition(vector_origin)
	self.InkDamageInfo:SetDamageType(DMG_SHOCK)
	self.InkDamageInfo:SetInflictor(game.GetWorld())
	self.InkDamageInfo:SetMaxDamage(1)
	self.InkDamageInfo:SetReportedPosition(vector_origin)
	collectgarbage()
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
