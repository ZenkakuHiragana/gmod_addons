
include("shared.lua")
local classname = "nextbot_tracer"
killicon.AddAlias(classname, "weapon_pistol")
language.Add(classname, "Nextbot Tracer")

hook.Add("EntityEmitSound", "NextbotHearsSound", function(t)
	if not IsValid(t.Entity) then return end
	for k, v in pairs(ents.FindByClass(classname)) do
		if t.Entity == v or v:Validate(t.Entity) ~= 0 then return end
		if v:IsHearingSound(t) then
			net.Start("NextbotHearsSound")
			net.WriteEntity(v)
			net.WriteTable(t)
			net.SendToServer()
		end
	end
end)

--Initializes this NPC.
function ENT:Initialize()	
	--Shared functions
	self:SetModel(self.Model)
	self:SetHealth(self.HP.Init)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:AddFlags(FL_AIMTARGET)
	self:SetSolid(SOLID_BBOX)
	self:MakePhysicsObjectAShadow(true, true)
end