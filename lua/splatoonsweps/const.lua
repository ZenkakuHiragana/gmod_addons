
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
ss.Units = include "splatoonsweps/constants/parameterunits.lua"
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

ss.Materials = {
	Crosshair = {
		Dot = Material "splatoonsweps/crosshair/dot.vmt",
		Flash = Material "splatoonsweps/crosshair/charged.vmt",
		Inner = Material "splatoonsweps/crosshair/inner.vmt",
		Line = Material "splatoonsweps/crosshair/line.vmt",
		LineColor = Material "splatoonsweps/crosshair/linecolor.vmt",
		Outer = Material "splatoonsweps/crosshair/outer.vmt",
	},
	Effects = {
		Hit = Material "splatoonsweps/effects/splatling_muzzleflash",
		HitCritical = Material "particle/particle_glow_04_additive",
		Ink = Material "splatoonsweps/inkeffect",
		Invisible = Material "splatoonsweps/weapons/primaries/shared/weapon_hider",
	},
}

ss.Particles = {
	BlasterTrail = "splatoonsweps_blaster_trail",
	BrushRunning = "splatoonsweps_roller_rolling_brush",
	BrushSplash = "splatoonsweps_roller_splash_brush",
	ChargerFlash = "splatoonsweps_charger_flash",
	ChargerMuzzleFlash = "splatoonsweps_explosion_impact",
	Explosion = "splatoonsweps_explosion",
	MuzzleMist = "splatoonsweps_muzzlemist",
	RollerRolling = "splatoonsweps_roller_rolling",
	RollerSplash = "splatoonsweps_roller_splash",
	SplatlingMuzzleFlash = "splatoonsweps_splatling_muzzleflash",
}

ss.KeyMask = {IN_ATTACK, IN_DUCK, IN_ATTACK2}
ss.KeyMaskFind = {[IN_ATTACK] = true, [IN_DUCK] = true, [IN_ATTACK2] = true}
ss.CleanupTypeInk = "SplatoonSWEPs Ink"
ss.GrayScaleFactor = Vector(.298912, .586611, .114478)
ss.ShooterGravityMul = 15
ss.RollerGravityMul = 2.25
ss.COLOR_BITS = 5 -- unsigned
ss.INK_TYPE_BITS = 4 -- unsigned
ss.PLAYER_BITS = 3 -- unsigned enum
ss.SEND_ERROR_DURATION_BITS = 4 -- unsgined
ss.SEND_ERROR_NOTIFY_BITS = 3 -- unsigned NOTIFY_ enum 0 to 4
ss.SQUID_BITS = 2 -- unsigned enum
ss.SURFACE_ID_BITS = 16 -- signed, for surface ID
ss.WEAPON_CLASSNAMES_BITS = 8 -- unsigned, number of weapon classname array
ss.MAX_DEGREES_DIFFERENCE = 45 -- Maximum angle difference between two surfaces to paint
ss.MAX_COS_DEG_DIFF = math.cos(math.rad(ss.MAX_DEGREES_DIFFERENCE)) -- Used by filtering process
ss.ViewModel = { -- Viewmodel animations
	Standing = ACT_VM_IDLE, -- Humanoid form
	Squid = ACT_VM_IDLE_LOWERED, -- Squid form
	Throwing = ACT_VM_PULLPIN, -- About to throw sub weapon
	Throw = ACT_VM_THROW, -- Actual throw animation
}

-- HACKHACK
-- This is a list of Splatoon maps available in Garry's Mod.
-- They seem unusual and hide our ink.
ss.SplatoonMapPorts = {
	gm_arena_octostomp = true,
	gm_blackbelly_skatepark = true,
	gm_blackbelly_skatepark_night = true,
	-- gm_camp_triggerfish_day_closegate = true,
	-- gm_camp_triggerfish_day_opengate = true,
	-- gm_camp_triggerfish_night_closegate = true,
	-- gm_camp_triggerfish_night_opengate = true,
	gm_flounder_heights_day = true,
	gm_flounder_heights_night = true,
	-- gm_inkopolis_b1 = true,
	-- gm_inkopolis_plaza_day = true,
	-- gm_inkopolis_plaza_fes_day = true,
	-- gm_inkopolis_plaza_fes_night = true,
	-- gm_inkopolis_plaza_night = true,
	-- gm_inkopolis_square = true,
	gm_kelp_dome = true,
	gm_kelp_dome_fes = true,
	-- gm_mako_mart = true,
	-- gm_mako_mart_night = true,
	-- gm_mc_princess_diaries = true,
	gm_moray_towers = true,
	gm_new_albacore_hotel = true,
	-- gm_octo_showdown = true,
	-- gm_octo_valley_hubworld = true,
	-- gm_octo_valley_hubworld_night = true,
	gm_port_mackerel_day = true,
	gm_port_mackerel_night = true,
	gm_skipper_pavilion_day = true,
	gm_skipper_pavilion_night = true,
	gm_shootingrange_splat1 = true,
	gm_shootingrange_splat1_night = true,
	-- gm_snapper_canal = true,
	-- gm_snapper_canal_night = true,
	-- gm_spawning_grounds_fog_high = true,
	-- gm_spawning_grounds_fog_low = true,
	-- gm_spawning_grounds_fog_normal = true,
	-- gm_spawning_grounds_high = true,
	-- gm_spawning_grounds_low = true,
	-- gm_spawning_grounds_night_high = true,
	-- gm_spawning_grounds_night_low = true,
	-- gm_spawning_grounds_night_normal = true,
	-- gm_spawning_grounds_normal = true,
	-- gm_tutorial = true,
	-- gm_tutorial_night = true,
	humpback_pump_track_day = true,
	humpback_pump_track_night = true,
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
	ss.MAX_COLORS = #ss.InkColors
end

do -- Ink distribution map
	local one = string.byte "1"
	local path = "splatoonsweps/constants/inkdistributions/shot%d.lua"
	for i = 1, 12 do
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
game.AddParticles "particles/splatoonsweps.pcf"
for _, p in pairs(ss.Particles) do PrecacheParticleSystem(p) end

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
ss.InkGridSize = 12 -- in Hammer Units
ss.InklingJumpPower = 250
ss.DisruptoredSpeed = .45 -- Disruptor's debuff factor
ss.OnEnemyInkJumpPower = ss.InklingJumpPower * .75
ss.ToHammerUnits = .1 * 3.28084 * 16 * (1.00965 / 1.5) -- = 3.53, Splatoon distance units -> Hammer distance units
ss.ToHammerUnitsPerSec = ss.ToHammerUnits * framepersec -- = 212, Splatoon du/s -> Hammer du/s
ss.ToHammerUnitsPerSec2 = ss.ToHammerUnitsPerSec * framepersec -- = 12720, Splatoon du/s^2 -> Hammer du/s^2
ss.ToHammerHealth = 100 -- Health is normalized in Splatoon (0--1)
ss.FrameToSec = 1 / framepersec -- = 0.016667, Constants for time conversion
ss.SecToFrame = framepersec -- = 60, Constants for time conversion
ss.mDegRandomY = .5 -- Shooter spread angle, yaw (need to be validated)
ss.SquidSpeedOutofInk = .45 -- Squid speed coefficient when it goes out of ink.
ss.CameraFadeDistance = 100^2 -- Thirdperson model fade distance[Hammer units^2]
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

for key, value in pairs {
	AimDuration = 20, -- Change hold type
	CrouchDelay = 6, -- Cannot crouch for some frames after firing.
	HealDelay = 60, -- Time to heal again after taking damage.
	RollerRunoverStopFrame = 30, -- Stopping time when inkling tries to run over.
	RollerDecreaseFrame = 15, -- Rollers ink velocity deceleration time to start falling.
	ShooterDecreaseFrame = 5, -- Shooters ink velocity deceleration time to start falling.
	ShooterTermTime = 10, -- Time to reach the terminal velocity.
	ShooterTrailDelay = 2, -- Time to start to move the latter half of shooter's ink.
	SubWeaponThrowTime = 25, -- Duration of TPS sub weapon throwing animation.
} do
	ss[key] = value * ss.FrameToSec
end

ss.UnitsConverter = {
	["du"] = ss.ToHammerUnits,
	["du/f"] = ss.ToHammerUnitsPerSec,
	["du/f2"] = ss.ToHammerUnitsPerSec2,
	["f"] = ss.FrameToSec,
	["ink"] = ss.MaxInkAmount,
}
