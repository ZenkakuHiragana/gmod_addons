
local ss = SplatoonSWEPs
if not ss then return end

local DecreaseFrame = 4 * ss.FrameToSec
local TermTime = 10 * ss.FrameToSec -- Time to reach terminal velocity
local TrailLagTime = 20 * ss.FrameToSec
local Mat = Material "splatoonsweps/inkeffect"
local MatInvisible = "models/props_splatoon/weapons/primaries/shared/weapon_hider"
function EFFECT:Init(e)
	self.Weapon = e:GetEntity()
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	local f = e:GetFlags()
	local p = self.Weapon.Primary
	local StraightTime = p.Straight + DecreaseFrame / 2
	self.IsDrop = bit.band(f, 1) > 0
	self.InitTime = CurTime() - self.Weapon:Ping() * bit.band(f, 128) / 128
	self.TruePos, self.TrueAng, self.TrueVelocity = e:GetOrigin(), e:GetAngles(), e:GetStart()
	self.AppPos, self.AppAng = self.Weapon:GetMuzzlePosition()
	self.AppVelocity = (self.TruePos + self.TrueVelocity * StraightTime - self.AppPos) / StraightTime
	if self.IsDrop then
		self.AppPos, self.AppAng, self.AppVelocity = self.TruePos, self.TrueAng, vector_origin
	end
	
	self.TrailPos, self.TrailAng = self.AppPos, self.AppAng
	self.TrailVelocity = self.AppVelocity
	self.TrailInitTime = self.InitTime + ss.ShooterTrailDelay
	self.Speed = self.TrueVelocity:Length()
	self.SplashCount = 0
	self.SplashInit = e:GetAttachment() * p.SplashInterval / p.SplashPatterns
	self.SplashNum = e:GetScale()
	self.ColorCode = e:GetColor()
	self.Color = ss.GetColor(self.ColorCode)
	self.Hit = false
	self.Size = ss.mColRadius * (self.IsDrop and .5 or 1)
	self.IsCarriedByLocalPlayer = self.Weapon:IsCarriedByLocalPlayer()
	self:SetModel "models/props_junk/PopCan01a.mdl"
	self:SetAngles(self.TrueAng)
	self:SetMaterial(MatInvisible)
	self:SetPos(self.TruePos)
	self:SetRenderOrigin(self.TruePos)
end

function EFFECT:Simulate(initpos, initang, initvel, lt, outpos, outang, outstart)
	local g = physenv.GetGravity() * 15
	local Straight = self.IsDrop and 0 or self.Weapon.Primary.Straight
	if not self.IsDrop and lt < Straight then
		outpos:Set(initpos + initvel * lt)
		outstart:Set(initpos + initvel * math.max(lt - ss.FrameToSec, 0))
		outang:Set(initvel:Angle())
	else
		local RestTime = lt - Straight -- 0 <= t <= DecreaseFrame
		local f = math.Clamp(RestTime / (DecreaseFrame + TermTime), 0, 1)
		outang:Set(LerpAngle(f, initvel:Angle(), g:Angle()))
		outang:Set(LerpAngle(0, initvel:Angle(), g:Angle()))
		if self.IsDrop or lt > Straight + DecreaseFrame then
			local StraightTime = Straight + DecreaseFrame / 2
			local FallTime = math.max(lt - Straight - DecreaseFrame, 0)
			local StraightPos = initpos + initvel * StraightTime
			
			if FallTime > TermTime then
				local v = g * TermTime -- Terminal velocity
				outpos:Set(StraightPos - v * TermTime / 2 + v * FallTime)
				FallTime = math.max(FallTime - ss.FrameToSec, 0)
				outstart:Set(StraightPos - v * TermTime / 2 + v * FallTime)
			else
				outpos:Set(StraightPos + g * FallTime^2 / 2)
				FallTime = math.max(FallTime - ss.FrameToSec, 0)
				outstart:Set(StraightPos + g * FallTime * FallTime / 2)
			end
		else
			local Time = Straight + RestTime / 2
			outpos:Set(initpos + initvel * Time)
			outang:Set(LerpAngle(RestTime / (DecreaseFrame + TermTime), initvel:Angle(), g:Angle()))
			RestTime = RestTime - ss.FrameToSec
			outstart:Set(initpos + initvel * (Straight + RestTime / (RestTime > 0 and 2 or 1)))
		end
	end
end

function EFFECT:HitEffect(tr)
	self.Hit = tr.Hit or math.abs(tr.HitPos.x) > 16384
	or math.abs(tr.HitPos.y) > 16384 or math.abs(tr.HitPos.z) > 16384
	if tr.HitWorld then -- World hit effect here
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
		if self.IsDrop then return end
		sound.Play("SplatoonSWEPs_Ink.HitWorld", tr.HitPos)
	elseif not self.IsDrop and self.IsCarriedByLocalPlayer
	and IsValid(tr.Entity) and tr.Entity:Health() > 0 then
		local ent = ss.IsValidInkling(tr.Entity) -- Entity hit effect here
		if not (ent and ss.IsAlly(ent, self.ColorCode)) then
			surface.PlaySound(self.IsCritical and ss.DealDamageCritical or ss.DealDamage)
		end
	end
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

function EFFECT:Render()
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	if not istable(self.Color) then return end
	if not isnumber(self.Color.r) then return end
	if not isnumber(self.Color.g) then return end
	if not isnumber(self.Color.b) then return end
	if not isnumber(self.ColorCode) then return end
	if not isangle(self.TrueAng) then return end
	if not isvector(self.TruePos) then return end
	if not isangle(self.AppAng) then return end
	if not isvector(self.AppPos) then return end
	if not isangle(self.TrailAng) then return end
	if not isvector(self.TrailPos) then return end
	if not isvector(self.TrueVelocity) then return end
	if not isvector(self.AppVelocity) then return end
	if not isvector(self.TrailVelocity) then return end
	if not isnumber(self.InitTime) then return end
	if not isnumber(self.SplashInit) then return end
	if not isnumber(self.SplashNum) then return end
	local w, Straight = self.Weapon, self.Weapon.Primary.Straight
	local LifeTime = math.max(CurTime() - self.InitTime, 0)
	local TrailTime = math.max(CurTime() - self.TrailInitTime, 0)
	local TruePos, TrueStart, AppPos, TrailPos = Vector(), Vector(), Vector(), Vector()
	local TrueAng, AppAng, TrailAng = Angle(), Angle(), Angle()
	
	if not self.IsDrop and CurTime() < self.TrailInitTime then
		local aim = ss.ProtectedCall(w.Owner.GetAimVector, w.Owner) or w.Owner:GetForward()
		self.TrailPos, self.TrailAng = w:GetMuzzlePosition()
		self.TrailVelocity = aim * self.Speed
	end
	
	for to, from in pairs {
		[{TruePos, TrueAng, TrueStart}] = {self.TruePos, self.TrueAng, self.TrueVelocity, LifeTime},
		[{AppPos, AppAng, Vector()}] = {self.AppPos, self.AppAng, self.AppVelocity, LifeTime},
		[{TrailPos, TrailAng, Vector()}] = {self.TrailPos, self.TrailAng, self.TrailVelocity, TrailTime},
	} do
		self:Simulate(from[1], from[2], from[3], from[4], to[1], to[2], to[3])
	end
	
	local size = self.Size * .75
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
	self:SetPos(tr.HitPos)
	self:SetRenderOrigin(tr.HitPos)
	self:SetAngles(TrueAng)
	self:SetColor(self.Color)
	self:DrawModel()
	
	if not self.IsDrop and self.SplashCount <= self.SplashNum then -- Creates an ink drop
		local len = (tr.HitPos - self.TruePos):Length2D()
		local nextlen = self.SplashCount * w.Primary.SplashInterval + self.SplashInit
		local e = EffectData()
		while len >= nextlen do -- Create drops
			e:SetAttachment(0)
			e:SetAngles(self.TrueAng)
			e:SetColor(self.ColorCode)
			e:SetEntity(w)
			e:SetFlags(1)
			e:SetOrigin(self.TruePos + self.TrueAng:Forward() * nextlen)
			e:SetScale(0)
			e:SetStart(vector_origin)
			util.Effect("SplatoonSWEPsShooterInk", e)
			
			len = len - w.Primary.SplashInterval
			nextlen = nextlen + w.Primary.SplashInterval
			self.SplashCount = self.SplashCount + 1
		end
	end
	
	TrailPos = LerpVector(math.Clamp((TrailTime - Straight) / TrailLagTime, 0, 1), TrailPos, AppPos)
	local fore = AppPos + AppAng:Forward() * self.Size
	local foreup = AppPos + AppAng:Up() * self.Size
	local foreleft, foreright = Angle(AppAng), Angle(AppAng)
	local back = TrailPos - TrailAng:Forward() * size
	local backdown = TrailPos - TrailAng:Up() * size
	local backleft, backright = Angle(TrailAng), Angle(TrailAng)
	foreleft:RotateAroundAxis(AppAng:Forward(), 120)
	foreright:RotateAroundAxis(AppAng:Forward(), -120)
	backleft:RotateAroundAxis(TrailAng:Forward(), -120)
	backright:RotateAroundAxis(TrailAng:Forward(), 120)
	foreleft, foreright = AppPos + foreleft:Up() * self.Size, AppPos + foreright:Up() * self.Size
	backleft, backright = TrailPos - backleft:Up() * size, TrailPos - backright:Up() * size
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
	and isangle(self.TrueAng)
	and isvector(self.TruePos)
	and isangle(self.AppAng)
	and isvector(self.AppPos)
	and isangle(self.TrailAng)
	and isvector(self.TrailPos)
	and isvector(self.TrueVelocity)
	and isvector(self.AppVelocity)
	and isvector(self.TrailVelocity)
	and isnumber(self.InitTime)
	and isnumber(self.SplashInit)
	and isnumber(self.SplashNum)
	and not self.Hit
	and CurTime() < self.InitTime + self.Weapon.Primary.Straight + 20
	if not valid then return false end
	
	local TrueAng, t = Angle(), {
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		filter = owner,
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * ss.mColRadius,
		mins = -ss.vector_one * ss.mColRadius,
		start = Vector(),
		endpos = Vector(),
	}
	
	self:Simulate(self.TruePos, self.TrueAng, self.TrueVelocity,
	math.max(CurTime() - self.InitTime, 0), t.endpos, TrueAng, t.start)
	local tr = util.TraceHull(t)
	self:HitEffect(tr)
	self:SetPos(tr.HitPos)
	self:SetRenderOrigin(tr.HitPos)
	self:SetAngles(TrueAng)
	self:SetColor(self.Color)
	return true
end
