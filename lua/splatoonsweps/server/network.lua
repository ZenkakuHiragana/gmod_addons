
-- util.AddNetworkString's

local ss = SplatoonSWEPs
if not ss then return end

util.AddNetworkString "SplatoonSWEPs: DrawInk"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Ready to splat"
util.AddNetworkString "SplatoonSWEPs: Redownload ink data"
util.AddNetworkString "SplatoonSWEPs: Resend weapon settings"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Send ink cleanup"
util.AddNetworkString "SplatoonSWEPs: Send weapon settings"
util.AddNetworkString "SplatoonSWEPs: Shooter Tracer"
net.Receive("SplatoonSWEPs: Ready to splat", function(_, ply)
	table.insert(ss.PlayersReady, ply)
	ss.InitializeMoveEmulation(ply)
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
	print("Redownloading ink data to", ply, "(" .. math.floor(startpos / bps) .. "/" .. math.floor(data:len() / bps) .. ")")
end)

net.Receive("SplatoonSWEPs: Send ink cleanup", function(_, ply)
	if not ply:IsAdmin() then return end
	ss.ClearAllInk()
end)

net.Receive("SplatoonSWEPs: Resend weapon settings", function(_, ply)
	local self = ss.IsValidInkling(ply)
	if not self then return end
	net.Start "SplatoonSWEPs: Send weapon settings"
	net.WriteEntity(self)
	net.WriteBool(self.AvoidWalls)
	net.WriteBool(self.BecomeSquid)
	net.WriteBool(self.CanHealStand)
	net.WriteBool(self.CanHealInk)
	net.WriteBool(self.CanReloadStand)
	net.WriteBool(self.CanReloadInk)
	net.WriteUInt(self.ColorCode, ss.COLOR_BITS)
	net.WriteUInt(self.PMID, ss.PLAYER_BITS)
	net.Send(ss.PlayersReady)
end)
