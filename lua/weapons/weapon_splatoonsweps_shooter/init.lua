
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile "shared.lua"
include "shared.lua"

function SWEP:ServerInit()
	if not self.Primary.TripleShotDelay then return end
	self:SetNPCMinBurst(1)
	self:SetNPCMaxBurst(1)
	self:SetNPCMinRest(self.Primary.TripleShotDelay)
	self:SetNPCMaxRest(self.Primary.TripleShotDelay)
end

local TrailParams = {true, 3, 1, .5, .125, "sprites/physbeama"}
function SWEP:ServerDeploy()
	if not (self.IsHeroShot and IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
	local a = self:LookupAttachment "trail"
	local c = self.HeroColor[self:GetNWInt "level" + 1]
	local vm = self.Owner:GetViewModel()
	self:SetNWEntity("Trail", util.SpriteTrail(self, a,	c, unpack(TrailParams)))

	if not IsValid(vm) then return end
	a = vm:LookupAttachment "trail"
	self:SetNWEntity("TrailVM", util.SpriteTrail(vm, a, c, unpack(TrailParams)))
end

function SWEP:ServerHolster()
	if not self.IsHeroShot then return end
	SafeRemoveEntity(self:GetNWEntity "Trail")
	SafeRemoveEntity(self:GetNWEntity "TrailVM")
end

function SWEP:ServerThink()
	local c = self.HeroColor[self:GetNWInt "level" + 1]
	for _, t in ipairs {self.Trail, self.TrailViewmodel} do
		if IsValid(t) then t:Fire("Color", tostring(c)) end
	end
end

function SWEP:NPCShoot_Primary(ShootPos, ShootDir)
	self:PrimaryAttack()
	self:AddSchedule(self.Primary.Delay, 2, function(self, schedule)
		self:PrimaryAttack()
	end)
end
