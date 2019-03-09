
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
	local pos, ang = self.Weapon:GetMuzzlePosition()
	local cc = e:GetColor()
	local c = ss.GetColor(cc)
	self.Charge = e:GetMagnitude()
	self.Color = c
	self.ColorCode = cc
	self.ColorTable = {c.r, c.g, c.b, 255}
	self.ColorVector = c:ToVector()
	self.Damage = self.Weapon:GetLerp(self.Charge, p.MinDamage, p.MaxDamage, p.Damage)
	self.Hit = false
	self.IsCharger = true
	self.IsDrop = isdrop
	self.IsCarriedByLocalPlayer = self.Weapon:IsCarriedByLocalPlayer()
	self.IsCritical = self.Damage >= 100
	self.Range = e:GetScale()
	self.Render = ss.Simulate.EFFECT_ShooterRender
	self.Simulate = ss.Simulate.Charger
	self.Size = ss.mColRadius
	self.Speed = e:GetStart():Length()
	self.SplashCount = 0
	self.SplashInterval = Lerp(self.Charge, p.MinSplashInterval, p.MaxSplashInterval)
	self.SplashRadius = Lerp(self.Charge, p.MinSplashRadius, p.MaxSplashRadius)
	self.SplashRatio = Lerp(self.Charge, p.MinSplashRatio, p.MaxSplashRatio)
	self.SplashInit = self.SplashInterval / p.SplashPatterns * e:GetAttachment() + self.SplashRadius * self.SplashRatio
	self.SplashInterval = self.SplashInterval * self.SplashRadius * self.SplashRatio * .9
	self.Straight = self.Range / self.Speed
	self.Think = ss.Simulate.EFFECT_ShooterThink
	self.Real = {
		Ang = e:GetAngles(),
		InitTime = CurTime() - ping - e:GetRadius(),
		InitPos = e:GetOrigin(),
		Pos = e:GetOrigin(),
		Velocity = e:GetStart(),
	}
	self.Apparent = {
		Ang = ang,
		InitTime = self.Real.InitTime,
		InitPos = Vector(pos),
		Pos = pos,
		Velocity = (self.Real.Pos + self.Real.Ang:Forward() * self.Range - pos):GetNormalized() * self.Speed
	}
	self.Tail = {
		Ang = self.Apparent.Ang,
		InitTime = self.Real.InitTime + ss.ShooterTrailDelay,
		InitPos = self.Apparent.InitPos,
		Pos = Vector(self.Apparent.Pos),
		Velocity = Vector(self.Apparent.Velocity),
	}

	if isdrop then
		self.Apparent.InitPos = Vector(self.Real.Pos)
		self.Apparent.Pos = Vector(self.Real.Pos)
		self.Apparent.Ang = Angle(self.Real.Ang)
		self.Apparent.Velocity = vector_origin
		self.Tail.InitPos = self.Apparent.Pos - self.Real.Ang:Forward() * self.SplashInterval
		self.Tail.Pos = Vector(self.Tail.InitPos)
		self.Tail.Ang = self.Apparent.Ang
		self.Tail.Velocity = vector_origin
	end

	self.Table = {self.Real, self.Apparent, self.Tail}
	for _, t in ipairs(self.Table) do
		t.endpos = t.Pos
		t.InitDirection = t.Velocity:GetNormalized()
		t.IsDrop = self.IsDrop
		t.Range = self.Range
		t.Speed = self.Speed
		t.Straight = self.Straight
		t.StraightPos = t.InitPos + t.InitDirection * t.Range
		t.start = Vector()
		t.Time = 0
	end

	self:SetModel "models/props_junk/PopCan01a.mdl"
	self:SetAngles(self.Apparent.Ang)
	self:SetMaterial(ss.Materials.Effects.Invisible)
	self:SetPos(self.Apparent.Pos)
end

function EFFECT:CreateDrops(tr)
	if self.IsDrop then return end
	local e = EffectData()
	local Length = tr.HitPos:Distance(self.Real.InitPos)
	local NextLength = self.SplashCount * self.SplashInterval + self.SplashInit
	while Length < self.Range and Length >= NextLength do -- Create ink drops
		e:SetAttachment(0)
		e:SetAngles(self.Real.Ang)
		e:SetColor(self.ColorCode)
		e:SetEntity(self.Weapon)
		e:SetFlags(1)
		e:SetOrigin(self.Real.InitPos + self.Real.Ang:Forward() * NextLength)
		e:SetScale(0)
		e:SetStart(self.Real.Velocity)
		e:SetRadius(self.SplashInterval / self.Speed)
		e:SetMagnitude(self.Charge)
		util.Effect("SplatoonSWEPsChargerInk", e)

		NextLength = NextLength + self.SplashInterval
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
