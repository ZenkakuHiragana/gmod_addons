
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.IsSlosher = true

local FirePosition = 10
function SWEP:GetRange() return self.Range end
function SWEP:GetFirePosition(ping)
	if not IsValid(self.Owner) then return self:GetPos(), self:GetForward(), 0 end
	local aim = self:GetAimVector() * self:GetRange(ping)
	local ang = aim:Angle()
	local shootpos = self:GetShootPos()
	local col = ss.vector_one * self.Parameters.mFirstGroupBulletFirstCollisionRadiusForField
	local dy = FirePosition * (self:GetNWBool "lefthand" and -1 or 1)
	local dp = -Vector(0, dy, FirePosition) dp:Rotate(ang)
	local t = ss.SquidTrace
	t.start, t.endpos = shootpos, shootpos + aim
	t.mins, t.maxs = -col, col
	t.filter = {self, self.Owner}
	for _, e in pairs(ents.FindAlongRay(t.start, t.endpos, t.mins * 5, t.maxs * 5)) do
		local w = ss.IsValidInkling(e)
		if w and ss.IsAlly(w, self) then
			t.filter = {self, self.Owner, e, w}
		end
	end

	local tr = util.TraceLine(t)
	local trhull = util.TraceHull(t)
	local pos = shootpos + dp
	local min = {dir = 1, dist = math.huge, pos = pos}

	t.start, t.endpos = pos, tr.HitPos
	local trtest = util.TraceHull(t)
	if self:GetNWBool "avoidwalls" and tr.HitPos:DistToSqr(shootpos) > trtest.HitPos:DistToSqr(pos) * 9 then
		for dir, negate in ipairs {false, "y", "z", "yz", 0} do -- right, left, up
			if negate then
				if negate == 0 then
					dp = vector_up * -FirePosition
					pos = shootpos
				else
					dp = -Vector(0, dy, FirePosition)
					for i = 1, negate:len() do
						local s = negate:sub(i, i)
						dp[s] = -dp[s]
					end
					dp:Rotate(ang)
					pos = shootpos + dp
				end

				t.start = pos
				trtest = util.TraceHull(t)
			end
			
			if not trtest.StartSolid then
				local dist = math.floor(trtest.HitPos:DistToSqr(tr.HitPos))
				if dist < min.dist then
					min.dir, min.dist, min.pos = dir, dist, pos
				end
			end
		end
	end

	return min.pos, (tr.HitPos - min.pos):GetNormalized(), min.dir
end

function SWEP:GetSpreadAmount()
	return 0, 0
end

local OrdinalNumbers = {"First", "Second", "Third"}
function SWEP:GetInitSpeed(number, spawncount)
	local order = OrdinalNumbers[number]
	local p = self.Parameters
	local base = p["m" .. order .. "GroupBulletFirstInitSpeedBase"]
	if not self.Owner:OnGround() then
		base = p["m" .. order .. "GroupBulletFirstInitSpeedJumpingBase"]
	end

	return base + spawncount * p["m" .. order .. "GroupBulletAfterInitSpeedOffset"]
end

local randvel = "SplatoonSWEPs: Spread velocity"
function SWEP:GetInitVelocity(number, spawncount)
	local order = OrdinalNumbers[number]
	local p = self.Parameters
	local base = self:GetInitSpeed(number, spawncount)
	local x = p["m" .. order .. "GroupBulletInitSpeedRandomX"]
	local z = p["m" .. order .. "GroupBulletInitSpeedRandomZ"]
	local y = base * p["m" .. order .. "GroupBulletInitVecYRate"]
	x = util.SharedRandom(randvel, -x, x, number)
	z = base + util.SharedRandom(randvel, -z, z, number * 2)
	return z, x, y -- Forward, Right, Up
end

function SWEP:GetPaintParameters(number, spawncount)
	local order = OrdinalNumbers[number]
	local p = self.Parameters
	if spawncount == 0 then
		return p["m" .. order .. "GroupBulletFirstPaintFarD"],
			   p["m" .. order .. "GroupBulletFirstPaintFarR"],
			   p["m" .. order .. "GroupBulletFirstPaintFarRate"],
			   p["m" .. order .. "GroupBulletFirstPaintNearD"],
			   p["m" .. order .. "GroupBulletFirstPaintNearR"],
			   p["m" .. order .. "GroupBulletFirstPaintNearRate"]
	else
		return p["m" .. order .. "GroupBulletSecondAfterPaintFarD"],
			   p["m" .. order .. "GroupBulletSecondAfterPaintFarR"],
			   p["m" .. order .. "GroupBulletSecondAfterPaintFarRate"],
			   p["m" .. order .. "GroupBulletSecondAfterPaintNearD"],
			   p["m" .. order .. "GroupBulletSecondAfterPaintNearR"],
			   p["m" .. order .. "GroupBulletSecondAfterPaintNearRate"]
	end
end

function SWEP:GetCollisionRadii(number, spawncount)
	local order = OrdinalNumbers[number]
	local p = self.Parameters
	local forent = p["m" .. order .. "GroupBulletFirstCollisionRadiusForPlayer"]
	local forworld = p["m" .. order .. "GroupBulletFirstCollisionRadiusForField"]
	local forent_offset = p["m" .. order .. "GroupBulletAfterCollisionRadiusForPlayerOffset"]
	local forworld_offset = p["m" .. order .. "GroupBulletAfterCollisionRadiusForFieldOffset"]
	return forent + spawncount * forent_offset, forworld + spawncount * forworld_offset
end

function SWEP:GetDamageParameters(number, spawncount)
	local order = OrdinalNumbers[number]
	local p = self.Parameters
	local maxdist = p.mBulletDamageMaxDist
	local mindist = p.mBulletDamageMinDist
	local max = p["m" .. order .. "GroupBulletFirstDamageMaxValue"]
	local min = p["m" .. order .. "GroupBulletFirstDamageMinValue"]
	local mul = p["m" .. order .. "GroupBulletAfterDamageRateOffset"]
	mul = 1 + spawncount * mul
	return mul * max, maxdist, mul * min, mindist
end

function SWEP:GetDrawRadius(number, spawncount)
	local order = OrdinalNumbers[number]
	local p = self.Parameters
	local base = p["m" .. order .. "GroupBulletFirstDrawRadius"]
	local offset = p["m" .. order .. "GroupBulletAfterDrawRadiusOffset"]
	return base + spawncount * offset
end

local randink = "SplatoonSWEPs: Shooter ink type"
function SWEP:CreateInk(number, spawncount) -- Group #, spawncount-th bullet(0, 1, 2, ...)
	if not self:IsFirstTimePredicted() then return end
	local order = OrdinalNumbers[number]
	local p = self.Parameters
	local dir = self:GetAimVector()
	local pos = self:GetShootPos()
	local right = self.Owner:GetRight()
	local IsLP = CLIENT and self:IsCarriedByLocalPlayer()
	local ang = dir:Angle()
	
	local vforward, vright, vup = self:GetInitVelocity(number, spawncount)
	local initvelocity = dir * vforward + ang:Right() * vright + ang:Up() * vup
	local yaw = initvelocity:Angle().yaw
	local dmax, dmaxdist, dmin, dmindist = self:GetDamageParameters(number, spawncount)
	local pfardist, pfarradius, pfarrate, pneardist, pnearradius, pnearrate = self:GetPaintParameters(number, spawncount)
	local colent, colworld = self:GetCollisionRadii(number, spawncount)
	if initvelocity.x == 0 and initvelocity.y == 0 then yaw = ang.yaw end
	table.Merge(self.Projectile, {
		Color = self:GetNWInt "inkcolor",
		InitPos = pos,
		InitVel = initvelocity,
		Type = util.SharedRandom(randink, 1, 4, CurTime() * spawncount),
		Yaw = yaw,
		ColRadiusEntity = colent,
		ColRadiusWorld = colworld,
		DamageMax = dmax,
		DamageMaxDistance = dmaxdist,
		DamageMin = dmin,
		DamageMinDistance = dmindist,
		PaintRatioFarDistance = pfardist,
		PaintFarDistance = pfardist,
		PaintFarRadius = pfarradius,
		PaintFarRatio = pfarrate,
		PaintRatioNearDistance = pneardist,
		PaintNearDistance = pneardist,
		PaintNearRadius = pnearradius,
		PaintNearRatio = pnearrate,
		StraightFrame = p.mBulletStraightFrame,
	})
	
	local e = EffectData()
	e:SetAttachment(spawncount * 10 + number)
	e:SetColor(self.Projectile.Color)
	e:SetEntity(self)
	e:SetFlags(IsLP and 128 or 0)
	e:SetMagnitude(self.Projectile.ColRadiusWorld)
	e:SetOrigin(self.Projectile.InitPos)
	e:SetScale(0)
	e:SetStart(self.Projectile.InitVel)
	ss.UtilEffectPredicted(self.Owner, "SplatoonSWEPsShooterInk", e, true, self.IgnorePrediction)
	ss.AddInk(p, self.Projectile)
end

function SWEP:SharedPrimaryAttack(able, auto)
	if self:GetIsBusy() then return end
	self:SetIsBusy(true)
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	local p = self.Parameters
	local spawntimebase = CurTime() + p.mSwingLiftFrame
	self:SetCooldown(spawntimebase + p.mPostDelayFrm_Main)
	self:SetSpawnTimeBase(spawntimebase)
	self:SetNextInkSpawnTime1(spawntimebase)
	self:SetNextInkSpawnTime2(spawntimebase + p.mSecondGroupBulletFirstFrameOffset)
	self:SetNextInkSpawnTime3(spawntimebase + p.mThirdGroupBulletFirstFrameOffset)
end

function SWEP:Move(ply)
	local p = self.Parameters
	if ply:IsPlayer() then
		if self:GetNWBool "toggleads" then
			if ply:KeyPressed(IN_USE) then
				self:SetADS(not self:GetADS())
			end
		else
			self:SetADS(ply:KeyDown(IN_USE))
		end
	end

	for number, order in ipairs(OrdinalNumbers) do
		local spawnmax = p["m" .. order .. "GroupBulletNum"]
		local spawnremaining = self["GetSpawnRemaining" .. number](self)
		local spawntime = self["GetNextInkSpawnTime" .. number](self)
		local SetRemaining = self["SetSpawnRemaining" .. number]
		local SetTime = self["SetNextInkSpawnTime" .. number]
		local frameoffset = p["m" .. order .. "GroupBulletAfterFrameOffset"]
		if spawnremaining > 0 and CurTime() > spawntime then
			SetRemaining(self, spawnremaining - 1)
			SetTime(self, spawntime + frameoffset)
			self:CreateInk(number, spawnmax - spawnremaining)
		end
	end

	if not self:GetIsBusy() then return end
	if CurTime() < self:GetSpawnTimeBase() then return end
	self.Projectile.ID = CurTime() + self:EntIndex()
	self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)
	self:SetIsBusy(false)
	self:SetNextPrimaryFire(CurTime() + p.mPostDelayFrm_Main)
	if self:GetInk() < p.mInkConsume then
		ss.EmitSound(ply, ss.TankEmpty)
		self:EmitSound "SplatoonSWEPs.EmptySwing"
		return
	end

	self:SetInk(math.max(self:GetInk() - p.mInkConsume, 0))
	self:SetReloadDelay(p.mInkRecoverStop)
	self:EmitSound(self.ShootSound)
	self:SetSpawnRemaining1(p.mFirstGroupBulletNum)
	self:SetSpawnRemaining2(p.mSecondGroupBulletNum)
	self:SetSpawnRemaining3(p.mThirdGroupBulletNum)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Bool", "IsBusy")
	self:AddNetworkVar("Bool", "PreviousHasInk")
	self:AddNetworkVar("Float", "NextInkSpawnTime1")
	self:AddNetworkVar("Float", "NextInkSpawnTime2")
	self:AddNetworkVar("Float", "NextInkSpawnTime3")
	self:AddNetworkVar("Float", "SpawnTimeBase")
	self:AddNetworkVar("Int", "SpawnRemaining1")
	self:AddNetworkVar("Int", "SpawnRemaining2")
	self:AddNetworkVar("Int", "SpawnRemaining3")
end

function SWEP:CustomActivity()
	return "crossbow"
end
