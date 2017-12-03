
--net.Receive's
if not SplatoonSWEPs then return end

net.Receive("SplatoonSWEPs: DrawInk", function(len, ply)
	local facenumber = net.ReadUInt(20)
	local color = net.ReadUInt(SplatoonSWEPs.COLOR_BITS)
	local pos = net.ReadVector()
	local radius = net.ReadFloat()
	local whitealpha = net.ReadUInt(8)
	local whiterotate = net.ReadUInt(8)
	table.insert(SplatoonSWEPs.InkQueue, {
		facenumber = facenumber,
		c = color,
		pos = pos,
		r = radius,
		alpha = whitealpha / 1000 + 0.05,
		rotate = whiterotate - 128,
	})
end)

net.Receive("SplatoonSWEPs: Send error message from server", function(...)
	local msg = net.ReadString()
	local icon = net.ReadUInt(3)
	local duration = net.ReadUInt(4)
	notification.AddLegacy(msg, icon, duration)
end)