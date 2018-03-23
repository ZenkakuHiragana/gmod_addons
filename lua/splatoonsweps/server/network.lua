
--util.AddNetworkString's
local ss = SplatoonSWEPs
if not ss then return end

util.AddNetworkString "SplatoonSWEPs: DrawInk"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Ready to splat"
net.Receive("SplatoonSWEPs: Ready to splat", function(_, ply)
	table.insert(ss.PlayersReady, ply)
end)
