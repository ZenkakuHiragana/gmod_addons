
local ___DEBUG_SEE = false
local ___DEBUG_ENEMY_MEMORY = false

--Gets personal enemy entity.
function ENT:GetEnemy()
	if self:Validate(self.Memory.Enemy) ~= 0 then return nil end
	return self.Memory.Enemy
end

--Sets personal enemy memory.
function ENT:SetEnemy(ent)
	if self:Validate(ent) ~= 0 then return end
	self.Memory.Enemy = ent
end

--Finds nearest enemy and returns it.
function ENT:FindEnemy()
	local lst = ents.FindInSphere(self:GetEye().Pos, self.Dist.Search)
	local pos, nearestenemy = vector_origin, NULL
	
	for k, v in pairs(lst) do
		if self:Validate(v) == 0 and self:GetAimVector(v:WorldSpaceCenter()):Dot(self:GetEye().Ang:Forward()) > math.cos(math.rad(self.SearchAngle)) then
			pos = v:WorldSpaceCenter()
			if self:CanSee(pos) then --normal entity and can see
				self.Memory.Enemies[v] = {Pos = pos, Distance = self:GetRangeSquaredTo(v:GetPos()), Forward = self:GetEnemyAimVector(v)}
			end
		end
	end
	
	--Clean up old infomations.
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		if self:Validate(k) ~= 0 or 
			(self:CanSee(v.Pos) and not self:CanSee(k:WorldSpaceCenter())) then
			self.Memory.Enemies[k] = nil
		end
	end
	
	if ___DEBUG_ENEMY_MEMORY then
		for k, v in pairs(self.Memory.Enemies) do
			debugoverlay.Sphere(k:WorldSpaceCenter(), 10, 0.1, Color(0, 255, 0, 255), true)
		end
	end
	
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		if IsValid(k) then --Get the nearest enemy.
			if ___DEBUG_ENEMY_MEMORY then
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
function ENT:CanSee(pos, opt)
	local opt = opt or {}
	local e = pos or self.Memory.EnemyPosition
	local filter = table.Copy(self.breakable_filter)
	local tr = util.TraceLine({
		start = opt.start or self:GetEye().Pos,
		endpos = e,
		filter = self.breakable_filter,
		mask = opt.shoot and MASK_SHOT or MASK_BLOCKLOS_AND_NPCS,
	})
	if ___DEBUG_SEE then
		debugoverlay.Line(tr.StartPos, tr.HitPos, 3, Color(0, 255, 0, 255), false)
	end
	return not tr.StartSolid and not tr.HitWorld and tr.HitPos:DistToSqr(e) < 100e+2
end

--Returns where current enemy or the given entity is looking at.
--Argument:
----Entity e | The given entity(Optional).
function ENT:GetEnemyAimVector(e)
	if not IsValid(e) and not IsValid(self.Memory.Enemy) then return self:WorldSpaceCenter() end
	local ent = IsValid(e) and e or self.Memory.Enemy
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
	if self:GetEnemy() and self.Memory.Look then
		--Update the position of current enemy
		self.Memory.EnemyAimVector = self:GetEnemyAimVector()
		self.Memory.EnemyPosition = self:GetEnemy():WorldSpaceCenter() --set the last position I saw
		self.Memory.Distance = self:GetRangeTo(self.Memory.EnemyPosition) --set the last distance I know
		self.Time.SeeEnemy = CurTime()
	end
end
