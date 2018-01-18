
--net.Receive's
if not SplatoonSWEPs then return end

net.Receive("SplatoonSWEPs: DrawInk", function(len, ply)
	local facenumber = net.ReadInt(20)
	local color = net.ReadUInt(SplatoonSWEPs.COLOR_BITS)
	local pos = net.ReadVector()
	local radius = net.ReadFloat()
	local whitealpha = net.ReadUInt(6)
	local whiterotate = net.ReadUInt(8)
	local origin = net.ReadVector()
	local normal = net.ReadVector()
	local angle = net.ReadAngle()
	table.insert(SplatoonSWEPs.InkQueue, {
		alpha = whitealpha / 1000,
		angle = angle,
		c = color,
		facenumber = math.abs(facenumber),
		isdisplacement = facenumber < 0,
		normal = normal,
		origin = origin,
		pos = pos,
		r = radius,
		rotate = whiterotate - 128,
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