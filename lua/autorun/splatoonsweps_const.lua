
--Constant values
if not SplatoonSWEPs then return end

SplatoonSWEPs.ConVar = {
	"cl_splatoonsweps_inkcolor",
	"cl_splatoonsweps_playermodel",
	"cl_splatoonsweps_canhealstand",
	"cl_splatoonsweps_canhealink",
	"cl_splatoonsweps_canreloadstand",
	"cl_splatoonsweps_canreloadink",
	"cl_splatoonsweps_rtresolution",
}

SplatoonSWEPs.ConVarName = {
	InkColor = 1,
	Playermodel = 2,
	CanHealStand = 3,
	CanHealInk = 4,
	CanReloadStand = 5,
	CanReloadInk = 6,
	RTResolution = 7,
}

SplatoonSWEPs.RTResID = {
	SMALL	= 1, --	4096x4096,		128MB
	DSMALL	= 2, --	2x4096x4096,	256MB
	MEDIUM	= 3, --	8192x8192,		512MB
	DMEDIUM	= 4, --	2x8192x8192,	1GB 
	LARGE	= 5, --	16384x16384,	2GB
	DLARGE	= 6, --	2x16384x16384,	4GB
	ULTRA	= 7, --	32768x32768,	8GB
	DULTRA	= 8, --	2x32768x32768,	16GB
}

SplatoonSWEPs.RTSize = {
	[SplatoonSWEPs.RTResID.SMALL	] = 4096,
	[SplatoonSWEPs.RTResID.DSMALL	] = 5792,
	[SplatoonSWEPs.RTResID.MEDIUM	] = 8192,
	[SplatoonSWEPs.RTResID.DMEDIUM	] = 11585,
	[SplatoonSWEPs.RTResID.LARGE	] = 16384,
	[SplatoonSWEPs.RTResID.DLARGE	] = 23170,
	[SplatoonSWEPs.RTResID.ULTRA	] = 32768,
	[SplatoonSWEPs.RTResID.DULTRA	] = 40132,
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
function SplatoonSWEPs:GetColor(colorid)
	return InkColors[colorid or math.random(SplatoonSWEPs.MAX_COLORS)]
end

SplatoonSWEPs.TEXTUREFLAGS = {
	POINTSAMPLE			= 0x00000001, --Low quality, "pixel art" texture filtering.
	TRILINEAR			= 0x00000002, --Medium quality texture filtering.
	CLAMPS				= 0x00000004, --Clamp S coordinates.
	CLAMPT				= 0x00000008, --Clamp T coordinates.
	ANISOTROPIC			= 0x00000010, --High quality texture filtering.
	HINT_DXT5			= 0x00000020, --Used in skyboxes.  Make sure edges are seamless.
	PWL_CORRECTED		= 0x00000040, --Purpose unknown.
	NORMAL				= 0x00000080, --Texture is a normal map.
	NOMIP				= 0x00000100, --Render largest mipmap only. (Does not delete existing mipmaps, just disables them.)
	NOLOD				= 0x00000200, --Not affected by texture resolution settings.
	ALL_MIPS			= 0x00000400, --No Minimum Mipmap
	PROCEDURAL			= 0x00000800, --Texture is an procedural texture (code can modify it).
	ONEBITALPHA			= 0x00001000, --One bit alpha channel used.
	EIGHTBITALPHA		= 0x00002000, --Eight bit alpha channel used.
	ENVMAP				= 0x00004000, --Texture is an environment map.
	RENDERTARGET		= 0x00008000, --Texture is a render target.
	DEPTHRENDERTARGET	= 0x00010000, --Texture is a depth render target.
	NODEBUGOVERRIDE		= 0x00020000, --
	SINGLECOPY			= 0x00040000, --
	UNUSED_00080000		= 0x00080000, --
	IMMEDIATE_CLEANUP	= 0x00100000, --Immediately destroy this texture when its refernce count hits zero.
	UNUSED_00200000		= 0x00200000, --
	UNUSED_00400000		= 0x00400000, --
	NODEPTHBUFFER		= 0x00800000, --Do not buffer for Video Processing, generally render distance.
	UNUSED_01000000		= 0x01000000, --
	CLAMPU				= 0x02000000, --Clamp U coordinates (for volumetric textures).
	VERTEXTEXTURE		= 0x04000000, --Usable as a vertex texture
	SSBUMP				= 0x08000000, --Texture is a SSBump. (SSB)
	UNUSED_10000000		= 0x10000000, --
	BORDER				= 0x20000000, --Clamp to border colour on all texture coordinates.
	UNUSED_40000000		= 0x40000000, --
	UNUSED_80000000		= 0x80000000, --
}
