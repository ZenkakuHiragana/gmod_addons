
local ss = SplatoonSWEPs
if not ss then return end
ss:AddTimerFramework(SWEP)
local function PlayLoopSound(self)
	if not self.SwimSound:IsPlaying() then
		self.SwimSound:Play()
		self.SwimSound:ChangeVolume(0)
	end
	
	if not self.EnemyInkSound:IsPlaying() then
		self.EnemyInkSound:Play()
		self.EnemyInkSound:ChangeVolume(0)
	end
end

local function StopLoopSound(self)
	if self.SwimSound:IsPlaying() then
		self.SwimSound:ChangeVolume(0)
		self.SwimSound:Stop()
	end
	
	if self.EnemyInkSound:IsPlaying() then
		self.EnemyInkSound:ChangeVolume(0)
		self.EnemyInkSound:Stop()
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

-- Speed on humanoid form = base speed * ability factor
function SWEP:GetInklingSpeed()
	return ss.InklingBaseSpeed
end

-- Speed on squid form = base speed * ability factor
function SWEP:GetSquidSpeed()
	return ss.SquidBaseSpeed
end

-- Returns the owner ping in seconds.
-- Returns 0 if the owner is invalid or an NPC.
function SWEP:Ping()
	return self.Owner:IsPlayer() and self.Owner:Ping() / 1000 or 0
end

function SWEP:Crouching()
	return Either(self.Owner:IsPlayer(), ss:ProtectedCall(self.Owner.Crouching, self.Owner), self.Owner:IsFlagSet(FL_DUCKING))
end

function SWEP:GetLaggedMovementValue()
	return self.Owner:IsPlayer() and self.Owner:GetLaggedMovementValue() or 1
end

-- When NPC weapon is picked up by player.
function SWEP:OwnerChanged()
	if not IsValid(self.Owner) then
		if SERVER then
			timer.Simple(5, function()
				if not IsValid(self) or IsValid(self.Owner) then return end
				self:Remove()
			end)
		end
		return StopLoopSound(self)
	else
		return PlayLoopSound(self)
	end
end

function SWEP:SharedInitBase()
	self.ValidKey = 0
	self.OldKey = 0
	self.SwimSound = CreateSound(self, ss.SwimSound)
	self.EnemyInkSound = CreateSound(self, ss.EnemyInkSound)
	ss:ProtectedCall(self.SharedInit, self)
end

-- Predicted hooks
function SWEP:SharedDeployBase()
	PlayLoopSound(self)
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
	
	ss:ProtectedCall(self.SharedDeploy, self)
	return true
end

function SWEP:SharedHolsterBase()
	ss:ProtectedCall(self.SharedHolster, self)
	self:SetHolstering(true)
	StopLoopSound(self)
	return true
end

function SWEP:SharedThinkBase()
	ss:ProtectedCall(self.SharedThink, self)
end

-- Begin to use special weapon.
function SWEP:Reload()
	if self:GetHolstering() then return end
	if game.SinglePlayer() and
	self.Owner:IsPlayer() and
	IsValid(self.Owner) then
		self:CallOnClient "Reload"
	end
end

function SWEP:CommonFire(Weapon)
	local lv = self:GetLaggedMovementValue()
	if self.Owner:IsPlayer() then
		local plmins, plmaxs = self.Owner:GetHull()
		self.CannotStandup = self:Crouching() and util.TraceHull {
			start = self.Owner:GetPos(),
			endpos = self.Owner:GetPos(),
			mins = plmins, maxs = plmaxs,
			filter = {self, self.Owner},
			mask = MASK_PLAYERSOLID,
			collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
		} .Hit
		
		if self.CannotStandup then return false end
	end
	
	local reloadtime = Weapon.ReloadDelay / lv
	self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
	self.ReloadSchedule.prevtime = CurTime() + reloadtime
	self:SetNextCrouchTime(CurTime() + Weapon.CrouchDelay / lv) -- Prevent crouching
	
	local hasink = self:GetInk() > 0 -- Ink check
	if hasink then self:SetNextPrimaryFire(CurTime() + Weapon.Delay / lv) end
	return hasink
end

function SWEP:PrimaryAttack() -- Shoot ink.
	if self:GetHolstering() then return end
	local canattack = self:CommonFire(self.Primary)
	if self.Owner:IsPlayer() then self:CallOnClient "PrimaryAttack" end
	if self.CannotStandup then return end
	ss:ProtectedCall(self.SharedPrimaryAttack, self, canattack)
	ss:ProtectedCall(Either(SERVER, self.ServerPrimaryAttack, self.ClientPrimaryAttack), self, canattack)
	if CLIENT then return end
	net.Start "SplatoonSWEPs: Client PrimaryAttack"
	net.WriteEntity(self.Owner)
	net.Send(ss.PlayersReady)
end

function SWEP:SecondaryAttack() -- Use sub weapon
	if self:GetHolstering() then return end
	local canattack = self:CommonFire(self.Secondary)
	if self.Owner:IsPlayer() then self:CallOnClient "SecondaryAttack" end
	if self.CannotStandup or not (canattack and
	(SERVER or self:IsFirstTimePredicted())) then return end
	self:SetThrowing(true)
	self:SetHoldType "grenade"
	self:AddSchedule(0, function(self, sched)
		self:SetNextPrimaryFire(CurTime() + 1)
		if self.Owner:KeyDown(IN_ATTACK2) then
			self:SetHoldType "grenade"
			return
		elseif not self:GetThrowing() or self:Crouching() then
			self:SetThrowing(false)
			return true
		end
		
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		self:SetNextSecondaryFire(CurTime() + 1)
		self:AddSchedule(.6, 1, function(self, sched)
			self:SetThrowing(self.Owner:KeyDown(IN_ATTACK2))
			self:SetHoldType(self:GetThrowing() and "grenade" or "passive")
		end)
		
		ss:ProtectedCall(self.SharedSecondaryAttack, self, canattack)
		ss:ProtectedCall(Either(SERVER, self.ServerSecondaryAttack, self.ClientSecondaryAttack), self, canattack)
		return true
	end)
end
-- End of predicted hooks

local NetworkVarNotifyCallsOnClient = false
function SWEP:ChangeInInk(name, old, new)
	if self:GetHolstering() then return end
	if not NetworkVarNotifyCallsOnClient then
		if SERVER then
			if IsValid(self.Owner) and self.Owner:IsPlayer() then
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
	if outofink == intoink then return
	elseif self.Owner:IsPlayer() then
		self.Owner:SetCrouchedWalkSpeed(intoink and 1 or .5)
		self:SetPlayerSpeed(intoink and self.SquidSpeed or self.InklingSpeed)
	end
	
	if CLIENT then return end
	if intoink then
		if self.Owner:IsPlayer() then self.Owner:SetDSP(14) end
		local velocity = math.abs(self.OwnerVelocity.z)
		if self.Owner:OnGround() and velocity > 400 then
			local dp = math.Clamp(600 - velocity, 0, 200) / 2
			self.Owner:EmitSound("SplatoonSWEPs_Player.InkDiveDeep", 75, 100 + dp, .5, CHAN_BODY)
		else
			local dp = 50 - velocity / 4
			self.Owner:EmitSound("SplatoonSWEPs_Player.InkDiveShallow", 75, 100 + dp, .5, CHAN_BODY)
		end
	elseif outofink and self.Owner:IsPlayer() then
		self.Owner:SetDSP(1)
	end
end

function SWEP:ChangeOnEnemyInk(name, old, new)
	if self:GetHolstering() then return end
	if not NetworkVarNotifyCallsOnClient then
		if SERVER then
			if IsValid(self.Owner) and self.Owner:IsPlayer() then
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
			self:SetPlayerSpeed(self.OnEnemyInkSpeed) -- Hard to move while in enemy ink
			self.Owner:SetJumpPower(self.OnEnemyInkJumpPower) -- Reduce jump power
		end
		
		if CLIENT then return end
		self:AddSchedule(200 / ss.ToHammerHealth * ss.FrameToSec, function(self, schedule)
			if not self:GetOnEnemyInk() then return true end -- Enemy ink damage
			local d = DamageInfo()
			d:SetAttacker(game.GetWorld())
			d:SetDamage(self.Owner:Health() > self.Owner:GetMaxHealth() / 2 and 1 or 0)
			d:SetInflictor(self.Owner)
			self.Owner:TakeDamageInfo(d)
		end)
		
		self:AddSchedule(20 * ss.FrameToSec, 1, function(self, schedule)
			self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
		end)
	else
		self.EnemyInkSound:ChangeVolume(0, .5)
		if self.Owner:IsPlayer() then
			self:SetPlayerSpeed(self:GetInInk() and self.SquidSpeed or self.InklingSpeed)
			self.Owner:SetJumpPower(self.JumpPower) -- Restore
		end
	end
end

local ReloadMultiply = ss.MaxInkAmount / 10 -- Reloading rate(inkling)
local HealingDelay = 10 / ss.ToHammerHealth -- Healing rate(inkling)
function SWEP:SetupDataTables()
	self.FunctionQueue = {}
	self:AddNetworkVar("Bool", "InInk") -- If owner is in ink.
	self:AddNetworkVar("Bool", "InFence") -- If owner is in fence.
	self:AddNetworkVar("Bool", "InWallInk") -- If owner is on wall.
	self:AddNetworkVar("Bool", "OnEnemyInk") -- If owner is on enemy ink.
	self:AddNetworkVar("Bool", "Holstering") -- The weapon is being holstered.
	self:AddNetworkVar("Bool", "Throwing") -- Is about to use sub weapon.
	self:AddNetworkVar("Float", "Ink") -- Ink remainig. 0 to ss.MaxInkAmount
	self:AddNetworkVar("Vector", "InkColorProxy") -- For material proxy.
	self:AddNetworkVar("Float", "NextCrouchTime") -- Shooting cooldown.
	self:AddNetworkVar("Int", "GroundColor") -- Surface ink color.
	self:AddNetworkVar("Int", "PMID") -- Playermodel ID
	self.HealSchedule = self:AddNetworkSchedule(HealingDelay, function(self, schedule)
		local canheal = self.CanHealInk and self:GetInInk() -- Gradually heals the owner
		local laggedvalue = self:GetLaggedMovementValue()
		schedule:SetDelay(HealingDelay / (canheal and 8 or 1) / laggedvalue)
		if not self:GetOnEnemyInk() and (self.CanHealStand or canheal) then
			self.Owner:SetHealth(math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth()))
		end
	end)
	
	self.ReloadSchedule = self:AddNetworkSchedule(0, function(self, schedule)
		local reloadamount = math.max(0, schedule:SinceLastCalled()) -- Recharging ink
		local fastreload = self.CanReloadInk and self:GetInInk()
		local laggedvalue = self:GetLaggedMovementValue()
		local mul = ReloadMultiply * (fastreload and 10/3 or 1) * laggedvalue
		if self.CanReloadStand or fastreload then
			self:SetInk(math.Clamp(self:GetInk() + reloadamount * mul, 0, ss.MaxInkAmount))
		end
		
		schedule:SetDelay(0)
	end)
	
	self:NetworkVarNotify("InInk", self.ChangeInInk)
	self:NetworkVarNotify("OnEnemyInk", self.ChangeOnEnemyInk)
	ss:ProtectedCall(self.CustomDataTables, self)
end
