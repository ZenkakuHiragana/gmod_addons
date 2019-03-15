
local ss = SplatoonSWEPs
if not ss then return end
local drawviewmodel = GetConVar "r_drawviewmodel"
function EFFECT:Init(e)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) or self.Weapon:ViewModelIndex() and not drawviewmodel:GetBool() then return end
	local p = CreateParticleSystem(self.Weapon, ss.Particles.MuzzleMist, e:GetFlags(), e:GetAttachment(), e:GetOrigin())
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, ss.GetColor(e:GetColor()):ToVector())
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * e:GetScale())
	p:AddControlPoint(3, game.GetWorld(), PATTACH_WORLDORIGIN, nil, e:GetStart())
	self.Effect = p
	self:SetNoDraw(true)
end
