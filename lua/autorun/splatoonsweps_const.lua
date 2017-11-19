
--Constant values
if not SplatoonSWEPs then return end

SplatoonSWEPs.ConVar = {
	"cl_splatoonsweps_inkcolor",
	"cl_splatoonsweps_playermodel",
	"cl_splatoonsweps_canhealstand",
	"cl_splatoonsweps_canhealink",
	"cl_splatoonsweps_canreloadstand",
	"cl_splatoonsweps_canreloadink",
}

SplatoonSWEPs.ConVarName = {
	InkColor = 1,
	Playermodel = 2,
	CanHealStand = 3,
	CanHealInk = 4,
	CanReloadStand = 5,
	CanReloadInk = 6,
}

function SplatoonSWEPs:GetConVarName(name)
	return SplatoonSWEPs.ConVar[SplatoonSWEPs.ConVarName[name]]
end

function SplatoonSWEPs:GetConVar(name)
	return GetConVar(SplatoonSWEPs:GetConVarName(name))
end

function SplatoonSWEPs:GetConVarInt(name)
	local cvar = SplatoonSWEPs:GetConVar(name)
	if cvar then
		return cvar:GetInt()
	else
		return CVAR_DEFAULT[SplatoonSWEPs.ConVarName[name]]
	end
end

function SplatoonSWEPs:GetConVarBool(name)
	return SplatoonSWEPs:GetConVarInt(name) ~= 0
end

SplatoonSWEPs.PlayermodelName = {
	"Inkling Girl",
	"Inkling Boy",
	"Octoling",
	"Marie",
	"Callie",
	"Don't change playermodel",
	"Don't change playermodel and don't become squid",
}
SplatoonSWEPs.PLAYER = {
	GIRL = 1,
	BOY = 2,
	OCTO = 3,
	MARIE = 4,
	CALLIE = 5,
	NOCHANGE = 6,
	NOSQUID = 7,
}
SplatoonSWEPs.Playermodel = {
	"models/drlilrobot/splatoon/ply/inkling_girl.mdl",
	"models/drlilrobot/splatoon/ply/inkling_boy.mdl",
	"models/drlilrobot/splatoon/ply/octoling.mdl",
	"models/drlilrobot/splatoon/ply/marie.mdl",
	"models/drlilrobot/splatoon/ply/callie.mdl",
	nil,
	nil,
}
for i, v in ipairs(SplatoonSWEPs.Playermodel) do
	util.PrecacheModel(v)
end

SplatoonSWEPs.SQUID = {
	INKLING = 1,
	KRAKEN = 2,
	OCTO = 3,
}
SplatoonSWEPs.Squidmodel = {
	"models/props_splatoon/squids/squid_beta.mdl",
	"models/props_splatoon/squids/kraken_beta.mdl",
	"models/props_splatoon/squids/octopus_beta.mdl",
}
for i, v in ipairs(SplatoonSWEPs.Squidmodel) do
	util.PrecacheModel(v)
end

SplatoonSWEPs.SEND_ERROR_DURATION_BITS = 4
SplatoonSWEPs.SEND_ERROR_NOTIFY_BITS = 3

--List of available ink colors
local InkColors = {
	Color(255, 165, 0), --Orange
	Color(255, 144, 192), --Pink
	Color(160, 0, 160), --Purple
	Color(0, 255, 0), --Green
	Color(0, 160, 0), --Dark green
	Color(0, 255, 255), --Cyan
	Color(0, 139, 139), --Dark cyan
	Color(0, 0, 255), --Blue
	Color(0, 191, 255), --Sky blue
	Color(255, 0, 0), --Red
	Color(178, 34, 34), --Dark red
	Color(255, 255, 0), --Yellow
	Color(178, 178, 0), --Dark yellow
	Color(255, 255, 255), --White
	Color(3, 3, 3), --Black
	Color(169, 169, 169), --Grey
}
SplatoonSWEPs.COLOR = {
	ORANGE = 1,
	PINK = 2,
	PURPLE = 3,
	GREEN = 4,
	DARKGREEN = 5,
	CYAN = 6,
	DARKCYAN = 7,
	BLUE = 8,
	SKYBLUE = 9,
	RED = 10,
	DARKRED = 11,
	YELLOW = 12,
	DARKYELLOW = 13,
	WHITE = 14,
	BLACK = 15,
	GREY = 16,
}
SplatoonSWEPs.ColorName = {
	"Orange",
	"Pink",
	"Purple",
	"Green",
	"Dark green",
	"Cyan",
	"Dark cyan",
	"Blue",
	"Sky blue",
	"Red",
	"Dark red",
	"Yellow",
	"Dark yellow",
	"White",
	"Black",
	"Grey",
}
SplatoonSWEPs.MAX_COLORS = #InkColors
SplatoonSWEPs.COLOR_BITS = 5
function SplatoonSWEPs.GetColor(colorid)
	return InkColors[colorid or math.random(SplatoonSWEPs.MAX_COLORS)]
end
