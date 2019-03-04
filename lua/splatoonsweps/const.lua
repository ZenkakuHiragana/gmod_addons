
-- Constant values

local ss = SplatoonSWEPs
if not ss then return end

local InkGirl = Model "models/drlilrobot/splatoon/ply/inkling_girl.mdl"
local InkBoy = Model "models/drlilrobot/splatoon/ply/inkling_boy.mdl"
local Octo = Model "models/drlilrobot/splatoon/ply/octoling.mdl"
local Marie = Model "models/drlilrobot/splatoon/ply/marie.mdl"
local Callie = Model "models/drlilrobot/splatoon/ply/callie.mdl"
local OctoGirl = Model "models/player/octoling.mdl"
local OctoBoy = Model "models/player/octoling_male.mdl"

ss.sp = game.SinglePlayer()
ss.mp = not ss.sp
ss.Options = include "splatoonsweps/constants/options.lua"
ss.WeaponClassNames = include "splatoonsweps/constants/weaponclasses.lua"
ss.WeaponClassNames2 = include "splatoonsweps/constants/weaponclasses2.lua"
ss.TEXTUREFLAGS = include "splatoonsweps/constants/textureflags.lua"
ss.RenderTarget = table.Merge(ss.RenderTarget, include "splatoonsweps/constants/rendertarget.lua")
ss.InkTankModel = Model "models/props_splatoon/gear/inktank_backpack/inktank_backpack.mdl"
ss.Playermodel = {nil, InkGirl, InkBoy, Marie, Callie, Octo, OctoGirl, OctoBoy}
ss.PLAYER = {
	NOCHANGE = 1,
	GIRL = 2,
	BOY = 3,
	MARIE = 4,
	CALLIE = 5,
	OCTO = 6,
	OCTOGIRL = 7,
	OCTOBOY = 8,
}

ss.SQUID = {
	INKLING = 1,
	KRAKEN = 2,
	OCTO = 3,
}
ss.Squidmodel = {
	[ss.SQUID.INKLING] = Model "models/props_splatoon/squids/squid_beta.mdl",
	[ss.SQUID.KRAKEN] = Model "models/props_splatoon/squids/kraken_beta.mdl",
	[ss.SQUID.OCTO] = Model "models/props_splatoon/squids/octopus_beta.mdl",
}

ss.SquidmodelIndex = {
	[ss.PLAYER.NOCHANGE] = ss.SQUID.INKLING,
	[ss.PLAYER.GIRL] = ss.SQUID.INKLING,
	[ss.PLAYER.BOY] = ss.SQUID.INKLING,
	[ss.PLAYER.MARIE] = ss.SQUID.INKLING,
	[ss.PLAYER.CALLIE] = ss.SQUID.INKLING,
	[ss.PLAYER.OCTO] = ss.SQUID.OCTO,
	[ss.PLAYER.OCTOGIRL] = ss.SQUID.OCTO,
	[ss.PLAYER.OCTOBOY] = ss.SQUID.OCTO,
}

ss.ChargingEyeSkin = {
	[Marie] = 0,
	[Callie] = 5,
	[InkBoy] = 4,
	[InkGirl] = 4,
	[Octo] = 4,
}
ss.DrLilRobotPlayermodels = {
	[InkGirl] = true,
	[InkBoy] = true,
	[Marie] = true,
	[Callie] = true,
	[Octo] = true,
}
ss.TwilightPlayermodels = {
	[OctoGirl] = true,
	[OctoBoy] = true, -- Can't apply flex manipulation with Octoling boy.
}

function ss.GetSquidmodel(pmid)
	if pmid == ss.PLAYER.NOCHANGE then return end
	local squid = ss.Squidmodel[ss.SquidmodelIndex[pmid] or ss.SQUID.INKLING]
	return file.Exists(squid, "GAME") and squid or nil
end

for i, t in ipairs(include "splatoonsweps/constants/inkcolors.lua") do
	local c = HSVToColor(t[1], t[2], t[3])
	ss.InkColors[i] = ColorAlpha(c, c.a)
	ss.CrosshairColors[i] = t[4]
end

ss.Materials = {
	Crosshair = {
		Dot = Material "splatoonsweps/crosshair/dot.vmt",
		Flash = Material "splatoonsweps/crosshair/charged.vmt",
		Inner = Material "splatoonsweps/crosshair/inner.vmt",
		Line = Material "splatoonsweps/crosshair/line.vmt",
		LineColor = Material "splatoonsweps/crosshair/linecolor.vmt",
		Outer = Material "splatoonsweps/crosshair/outer.vmt",
	},
}

do -- Ink distribution map
	local one = string.byte "1"
	local path = "splatoonsweps/constants/inkdistributions/shot%d.lua"
	for i = 1, 9 do
		local f, mask = path:format(i), {}
		local w, h, data = include(f)
		mask.width, mask.height = w, h
		data = string.Explode("\n", data)
		for y = 1, h do
			for x, d in ipairs {data[y]:byte(1, #data[y])} do
				mask[x] = mask[x] or {}
				mask[x][y] = d == one
			end
		end

		ss.InkShotMaterials[i] = mask
	end
end

ss.Particles = {
	Explosion = "splatoonsweps_explosion",
	MuzzleMist = "splatoonsweps_muzzlemist",
}
game.AddParticles "particles/splatoonsweps.pcf"
for _, p in pairs(ss.Particles) do PrecacheParticleSystem(p) end

ss.KeyMask = {IN_ATTACK, IN_DUCK, IN_ATTACK2}
ss.KeyMaskFind = {[IN_ATTACK] = true, [IN_DUCK] = true, [IN_ATTACK2] = true}
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

function ss.GetColor(colorid) return ss.InkColors[tonumber(colorid)] end

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
