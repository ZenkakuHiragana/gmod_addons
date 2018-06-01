
--net.Receive's
local ss = SplatoonSWEPs
if not ss then return end

net.Receive("SplatoonSWEPs: DrawInk", function()
	local facenumber = net.ReadInt(ss.SURFACE_INDEX_BITS)
	local color = net.ReadUInt(ss.COLOR_BITS)
	local inktype = net.ReadUInt(4)
	local pos = net.ReadVector()
	local info = net.ReadVector() --(Radius, Inkangle, Ratio)
	ss.InkQueue[{
		c = color,
		dispflag = facenumber < 0 and 0 or 1,
		done = 0,
		inkangle = info.y,
		n = math.abs(facenumber),
		pos = pos,
		r = info.x,
		ratio = info.z,
		t = inktype,
	}] = true
end)

net.Receive("SplatoonSWEPs: Send ink cleanup", ss.ClearAllInk)
net.Receive("SplatoonSWEPs: Send an error message", function()
	local icon = net.ReadUInt(ss.SEND_ERROR_NOTIFY_BITS)
	local duration = net.ReadUInt(ss.SEND_ERROR_DURATION_BITS)
	local msg = ss.Text.Error[net.ReadString()]
	if not msg then return end
	notification.AddLegacy(msg, icon, duration)
end)


local DamageSounds = {"TakeDamage", "DealDamage", "DealDamageCritical"}
net.Receive("SplatoonSWEPs: Play damage sound", function()
	surface.PlaySound(ss[DamageSounds[net.ReadUInt(2)]])
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
	ss:PrepareInkSurface(redownload)
end)
