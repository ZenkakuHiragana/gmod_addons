
-- Sound script registrations

local ss = SplatoonSWEPs
if not ss then return end

-- SplatoonSWEPs.BombAvailable
-- SplatoonSWEPs_Ink.HitWorld
-- SplatoonSWEPs_Player.InkDiveDeep
-- SplatoonSWEPs_Player.InkDiveShallow
-- SplatoonSWEPs_Player.InkFootstep
-- SplatoonSWEPs_Player.ToHuman
-- SplatoonSWEPs_Player.ToSquid
-- SplatoonSWEPs_Player.SquidJump
-- SplatoonSWEPs_Player.Swim

ss.EnemyInkSound = Sound "splatoonsweps/player/onenemyink.wav"
ss.SwimSound = Sound "splatoonsweps/player/swimloop.wav"
ss.TankEmpty = Sound "splatoonsweps/player/tankempty.wav"
ss.BombAvailable = Sound "splatoonsweps/player/bombavailable.wav"
ss.DealDamage = Sound "splatoonsweps/player/dealdamagenormal.wav"
ss.DealDamageCritical = Sound "splatoonsweps/player/dealdamagecritical.wav"
ss.TakeDamage = Sound "splatoonsweps/player/takedamage.wav"
ss.ChargerAim = Sound "splatoonsweps/weapons/charger/aim.wav"
ss.ChargerBeep = Sound "splatoonsweps/weapons/charger/beep.mp3"

sound.Add {
	channel = CHAN_BODY,
	name = "SplatoonSWEPs_Player.InkDiveShallow",
	level = 75,
	sound = "splatoonsweps/player/inkdiveshallow.wav",
	volume = 1,
	pitch = {90, 110},
}

sound.Add {
	channel = CHAN_BODY,
	name = "SplatoonSWEPs_Player.InkDiveDeep",
	level = 75,
	sound = "splatoonsweps/player/inkdivedeep.wav",
	volume = 1,
	pitch = 100,
}

sound.Add {
	channel = CHAN_BODY,
	name = "SplatoonSWEPs_Player.ToHuman",
	level = 75,
	sound = "splatoonsweps/player/tohuman.wav",
	volume = 1,
	pitch = 100,
}

sound.Add {
	channel = CHAN_BODY,
	name = "SplatoonSWEPs_Player.ToSquid",
	level = 75,
	sound = "splatoonsweps/player/tosquid.wav",
	volume = 1,
	pitch = 100,
}

sound.Add {
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.EmptyShot",
	level = 75,
	sound = "splatoonsweps/player/emptyshot.wav",
	volume = 1,
	pitch = {85, 95},
}

sound.Add {
	channel = CHAN_ITEM,
	name = "SplatoonSWEPs.ChargerPreFire",
	level = 75,
	sound = "splatoonsweps/weapons/charger/prefire.wav",
	volume = 1,
	pitch = 100,
}

for _, soundData in ipairs {
	{
		channel = CHAN_BODY,
		name = "SplatoonSWEPs_Ink.HitWorld",
		level = 75,
		sound = "splatoonsweps/ink/hit",
		volume = 1,
		pitch = 100,
	},
	{
		channel = CHAN_BODY,
		name = "SplatoonSWEPs_Player.InkFootstep",
		level = 75,
		sound = "splatoonsweps/player/footsteps/slime",
		volume = 1,
		pitch = 80,
	},
	{
		channel = CHAN_BODY,
		name = "SplatoonSWEPs_Player.SquidJump",
		level = 75,
		sound = "splatoonsweps/player/squidjump",
		volume = 1,
		pitch = {95, 105},
	},
} do
	local soundtable = {}
	local i, str = 1, soundData.sound .. "0.wav"
	while file.Exists("sound/" .. str, "GAME") do
		table.insert(soundtable, Sound(str))
		str = soundData.sound .. tostring(i) .. ".wav"
		i = i + 1
	end
	
	soundData.sound = soundtable
	sound.Add(soundData)
end

local WeaponSoundLevel = 80
local WeaponSoundVolume = 1
local WeaponSoundPitch = {90, 110}
sound.Add { -- .52 Gallon / Deco
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.52",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/52.wav",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- .96 Gallon / Deco
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.96",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/96.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Aerospray MG / RG / PG
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Aerospray",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/aerospray.wav",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Blasters except Rapid Blaster series
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Blaster",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/blaster.wav",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Dual Squelcher / Custom
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Dual",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/dual.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- H-3 Nozzlenose / D / Cherry
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.H-3",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/h-3.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Jet Squelcher / Custom
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Jet",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/jet.wav",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- L-3 Nozzlenose / D
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.L-3",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/l-3.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Octoshot Replica
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Octoshot",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/octoshot.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Rapid Blaster / Deco / Pro / Pro Deco
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.RapidBlaster",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/rapidblaster.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Splash-o-matic / Neo
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Splash-o-matic",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/splash-o-matic.mp3",
	volume = WeaponSoundVolume,
	pitch = {95, 115}, -- +5 Pitch
}

sound.Add { -- Splattershot / Tentatek / Wasabi
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Splattershot",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/splattershot.wav",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Splattershot Jr. / Custom
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.SplattershotJr",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/splattershotjr.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Splattershot Pro / Forge / Berry
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.SplattershotPro",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/splattershotpro.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- Sploosh-o-matic / Neo / 7
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Sploosh-o-matic",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/sploosh-o-matic.mp3",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

sound.Add { -- N-Zap 85 / 89 / 83
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Zap",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/shooter/zap.wav",
	volume = WeaponSoundVolume,
	pitch = WeaponSoundPitch,
}

----------------------------------------

local WeakShotLevel = 75
sound.Add { -- Splat Charger / Kelp / Bento
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.SplatCharger",
	level = WeakShotLevel,
	sound = "splatoonsweps/weapons/charger/splatcharger0.wav",
	volume = WeaponSoundVolume,
	pitch = 100,
}

sound.Add { -- Splat Charger / Kelp / Bento, Fully charged
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.SplatChargerFull",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/charger/splatcharger1.wav",
	volume = WeaponSoundVolume,
	pitch = 100,
}

sound.Add { -- E-Liter 3K / Custom
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Eliter3K",
	level = WeakShotLevel,
	sound = "splatoonsweps/weapons/charger/eliter0.mp3",
	volume = WeaponSoundVolume,
	pitch = 100,
}

sound.Add { -- E-Liter 3K / Custom, Fully charged
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Eliter3KFull",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/charger/eliter1.mp3",
	volume = WeaponSoundVolume,
	pitch = 100,
}

sound.Add { -- Classic Squiffer / New / Fresh
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Squiffer",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/charger/squiffer.mp3",
	volume = WeaponSoundVolume,
	pitch = 100,
}

sound.Add { -- Bamboozler Mk.I / Mk.II / MK.III
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Bamboozler",
	level = WeakShotLevel,
	sound = "splatoonsweps/weapons/charger/bamboozler0.mp3",
	volume = WeaponSoundVolume,
	pitch = 100,
}

sound.Add { -- Bamboozler Mk.I / Mk.II / MK.III, Fully charged
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.BamboozlerFull",
	level = WeaponSoundLevel,
	sound = "splatoonsweps/weapons/charger/bamboozler1.mp3",
	volume = WeaponSoundVolume,
	pitch = 100,
}
