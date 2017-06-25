
util.PrecacheSound("entities/nextbot_tracer/vo/and stay down.wav")
util.PrecacheSound("entities/nextbot_tracer/blink1.wav")
util.PrecacheSound("entities/nextbot_tracer/blink2.wav")
util.PrecacheSound("entities/nextbot_tracer/blink3.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/blink laugh.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/blink wicked.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/down for the count.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/i'm on fire.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/i'm on fire really.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/onspawn.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/pow.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/recall ever get that feeling of.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/recall just in time.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/recall let's try that again.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/recall now, where were we.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/tracer here.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/whee!.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/whoa.wav")
util.PrecacheSound("entities/nextbot_tracer/vo/yeah.wav")

sound.Add({
	name = "Nextbot_Tracer.Blink1",
	channel = CHAN_BODY,
	volume = {0.95, 1},
	level = 105,
	sound = "entities/nextbot_tracer/blink1.wav",
})
sound.Add({
	name = "Nextbot_Tracer.Blink2",
	channel = CHAN_BODY,
	volume = {0.95, 1},
	level = 105,
	sound = "entities/nextbot_tracer/blink2.wav",
})
sound.Add({
	name = "Nextbot_Tracer.Blink3",
	channel = CHAN_BODY,
	volume = {0.95, 1},
	level = 105,
	sound = "entities/nextbot_tracer/blink3.wav",
})
sound.Add({
	name = "Nextbot_Tracer.BlinkVoice",
	channel = CHAN_VOICE,
	volume = 1,
	level = 100,
	sound = {
		"entities/nextbot_tracer/vo/blink laugh.wav",
		"entities/nextbot_tracer/vo/blink wicked.wav",
		"entities/nextbot_tracer/vo/whee!.wav",
		"entities/nextbot_tracer/vo/whoa.wav",
		"entities/nextbot_tracer/vo/yeah.wav",
	},
})
sound.Add({
	name = "Nextbot_Tracer.MeleeFinalBlow",
	channel = CHAN_VOICE,
	volume = 1,
	level = 100,
	sound = {
		"entities/nextbot_tracer/vo/and stay down.wav",
		"entities/nextbot_tracer/vo/down for the count.wav",
		"entities/nextbot_tracer/vo/pow.wav",
	},
})
sound.Add({
	name = "Nextbot_Tracer.OnFire",
	channel = CHAN_VOICE,
	volume = 1,
	level = 100,
	sound = {
		"entities/nextbot_tracer/vo/i'm on fire.wav",
		"entities/nextbot_tracer/vo/i'm on fire really.wav",
	},
})
sound.Add({
	name = "Nextbot_Tracer.OnSpawn",
	channel = CHAN_VOICE,
	volume = 1,
	level = 100,
	sound = "entities/nextbot_tracer/vo/onspawn.wav",
})
sound.Add({
	name = "Nextbot_Tracer.OnSpawnAlly",
	channel = CHAN_VOICE,
	volume = 1,
	level = 100,
	sound = "entities/nextbot_tracer/vo/tracer here.wav",
})
sound.Add({
	name = "Nextbot_Tracer.RecallVoice",
	channel = CHAN_VOICE,
	volume = 1,
	level = 100,
	sound = {
		"entities/nextbot_tracer/vo/recall ever get that feeling of.wav",
		"entities/nextbot_tracer/vo/recall just in time.wav",
		"entities/nextbot_tracer/vo/recall let's try that again.wav",
		"entities/nextbot_tracer/vo/recall now, where were we.wav",
	},
})

if SERVER then
	function ENT:PlayBlink()
		if CurTime() > self.Time.Blink + 2 then
			self.BlinkSoundLevel = 1
		elseif self.BlinkSoundLevel < 3 then
			self.BlinkSoundLevel = self.BlinkSoundLevel + 1
			if self.BlinkSoundLevel == 3 then
				self:EmitSound("Nextbot_Tracer.BlinkVoice")
			end
		end
		
		self.Equipment.Entity:EmitSound("Nextbot_Tracer.Blink" .. self.BlinkSoundLevel)
	end
	
	function ENT:PlayRecall()
		self:EmitSound("Nextbot_Tracer.RecallVoice")
	end
end