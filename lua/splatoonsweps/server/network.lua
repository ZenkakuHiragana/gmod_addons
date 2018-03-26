
--util.AddNetworkString's
local ss = SplatoonSWEPs
if not ss then return end

util.AddNetworkString "SplatoonSWEPs: DrawInk"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Ready to splat"
util.AddNetworkString "SplatoonSWEPs: Redownload ink data"
net.Receive("SplatoonSWEPs: Ready to splat", function(_, ply)
	table.insert(ss.PlayersReady, ply)
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
