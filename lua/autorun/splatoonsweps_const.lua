
--Constant values
if not SplatoonSWEPs then return end

SplatoonSWEPs.ConVarName = {
	InkColor = "cl_splatoonsweps_inkcolor",
	Playermodel = "cl_splatoonsweps_playermodel",
	CanHealStand = "cl_splatoonsweps_canhealstand",
	CanHealInk = "cl_splatoonsweps_canhealink",
	CanReloadStand = "cl_splatoonsweps_canreloadstand",
	CanReloadInk = "cl_splatoonsweps_canreloadink",
}

SplatoonSWEPs.PlayermodelName = {
	"Inkling Girl",
	"Inkling Boy",
	"Octoling",
	"Don't change playermodel",
	"Don't change playermodel and don't become squid",
}
SplatoonSWEPs.PLAYER = {
	GIRL = 1,
	BOY = 2,
	OCTO = 3,
	NOCHANGE = 4,
	NOSQUID = 5,
}
SplatoonSWEPs.Playermodel = {
	"models/drlilrobot/splatoon/ply/inkling_girl.mdl",
	"models/drlilrobot/splatoon/ply/inkling_boy.mdl",
	"models/drlilrobot/splatoon/ply/octoling.mdl",
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

--List of available ink colors
if not SplatoonSWEPs then return end
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
SplatoonSWEPs.GetColor = function(colorid)
	return InkColors[colorid or math.random(SplatoonSWEPs.MAX_COLORS)]
end
