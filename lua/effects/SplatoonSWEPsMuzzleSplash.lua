
local ss = SplatoonSWEPs
if not ss then return end

local MinRadius = 3
local Division = 16
local DegStep = 360 / Division
local RadStep = math.rad(DegStep)
local LifeTime = 7 * ss.FrameToSec
local mat = Material "splatoonsweps/effects/muzzlesplash.vmt"
function EFFECT:Init(e)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
	self.Color = ss:GetColor(e:GetColor())
	self.deg = math.Rand(0, 360)
	self.deg2 = math.Rand(0, 360)
	self.rad = e:GetRadius()
	self.tmin = MinRadius
	self.tmax = self.rad * 2
	self.InitTime = CurTime() - self.Weapon:Ping()
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

local halfpi = math.pi / 2
function EFFECT:Render()
	if not IsValid(self.Weapon) then return end
	if not isnumber(self.InitTime) then return end
	if not isnumber(self.rad) then return end
	if not isnumber(self.tmax) then return end
	if not isnumber(self.tmin) then return end
	local pos, ang = self.Weapon:GetMuzzlePosition()
	local norm = ang:Forward()
	local mul = self.Weapon:IsTPS() and
	self.Weapon.WElements.weapon.size or self.Weapon.VElements.weapon.size
	pos = self.Weapon:TranslateViewmodelPos(pos)
	mul = (mul.x + mul.y + mul.z) / 3
	self:SetPos(pos)
	
	render.SetMaterial(mat)
	local f = (CurTime() - self.InitTime) / LifeTime
	local alpha = math.Clamp(Lerp(f^2, 512, 0), 0, 255)
	local t = Lerp(f, self.tmin, self.tmax)
	local r = Lerp(4 * f * (1 - f), self.rad / 5, self.rad) * mul
	local u, v = {}, {}
	for _, deg in ipairs {self.deg, self.deg2} do
		mesh.Begin(MATERIAL_TRIANGLES, Division)
		for i = 0, Division do
			local a = Angle(ang) a:RotateAroundAxis(norm, deg + i * DegStep)
			local dir = a:Right() a:RotateAroundAxis(norm, DegStep)
			local nextdir = a:Right() a:RotateAroundAxis(norm, DegStep)
			local nextdir2 = a:Right() a:RotateAroundAxis(norm, -DegStep * 3)
			local prevdir = a:Right()
			local n = norm:Cross((prevdir - nextdir):GetNormalized())
			local n2 = norm:Cross((dir - nextdir2):GetNormalized())
			local p1 = dir * r + norm * t
			local p2 = nextdir * r + norm * t
			for n = i, i + 1 do
				local d = n * DegStep
				local q = math.Round(d / 90)
				local rad = math.rad(d)
				local tan = math.tan(rad - q * halfpi) / 2
				u[n] = u[n] or q % 2 == 0 and (q == 2 and 0 or 1) or q == 1 and .5 - tan or .5 + tan
				v[n] = v[n] or q % 2 > 0 and (q == 1 and 1 or 0) or q == 2 and .5 - tan or .5 + tan
			end
			
			AdvanceVertex(self, pos, -norm, .5, .5, alpha)
			AdvanceVertex(self, pos + p1, n, u[i], v[i], alpha)
			AdvanceVertex(self, pos + p2, n2, u[i + 1], v[i + 1], alpha)
		end
		mesh.End()
		
		f = f * 2
		alpha = math.Clamp(Lerp(f^2, 512, 0), 0, 255)
		t = Lerp(f * .7, self.tmin, self.tmax)
		r = Lerp(4 * f * (1 - f), self.rad / 5, self.rad) * mul
	end
end

-- Called when the effect should think, return false to kill the effect.
function EFFECT:Think()
	return IsValid(self.Weapon)
	and isnumber(self.InitTime)
	and isnumber(self.rad)
	and isnumber(self.tmax)
	and isnumber(self.tmin)
	and CurTime() < self.InitTime + LifeTime
end
