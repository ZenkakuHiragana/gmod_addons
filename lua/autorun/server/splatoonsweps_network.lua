
--util.AddNetworkString's
if not SplatoonSWEPs then return end

util.AddNetworkString "SplatoonSWEPs: DrawInk"
util.AddNetworkString "SplatoonSWEPs: Send an error message"
util.AddNetworkString "SplatoonSWEPs: Play damage sound"
util.AddNetworkString "SplatoonSWEPs: Fetch ink information"
net.Receive("SplatoonSWEPs: Fetch ink information", function(length, sender)
	if not sender.FetchInkInfo then
		sender.FetchInkInfo = coroutine.create(function()
			local count = 0
			for node in SplatoonSWEPs:BSPPairsAll() do
				local surf = node.Surfaces
				for i, inkcircle in ipairs(surf.InkCircles) do
					local whitealpha, whiterotate = math.Rand(0, 63), math.Rand(0, 255)
					for info, zorder in pairs(inkcircle) do
						net.Start "SplatoonSWEPs: DrawInk"
						net.WriteUInt(surf.Indices[i], 20)
						net.WriteUInt(info.color, SplatoonSWEPs.COLOR_BITS)
						net.WriteVector(SplatoonSWEPs:To3D(info.pos, surf.Origins[i], surf.Angles[i]))
						net.WriteFloat(info.radius)
						net.WriteFloat(info.angle)
						net.WriteUInt(info.texid, 4)
						net.WriteFloat(info.ratio)
						net.Send(sender)
						count = count + 1
						if count > 10 then coroutine.yield() count = 0 end
					end
				end
			end
			sender:SendLua "SplatoonSWEPs.RenderTarget.Ready = true"
			coroutine.yield(true)
		end)
	end
	
	local ok, msg = coroutine.resume(sender.FetchInkInfo)
	if not ok then ErrorNoHalt(msg) end
	if ok and msg then sender.FetchInkInfo = nil end
end)
