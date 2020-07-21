
--Build schedule determines what the nextbot should do next by returning schedule name.

--Sets NPC State: Idle/Alert/Combat
function ENT:BuildNPCState()
	local s = NPC_STATE_IDLE
	if self:GetEnemy() then
		s = NPC_STATE_COMBAT
		self.Memory.Walk = false
	elseif self:GetState() == NPC_STATE_ALERT then
		s = NPC_STATE_ALERT
	end
	if s ~= self:GetState() then self.State.ScheduleProgress = math.huge end
	self:SetState(s)
end

--Build shcedule for Idle state.
function ENT:BuildIdleSchedule()
	if self.State.FailReason == self.FailReason.NoHealthKitFound then
		self.State.FailReason = self.FailReason.NoReasonGiven
		self.Time.FindHealthKit = CurTime() + 5
	end
	
	if self:Health() < self:GetMaxHealth() and
		CurTime() > self.Time.FindHealthKit then
		return "GotoHealthKit"
	else
		return "Idle" --Just stand there.
	end
end

--Build schedule for Alert state.
function ENT:BuildAlertSchedule()
	if self.State.FailReason == self.FailReason.NoHealthKitFound then
		self.State.FailReason = self.FailReason.NoReasonGiven
		self.Time.FindHealthKit = CurTime() + math.Rand(5, 10)
	end
	
	if self:Health() < self.HP.MoreBlink and
		CurTime() > self.Time.FindHealthKit then
		return "GotoHealthKit"
	else
		return "PatrolAround" --Just wander around.
	end
end

local CombatSchedule = {}
CombatSchedule.Assault = function(self)
	local dist = self.Memory.Distance
	local blinkdist = self.Dist.Blink / 2

	--Take damage several times in a row.
	--Or mobbed by enemies.
	if self:HasCondition("NearDanger") or
		self:HasCondition("RepeatedDamage") or
		self:HasCondition("MobbedByEnemies") then
		
		if self.Debug.Fleeing then
			print("NearDanger: " .. tostring(self:HasCondition("NearDanger")),
			"RepeatedDamage: ", tostring(self:HasCondition("RepeatedDamage")),
			"MobbedByEnemies: " .. tostring(self:HasCondition("MobbedByEnemies")))
		end
		self.State.Mode = "Flee"
	end
	
	--An enemy is behind me and it is nearer than the current one.
	if CurTime() > self.Time.SetBehindEnemy and
		self:HasCondition("BehindEnemy") then
		for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
			if self.Debug.BehindEnemy then
				print("EnemyMemory: ", k, "CurrentEnemy: ", self:GetEnemy())
			end
			
			if IsValid(k) and self.Memory.Enemies[k].Distance < dist then
				self:SetEnemy(k)
				dist = self.Memory.Enemies[k].Distance
				break
			end
		end
		self.Time.SetBehindEnemy = CurTime() + math.Rand(2, 5)
	end
	
	--No ammo.
	if CurTime() > self.Time.Reload and self:HasCondition("NoPrimaryAmmo") then
		--Go behind the enemy and reload.
		if self:HasCondition("EnemyFacingMe") then
			if self:HasCondition("CanBlink") then
				self:ReloadWeapon()
				if dist < blinkdist then
					return "BlinkTowardEnemy"
				else
					return "BlinkSidestep"
				end
			else
				return "HideAndReload"
			end
		else --Just reload.
			self:ReloadWeapon()
		end
	end
	
	--I've taken damage or feel dangerous, blink.
	if self:HasCondition("CanBlink") and
		(self:HasCondition("NearDanger") or
		self:HasCondition("HeavyDamage") or
		(self:Health() < self.HP.MoreBlink and
		self:HasCondition("LightDamage"))) then
		
		if self:HasCondition("EnemyFacingMe") and dist < blinkdist then
			return "BlinkTowardEnemy"
		else
			return math.random() > 0.5 and "BlinkFromEnemy" or "BlinkSidestep"
		end
	end
	
	--The enemy is in attack range.
	if self:HasCondition("CanPrimaryAttack") then
		if self:HasCondition("CanBlink") then
			--The enemy is looking at me.
			if self:HasCondition("EnemyFacingMe") then
				--Go behind the enemy.
				if dist < self.Dist.Blink * 0.8 then
					return "BlinkTowardEnemy"
				else --Move sideways.
					return "BlinkSidestep"
				end
			elseif self:HasCondition("EnemyApproaching") then
				return "RunAroundAndFire"
			else --Shoot the enemy from side or back.
				return "RangeAttack"
			end
		else --I can't blink but can attack.
			if self:HasCondition("EnemyFacingMe") then
				return "RunAroundAndFire"
			else
				return "RangeAttack"
			end
		end
	--The enemy is out of range.
	elseif self:HasCondition("EnemyTooFar") and not self:HasCondition("EnemyApproaching") then
		--Blink and approach it.
		if self:HasCondition("CanBlink") and dist > self.Dist.Blink * 2 then
			return "BlinkTowardEnemy"
		else --Approach it.
			if self.State.InterruptCondition == "InvalidPath" then
				return "RunAroundAndFire"
			else
				return "Advance"
			end
		end
	--The enemy is not visible, chase it.
	elseif self:HasCondition("EnemyOccluded") then
		if self:HasCondition("LowPrimaryAmmo") then
			return "HideAndReload"
		else
			return "AppearUntilSee"
		end
	elseif self:HasCondition("CanBlink")
	and self:HasCondition("EnemyFacingMe") then
		if dist < self.Dist.Blink * 0.8 then
			return "BlinkTowardEnemyAndReload"
		else
			return "BlinkSidestep"
		end
	else
		return "EscapeLimitedTime"
	end
end

CombatSchedule.Flee = function(self)
	if not (self:HasCondition("NearDanger") or
		self:HasCondition("RepeatedDamage") or
		self:HasCondition("MobbedByEnemies")) then
		self.State.Mode = "Assault"
	end
	
	if self:HasCondition("EnemyTooFar") then
		if CurTime() > self.Time.Reload and 
			(self:HasCondition("NoPrimaryAmmo") or
			self:HasCondition("NoSecondaryAmmo") or
			(math.random() < 0.3 and
			(self:HasCondition("LowPrimaryAmmo") or
			self:HasCondition("LowSecondaryAmmo"))))then
			return "HideAndReload"
		else
			return "Escape"
		end
	else
		if self:HasCondition("CanBlink") then
			if self.Memory.Distance > self.Dist.Blink / 2 then
				return "BlinkFromEnemy"
			else
				return "BlinkTowardEnemy"
			end
		elseif self:HasCondition("CanPrimaryAttack") then
			return "EscapeLimitedTime"
		else
			return "HideAndReload"
		end
	end
end

function ENT:BuildCombatSchedule()
	if not self:HasCondition("MobbedByEnemies") and
		self:HasCondition("CanMeleeAttack") and self:GetEnemy():Health() < 30 then
		return "MeleeAttack"
	--Recall and heal myself.
	elseif self:HasCondition("CanRecall") then
		return "Recall"
	elseif isfunction(CombatSchedule[self.State.Mode]) then
		return CombatSchedule[self.State.Mode](self)
	else
		self.State.Mode = "Assault"
		return "RunIntoEnemy"
	end
end