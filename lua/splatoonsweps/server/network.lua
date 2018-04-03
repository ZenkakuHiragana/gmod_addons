
--util.AddNetworkString's
local ss = SplatoonSWEPs
if not ss then return end

util.AddNetworkString "SplatoonSWEPs: DrawInk"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Send ink cleanup"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Ready to splat"
util.AddNetworkString "SplatoonSWEPs: Redownload ink data"
net.Receive("SplatoonSWEPs: Ready to splat", function(_, ply)
	table.insert(ss.PlayersReady, ply)
	ss.m_surfaceFriction[ply] = ss.m_surfaceFriction[ply] or 1.0
	ss.m_bInDuckJump[ply] = ss.m_bInDuckJump[ply] or false
	ss.m_flDuckJumpTime[ply] = ss.m_flDuckJumpTime[ply] or 0
	ss.m_flDucktime[ply] = ss.m_flDucktime[ply] or 0
	ss.m_flFallVelocity[ply] = ss.m_flFallVelocity[ply] or 0
	ss.m_flJumpTime[ply] = ss.m_flJumpTime[ply] or 0
	ss.m_flSwimSoundTime[ply] = ss.m_flSwimSoundTime[ply] or 0
	ss.m_flWaterJumpTime[ply] = ss.m_flWaterJumpTime[ply] or 0
	ss.m_nWaterLevel[ply] = ss.m_nWaterLevel[ply] or 0
	ss.m_nWaterType[ply] = ss.m_nWaterType[ply] or CONTENTS_EMPTY
	ss.m_vecPunchAngleVel[ply] = ss.m_vecPunchAngleVel[ply] or vector_origin
	ss.m_vecWaterJumpVel[ply] = ss.m_vecWaterJumpVel[ply] or vector_origin
end)

net.Receive("SplatoonSWEPs: Redownload ink data", function(_, ply)
	local data = file.Read("splatoonsweps/" .. game.GetMap() .. ".txt", "DATA")
	local startpos = ply.SendData or 1
	local bps = 65530
	local chunk = data:sub(startpos, startpos + bps - 1)
	local size = chunk:len()
	ply.SendData = startpos + size
	net.Start "SplatoonSWEPs: Redownload ink data"
	net.WriteBool(size < bps or data:len() < startpos + bps)
	net.WriteUInt(size, 16)
	net.WriteData(chunk, size)
	net.Send(ply)
	print("Redownloading ink data to", ply,
	"(" .. math.floor(startpos / bps) .. "/" .. math.floor(data:len() / bps) .. ")")
end)

net.Receive("SplatoonSWEPs: Send ink cleanup", function(_, ply)
	if not ply:IsAdmin() then return end
	ss:ClearAllInk()
end)
