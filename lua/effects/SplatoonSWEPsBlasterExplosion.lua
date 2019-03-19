
local ss = SplatoonSWEPs
if not ss then return end
local mdl = Model "models/props_junk/PopCan01a.mdl"
function EFFECT:Init(e)
	self:SetModel(mdl)
	self:SetMaterial(ss.Materials.Effects.Invisible)
	self:SetNoDraw(true)
	local c = ss.GetColor(e:GetColor())
	local p = CreateParticleSystem(game.GetWorld(), ss.Particles.Explosion, PATTACH_WORLDORIGIN, 0, e:GetOrigin())
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, c:ToVector())
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * e:GetRadius())
	sound.Play(e:GetFlags() > 0 and "SplatoonSWEPs.BlasterHitWall" or "SplatoonSWEPs.BlasterExplosion", e:GetOrigin())
end
