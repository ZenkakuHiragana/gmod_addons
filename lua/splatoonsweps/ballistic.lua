
local ss = SplatoonSWEPs
if not ss then return end

ss.Simulate = {}

local TrailLagTime = 20 * ss.FrameToSec
local InflateTime = 4 * ss.FrameToSec
local Mat = ss.Materials.Effects.Ink
local function AdvanceVertex(color, pos, normal, u, v, alpha)
	mesh.Color(unpack(color))
	mesh.Normal(normal)
	mesh.Position(pos)
	mesh.TexCoord(0, u, v)
	mesh.AdvanceVertex()
end

local function DrawMesh(MeshTable, color)
	mesh.Begin(MATERIAL_TRIANGLES, 12)
	for _, tri in pairs(MeshTable) do
		local n = (tri[3] - tri[1]):Cross(tri[2] - tri[1]):GetNormalized()
		AdvanceVertex(color, tri[1], n, .5, 0)
		AdvanceVertex(color, tri[2], n, 0, 1)
		AdvanceVertex(color, tri[3], n, 1, 1)
	end
	mesh.End()
end

function ss.Simulate.EFFECT_ShooterRender(self)
	if not IsValid(self.Weapon) then return end
	if not IsValid(self.Weapon.Owner) then return end
	if not isnumber(self.ColorCode) then return end
	local LifeTime = math.max(CurTime() - self.Real.InitTime, 0)
	local sizeinflate = self.IsDrop and 1 or math.Clamp(LifeTime / InflateTime, 0, 1)
	local sizef = self.Size * sizeinflate
	local sizeb = sizef * .75
	local AppPos, AppAng = self:GetPos(), self:GetAngles()
    local TailPos, TailAng = self.Tail.Pos, self.Tail.Ang
    AppAng = LerpAngle(0.4, AppAng, (AppPos - TailPos):Angle())
    TailAng = LerpAngle(0.4, TailAng, (AppPos - TailPos):Angle())
	local fore = AppPos + AppAng:Forward() * sizef
	local back = TailPos - TailAng:Forward() * sizeb
	local foreup, foreleft, foreright = Angle(AppAng), Angle(AppAng), Angle(AppAng)
	local backdown, backleft, backright = Angle(TailAng), Angle(TailAng), Angle(TailAng)
	local deg = CurTime() * self.Speed / 10
	foreup:RotateAroundAxis(AppAng:Forward(), deg)
	foreleft:RotateAroundAxis(AppAng:Forward(), deg + 120)
	foreright:RotateAroundAxis(AppAng:Forward(), deg - 120)
	backdown:RotateAroundAxis(TailAng:Forward(), deg)
	backleft:RotateAroundAxis(TailAng:Forward(), deg - 120)
	backright:RotateAroundAxis(TailAng:Forward(), deg + 120)
	foreup = AppPos + foreup:Up() * sizef
	foreleft = AppPos + foreleft:Up() * sizef
	foreright = AppPos + foreright:Up() * sizef
	backdown = TailPos - backdown:Up() * sizeb
	backleft = TailPos - backleft:Up() * sizeb
	backright = TailPos - backright:Up() * sizeb
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
	Mat:SetVector("$color", self.Weapon:GetInkColorProxy())
	DrawMesh(MeshTable, self.ColorTable)
	if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then
		Mat:SetVector("$color", ss.vector_one)
		return
	end

	render.PushFlashlightMode(true) -- Ink lit by player's flashlight or a projected texture
	DrawMesh(MeshTable, self.ColorTable)
	render.PopFlashlightMode()
	Mat:SetVector("$color", ss.vector_one)
end

-- Called when the effect should think, return false to kill the effect.
function ss.Simulate.EFFECT_ShooterThink(self)
	local valid = IsValid(self.Weapon)
	and IsValid(self.Weapon.Owner)
	and isnumber(self.ColorCode)
	and not self.Hit
	and ss.IsInWorld(self.Real.Pos)
	if not valid then return end
	if not (self.IsDrop or self.IsCharger) and CurTime() < self.Tail.InitTime then
		local pos, ang = self.Weapon:GetMuzzlePosition()
		self.Tail.Pos:Set(pos)
		self.Tail.Ang:Set(ang)
		self.Tail.Velocity:Set(self.Weapon:GetAimVector() * self.Speed)
	end

	for _, t in ipairs(self.Table) do self.Simulate(t) end
	local tr = util.TraceHull {
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		filter = {self.Weapon, self.Weapon.Owner},
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * ss.mColRadius,
		mins = -ss.vector_one * ss.mColRadius,
		start = self.Real.start,
		endpos = self.Real.endpos,
    }

	self:HitEffect(tr)
	self:SetPos(self.Apparent.Pos)
	self:SetAngles(self.Apparent.Ang)
	self:DrawModel()
	self:CreateDrops(tr)
	self.Apparent.Ang:Set(LerpAngle(math.Clamp((self.Apparent.Time - self.Straight) /
	(ss.ShooterDecreaseFrame + ss.ShooterTermTime) / 2, 0, 1), self.Apparent.Velocity:Angle(), physenv.GetGravity():Angle()))

	if self.IsCharger then return true end
	self.Tail.Pos:Set(LerpVector(math.Clamp((self.Tail.Time - self.Straight) / TrailLagTime, 0, 0.825), self.Tail.Pos, self.Apparent.Pos))
	return true
end

-- table ink | A table containing these fields:
--   Vector endpos   | Former position
--   number InitTime | A creation time related to CurTime()
--   Vector InitPos  | Initial position
--   bool   IsDrop   | Is the ink a drop or not
--   Vector start    | Latter position
--   number Straight | Duration of going straight
--   number Time     | The living time
--   Vector Velocity | Initial velocity
function ss.Simulate.Shooter(ink)
	local g = physenv.GetGravity() * ss.InkGravityMul
	local LifeTime = math.max(0, CurTime() - ink.InitTime)
	if ink.Time > LifeTime then return end

	local Straight = ink.IsDrop and 0 or ink.Straight
	local MaxFrame = Straight + ss.ShooterDecreaseFrame
	local MaxPos = ink.InitPos + ink.Velocity * (MaxFrame - ss.ShooterDecreaseFrame / 2)
	for Pos, Time in pairs {[ink.endpos] = LifeTime, [ink.start] = ink.Time} do
        if not ink.IsDrop and Time < Straight then -- Goes Straight
			Pos:Set(ink.InitPos + ink.Velocity * math.Clamp(Time, 0, Straight))
		elseif Time > Straight + ss.ShooterDecreaseFrame then -- Falls Straight
			local FallTime = math.max(Time - Straight - ss.ShooterDecreaseFrame, 0)
			if FallTime > ss.ShooterTermTime then
				local v = g * ss.ShooterTermTime
				Pos:Set(MaxPos - v * ss.ShooterTermTime / 2 + v * FallTime)
			else
				Pos:Set(MaxPos + g * FallTime * FallTime / 2)
			end
		else
			Pos:Set(ink.InitPos + ink.Velocity * (Straight + Time) / 2)
        end
    end

    if ink.Time < MaxFrame and MaxFrame < LifeTime then
        ink.endpos:Set(MaxPos)
        ink.Time = MaxFrame
        return
    end

    ink.Time = LifeTime
end

-- table ink | A table containing these fields:
--   Vector endpos        | Former position
--   Vector InitDirection | Initial movement direction
--   number InitTime      | A creation time related to CurTime()
--   number Range         | Maximum distance that can be reached
--   number Speed         | Speed of the ink
--   number Straight      | Duration of going straight
--   Vector StraightPos   | A position to start falling ink
--   Vector start         | Latter position
--   number Time          | The living time
function ss.Simulate.Charger(ink)
	local g = physenv.GetGravity() * ss.InkGravityMul
	local dir = ink.InitDirection
	local LifeTime = math.max(0, CurTime() - ink.InitTime)
	if ink.Time > LifeTime then return end

	local Length = math.Clamp(ink.Speed * LifeTime, 0, ink.Range)
	for Pos, Time in pairs {[ink.endpos] = LifeTime, [ink.start] = ink.Time} do
		if Time <= ink.Straight then -- Goes Straight
			Pos:Set(ink.InitPos + dir * math.Clamp(ink.Speed * Time, 0, ink.Range))
		else -- Falls Straight
			local FallTime = math.max(Time - ink.Straight, 0)
			if FallTime > ss.ShooterTermTime then
				local v = g * ss.ShooterTermTime
				Pos:Set(ink.StraightPos - v * ss.ShooterTermTime / 2 + v * FallTime)
			else
				Pos:Set(ink.StraightPos + g * FallTime * FallTime / 2)
			end
		end
    end

    ink.Time = LifeTime
end
