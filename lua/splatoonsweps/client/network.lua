
-- net.Receive()

local ss = SplatoonSWEPs
if not ss then return end
net.Receive("SplatoonSWEPs: Change throwing", function()
	local w = net.ReadEntity()
	if not (IsValid(w) and w.IsSplatoonWeapon) then return end
	w.WorldModel = w.ModelPath .. (net.ReadBool() and "w_left.mdl" or "w_right.mdl")
end)

net.Receive("SplatoonSWEPs: Play damage sound", function()
	surface.PlaySound(ss.TakeDamage)
end)

local redownload = ""
net.Receive("SplatoonSWEPs: Redownload ink data", function()
	local finished = net.ReadBool()
	local size = net.ReadUInt(16)
	local data = net.ReadData(size)
	redownload = redownload .. data
	if not finished then
		net.Start "SplatoonSWEPs: Redownload ink data"
		net.SendToServer()
		return
	end
	
	file.Write("splatoonsweps/" .. game.GetMap() .. ".txt", redownload)
	ss.PrepareInkSurface(redownload)
end)

net.Receive("SplatoonSWEPs: Send ink cleanup", ss.ClearAllInk)
net.Receive("SplatoonSWEPs: Send player data", function()
	local size = net.ReadUInt(16)
	local record = util.Decompress(net.ReadData(size))
	ss.WeaponRecord[LocalPlayer()] = util.JSONToTable(record) or ss.WeaponRecord[LocalPlayer()]
end)

net.Receive("SplatoonSWEPs: Send turf inked", function()
	local inked = net.ReadDouble()
	local classname = assert(ss.WeaponClassNames[net.ReadUInt(8)], "SplatoonSWEPs: Invalid classname!")
	ss.WeaponRecord[LocalPlayer()].Inked[classname] = inked
end)

net.Receive("SplatoonSWEPs: Send an error message", function()
	local icon = net.ReadUInt(ss.SEND_ERROR_NOTIFY_BITS)
	local duration = net.ReadUInt(ss.SEND_ERROR_DURATION_BITS)
	local msg = ss.Text.Error[net.ReadString()]
	if not msg then return end
	notification.AddLegacy(msg, icon, duration)
end)
