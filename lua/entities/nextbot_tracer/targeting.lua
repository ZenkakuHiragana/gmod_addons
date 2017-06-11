
--Determines whether given entity is targetable or not.
function ENT:Validate(e)
	if not IsValid(e) or e == self then return -1 end
	
	local c = e:GetClass()
	if not isstring(c) then return -1
	elseif c == "npc_rollermine" or c == "npc_turret_floor" then
		return 0
	elseif c ~= classname or IsAlone then
		if e:Health() > 0 then
			if not c:find("bullseye") and c ~= "env_flare" and
			c ~= "npc_combinegunship" and c ~= "npc_helicopter" and c ~= "npc_strider" then
				if e:IsNPC() or e.Type == "nextbot" or
				(e:IsPlayer() and not (self:GetConVarBool("ai_ignoreplayers") or e:IsFlagSet(FL_NOTARGET))) then
						return 0
				end
			end
		end
	else
		return 1
	end
end

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
	local lst = ents.FindInSphere(self:GetEye().Pos, self.FarDistance)
	local pos, dist, pool, nearestenemy, e, sentence = math.huge, math.huge, {}
	
	for k, v in pairs(lst) do
		e = self:Validate(v)
		if e == 0 and (v:GetPos() - self:GetEye().Pos):GetNormalized():Dot(self:GetEye().Ang:Forward())
			> math.cos(math.rad(self.SearchAngle)) then
			pos = v:WorldSpaceCenter()
			dist = self:GetRangeSquaredTo(v:GetPos())
			if self:CanSee(pos) then --normal entity and can see
				self.Memory.Enemies[v] = {Pos = pos, Distance = dist, Forward = v:GetForward()}
			end
		end
	end
	
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		if self:Validate(k) ~= 0 or 
			(self:CanSee(v.Pos) and not self:CanSee(k:WorldSpaceCenter())) then
			self.Memory.Enemies[k] = nil
		end
	end
	for k, v in SortedPairsByMemberValue(self.Memory.Enemies, "Distance") do
		if IsValid(k) then return k end --Get the nearest enemy.
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

