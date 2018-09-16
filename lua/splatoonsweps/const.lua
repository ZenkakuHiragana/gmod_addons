
-- Constant values

local ss = SplatoonSWEPs
if not ss then return end

function ss.ReadJSON(name)
	local path = "data/splatoonsweps/constants/" .. name .. ".json"
	return file.Exists(path, "GAME") and util.JSONToTable(file.Read(path, true)) or {}
end

ss.sp = game.SinglePlayer()
ss.mp = not ss.sp
ss.Options = ss.ReadJSON "options"
ss.WeaponClassNames = ss.ReadJSON "weaponclasses"
ss.WeaponClassNames2 = ss.ReadJSON "weaponclasses2"
ss.TEXTUREFLAGS = ss.ReadJSON "textureflags"
ss.RTResID = {
	MINIMUM	= 0, -- 2048x2048,		32MB
	SMALL	= 1, --	4096x4096,		128MB
	DSMALL	= 2, --	2x4096x4096,	256MB
	MEDIUM	= 3, --	8192x8192,		512MB
	DMEDIUM	= 4, --	2x8192x8192,	1GB 
	LARGE	= 5, --	16384x16384,	2GB
	DLARGE	= 6, --	2x16384x16384,	4GB
	ULTRA	= 7, --	32768x32768,	8GB
	DULTRA	= 8, --	2x32768x32768,	16GB
}

ss.RTSize = {
	[ss.RTResID.MINIMUM	] = 2048,
	[ss.RTResID.SMALL	] = 4096,
	[ss.RTResID.DSMALL	] = 5792,
	[ss.RTResID.MEDIUM	] = 8192,
	[ss.RTResID.DMEDIUM	] = 11585,
	[ss.RTResID.LARGE	] = 16384,
	[ss.RTResID.DLARGE	] = 23170,
	[ss.RTResID.ULTRA	] = 32768,
	[ss.RTResID.DULTRA	] = 40132,
}

ss.RTName = {
	BaseTexture = "splatoonsweps_basetexture",
	Normalmap = "splatoonsweps_normalmap",
	Lightmap = "splatoonsweps_lightmap",
	RenderTarget = "splatoonsweps_rendertarget",
	WaterMaterial = "splatoonsweps_watermaterial",
	RTScope = "splatoonsweps_rtscope",
}

ss.RTFlags = {
	BaseTexture = bit.bor(
		ss.TEXTUREFLAGS.NOMIP,
		ss.TEXTUREFLAGS.NOLOD,
		ss.TEXTUREFLAGS.ALL_MIPS,
		ss.TEXTUREFLAGS.PROCEDURAL,
		ss.TEXTUREFLAGS.RENDERTARGET,
		ss.TEXTUREFLAGS.NODEPTHBUFFER
	),
	Normalmap = bit.bor(
		ss.TEXTUREFLAGS.NORMAL,
		ss.TEXTUREFLAGS.NOMIP,
		ss.TEXTUREFLAGS.NOLOD,
		ss.TEXTUREFLAGS.ALL_MIPS,
		ss.TEXTUREFLAGS.PROCEDURAL,
		ss.TEXTUREFLAGS.RENDERTARGET,
		ss.TEXTUREFLAGS.NODEPTHBUFFER,
		ss.TEXTUREFLAGS.SSBUMP
	),
	Lightmap = bit.bor(
		ss.TEXTUREFLAGS.NOMIP,
		ss.TEXTUREFLAGS.NOLOD,
		ss.TEXTUREFLAGS.ALL_MIPS,
		ss.TEXTUREFLAGS.PROCEDURAL,
		ss.TEXTUREFLAGS.RENDERTARGET,
		ss.TEXTUREFLAGS.NODEPTHBUFFER
	),
}

ss.InkTankModel = Model "models/props_splatoon/gear/inktank_backpack/inktank_backpack.mdl"
ss.PLAYER = {
	GIRL = 1,
	BOY = 2,
	OCTO = 3,
	MARIE = 4,
	CALLIE = 5,
	NOCHANGE = 6,
}
ss.Playermodel = {
	Model "models/drlilrobot/splatoon/ply/inkling_girl.mdl",
	Model "models/drlilrobot/splatoon/ply/inkling_boy.mdl",
	Model "models/drlilrobot/splatoon/ply/octoling.mdl",
	Model "models/drlilrobot/splatoon/ply/marie.mdl",
	Model "models/drlilrobot/splatoon/ply/callie.mdl",
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

local Marie = "models/drlilrobot/splatoon/ply/marie.mdl"
local Callie = "models/drlilrobot/splatoon/ply/callie.mdl"
local InkBoy = "models/drlilrobot/splatoon/ply/inkling_boy.mdl"
local InkGirl = "models/drlilrobot/splatoon/ply/inkling_girl.mdl"
local Octo = "models/drlilrobot/splatoon/ply/octoling.mdl"
ss.ChargingEyeSkin = {
	[Marie] = 0,
	[Callie] = 5,
	[InkBoy] = 4,
	[InkGirl] = 4,
	[Octo] = 4,
}
ss.CheckSplatoonPlayermodels = ss.ChargingEyeSkin

function ss.GetSquidmodel(pmid)
	if pmid == ss.PLAYER.NOCHANGE then return end
	local squid = ss.Squidmodel[pmid == ss.PLAYER.OCTO and ss.SQUID.OCTO or ss.SQUID.INKLING]
	return file.Exists(squid, "GAME") and squid or nil
end

-- List of available ink colors(25 colors)
ss.InkColors = {
	HSVToColor(0,	1,	1	),
	HSVToColor(30,	1,	1	),
	HSVToColor(60,	1,	1	),
	HSVToColor(80,	1,	1	),
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
	HSVToColor(0,	0,	.999),
}

--Workaround of issue #2407 in Facepunch/garrysmod-issues
for i, c in ipairs(ss.InkColors) do
	ss.InkColors[i] = ColorAlpha(c, c.a)
end

ss.CrosshairColors = {
	2, -- Red -> Orange
	1, -- Orange -> Red
	14, -- Yellow -> Olive
	14, -- Yellowish green -> Olive
	15, -- Lime -> Green
	16, -- Spring green -> Dark cyan
	16, -- Cyan -> Dark cyan
	10, -- Azure blue -> Light indigo
	18, -- Blue -> Purple
	9, -- Light indigo -> Blue
	12, -- Magenta -> Deep pink
	11, -- Deep pink -> Magenta
	
	1, -- Maroon -> Red
	15, -- Olive -> Green
	19, -- Green -> Light green
	10, -- Dark cyan -> Light indigo
	10, -- Navy -> Light indigo
	8, -- Purple -> Azure blue
	
	15, -- Light green -> Green
	16, -- Light blue -> Dark cyan
	11, -- Pink -> Magenta
	
	22, -- Black -> Black
	23, -- Gray -> Gray
	24, -- Light gray -> Light gray
	25, -- White -> White
}

ss.Materials = {
	Crosshair = {
		Dot = Material "splatoonsweps/crosshair/dot.vmt",
		Outer = Material "splatoonsweps/crosshair/outer.vmt",
		Inner = Material "splatoonsweps/crosshair/inner.vmt",
		Line = Material "splatoonsweps/crosshair/line.vmt",
		LineColor = Material "splatoonsweps/crosshair/linecolor.vmt",
	},
}

ss.Particles = {
	MuzzleMist = "splatoonsweps_muzzlemist",
}
game.AddParticles "particles/splatoonsweps.pcf"
for _, p in pairs(ss.Particles) do PrecacheParticleSystem(p) end

ss.CleanupTypeInk = "SplatoonSWEPs Ink"
ss.GrayScaleFactor = Vector(.298912, .586611, .114478)
ss.InkGravityMul = 15
ss.MAX_COLORS = #ss.InkColors
ss.COLOR_BITS = 5
ss.PLAYER_BITS = 3
ss.SQUID_BITS = 2
ss.SEND_ERROR_DURATION_BITS = 4
ss.SEND_ERROR_NOTIFY_BITS = 3
ss.MAX_DEGREES_DIFFERENCE = 45 -- Maximum angle difference between two surfaces
ss.MAX_COS_DEG_DIFF = math.cos(math.rad(ss.MAX_DEGREES_DIFFERENCE)) -- Used by filtering process
ss.ViewModel = { -- Viewmodel animations
	Standing = ACT_VM_IDLE, -- Humanoid form
	Squid = ACT_VM_IDLE_LOWERED, -- Squid form
	Throwing = ACT_VM_PULLPIN, -- About to throw sub weapon
	Throw = ACT_VM_THROW, --Actual throw animation
}

function ss.GetColor(colorid)
	return ss.InkColors[colorid or math.random(ss.MAX_COLORS)]
end

if game.GetMap() == "gm_inkopolis_b1" then
	ss.SquidSolidMask = bit.band(MASK_PLAYERSOLID, bit.bnot(CONTENTS_PLAYERCLIP))
	ss.SquidSolidMaskBrushOnly = bit.band(MASK_PLAYERSOLID_BRUSHONLY, bit.bnot(CONTENTS_PLAYERCLIP))
	ss.MASK_GRATE = CONTENTS_PLAYERCLIP
else
	ss.SquidSolidMask = MASK_SHOT
	ss.SquidSolidMaskBrushOnly = MASK_SHOT_PORTAL
	ss.MASK_GRATE = bit.bor(CONTENTS_GRATE, CONTENTS_MONSTER)
end

local framepersec = 60
local inklingspeed = .96 * framepersec
ss.vector_one = Vector(1, 1, 1)
ss.MaxInkAmount = 100
ss.SquidBoundHeight = 32
ss.SquidViewOffset = vector_up * 24
ss.InklingJumpPower = 250
ss.DisruptoredSpeed = .45 -- Disruptor's debuff factor
ss.OnEnemyInkJumpPower = ss.InklingJumpPower * .75
ss.ToHammerUnits = .1 * 3.28084 * 16 * (1.00965 / 1.5) -- = 3.53 Constants for unit conversion
ss.ToHammerUnitsPerSec = ss.ToHammerUnits * framepersec --
ss.ToHammerHealth = 100 --
ss.FrameToSec = 1 / framepersec --
ss.SecToFrame = framepersec --
ss.mDegRandomY = .5 -- Shooter spread angle, yaw (need to be validated)
ss.HealDelay = 60 * ss.FrameToSec -- Time to heal again after taking damage.
ss.ShooterTrailDelay = 2 * ss.FrameToSec -- Time to start moving shooter trail.
ss.SpreadJumpMaxVelocity = 32 -- Shooter spread angle expansion by jumping.
ss.SpreadJumpCoefficient = .25 --   Angle expansion : Player's Z-velocity
ss.SpreadJumpFraction = ss.SpreadJumpCoefficient / ss.SpreadJumpMaxVelocity
ss.SquidSpeedOutofInk = .45 -- Squid speed coefficient if it is out of ink.
ss.CameraFadeDistance = 100^2 -- Thirdperson model fade distance[units^2]
ss.SubWeaponThrowTime = 25 * ss.FrameToSec -- Duration of TPS sub weapon throwing animation.
ss.ShooterDecreaseFrame = 4 * ss.FrameToSec -- Shooters ink velocity deceleration time to fall.
ss.ShooterTermTime = 10 * ss.FrameToSec -- Time to reach terminal velocity
ss.SquidTrace = {
	start = vector_origin, endpos = vector_origin,
	filter = {}, mask = ss.SquidSolidMask,
	collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
	mins = -ss.vector_one, maxs = ss.vector_one,
}

for key, value in pairs {
	InklingBaseSpeed = inklingspeed, -- Walking speed [Splatoon units/60frame]
	SquidBaseSpeed = 1.923 * framepersec, -- Swimming speed [Splatoon units/60frame]
	OnEnemyInkSpeed = inklingspeed / 4, -- On enemy ink speed[Splatoon units/60frame]
	mColRadius = 2, -- Shooter's ink collision radius[Splatoon units]
	mPaintNearDistance = 11, -- Start decreasing distance[Splatoon units]
	mPaintFarDistance = 200, -- Minimum radius distance[Splatoon units]
	mSplashDrawRadius = 3, -- Ink drop position random spread value[Splatoon units]
	mSplashColRadius = 1.5, -- Ink drop collision radius[Splatoon units]
} do
	ss[key] = value * ss.ToHammerUnits
end
