
--net.Receive's
local ss = SplatoonSWEPs
if not ss then return end

net.Receive("SplatoonSWEPs: DrawInk", function(...)
	local facenumber = net.ReadInt(ss.SURFACE_INDEX_BITS)
	local color = net.ReadUInt(ss.COLOR_BITS)
	local inktype = net.ReadUInt(4)
	local pos = net.ReadVector()
	local radius = net.ReadVector()
	local inkangle = radius.y
	local ratio = radius.z
	radius = radius.x
	ss.InkQueue[{
		c = color,
		dispflag = facenumber < 0 and 0 or 1,
		done = 0,
		inkangle = inkangle,
		n = math.abs(facenumber),
		pos = pos,
		r = radius,
		ratio = ratio,
		t = inktype,
	}] = true
end)

net.Receive("SplatoonSWEPs: Send error message from server", function(...)
	local msg = net.ReadString()
	local icon = net.ReadUInt(3)
	local duration = net.ReadUInt(4)
	notification.AddLegacy(msg, icon, duration)
end)

local DamageSounds = {"TakeDamage", "DealDamage", "DealDamageCritical"}
net.Receive("SplatoonSWEPs: Play damage sound", function(...)
	surface.PlaySound(ss[DamageSounds[net.ReadUInt(2)]])
end)
