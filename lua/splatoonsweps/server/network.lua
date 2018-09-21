
-- util.AddNetworkString's

local ss = SplatoonSWEPs
if not ss then return end

util.AddNetworkString "SplatoonSWEPs: Change throwing"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Ready to splat"
util.AddNetworkString "SplatoonSWEPs: Redownload ink data"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Send ink cleanup"
util.AddNetworkString "SplatoonSWEPs: Send player data"
util.AddNetworkString "SplatoonSWEPs: Send turf inked"
util.AddNetworkString "SplatoonSWEPs: Send weapon settings"
util.AddNetworkString "SplatoonSWEPs: Strip weapon"
net.Receive("SplatoonSWEPs: Ready to splat", function(_, ply)
	table.insert(ss.PlayersReady, ply)
	ss.InitializeMoveEmulation(ply)
	ss.WeaponRecord[ply] = {
		Duration = {},
		Inked = {},
		Recent = {},
	}
	
	local id = ss.PlayerID[ply]
	if not id then return end
	local record = "data/splatoonsweps/record/" .. id .. ".txt"
	if not file.Exists(record, "GAME") then return end
	local json = file.Read(record, "GAME")
	local cmpjson = util.Compress(json)
	ss.WeaponRecord[ply] = util.JSONToTable(json)
	net.Start "SplatoonSWEPs: Send player data"
	net.WriteUInt(cmpjson:len(), 16)
	net.WriteData(cmpjson, cmpjson:len())
	net.Send(ply)
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

net.Receive("SplatoonSWEPs: Strip weapon", function(_, ply)
	local weapon = ss.WeaponClassNames[net.ReadUInt(8)]
	if not weapon then return end
	ply:GetWeapon(weapon):Holster()
	ply:StripWeapon(weapon)
end)
