
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.IsSlosher = true

local FirePosition = 10
function SWEP:GetRange() return self.Range end
function SWEP:GetInitVelocity() return self.Parameters.mInitVel end
function SWEP:GetFirePosition(ping)
	if not IsValid(self.Owner) then return self:GetPos(), self:GetForward(), 0 end
	local aim = self:GetAimVector() * self:GetRange(ping)
	local ang = aim:Angle()
	local shootpos = self:GetShootPos()
	local col = ss.vector_one * self.Parameters.mFirstGroupBulletFirstCollsionRadiusForField
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
	return self.Parameters.mShotRandomDegreeExceptBulletForGuide, ss.mDegRandomY
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Bool", "ADS")
	self:AddNetworkVar("Bool", "PreviousHasInk")
	self:AddNetworkVar("Float", "AimTimer")
	self:AddNetworkVar("Float", "Bias")
	self:AddNetworkVar("Float", "Jump")
	self:AddNetworkVar("Float", "NextPlayEmpty")
	self:AddNetworkVar("Int", "SplashInitMul")
end

function SWEP:CustomActivity()
	return "crossbow"
end
