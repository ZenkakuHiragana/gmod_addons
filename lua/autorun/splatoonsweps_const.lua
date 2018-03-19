
--Constant values
local ss = SplatoonSWEPs
if not ss then return end

ss.ConVar = {
	"cl_splatoonsweps_inkcolor",
	"cl_splatoonsweps_playermodel",
	"cl_splatoonsweps_canhealstand",
	"cl_splatoonsweps_canhealink",
	"cl_splatoonsweps_canreloadstand",
	"cl_splatoonsweps_canreloadink",
	"cl_splatoonsweps_hideinkoverlay",
	"cl_splatoonsweps_rtresolution",
}

ss.ConVarName = {
	InkColor = 1,
	Playermodel = 2,
	CanHealStand = 3,
	CanHealInk = 4,
	CanReloadStand = 5,
	CanReloadInk = 6,
	HideInkOverlay = 7,
	RTResolution = 8,
}

ss.RTResID = {
	SMALL	= 1, --	4096x4096,		128MB
	DSMALL	= 2, --	2x4096x4096,	256MB
	MEDIUM	= 3, --	8192x8192,		512MB
	DMEDIUM	= 4, --	2x8192x8192,	1GB 
	LARGE	= 5, --	16384x16384,	2GB
	DLARGE	= 6, --	2x16384x16384,	4GB
	ULTRA	= 7, --	32768x32768,	8GB
	DULTRA	= 8, --	2x32768x32768,	16GB
}

ss.ConVarDefaults = {
	1,
	1,
	1,
	1,
	1,
	1,
	0,
	ss.RTResID.MEDIUM,
}

ss.RTSize = {
	[ss.RTResID.SMALL	] = 4096,
	[ss.RTResID.DSMALL	] = 5792,
	[ss.RTResID.MEDIUM	] = 8192,
	[ss.RTResID.DMEDIUM	] = 11585,
	[ss.RTResID.LARGE	] = 16384,
	[ss.RTResID.DLARGE	] = 23170,
	[ss.RTResID.ULTRA	] = 32768,
	[ss.RTResID.DULTRA	] = 40132,
}

function ss:GetConVarName(name)
	return self.ConVar[self.ConVarName[name]]
end

function ss:GetConVar(name)
	return GetConVar(self:GetConVarName(name))
end

function ss:GetConVarInt(name)
	local cvar = self:GetConVar(name)
	if cvar then
		return cvar:GetInt()
	else
		return self.ConVarDefaults[self.ConVarName[name]]
	end
end

function ss:GetConVarBool(name)
	return ss:GetConVarInt(name) ~= 0
end

ss.PlayermodelName = {
	"Inkling Girl",
	"Inkling Boy",
	"Octoling",
	"Marie",
	"Callie",
	"Don't change playermodel",
	"Don't change playermodel and don't become squid",
}
ss.PLAYER = {
	GIRL = 1,
	BOY = 2,
	OCTO = 3,
	MARIE = 4,
	CALLIE = 5,
	NOCHANGE = 6,
	NOSQUID = 7,
}
ss.Playermodel = {
	Model "models/drlilrobot/splatoon/ply/inkling_girl.mdl",
	Model "models/drlilrobot/splatoon/ply/inkling_boy.mdl",
	Model "models/drlilrobot/splatoon/ply/octoling.mdl",
	Model "models/drlilrobot/splatoon/ply/marie.mdl",
	Model "models/drlilrobot/splatoon/ply/callie.mdl",
	nil,
	nil,
}

ss.SQUID = {
	INKLING = 1,
	KRAKEN = 2,
	OCTO = 3,
}
ss.Squidmodel = {
	Model "models/props_splatoon/squids/squid_beta.mdl",
	Model "models/props_splatoon/squids/kraken_beta.mdl",
	Model "models/props_splatoon/squids/octopus_beta.mdl",
}

function ss:GetSquidmodel(pmid)
	if pmid == self.PLAYER.NOSQUID or pmid == self.PLAYER.NOCHANGE then return end
	local squid = self.Squidmodel[pmid == self.PLAYER.OCTO and self.SQUID.OCTO or self.SQUID.INKLING]
	return file.Exists(squid, "GAME") and squid or nil
end

--List of available ink colors(25 colors)
local InkColors = {
	{Name = "Red",				HSVToColor(0,	1,	1)},
	{Name = "Orange",			HSVToColor(30,	1,	1)},
	{Name = "Yellow",			HSVToColor(60,	1,	1)},
	{Name = "Yellowish green",	HSVToColor(90,	1,	1)},
	{Name = "Lime",				HSVToColor(120,	1,	1)},
	{Name = "Spring green",		HSVToColor(150,	1,	1)},
	{Name = "Cyan",				HSVToColor(180,	1,	1)},
	{Name = "Azure blue",		HSVToColor(210,	1,	1)},
	{Name = "Blue",				HSVToColor(240,	1,	1)},
	{Name = "Light indigo",		HSVToColor(270,	1,	1)},
	{Name = "Magenta",			HSVToColor(300,	1,	1)},
	{Name = "Deep pink",		HSVToColor(330,	1,	1)},
	
	{Name = "Maroon",			HSVToColor(0,	1,	.5)},
	{Name = "Olive",			HSVToColor(60,	1,	.5)},
	{Name = "Green",			HSVToColor(120,	1,	.5)},
	{Name = "Dark cyan",		HSVToColor(180,	1,	.5)},
	{Name = "Navy",				HSVToColor(240,	1,	.5)},
	{Name = "Purple",			HSVToColor(300,	1,	.5)},
	
	{Name = "Light green",		HSVToColor(105,	.5,	1)},
	{Name = "Light blue",		HSVToColor(210,	.5,	1)},
	{Name = "Pink",				HSVToColor(315,	.5,	1)},
	
	{Name = "Black",			HSVToColor(0,	0,	.03)},
	{Name = "Gray",				HSVToColor(0,	0,	.5)},
	{Name = "Light gray",		HSVToColor(0,	0,	.75)},
	{Name = "White",			HSVToColor(0,	0,	1)},
}

function ss:GetColorName(colorid)
	return InkColors[colorid or math.random(self.MAX_COLORS)].Name
end
function ss:GetColor(colorid)
	return InkColors[colorid or math.random(self.MAX_COLORS)][1]
end

ss.GrayScaleFactor = Vector(.298912, .586611, .114478)
ss.MAX_COLORS = #InkColors
ss.COLOR_BITS = 6
ss.SURFACE_INDEX_BITS = 20
ss.SEND_ERROR_DURATION_BITS = 4
ss.SEND_ERROR_NOTIFY_BITS = 3
ss.TEXTUREFLAGS = {
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

ss.FACEVERT_BITS = 7
ss.SETUP_BITS = 2
ss.SETUPMODE = {
	BEGIN = 0,
	SURFACE = 1,
	DISPLACEMENT = 2,
	INKDATA = 3,
}

local framepersec = 60
local inklingspeed = .96 * framepersec
ss.vector_one = Vector(1, 1, 1)
ss.MaxInkAmount = 100
ss.SquidBoundMins = -Vector(13, 13, 0)
ss.SquidBoundMaxs = Vector(13, 13, 32)
ss.SquidViewOffset = Vector(0, 0, 24)
ss.InklingJumpPower = 250
ss.DisruptoredSpeed = .45 --Disruptor's debuff factor
ss.OnEnemyInkJumpPower = ss.InklingJumpPower * .75
ss.ToHammerUnits = 2.88 --.1 * 3.28084 * 16 * (1.00965 / 1.5)
ss.ToHammerUnitsPerSec = ss.ToHammerUnits * framepersec
ss.ToHammerHealth = 100
ss.FrameToSec = 1 / framepersec
ss.SecToFrame = framepersec
ss.mDegRandomY = 1.5 --Crosshair ratio in Splattershot Pro is 2:1, mDegRandom of that is 3.00.
for key, value in pairs {
	InklingBaseSpeed = inklingspeed, --Walking speed [Splatoon units/60frame]
	SquidBaseSpeed = 1.923 * framepersec, --Swimming speed [Splatoon units/60frame]
	OnEnemyInkSpeed = inklingspeed / 4, --On enemy ink speed[Splatoon units/60frame]
	mColRadius = 2, --Shooter's ink collision radius[Splatoon units]
	mPaintNearDistance = 11, --Start decreasing distance[Splatoon units]
	mPaintFarDistance = 200, --Minimum radius distance[Splatoon units]
	mSplashDrawRadius = 3, --Ink drop position random spread value[Splatoon units]
	mSplashColRadius = 1.5, --Ink drop collision radius[Splatoon units]
} do
	ss[key] = value * ss.ToHammerUnits
end
