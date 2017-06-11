
--++Conditions++----------------{
local COND_NO_CUSTOM_INTERRUPTS = 70
local COND_LOW_SECONDARY_AMMO = COND_NO_CUSTOM_INTERRUPTS + 1
local COND_RELOAD_FINISHED = COND_NO_CUSTOM_INTERRUPTS + 2
local COND_PATH_FINISHED = COND_NO_CUSTOM_INTERRUPTS + 3
local COND_SCHEDULE_DONE = COND_NO_CUSTOM_INTERRUPTS + 4
--Nextbot conditions
ENT.Condition = {
	"BehindEnemy", --An enemy is behind me.
	"CanMeleeAttack", --I can swing my baton.
	"CanPrimaryAttack", --The enemy is in enough range and ready to fire.
	"CanSecondaryAttack", --The enemy is in close range and ready to fire.
	"Done", --Schedule is done.
	"EnemyDead", --Current enemy is dead and I have no enemy for now.
	"EnemyFacingMe", --The enemy is facing me.
	"EnemyOccluded", --The enemy is occluded.
	"EnemyTooFar", --The enemy is out of range, I need to draw near.
	"EnemyUnreachable", --The enemy position is unreachable for me.
	"HeavyDamage", --I've just taken a heavy damage.
	"HaveEnemyLOS", --I can see the enemy.
	"LightDamage", --I've just taken a light damage.
	"LostEnemy", --I've lost the enemy.
	"LowPrimaryAmmo", --I have low primary ammo.
	"LowSecondaryAmmo", --I have low secondary ammo.
	"MobbedByEnemies", --I'm mobbed by enemies.
	"NearDanger", --Dangerous things is near me.
	"NewEnemy", --I found a new enemy.
	"NoPrimaryAmmo", --I have no primary ammo and need to reload.
	"NoSecondaryAmmo", --I have no secondary ammo and need to reload.
	"PathFinished", --I've just finished moving.
	"ReloadFinished", --I've just finished reloading.
	"RepeatedDamage", --I take a damage repeatedly.
}
for i, v in ipairs(ENT.Condition) do
	ENT.Condition[v] = i
	ENT.Condition[i] = nil
end

--Builds some conditions of the nextbot.
--Compare e and PreviousMemory to set "EnemyDead" condition.
function ENT.Condition.Build(self, e)
	local c = {} --list of conditions
	
	c.NewEnemy = self.State.Previous.HaveEnemy ~= e --I got new enemy.
	c.LostEnemy = tobool(not e and self.State.Previous.HaveEnemy) --I had an enemy previous tick.
	c.EnemyDead = c.LostEnemy or (IsValid(e) and e:Health() <= 0) --An enemy with 0 health.
	if IsValid(e) then
		c.EnemyFacingMe = (self:GetEye().Pos --the enemy is facing me.
		 - self.Memory.EnemyPosition):GetNormalized():Dot(e:GetForward()) > 0.85
		c.EnemyTooFar = self.Memory.Distance >= self.FarDistance --the enemy is too far.
		local n = navmesh.Find(self.Memory.EnemyPosition, self.MeleeDistance,
			self.loco:GetDeathDropHeight(), self.loco:GetStepHeight())
		for k, v in pairs(n) do
			if self.loco:IsAreaTraversable(v) then n = true break end
		end
		c.EnemyUnreachable = not isbool(n) --the enemy position is unreachable.
		
		if self.Memory.Shoot then--and self:GetAimVector():Dot(self:GetForward()) > 0.7 then
			c.CanPrimaryAttack = --if I'm enough to fire primary weapon
			self.Memory.Distance < self.FarDistance and
			self.Memory.Distance >= self.NearDistance and
			self.Primary.Ammo > 0 and
			CurTime() > self.Time.Fired
			c.CanSecondaryAttack = --if I'm enough to fire secondary weapon
			self.Memory.Distance < self.NearDistance and
			self.Memory.Distance >= self.MeleeDistance and
			self.Secondary.Ammo > 0 and
			CurTime() > self.Time.Fired
			c.CanMeleeAttack = self.Memory.Distance < self.MeleeDistance --enemy is too close, beat it
		end
		c.HaveEnemyLOS = self.Memory.Look --I have LOS of the enemy.
		c.EnemyOccluded = not self.Memory.Look --I can't see the enemy.
	end
	
	for enemy in pairs(self.Memory.Enemies) do
		local tp = self:GetTargetPos(false, enemy)
		if self:CanSee(tp) and (self:GetEye().Pos - tp):GetNormalized():Dot(self:GetForward()) > 0.7 then
			c.BehindEnemy = true
			break
		end
	end
	
	--Checking weapon ammunition.
	c.NoPrimaryAmmo = self.Primary.Ammo <= 0
	c.NoSecondaryAmmo = self.Secondary.Ammo <= 0
	c.ReloadFinished = math.abs(CurTime() - self.Time.Reload) < 0.1
	c.LowPrimaryAmmo = self.Primary.Ammo > 0 and self.Primary.Ammo < self.Primary.Clip / 3
	c.LowSecondaryAmmo = self.Secondary.Ammo > 0 and self.Secondary.Ammo < self.Secondary.Clip / 3
	
	--Set if current schedule is done.
	c.Done = self.State.ScheduleProgress > #self.Schedule[self:GetSchedule()]
	c.PathFinished = self.State.Previous.Path and not (self.Path.Main:IsValid() or self.Path.Approaching)
	
	--Around my health.
	c.LightDamage = self.State.Previous.Health - self:Health() > 1
	c.HeavyDamage = self.State.Previous.Health - self:Health() > self:GetMaxHealth() / 5
	c.RepeatedDamage = self.Time.Damage - self.Time.DamageRepeated > 0.8
	if c.RepeatedDamage then self.Time.DamageRepeated = CurTime() end
	
	--Get dangerous things.
	local d, ent = self.State.GetDanger(self)
	if d then
		c.NearDanger = true
		self.Memory.DangerEntity = ent
	end
	
	--Build conditions
	for i, v in pairs(c) do
		self:AddCondition(i, v)
	end
end
--------------------------------}


--Adds the given condition.
--Arguments:
--string c | Condition.
--Bool state | Set condition state manually.
function ENT:AddCondition(c, state)
	if not self.Condition[c] then return end
	self.State[self.Condition[c]] = not isbool(state) or state
end

--Removes a condition.
--Argument: string c | Condition.
function ENT:RemoveCondition(c)
	if not self.Condition[c] then return end
	self.State[self.Condition[c]] = nil
end

--Removes all conditions.
function ENT:RemoveAllConditions()
	for i, c in pairs(self.Condition) do
		self.State[c] = nil
	end
end

--Returns if the nextbot has the given condition.
--Argument: number c | Condition.
function ENT:HasCondition(c)
	if not self.Condition[c] then return end
	return self.State[self.Condition[c]]
end