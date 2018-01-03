
function SWEP:CustomPrimary(p, info)
	p.Straight = SplatoonSWEPs:FrameToSec(info.Delay.Straight)
	p.Damage = info.Damage
	p.MinDamage = info.MinDamage
	p.InkRadius = info.InkRadius / 2
	p.MinRadius = info.MinRadius / 2
	p.SplashRadius = info.SplashRadius / 2
	p.SplashPatterns = info.SplashPatterns
	p.SplashNum = info.SplashNum
	p.SplashInterval = info.SplashInterval
	p.Spread = info.Spread
	p.SpreadJump = info.SpreadJump
	p.SpreadBias = info.SpreadBias
	p.MoveSpeed = SplatoonSWEPs.ToHammerUnits * info.MoveSpeed * 60
	p.MinDamageTime = SplatoonSWEPs:FrameToSec(info.Delay.MinDamage)
	p.DecreaseDamage = SplatoonSWEPs:FrameToSec(info.Delay.DecreaseDamage)
	p.InitVelocity = info.InitVelocity
	p.FirePosition = info.FirePosition
end

SWEP.Spawnable = true
SWEP.Base = "inklingbase"
SplatoonSWEPs.SetPrimary(SWEP, {
	Recoil				= .2,					--Viewmodel recoil intensity
	TakeAmmo			= .9,					--Ink consumption per fire[%]
	PlayAnimPercent		= 0,					--Play PLAYER_ATTACK1 animation frequency[%]
	FirePosition		= Vector(0, -6, -9),	--Ink spawn position
	Damage				= 36,					--Maximum damage[units]
	MinDamage			= 18,					--Minimum damage[units]
	InkRadius			= 100.8,				--Painting radius[units]
	MinRadius			= 94.5,					--Minimum painting radius[units]
	SplashRadius		= 68.25,				--Painting radius[units]
	SplashPatterns		= 5,					--Paint patterns
	SplashNum			= 2,					--Number of splashes
	SplashInterval		= 393.75,				--Make an interval on each splash
	Spread				= 6,					--Aim cone[deg]
	SpreadJump			= 15,					--Aim cone while jumping[deg]
	SpreadBias			= .25,					--Aim cone random component[deg]
	MoveSpeed			= .72,					--Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 6929.13408,			--Ink initial velocity[units/s]	
	Delay = {
		Fire			= 6,					--Fire rate[frames]
		Reload			= 20,					--Start reloading after firing weapon[frames]
		Crouch			= 10,					--Can't crouch for some frames after firing
		Straight		= 4,					--Ink goes without gravity[frames]
		MinDamage		= 15,					--Deals minimum damage[frames]
		DecreaseDamage	= 8,					--Start decreasing damage[frames]
	},
})

function SWEP:SharedInit()
	self.NextPlayEmpty = CurTime()
end

--Playing sounds
function SWEP:SharedPrimaryAttack(canattack)
	if self:GetInk() <= 0 then
		if CLIENT and self.PreviousInk then
			surface.PlaySound(SplatoonSWEPs.TankEmpty)
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
			self.PreviousInk = false
		elseif SERVER and CurTime() > self.NextPlayEmpty then
			self:EmitSound "SplatoonSWEPs.EmptyShot"
			self.NextPlayEmpty = CurTime() + self.Primary.Delay * 2
		end
	elseif canattack then
		self:EmitSound "SplatoonSWEPs.Splattershot"
		if CLIENT then self.PreviousInk = true end
	end
end

function SWEP:SharedSecondaryAttack(canattack)
	SplatoonSWEPs:ClearAllInk()
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "ModifyWeaponSize") --Shooter expands its model when firing.
end
