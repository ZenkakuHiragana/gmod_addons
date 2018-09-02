
-- net.Receive()

local ss = SplatoonSWEPs
if not ss then return end
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
net.Receive("SplatoonSWEPs: Send an error message", function()
	local icon = net.ReadUInt(ss.SEND_ERROR_NOTIFY_BITS)
	local duration = net.ReadUInt(ss.SEND_ERROR_DURATION_BITS)
	local msg = ss.Text.Error[net.ReadString()]
	if not msg then return end
	notification.AddLegacy(msg, icon, duration)
end)

net.Receive("SplatoonSWEPs: Send weapon settings", function()
	local w = net.ReadEntity()
	if not IsValid(w) then
		net.Start "SplatoonSWEPs: Resend weapon settings"
		net.SendToServer()
		return
	end
	
	w.AvoidWalls = net.ReadBool()
	w.BecomeSquid = net.ReadBool()
	w.CanHealStand = net.ReadBool()
	w.CanHealInk = net.ReadBool()
	w.CanReloadStand = net.ReadBool()
	w.CanReloadInk = net.ReadBool()
	w.ColorCode = net.ReadUInt(ss.COLOR_BITS)
	w.PMID = net.ReadUInt(ss.PLAYER_BITS)
	w.Color = ss.GetColor(w.ColorCode)
end)
