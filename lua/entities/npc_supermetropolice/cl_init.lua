
include('shared.lua')
language.Add("npc_supermetropolice", "Super Metropolice")

hook.Add("EntityEmitSound", "SuperMetropoliceHearSound", function(t)
	if not IsValid(t.Entity) then return end
	for k, v in pairs(ents.FindByClass("npc_supermetropolice")) do
		if t.Entity == v or v:Validate(t.Entity) ~= 0 then return end
		if v:IsHearingSound(t) then
			net.Start("SuperMetropoliceHearSound")
			net.WriteEntity(v)
			net.WriteTable(t)
			net.SendToServer()
		end
	end
end)

function ENT:GetEnemy()
	return self:GetNetworkedEnemy()
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Look")
	self:NetworkVar("Entity", 0, "NetworkedEnemy")
end

function ENT:OnRemove() if IsValid(self.mdl) then self.mdl:Remove() end end
function ENT:Initialize()
	self:SetModel("models/Police.mdl")
	self:SetHealth(self.MaxHealth)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:MakePhysicsObjectAShadow(true, true)
	
--	self.Memory = {}
--	self.Memory.AimAttach = 1 --Aiming at attachment, if I couldn't find the enemy's head.
	self.aimattach = 1
	
	if GetConVar("supermetropolice_burninghead"):GetBool() then
		local tb = {}
		self.mdl = ents.CreateClientProp()
		self.mdl:SetPos(self:GetPos())
		self.mdl:SetParent(self, self:LookupAttachment("forward"))
		self.mdl:SetNoDraw(true)
		self.mdl:DrawShadow(false)
		self.mdl:Spawn()
		self:CallOnRemove("SuperMetropolice.RemoveClientSideEntity" .. self:EntIndex(), 
		function(self) if IsValid(self.mdl) then self.mdl:Remove() end end)
		for i = 1, 64 do tb[i] = {attachtype = PATTACH_ABSORIGIN_FOLLOW, entity = self.mdl} end
		self.mdl:CreateParticleEffect("burning_character", tb)
	end
end

function ENT:Think()
	if IsValid(self.mdl) then
		self.mdl:SetPos(self:GetAttachment(self:LookupAttachment("forward")).Pos)
	end
end

