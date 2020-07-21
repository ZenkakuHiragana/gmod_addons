
include("relationship.lua")

--Gets personal enemy entity.
function ENT:GetEnemy()
	if not self.IsInitialized or self:Disposition(self.Memory.Enemy) ~= D_HT then return nil end
	return self.Memory.Enemy
end

--Sets personal enemy memory.
function ENT:SetEnemy(ent)
	if self:Disposition(ent) ~= D_HT then return end
	self.Memory.Enemy = ent
	self.Memory.EnemyAimVector = self:GetEnemyAimVector()
	self.Memory.EnemyPosition = ent:WorldSpaceCenter() --set the last position I saw
	self.Memory.Distance = self:GetRangeTo(self.Memory.EnemyPosition)
	
	for ally, distance in pairs(self.Memory.Allies) do
		if self:Disposition(ally) == D_LI and isfunction(ally.UpdateEnemyMemory) then
			ally:UpdateEnemyMemory(ent, ent:WorldSpaceCenter())
		else
			self.Memory.Allies[ally] = nil
		end
	end
end

--Finds nearest enemy and returns it.
function ENT:FindEnemy()
	local lst = ents.FindInSphere(self:GetEye().Pos, self.Dist.Search)
	local pos, nearestenemy = vector_origin, NULL
	local relationship = D_ER
	
	for k, v in pairs(lst) do
		pos = v:WorldSpaceCenter()
		if self:CanSee(pos, {target = v}) and self:GetAimVector(pos):Dot(self:GetEye().Ang:Forward()) > math.cos(math.rad(self.SearchAngle)) then
			relationship = self:Disposition(v)
			if relationship == D_LI then
				if isfunction(v.GetEnemy) and IsValid(v:GetEnemy()) then
					v = v:GetEnemy()
					pos = v:WorldSpaceCenter()
					relationship = self:Disposition(v)
				end
				
				self.Memory.Allies[v] = self:GetPos():DistToSqr(v:GetPos())
			end
			
			if relationship == D_HT then --normal entity and can see
				self.Memory.Enemies[v] = {Pos = pos, Distance = self:GetPos():DistToSqr(pos), Forward = self:GetEnemyAimVector(v)}
			end
		end
	end
	
	--Clean up old infomations.
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		local t = {target = k}
		if self:Disposition(k) ~= D_HT or (self:CanSee(v.Pos, t) and not self:CanSee(k:WorldSpaceCenter(), t)) then
			self.Memory.Enemies[k] = nil
		end
	end
	
	if self.Debug.ShowEnemyMemory then
		for k, v in pairs(self.Memory.Enemies) do
			debugoverlay.Sphere(k:WorldSpaceCenter(), 10, 0.1, Color(0, 255, 0, 255), true)
		end
	end
	
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		if IsValid(k) then --Get the nearest enemy.
			if self.Debug.ShowEnemyMemory then
				debugoverlay.Sphere(k:WorldSpaceCenter(), 50, 0.1, Color(255, 0, 0, 255), true)
			end
			return k
		end
	end
end

--Returns if a position is visible.
--Arguments:
----Vector pos | The end position of the trace.
----Table opt | Options.
------Vector start | The start position of the trace.
------Bool shoot | If true, check MASK_SHOT in place of visiblity.
------Entity target | Target entity if it is other than the current enemy.
function ENT:CanSee(pos, opt)
	local opt = opt or {}
	local e = pos or self.Memory.EnemyPosition
	local filter = table.Copy(self.breakable_filter)
	local target = opt.target or self:GetEnemy()
	table.insert(filter, self)
	local tr = util.TraceLine({
		start = opt.start or self:GetEye().Pos,
		endpos = e,
		filter = self.breakable_filter,
		mask = opt.shoot and MASK_SHOT or MASK_BLOCKLOS_AND_NPCS,
	})
	if self.Debug.SeeTrace then
		debugoverlay.Line(tr.StartPos, tr.HitPos, 3, Color(0, 255, 0, 255), false)
	end
	
	if tr.Entity == target then return true end
	for _, v in ipairs(ents.FindInSphere(tr.HitPos, 50)) do
		if v == target then return not (tr.StartSolid or tr.HitWorld) end
	end
end

--Returns where current enemy or the given entity is looking at.
--Argument:
----Entity e | The given entity(Optional).
function ENT:GetEnemyAimVector(e)
	local ent = IsValid(e) and e or self.Memory.Enemy
	if not IsValid(ent) then return vector_origin end

	-- IV04's HL2DM Nextbots make errors, but I shouldn't say it's a bug.
	-- They aren't NPC or Player and there's no guarantee for GetAimVector().
	if ent.IV04NextBot then
		local weapon = isfunction(e.GetActiveWeapon) and e:GetActiveWeapon()
		if IsValid(weapon) and weapon:LookupAttachment "muzzle" < 1 then
			return ent:GetForward()
		end
	end

	return isfunction(ent.GetAimVector) and ent:GetAimVector() or ent:GetForward()
end

--Returns aiming direction vector.
--Argument:
----Vector dir | Looking at this position(Optional).
function ENT:GetAimVector(dir)
	local aimat = dir or self.Memory.EnemyPosition
	return (aimat - self:WorldSpaceCenter()):GetNormalized()
end

--Returns if the enemy or the given entity is facing me.
--Argument:
----Entity e | The given entity(Optional).
function ENT:IsFacingMe(e)
	local vEnemyPos = IsValid(e) and e:WorldSpaceCenter() or self.Memory.EnemyPosition
	local vEnemyAim = IsValid(e) and self:GetEnemyAimVector(e) or self.Memory.EnemyAimVector
	local vEnemyToMe = -self:GetAimVector(vEnemyPos)
	return vEnemyAim:Dot(vEnemyToMe) > math.cos(math.rad(40))
end

--Updates current enemy's information.
function ENT:UpdateEnemyMemory()
	if self:GetEnemy() and self.Memory.Look and self:HasCondition("HaveEnemyLOS") and
		math.abs((self:GetEnemy():WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized()
		:Dot(self:GetEye().Ang:Forward())) > math.cos(math.rad(self.SearchAngle)) then
		--Update the position of current enemy
		self.Memory.EnemyAimVector = self:GetEnemyAimVector()
		self.Memory.EnemyPosition = self:GetEnemy():WorldSpaceCenter() --set the last position I saw
		self.Memory.Distance = self:GetRangeTo(self.Memory.EnemyPosition) --set the last distance I know
		self.Time.SeeEnemy = CurTime()
	end
end
