--Splatoon SWEPs library includes
if SERVER then
	for _, folder in ipairs {"splatoonsweps/", "splatoonsweps/client"} do
		for _, f in ipairs(file.Find(folder .. "*.lua", "LUA")) do
			AddCSLuaFile(folder .. f)
		end
	end
end

include("splatoonsweps/" .. (SERVER and "server" or "client") .. "/autorun.lua")
