
sound.Add({
	name = "Nextbot.Tracer.Blink1",
	channel = CHAN_BODY,
	volume = {0.95, 1},
	level = 105,
	sound = "entities/nextbot_tracer/blink1.wav",
})
sound.Add({
	name = "Nextbot.Tracer.Blink2",
	channel = CHAN_BODY,
	volume = {0.95, 1},
	level = 105,
	sound = "entities/nextbot_tracer/blink2.wav",
})
sound.Add({
	name = "Nextbot.Tracer.Blink3",
	channel = CHAN_BODY,
	volume = {0.95, 1},
	level = 105,
	sound = "entities/nextbot_tracer/blink3.wav",
})
sound.Add({
	name = "Nextbot.Tracer.BlinkVoice",
	channel = CHAN_BODY,
	volume = 1,
	level = 100,
	sound = {
		"entities/nextbot_tracer/vo/blink laugh.wav",
		"entities/nextbot_tracer/vo/blink wicked.wav",
		"entities/nextbot_tracer/vo/whee!.wav",
		"entities/nextbot_tracer/vo/whoa.wav",
	},
})
sound.Add({
	name = "Nextbot.Tracer.OnSpawn",
	channel = CHAN_BODY,
	volume = 1,
	level = 100,
	sound = "entities/nextbot_tracer/vo/onspawn.wav",
})

function ENT:PlayBlink()
	if CurTime() > self.Time.Blink + 2 then
		self.BlinkSoundLevel = 1
	elseif self.BlinkSoundLevel < 3 then
		self.BlinkSoundLevel = self.BlinkSoundLevel + 1
		if self.BlinkSoundLevel == 3 then
			self:EmitSound("Nextbot.Tracer.BlinkVoice")
		end
	end
	
	self.Equipment.Entity:EmitSound("Nextbot.Tracer.Blink" .. self.BlinkSoundLevel)
end