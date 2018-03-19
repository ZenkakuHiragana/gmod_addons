
--util.AddNetworkString's
local ss = SplatoonSWEPs
if not ss then return end

util.AddNetworkString "SplatoonSWEPs: DrawInk"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Receive ink surface"
util.AddNetworkString "SplatoonSWEPs: Setup ink surface"
net.Receive("SplatoonSWEPs: Setup ink surface", function(length, sender)
	local mode = net.ReadUInt(ss.SETUP_BITS)
	net.Start "SplatoonSWEPs: Receive ink surface"
	net.WriteUInt(mode, ss.SETUP_BITS)
	if mode == ss.SETUPMODE.BEGIN then
		net.WriteFloat(ss.AreaBound)
		net.WriteFloat(ss.AspectSum)
		net.WriteFloat(ss.AspectSumX)
		net.WriteFloat(ss.AspectSumY)
		net.WriteUInt(ss.NumSurfaces + table.Count(ss.Displacements), 32)
		sender.SendSurfaces = coroutine.create(function()
			local count = 0
			for node in ss:BSPPairsAll() do
				local surf = node.Surfaces
				for i, index in ipairs(surf.Indices) do
					net.WriteBool(false)
					net.WriteInt(math.abs(index), ss.SURFACE_INDEX_BITS)
					net.WriteAngle(surf.Angles[i])
					net.WriteFloat(surf.Areas[i])
					net.WriteVector(surf.Bounds[i])
					net.WriteVector(surf.Normals[i])
					net.WriteVector(surf.Origins[i])
					net.WriteUInt(#surf.Vertices[i], ss.FACEVERT_BITS)
					for k, v in ipairs(surf.Vertices[i]) do
						net.WriteVector(v)
					end
					count = count + 1
					if count % 100 == 0 then coroutine.yield() end
				end
			end
			if count % 100 ~= 0 then coroutine.yield() end
			net.WriteBool(true)
			coroutine.yield(true)
		end)
	elseif mode == ss.SETUPMODE.SURFACE then
		assert(sender.SendSurfaces and coroutine.status(sender.SendSurfaces) ~= "dead")
		local ok, msg = coroutine.resume(sender.SendSurfaces)
		if not ok then ErrorNoHalt(msg) elseif msg then
			sender.SendSurfaces = nil
			sender.SendDisplacements = coroutine.create(function()
				for i, disp in pairs(ss.Displacements) do
					local power = math.log(math.sqrt(#disp + 1) - 1, 2) - 1 --1, 2, 3
					assert(power % 1 == 0)
					
					net.WriteBool(false)
					net.WriteInt(i, ss.SURFACE_INDEX_BITS)
					net.WriteUInt(power, 2)
					net.WriteUInt(#disp, 9)
					for k = 0, #disp do
						local v = disp[k]
						net.WriteVector(v.pos)
						net.WriteVector(v.vec)
						net.WriteFloat(v.dist)
					end
					coroutine.yield()
				end
				net.WriteBool(true)
				coroutine.yield(true)
			end)
		end
	elseif mode == ss.SETUPMODE.DISPLACEMENT then
		assert(sender.SendDisplacements and coroutine.status(sender.SendDisplacements) ~= "dead")
		local ok, msg = coroutine.resume(sender.SendDisplacements)
		if not ok then ErrorNoHalt(msg) elseif msg then
			sender.SendDisplacements = nil
			sender.SendInkData = coroutine.create(function()
				for node in ss:BSPPairsAll() do
					local surf = node.Surfaces
					for i, inkcircle in ipairs(surf.InkCircles) do
						for info, zorder in pairs(inkcircle) do
							net.WriteBool(false)
							net.WriteInt(surf.Indices[i], ss.SURFACE_INDEX_BITS)
							net.WriteUInt(info.color, ss.COLOR_BITS)
							net.WriteVector(ss:To3D(info.pos, surf.Origins[i], surf.Angles[i]))
							net.WriteFloat(info.radius)
							net.WriteFloat(info.angle)
							net.WriteUInt(info.texid, 4)
							net.WriteFloat(info.ratio)
							coroutine.yield()
						end
					end
				end
				net.WriteBool(true)
				coroutine.yield(true)
			end)
		end
	elseif mode == ss.SETUPMODE.INKDATA then
		assert(sender.SendInkData and coroutine.status(sender.SendInkData) ~= "dead")
		local ok, msg = coroutine.resume(sender.SendInkData)
		if not ok then ErrorNoHalt(msg) elseif msg then
			sender.SendInkData = nil
			sender.Ready = true
		end
	end
	net.Send(sender)
end)
