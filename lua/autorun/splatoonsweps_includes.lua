--Splatoon SWEPs library includes
if SERVER then
	for _, f in ipairs {
		"client/autorun",
		"client/inkmanager",
		"client/network",
		"client/userinfo",
		"const",
		"shared",
		"sound",
		"text",
		"weapons"
	} do
		AddCSLuaFile("splatoonsweps/" .. f .. ".lua")
	end
end

include("splatoonsweps/" .. (SERVER and "server" or "client") .. "/autorun.lua")
