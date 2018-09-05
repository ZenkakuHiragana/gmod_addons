
local ss = SplatoonSWEPs
if not ss then return end

local MinRadius = 3
local Division = 16
local DegStep = 90 / Division
local mat = Material "splatoonsweps/effects/ring"
local ref = Material "effects/water_warp01"
function EFFECT:Init(e)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
	local f = e:GetFlags()
	self.Color = ss.GetColor(e:GetColor())
	self.deg = e:GetScale()
	self.rad = e:GetRadius()
	self.LifeTime = e:GetAttachment() * ss.FrameToSec
	self.UseRefract = bit.band(f, 1) > 0
	self.curl = self.UseRefract and 3 or 2
	self.tmax = self.rad / 3
	self.tmin = self.rad / 6
	self.InitTime = CurTime() - self.Weapon:Ping() * bit.band(f, 128) / 128
	local pos, ang = self.Weapon:GetMuzzlePosition()
	self:SetPos(pos)
	self:SetAngles(ang)
end

local function AdvanceVertex(self, pos, norm, u, v, alpha)
	mesh.Color(self.Color.r, self.Color.g, self.Color.b, alpha)
	mesh.Normal(norm)
	mesh.Position(pos)
	mesh.TexCoord(0, u, v)
	mesh.AdvanceVertex()
end

function EFFECT:Render()
	if not IsValid(self.Weapon) then return end
	if not istable(self.Color) then return end
	if not isnumber(self.Color.r) then return end
	if not isnumber(self.Color.g) then return end
	if not isnumber(self.Color.b) then return end
	if not isnumber(self.deg) then return end
	if not isnumber(self.rad) then return end
	if not isnumber(self.InitTime) then return end
	if not isnumber(self.LifeTime) then return end
	if not isnumber(self.tmax) then return end
	if not isnumber(self.tmin) then return end
	local pos, ang = self.Weapon:GetMuzzlePosition()
	if not isvector(pos) then return end
	if not isangle(ang) then return end
	
	local g = physenv.GetGravity()
	local norm = ang:Forward()
	local mul = self.Weapon:IsTPS() and 1 or .5
	local LifeTime = math.max(0, CurTime() - self.InitTime)
	local f = LifeTime / self.LifeTime
	pos:Add(norm * self.tmax * f + g / 2 * LifeTime^2)
	self:SetPos(pos)
	
	render.SetMaterial(self.UseRefract and ref or mat)
	local alpha = math.Clamp(Lerp(f^2, 512, 0), 0, 255)
	local t = Lerp(f, self.tmax, self.tmin)
	local r = Lerp(f, MinRadius, self.rad) * mul
	for x = 0, 2 do
		mesh.Begin(MATERIAL_TRIANGLE_STRIP, Division * 2)
		for i = 0, Division do
			local v = i / Division
			local a = Angle(ang) a:RotateAroundAxis(norm, self.deg + DegStep * i)
			local dir = a:Right() a:RotateAroundAxis(norm, DegStep)
			local nextdir = a:Right() a:RotateAroundAxis(norm, -DegStep * 2)
			local prevdir = a:Right()
			local n = norm:Cross((prevdir - nextdir):GetNormalized())
			local dp1 = norm * (.5 - x / 3) * t
			local dp2 = norm * (.5 - (x + 1) / 3) * t
			local p1 = dir * (r - (x == 0 and t / self.curl or 0)) + dp1
			local p2 = dir * (r - (x == 2 and t / self.curl or 0)) + dp2
			AdvanceVertex(self, pos + p1, n, x / 3, v, alpha)
			AdvanceVertex(self, pos + p2, n, (x + 1) / 3, v, alpha)
		end
		mesh.End()
	end
end

-- Called when the effect should think, return false to kill the effect.
function EFFECT:Think()
	return IsValid(self.Weapon)
	and istable(self.Color)
	and isnumber(self.Color.r)
	and isnumber(self.Color.g)
	and isnumber(self.Color.b)
	and isnumber(self.deg)
	and isnumber(self.rad)
	and isnumber(self.InitTime)
	and isnumber(self.LifeTime)
	and isnumber(self.tmax)
	and isnumber(self.tmin)
	and CurTime() < self.InitTime + self.LifeTime
end
