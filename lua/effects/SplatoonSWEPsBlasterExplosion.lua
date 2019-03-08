
local ss = SplatoonSWEPs
if not ss then return end

function EFFECT:Init(e)
	self:SetNoDraw(true)
	local c = ss.GetColor(e:GetColor())
	local p = CreateParticleSystem(game.GetWorld(), ss.Particles.Explosion, PATTACH_WORLDORIGIN, 0, e:GetOrigin())
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, Vector(c.r, c.g, c.b) / 255)
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * e:GetRadius())
	sound.Play(e:GetFlags() > 0 and "SplatoonSWEPs.BlasterHitWall" or "SplatoonSWEPs.BlasterExplosion", e:GetOrigin())
end
