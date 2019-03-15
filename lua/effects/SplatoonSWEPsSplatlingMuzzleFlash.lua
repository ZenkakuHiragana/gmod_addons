
local ss = SplatoonSWEPs
if not ss then return end
function EFFECT:Init(e)
	local w = e:GetEntity()
	if not IsValid(w) then return end
	local t = w:IsTPS()
	local ent = t and w or w:GetViewModel()
	local s = t and 30 or 15
	local c = w:GetInkColorProxy() + ss.vector_one
	local a = ent:LookupAttachment "muzzle"
	local p = CreateParticleSystem(ent, ss.Particles.SplatlingMuzzleFlash, PATTACH_POINT_FOLLOW, a, vector_origin)
	p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, c / 2)
	p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * s)
	self:SetNoDraw(true)
end
