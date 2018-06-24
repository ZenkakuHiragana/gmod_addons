
local ss = SplatoonSWEPs
if not ss then return end

SWEP.Base = "inklingbase"
SWEP.PrintName = "Shooter base"
function SWEP:GetFirePosition(aim, ang, shootpos)
	if not IsValid(self.Owner) then return self:GetPos(), self:GetForward(), 0 end
	if not aim then
		local aimvector = ss:ProtectedCall(self.Owner.GetAimVector, self.Owner) or self.Owner:GetForward()
		aim = self.Primary.Range * aimvector
		ang = self.Owner:EyeAngles()
		shootpos = ss:ProtectedCall(self.Owner.GetShootPos, self.Owner) or self.Owner:WorldSpaceCenter()
	end
	
	local col = ss.vector_one * self.Primary.ColRadius
	local dp = Vector(self.Primary.FirePosition) dp:Rotate(ang)
	local t = ss.SquidTrace
	t.start, t.endpos = shootpos, shootpos + aim
	t.mins, t.maxs = -col, col
	t.filter = {self, self.Owner}
	for _, e in pairs(ents.FindAlongRay(t.start, t.endpos, t.mins * 5, t.maxs * 5)) do
		local w = ss:IsValidInkling(e)
		if not w or w.ColorCode == self.ColorCode then continue end
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
					dp = vector_up * self.Primary.FirePosition.z
					pos = shootpos
				else
					dp = Vector(self.Primary.FirePosition)
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
	if not self.Primary.TripleShotDelay then return end
	self.TripleShot = CurTime()
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "AimTimer")
end
