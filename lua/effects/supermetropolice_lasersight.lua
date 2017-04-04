
local LASER = Material("effects/bluelaser1")
local SPRITE = Material("sprites/blueglow2")

function EFFECT:Init(e)
	self.ent = e:GetEntity()
	if not IsValid(self.ent) then return end
	
	self.Owner = self.ent:GetParent()
	if not IsValid(self.Owner) then return end
	
	self.att = self.ent:LookupAttachment("muzzle")
	if self.ent:GetAttachment(self.att) then
		self.pos = self.ent:GetAttachment(self.att).Pos
		self.ang = self.ent:GetAttachment(self.att).Ang
	end
	self.dir = self.ent:GetForward()
	
	self.rot = math.random(-100, 100)
end

function EFFECT:Think()
	self:SetPos(EyePos() + EyeVector() * 10)
	return true
end

function EFFECT:Render()
	if IsValid(self.ent) and IsValid(self.Owner) and self.ent:GetAttachment(self.att) and
		IsValid(self.Owner:GetNetworkedEnemy()) and self.Owner:GetNetworkedEnemy():Health() > 0 and self.Owner:GetLook() then
		
		self.pos = self.ent:GetAttachment(self.att).Pos
		self.ang = self.ent:GetAttachment(self.att).Ang
		self.targetpos = self.Owner:GetTargetPos()
		self.dir = (self.targetpos - self.pos):GetNormalized()
		if self.dir:Dot(self.ang:Forward()) < 0.75 then return end
	--	self.dir = self.ent:GetForward()
	--	self.dir = self.Owner:GetAttachment(self.Owner:LookupAttachment("anim_attachment_RH")).Ang:Forward()
		
		local tr = util.TraceLine({
			start = self.pos,
			endpos = self.targetpos,
		--	endpos = self.pos + self.dir * 60000,
			filter = {self.ent, self.Owner},
			mask = MASK_BLOCKLOS_AND_NPCS,
		})
		local target = tr.HitPos
		local normal = tr.HitNormal
		local beamscale = tr.HitPos:DistToSqr(self.pos) / 40000
		local alpha = 254 * (math.cos(CurTime() * self.rot / 10) + 1) / 2 + 1
		
		render.SetMaterial(LASER)
		render.DrawBeam(self.pos, target, 2, 0, beamscale, Color(255, 255, 255, alpha))
		
		render.SetMaterial(SPRITE)
		render.DrawSprite(target + normal, 5, 5, Color(255, 255, 255, alpha * 0.7))
		render.DrawQuadEasy(target + normal / 2, normal, 6, 6, Color(255, 255, 255, alpha), CurTime() * self.rot)
		
		return true
	else
		return false
	end
	
end
