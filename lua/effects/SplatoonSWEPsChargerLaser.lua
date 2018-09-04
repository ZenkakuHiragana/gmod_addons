
local ss = SplatoonSWEPs
if not ss then return end

local interp = 30
local beam = Material "trails/smoke"
local beamlight = Material "sprites/physbeama"
local sprite = Material "sprites/gmdm_pickups/light"
local cubic = Matrix {
	{2, -2, 1, 1},
	{-3, 3, -2, -1},
	{0, 0, 1, 0},
	{1, 0, 0, 0},
}

function EFFECT:Init(e)
	self:SetPos(GetViewEntity():GetPos())
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
end

function EFFECT:Render()
	if not IsValid(self.Weapon) then return end
	self:SetPos(GetViewEntity():GetPos())
	
	local self = self.Weapon
	local prog = self:GetChargeProgress(true)
	if prog == 0 then return end
	local color = ColorAlpha(self.Color, (1 - self:GetScopedProgress(true)) * 255)
	
	local shootpos, dir = self:GetFirePosition()
	local pos, ang = self:GetMuzzlePosition()
	local col = ss.vector_one * self:GetColRadius()
	local range = self:GetRange()
	local tb = ss.SquidTrace
	tb.start, tb.endpos, tb.mins, tb.maxs, tb.filter
	= pos, shootpos + dir * range, -col, col, {self, self.Owner}
	if util.TraceHull(tb).StartSolid then return end
	
	tb.start = shootpos
	local tr = util.TraceHull(tb)
	local texpos, dp = prog * tr.Fraction * 2 / interp, CurTime() / 5
	local length = tr.HitPos:Distance(pos)
	local aimang = self.Owner:EyeAngles() aimang:Normalize()
	
	ang = ang:Forward() * length / 5
	dir = dir * length
	local p, q, mpos = pos, dp, Matrix {
		{pos.x, pos.y, pos.z, 0},
		{tr.HitPos.x, tr.HitPos.y, tr.HitPos.z, 0},
		{ang.x, ang.y, ang.z, 0},
		{dir.x, dir.y, dir.z, 0},
	}
	
	local tpoints = {q}
	local points = {p}
	for t = 0, interp do
		t = t / interp
		local t2, t3 = t^2, t^3
		p, q = Matrix {
			{t3, t2, t, 1},
			{t3, t2, t, 1},
			{t3, t2, t, 1},
			{t3, t2, t, 1},
		} * cubic * mpos, q + texpos
		table.insert(points, Vector(p:GetField(1, 1), p:GetField(2, 2), p:GetField(3, 3)))
		table.insert(tpoints, q)
	end
	
	for _, m in ipairs {beam, beamlight} do
		render.SetMaterial(m)
		render.StartBeam(interp + 2)
		for i, p in ipairs(points) do
			render.AddBeam(p, 1, tpoints[i], color)
		end
		render.EndBeam()
	end
	
	local tipcolor = self:GetInkColorProxy() * 255
	tipcolor = (tipcolor / tipcolor:Dot(ss.GrayScaleFactor)):ToColor()
	
	render.SetMaterial(sprite)
	render.DrawSprite(tr.HitPos, 16, 16, ColorAlpha(tipcolor, color.a))
end

function EFFECT:Think()
	return IsValid(self.Weapon) and self.Weapon:GetCharge() < math.huge
end
