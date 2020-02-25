
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

local buffer = ""
net.Receive("SplatoonSWEPs: Redownload ink data", function()
	local finished = net.ReadBool()
	local size = net.ReadUInt(16)
	local data = net.ReadData(size)
	local prog = net.ReadFloat()
	buffer = buffer .. data
	if not finished then
		net.Start "SplatoonSWEPs: Redownload ink data"
		net.SendToServer()
		return
	end

	if not file.Exists("splatoonsweps", "DATA") then file.CreateDir "splatoonsweps" end
	file.Write(("splatoonsweps/%s.txt"):format(game.GetMap()), buffer)
	notification.Kill "SplatoonSWEPs: Redownload ink data"
	ss.PrepareInkSurface(util.JSONToTable(util.Decompress(buffer)))
	notification.AddLegacy(ss.Text.LateReadyToSplat, NOTIFY_HINT, 8)
end)

net.Receive("SplatoonSWEPs: Send a sound", function()
	local soundName = net.ReadString()
	local soundLevel = net.ReadUInt(9)
	local pitchPercent = net.ReadUInt(8)
	local volume = net.ReadFloat()
	local channel = net.ReadUInt(8) - 1
	LocalPlayer():EmitSound(soundName, soundLevel, pitchPercent, volume, channel)
end)

net.Receive("SplatoonSWEPs: Send an error message", function()
	local icon = net.ReadUInt(ss.SEND_ERROR_NOTIFY_BITS)
	local duration = net.ReadUInt(ss.SEND_ERROR_DURATION_BITS)
	local msg = ss.Text.Error[net.ReadString()]
	if not msg then return end
	notification.AddLegacy(msg, icon, duration)
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

-- misc = Vector(Radius, Inkangle, Ratio)
function ss.InkQueueReceiveFunction(index, misc, color, ply, inktype, pos)
	local t = ss.PaintQueue[CurTime()] or {}
	ss.PaintQueue[CurTime()], t[#t + 1] = t, {
		c = color,
		dispflag = ss.SurfaceArray[index].Displacement and 0 or 1,
		done = 0,
		index = index,
		inkangle = misc.y,
		owner = ply,
		pos = pos,
		r = misc.x,
		ratio = misc.z,
		t = inktype,
	}
end

net.Receive("SplatoonSWEPs: Send an ink queue", function()
	local index = net.ReadUInt(ss.SURFACE_ID_BITS)
	local misc = net.ReadVector()
	local color = net.ReadUInt(ss.COLOR_BITS)
	local ply = net.ReadEntity()
	local inktype = net.ReadUInt(ss.INK_TYPE_BITS)
	local pos = net.ReadVector()
	ss.InkQueueReceiveFunction(index, misc, color, ply, inktype, pos)
end)
