
if SERVER then -- SplatoonSWEPs library includes
	for _, folder in ipairs {"splatoonsweps/", "splatoonsweps/client/"} do
		for _, f in ipairs(file.Find(folder .. "*.lua", "LUA")) do
			AddCSLuaFile(folder .. f)
		end -- Finds required lua files automatically and adds them.
	end
end
-- Include the root file.  Other files are listed in it.
include("splatoonsweps/" .. (SERVER and "server" or "client") .. "/autorun.lua")
