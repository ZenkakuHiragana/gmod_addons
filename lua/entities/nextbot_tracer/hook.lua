
--Called when I've heard something.
--Arguments:
----Entity self | myself.
----Table t | Sound informations.
local function OnHearSound(self, t)
	--TODO: Tell other mates to alert
	if self:Validate(t.Entity) == 0 then
		if self:GetState() == NPC_STATE_IDLE then
			self:SetState(NPC_STATE_ALERT)
			self.Path.DesiredPosition = t.Entity:GetPos()
			self:StartMove()
		elseif self:GetState() == NPC_STATE_ALERT and self.Memory.Enemies == {} then
			self:SetEnemy(t.Entity)
		end
		
		self.Memory.Enemies[t.Entity] = {
			Pos = t.Entity:GetPos(),
			Distance = t.Entity:GetPos():DistToSqr(self:GetPos()),
			Forward = t.Entity:GetForward()
		}
	end
end

--++Hooks++-----------------------------------{
local classname = "nextbot_tracer"
hook.Add("OnEntityCreated", "NextbotIsAlone!", function(e)
	if IsValid(e) and e:GetClass() ~= classname and isfunction(e.AddEntityRelationship) then
		timer.Simple(1, function()
			if not IsValid(e) then return end
			for k, v in pairs(ents.FindByClass(classname)) do
				if IsValid(v) then e:AddEntityRelationship(v, D_HT, 1) end
			end
		end)
	end
end)

--Receiving serverside sound.
hook.Add("EntityEmitSound", "NextbotHearsSound", function(t)
	if not IsValid(t.Entity) then return end
	for k, v in pairs(ents.FindByClass(classname)) do
		if t.Entity == v then return end
		if IsValid(v) and v:IsHearingSound(t) then
			OnHearSound(v, t)
		end
	end
end)

--Receiving clientside sound.
util.AddNetworkString("NextbotHearsSound")
net.Receive("NextbotHearsSound", function(len, ply)
	local bot = net.ReadEntity()
	local t = net.ReadTable()
	if IsValid(bot) and IsValid(t.Entity) and bot:GetClass() == classname then
		OnHearSound(bot, t)
	end
end)

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

function ENT:OnInjured(info)
	if info:IsDamageType(DMG_BURN) then return end
	
	--Damage doubles when take a headshot.
	local tr = util.QuickTrace(info:GetDamagePosition(), info:GetDamageForce())
	if tr.Entity == self and tr.HitGroup == HITGROUP_HEAD then info:ScaleDamage(2) end
	
	--For "RepeatedDamage" condition.
	if CurTime() > self.Time.Damage + self.Time.ResetRepeatedDamage then self.Time.RepeatedDamage = CurTime() end
	self.Time.Damage = CurTime()
	
	--Register the attacker's info.
	if self:Validate(info:GetAttacker()) ~= 0 then return end
	local newenemy = self:FindEnemy()
	if newenemy then self:SetEnemy(newenemy) end
	if self:GetState() == NPC_STATE_IDLE then
		self:SetState(NPC_STATE_ALERT)
		self.Path.DesiredPosition = info:GetAttacker():GetPos()
		self:StartMove()
	elseif self:GetState() == NPC_STATE_ALERT and self.Memory.Enemies == {} then
		self:SetEnemy(info:GetAttacker())
	end
	
	self.Memory.Enemies[info:GetAttacker()] = {
		Pos = info:GetAttacker():GetPos(),
		Distance = info:GetAttacker():GetPos():DistToSqr(self:GetPos()),
		Forward = info:GetAttacker():GetForward()
	}
end

function ENT:OnRemove()	
	if IsValid(self.Equipment.Entity) then self.Equipment.Entity:Remove() end
	if IsValid(self.Trail) then self.Trail:Remove() end
end

function ENT:OnKilled(info)
	hook.Call("OnNPCKilled", GAMEMODE, self, info:GetAttacker(), info:GetInflictor())
	if IsValid() then
		local w = ents.Create(self.Weapon:GetClass())
		w:SetPos(self.Weapon:GetPos())
		w:SetAngles(self.Weapon:GetAngles())
		w:SetVelocity(self.Weapon:GetAbsVelocity())
		w:Spawn()
		self.Weapon:Remove()
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
	self.loco:Jump()
	self.loco:ClearStuck()
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
	
	debugoverlay.Line(self:WorldSpaceCenter(), self:WorldSpaceCenter() + warpto * 50, 5, Color(255,255,0,255),true)
	self:SetPos(self:GetPos() + warpto)
	self.Path.DesiredPosition = self:GetPos() + warpto * 5
	self:StartMove()
	
	local min, max = self:GetCollisionBounds()
	self:SetCollisionBounds(Vector(-4, -4, min.z), Vector(4, 4, max.z))
	timer.Simple(1, function() if not IsValid(self) then return end
		self:SetCollisionBounds(min, max)
	end)
end
----------------------------------------------}


