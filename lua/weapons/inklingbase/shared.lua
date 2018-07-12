
include "sh_anim.lua"

local ss = SplatoonSWEPs
if not ss then return end

ss:AddTimerFramework(SWEP)
local KeyMask = {IN_ATTACK, IN_DUCK, IN_ATTACK2}
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

function SWEP:IsMine()
	return SERVER or LocalPlayer() == self.Owner
end

function SWEP:IsFirstTimePredicted()
	return SERVER or game.SinglePlayer() or IsFirstTimePredicted() or self.Owner ~= LocalPlayer()
end

function SWEP:CheckButtons(key)
	if not IsValid(self.Owner) then return end
	if not self.Owner:IsPlayer() then return true end
	if not self:IsMine() then return true end
	local neutral = true
	local keytable, keytime = {}, {}
	for _, k in ipairs(KeyMask) do
		local last = bit.band(self.OldButtons, k) == 0
		if bit.band(self.Buttons, k) > 0 then
			if last then self.LastKeyDown[k] = CurTime() end
			table.insert(keytime, self.LastKeyDown[k])
		end
		
		neutral = neutral and last
		keytable[self.LastKeyDown[k]] = k -- [Last time key down] = key
	end
	
	self.ValidKey = keytable[math.max(unpack(keytime))] or 0
	self.EnemyInkPreventCrouching = self.EnemyInkPreventCrouching and self:GetOnEnemyInk() and bit.band(self.Buttons, IN_DUCK) > 0
	self.PreventCrouching = self.ValidKey ~= 0 and self.ValidKey ~= IN_DUCK or CurTime() < self.Cooldown
	return self.ValidKey == key
end

function SWEP:ChangeViewModel(act)
	if not act then act = self.ViewAnim
	elseif self.ViewAnim == act then return end
	self.ViewAnim = act
	self:SendWeaponAnim(act)
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
	return IsValid(self.Owner) and self.Owner:IsPlayer() and self.Owner:Ping() / 1000 or 0
end

function SWEP:Crouching()
	return IsValid(self.Owner) and Either(self.Owner:IsPlayer(),
	ss:ProtectedCall(self.Owner.Crouching, self.Owner), self.Owner:IsFlagSet(FL_DUCKING))
end

function SWEP:GetLaggedMovementValue()
	return IsValid(self.Owner) and self.Owner:IsPlayer()
	and self.Owner:GetLaggedMovementValue() or 1
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

local InkTraceLength = 20
local InkTraceDown = -vector_up * InkTraceLength
function SWEP:UpdateInkState() -- Set if player is in ink
	local ang = Angle(0, self.Owner:GetAngles().yaw)
	local c = self:GetColorCode()
	local filter = {self, self.Owner}
	local p = self.Owner:WorldSpaceCenter()
	local fw, right = ang:Forward() * InkTraceLength, ang:Right() * InkTraceLength
	self:SetGroundColor(ss:GetSurfaceColor(util.QuickTrace(self.Owner:GetPos(), InkTraceDown, filter)) or -1)
	local onink = self:GetGroundColor() >= 0
	local onourink = self:GetGroundColor() == c
	
	self:SetInWallInk(self:Crouching() and (
	ss:GetSurfaceColor(util.QuickTrace(p, fw - right, filter)) == c or
	ss:GetSurfaceColor(util.QuickTrace(p, fw + right, filter)) == c or
	ss:GetSurfaceColor(util.QuickTrace(p,-fw - right, filter)) == c or
	ss:GetSurfaceColor(util.QuickTrace(p,-fw + right, filter)) == c))
	
	self:SetInInk(self:Crouching() and (onink and onourink or self:GetInWallInk()))
	self:SetOnEnemyInk(onink and not onourink)
	self.OwnerVelocity = self.Owner:GetVelocity()
end

function SWEP:SharedInitBase()
	self.Cooldown = CurTime()
	self.SwimSound = CreateSound(self, ss.SwimSound)
	self.EnemyInkSound = CreateSound(self, ss.EnemyInkSound)
	self.Buttons, self.OldButtons = 0, 0
	self.LastKeyDown = {}
	for _, k in ipairs(KeyMask) do
		self.LastKeyDown[k] = CurTime()
	end
	
	local translate = {}
	for _, t in ipairs {"crossbow", "grenade", "melee2", "passive", "rpg", "smg"} do
		self:SetWeaponHoldType(t)
		translate[t] = self.ActivityTranslate
	end
	
	self.Translate = translate
	ss:ProtectedCall(self.SharedInit, self)
end

-- Predicted hooks
function SWEP:SharedDeployBase()
	PlayLoopSound(self)
	self:SetHolstering(false)
	self.Cooldown = CurTime()
	self.InklingSpeed = self:GetInklingSpeed()
	self.SquidSpeed = self:GetSquidSpeed()
	self.OnEnemyInkSpeed = ss.OnEnemyInkSpeed
	self.JumpPower = ss.InklingJumpPower
	self.OnEnemyInkJumpPower = ss.OnEnemyInkJumpPower
	if self.Owner:IsPlayer() then
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

function SWEP:CheckCannotStandup()
	if not IsValid(self.Owner) then return end
	if not self.Owner:IsPlayer() then return end
	local plmins, plmaxs = self.Owner:GetHull()
	self.CannotStandup = self:Crouching() and util.TraceHull {
		start = self.Owner:GetPos(),
		endpos = self.Owner:GetPos(),
		mins = plmins, maxs = plmaxs,
		filter = {self, self.Owner},
		mask = MASK_PLAYERSOLID,
		collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
	} .Hit
	
	return self.CannotStandup
end

function SWEP:PrimaryAttack(auto) -- Shoot ink.  bool auto | is a scheduled shot
	if self:GetHolstering() then return end
	if self:CheckCannotStandup() then return end
	if not auto and self:IsFirstTimePredicted() and CurTime() < self.Cooldown then return end
	if not auto and self:IsFirstTimePredicted() and not self:CheckButtons(IN_ATTACK) then return end
	local hasink = self:GetInk() > 0
	local able = hasink and not self.CannotStandup
	local lv = self:GetLaggedMovementValue()
	local reloadtime = self.Primary.ReloadDelay / lv
	ss:ShouldSuppress(self.Owner)
	self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
	self.ReloadSchedule:SetLastCalled(CurTime() + reloadtime)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay / lv)
	ss:ProtectedCall(self.SharedPrimaryAttack, self, able, auto)
	ss:ProtectedCall(Either(SERVER, self.ServerPrimaryAttack, self.ClientPrimaryAttack), self, able, auto)
	if CLIENT then return end
	net.Start "SplatoonSWEPs: Client PrimaryAttack"
	net.WriteEntity(self)
	net.WriteBool(tobool(auto))
	net.Send(ss.PlayersReady)
	ss:ShouldSuppress()
end

function SWEP:SecondaryAttack() -- Use sub weapon
	if self:GetHolstering() then return end
	if self:CheckCannotStandup() then return end
	if CurTime() < self.Cooldown then return end
	if not self:CheckButtons(IN_ATTACK2) then return end
	if self.Owner:IsPlayer() then self:CallOnClient "SecondaryAttack" end
	self:SetThrowing(true)
	self:AddSchedule(0, function(self, sched)
		self:CheckButtons()
		if bit.band(self.Buttons, IN_ATTACK2) > 0 then
			if self.ValidKey == IN_ATTACK2 then return end
			if self.ValidKey == IN_DUCK then
				self:SetThrowing(false)
				return true
			end
		end
		
		local time = CurTime() + self.Secondary.Delay
		ss:ShouldSuppress(self.Owner)
		self.Cooldown = time
		self:SetNextPrimaryFire(time)
		self:SetNextSecondaryFire(time)
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		self:AddSchedule(self.Secondary.Delay, 1, function(self, sched)
			self:SetThrowing(false)
		end)
		
		local hasink = self:GetInk() > 0
		local able = hasink and not self:CheckCannotStandup()
		ss:ProtectedCall(self.SharedSecondaryAttack, self, able)
		ss:ProtectedCall(Either(SERVER, self.ServerSecondaryAttack, self.ClientSecondaryAttack), self, able)
		ss:ShouldSuppress()
		return true
	end)
end
-- End of predicted hooks

local NetworkVarNotifyNOTCalledOnClient = true
function SWEP:ChangeInInk(name, old, new)
	if self:GetHolstering() then return end
	if NetworkVarNotifyNOTCalledOnClient and CLIENT and self:IsFirstTimePredicted() then
		old, new = unpack(string.Explode(" ", name))
	end
	
	old, new = tobool(old), tobool(new)
	local outofink = old and not new
	local intoink = not old and new
	if outofink == intoink then return end
	if NetworkVarNotifyNOTCalledOnClient then
		if not self:IsFirstTimePredicted() then return end
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
			self:CallOnClient("ChangeInInk", table.concat({tostring(old), tostring(new)}, " "))
		end
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
	if NetworkVarNotifyNOTCalledOnClient and CLIENT and self:IsFirstTimePredicted() then
		old, new = unpack(string.Explode(" ", name))
	end
	
	old, new = tobool(old), tobool(new)
	local outofink = old and not new
	local intoink = not old and new
	if outofink == intoink then return end
	if NetworkVarNotifyNOTCalledOnClient then
		if not self:IsFirstTimePredicted() then return end
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
			self:CallOnClient("ChangeOnEnemyInk", table.concat({tostring(old), tostring(new)}, " "))
		end
	end
	
	if intoink then
		self.EnemyInkSound:ChangeVolume(1, .5)
		if self.Owner:IsPlayer() then
			self.Owner:SetJumpPower(self.OnEnemyInkJumpPower) -- Reduce jump power
		end
		
		if CLIENT then return end
		self:AddSchedule(200 / ss.ToHammerHealth * ss.FrameToSec, function(self, schedule)
			if not self:GetOnEnemyInk() then return true end -- Enemy ink damage
			local d = DamageInfo()
			d:SetAttacker(game.GetWorld())
			d:SetDamage(self.Owner:Health() > self.Owner:GetMaxHealth() / 2 and 1 or 0)
			d:SetInflictor(self)
			self.Owner:TakeDamageInfo(d)
		end)
		
		self:AddSchedule(20 * ss.FrameToSec, 1, function(self, schedule)
			self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
		end)
	else
		self.EnemyInkSound:ChangeVolume(0, .5)
		if self.Owner:IsPlayer() then
			self.Owner:SetJumpPower(self.JumpPower) -- Restore
		end
	end
end

local ReloadMultiply = ss.MaxInkAmount / 10 -- Reloading rate(inkling)
local HealingDelay = 10 / ss.ToHammerHealth -- Healing rate(inkling)
function SWEP:SetupDataTables()
	self:AddNetworkVar("Bool", "AvoidWalls")
	self:AddNetworkVar("Bool", "BecomeSquid")
	self:AddNetworkVar("Bool", "CanHealStand")
	self:AddNetworkVar("Bool", "CanHealInk")
	self:AddNetworkVar("Bool", "CanReloadStand")
	self:AddNetworkVar("Bool", "CanReloadInk")
	self:AddNetworkVar("Bool", "InInk") -- If owner is in ink.
	self:AddNetworkVar("Bool", "InFence") -- If owner is in fence.
	self:AddNetworkVar("Bool", "InWallInk") -- If owner is on wall.
	self:AddNetworkVar("Bool", "OnEnemyInk") -- If owner is on enemy ink.
	self:AddNetworkVar("Bool", "Holstering") -- The weapon is being holstered.
	self:AddNetworkVar("Bool", "Throwing") -- Is about to use sub weapon.
	self:AddNetworkVar("Float", "Ink") -- Ink remainig. 0 to ss.MaxInkAmount
	self:AddNetworkVar("Int", "ColorCode")
	self:AddNetworkVar("Int", "GroundColor") -- Surface ink color.
	self:AddNetworkVar("Int", "PMID") -- Playermodel ID
	self:AddNetworkVar("Vector", "InkColorProxy") -- For material proxy.
	self.HealSchedule = self:AddNetworkSchedule(HealingDelay, function(self, schedule)
		local canheal = self:GetCanHealInk() and self:GetInInk() -- Gradually heals the owner
		local lv = self:GetLaggedMovementValue()
		local delay = HealingDelay / lv / (canheal and 8 or 1)
		if schedule:GetDelay() ~= delay then schedule:SetDelay(delay) end
		if not self:GetOnEnemyInk() and (self:GetCanHealStand() or canheal) then
			local health = math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth())
			if self.Owner:Health() ~= health then self.Owner:SetHealth(health) end
		end
	end)
	
	self.ReloadSchedule = self:AddNetworkSchedule(0, function(self, schedule)
		local reloadamount = math.max(0, schedule:SinceLastCalled()) -- Recharging ink
		local fastreload = self:GetCanReloadInk() and self:GetInInk()
		local lv = self:GetLaggedMovementValue()
		local mul = ReloadMultiply * (fastreload and 10/3 or 1) * lv
		if self:GetCanReloadStand() or fastreload then
			local ink = math.Clamp(self:GetInk() + reloadamount * mul, 0, ss.MaxInkAmount)
			if self:GetInk() ~= ink then self:SetInk(ink) end
		end
		
		if schedule:GetDelay() == 0 then return end
		schedule:SetDelay(0)
	end)
	
	self:NetworkVarNotify("InInk", self.ChangeInInk)
	self:NetworkVarNotify("OnEnemyInk", self.ChangeOnEnemyInk)
	ss:ProtectedCall(self.CustomDataTables, self)
end
