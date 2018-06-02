
local ss = SplatoonSWEPs
if not ss then return end

SWEP.Base = "inklingbase"
SWEP.PrintName = "Shooter base"
function SWEP:GetFirePosition()
	if not IsValid(self.Owner) then return self:GetPos(), self:GetForward(), 0 end
	local aim = self.Owner:GetAimVector()
	local col = self.Primary.ColRadius
	local dp = Vector(self.Primary.FirePosition)
	dp:Rotate(self.Owner:EyeAngles())
	local shootpos = self.Owner:GetShootPos()
	local t = {
		start = shootpos, endpos = shootpos + aim * self.Primary.Range,
		filter = {self, self.Owner}, mask = ss.SquidSolidMask,
		collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS,
		mins = -ss.vector_one * col, maxs = ss.vector_one * col,
	}
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
					dp = vector_origin
					pos = shootpos
				else
					dp = Vector(self.Primary.FirePosition)
					for i = 1, negate:len() do
						local s = negate:sub(i, i)
						dp[s] = -dp[s]
					end
					dp:Rotate(self.Owner:EyeAngles())
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
	self:SetModifyWeaponSize(CurTime() - 1)
	self:SetAimTimer(CurTime())
	
	if not self.Primary.TripleShotDelay then return end
	self:SetTripleShot(0)
end

--Playing sounds
function SWEP:SharedPrimaryAttack(canattack)
	if not self.CrouchPriority or CLIENT and LocalPlayer() ~= self.Owner then
		self:SetHoldType(self.HoldType)
		self.InklingSpeed = self.Primary.MoveSpeed
		if not self:GetOnEnemyInk() then self:SetPlayerSpeed(self.Primary.MoveSpeed) end
		self:SetAimTimer(CurTime() + self.Primary.AimDuration)
		if SERVER then self:SetInk(math.max(0, self:GetInk() - self.Primary.TakeAmmo)) end
	end
	
	if self:GetInk() <= 0 then
		if CLIENT and self.PreviousInk then
			surface.PlaySound(ss.TankEmpty)
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
			self.PreviousInk = false
		elseif CurTime() > self.NextPlayEmpty then
			self:EmitSound "SplatoonSWEPs.EmptyShot"
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
		end
	elseif canattack then
		self:SetModifyWeaponSize(CurTime())
		if SERVER or IsFirstTimePredicted() then self:EmitSound(self.ShootSound) end
		if CLIENT then self.PreviousInk = true end
		
		if not (self.Primary.TripleShotDelay and (SERVER or IsFirstTimePredicted())) then return end
		if self:GetTripleShot() > 0 then
			if self:GetTripleShot() > 1 then
				local laggedvalue = self.Owner:IsPlayer() and self.Owner:GetLaggedMovementValue() or 1
				self:SetNextPrimaryFire(CurTime() + self.Primary.TripleShotDelay / laggedvalue)
				self:SetNextCrouchTime(CurTime() + self.Primary.TripleShotDelay / laggedvalue)
				if SERVER then self:SetTripleShot(0) end
			elseif SERVER then
				self:SetTripleShot(2)
			end
		else
			if SERVER then self:SetTripleShot(1) end
			self:AddSchedule(self:GetNextPrimaryFire() - CurTime(), 2, function(self, schedule)
				self:PrimaryAttack()
			end)
		end
	end
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "ModifyWeaponSize") --Shooter expands its model when firing.
	self:AddNetworkVar("Float", "AimTimer")
	
	if not self.Primary.TripleShotDelay then return end
	self:AddNetworkVar("Int", "TripleShot") --Shooting counter for Nozzlenoses.
end

function SWEP:SharedThink()
	if self.Owner:IsFlagSet(FL_DUCKING) then
		self:SetHoldType(self.HoldType)
	elseif self.Owner:IsPlayer() and self:GetAimTimer() < CurTime() then
		self:SetHoldType "passive"
		self.InklingSpeed = self:GetInklingSpeed()
		if not (self:GetOnEnemyInk() or self:GetInInk()) then
			self:SetPlayerSpeed(self.InklingSpeed)
		end
	end
end
