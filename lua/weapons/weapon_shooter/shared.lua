
local ss = SplatoonSWEPs
if not ss then return end

SWEP.Base = "inklingbase"
SWEP.PrintName = "Shooter base"

local FirePosition = 10
function SWEP:GetRange() return self.Primary.Range end
function SWEP:GetFirePosition(aim, ang, shootpos)
	if not IsValid(self.Owner) then return self:GetPos(), self:GetForward(), 0 end
	if not aim then
		local aimvector = ss.ProtectedCall(self.Owner.GetAimVector, self.Owner) or self.Owner:GetForward()
		aim = self:GetRange() * aimvector
		ang = self.Owner:EyeAngles()
		shootpos = ss.ProtectedCall(self.Owner.GetShootPos, self.Owner) or self.Owner:WorldSpaceCenter()
	end
	
	local col = ss.vector_one * self.Primary.ColRadius
	local dp = -Vector(0, FirePosition, FirePosition) dp:Rotate(ang)
	local t = ss.SquidTrace
	t.start, t.endpos = shootpos, shootpos + aim
	t.mins, t.maxs = -col, col
	t.filter = {self, self.Owner}
	for _, e in pairs(ents.FindAlongRay(t.start, t.endpos, t.mins * 5, t.maxs * 5)) do
		local w = ss.IsValidInkling(e)
		if not w or ss.IsAlly(w, self) then continue end
		table.insert(t.filter, e)
		table.insert(t.filter, w)
	end
	
	local tr = util.TraceLine(t)
	local trhull = util.TraceHull(t)
	local pos = shootpos + dp
	local min = {dir = 1, dist = math.huge, pos = pos}
	
	t.start, t.endpos = pos, tr.HitPos
	local trtest = util.TraceHull(t)
	if self.AvoidWalls and tr.HitPos:DistToSqr(shootpos) > trtest.HitPos:DistToSqr(pos) * 9 then
		for dir, negate in ipairs {false, "y", "z", "yz", 0} do --right, left, up
			if negate then
				if negate == 0 then
					dp = vector_up * -FirePosition
					pos = shootpos
				else
					dp = -Vector(0, FirePosition, FirePosition)
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
			
			if trtest.StartSolid then continue end
			local dist = math.floor(trtest.HitPos:DistToSqr(tr.HitPos))
			if dist < min.dist then min.dir, min.dist, min.pos = dir, dist, pos end
		end
	end
	
	return min.pos, (tr.HitPos - min.pos):GetNormalized(), min.dir
end

function SWEP:SharedInit()
	self.NextPlayEmpty = CurTime()
	self:SetAimTimer(CurTime())
end

function SWEP:SharedDeploy()
	if not self.Primary.TripleShotDelay then return end
	self.TripleSchedule:SetDone(0)
end

function SWEP:SharedPrimaryAttack(able, auto)
	if not IsValid(self.Owner) then return end
	local p = self.Primary
	local lmv = self:GetLaggedMovementValue()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay / lmv)
	self:SetCooldown(math.max(self:GetCooldown(), CurTime() + math.min(p.Delay, p.CrouchDelay) / lmv))
	self:SetAimTimer(CurTime() + p.AimDuration)
	self:SetInk(math.max(0, self:GetInk() - p.TakeAmmo))
	
	if not able then
		if p.TripleShotDelay then self:SetCooldown(CurTime()) end
		if self:GetPreviousHasInk() then
			if CLIENT and IsFirstTimePredicted() and self:IsCarriedByLocalPlayer() then
				surface.PlaySound(ss.TankEmpty)
			end
			self:SetNextPlayEmpty(CurTime() + p.Delay * 2)
			self:SetPreviousHasInk(false)
		elseif CurTime() > self:GetNextPlayEmpty() then
			self:EmitSound "SplatoonSWEPs.EmptyShot"
			self:SetNextPlayEmpty(CurTime() + p.Delay * 2)
		end
		
		return
	end
	
	local pos, dir = self:GetFirePosition()
	local right = self.Owner:GetRight()
	local ang = dir:Angle()
	local angle_initvelocity = Angle(ang)
	local DegRandomX = util.SharedRandom("SplatoonSWEPs: Spread", -p.SpreadBias, p.SpreadBias)
	+ Lerp(self.Owner:GetVelocity().z * ss.SpreadJumpFraction, p.Spread, p.SpreadJump)
	local rx = util.SharedRandom("SplatoonSWEPs: Spread", -DegRandomX, DegRandomX, CurTime() * 1e4)
	local ry = util.SharedRandom("SplatoonSWEPs: Spread", -ss.mDegRandomY, ss.mDegRandomY, CurTime() * 1e3)
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	angle_initvelocity:RotateAroundAxis(right:Cross(dir), rx)
	angle_initvelocity:RotateAroundAxis(right, ry)
	self.InitVelocity = angle_initvelocity:Forward() * p.InitVelocity
	self.InitAngle = angle_initvelocity
	self.SplashInit = self:GetSplashInitMul() % p.SplashPatterns
	self.SplashNum = math.floor(p.SplashNum) + math.Round(util.SharedRandom("SplatoonSWEPs: SplashNum", 0, 1))
	self:SetSplashInitMul(self:GetSplashInitMul() + (p.TripleShotDelay and 3 or 1))
	self:SetPreviousHasInk(true)
	self:EmitSound(self.ShootSound)
	self:ResetSequence "fire"
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	if self:IsFirstTimePredicted() then
		local rnda = p.Recoil * -1
		local rndb = p.Recoil * math.Rand(-1, 1)
		self.ViewPunch = Angle(rnda, rndb, rnda)
		self.ModifyWeaponSize = SysTime()
		
		local e = EffectData()
		e:SetAttachment(self.SplashInit)
		e:SetAngles(self.InitAngle)
		e:SetColor(self.ColorCode)
		e:SetEntity(self)
		e:SetFlags(CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0)
		e:SetOrigin(pos)
		e:SetScale(self.SplashNum)
		e:SetStart(self.InitVelocity)
		util.Effect("SplatoonSWEPsShooterInk", e)
		ss.AddInk(self.Owner, pos, util.SharedRandom("SplatoonSWEPs: Shooter ink type", 4, 9))
	end
	
	if not p.TripleShotDelay then return end
	local d = self.TripleSchedule:GetDone()
	if d == 1 or d == 2 then return end
	self:SetCooldown(CurTime() + (p.Delay * 2 + p.TripleShotDelay) / lmv)
	self:SetAimTimer(self:GetCooldown())
	self.TripleSchedule:SetDone(1)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "PreviousHasInk")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "NextPlayEmpty")
	self:AddNetworkVar("Int", "SplashInitMul")
	
	if not self.Primary.TripleShotDelay then return end
	self.TripleSchedule = self:AddNetworkSchedule(0, function(self, schedule)
		if schedule:GetDone() == 1 or schedule:GetDone() == 2 then
			if self:GetNextPrimaryFire() > CurTime() then
				schedule:SetDone(schedule:GetDone() - 1)
			else
				self:PrimaryAttack(true)
			end
			
			return
		end
		
		schedule:SetDone(3)
	end)
	self.TripleSchedule:SetDone(3)
end

function SWEP:CustomActivity()
	local at = self:GetAimTimer()
	if CLIENT and self:IsCarriedByLocalPlayer() then at = at - self:Ping() end
	if CurTime() > at then return end
	local aimpos = select(3, self:GetFirePosition())
	aimpos = aimpos == 3 or aimpos == 4
	return aimpos and "rpg" or "crossbow"
end

function SWEP:CustomMoveSpeed()
	return CurTime() < self:GetAimTimer() and self.Primary.MoveSpeed or nil
end

function SWEP:GetAnimWeight()
	return (self.Primary.Delay + .5) / 1.5
end

function SWEP:UpdateAnimation(ply, vel, max)
	ply:AnimSetGestureWeight(GESTURE_SLOT_ATTACK_AND_RELOAD, self:GetAnimWeight())
end
