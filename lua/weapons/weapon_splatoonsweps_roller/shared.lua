
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_inklingbase"
SWEP.MODE = {READY = 0, ATTACK = 1, PAINT = 2}
SWEP.CollapseRollTime = 10 * ss.FrameToSec
SWEP.PreSwingTime = 10 * ss.FrameToSec
SWEP.SwingAnimTime = 10 * ss.FrameToSec
SWEP.SwingBackWait = 20 * ss.FrameToSec

function SWEP:AddPlaylist(p)
	p[#p + 1] = self.EmptyRollSound
	p[#p + 1] = self.RollingSound
end

function SWEP:SharedInit()
	self.EmptyRollSound = CreateSound(self, ss.EmptyRoll)
	self.RollingSound = CreateSound(self, self.RollSound)
	self:SetStartTime(CurTime())
	self:SetEndTime(CurTime())
	self:SetMode(self.MODE.READY)
end

function SWEP:SharedPrimaryAttack(able, auto)
	if not IsValid(self.Owner) then return end
	if self:GetMode() > self.MODE.READY then return end
	local p = self.Primary
	local timescale = ss.GetTimeScale(self.Owner)
	self:SetMode(self.MODE.ATTACK)
	self:SetStartTime(CurTime())
	self:SetEndTime(CurTime() + p.SwingWaitTime)
	self:SetInk(math.max(0, self:GetInk() - self:GetTakeAmmo()))
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	if not self:IsFirstTimePredicted() then return end
	self:EmitSound(self.PreSwingSound)
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "StartTime")
	self:AddNetworkVar("Float", "EndTime")
	self:AddNetworkVar("Int", "Mode")
end

function SWEP:CustomActivity() return "melee2" end
function SWEP:CustomMoveSpeed() end
function SWEP:Move(ply, mv)
	local mode = self:GetMode()
	local keyrelease = not (ply:IsPlayer() and self:GetKey() == IN_ATTACK)
	if mode == self.MODE.PAINT then
		if keyrelease and CurTime() > self:GetEndTime() + self.SwingBackWait then
			self:SetMode(self.MODE.READY)
			self:SetWeaponAnim(ACT_VM_IDLE)
			self:SetStartTime(CurTime())
			self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
			if self:IsFirstTimePredicted() then
				self:EmitSound "SplatoonSWEPs.RollerHolster"
			end
		end

		local s = self:GetInk() > 0 and self.RollingSound or self.EmptyRollSound
		local v = ply:OnGround() and 1 or 0
		if ply:IsPlayer() then
			v = v * math.abs(mv:GetForwardSpeed()) / ply:GetMaxSpeed()
		elseif ply:IsNPC() and isfunction(ply.IsMoving) then
			v = v * (ply:IsMoving() and 1 or 0)
		end

		s:ChangeVolume(v)
	else
		self.RollingSound:ChangeVolume(0)
		self.EmptyRollSound:ChangeVolume(0)
	end

	if mode ~= self.MODE.READY then
		self:SetCooldown(CurTime() + FrameTime())
	end

	if mode ~= self.MODE.ATTACK then return end
	if CurTime() < self:GetEndTime() then return end
	self:SetMode(self.MODE.PAINT)
	self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)
	if not self:IsFirstTimePredicted() then return end
	self:EmitSound(self.SwingSound)
	self:EmitSound(self.SplashSound)
end

function SWEP:UpdateAnimation(ply, velocity, maxseqspeed)
	local mode = self:GetMode()
	local ct = CurTime() + (self:IsMine() and self:Ping() or 0)
	local start, duration, c1, c2
	if mode == self.MODE.READY then
		return
	elseif mode == self.MODE.ATTACK then
		start = self:GetStartTime()
		duration = self.PreSwingTime
		c1, c2 = 0, .3
	else
		start = self:GetEndTime()
		duration = self.SwingAnimTime
		c1, c2 = .3, .6125
	end

	local f = math.TimeFraction(start, start + duration, ct)
	local cycle = Lerp(math.EaseInOut(math.Clamp(f, 0, 1), 0, 1), c1, c2)
	ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, ply:SelectWeightedSequence(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2), cycle, true)
end
