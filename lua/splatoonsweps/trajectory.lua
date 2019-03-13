
local ss = SplatoonSWEPs
if not ss then return end

ss.Simulate = {}
local TrailLagTime = 20 * ss.FrameToSec
local InflateTime = 4 * ss.FrameToSec
local Mat = ss.Materials.Effects.Ink
local Simulate, HitPaint, HitEntity = {}, {}, {}
local MAX_INK_SIM_AT_ONCE = 60 -- Calculating ink trajectory at once
local SplashDistance = 50 * ss.ToHammerUnits -- Transition between drop and splash
local dropdata = {
	Damage = 0,
	MinDamage = 0,
	MinDamageTime = 0,
	DecreaseDamage = 0,
	InitTime = 0,
	InkRadius = 10,
	MinRadius = 10,
	ColRadius = ss.mColRadius,
	SplashRadius = 0,
	SplashPatterns = 1,
	SplashNum = 0,
	SplashInterval = 0,
	Straight = 0,
	InitVelocity = 0,
}

function ss.GetDropType() -- math.floor(1 <= x < 4) -> 1, 2, 3
	return util.SharedRandom("SplatoonSWEPs: Drop ink type", 1, 4, CurTime())
end

function ss.PlayHitSound(iscritical, owner)
	if ss.sp or CLIENT and IsFirstTimePredicted() then
		local ent = ss.IsValidInkling(e) -- Entity hit effect here
		if not (ent and ss.IsAlly(ent, ink.Color)) then
			if ss.mp then
				surface.PlaySound(iscritical and ss.DealDamageCritical or ss.DealDamage)
			elseif owner:IsPlayer() and SERVER then
				local s = "SplatoonSWEPs.DealDamage"
				if iscritical then s = "SplatoonSWEPs.DealDamageCritical" end
				owner:SendLua(string.format("surface.PlaySound(%s)", s))
			end
		end
	end
end

-- Physics simulation for ink trajectory.
-- The first some frames(1/60 sec.) ink flies without gravity.
-- After that, ink decelerates horizontally and is affected by gravity.
function Simulate.weapon_splatoonsweps_shooter(ink)
	ss.Simulate.Shooter(ink)
	if not IsFirstTimePredicted() then return end
	if ink.SplashCount < ink.SplashNum then -- Creates ink drops
		dropdata.InkRadius = ink.SplashRadius
		dropdata.MinRadius = ink.SplashRadius
		dropdata.InitTime = CurTime() - ss.ShooterDecreaseFrame
		local Length = (ink.endpos - ink.InitPos):Length2D()
		local NextLength = ink.SplashCount * ink.SplashInterval + ink.SplashInit
		local DropDir = Vector(ink.InitDirection.x, ink.InitDirection.y, 0):GetNormalized()
		while Length >= NextLength and ink.SplashCount < ink.SplashNum do
			local start = ink.InitPos + DropDir * NextLength
			start.z = Lerp(Length / NextLength, ink.InitPos.z, ink.endpos.z)
			ss.AddInk(ink.filter, start, ss.GetDropType(), {
				Angle = ink.Angle,
				ClassName = ink.ClassName,
				Color = ink.Color,
				SplashInit = ink.WeaponSplashInit,
			})

			if ink.IsBlaster then
				if ss.mp and SERVER and IsValid(ink.filter) and ink.filter:IsPlayer() then SuppressHostEvents(ink.filter) end
				local e = EffectData()
				e:SetColor(ink.Color)
				e:SetRadius((ink.ColRadiusMiddle + ink.ColRadiusClose) / 4)
				e:SetOrigin(start)
				util.Effect("SplatoonSWEPsBlasterTrail", e)
				if ss.mp and SERVER and IsValid(ink.filter) and ink.filter:IsPlayer() then SuppressHostEvents() end
			end

			if util.TraceLine {
				collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
				start = start,
				endpos = start + ink.InitDirection * ink.SplashInterval,
				filter = ink.filter,
				mask = ss.SquidSolidMask,
			} .Hit then
				break
			end

			NextLength = NextLength + ink.SplashInterval
			ink.SplashCount = ink.SplashCount + 1
		end
	end
end

function HitPaint.weapon_splatoonsweps_shooter(ink, t)
	local ratio = 1
	local radius = ink.InkRadius
	if not ink.IsDrop and ink.Base ~= "weapon_splatoonsweps_charger" and t.HitNormal.z > ss.MAX_COS_DEG_DIFF then
		local actual = (t.HitPos - ink.InitPos):Length2D()
		local min = SplashDistance + ink.PaintNearDistance
		if actual > min then
			local max = ss.mPaintFarDistance
			local stretch = (actual - min) / max + 0.5
			radius, ratio = radius * (stretch + 0.5), 0.5 / stretch
		else
			ink.InkType = ss.GetDropType()
		end
	else
		ink.InkType = ss.GetDropType()
		ratio = ink.Ratio or ratio
	end

	if (ss.sp or CLIENT and IsFirstTimePredicted()) and t.Hit and (not ink.IsDrop or ink.PlayHitSound) then
		sound.Play("SplatoonSWEPs_Ink.HitWorld", t.HitPos)
	end

	ss.Paint(t.HitPos, t.HitNormal, radius, ink.Color,
	ink.Angle, ink.InkType, ratio, ink.filter, ink.ClassName)
end

function HitEntity.weapon_splatoonsweps_shooter(ink, t, w)
	local d, e, o = DamageInfo(), t.Entity, ink.filter
	local frac = (math.max(0, CurTime() - ink.InitTime)
	- ink.DecreaseDamage) / ink.MinDamageTime
	if ink.IsCarriedByLocalPlayer then
		ss.PlayHitSound(ink.IsCritical, o)
		if ss.mp and CLIENT then return end
	end

	d:SetDamage(Lerp(1 - frac, ink.MinDamage, ink.Damage))
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(ink.Damage)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(IsValid(ink.Inflictor) and ink.Inflictor or game.GetWorld())
	d:ScaleDamage(ss.ToHammerHealth)
	ss.ProtectedCall(e.TakeDamageInfo, e, d)
end

function Simulate.weapon_splatoonsweps_charger(ink)
	ss.Simulate.Charger(ink)
	if not IsFirstTimePredicted() then return end
	dropdata.PlayHitSound = true
	dropdata.InitTime = CurTime() - ss.ShooterDecreaseFrame
	local Length = math.Clamp(ink.Speed * math.max(0, CurTime() - ink.InitTime), 0, ink.Range)
	local NextLength = ink.SplashCount * ink.SplashInterval + ink.SplashInit
	while Length >= NextLength do -- Create ink drops
		dropdata.InkRadius = ink.SplashRadius / ink.Ratio
		local droptable = {
			Angle = ink.Angle,
			ClassName = ink.ClassName,
			Color = ink.Color,
			SplashInit = ink.WeaponSplashInit,
		}
		local hull = {
			collisiongroup = ink.collisiongroup,
			endpos = ink.InitPos + ink.InitDirection * NextLength,
			filter = ink.filter,
			mask = ss.SquidSolidMask,
			maxs = ink.maxs,
			mins = ink.mins,
			start = ink.InitPos,
		}
		local t = util.TraceHull(hull)
		t = ss.AddInk(ink.filter, t.HitPos + t.HitNormal, ss.GetDropType(), droptable)
		t.Ratio = ink.Ratio

		hull.start, hull.endpos = hull.endpos, hull.endpos + ink.InitDirection * ink.SplashInterval
		if util.TraceHull(hull).Hit then break end

		NextLength = NextLength + ink.SplashInterval
		ink.SplashCount = ink.SplashCount + 1
		if NextLength >= ink.Range then
			dropdata.InkRadius = dropdata.InkRadius * ink.SplashRadiusMul
			t = nil
			t = ss.AddInk(ink.filter, ink.StraightPos, ss.GetDropType(), droptable)
			t.Ratio = ink.Ratio

			HitPaint.weapon_splatoonsweps_charger(ink, {
				FractionPaintWall = .8,
				HitPos = ink.InitPos + ink.InitDirection * ink.Range,
				HitNormal = -ink.InitDirection,
			})
		elseif ink.SplashCount == 1 and ink.Charge > ink.FootpaintCharge then
			dropdata.InkRadius = ink.FootpaintRadius
			ss.AddInk(ink.filter, ink.InitPos, ss.GetDropType(), droptable)
		end
	end

	dropdata.PlayHitSound = nil
end

local function HitSmoke(ink, t)
	if ink.ClassName:find "bamboozler" then return end
	if not t.HitWorld or CurTime() - ink.InitTime > ink.Straight then return end
	local e = EffectData()
	e:SetAttachment(0)
	e:SetColor(ink.Color)
	e:SetEntity(game.GetWorld())
	e:SetFlags(PATTACH_ABSORIGIN)
	e:SetOrigin(t.HitPos + t.HitNormal * 10)
	e:SetScale(6)
	e:SetStart(ink.InitPos)
	util.Effect("SplatoonSWEPsMuzzleMist", e, true,
	not ink.filter:IsPlayer() and SERVER and ss.mp or nil)
end

function HitPaint.weapon_splatoonsweps_charger(ink, t)
	local wallfrac = math.Remap(ink.Charge, 0, ink.WallPaintCharge, 0, 1)
	local radius = ink.SplashRadius / ink.SplashRadiusMul
	local SplashNum = math.Round(Lerp(wallfrac, ink.MinWallPaintNum, ink.MaxWallPaintNum))
	ink.InkRadius, ink.Ratio = ink.SplashRadius * ((1 + 1 / ink.Ratio) / 2), 1
	HitPaint.weapon_splatoonsweps_shooter(ink, t)
	HitSmoke(ink, t)
	if t.HitNormal.z > ss.MAX_COS_DEG_DIFF then return end
	for i = 1, SplashNum do
		local pos = t.HitPos - vector_up * i * radius * Lerp(wallfrac, 1, 1.25)
		local tr = util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			endpos = pos - t.HitNormal,
			filter = ink.filter,
			mask = ss.SquidSolidMask,
			start = ink.InitPos,
		}

		if math.abs(tr.HitNormal.z) > ss.MAX_COS_DEG_DIFF then continue end
		if (t.FractionPaintWall or 0) > tr.Fraction then continue end
		if tr.StartSolid or not tr.HitWorld then continue end
		ss.PaintSchedule[{
			pos = tr.HitPos,
			normal = tr.HitNormal,
			radius = radius,
			color = ink.Color,
			angle = ink.Angle,
			inktype = ss.GetDropType(),
			ratio = 1,
			Time = CurTime() + i * radius / ink.Speed,
			filter = ink.filter,
			ClassName = ink.ClassName,
		}] = true
	end
end

function HitEntity.weapon_splatoonsweps_charger(ink, t, w)
	local LifeTime = math.max(0, CurTime() - FrameTime() - ink.InitTime)
	local d, e, o = DamageInfo(), t.Entity, ink.filter

	HitSmoke(ink, t)
	if LifeTime > ink.Straight then return end
	if ink.IsCarriedByLocalPlayer then
		ss.PlayHitSound(ink.Damage >= 1, o)
		if ss.mp and CLIENT then return end
	end

	d:SetDamage(ink.Damage)
	d:SetDamageForce(-t.HitNormal)
	d:SetDamagePosition(t.HitPos)
	d:SetDamageType(DMG_GENERIC)
	d:SetMaxDamage(ink.Damage)
	d:SetReportedPosition(t.HitPos)
	d:SetAttacker(IsValid(o) and o or game.GetWorld())
	d:SetInflictor(IsValid(ink.Inflictor) and ink.Inflictor or game.GetWorld())
	d:ScaleDamage(ss.ToHammerHealth)
	ss.ProtectedCall(e.TakeDamageInfo, e, d)
end

Simulate.weapon_splatoonsweps_splatling = Simulate.weapon_splatoonsweps_shooter
HitPaint.weapon_splatoonsweps_splatling = HitPaint.weapon_splatoonsweps_shooter
HitEntity.weapon_splatoonsweps_splatling = HitEntity.weapon_splatoonsweps_shooter
function Simulate.weapon_splatoonsweps_blaster_base(ink)
	Simulate.weapon_splatoonsweps_shooter(ink)
	if ink.Time <= ink.ExplosionTime then return end
	if ink.Hit or ink.Exploded then return end
	ink.Exploded = true
	ink.collisiongroup = COLLISION_GROUP_DEBRIS
	ss.MakeBlasterExplosion(ink)
end

function HitPaint.weapon_splatoonsweps_blaster_base(ink, t)
	if not ink.Exploded then
		if t.HitNormal.z > ss.MAX_COS_DEG_DIFF then
			ink.InkRadius = ink.InkRadiusGround
			ink.MinRadius = ink.InkRadiusGround
		else
			ink.InkRadius = ink.InkRadiusWall
			ink.MinRadius = ink.InkRadiusWall
		end

		ink.HitWall = true
		ink.InitDirection = t.HitNormal
		ink.endpos = t.HitPos
		ink.DamageClose = ink.DamageClose * ink.DamageWallMul
		ink.DamageMiddle = ink.DamageMiddle * ink.DamageWallMul
		ink.DamageFar = ink.DamageFar * ink.DamageWallMul
		ink.ColRadiusFar = ink.ColRadiusFar * ink.ColRadiusWallMul
		ink.ColRadiusMiddle = ink.ColRadiusMiddle * ink.ColRadiusWallMul
		ink.ColRadiusClose = ink.ColRadiusClose * ink.ColRadiusWallMul
		ink.InkRadiusBlastMax = ink.InkRadiusBlastMax * ink.ColRadiusWallMul
		ink.InkRadiusBlastMin = ink.InkRadiusBlastMin * ink.ColRadiusWallMul
		ss.MakeBlasterExplosion(ink)
	end

	ink.IsDrop = true
	HitPaint.weapon_splatoonsweps_shooter(ink, t)
end

HitEntity.weapon_splatoonsweps_blaster_base = HitEntity.weapon_splatoonsweps_shooter

local function ProcessInkQueue(ply)
	while true do
		for ink in pairs(ss.InkQueue) do
			if not IsValid(ink.filter) then ss.InkQueue[ink] = nil continue end
			if ink.filter:IsPlayer() and ink.filter ~= ply then continue end

			ss.ProtectedCall(Simulate[ink.Base], ink)
			if not (ink.start and ink.endpos) then
				ss.InkQueue[ink] = nil
				continue
			end

			local t = util.TraceHull(ink)
			ink.start = t.HitPos
			if not (t.Hit or ss.IsInWorld(t.HitPos)) then
				ss.InkQueue[ink] = nil
			elseif IsValid(t.Entity) and t.Entity:Health() > 0 and ink.Damage > 0 then -- If ink hits an NPC or something
				local w = ss.IsValidInkling(t.Entity)
				if not (w and ss.IsAlly(w, ink.Color)) then
					ss.ProtectedCall(HitEntity[ink.Base], ink, t, w)
				end
				ss.InkQueue[ink] = nil
			elseif t.Hit then
				ink.endpos = t.HitPos - t.HitNormal * ink.ColRadius * 2
				t = util.TraceLine(ink)
				ss.ProtectedCall(HitPaint[ink.Base], ink, t)
				ss.InkQueue[ink] = nil
			end
		end

		for ink in pairs(ss.PaintSchedule) do
			if CurTime() > ink.Time then
				ss.Paint(ink.pos, ink.normal, ink.radius, ink.color,
				ink.angle, ink.inktype, ink.ratio, ink.filter, ink.ClassName)
				ss.PaintSchedule[ink] = nil
			end
		end

		repeat
			ply = coroutine.yield()
		until IsFirstTimePredicted()
	end
end

-- Make an ink bullet for shooter.
-- Arguments:
--   Entity owner				| The owner of fired ink.
--   Vector pos					| Initial position of ink.
--   number inktype				| Shape of ink.
function ss.AddInk(ply, pos, inktype, isdrop)
	local w = ss.IsValidInkling(ply)
	if not (isdrop or w) then return {} end
	if isdrop then w = isdrop end
	local info = isdrop and dropdata or w.Primary
	local base = isdrop and "weapon_splatoonsweps_shooter" or w.Base
	local IsLP = Either(isdrop,
		(isdrop or {}).IsCarriedByLocalPlayer,
		SERVER or ss.ProtectedCall(w.IsCarriedByLocalPlayer, w))
	local dt = CLIENT and IsLP and w:Ping() or 0
	local t = {
		Angle = isdrop and isdrop.Angle or w.InitAngle,
		Base = base,
		ClassName = w.ClassName,
		Color = isdrop and isdrop.Color or w:GetNWInt "inkcolor",
		ColRadius = info.ColRadius,
		Damage = info.Damage,
		DecreaseDamage = info.DecreaseDamage,
		Inflictor = w,
		InitDirection = isdrop and -vector_up or w.InitVelocity:GetNormalized(),
		InitPos = pos,
		InitTime = info.InitTime or CurTime(),
		InkType = math.floor(inktype),
		IsCarriedByLocalPlayer = IsLP,
		IsBlaster = base == "weapon_splatoonsweps_blaster_base",
		IsCharger = base == "weapon_splatoonsweps_charger",
		IsShooter = not isdrop and base == "weapon_splatoonsweps_shooter",
		IsDrop = isdrop,
		MinDamage = info.MinDamage,
		MinDamageTime = info.MinDamageTime,
		SplashInterval = info.SplashInterval,
		Straight = info.Straight,
		Time = 0,
		Velocity = isdrop and vector_origin or w.InitVelocity,
		WeaponSplashInit = w.SplashInit,
		-- collisiongroup = COLLISION_GROUP_IN_VEHICLE,
		endpos = Vector(),
		filter = ply,
		mask = ss.SquidSolidMask,
		maxs = ss.vector_one * info.ColRadius,
		mins = -ss.vector_one * info.ColRadius,
		start = pos,
	}

	if t.IsCharger then
		local prog = w:GetChargeProgress()
		local Speed = w:GetInkVelocity()
		local SplashRadius = Lerp(prog, info.MinSplashRadius, info.MaxSplashRadius)
		local SplashRatio = Lerp(prog, info.MinSplashRatio, info.MaxSplashRatio)
		local SplashInterval = Lerp(prog, info.MinSplashInterval, info.MaxSplashInterval)
		SplashInterval = SplashInterval * SplashRadius * SplashRatio * .85
		table.Merge(t, {
			Charge = prog,
			Damage = w:GetDamage(),
			FootpaintCharge = info.FootpaintCharge,
			FootpaintRadius = SplashRadius / info.SplashRadiusMul,
			MaxWallPaintNum = info.MaxWallPaintNum,
			MinWallPaintNum = info.MinWallPaintNum,
			Range = w.Range,
			Ratio = 1 / SplashRatio,
			Speed = Speed,
			SplashCount = 0,
			SplashInit = SplashInterval / info.SplashPatterns * w.SplashInit + SplashRadius,
			SplashInitMul = w.SplashInit,
			SplashInterval = SplashInterval,
			SplashRadius = SplashRadius,
			SplashRadiusMul = info.SplashRadiusMul,
			Straight = w.Range / Speed,
			StraightPos = pos + t.InitDirection * w.Range,
			WallPaintCharge = info.WallPaintCharge,
		})
	else
		table.Merge(t, {
			InkRadius = info.InkRadius,
			MinRadius = info.MinRadius,
			PaintNearDistance = info.PaintNearDistance or ss.mPaintNearDistance,
			PlayHitSound = isdrop and info.PlayHitSound or nil,
			Range = isdrop and 0 or info.InitVelocity * info.Straight,
			SplashCount = 0,
			SplashInit = info.SplashInterval / info.SplashPatterns * w.SplashInit,
			SplashInitMul = isdrop and 0 or w.SplashInit,
			SplashMinRadius = info.SplashRadius * info.MinRadius / info.InkRadius,
			SplashNum = isdrop and 0 or w.SplashNum,
			SplashRadius = info.SplashRadius,
		})

		if t.IsBlaster then
			table.Merge(t, {
				ColRadiusClose = info.ColRadiusClose,
				ColRadiusMiddle = info.ColRadiusMiddle,
				ColRadiusFar = info.ColRadiusFar,
				ColRadiusWallMul = info.ColRadiusWallMul,
				DamageClose = info.DamageClose,
				DamageMiddle = info.DamageMiddle,
				DamageFar = info.DamageFar,
				DamageWallMul = info.DamageWallMul,
				ExplosionTime = info.ExplosionTime,
				HitWall = false,
				InkRadiusBlastMax = info.InkRadiusBlastMax,
				InkRadiusBlastMin = info.InkRadiusBlastMin,
				InkRadiusGround = info.InkRadiusGround,
				InkRadiusWall = info.InkRadiusWall,
				InkType = ss.GetDropType(),
				IsCritical = true,
				Ratio = 1,
			})
		end
	end

	ss.InkQueue[t] = true
	return t
end

local process = coroutine.create(ProcessInkQueue)
hook.Add("Move", "SplatoonSWEPs: Simulate ink", function(ply, mv)
	if coroutine.status(process) == "dead" then return end
	ply:LagCompensation(true)
	local ok, msg = coroutine.resume(process, ply)
	ply:LagCompensation(false)
	if not ok then ErrorNoHalt(msg) end
end)

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
	if not isvector(self.ColorVector) then return end
	if self.IsBlaster then
		if self.Real.Time > self.Straight + ss.ShooterDecreaseFrame then
			self.Size, self.IsBlaster = ss.mColRadius * 2
		end

		render.SetMaterial(Mat)
		Mat:SetVector("$color", self.ColorVector)
		render.DrawSphere(self.Apparent.Pos, self.Size, 8, 8, self.Color)
		if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then
			Mat:SetVector("$color", ss.vector_one)
			return
		end

		render.PushFlashlightMode(true) -- Ink lit by player's flashlight or a projected texture
		render.DrawSphere(self.Apparent.Pos, self.Size, 8, 8, self.Color)
		render.PopFlashlightMode()
		Mat:SetVector("$color", ss.vector_one)
		return
	end

	local LifeTime = math.max(CurTime() - self.Real.InitTime, 0)
	local sizeinflate = self.IsDrop and 1 or math.Clamp(LifeTime / InflateTime, 0, 1)
	local sizef = self.Size * sizeinflate
	local sizeb = sizef * .75
	local AppPos, AppAng = self:GetPos(), self:GetAngles()
    local TailPos, TailAng = self.Tail.Pos, self.Tail.Ang
    if self.IsCharger then AppAng, TailAng = (AppPos - TailPos):Angle(), (AppPos - TailPos):Angle() end
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
	Mat:SetVector("$color", self.ColorVector)
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
		elseif Time > MaxFrame then -- Falls Straight
			local FallTime = math.max(Time - Straight - ss.ShooterDecreaseFrame, 0)
			if FallTime > ss.ShooterTermTime then
				local v = g * ss.ShooterTermTime
				Pos:Set(MaxPos - v * ss.ShooterTermTime / 2 + v * FallTime)
			else
				Pos:Set(MaxPos + g * FallTime * FallTime / 2)
			end
		else
			Pos:Set(ink.InitPos + ink.Velocity * math.Clamp((Straight + Time) / 2, Straight, MaxFrame))
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

-- table ink | A table containing these fields:
--   Angle Angle                    | The orientation
--   Color Color                    | Ink color (r, g, b)
--   number ColRadiusClose          | Collision radius of close range
--   number ColRadiusMiddle         | Collision radius of middle range
--   number ColRadiusFar            | Collision radius of far range
--   number DamageClose             | Dealing damage of close range
--   number DamageMiddle            | Dealing damage of middle range
--   number DamageFar               | Dealing damage of far range
--   Vector endpos                  | Former position
--   Entity filter                  | The owner of the ink
--   boolean HitWall                | The explosion is on the wall or not
--   boolean IsCarriedByLocalPlayer | The owner is local player or not
local components = {"x", "y", "z"}
local directions = {"GetForward", "GetRight", "GetUp"}
function ss.MakeBlasterExplosion(ink)
	local d = DamageInfo()
	local attacker = IsValid(ink.filter) and ink.filter or game.GetWorld()
	local inflictor = ss.IsValidInkling(ink.filter) or game.GetWorld()
	local hurtowner = ss.GetOption "weapon_splatoonsweps_blaster_base" "hurtowner"
	local damagedealed = false
	for _, e in ipairs(ents.FindInSphere(ink.endpos, ink.ColRadiusFar)) do
		if not IsValid(e) or ss.IsAlly(e) or e:Health() <= 0 then continue end
		if not hurtowner and e == ink.filter then continue end
		if CLIENT and e ~= ink.filter then damagedealed = true break end
		local dmg = ink.DamageClose
		local dist = Vector()
		local maxs, mins = e:OBBMaxs(), e:OBBMins()
		local origin = e:LocalToWorld(e:OBBCenter())
		local size = (maxs - mins) / 2
		for i, dir in pairs {x = e:GetForward(), y = e:GetRight(), z = e:GetUp()} do
			local segment = dir:Dot(ink.endpos - origin)
			local sign = segment == 0 and 0 or segment > 0 and 1 or -1
			segment = math.abs(segment)
			if segment <= size[i] then continue end
			dist = dist + sign * (size[i] - segment) * dir
		end

		damagedealed = damagedealed or e == ink.filter
		dist = dist:Length()
		if dist > ink.ColRadiusMiddle then
			dmg = math.Remap(dist, ink.ColRadiusMiddle, ink.ColRadiusFar, ink.DamageMiddle, ink.DamageFar)
		elseif dist > ink.ColRadiusClose then
			dmg = math.Remap(dist, ink.ColRadiusClose, ink.ColRadiusMiddle, ink.DamageClose, ink.DamageMiddle)
		end

		d:SetDamage(dmg)
		d:SetDamageForce((e:WorldSpaceCenter() - ink.endpos):GetNormalized() * dmg)
		d:SetDamagePosition(ink.endpos)
		d:SetDamageType(DMG_GENERIC)
		d:SetMaxDamage(dmg)
		d:SetReportedPosition(ink.endpos)
		d:SetAttacker(attacker)
		d:SetInflictor(inflictor)
		d:ScaleDamage(ss.ToHammerHealth)
		ss.ProtectedCall(e.TakeDamageInfo, e, d)
	end

	if ss.mp and not IsFirstTimePredicted() then return end
	if ink.IsCarriedByLocalPlayer and damagedealed then ss.PlayHitSound(false, attacker) end
	if ss.mp and SERVER and IsValid(ink.filter) and ink.filter:IsPlayer() then SuppressHostEvents(ink.filter) end
	local e = EffectData()
	e:SetOrigin(ink.endpos)
	e:SetColor(ink.Color)
	e:SetFlags(ink.HitWall and 1 or 0)
	e:SetRadius(ink.ColRadiusFar)
	util.Effect("SplatoonSWEPsBlasterExplosion", e, true,
	not ink.filter:IsPlayer() and SERVER and ss.mp or nil)
	if ss.mp and SERVER and IsValid(ink.filter) and ink.filter:IsPlayer() then SuppressHostEvents() end

	local a = ink.InitDirection:Angle()
	if ink.HitWall then a:RotateAroundAxis(a:Right(), -90) end
	local a2, a3 = Angle(a), Angle(a)
	a2:RotateAroundAxis(a:Right(), 45)
	a2:RotateAroundAxis(a:Up(), 45)
	a3:RotateAroundAxis(a:Right(), 45)
	a3:RotateAroundAxis(a:Up(), -45)
	for _, d in ipairs {
		a:Forward(), -a:Forward(), a:Right(), -a:Right(), a:Up(),
		a2:Forward(), a2:Right(), -a2:Right(), a2:Up(),
		a3:Forward(), a3:Right(), -a3:Right(), a3:Up(),
	} do
		local t = util.TraceLine {
			collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
			start = ink.endpos,
			endpos = ink.endpos + d * ink.ColRadiusFar,
			filter = ink.filter,
			mask = ss.SquidSolidMaskBrushOnly,
		}

		if not t.Hit or t.StartSolid then continue end
		local frac = t.HitPos:Distance(t.StartPos) / ink.ColRadiusFar
		local radius = Lerp(frac, ink.InkRadiusBlastMax, ink.InkRadiusBlastMin)
		ss.Paint(t.HitPos, t.HitNormal, radius, ink.Color, ink.Angle, ss.GetDropType(), 1, ink.filter, ink.ClassName)
	end
end
