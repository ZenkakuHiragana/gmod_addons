
--Called when I've heard something.
--Arguments:
----Entity self | myself.
----Table t | Sound informations.
function ENT:OnHearSound(t)
	--TODO: Tell other mates to alert
	if self:GetState() == NPC_STATE_COMBAT then return end
	local pos = isvector(t.Pos) and t.Pos or t.Entity:GetPos()
	if self:Disposition(t.Entity) == D_HT then
		if self:GetState() == NPC_STATE_IDLE then
			self:SetState(NPC_STATE_ALERT)
		elseif self:GetState() == NPC_STATE_ALERT then
			self:SetEnemy(t.Entity)
		end
		
		self.Path.DesiredPosition = pos
		self:StartMove()
	elseif not (t.Entity:IsPlayer() or t.Entity:GetClass():find("grenade") or
		CurTime() > self.Time.GotoSoundSource) then
		if t.Channel == CHAN_WEAPON or not
		(self:Disposition(t.Entity) == D_LI and t.Channel == CHAN_BODY) then
			self:SetState(NPC_STATE_ALERT)
			self.Path.DesiredPosition = pos
			self:StartMove()
			
			self.Time.GotoSoundSource = CurTime() + math.Rand(5, 8)
		end
	end
end

--++Hooks++-----------------------------------{
local classname = "nextbot_tracer"
local targetname = "NextbotTracerRelationship"
hook.Add("OnEntityCreated", "NextbotTracerIsAlone!", function(e)
	if IsValid(e) and e:GetClass() ~= classname and isfunction(e.AddEntityRelationship) then
		local t = targetname .. e:EntIndex()
		timer.Create(t, 1, 0, function()
			if not IsValid(e) then timer.Remove(t) return end
			for k, v in pairs(ents.FindByClass(classname)) do
				if IsValid(v) then e:AddEntityRelationship(v, v:Disposition(e), 0) end
			end
		end)
	end
end)

--Receiving serverside sound.
hook.Add("EntityEmitSound", "NextbotTracerHearsSound", function(t)
	if not IsValid(t.Entity) then return end
	for k, v in pairs(ents.FindByClass(classname)) do
		if t.Entity == v then return end
		if IsValid(v) and isfunction(v.OnHearSound) and v.IsInitialized and v:IsHearingSound(t) then
			v:OnHearSound(t)
		end
	end
end)

--Receiving clientside sound.
util.AddNetworkString("NextbotTracerHearsSound")
net.Receive("NextbotTracerHearsSound", function(len, ply)
	local bot = net.ReadEntity()
	local t = net.ReadTable()
	if IsValid(bot) and IsValid(t.Entity) and bot:GetClass() == classname and isfunction(bot.OnHearSound) then
		bot:OnHearSound(t)
	end
end)

util.AddNetworkString("SetAimParameterRecall") --Sets aim position properly for recall.
util.AddNetworkString("Nextbot Tracer: No playermodel notification") --Error notification.

--Called when the nextbot touches another entity.
--Applies the physics damage.
--Argument:
----Entity v | The entity the nextbot came in contact with.
function ENT:OnContact(v)
	if not IsValid(v) then return end
	self.Time.Touch = CurTime()
	
	if v:IsPlayer() or v:IsNPC() or v.Type == "nextbot" then return end	
	local p = v:GetPhysicsObject() if not IsValid(p) then return end
	local f = -p:GetVelocity()
	
	p:SetVelocityInstantaneous(vector_origin)
	p:ApplyForceCenter(f)
	
	local e, division = p:GetEnergy(), 2.0 * 10e+6 if e < division then return end
	if v:IsVehicle() then e = v:GetSpeed() * division end
	local d, attacker = DamageInfo(), v:GetPhysicsAttacker()
	if not IsValid(attacker) then attacker = v end
	d:SetAttacker(attacker)
	d:SetDamage(e / division)
	d:SetDamageForce(p:GetVelocity() / 2)
	d:SetDamagePosition(self:WorldSpaceCenter())
	d:SetDamageType(DMG_CRUSH)
	d:SetInflictor(v)
	d:SetMaxDamage(d:GetDamage())
	d:SetReportedPosition(p:GetMassCenter())
	
	self:TakeDamageInfo(d)
end

--Returns whether or not the given position is in a certain hitbox.
--Arguments:
----Vector pos | The given position.
----number box | HitBox number.
----number group | HitGroup number.
----string bone | Bone name.
local boxdelta = Vector(1, 1, 1)
function ENT:WithinHitBox(pos, box, group, bone)
	local boxmin, boxmax = self:GetHitBoxBounds(box, group)
	local bonepos, boneang = self:GetBonePosition(self:LookupBone(bone))
	local dmgpos = WorldToLocal(pos, angle_zero, bonepos, boneang)
	return dmgpos:WithinAABox(boxmin - boxdelta, boxmax + boxdelta)
end

function ENT:OnInjured(info)
	if info:IsDamageType(DMG_BURN) then
		if CurTime() > self.Time.VoiceOnFire then
			self.Time.VoiceOnFire = CurTime() + math.Rand(15, 40)
			self:EmitSound("Nextbot_Tracer.OnFire")
		end
		return
	end
	
	--Damage doubles when it's a headshot.
	self:PerformFlinch(info)
	if self:WithinHitBox(info:GetDamagePosition(),
		self.HitBox.Head, self.HitGroup.Head, self.Bone.Head) then
		info:ScaleDamage(2)
	end
	
	--For "RepeatedDamage" condition.
	if CurTime() > self.Time.Damage + self.Time.ResetRepeatedDamage then self.Time.RepeatedDamage = CurTime() end
	self.Time.Damage = CurTime()
	
	--Register the attacker's info.
	local relationship = self:Disposition(info:GetAttacker())
	if relationship == D_HT then
		if self:GetState() == NPC_STATE_IDLE then
			self:SetState(NPC_STATE_ALERT)
			self.Path.DesiredPosition = info:GetAttacker():GetPos()
			self:StartMove()
		elseif not self:GetEnemy() then
			self:SetEnemy(info:GetAttacker())
		end
	elseif relationship == D_NU then
		self:AddEntityRelationship(info:GetAttacker(), D_HT, 0)
	elseif info:GetAttacker():IsPlayer() and relationship == D_LI then
		self:AddEntityRelationship(info:GetAttacker(), D_NU, 0)
	end
end

function ENT:OnRemove()	
	if istable(self.Equipment) and IsValid(self.Equipment.Entity) then
		SafeRemoveEntity(self.Equipment.Entity)
	end
	if IsValid(self.Trail) then SafeRemoveEntity(self.Trail) end
end

function ENT:OnLandOnGround()
	if self:GetVelocity().z < -1 then self:AddGesture(ACT_LAND) end
end

function ENT:OnKilled(info)
	hook.Run("OnNPCKilled", self, info:GetAttacker(), info:GetInflictor())
	if IsValid(self.Equipment.Entity) then
		local w = ents.Create(self.Equipment.Name)
		w:SetPos(self:WorldSpaceCenter())
		w:SetAngles(self.Equipment.Entity:GetAngles())
		w:SetVelocity(self.Equipment.Entity:GetAbsVelocity())
		w:Spawn()
		SafeRemoveEntity(self.Equipment.Entity)
		timer.Simple(10, function()
			if not IsValid(w) or IsValid(w:GetOwner()) then return end
			SafeRemoveEntity(w)
		end)
	end
	self:BecomeRagdoll(info)
	self:OnRemove()
end

function ENT:OnNavAreaChanged(old, new)
	if new and new:IsValid() then
		self.Memory.CrouchNav = new:HasAttributes(NAV_MESH_CROUCH)
		self.Memory.WalkNav = new:HasAttributes(NAV_MESH_WALK)
		self.Memory.Jump = new:HasAttributes(NAV_MESH_JUMP)
	end
end

function ENT:OnStuck()
	self.Path.Main:Invalidate()
	self.loco:ClearStuck()
	self.loco:Jump()
	local forward, back, right, left =
		util.QuickTrace(self:WorldSpaceCenter(), self:GetForward() * 30, self),
		util.QuickTrace(self:WorldSpaceCenter(), -self:GetForward() * 30, self),
		util.QuickTrace(self:WorldSpaceCenter(), self:GetRight() * 30, self),
		util.QuickTrace(self:WorldSpaceCenter(), -self:GetRight() * 30, self)
	local warpto = self:GetForward() * 5
	local state = (forward.Hit and 1 or 0) + (back.Hit and 2 or 0) + (left.Hit and 4 or 0) + (right.Hit and 8 or 0)
	if state == 0 or state == 15 then
		warpto = VectorRand() * 5
	elseif state == 1 then
		warpto:Rotate(Angle(0, math.Rand(45, 315), 0))
	elseif state == 2 then
		warpto:Rotate(Angle(0, math.Rand(-135, 135), 0))
	elseif state == 3 then
		warpto:Rotate(Angle(0, math.Rand(45, 135), 0))
		if math.random() > 5 then warpto = -warpto end
	elseif state == 4 then
		warpto:Rotate(Angle(0, math.Rand(-225, 45), 0))
	elseif state == 5 then
		warpto:Rotate(Angle(0, math.Rand(-225, -45), 0))
	elseif state == 6 then
		warpto:Rotate(Angle(0, math.Rand(-135, 45), 0))
	elseif state == 7 then
		warpto:Rotate(Angle(0, math.Rand(-135, -45), 0))
	elseif state == 8 then
		warpto:Rotate(Angle(0, math.Rand(-45, 225), 0))
	elseif state == 9 then
		warpto:Rotate(Angle(0, math.Rand(45, 225), 0))
	elseif state == 10 then
		warpto:Rotate(Angle(0, math.Rand(-45, 135), 0))
	elseif state == 11 then
		warpto:Rotate(Angle(0, math.Rand(45, 135), 0))
	elseif state == 12 then
		warpto:Rotate(Angle(0, math.Rand(-45, 45), 0))
		if math.random() > 5 then warpto = -warpto end
	elseif state == 13 then
		warpto:Rotate(Angle(0, math.Rand(135, 225), 0))
	elseif state == 14 then
		warpto:Rotate(Angle(0, math.Rand(-45, 45), 0))
	end
	
	if self.Debug.StuckReposition then
		debugoverlay.Line(self:WorldSpaceCenter(), self:WorldSpaceCenter() + warpto * 50, 5, Color(255,255,0,255),true)
	end
	
	self:SetPos(self:GetPos() + warpto)
end

function ENT:Use(activator, caller, type, value)
	if self:Disposition(activator) == D_LI and activator:IsPlayer() then
		if self.Memory.ChaseTarget == activator then
			self.Memory.ChaseTarget = nil
		else
			self.Memory.ChaseTarget = activator
			self.Path.Chasing:Compute(self, activator:GetPos())
			if CurTime() > self.Time.SpeakUnderstood then
				self.Time.SpeakUnderstood = CurTime() + math.Rand(15, 45)
				self:EmitSound("Nextbot_Tracer.Understood")
			end
		end
	end
end
----------------------------------------------}


