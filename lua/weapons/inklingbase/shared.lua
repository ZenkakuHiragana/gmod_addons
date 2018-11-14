
include "sh_anim.lua"

local ss = SplatoonSWEPs
if not ss then return end

ss.AddTimerFramework(SWEP)
local function PlayLoopSound(self)
	local playlist = {self.SwimSound, self.EnemyInkSound}
	ss.ProtectedCall(self.AddPlaylist, self, playlist)
	for _, s in ipairs(playlist) do
		s:PlayEx(0, 100)
	end
end

local function StopLoopSound(self)
	local playlist = {self.SwimSound, self.EnemyInkSound}
	ss.ProtectedCall(self.AddPlaylist, self, playlist)
	for _, s in ipairs(playlist) do
		s:ChangeVolume(0)
		s:Stop()
	end
end

function SWEP:IsMine()
	return SERVER or self:IsCarriedByLocalPlayer()
end

function SWEP:IsFirstTimePredicted()
	return SERVER or ss.sp or IsFirstTimePredicted() or not self:IsCarriedByLocalPlayer()
end

function SWEP:ChangeViewModel(act)
	if not act then return end
	if not self:IsFirstTimePredicted() then return end
	if SERVER then SuppressHostEvents(self.Owner) end
	self:SendWeaponAnim(act)
	if SERVER then SuppressHostEvents() end
end

function SWEP:GetBase(BaseClassName)
	BaseClassName = BaseClassName or "inklingbase"
	local base = self.BaseClass
	while base and base.Base ~= BaseClassName do
		base = base.BaseClass
	end
	
	return base
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
	ss.ProtectedCall(self.Owner.Crouching, self.Owner), self.Owner:IsFlagSet(FL_DUCKING))
end

function SWEP:GetFOV()
	return self.Owner:GetFOV()
end

local Options = {
	Playermodel = "PMID",
	InkColor = "ColorCode",
	CanHealStand = true,
	CanHealInk = true,
	CanReloadStand = true,
	CanReloadInk = true,
	BecomeSquid = true,
	AvoidWalls = true,
	Southpaw = true,
	ToggleADS = true,
}
function SWEP:GetOptions()
	if not self:IsMine() then return end
	local queue = {ss.Options}
	local getoption = {true}
	while #queue > 0 do
		local t = table.remove(queue, 1)
		local g = table.remove(getoption, 1)
		if not isfunction(g) then g = ss.GetOption end
		for name, default in pairs(t) do
			if (not istable(default) and t ~= ss.Options) or Options[name]
			or name == self.Base or name == self.ClassName then
				if istable(default) then
					table.insert(queue, default)
					table.insert(getoption, g(name))
				else
					local alias = isstring(Options[name]) and Options[name] or name
					local value = g(name, self.Owner)
					if isbool(value) then
						if self:GetNWBool(alias) ~= value then
							self:SetNWBool(alias, value)
						end
					else
						if self:GetNWInt(alias) ~= value then
							self:SetNWInt(alias, value)
						end
					end
				end
			end
		end
	end
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
	local c = self:GetNWInt "ColorCode"
	local filter = {self, self.Owner}
	local p = self.Owner:WorldSpaceCenter()
	local fw, right = ang:Forward() * InkTraceLength, ang:Right() * InkTraceLength
	self:SetGroundColor(ss.GetSurfaceColor(util.QuickTrace(self.Owner:GetPos(), InkTraceDown, filter)) or -1)
	local onink = self:GetGroundColor() >= 0
	local onourink = self:GetGroundColor() == c
	
	self:SetInWallInk(self:Crouching() and (
	ss.GetSurfaceColor(util.QuickTrace(p, fw - right, filter)) == c or
	ss.GetSurfaceColor(util.QuickTrace(p, fw + right, filter)) == c or
	ss.GetSurfaceColor(util.QuickTrace(p,-fw - right, filter)) == c or
	ss.GetSurfaceColor(util.QuickTrace(p,-fw + right, filter)) == c))
	
	self:SetInInk(self:Crouching() and (onink and onourink or self:GetInWallInk()))
	self:SetOnEnemyInk(onink and not onourink)
	
	self:GetOptions()
	self.Color = ss.GetColor(c)
	self:SetInkColorProxy(Vector(self.Color.r, self.Color.g, self.Color.b) / 255)
end

function SWEP:SharedInitBase()
	self:SetCooldown(CurTime())
	self.SwimSound = CreateSound(self, ss.SwimSound)
	self.EnemyInkSound = CreateSound(self, ss.EnemyInkSound)
	self.LastKeyDown = {}
	for _, k in ipairs(ss.KeyMask) do
		self.LastKeyDown[k] = CurTime()
	end
	
	local translate = {}
	for _, t in ipairs {
		"ar2",
		"crossbow",
		"grenade",
		"melee2",
		"passive",
		"revolver",
		"rpg",
		"shotgun",
		"smg"
	} do
		self:SetWeaponHoldType(t)
		translate[t] = self.ActivityTranslate
	end
	
	if ss.sp then 
		self.Buttons, self.OldButtons = 0, 0
	end
	
	self.Translate = translate
	ss.ProtectedCall(self.SharedInit, self)
end

-- Predicted hooks
function SWEP:SharedDeployBase()
	PlayLoopSound(self)
	self:SetHolstering(false)
	self:SetThrowing(false)
	self:SetCooldown(CurTime())
	self.LastKeyDown = {}
	self:SetKey(0)
	self.InklingSpeed = self:GetInklingSpeed()
	self.SquidSpeed = self:GetSquidSpeed()
	self.OnEnemyInkSpeed = ss.OnEnemyInkSpeed
	self.JumpPower = ss.InklingJumpPower
	self.OnEnemyInkJumpPower = ss.OnEnemyInkJumpPower
	if self.Owner:IsPlayer() then
		self.Owner:SetJumpPower(self.JumpPower)
		self.Owner:SetColor(color_white)
		self.Owner:SetCrouchedWalkSpeed(.5)
		if ss.WeaponRecord[self.Owner] then
			ss.WeaponRecord[self.Owner].Recent[self.ClassName] = -os.time()
		end
	end
	
	ss.ProtectedCall(self.SharedDeploy, self)
	return true
end

function SWEP:SharedHolsterBase()
	self:SetHolstering(true)
	ss.ProtectedCall(self.SharedHolster, self)
	StopLoopSound(self)
	
	if self.Owner:IsPlayer() and ss.WeaponRecord[self.Owner] then
		ss.WeaponRecord[self.Owner].Duration[self.ClassName]
		= (ss.WeaponRecord[self.Owner].Duration[self.ClassName] or 0)
		- (os.time() + (ss.WeaponRecord[self.Owner].Recent[self.ClassName] or -os.time()))
	end
	
	return true
end

function SWEP:SharedThinkBase()
	self:SetSkin(self.Skin or 0)
	for k, v in pairs(self.Bodygroup or {}) do
		self:SetBodygroup(k, v)
	end
	
	local ShouldNoDraw = Either(self:GetNWBool "BecomeSquid", self:Crouching(), self:GetInInk())
	self.Owner:DrawShadow(not ShouldNoDraw)
	self:DrawShadow(not ShouldNoDraw)
	
	ss.ProtectedCall(self.SharedThink, self)
end

-- Begin to use special weapon.
function SWEP:Reload()
	if self:GetHolstering() then return end
	if ss.sp and self.Owner:IsPlayer() and IsValid(self.Owner) then
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
	if self:GetThrowing() then return end
	if auto and ss.sp and CLIENT then return end
	if not auto and CurTime() < self:GetCooldown() then return end
	if not auto and self:GetKey() ~= IN_ATTACK then return end
	local hasink = self:GetInk() > 0
	local able = hasink and not self.CannotStandup
	local timescale = ss.GetTimeScale(self.Owner)
	local reloadtime = self.Primary.ReloadDelay / timescale
	self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
	self.ReloadSchedule:SetLastCalled(CurTime() + reloadtime)
	if SERVER and ss.mp then SuppressHostEvents(self.Owner) end
	ss.ProtectedCall(self.SharedPrimaryAttack, self, able, auto)
	ss.ProtectedCall(Either(SERVER, self.ServerPrimaryAttack, self.ClientPrimaryAttack), self, able, auto)
	if SERVER and ss.mp then SuppressHostEvents() end
end

function SWEP:SecondaryAttack() -- Use sub weapon
	if self:GetHolstering() then return end
	if self:CheckCannotStandup() then return end
	if CurTime() < self:GetCooldown() then return end
	if self:GetKey() ~= IN_ATTACK2 then return end
	self:SetThrowing(true)
	self:SendWeaponAnim(ss.ViewModel.Throwing)
	if not self:IsFirstTimePredicted() then return end
	if self.ThrowSchedule then return end
	if self.HoldType ~= "grenade" then
		self.Owner:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)
	end
end
-- End of predicted hooks

local NetworkVarNotifyNOTCalledOnClient = true
function SWEP:ChangeInInk(name, old, new)
	if not IsValid(self.Owner) or self:GetHolstering() then return end
	local outofink, intoink = old and not new, not old and new
	if not intoink then self:SetOldSpeed(self.Owner:GetVelocity().z) end
	if outofink == intoink then return end
	if intoink and self:IsFirstTimePredicted() then
		if self.Owner:IsPlayer() then self.Owner:SetDSP(14) end
		local velocity = math.abs(self:GetOldSpeed())
		local e, f = EffectData(), (velocity - 100) / 600
		local t = util.QuickTrace(self.Owner:GetPos(), -vector_up * 16384, {self, self.Owner})
		e:SetAngles(t.HitNormal:Angle())
		e:SetAttachment(10)
		e:SetColor(self:GetNWInt "ColorCode")
		e:SetEntity(self)
		e:SetFlags((f > .5 and 7 or 3) + (CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0))
		e:SetOrigin(t.HitPos)
		e:SetRadius(Lerp(f, 25, 50))
		e:SetScale(.5)
		util.Effect("SplatoonSWEPsMuzzleSplash", e)
	elseif outofink and self.Owner:IsPlayer() then
		self.Owner:SetDSP(1)
	end
end

function SWEP:ChangeOnEnemyInk(name, old, new)
	if self:GetHolstering() then return end
	local outofink, intoink = old and not new, not old and new
	if outofink == intoink then return end
	if intoink then
		self.EnemyInkSound:ChangeVolume(1, .5)
		if self:IsFirstTimePredicted() then
			self:AddSchedule(20 * ss.FrameToSec, 1, function(self, schedule)
				self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
			end)
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
	else
		self.EnemyInkSound:ChangeVolume(0, .5)
	end
end

function SWEP:ChangeThrowing(name, old, new)
	if self:GetHolstering() then return end
	local start, stop = not old and new, old and not new
	if start == stop then return end
	self.WorldModel = self.ModelPath .. (start and "w_left.mdl" or "w_right.mdl")
	
	if CLIENT then return end
	net.Start "SplatoonSWEPs: Change throwing"
	net.WriteEntity(self)
	net.WriteBool(start)
	net.Send(ss.PlayersReady)
end

local ReloadMultiply = ss.MaxInkAmount / 10 -- Reloading rate(inkling)
local HealingDelay = 10 / ss.ToHammerHealth -- Healing rate(inkling)
function SWEP:SetupDataTables()
	self:AddNetworkVar("Bool", "InInk") -- If owner is in ink.
	self:AddNetworkVar("Bool", "InFence") -- If owner is in fence.
	self:AddNetworkVar("Bool", "InWallInk") -- If owner is on wall.
	self:AddNetworkVar("Bool", "OldCrouching") -- If owner was crouching a tick ago.
	self:AddNetworkVar("Bool", "OnEnemyInk") -- If owner is on enemy ink.
	self:AddNetworkVar("Bool", "Holstering") -- The weapon is being holstered.
	self:AddNetworkVar("Bool", "Throwing") -- Is about to use sub weapon.
	self:AddNetworkVar("Float", "Cooldown") -- Cannot crouch, fire, or use sub weapon.
	self:AddNetworkVar("Float", "Ink") -- Ink remainig. 0 to ss.MaxInkAmount
	self:AddNetworkVar("Float", "Key") -- A valid key input.
	self:AddNetworkVar("Float", "OldSpeed") -- Old Z-velocity of the player.
	self:AddNetworkVar("Float", "ThrowAnimTime") -- Time to adjust throw anim. speed.
	self:AddNetworkVar("Int", "GroundColor") -- Surface ink color.
	self:AddNetworkVar("Vector", "InkColorProxy") -- For material proxy.
	self.HealSchedule = self:AddNetworkSchedule(HealingDelay, function(self, schedule)
		local canheal = self:GetNWBool "CanHealInk" and self:GetInInk() -- Gradually heals the owner
		local timescale = ss.GetTimeScale(self.Owner)
		local delay = HealingDelay / timescale / (canheal and 8 or 1)
		if schedule:GetDelay() ~= delay then schedule:SetDelay(delay) end
		if not self:GetOnEnemyInk() and (self:GetNWBool "CanHealStand" or canheal) then
			local health = math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth())
			if self.Owner:Health() ~= health then self.Owner:SetHealth(health) end
		end
	end)
	
	self.ReloadSchedule = self:AddNetworkSchedule(0, function(self, schedule)
		local reloadamount = math.max(0, schedule:SinceLastCalled()) -- Recharging ink
		local fastreload = self:GetNWBool "CanReloadInk" and self:GetInInk()
		local timescale = ss.GetTimeScale(self.Owner)
		local mul = ReloadMultiply * (fastreload and 10/3 or 1) * timescale
		if self:GetNWBool "CanReloadStand" or fastreload then
			local ink = math.Clamp(self:GetInk() + reloadamount * mul, 0, ss.MaxInkAmount)
			if self:GetInk() ~= ink then self:SetInk(ink) end
		end
		
		if schedule:GetDelay() == 0 then return end
		schedule:SetDelay(0)
	end)
	
	self:NetworkVarNotify("InInk", self.ChangeInInk)
	self:NetworkVarNotify("OnEnemyInk", self.ChangeOnEnemyInk)
	self:NetworkVarNotify("Throwing", self.ChangeThrowing)
	ss.ProtectedCall(self.CustomDataTables, self)
end
