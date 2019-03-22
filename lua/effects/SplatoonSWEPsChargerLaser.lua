
local ss = SplatoonSWEPs
if not ss then return end

local interp = 30
local beam = Material "trails/smoke"
local beamlight = Material "sprites/physbeama"
local drawviewmodel = GetConVar "r_drawviewmodel"
local cubic = Matrix {
	{2, -2, 1, 1},
	{-3, 3, -2, -1},
	{0, 0, 1, 0},
	{1, 0, 0, 0},
}

function EFFECT:Init(e)
	self:SetPos(GetViewEntity():GetPos())
	self.Weapon = e:GetEntity()
end

function EFFECT:Render()
	if ss.RenderingRTScope then return end
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	if not (self.Weapon:IsTPS() or drawviewmodel:GetBool()) then return end
	self:SetPos(GetViewEntity():GetPos())

	local self = self.Weapon
	local prog = self:GetChargeProgress(true)
	if prog == 0 then return end
	local scprog =  self:GetScopedProgress(true) * 255
	if self:GetNWBool "usertscope" and self:IsMine() and self:IsTPS() then
		scprog = 0
	end

	local color = ColorAlpha(ss.GetColor(self:GetNWInt "inkcolor"), 255 - scprog)
	local shootpos, dir = self:GetFirePosition(true)
	local pos, ang = self:GetMuzzlePosition()
	local col = ss.vector_one * self:GetColRadius(true)
	local range = self:GetRange(true)
	local tb = ss.SquidTrace
	if self.Owner:IsNPC() then
		local target = self:GetNPCTarget()
		if IsValid(target) then dir = (target:WorldSpaceCenter() - shootpos):GetNormalized() end
	end

	tb.start = pos
	tb.endpos = shootpos + dir * range
	tb.mins = -col
	tb.maxs = col
	tb.filter = {self, self.Owner}
	local tr = util.TraceHull(tb)
	if tr.StartSolid then return end

	tb.start = shootpos
	local tr = util.TraceHull(tb)
	local trlp = self.Owner ~= LocalPlayer() and ss.TraceLocalPlayer(tb.start, tb.endpos - tb.start)
	local texpos, dp = prog * tr.Fraction * 2 / interp, CurTime() / 5
	tr.HitPos = trlp or tr.HitPos
	local length = tr.HitPos:Distance(pos)

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
		local m = Matrix {
			{t3, t2, t, 1},
			{t3, t2, t, 1},
			{t3, t2, t, 1},
			{t3, t2, t, 1},
		} * cubic * mpos
		tpoints[#tpoints + 1] = tpoints[#tpoints] + texpos
		points[#points + 1] = Vector(m:GetField(1, 1), m:GetField(2, 2), m:GetField(3, 3))
	end

	for _, m in ipairs {beam, beamlight} do
		render.SetMaterial(m)
		render.StartBeam(interp + 2)
		for i, p in ipairs(points) do
			render.AddBeam(p, i == #points and .25 or 1, tpoints[i], color)
		end
		render.EndBeam()
	end
end

function EFFECT:Think()
	return IsValid(self.Weapon)
	and IsValid(self.Weapon.Owner)
	and self.Weapon:GetCharge() < math.huge
end
