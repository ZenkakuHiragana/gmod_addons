
local ss = SplatoonSWEPs
if not ss then return end
function SWEP:CustomPrimary(p, info)
	p.Straight = info.Delay.Straight * ss.FrameToSec
	p.Damage = info.Damage * ss.ToHammerHealth
	p.MinDamage = info.MinDamage * ss.ToHammerHealth
	p.InkRadius = info.InkRadius * ss.ToHammerUnits
	p.MinRadius = info.MinRadius * ss.ToHammerUnits
	p.SplashRadius = info.SplashRadius * ss.ToHammerUnits
	p.SplashPatterns = info.SplashPatterns
	p.SplashNum = info.SplashNum
	p.SplashInterval = info.SplashInterval * ss.ToHammerUnits
	p.Spread = info.Spread
	p.SpreadJump = info.SpreadJump
	p.SpreadBias = info.SpreadBias
	p.MoveSpeed = info.MoveSpeed * ss.ToHammerUnitsPerSec
	p.MinDamageTime = info.Delay.MinDamage * ss.FrameToSec
	p.DecreaseDamage = info.Delay.DecreaseDamage * ss.FrameToSec
	p.InitVelocity = info.InitVelocity * ss.ToHammerUnitsPerSec
	p.FirePosition = info.FirePosition
	p.AimDuration = info.Delay.Aim * ss.FrameToSec
end

SWEP.Base = "inklingbase"
ss:SetPrimary(SWEP, {
	IsAutomatic			= true,					--false to semi-automatic
	Recoil				= .2,					--Viewmodel recoil intensity
	TakeAmmo			= .009,					--Ink consumption per fire[-]
	PlayAnimPercent		= 0,					--Play PLAYER_ATTACK1 animation frequency[%]
	FirePosition		= Vector(0, -6, -9),	--Ink spawn position
	Damage				= .36,					--Maximum damage[-]
	MinDamage			= .18,					--Minimum damage[-]
	InkRadius			= 19.20000076,			--Painting radius[Splatoon units]
	MinRadius			= 18,					--Minimum painting radius[Splatoon units]
	SplashRadius		= 13,					--Painting radius[Splatoon units]
	SplashPatterns		= 5,					--Paint patterns
	SplashNum			= 2,					--Number of splashes
	SplashInterval		= 75,					--Make an interval on each splash[Splatoon units]
	Spread				= 6,					--Aim cone[deg]
	SpreadJump			= 15,					--Aim cone while jumping[deg]
	SpreadBias			= .25,					--Aim cone random component[deg]
	MoveSpeed			= .72,					--Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,					--Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,					--Change hold type[frames]
		Fire			= 6,					--Fire rate[frames]
		Reload			= 20,					--Start reloading after firing weapon[frames]
		Crouch			= 6,					--Can't crouch for some frames after firing
		Straight		= 4,					--Ink goes without gravity[frames]
		MinDamage		= 15,					--Deals minimum damage[frames]
		DecreaseDamage	= 8,					--Start decreasing damage[frames]
	},
})

function SWEP:SharedInit()
	self.NextPlayEmpty = CurTime()
	self.AimTimer = self:AddSchedule(math.huge, function(self, schedule)
		if schedule.disabled then return end
		schedule.disabled = true
		self:SetHoldType "passive"
		self.InklingSpeed = self:GetInklingSpeed()
		if not (self:GetOnEnemyInk() or self:GetInInk()) then
			self:SetPlayerSpeed(self.InklingSpeed)
		end
	end)
end

--Playing sounds
function SWEP:SharedPrimaryAttack(canattack)
	if not self.CrouchPriority then
		self:SetHoldType(self.HoldType)
		self.InklingSpeed = self.Primary.MoveSpeed
		if not self:GetOnEnemyInk() then self:SetPlayerSpeed(self.Primary.MoveSpeed) end
		self.AimTimer:SetDelay(self.Primary.AimDuration)
		self.AimTimer.disabled = false
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
		self:EmitSound "SplatoonSWEPs.Splattershot"
		if CLIENT then self.PreviousInk = true end
	end
end

function SWEP:SharedSecondaryAttack(canattack)
	ss:ClearAllInk()
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "ModifyWeaponSize") --Shooter expands its model when firing.
end
