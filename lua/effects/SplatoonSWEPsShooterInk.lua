
local ss = SplatoonSWEPs
if not ss then return end

local TrailLagTime = 20 * ss.FrameToSec
local InflateTime = 4 * ss.FrameToSec
local Mat = Material "splatoonsweps/inkeffect"
local MatInvisible = "models/props_splatoon/weapons/primaries/shared/weapon_hider"
function EFFECT:Init(e)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	local f = e:GetFlags()
	local p = self.Weapon.Primary
	self.IsDrop = bit.band(f, 1) > 0
	self.IsShooter = self.Weapon.Base == "weapon_shooter"
	self.InitTime = CurTime() - self.Weapon:Ping() * bit.band(f, 128) / 128
	self.TrailInitTime = self.InitTime + ss.ShooterTrailDelay
	self.TruePos, self.TrueAng, self.TrueVelocity = e:GetOrigin(), e:GetAngles(), e:GetStart()
	self.AppPos, self.AppAng = self.Weapon:GetMuzzlePosition()
	self.Speed = self.TrueVelocity:Length()
	if self.IsShooter then
		local StraightTime = self.IsDrop and 0 or p.Straight + ss.ShooterDecreaseFrame / 2
		self.AppVelocity = (self.TruePos + self.TrueVelocity * StraightTime - self.AppPos) / StraightTime
		self.SplashInit = e:GetAttachment() * p.SplashInterval / p.SplashPatterns
		self.SplashNum = e:GetScale()
		if self.IsDrop then
			self.AppPos, self.AppAng, self.AppVelocity = self.TruePos, self.TrueAng, vector_origin
		end
		
		self.TrailPos = self.AppPos
	else
		self.Charge = e:GetMagnitude()
		self.Damage = self.Weapon:GetLerp(self.Charge, p.MinDamage, p.MaxDamage, p.Damage)
		self.IsCritical = self.Damage >= 100
		self.Range = e:GetScale()
		self.AppVelocity = (self.TruePos + self.TrueAng:Forward() * self.Range - self.AppPos):GetNormalized() * self.Speed
		self.SplashInterval = Lerp(self.Charge, p.MinSplashInterval, p.MaxSplashInterval)
		self.SplashRadius = Lerp(self.Charge, p.MinSplashRadius, p.MaxSplashRadius)
		self.SplashRatio = Lerp(self.Charge, p.MinSplashRatio, p.MaxSplashRatio)
		self.SplashInit = self.SplashInterval / p.SplashPatterns * e:GetAttachment() + self.SplashRadius * self.SplashRatio
		self.SplashInterval = self.SplashInterval * self.SplashRadius * self.SplashRatio * .9
		self.Straight = self.Range / self.Speed
		self.InitTime = self.InitTime - e:GetRadius()
		self.TrailPos = self.AppPos
		if self.IsDrop then
			self.AppPos, self.AppAng, self.AppVelocity = self.TruePos, self.TrueAng, vector_origin
			self.TrailPos = self.AppPos - self.TrueAng:Forward() * self.SplashInterval
			self.TrailInitTime = self.InitTime
		end
	end
	
	self.TrailAng = self.AppAng
	self.TrailVelocity = self.AppVelocity
	self.NowTrailPos, self.NowTrailAng = self.TrailPos, self.TrailAng
	self.PrevTime, self.TrailPrevTime = 0, 0
	self.SplashCount = 0
	self.ColorCode = e:GetColor()
	self.Color = ss.GetColor(self.ColorCode)
	self.Hit = false
	self.Size = ss.mColRadius * (self.IsDrop and .5 or 1)
	self.IsCarriedByLocalPlayer = self.Weapon:IsCarriedByLocalPlayer()
	self:SetModel "models/props_junk/PopCan01a.mdl"
	self:SetAngles(self.AppAng)
	self:SetMaterial(MatInvisible)
	self:SetPos(self.AppPos)
end

function EFFECT:Simulate(initpos, initang, initvel, lt, prevlt, outpos, outang, outstart)
	outang:Set(initang)
	
	local g = physenv.GetGravity() * ss.InkGravityMul
	local Straight = self.IsDrop and 0 or self.Weapon.Primary.Straight
	local MaxFrame = Straight + ss.ShooterDecreaseFrame
	local MaxPos = initpos + initvel * (MaxFrame - ss.ShooterDecreaseFrame / 2)
	for Pos, Time in pairs {[outpos] = lt, [outstart] = prevlt} do
		if not self.IsDrop and Time < Straight then -- Goes Straight
			Pos:Set(initpos + initvel * math.Clamp(Time, 0, Straight))
		elseif Time > Straight + ss.ShooterDecreaseFrame then -- Falls Straight
			local FallTime = math.max(Time - Straight - ss.ShooterDecreaseFrame, 0)
			if FallTime > ss.ShooterTermTime then
				local v = g * ss.ShooterTermTime
				Pos:Set(MaxPos - v * ss.ShooterTermTime / 2 + v * FallTime)
			else
				Pos:Set(MaxPos + g * FallTime * FallTime / 2)
			end
		else
			Pos:Set(initpos + initvel * (Straight + Time) / 2)
			if Time ~= lt then continue end
			local f = math.Clamp((Time - Straight) / (ss.ShooterDecreaseFrame + ss.ShooterTermTime) / 2, 0, 1)
			outang:Set(LerpAngle(f, initvel:Angle(), g:Angle()))
		end
	end
	
	if prevlt < MaxFrame and MaxFrame < lt then
		outpos:Set(MaxPos)
		self.PrevTime = MaxFrame + ss.FrameToSec
	end
end

function EFFECT:SimulateCharger(initpos, initang, initvel, lt, prevlt, outpos, outang, outstart)
	outang:Set(initang)
	
	local g = physenv.GetGravity() * ss.InkGravityMul
	local Length = math.Clamp(self.Speed * lt, 0, self.Range)
	local dir = initvel:GetNormalized()
	local StraightPos = initpos + dir * self.Range
	for Pos, Time in pairs {[outpos] = lt, [outstart] = prevlt} do
		if Time <= self.Straight then -- Goes Straight
			Pos:Set(initpos + dir * math.Clamp(self.Speed * Time, 0, self.Range))
		else -- Falls Straight
			local FallTime = math.max(Time - self.Straight, 0)
			if FallTime > ss.ShooterTermTime then
				local v = g * ss.ShooterTermTime
				Pos:Set(StraightPos - v * ss.ShooterTermTime / 2 + v * FallTime)
			else
				Pos:Set(StraightPos + g * FallTime * FallTime / 2)
			end
		end
	end
end

function EFFECT:CreateDrops(tr) -- Creates ink drops
	if self.IsDrop or self.SplashCount > self.SplashNum then return end
	local SplashInterval = self.Weapon.Primary.SplashInterval
	local len = (tr.HitPos - self.TruePos):Length2D()
	local nextlen = self.SplashCount * SplashInterval + self.SplashInit
	local e = EffectData()
	while len >= nextlen do -- Create drops
		e:SetAttachment(0)
		e:SetAngles(self.TrueAng)
		e:SetColor(self.ColorCode)
		e:SetEntity(self.Weapon)
		e:SetFlags(1)
		e:SetOrigin(self.TruePos + self.TrueAng:Forward() * nextlen)
		e:SetScale(0)
		e:SetStart(vector_origin)
		util.Effect("SplatoonSWEPsShooterInk", e)
		
		nextlen = nextlen + SplashInterval
		self.SplashCount = self.SplashCount + 1
	end
end

function EFFECT:CreateChargerDrops(tr)
	if self.IsDrop then return end
	local e = EffectData()
	local Length = tr.HitPos:Distance(self.TruePos)
	local NextLength = self.SplashCount * self.SplashInterval + self.SplashInit
	while Length < self.Range and Length >= NextLength do -- Create ink drops
		e:SetAttachment(0)
		e:SetAngles(self.TrueAng)
		e:SetColor(self.ColorCode)
		e:SetEntity(self.Weapon)
		e:SetFlags(1)
		e:SetOrigin(self.TruePos + self.TrueAng:Forward() * NextLength)
		e:SetScale(0)
		e:SetStart(self.TrueVelocity)
		e:SetRadius(self.SplashInterval / self.Speed)
		e:SetMagnitude(self.Charge)
		util.Effect("SplatoonSWEPsShooterInk", e)
		
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

function EFFECT:AdvanceVertex(pos, normal, u, v, alpha)
	mesh.Color(self.Color.r, self.Color.g, self.Color.b, alpha or 255)
	mesh.Normal(normal)
	mesh.Position(pos)
	mesh.TexCoord(0, u, v)
	mesh.AdvanceVertex()
end

function EFFECT:DrawMesh(MeshTable)
	mesh.Begin(MATERIAL_TRIANGLES, 12)
	for _, tri in pairs(MeshTable) do
		local n = (tri[3] - tri[1]):Cross(tri[2] - tri[1]):GetNormalized()
		self:AdvanceVertex(tri[1], n, .5, 0)
		self:AdvanceVertex(tri[2], n, 0, 1)
		self:AdvanceVertex(tri[3], n, 1, 1)
	end
	mesh.End()
end

function EFFECT:Render(NoDraw)
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	if not istable(self.Color) then return end
	if not isnumber(self.Color.r) then return end
	if not isnumber(self.Color.g) then return end
	if not isnumber(self.Color.b) then return end
	if not isnumber(self.ColorCode) then return end
	local w = self.Weapon
	local LifeTime = math.max(CurTime() - self.InitTime, 0)
	local sizeinflate = self.IsDrop and 1 or math.Clamp(LifeTime / InflateTime, 0, 1)
	local sizef = self.Size * sizeinflate
	local size = sizef * .75
	local AppPos, AppAng = self:GetPos(), self:GetAngles()
	local TrailPos, TrailAng = self.NowTrailPos, self.NowTrailAng
	local fore = AppPos + AppAng:Forward() * sizef
	local back = TrailPos - TrailAng:Forward() * size
	local foreup, foreleft, foreright = Angle(AppAng), Angle(AppAng), Angle(AppAng)
	local backdown, backleft, backright = Angle(TrailAng), Angle(TrailAng), Angle(TrailAng)
	local deg = CurTime() * self.Speed
	foreup:RotateAroundAxis(AppAng:Forward(), deg)
	foreleft:RotateAroundAxis(AppAng:Forward(), deg + 120)
	foreright:RotateAroundAxis(AppAng:Forward(), deg - 120)
	backdown:RotateAroundAxis(TrailAng:Forward(), deg)
	backleft:RotateAroundAxis(TrailAng:Forward(), deg - 120)
	backright:RotateAroundAxis(TrailAng:Forward(), deg + 120)
	foreup = AppPos + foreup:Up() * sizef
	foreleft = AppPos + foreleft:Up() * sizef
	foreright = AppPos + foreright:Up() * sizef
	backdown = TrailPos - backdown:Up() * size
	backleft = TrailPos - backleft:Up() * size
	backright = TrailPos - backright:Up() * size
	local MeshTable = {
		{fore, foreleft, foreup},
		{fore, foreup, foreright},
		{fore, foreright, foreleft},
		{foreup, backleft, backright},
		{backleft, foreup, foreleft},
		{foreleft, backdown, backleft},
		{backdown, foreleft, foreright},
		{foreright, backright, backdown},
		{backright, foreright, foreup},
		{back, backleft, backdown},
		{back, backdown, backright},
		{back, backright, backleft},
	}
	
	render.SetMaterial(Mat)
	Mat:SetVector("$color", w:GetInkColorProxy())
	self:DrawMesh(MeshTable)
	Mat:SetVector("$color", ss.vector_one)
	
	if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then return end
	render.PushFlashlightMode(true) -- Ink lit by player's flashlight or a projected texture
	Mat:SetVector("$color", w:GetInkColorProxy())
	self:DrawMesh(MeshTable)
	Mat:SetVector("$color", ss.vector_one)
	render.PopFlashlightMode()
end

-- Called when the effect should think, return false to kill the effect.
function EFFECT:Think()
	local valid = IsValid(self.Weapon)
	and IsValid(self.Weapon.Owner)
	and istable(self.Color)
	and isnumber(self.Color.r)
	and isnumber(self.Color.g)
	and isnumber(self.Color.b)
	and isnumber(self.ColorCode)
	and not self.Hit
	and ss.IsInWorld(self.TruePos)
	if not valid then return end
	
	local w, Straight = self.Weapon, self.Weapon.Primary.Straight or 0
	local LifeTime = math.max(CurTime() - self.InitTime, 0)
	local TrailTime = math.max(CurTime() - self.TrailInitTime, 0)
	local TruePos, TrueStart, AppPos, TrailPos = Vector(), Vector(), Vector(), Vector()
	local TrueAng, AppAng, TrailAng = Angle(), Angle(), Angle()
	
	if not self.IsDrop and self.IsShooter and CurTime() < self.TrailInitTime then
		local aim = ss.ProtectedCall(w.Owner.GetAimVector, w.Owner) or w.Owner:GetForward()
		self.TrailPos, self.TrailAng = w:GetMuzzlePosition()
		self.TrailVelocity = aim * self.Speed
	end
	
	for to, from in pairs {
		[{TruePos, TrueAng, TrueStart}] = {self.TruePos, self.TrueAng, self.TrueVelocity, LifeTime, self.PrevTime},
		[{AppPos, AppAng, Vector()}] = {self.AppPos, self.AppAng, self.AppVelocity, LifeTime, self.PrevTime},
		[{TrailPos, TrailAng, Vector()}] = {self.TrailPos, self.TrailAng, self.TrailVelocity, TrailTime, self.TrailPrevTime},
	} do
		if self.IsShooter then
			self:Simulate(unpack(table.Add(from, to)))
		else
			self:SimulateCharger(unpack(table.Add(from, to)))
		end
	end
	
	self.PrevTime = LifeTime
	self.TrailPrevTime = TrailTime
	self.NowTrailPos = TrailPos
	self.NowTrailAng = TrailAng
	
	local tr = util.TraceHull {
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		filter = {w, w.Owner},
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * ss.mColRadius,
		mins = -ss.vector_one * ss.mColRadius,
		start = TrueStart,
		endpos = TruePos,
	}
	
	self:HitEffect(tr)
	self:SetPos(AppPos)
	self:SetAngles(AppAng)
	self:SetColor(self.Color)
	self:DrawModel()
	
	if self.IsShooter then
		self:CreateDrops(tr)
		TrailPos = LerpVector(math.Clamp((TrailTime - Straight) / TrailLagTime, 0, 1), TrailPos, AppPos)
	else
		self:CreateChargerDrops(tr)
	end
	
	return true
end
