
local ss = SplatoonSWEPs
if not ss then return end
local drawviewmodel = GetConVar "r_drawviewmodel"
function EFFECT:Init(e)
	local w = e:GetEntity()
	if not IsValid(w) or w:ViewModelIndex() and not drawviewmodel:GetBool() then return end
	local p = CreateParticleSystem(w, ss.Particles.MuzzleMist, e:GetFlags(), e:GetAttachment(), e:GetOrigin())
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, ss.GetColor(e:GetColor()):ToVector())
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * e:GetScale())
	p:AddControlPoint(3, game.GetWorld(), PATTACH_WORLDORIGIN, nil, e:GetStart())
	self:SetNoDraw(true)
end
