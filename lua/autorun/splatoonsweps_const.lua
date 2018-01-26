
--Constant values
if not SplatoonSWEPs then return end

SplatoonSWEPs.ConVar = {
	"cl_splatoonsweps_inkcolor",
	"cl_splatoonsweps_playermodel",
	"cl_splatoonsweps_canhealstand",
	"cl_splatoonsweps_canhealink",
	"cl_splatoonsweps_canreloadstand",
	"cl_splatoonsweps_canreloadink",
	"cl_splatoonsweps_hideinkoverlay",
	"cl_splatoonsweps_rtresolution",
}

SplatoonSWEPs.ConVarName = {
	InkColor = 1,
	Playermodel = 2,
	CanHealStand = 3,
	CanHealInk = 4,
	CanReloadStand = 5,
	CanReloadInk = 6,
	HideInkOverlay = 7,
	RTResolution = 8,
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
	Model "models/drlilrobot/splatoon/ply/inkling_girl.mdl",
	Model "models/drlilrobot/splatoon/ply/inkling_boy.mdl",
	Model "models/drlilrobot/splatoon/ply/octoling.mdl",
	Model "models/drlilrobot/splatoon/ply/marie.mdl",
	Model "models/drlilrobot/splatoon/ply/callie.mdl",
	nil,
	nil,
}

SplatoonSWEPs.SQUID = {
	INKLING = 1,
	KRAKEN = 2,
	OCTO = 3,
}
SplatoonSWEPs.Squidmodel = {
	Model "models/props_splatoon/squids/squid_beta.mdl",
	Model "models/props_splatoon/squids/kraken_beta.mdl",
	Model "models/props_splatoon/squids/octopus_beta.mdl",
}

--List of available ink colors(25 colors)
local InkColors = {
	{Name = "Red",
		HSVToColor(0, 1, 1)
	},
	{Name = "Orange",
		HSVToColor(30, 1, 1)
	},
	{Name = "Yellow",
		HSVToColor(60, 1, 1)
	},
	{Name = "Yellowish green",
		HSVToColor(90, 1, 1)
	},
	{Name = "Lime",
		HSVToColor(120, 1, 1)
	},
	{Name = "Spring green",
		HSVToColor(150, 1, 1)
	},
	{Name = "Cyan",
		HSVToColor(180, 1, 1)
	},
	{Name = "Azure blue",
		HSVToColor(210, 1, 1)
	},
	{Name = "Blue",
		HSVToColor(240, 1, 1)
	},
	{Name = "Light indigo",
		HSVToColor(270, 1, 1)
	},
	{Name = "Magenta",
		HSVToColor(300, 1, 1)
	},
	{Name = "Deep pink",
		HSVToColor(330, 1, 1)
	},
	
	{Name = "Maroon",
		HSVToColor(0, 1, .5)
	},
	{Name = "Olive",
		HSVToColor(60, 1, .5)
	},
	{Name = "Green",
		HSVToColor(120, 1, .5)
	},
	{Name = "Dark cyan",
		HSVToColor(180, 1, .5)
	},
	{Name = "Navy",
		HSVToColor(240, 1, .5)
	},
	{Name = "Purple",
		HSVToColor(300, 1, .5)
	},
	
	{Name = "Light green",
		HSVToColor(105, .5, 1)
	},
	{Name = "Light blue",
		HSVToColor(210, .5, 1)
	},
	{Name = "Pink",
		HSVToColor(315, .5, 1)
	},
	
	{Name = "Black",
		HSVToColor(0, 0, .05)
	},
	{Name = "Gray",
		HSVToColor(0, 0, .5)
	},
	{Name = "Light gray",
		HSVToColor(0, 0, .75)
	},
	{Name = "White",
		HSVToColor(0, 0, 1)
	},
}

function SplatoonSWEPs:GetColorName(colorid)
	return InkColors[colorid or math.random(SplatoonSWEPs.MAX_COLORS)].Name
end
function SplatoonSWEPs:GetColor(colorid)
	return InkColors[colorid or math.random(SplatoonSWEPs.MAX_COLORS)][1]
end

SplatoonSWEPs.GrayScaleFactor = Vector(.298912, .586611, .114478)
SplatoonSWEPs.MAX_COLORS = #InkColors
SplatoonSWEPs.COLOR_BITS = 6
SplatoonSWEPs.SEND_ERROR_DURATION_BITS = 4
SplatoonSWEPs.SEND_ERROR_NOTIFY_BITS = 3
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

SplatoonSWEPs.vector_one = Vector(1, 1, 1)
SplatoonSWEPs.MaxInkAmount = 100
SplatoonSWEPs.MaxVelocity = 32768 --physenv.GetPerformanceSettings().MaxVelocity, default is 3500
SplatoonSWEPs.SquidBoundMins = -Vector(13, 13, 0)
SplatoonSWEPs.SquidBoundMaxs = Vector(13, 13, 32)
SplatoonSWEPs.SquidViewOffset = Vector(0, 0, 24)
SplatoonSWEPs.InklingJumpPower = 250
SplatoonSWEPs.OnEnemyInkJumpPower = SplatoonSWEPs.InklingJumpPower * .75
SplatoonSWEPs.ToHammerUnits = 0.1 * 3.28084 * 16
for key, value in pairs {
	InklingBaseSpeed = .96 * 60, --Walking speed [Splatoon units/frame]
	SquidBaseSpeed = 1.923 * 60, --Swimming speed [Splatoon units/frame]
	OnEnemyInkSpeed = .96 * 60 / 4, --On enemy ink speed[Splatoon units/frame]
	mColRadius = 2, --Shooter's ink collision radius
	mPaintNearDistance = 11, --Start decreasing distance
	mPaintFarDistance = 200, --Minimum radius after distance
	mSplashDrawRadius = 3, --Ink drop position random spread value
	mSplashColRadius = 1.5, --Ink drop collision radius
} do
	SplatoonSWEPs[key] = value * SplatoonSWEPs.ToHammerUnits
end
