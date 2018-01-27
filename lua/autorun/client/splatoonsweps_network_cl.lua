
--net.Receive's
if not SplatoonSWEPs then return end

net.Receive("SplatoonSWEPs: DrawInk", function(len, ply)
	local facenumber = net.ReadInt(20)
	local color = net.ReadUInt(SplatoonSWEPs.COLOR_BITS)
	local pos = net.ReadVector()
	local radius = net.ReadFloat()
	local inkangle = net.ReadFloat()
	local inktype = net.ReadUInt(4)
	return table.insert(SplatoonSWEPs.InkQueue, {
		c = color,
		dispflag = facenumber < 0 and 0 or 1,
		done = 0,
		inkangle = inkangle,
		n = math.abs(facenumber),
		pos = pos,
		r = radius,
		t = inktype,
	})
end)

net.Receive("SplatoonSWEPs: Send error message from server", function(...)
	local msg = net.ReadString()
	local icon = net.ReadUInt(3)
	local duration = net.ReadUInt(4)
	notification.AddLegacy(msg, icon, duration)
end)

net.Receive("SplatoonSWEPs: Play damage sound", function(...)
	surface.PlaySound(SplatoonSWEPs[net.ReadString()])
end)