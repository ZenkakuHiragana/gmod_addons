
AddCSLuaFile "shared.lua"
include "shared.lua"

local function AddCleanup(e)
	for _, p in ipairs(player.GetAll()) do
		cleanup.Add(p, SplatoonSWEPs.CleanupTypeInk, e)
	end
end

function SWEP:ServerInit()
	self.SplashInitMul = 0
	self.SplashInitRandom = 0
end

--Serverside: create ink projectile.
function SWEP:ServerPrimaryAttack(canattack)
	if self.CrouchPriority or self:GetInk() <= 0 then return end
	self.SplashInitMul = self.SplashInitMul + 1
	local aim = IsValid(self.Owner) and self.Owner:GetAimVector() or self:GetForward()
	local ang = aim:Angle()
	local angle_initvelocity = Angle(ang)
	local delta_position = Vector(self.Primary.FirePosition)
	local spreadx = math.Rand(-self.Primary.SpreadBias, self.Primary.SpreadBias)
	if self.Owner:GetVelocity().z > 32 then
		spreadx = spreadx + self.Primary.SpreadJump
	else
		spreadx = spreadx + self.Primary.Spread
	end
	
	delta_position:Rotate(self.Owner:EyeAngles())
	ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 90)
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight():Cross(aim), math.Rand(-spreadx, spreadx))
	angle_initvelocity:RotateAroundAxis(self.Owner:GetRight(), math.Rand(-SplatoonSWEPs.mDegRandomY, SplatoonSWEPs.mDegRandomY))
	local InitVelocity = angle_initvelocity:Forward() * self.Primary.InitVelocity
	local SplashInitMul = self.SplashInitMul % self.Primary.SplashPatterns
	local SplashNumRounded = math[math.random() < .5 and "floor" or "ceil"](self.Primary.SplashNum)
	local p = ents.Create "projectile_ink"
	if not IsValid(p) then return end
	p:SetPos(self.Owner:GetShootPos() + delta_position)
	p:SetAngles(ang)
	p:SetOwner(self.Owner)
	p:SetInkColorProxy(self:GetInkColorProxy())
	p.ColorCode = self.ColorCode
	p.InkYaw = self.Owner:EyeAngles().yaw
	p.Damage = self.Primary.Damage
	p.MinDamage = self.Primary.MinDamage
	p.MinDamageTime = self.Primary.MinDamageTime
	p.DecreaseDamage = self.Primary.DecreaseDamage
	p.InkRadius = self.Primary.InkRadius
	p.MinRadius = self.Primary.MinRadius
	p.SplashRadius = self.Primary.SplashRadius
	p.SplashPatterns = self.Primary.SplashPatterns
	p.SplashNum = SplashNumRounded
	p.SplashInterval = self.Primary.SplashInterval
	p.SplashInitMul = SplashInitMul
	p.SplashRandom = self.SplashInitRandom
	p.Straight = self.Primary.Straight
	p.InitVelocity = InitVelocity
	p.InitVelocityLength = self.Primary.InitVelocity / SplatoonSWEPs.ToHammerUnitsPerSec
	p.InkType = math.random(4, 9)
	p:Spawn()
	AddCleanup(p)
	self.SplashInitRandom = self.SplashInitRandom + (SplashInitMul > 0 and 0 or 1)
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 1, function()
		if not IsValid(self.Owner) or self.Owner:IsPlayer() then return end
		self:PrimaryAttack()
	end)
end
