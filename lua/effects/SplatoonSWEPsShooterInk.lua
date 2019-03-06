
local ss = SplatoonSWEPs
if not ss then return end

function EFFECT:Init(e)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	local f = e:GetFlags()
	local p = self.Weapon.Primary
	local isdrop = bit.band(f, 1) > 0
	local ping = bit.band(f, 128) > 0 and self.Weapon:Ping() or 0
	local SplashInterval = isdrop and 0 or p.SplashInterval
	local SplashPatterns = isdrop and 1 or p.SplashPatterns
	local StraightTime = isdrop and 0 or p.Straight + ss.ShooterDecreaseFrame / 2
	local pos, ang = self.Weapon:GetMuzzlePosition()
	local cc = e:GetColor()
	local c = ss.GetColor(cc)
	self.Real = {
		Ang = e:GetAngles(),
		InitTime = CurTime() - ping - ss.ShooterDecreaseFrame,
		InitPos = e:GetOrigin(),
		Pos = e:GetOrigin(),
		Velocity = e:GetStart(),
	}
	self.Apparent = {
		Ang = ang,
		InitTime = self.Real.InitTime,
		InitPos = Vector(pos),
		Pos = pos,
		Velocity = (self.Real.Pos + self.Real.Velocity * StraightTime - pos) / StraightTime
	}

	if isdrop then
		self.Apparent.InitPos = Vector(self.Real.Pos)
		self.Apparent.Pos = Vector(self.Real.Pos)
		self.Apparent.Ang = Angle(self.Real.Ang)
		self.Apparent.Velocity = vector_origin
	end

	self.Tail = {
		Ang = self.Apparent.Ang,
		InitTime = self.Real.InitTime + ss.ShooterTrailDelay,
		InitPos = self.Apparent.InitPos,
		Pos = Vector(self.Apparent.Pos),
		Velocity = Vector(self.Apparent.Velocity),
	}

	self.ColorCode = cc
	self.ColorTable = {c.r, c.g, c.b, 255}
	self.Hit = false
	self.IsCarriedByLocalPlayer = self.Weapon:IsCarriedByLocalPlayer()
	self.IsDrop = isdrop
	self.Render = ss.Simulate.EFFECT_ShooterRender
	self.Simulate = ss.Simulate.Shooter
	self.Size = ss.mColRadius * (self.IsDrop and .5 or 1)
	self.Speed = self.Real.Velocity:Length()
	self.SplashCount = 0
	self.SplashInit = e:GetAttachment() * SplashInterval / SplashPatterns
	self.SplashInterval = SplashInterval
	self.SplashNum = e:GetScale()
	self.Straight = self.IsDrop and 0 or p.Straight
	self.Table = {self.Real, self.Apparent, self.Tail}
	self.Think = ss.Simulate.EFFECT_ShooterThink
	for _, t in ipairs(self.Table) do
		t.endpos = t.Pos
		t.IsDrop = self.IsDrop
		t.start = Vector()
		t.Straight = p.Straight
		t.Time = 0
	end

	self:SetModel "models/props_junk/PopCan01a.mdl"
	self:SetAngles(self.Apparent.Ang)
	self:SetMaterial(ss.Materials.Effects.Invisible)
	self:SetPos(self.Apparent.Pos)
end

function EFFECT:CreateDrops(tr) -- Creates ink drops
	if self.IsDrop or self.SplashCount > self.SplashNum then return end
	local SplashInterval = self.SplashInterval
	local len = (tr.HitPos - self.Real.InitPos):Length2D()
	local nextlen = self.SplashCount * SplashInterval + self.SplashInit
	local e = EffectData()
	while len >= nextlen do -- Create drops
		e:SetAttachment(0)
		e:SetAngles(self.Real.Ang)
		e:SetColor(self.ColorCode)
		e:SetEntity(self.Weapon)
		e:SetFlags(1)
		e:SetOrigin(self.Real.InitPos + self.Real.Ang:Forward() * nextlen)
		e:SetScale(0)
		e:SetStart(vector_origin)
		util.Effect("SplatoonSWEPsShooterInk", e)

		nextlen = nextlen + SplashInterval
		self.SplashCount = self.SplashCount + 1
	end
end

function EFFECT:HitEffect(tr) -- World hit effect here
	self.Hit = tr.Hit or not ss.IsInWorld(tr.HitPos)
	if not tr.HitWorld then return end
	local e = EffectData()
	e:SetAngles(tr.HitNormal:Angle())
	e:SetAttachment(6)
	e:SetColor(self.ColorCode)
	e:SetEntity(self.Weapon)
	e:SetFlags(1)
	e:SetOrigin(tr.HitPos - tr.HitNormal * self.Size)
	e:SetRadius(self.Size * 5)
	e:SetScale(.4)
	util.Effect("SplatoonSWEPsMuzzleSplash", e)
end
