
local ss = SplatoonSWEPs
if not ss then return end
function EFFECT:Init(e)
	local c = ss.GetColor(e:GetColor())
	local p = CreateParticleSystem(game.GetWorld(), ss.Particles.BlasterTrail, PATTACH_WORLDORIGIN, nil, e:GetOrigin())
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, (c:ToVector() + ss.vector_one) / 2)
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * e:GetRadius())
	self:SetNoDraw(true)
end
