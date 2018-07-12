
-- net.Receive()

local ss = SplatoonSWEPs
if not ss then return end
net.Receive("SplatoonSWEPs: Client PrimaryAttack", function()
	local w = net.ReadEntity()
	if not IsValid(w) or not game.SinglePlayer() and w.Owner == LocalPlayer() then return end
	local auto = net.ReadBool()
	ss:ProtectedCall(w.PrimaryAttack, w, auto)
end)

net.Receive("SplatoonSWEPs: Client Deploy", function()
	local w = net.ReadEntity()
	if not IsValid(w) or not game.SinglePlayer() and w.Owner == LocalPlayer() then return end
	ss:ProtectedCall(w.Deploy, w)
end)

net.Receive("SplatoonSWEPs: DrawInk", function()
	local facenumber = net.ReadInt(ss.SURFACE_INDEX_BITS)
	local color = net.ReadUInt(ss.COLOR_BITS)
	local inktype = net.ReadUInt(4)
	local pos = net.ReadVector()
	local info = net.ReadVector() -- Vector(Radius, Inkangle, Ratio)
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
	ss:PrepareInkSurface(redownload)
end)

net.Receive("SplatoonSWEPs: Shooter Tracer", function()
	local owner = net.ReadEntity()
	if owner == LocalPlayer() then return end
	local w = ss:IsValidInkling(owner)
	if not w then return end
	local pos = net.ReadVector()
	local dir = net.ReadVector()
	local speed = net.ReadFloat()
	local straight = net.ReadFloat()
	local color = net.ReadUInt(ss.COLOR_BITS)
	local splashinit = net.ReadUInt(4)
	ss.InkTraces[{
		Appearance = {
			InitPos = pos,
			Pos = pos,
			Speed = speed,
			TrailPos = pos,
			Velocity = dir * speed,
		},
		Color = ss:GetColor(color),
		ColorCode = color,
		InitPos = pos,
		InitTime = CurTime() - w:Ping(),
		Speed = speed,
		Straight = straight,
		TrailDelay = ss.ShooterTrailDelay,
		TrailTime = RealTime(),
		Velocity = dir * speed,
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		filter = owner,
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * ss.mColRadius,
		mins = -ss.vector_one * ss.mColRadius,
		start = pos,
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
