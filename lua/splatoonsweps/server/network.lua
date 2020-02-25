
-- util.AddNetworkString's

local ss = SplatoonSWEPs
if not ss then return end

util.AddNetworkString "SplatoonSWEPs: Change throwing"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Ready to splat"
util.AddNetworkString "SplatoonSWEPs: Redownload ink data"
util.AddNetworkString "SplatoonSWEPs: Send a sound"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Send an ink queue"
util.AddNetworkString "SplatoonSWEPs: Send ink cleanup"
util.AddNetworkString "SplatoonSWEPs: Send player data"
util.AddNetworkString "SplatoonSWEPs: Send turf inked"
util.AddNetworkString "SplatoonSWEPs: Strip weapon"
net.Receive("SplatoonSWEPs: Ready to splat", function(_, ply)
	ss.PlayersReady[#ss.PlayersReady + 1] = ply
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
	local data = file.Read(("splatoonsweps/%s.txt"):format(game.GetMap()))
	local startpos = ply.SendData or 1
	local bps = 65530
	local chunk = data:sub(startpos, startpos + bps - 1)
	local size = chunk:len()
	local current = math.floor(startpos / bps)
	local total = math.floor(data:len() / bps)
	ply.SendData = startpos + size
	net.Start "SplatoonSWEPs: Redownload ink data"
	net.WriteBool(size < bps or data:len() < startpos + bps)
	net.WriteUInt(size, 16)
	net.WriteData(chunk, size)
	net.WriteFloat(current / total)
	net.Send(ply)
	print(("Redownloading ink data to %s (%d/%d)"):format(tostring(ply), current, total))
end)

net.Receive("SplatoonSWEPs: Send ink cleanup", function(_, ply)
	if not ply:IsAdmin() then return end
	ss.ClearAllInk()
end)

net.Receive("SplatoonSWEPs: Strip weapon", function(_, ply)
	local weaponID = net.ReadUInt(ss.WEAPON_CLASSNAMES_BITS)
	local weaponClass = ss.WeaponClassNames[weaponID]
	if not weaponClass then return end
	local weapon = ply:GetWeapon(weaponClass)
	if not IsValid(weapon) then return end
	ply:StripWeapon(weaponClass)
end)
