
local ss = SplatoonSWEPs
ss:AddTimerFramework(SWEP)
function SWEP:ChangeHullDuck()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
	if self:GetPMID() ~= ss.PLAYER.NOSQUID then
		self.Owner:SetHullDuck(ss.SquidBoundMins, ss.SquidBoundMaxs)
		self.Owner:SetViewOffsetDucked(ss.SquidViewOffset)
	end
end

function SWEP:ChangeViewModel(act)
	if self.ViewAnim == act then return end
	self.ViewAnim = act
	self:SendWeaponAnim(act)
end

function SWEP:SetPlayerSpeed(spd)
	self.MaxSpeed = spd
	if not self.Owner:IsPlayer() then return end
	self.Owner:SetMaxSpeed(self.MaxSpeed)
	self.Owner:SetRunSpeed(self.MaxSpeed)
	self.Owner:SetWalkSpeed(self.MaxSpeed)
end

--Speed on humanoid form = base speed * ability factor
function SWEP:GetInklingSpeed()
	return ss.InklingBaseSpeed
end

--Speed on squid form = base speed * ability factor
function SWEP:GetSquidSpeed()
	return ss.SquidBaseSpeed
end

--When NPC weapon is picked up by player.
function SWEP:OwnerChanged()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
end

function SWEP:SharedInitBase()
	self.SwimSound = CreateSound(self, ss.SwimSound)
	self.EnemyInkSound = CreateSound(self, ss.EnemyInkSound)
	if isfunction(self.SharedInit) then return self:SharedInit() end
end

--Predicted hooks
function SWEP:SharedDeployBase()
	if not self.SwimSound:IsPlaying() then
		self.SwimSound:Play()
		self.SwimSound:ChangeVolume(0)
	end
	
	if not self.EnemyInkSound:IsPlaying() then
		self.EnemyInkSound:Play()
		self.EnemyInkSound:ChangeVolume(0)
	end
	
	self:SetHolstering(false)
	self.InklingSpeed = self:GetInklingSpeed()
	self.SquidSpeed = self:GetSquidSpeed()
	self.SquidSpeedSqr = self.SquidSpeed^2
	self.OnEnemyInkSpeed = ss.OnEnemyInkSpeed
	self.JumpPower = ss.InklingJumpPower
	self.OnEnemyInkJumpPower = ss.OnEnemyInkJumpPower
	if self.Owner:IsPlayer() then
		self:SetPlayerSpeed(self.InklingSpeed)
		self.Owner:SetJumpPower(self.JumpPower)
		self.Owner:SetColor(color_white)
		self.Owner:SetCrouchedWalkSpeed(.5)
	end
	
	if isfunction(self.SharedDeploy) then self:SharedDeploy() end
	return true
end

function SWEP:SharedHolsterBase()
	if self.SwimSound:IsPlaying() then
		self.SwimSound:ChangeVolume(0)
		self.SwimSound:Stop()
	end
	
	if self.EnemyInkSound:IsPlaying() then
		self.EnemyInkSound:ChangeVolume(0)
		self.EnemyInkSound:Stop()
	end
	
	if isfunction(self.SharedHolster) then self:SharedHolster() end
	self:SetHolstering(true)
	return true
end

local inklingVM = ACT_VM_IDLE --Viewmodel animation(humanoid)
local squidVM = ACT_VM_HOLSTER --Viewmodel animation(squid)
local throwingVM = ACT_VM_IDLE_LOWERED --Viewmodel animation(throwing sub weapon)
function SWEP:SharedThinkBase()
	if SERVER or self:IsFirstTimePredicted() then
		local sq = self.Owner:IsPlayer()
		if sq then
			sq = self.Owner:Crouching()
		else
			sq = self.Owner:GetFlags(FL_DUCKING)
		end
	
		--Send viewmodel animation.
		self:ChangeViewModel(self.IsSquid and squidVM or inklingVM)
		if sq then
			self.SwimSound:ChangeVolume(not self:GetInInk() and 0 or
			self.Owner:GetVelocity():LengthSqr() / self.SquidSpeedSqr)
			if not self.IsSquid then
				self.Owner:RemoveAllDecals()
				if CLIENT then self.Owner:EmitSound "SplatoonSWEPs_Player.ToSquid" end
			end
			
			if self:GetOnEnemyInk() then
				self:AddSchedule(20 * ss.FrameToSec, 1, function(self, schedule)
					self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
				end)
			end
		elseif not sq and self.IsSquid then
			self.SwimSound:ChangeVolume(0)
			if CLIENT then self.Owner:EmitSound "SplatoonSWEPs_Player.ToHuman" end
		end
		
		self.IsSquid = sq
	end
	if isfunction(self.SharedThink) then return self:SharedThink() end
end

--Begin to use special weapon.
function SWEP:Reload()
	if self:GetHolstering() then return end
	if game.SinglePlayer() and IsValid(self.Owner) then self:CallOnClient "Reload" end
	
end

function SWEP:CommonFire(isprimary)
	if self.Owner:IsPlayer() then
		local plmins, plmaxs = self.Owner:GetHull()
		self.CannotStandup = self.Owner:Crouching() and util.TraceHull {
			start = self.Owner:GetPos(),
			endpos = self.Owner:GetPos(),
			mins = plmins, maxs = plmaxs,
			filter = {self, self.Owner}
		} .Hit
	end
	
	if self.CannotStandup or self.CrouchPriority then return false end
	local Weapon = isprimary and self.Primary or self.Secondary
	local laggedvalue = self.Owner:IsPlayer() and self.Owner:GetLaggedMovementValue() or 1
	self.ReloadSchedule:SetDelay(Weapon.ReloadDelay / laggedvalue)
	self.ReloadSchedule.prevtime = CurTime() + Weapon.ReloadDelay / laggedvalue
	self:SetNextCrouchTime(CurTime() + Weapon.CrouchDelay / laggedvalue)
	
	if self:GetInk() <= 0 then return false end --Check remaining amount of ink
	self:SetNextPrimaryFire(CurTime() + Weapon.Delay / laggedvalue)
	self:MuzzleFlash()
	
	if self.Owner:IsPlayer() then
		local rnda = Weapon.Recoil * -1
		local rndb = Weapon.Recoil * util.SharedRandom(
		"SplatoonSWEPs: Weapon base recoil" .. self:EntIndex(), -1, 1)
		self.Owner:ViewPunch(Angle(rnda, rndb, rnda)) --Apply viewmodel punch
		if math.random() < Weapon.PlayAnimPercent then
			self.Owner:SetAnimation(PLAYER_ATTACK1)
		end
	end
	
	return true
end

--Shoot ink.
function SWEP:PrimaryAttack()
	if self:GetHolstering() then return end
	local canattack = self:CommonFire(true)
	if game.SinglePlayer() then self:CallOnClient "PrimaryAttack" end
	if self.CannotStandup then return end
	if isfunction(self.SharedPrimaryAttack) then self:SharedPrimaryAttack(canattack) end
	if SERVER and isfunction(self.ServerPrimaryAttack) then
		return self:ServerPrimaryAttack(canattack)
	elseif CLIENT and isfunction(self.ClientPrimaryAttack) then
		return self:ClientPrimaryAttack(canattack)
	end
end

--Use sub weapon
function SWEP:SecondaryAttack()
	if self:GetHolstering() then return end
	local canattack = self:CommonFire(false)
	if game.SinglePlayer() then self:CallOnClient "SecondaryAttack" end
	if self.CannotStandup then return end
	if isfunction(self.SharedSecondaryAttack) then self:SharedSecondaryAttack(canattack) end
	if SERVER and isfunction(self.ServerSecondaryAttack) then
		return self:ServerSecondaryAttack(canattack)
	elseif CLIENT and isfunction(self.ClientSecondaryAttack) then
		return self:ClientSecondaryAttack(canattack)
	end
end
--End of predicted hooks

local NetworkVarNotifyCallsOnClient = false
function SWEP:ChangeInInk(name, old, new)
	if self:GetHolstering() then return end
	if not NetworkVarNotifyCallsOnClient then
		if SERVER then
			if IsValid(self.Owner) then
				self:CallOnClient("ChangeInInk", table.concat({name, tostring(old), tostring(new)}, " "))
			end
		elseif self:IsFirstTimePredicted() then
			old, new = select(2, unpack(string.Explode(" ", name)))
		else
			return
		end
	end
	
	old, new = tobool(old), tobool(new)
	local outofink = old and not new
	local intoink = not old and new
	if outofink == intoink then return end
	if self.Owner:IsPlayer() then
		self.Owner:SetCrouchedWalkSpeed(intoink and 1 or .5)
		self:SetPlayerSpeed(intoink and self.SquidSpeed or self.InklingSpeed)
	end
	
	if intoink and SERVER then
		if self.Owner:IsPlayer() then self.Owner:SetDSP(14) end
		local velocity = math.abs(self.OwnerVelocity.z)
		if self.Owner:OnGround() and velocity > 400 then
			local dp = math.Clamp(600 - velocity, 0, 200) / 2
			self.Owner:EmitSound("SplatoonSWEPs_Player.InkDiveDeep", 75, 100 + dp, .5, CHAN_BODY)
		else
			local dp = 50 - velocity / 4
			self.Owner:EmitSound("SplatoonSWEPs_Player.InkDiveShallow", 75, 100 + dp, .5, CHAN_BODY)
		end
	elseif outofink then
		if SERVER and self.Owner:IsPlayer() then self.Owner:SetDSP(1) end
		self.OnOutOfInk = true
	end
end

function SWEP:ChangeOnEnemyInk(name, old, new)
	if self:GetHolstering() then return end
	if not NetworkVarNotifyCallsOnClient then
		if SERVER then
			if IsValid(self.Owner) then
				self:CallOnClient("ChangeOnEnemyInk", table.concat({name, tostring(old), tostring(new)}, " "))
			end
		elseif self:IsFirstTimePredicted() then
			old, new = select(2, unpack(string.Explode(" ", name)))
		else
			return
		end
	end
	
	old, new = tobool(old), tobool(new)
	local outofink = old and not new
	local intoink = not old and new
	if outofink == intoink then return
	elseif intoink then
		self.EnemyInkSound:ChangeVolume(1, .5)
		if self.Owner:IsPlayer() then
			self:SetPlayerSpeed(self.OnEnemyInkSpeed) --Hard to move
			self.Owner:SetJumpPower(self.OnEnemyInkJumpPower) --Reduce jump power
		end
		
		if CLIENT then return end
		self:AddSchedule(200 / ss.ToHammerHealth * ss.FrameToSec, function(self, schedule)
			if not self:GetOnEnemyInk() then return true end --Enemy ink damage
			if self.Owner:Health() > self.Owner:GetMaxHealth() / 2 then
				self.Owner:SetHealth(self.Owner:Health() - 1)
			end
		end)
		
		self:AddSchedule(20 * ss.FrameToSec, 1, function(self, schedule)
			self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
		end)
	else
		self.EnemyInkSound:ChangeVolume(0, .5)
		if self.Owner:IsPlayer() then
			self:SetPlayerSpeed(self:GetInInk() and self.SquidSpeed or self.InklingSpeed)
			self.Owner:SetJumpPower(self.JumpPower) --Restore
		end
	end
end

local ReloadMultiply = ss.MaxInkAmount / 10 --Reloading rate(inkling)
local HealingDelay = 10 / ss.ToHammerHealth --Healing rate(inkling)
function SWEP:SetupDataTables()
	ss:AddNetworkVar(self)
	self.FunctionQueue = {}
	self:AddNetworkVar("Bool", "InInk") --If owner is in ink.
	self:AddNetworkVar("Bool", "InWallInk") --If owner is on wall.
	self:AddNetworkVar("Bool", "OnEnemyInk") --If owner is on enemy ink.
	self:AddNetworkVar("Bool", "Holstering") --The weapon is being holstered.
	self:AddNetworkVar("Float", "Ink") --Ink remainig. 0 ~ ss.MaxInkAmount
	self:AddNetworkVar("Vector", "InkColorProxy") --For material proxy.
	self:AddNetworkVar("Float", "NextCrouchTime") --Shooting cooldown.
	self:AddNetworkVar("Int", "GroundColor") --Surface ink color.
	self:AddNetworkVar("Int", "PMID") --Playermodel ID
	self.HealSchedule = self:AddNetworkSchedule(HealingDelay, function(self, schedule)
		local canheal = self.CanHealInk and self:GetInInk() --Gradually heals the owner
		local laggedvalue = self.Owner:IsPlayer() and self.Owner:GetLaggedMovementValue() or 1
		schedule:SetDelay(HealingDelay / (canheal and 8 or 1) / laggedvalue)
		if not self:GetOnEnemyInk() and (self.CanHealStand or canheal) then
			self.Owner:SetHealth(math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth()))
		end
	end)
	
	self.ReloadSchedule = self:AddNetworkSchedule(0, function(self, schedule)
		local reloadamount = math.max(0, schedule:SinceLastCalled()) --Recharging ink
		local fastreload = self.CanReloadInk and self:GetInInk()
		local laggedvalue = self.Owner:IsPlayer() and self.Owner:GetLaggedMovementValue() or 1
		local mul = ReloadMultiply * (fastreload and 10/3 or 1) * laggedvalue
		if self.CanReloadStand or fastreload then
			self:SetInk(math.Clamp(self:GetInk() + reloadamount * mul, 0, ss.MaxInkAmount))
		end
		
		schedule:SetDelay(0)
	end)
	
	self:NetworkVarNotify("InInk", self.ChangeInInk)
	self:NetworkVarNotify("OnEnemyInk", self.ChangeOnEnemyInk)
	if isfunction(self.CustomDataTables) then return self:CustomDataTables() end
end
