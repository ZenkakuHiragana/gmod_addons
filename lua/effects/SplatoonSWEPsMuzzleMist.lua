
local ss = SplatoonSWEPs
if not ss then return end

local NumParticles = 16
local LifeTime = 16 * ss.FrameToSec
local mat = {}
for i = 1, 16 do
	local id = (i < 10 and "0" or "") .. tostring(i)
	mat[i] = Material("particle/smokesprites_00" .. id)
end

function EFFECT:Init(e)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
	self.Color = ss.GetColor(e:GetColor())
	self.size = e:GetScale()
	self.InitTime = CurTime() - self.Weapon:Ping()
	local pos, ang = self.Weapon:GetMuzzlePosition()
	self:SetPos(pos)
	self:SetAngles(ang)
	
	self.vel = {}
	self.rot = {}
	self.deg = {}
	local rad = e:GetRadius()
	local dir = e:GetNormal()
	for i = 1, NumParticles do
		self.vel[i] = (VectorRand() + dir):GetNormalized() * math.Rand(0, rad)
		self.rot[i] = math.Rand(-720, 720)
		self.deg[i] = math.Rand(0, 360)
	end
end

function EFFECT:Render()
	if not IsValid(self.Weapon) then return end
	if not istable(self.Color) then return end
	if not isnumber(self.Color.r) then return end
	if not isnumber(self.Color.g) then return end
	if not isnumber(self.Color.b) then return end
	local pos, ang = self.Weapon:GetMuzzlePosition()
	local norm = ang:Forward()
	local mul = self.Weapon:IsTPS() and 1 or .5
	self:SetPos(pos)
	
	local f = (CurTime() - self.InitTime) / LifeTime
	local alpha = Lerp(f, 255, 0)
	local s = Lerp(f^2, self.size / 5, self.size) * mul
	render.SetMaterial(mat[math.max(1, math.floor(f * 16) + 1)])
	for i = 1, NumParticles do
		render.DrawQuadEasy(Lerp(f, pos, pos + self.vel[i]),
		-EyeAngles():Forward(), s, s, ColorAlpha(self.Color, alpha),
		self.deg[i] + CurTime() * self.rot[i])
	end
end

-- Called when the effect should think, return false to kill the effect.
function EFFECT:Think()
	return IsValid(self.Weapon)
	and istable(self.Color)
	and isnumber(self.Color.r)
	and isnumber(self.Color.g)
	and isnumber(self.Color.b)
	and CurTime() < self.InitTime + LifeTime
end
