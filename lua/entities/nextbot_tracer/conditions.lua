
ENT.FailReason = {
	"InterruptByCcondition", --Schedule stopped by condition.
	"InvalidPath", --Calculating path is failed.
	"NoHealthKitFound", --There is no health kit around.
	"NoSpotsFound", --Appropriate position is not found.
	"NoReasonGiven", --No reason is given.
	"TimeOut", --Time out to move to position.
}
for i, v in ipairs(ENT.FailReason) do
	ENT.FailReason[v] = i
	ENT.FailReason[i] = nil
end

--++Conditions++----------------{
local COND_NO_CUSTOM_INTERRUPTS = 70
local COND_LOW_SECONDARY_AMMO = COND_NO_CUSTOM_INTERRUPTS + 1
local COND_RELOAD_FINISHED = COND_NO_CUSTOM_INTERRUPTS + 2
local COND_PATH_FINISHED = COND_NO_CUSTOM_INTERRUPTS + 3
local COND_SCHEDULE_DONE = COND_NO_CUSTOM_INTERRUPTS + 4
--Nextbot conditions
ENT.Condition = {
	"BehindEnemy", --An enemy is behind me.
	"CanBlink", --I can blink now.
	"CanMeleeAttack", --I can swing my baton.
	"CanPrimaryAttack", --The enemy is in enough range and ready to fire.
	"CanRecall", --I can use the recall ability.
	"CanSecondaryAttack", --The enemy is in close range and ready to fire.
	"Done", --Schedule is done.
	"EnemyApproaching", --Current enemy is moving toward me.
	"EnemyDead", --Current enemy is dead.
	"EnemyFacingMe", --The enemy is facing me.
	"EnemyOccluded", --The enemy is occluded.
	"EnemyTooFar", --The enemy is out of range, I need to draw near.
	"EnemyUnreachable", --The enemy position is unreachable for me.
	"HeavyDamage", --I've just taken a heavy damage.
	"HaveEnemyLOS", --I can see the enemy.
	"InvalidPath", --The main pathfollower is invalid.
	"LightDamage", --I've just taken a light damage.
	"LostEnemy", --I've lost the enemy.
	"LowPrimaryAmmo", --I have low primary ammo.
	"LowSecondaryAmmo", --I have low secondary ammo.
	"MobbedByEnemies", --I'm mobbed by enemies.
	"NearDanger", --Dangerous things is near me.
	"NewEnemy", --I found a new enemy.
	"NoPrimaryAmmo", --I have no primary ammo and need to reload.
	"NoSecondaryAmmo", --I have no secondary ammo and need to reload.
	"OnContact", --On contact someone.
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
function ENT.Replacement:BuildConditions(e)
	local c = {} --list of conditions
	
	c.NewEnemy = tobool(not self.State.Previous.HaveEnemy and e) --I got new enemy.
	c.LostEnemy = tobool(not e and self.State.Previous.HaveEnemy) --I had an enemy previous tick.
	c.EnemyDead = c.LostEnemy or (e and e:Health() <= 0) --An enemy with 0 health.
	
	if e then
		--the enemy is approaching me.
		local enemy_movement = self.Memory.EnemyPosition - self.State.Previous.ApproachingPos
		c.EnemyApproaching = enemy_movement:LengthSqr() > 6400 and
		enemy_movement:GetNormalized():Dot(self:GetAimVector()) > math.cos(math.rad(30))
		
		--the enemy is facing me.
		c.EnemyFacingMe = self:IsFacingMe()
		
		--the enemy is too far.
		c.EnemyTooFar = self.Memory.Distance > self.Dist.ShootRange
		
		--Check if the enemy position is unreachable.
		c.EnemyUnreachable = true
		local n = navmesh.Find(self.Memory.EnemyPosition, self.Dist.Melee,
			self.loco:GetDeathDropHeight(), self.loco:GetStepHeight())
		for k, v in pairs(n) do
			if self.loco:IsAreaTraversable(v) then
				c.EnemyUnreachable = false
				break
			end
		end
		
		local bLook, bShoot = self:CanSee(), self:CanSee(self.Memory.EnemyPosition, {shoot = true})
		if bLook then self.Time.SeeEnemy = CurTime() end
		c.EnemyOccluded = not bLook --I can't see the enemy.
		c.HaveEnemyLOS = bLook --I have LOS of the enemy.
		
		--if I'm enough to fire primary weapon
		c.CanPrimaryAttack = 
		bShoot and
		self:GetAimVector():Dot(self:GetForward()) > math.cos(math.rad(80)) and
		self.Memory.Distance < self.Dist.ShootRange and
		self.Equipment.Ammo > 0 and
		CurTime() > self.Time.Fire and
		CurTime() > self.Time.Reload
		
		--if I'm enough to fire secondary weapon
		c.CanSecondaryAttack = false
		
		--enemy is too close, beat it
		c.CanMeleeAttack = 
		bShoot and
		CurTime() > self.Time.Melee and
		self.Memory.Distance < self.Dist.Melee
	else
		c.EnemyApproaching = false
		c.EnemyFacingMe = false
		c.EnemyOccluded = false
		c.EnemyTooFar = false
		c.EnemyUnreachable = false
		c.HaveEnemyLOS = false
		c.CanMeleeAttack = false
		c.CanPrimaryAttack = false
		c.CanSecondaryAttack = false
	end
	
	--Is there an enemy behind me?
	c.BehindEnemy = false
	local mob_count = 0 --Mobbed by enemies.
	for enemy, data in pairs(self.Memory.Enemies) do
		if not IsValid(enemy) then self.Memory.Enemies[enemy] = nil continue end
		if data.Distance < self.Dist.Mobbed then mob_count = mob_count + 1 end
		if not c.BehindEnemy and self:CanSee(enemy:WorldSpaceCenter()) and 
		self:GetAimVector(enemy:WorldSpaceCenter()):Dot(self:GetForward()) > 0.7 then
			c.BehindEnemy = true
		end
	end
	
	c.MobbedByEnemies = mob_count > self:Health() / self:GetMaxHealth() * self.Bravery
	
	--Checking weapon ammunition.
	c.NoPrimaryAmmo = self.Equipment.Ammo <= 0
	c.NoSecondaryAmmo = false
	c.ReloadFinished = math.abs(CurTime() - self.Time.Reload) < 0.1
	c.LowPrimaryAmmo = self.Equipment.Ammo > 0 and self.Equipment.Ammo < self.Equipment.Clip / 2
	c.LowSecondaryAmmo = false
	
	--Is current schedule done?
	c.Done = self.State.ScheduleProgress > #self.Schedule[self.State.Schedule]
	--Have current path just finished?
	c.PathFinished = self.State.Previous.Path and not (self.Path.Main:IsValid() or self.Path.Approaching)
	--Is my path valid?
	c.InvalidPath = not self.Path.Main:IsValid()
	
	--Around my health.
	c.LightDamage = self.State.Previous.Health - self:Health() > 1
	c.HeavyDamage = self.State.Previous.Health - self:Health() > self.HP.HeavyDamage
	c.RepeatedDamage = self.Time.Damage - self.Time.RepeatedDamage > self.Time.RepeatedDamageDuration
	if c.RepeatedDamage then self.Time.RepeatedDamage = CurTime() end
	
	--Get dangerous things.
	c.NearDanger = false
	self.Memory.DangerEntity = NULL
	local d, ent = self.State.GetDanger(self)
	if d then
		c.NearDanger = true
		self.Memory.DangerEntity = ent
	end
	
	--Can I use my abilities now?
	c.CanBlink = self.BlinkRemaining > 0 and CurTime() > self.Time.Blink
	c.CanRecall = self.State.Previous.HealthForRecall - self:Health() > self:Health() * self.HP.Recall and CurTime() > self.Time.Recall
	--I touched someone.
	c.OnContact = math.abs(CurTime() - self.Time.Touch) < 0.05
	
	--Build conditions
	for i, v in pairs(c) do
		self:RemoveCondition(i)
		self:AddCondition(i, v)
	end
end
--------------------------------}

--Adds the given condition.
--Arguments:
--string c | Condition.
--Bool state | Set condition state manually.
function ENT.Replacement:AddCondition(c, state)
	if not self.Condition[c] then return end
	self.State[self.Condition[c]] = not isbool(state) or state
end

--Removes a condition.
--Argument: string c | Condition.
function ENT.Replacement:RemoveCondition(c)
	if not self.Condition[c] then return end
	self.State[self.Condition[c]] = nil
end

--Removes all conditions.
function ENT.Replacement:RemoveAllConditions()
	for i, c in pairs(self.Condition) do
		self.State[c] = nil
	end
end

--Returns if the nextbot has the given condition.
--Argument: number c | Condition.
function ENT.Replacement:HasCondition(c)
	if not self.Condition[c] then return false end
	return self.State[self.Condition[c]]
end