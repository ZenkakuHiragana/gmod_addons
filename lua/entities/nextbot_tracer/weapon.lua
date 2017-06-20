
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
function ENT.Weapon.Create(self, name, clip, numbullets, spread, dmg, ammotype, delay, muzzle, snd, firefunction)
	local delay, muzzle, snd = delay, muzzle, snd
	if not istable(delay) then
		delay = {								--Table of timers
			firerate = 0.1,						--Fire rate
			reloadtime = 1,						--Time to reload
			reloadsound = 0,					--Play a sound after a while from starting to reload
		}
	end
	
	if not istable(muzzle) then
		muzzle = {								--Parameters about muzzle flash
			probability = 0.5,					--How often the effect appears
			scale = 0.6,						--Scale of the effect
		}
	end
	
	if not istable(snd) then
		snd = {									--Parameters about sound
			fire = "Weapon_Pistol.NPC_Single",	--Firing sound
			reload = "Weapon_Pistol.NPC_Reload"	--Reloading sound
		}
	end
	
	local ent = ents.Create(name)
	if not IsValid(ent) then
		ent = NULL
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
		Entity = ent,			--Weapon entity
		Name = name,			--Weapon classname
		Clip = clip,			--Clip size
		Ammo = clip,			--Ammo that the weapon now has
		Num = numbullets,		--Amount of bullets per shot
		Spread = spread,		--Bullet spread
		Damage = dmg,	 		--Damage per bullets
		AmmoType = ammotype,	--Ammo type
		Delay = {Fire = delay.firerate or 0.5, Reload = delay.reloadtime or 1, ReloadSound = delay.reloadsound or 0},
		Muzzle = {Probability = muzzle.probability or 0.5, Scale = muzzle.scale or 0.6},
		Sound = {Fire = snd.fire or "Weapon_Pistol.NPC_Single", Reload = snd.reload or "Weapon_Pistol.NPC_Reload"},
		Fire = isfunction(firefunction) and firefunction or self.Weapon.Fire
	}, {__index = self.Weapon})
end

--Default function to fire bullets.
--Arguments:
--Nextbot self | The owner of the weapon.
--Entity weapon | The weapon.
function ENT.Weapon.Fire(self, weapon)
	if not IsValid(self) or not IsValid(weapon) then return end
	if self.Equipment.Ammo <= 0 then return end
	if CurTime() < self.Time.Fire then return end
	
	local shootPos = self:GetHand()
	self.Equipment.Ammo = self.Equipment.Ammo - 1
	self:AddGesture(self.Act.Attack)
	weapon:EmitSound(self.Equipment.Sound.Fire)
	
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
		Callback = function(attacker, tr, dmginfo)
			if not IsValid(tr.Entity) then return end
			
			dmginfo:SetInflictor(weapon)
			local c = tr.Entity:GetClass()			
			if c == "npc_turret_floor" then
				tr.Entity:Fire("SelfDestruct")
			elseif c == "npc_rollermine" then
				util.BlastDamage(weapon, self, tr.Entity:GetPos(), 1, 1)
			end
		end,
	}
	self.Equipment.Entity:FireBullets(bullet)
	
	local ef = EffectData()
	ef:SetEntity(weapon)
	ef:SetEntIndex(weapon:EntIndex())
	ef:SetOrigin(shootPos.Pos)
	ef:SetAngles(shootPos.Ang)
	ef:SetScale(self.Equipment.Muzzle.Scale)
	if math.random() < self.Equipment.Muzzle.Probability then
		util.Effect("MuzzleEffect", ef)
	end
	
	weapon:MuzzleFlash()
	self:MuzzleFlash()
	self.Time.Fired = CurTime() + self.Equipment.Delay.Fire
end

--Default function to reload the weapon.
--Arguments:
--Nextbot self | The owner of the weapon.
--Entity weapon | The weapon.
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
	if not IsValid(tr.Entity) then return end
	
	local c = tr.Entity:GetClass()			
	if c == "npc_turret_floor" then
		tr.Entity:Fire("SelfDestruct")
	elseif c == "npc_rollermine" then
		util.BlastDamage(attacker.Equipment.Entity, self, tr.Entity:GetPos(), 1, 1)
	end
end

--Fire function for Tracer's Pulse Pistols.
local function FireTracerPistols(self, weapon)
	if not IsValid(self) or not IsValid(weapon) then return end
	if self.Equipment.Ammo <= 0 then return end
	if CurTime() < self.Time.Fire then return end
	if self.Memory.Distance > self.Dist.ShootRange then return end
	if not self:HasCondition("CanPrimaryAttack") then return end
	
	local shootPos = {self:GetHand(true), self:GetHand()}
	self.Equipment.Ammo = self.Equipment.Ammo - 1
	self:AddGesture(self.Act.Attack)
	weapon:EmitSound(self.Equipment.Sound.Fire)
	
	local ef = EffectData()
	ef:SetEntity(weapon)
	ef:SetEntIndex(weapon:EntIndex())
	ef:SetScale(self.Equipment.Muzzle.Scale)
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
		ef:SetOrigin(shootPos[i].Pos + shootPos[i].Ang:Forward() * 10)
		ef:SetAngles(shootPos[i].Ang)
		if math.random() < self.Equipment.Muzzle.Probability then
			util.Effect("MuzzleEffect", ef)
		end
	end
	
	weapon:MuzzleFlash()
	self:MuzzleFlash()
	self.Time.Fire = CurTime() + self.Equipment.Delay.Fire
end

--Creates the weapon information class of Tracer's Pulse Pistols.
function ENT:CreatePulsePistols()
	--Pulse pistols damage: 1.5 - 6
	--distance: 11m - 30m
	--fire rate: 40rps
	--reload time: 1 second
	return self.Weapon.Create(self,
	"tfa_tracer_nope", 20, 1, 150, 6, "Pistol",
	{firerate = 1/40, reloadtime = 1, reloadsound = 0},
	{probability = 0.4, scale = 0.7},
	{fire = "NOPE_TRACER.1", reload = "NOPE_TRACER.RELOADFOLEY"},
	FireTracerPistols)
end