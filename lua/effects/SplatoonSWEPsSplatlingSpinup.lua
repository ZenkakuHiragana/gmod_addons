
local ss = SplatoonSWEPs
if not ss then return end
local drawviewmodel = GetConVar "r_drawviewmodel"
function EFFECT:Init(e)
	local w = e:GetEntity()
	if not IsValid(w) then return end
	self.TPS = w:IsTPS()
	if not (self.TPS or drawviewmodel:GetBool()) then return end
	local t = self.TPS
	local ent = t and w or w:GetViewModel()
	local a = ent:LookupAttachment "muzzle"
	local c = w:GetInkColorProxy() + ss.vector_one
	local div = t and 1 or 2 + e:GetFlags() / 2
	local s = e:GetScale() / div
	local p = CreateParticleSystem(ent, ss.Particles.SplatlingSpinup, PATTACH_POINT_FOLLOW, a, vector_origin)
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, c / 2)
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * s)
	p:SetIsViewModelEffect(not t)
	self:SetNoDraw(true)
	self.Weapon = w
	self.Effect = p
end

function EFFECT:Think()
	if not (self.TPS or drawviewmodel:GetBool()) then return false end
	local v = IsValid(self.Weapon)
	v = v and self.TPS == self.Weapon:IsTPS()
	v = v and self.Effect:IsValid()
	v = v and self.Weapon:GetCharge() < math.huge
	if v then return true end
	self.Effect:StopEmissionAndDestroyImmediately()
	return false
end
