
ENT.Weapon = {}
--Creates a weapon information class.
--Arguments:
--Nextbot self | The owner of the weapon.
--string name | Classname of the weapon.
--number clip | Clip size.
--number numbullets | Amount of bullets per shot.
--number spread | Acculacy of the weapon.
--number dmg | Amount of damage per bullet.
--string ammotype | Type of ammo.
--table delay | Parameters about time.
----number firerate | Waiting time to the next fire.
----number reloadtime | How long does reloading weapon take.
----number reloadsound | Reloading sound plays after waiting this time.
--table muzzle | Parameters about muzzle flash.
----number probability | How often the effect appears.
----number scale | Effect scale.
--table snd | Parameters about sound.
----string fire | Firing sound.
----string reload | Reloading sound.
--function fire | Firing function(Optional).
----Arguments:
----Nextbot self | The owner of the weapon.
----Entity weapon | The weapon.
local defaultparameter = {
	name = "weapon_pistol",
	clip = 18,
	numbullets = 1,
	spread = 10,
	dmg = 5,
	ammotype = "Pistol",
	delay = {				--Table of cooldown timers
		firerate = 0.4,		--Fire rate
		reloadtime = 1.2,	--Time to reload
		reloadsound = 0,	--Reload sound delay
	},
	muzzle = {				--Parameters of muzzle flash
		probability = 0.5,	--How often the effect appears
		scale = 0.6,		--Scale of the effect
	},
	snd = {					--Parameters of weapon sound
		fire = "Weapon_Pistol.NPC_Single",	--Firing sound
		reload = "Weapon_Pistol.NPC_Reload"	--Reloading sound
	},
	firefunction = ENT.Weapon.Fire,
}
function ENT.Weapon.Create(self, param)
	local param = istable(param) and param or defaultparameter
	
	local ent = ents.Create(param.name)
	if not IsValid(ent) then
		ent = NULL
		return
	else
		local att = "anim_attachment_RH"
		ent.Owner = self
		--Adds Spawn Flags.  2 .. Deny player pickup, 4 .. Not puntable bu Gravity Gun.
		ent:SetKeyValue("spawnflags", 2+4)
		ent:SetParent(self)
		ent:SetOwner(self)
		ent:Fire("SetParentAttachmentMaintainOffset", att)
		ent:AddEffects(EF_BONEMERGE)
		ent:Spawn()
	end
	
	return setmetatable({
		Entity = ent,				--Weapon entity
		Name = param.name,			--Weapon classname
		Clip = param.clip,			--Clip size
		Ammo = param.clip,			--Ammo that the weapon now has
		Num = param.numbullets,		--Amount of bullets per shot
		Spread = param.spread,		--Bullet spread
		Damage = param.dmg,	 		--Damage per bullets
		AmmoType = param.ammotype,	--Ammo type
		Delay = {
			Fire = param.delay.firerate,
			Reload = param.delay.reloadtime,
			ReloadSound = param.delay.reloadsound,
		},
		Muzzle = {
			Probability = param.muzzle.probability,
			Scale = param.muzzle.scale,
		},
		Sound = {
			Fire = param.snd.fire,
			Reload = param.snd.reload,
		},
		Fire = param.firefunction,
	}, {__index = self.Weapon})
end

local function DefaultFireCallback(attacker, tr, dmginfo)
	if not IsValid(attacker) or not istable(attacker.Equipment)
		or not IsValid(attacker.Equipment.Entity) then return end
	if not IsValid(tr.Entity) then return end
	
	dmginfo:SetInflictor(attacker.Equipment.Entity)
	local c = tr.Entity:GetClass()			
	if c == "npc_turret_floor" then
		tr.Entity:Fire("SelfDestruct")
	elseif c == "npc_rollermine" then
		util.BlastDamage(game.GetWorld(), game.GetWorld(), tr.Entity:GetPos(), 1, 1)
	end
end

--Default function to fire bullets.
--Arguments:
--Nextbot self | The owner of the weapon.
function ENT.Weapon.Fire(self)
	if not IsValid(self) or not istable(self.Equipment)
		or not IsValid(self.Equipment.Entity) then return end
	if self.Equipment.Ammo <= 0 then return end
	if CurTime() < self.Time.Fire then return end
	
	local shootPos = self:GetAttachment(self:LookupAttachment("anim_attachment_RH"))
	self.Equipment.Ammo = self.Equipment.Ammo - 1
	self:AddGesture(self.Act.Attack)
	self.Equipment.Entity:EmitSound(self.Equipment.Sound.Fire)
	
	local bullet = {
		Attacker = self,
		Num = 1,
		Src = shootPos.Pos,
		Dir = shootPos.Ang:Forward() * 10000,
		Spread = Vector(self.Equipment.Spread, self.Equipment.Spread, 0),
		Force = 100,
		Tracer = 5,
		TracerName = "Tracer",
		Damage = self.Equipment.Damage,
		AmmoType = self.Equipment.AmmoType,
		Callback = DefaultFireCallback,
	}
	self.Equipment.Entity:FireBullets(bullet)
	
	local ef = EffectData()
	ef:SetEntity(self.Equipment.Entity)
	ef:SetEntIndex(self.Equipment.Entity:EntIndex())
	ef:SetOrigin(shootPos.Pos)
	ef:SetAngles(shootPos.Ang)
	ef:SetScale(self.Equipment.Muzzle.Scale)
	if math.random() < self.Equipment.Muzzle.Probability then
		util.Effect("MuzzleEffect", ef)
	end
	
	self.Equipment.Entity:MuzzleFlash()
	self:MuzzleFlash()
	self.Time.Fired = CurTime() + self.Equipment.Delay.Fire
end

--Default function to reload the weapon.
--Arguments:
--Nextbot self | The owner of the weapon.
function ENT:ReloadWeapon()
	if self.Time.Reload > CurTime() then return end
	if self.Equipment.Ammo >= self.Equipment.Clip then return end
	
	self:RemoveAllGestures()
	local bLooking = self.Memory.Look
	self.Memory.Look = false
	
	self.ReloadLayerID = self:AddGesture(self.Act.Reload)
	self:SetLayerPlaybackRate(self.ReloadLayerID, self:GetLayerDuration(self.ReloadLayerID) * 0.9)
	self.Time.Reload = CurTime() + self.Equipment.Delay.Reload
	timer.Simple(self.Equipment.Delay.ReloadSound, function()
		if not IsValid(self) or not IsValid(self.Equipment.Entity) or
			not self:IsPlayingGesture(self.Act.Reload) then return end
		self.Equipment.Entity:EmitSound(self.Equipment.Sound.Reload)
	end)
	
	timer.Simple(self.Equipment.Delay.Reload, function()
		if not IsValid(self) then return end
		self.Equipment.Ammo = self.Equipment.Clip
		self.Memory.Look = bLooking
	end)
end

local function FireCallBack(attacker, tr, dmginfo)
	if not IsValid(attacker) or not istable(attacker.Equipment)
		or not IsValid(attacker.Equipment.Entity) then return end
	if not IsValid(tr.Entity) then return end
	
	local c = tr.Entity:GetClass()			
	if c == "npc_turret_floor" then
		tr.Entity:Fire("SelfDestruct")
	elseif c == "npc_rollermine" then
		util.BlastDamage(game.GetWorld(), game.GetWorld(), tr.Entity:GetPos(), 1, 1)
	end
end

--Fire function for Tracer's Pulse Pistols.
local function FireTracerPistols(self)
	if not IsValid(self) or not istable(self.Equipment)
		or not IsValid(self.Equipment.Entity) then return end
	if self.Equipment.Ammo <= 0 then return end
	if CurTime() < self.Time.Fire then return end
	if self.Memory.Distance > self.Dist.ShootRange then return end
	if not self:HasCondition("CanPrimaryAttack") then return end
	
	local att = {
		self:LookupAttachment("anim_attachment_LH"),
		self:LookupAttachment("anim_attachment_RH"),
	}
	local shootPos = {
		self:GetAttachment(att[1]),
		self:GetAttachment(att[2]),
	}
	self.Equipment.Ammo = self.Equipment.Ammo - 1
	self:AddGesture(self.Act.Attack)
	self.Equipment.Entity:EmitSound(self.Equipment.Sound.Fire)
	
	local bullet = {
		Attacker = self,
		Num = 1,
		Spread = Vector(self.Equipment.Spread, self.Equipment.Spread, 0),
		Force = 100,
		Tracer = 5,
		TracerName = "Tracer",
		Damage = self.Equipment.Damage,
		AmmoType = self.Equipment.AmmoType,
		Callback = FireCallBack,
	}
	
	for i = 1, 2 do
		bullet.Src = shootPos[i].Pos
		bullet.Dir = (self.Memory.EnemyPosition - shootPos[i].Pos):GetNormalized() * 1000
		
		self:FireBullets(bullet)
		if math.random() < self.Equipment.Muzzle.Probability then
			ParticleEffectAttach(self.MuzzleFlashParticleName, PATTACH_POINT_FOLLOW, self, att[i])
		end
	end
	
	self.Equipment.Entity:MuzzleFlash()
	self:MuzzleFlash()
	self.Time.Fire = CurTime() + self.Equipment.Delay.Fire
end

--Creates the weapon information class of Tracer's Pulse Pistols.
function ENT:CreatePulsePistols()
	--Pulse pistols damage: 1.5 - 6
	--distance: 11m - 30m
	--fire rate: 40rps
	--reload time: 1 second
	return self.Weapon.Create(self, {
		name = "tfa_tracer_nope",
		clip = 20,
		numbullets = 1,
		spread = 150,
		dmg = ({1.5, 3, 6})[game.GetSkillLevel()] or 6,
		ammotype = "Pistol",
		delay = {
			firerate = 1/20,
			reloadtime = 1,
			reloadsound = 0,
		},
		muzzle = {
			probability = 0.6,
			scale = 0.7,
		},
		snd = {
			fire = "NOPE_TRACER.1",
			reload = "NOPE_TRACER.RELOADFOLEY",
		},
		firefunction = FireTracerPistols
	})
end