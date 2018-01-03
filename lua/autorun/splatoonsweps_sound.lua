
if not SplatoonSWEPs then return end

-- SplatoonSWEPs.BombAvailable
-- SplatoonSWEPs_Ink.HitWorld
-- SplatoonSWEPs_Player.FootstepsInk
-- SplatoonSWEPs_Player.InkDiveDeep
-- SplatoonSWEPs_Player.InkDiveShallow
-- SplatoonSWEPs_Player.ToHuman
-- SplatoonSWEPs_Player.ToSquid
-- SplatoonSWEPs_Player.SquidJump
-- SplatoonSWEPs_Player.Swim

SplatoonSWEPs.EnemyInkSound = Sound "splatoonsweps/player/onenemyink.wav"
SplatoonSWEPs.SwimSound = Sound "splatoonsweps/player/swimloop.wav"
SplatoonSWEPs.TankEmpty = Sound "splatoonsweps/player/tankempty.wav"
SplatoonSWEPs.BombAvailable = Sound "splatoonsweps/player/bombavailable.wav"
SplatoonSWEPs.DealDamage = Sound "splatoonsweps/player/dealdamagenormal.wav"
SplatoonSWEPs.DealDamageCritical = Sound "splatoonsweps/player/dealdamagecritical.wav"
SplatoonSWEPs.TakeDamage = Sound "splatoonsweps/player/takedamage.wav"

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
	channel = CHAN_WEAPON,
	name = "SplatoonSWEPs.Splattershot",
	level = 80,
	sound = "splatoonsweps/weapons/shooter/splattershot.wav",
	volume = 1,
	pitch = {90, 110},
}

for _, soundData in ipairs {
	{
		channel = CHAN_BODY,
		name = "SplatoonSWEPs_Ink.HitWorld",
		level = 60,
		sound = "splatoonsweps/ink/hit",
		volume = 1,
		pitch = 100,
	},
	{
		channel = CHAN_BODY,
		name = "SplatoonSWEPs_Player.FootstepsInk",
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
