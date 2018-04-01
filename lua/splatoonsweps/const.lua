
--Constant values
local ss = SplatoonSWEPs
if not ss then return end

ss.WeaponClassNames = {
	"weapon_52gal",
	"weapon_52gal_deco",
	"weapon_96gal",
	"weapon_96gal_deco",
	"weapon_aerospray_mg",
	"weapon_aerospray_pg",
	"weapon_aerospray_rg",
	"weapon_bamboozler14_mk1",
	"weapon_bamboozler14_mk2",
	"weapon_bamboozler14_mk3",
	"weapon_blaster",
	"weapon_blaster_custom",
	"weapon_carbonroller",
	"weapon_carbonroller_deco",
	"weapon_dualsquelcher",
	"weapon_dualsquelcher_custom",
	"weapon_dynamoroller",
	"weapon_dynamoroller_gold",
	"weapon_dynamoroller_tempered",
	"weapon_eliter3k",
	"weapon_eliter3k_custom",
	"weapon_eliter3k_scope",
	"weapon_eliter3k_scope_custom",
	"weapon_h3nozzlenose",
	"weapon_h3nozzlenose_d",
	"weapon_h3nozzlenose_cherry",
	"weapon_heavysplatling",
	"weapon_heavysplatling_deco",
	"weapon_heavysplatling_remix",
	"weapon_herocharger",
	"weapon_heroroller",
	"weapon_heroshot",
	"weapon_hydrasplatling",
	"weapon_hydrasplatling_custom",
	"weapon_inkbrush",
	"weapon_inkbrush_nouveau",
	"weapon_inkbrush_permanent",
	"weapon_jetsquelcher",
	"weapon_jetsquelcher_custom",
	"weapon_l3nozzlenose",
	"weapon_l3nozzlenose_d",
	"weapon_lunablaster",
	"weapon_lunablaster_neo",
	"weapon_minisplatling",
	"weapon_minisplatling_refurbished",
	"weapon_minisplatling_zink",
	"weapon_nzap83",
	"weapon_nzap85",
	"weapon_nzap89",
	"weapon_octobrush",
	"weapon_octobrush_nouveau",
	"weapon_octoshot",
	"weapon_rangeblaster",
	"weapon_rangeblaster_custom",
	"weapon_rangeblaster_grim",
	"weapon_rapidblaster",
	"weapon_rapidblaster_deco",
	"weapon_rapidblasterpro",
	"weapon_rapidblasterpro_deco",
	"weapon_slosher",
	"weapon_slosher_deco",
	"weapon_slosher_soda",
	"weapon_sloshingmachine",
	"weapon_sloshingmachine_neo",
	"weapon_splash_o_matic",
	"weapon_splash_o_matic_neo",
	"weapon_splatcharger",
	"weapon_splatcharger_kelp",
	"weapon_splatcharger_bento",
	"weapon_splatroller",
	"weapon_splatroller_krakon",
	"weapon_splatroller_corocoro",
	"weapon_splatterscope",
	"weapon_splatterscope_kelp",
	"weapon_splatterscope_bento",
	"weapon_splattershot",
	"weapon_splattershot_tentatek",
	"weapon_splattershot_wasabi",
	"weapon_splattershotjr",
	"weapon_splattershotjr_custom",
	"weapon_splattershotpro",
	"weapon_splattershotpro_forge",
	"weapon_splattershotpro_berry",
	"weapon_sploosh_o_matic",
	"weapon_sploosh_o_matic_neo",
	"weapon_sploosh_o_matic_7",
	"weapon_squiffer_classic",
	"weapon_squiffer_fresh",
	"weapon_squiffer_new",
	"weapon_trislosher",
	"weapon_trislosher_nouveau",
}

ss.WeaponClassNames2 = {
	"weapon_clashblaster",
	"weapon_dappledualies",
	"weapon_dappledualies_nouveau",
	"weapon_darktetradualies",
	"weapon_dualiesquelchers",
	"weapon_eliter4k",
	"weapon_eliter4k_custom",
	"weapon_eliter4k_scope",
	"weapon_eliter4k_scope_custom",
	"weapon_flingzaroller",
	"weapon_flingzaroller_foil",
	"weapon_gloogadualies",
	"weapon_gootuber",
	"weapon_gootuber_custom",
	"weapon_heroblaster",
	"weapon_herobrella",
	"weapon_herobrush",
	"weapon_herodualie",
	"weapon_heroslosher",
	"weapon_herosplatling",
	"weapon_splatbrella",
	"weapon_splatcharger_firefin",
	"weapon_splatdualies",
	"weapon_splatdualies_emperry",
	"weapon_splatterscope_firefin",
	"weapon_squeezer",
	"weapon_tentabrella",
	"weapon_undercoverbrella",
}

ss.ConVar = {
	"cl_splatoonsweps_inkcolor",
	"cl_splatoonsweps_playermodel",
	"cl_splatoonsweps_canhealstand",
	"cl_splatoonsweps_canhealink",
	"cl_splatoonsweps_canreloadstand",
	"cl_splatoonsweps_canreloadink",
	"cl_splatoonsweps_drawinkoverlay",
	"cl_splatoonsweps_rtresolution",
}

ss.ConVarName = {
	InkColor = 1,
	Playermodel = 2,
	CanHealStand = 3,
	CanHealInk = 4,
	CanReloadStand = 5,
	CanReloadInk = 6,
	DrawInkOverlay = 7,
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
	HSVToColor(0,	1,	1	),
	HSVToColor(30,	1,	1	),
	HSVToColor(60,	1,	1	),
	HSVToColor(90,	1,	1	),
	HSVToColor(120,	1,	1	),
	HSVToColor(150,	1,	1	),
	HSVToColor(180,	1,	1	),
	HSVToColor(210,	1,	1	),
	HSVToColor(240,	1,	1	),
	HSVToColor(270,	1,	1	),
	HSVToColor(300,	1,	1	),
	HSVToColor(330,	1,	1	),
	
	HSVToColor(0,	1,	.5	),
	HSVToColor(60,	1,	.5	),
	HSVToColor(120,	1,	.5	),
	HSVToColor(180,	1,	.5	),
	HSVToColor(240,	1,	.5	),
	HSVToColor(300,	1,	.5	),
	
	HSVToColor(105,	.5,	1	),
	HSVToColor(210,	.5,	1	),
	HSVToColor(315,	.5,	1	),
	
	HSVToColor(0,	0,	.03	),
	HSVToColor(0,	0,	.5	),
	HSVToColor(0,	0,	.75	),
	HSVToColor(0,	0,	1	),
}

function ss:GetColor(colorid)
	return InkColors[colorid or math.random(self.MAX_COLORS)]
end

ss.CleanupTypeInk = "SplatoonSWEPs Ink"
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

local framepersec = 60
local inklingspeed = .96 * framepersec
ss.vector_one = Vector(1, 1, 1)
ss.MaxInkAmount = 100
ss.SquidBoundHeight = 32
ss.SquidViewOffset = vector_up * 24
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
