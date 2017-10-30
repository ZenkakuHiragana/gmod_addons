
--Clientside ink manager
SplatoonSWEPs = SplatoonSWEPs or {}

include "../splatoonsweps_const.lua"
include "splatoonsweps_userinfo.lua"
local MAX_PROCESS_QUEUE_AT_ONCE = 10000
local mat = Material("debug/debugbrushwireframe")
local IMaterial = Material("splatoonsweps/splatoonink.vmt")
local WaterOverlap = Material("splatoonsweps/splatoonwater.vmt")
local InkGroup = InkGroup or {}
local InkQueue = InkQueue or {}

net.Receive("SplatoonSWEPs: Broadcast ink vertices", function(len, ply)
	if not LocalPlayer().IsReceivingInkData then
		LocalPlayer().IsReceivingInkData = true
		LocalPlayer().ReceivingInkData = {}
	end
	
	local pos, u, v = vector_origin, 0, 0
	for i = 1, len / 8 do
		pos = net.ReadVector()
		if pos == vector_origin then break end
		u = net.ReadFloat()
		v = net.ReadFloat()
		table.insert(LocalPlayer().ReceivingInkData, {pos = pos, u = u, v = v})
	end
end)

net.Receive("SplatoonSWEPs: Finalize ink refreshment", function(...)
	local normal = net.ReadVector()
	local color = net.ReadUInt(SplatoonSWEPs.COLOR_BITS)
	local id = net.ReadUInt(32)
	local inkid = net.ReadInt(32)
	local newink = LocalPlayer().ReceivingInkData
	table.insert(InkQueue, {
		normal = normal,
		color = color,
		id = id,
		inkid = inkid,
		newink = newink,
	})
	LocalPlayer().IsReceivingInkData = nil
	LocalPlayer().ReceivingInkData = {}
end)

net.Receive("SplatoonSWEPs: Send error message from server", function(...)
	local msg = net.ReadString()
	local icon = net.ReadUInt(3)
	local duration = net.ReadUInt(4)
	notification.AddLegacy(msg, icon, duration)
end)

function ClearInk()
	for k, v in pairs(InkGroup) do
		if v.imesh then v.imesh:Destroy() end
	end
	InkGroup = {}
	InkQueue = {}
end

local imt = {
	{pos = Vector(0, 0, 0), u = 0, v = 0, color = Color(255, 255, 0)},
	{pos = Vector(100, 0, 0), u = 1, v = 0},
	{pos = Vector(0, 100, 0), u = 0, v = 1},
}
local function DrawMeshes()
	for id, ink in pairs(InkGroup) do
		render.SetMaterial(IMaterial)
		ink.imesh:Draw()
		-- render.SetMaterial(WaterOverlap)
		-- ink.imesh:Draw()
	end
end

local function ProcessQueue()
	while true do
		local done = 0
		for i, q in ipairs(InkQueue) do
			if not InkGroup[q.id] then InkGroup[q.id] = {} end
			if InkGroup[q.id].imesh then
				InkGroup[q.id].imesh:Destroy()
			end
			InkGroup[q.id].imesh = Mesh()
			InkGroup[q.id][q.inkid] = {}
			
			local triangles = {}
			local color = SplatoonSWEPs.GetColor(q.color + 1)
			local lightcolor, r, g, b = vector_origin, 0, 0, 0
			for i, v in ipairs(q.newink) do
				lightcolor = render.ComputeLighting(v.pos, q.normal) + Vector(0.1, 0.1, 0.1)
				q.newink[i].color = Color(
					math.Clamp(color.r * math.Clamp(lightcolor.x, 0, 1), 0, 255),
					math.Clamp(color.g * math.Clamp(lightcolor.y, 0, 1), 0, 255),
					math.Clamp(color.b * math.Clamp(lightcolor.z, 0, 1), 0, 255),
					math.Remap(765 - color.r - color.g - color.b, 0, 765, 160, 254)
				) --765 = 255 * 3
				table.insert(InkGroup[q.id][q.inkid], q.newink[i])
			end
			
			for i, ink in pairs(InkGroup[q.id]) do
				if not isnumber(i) then continue end
				for k, v in ipairs(ink) do
					table.insert(triangles, v)
				end
			end
			triangles = table.Reverse(triangles)
			InkGroup[q.id].imesh:BuildFromTriangles(triangles)
			
			q.done = true
			done = done + 1
			if done % MAX_PROCESS_QUEUE_AT_ONCE == 0 then coroutine.yield() end
		end
		local newqueue = {}
		for i, v in ipairs(InkQueue) do
			if not v.done then table.insert(newqueue. v) end
		end
		InkQueue = newqueue
		coroutine.yield()
	end
end
local DoCoroutine = coroutine.create(ProcessQueue)
local function GMTick()
	if coroutine.status(DoCoroutine) ~= "dead" then
		local ok, message = coroutine.resume(DoCoroutine)
		if not ok then
			ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n")
		end
	end
end

hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", DrawMeshes)
hook.Add("Tick", "SplatoonSWEPsRegisterInk_cl", GMTick)
