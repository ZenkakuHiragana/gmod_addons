
include "sh_anim.lua"

local ss = SplatoonSWEPs
if not ss then return end

ss.AddTimerFramework(SWEP)
function SWEP:PlayLoopSound()
	local playlist = {self.SwimSound, self.EnemyInkSound}
	ss.ProtectedCall(self.AddPlaylist, self, playlist)
	for _, s in ipairs(playlist) do s:PlayEx(0, 100) end
end

function SWEP:StopLoopSound()
	local playlist = {self.SwimSound, self.EnemyInkSound}
	ss.ProtectedCall(self.AddPlaylist, self, playlist)
	for _, s in ipairs(playlist) do s:Stop() end
end

function SWEP:StartRecording()
	local o = self.Owner
	if not (o:IsPlayer() and ss.WeaponRecord[o]) then return end
	self:SetNWEntity("Owner", o)
	ss.WeaponRecord[o].Recent[self.ClassName] = -os.time()
end

function SWEP:EndRecording()
	local o = IsValid(self.Owner) and self.Owner or self:GetNWEntity "Owner"
	local r = ss.WeaponRecord[o]
	local c = self.ClassName
	local t = os.time()
	if not (o:IsPlayer() and r) then return end
	r.Duration[c] = (r.Duration[o] or 0) - (t + (r.Recent[c] or -t))
end

function SWEP:IsMine()
	return SERVER or self:IsCarriedByLocalPlayer()
end

function SWEP:IsFirstTimePredicted()
	return SERVER or ss.sp or IsFirstTimePredicted() or not self:IsCarriedByLocalPlayer()
end

function SWEP:GetBase(BaseClassName)
	BaseClassName = BaseClassName or "weapon_splatoonsweps_inklingbase"
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

function SWEP:GetInkColor()
	return ss.GetColor(self:GetNWInt "inkcolor") or ss.GetColor(ss.GetNPCInkColor(self.Owner))
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

function SWEP:GetOptions(opt, getopt)
	if not self:IsMine() then return end
	local gc = greatzenkakuman.cvartree
	for name, pt in gc.IteratePreferences "splatoonsweps" do
		if pt.options and pt.options.serverside then continue end
		if #pt.location > 1 then
			if pt.location[2] ~= self.Base then continue end
			if #pt.location > 2 and pt.location[3] ~= self.ClassName then continue end
		end

		local value = gc.GetValue(pt, self.Owner)
		if isbool(value) and self:GetNWBool(name) ~= value then self:SetNWBool(name, value) end
		if isnumber(value) and self:GetNWInt(name) ~= value then self:SetNWInt(name, value) end
	end

	if self.Owner:IsPlayer() then return end
	self:SetNWInt("inkcolor", ss.GetNPCInkColor(self.Owner))
end

function SWEP:ApplySkinAndBodygroups()
	self:SetSkin(self.Skin or 0)
	for k, v in pairs(self.Bodygroup or {}) do
		self:SetBodygroup(k, v)
	end
end

-- When NPC weapon is picked up by player.
function SWEP:OwnerChanged()
	local o = self.Owner
	local isvalid = IsValid(o)
	local isplayer = isvalid and o:IsPlayer()
	self.IgnorePrediction = SERVER and ss.mp and not isplayer or nil
	if not isvalid then
		if SERVER then
			self:CreateRagdoll()
			timer.Simple(5, function()
				if not IsValid(self) or IsValid(self.Owner) then return end
				self:Remove()
			end)
		end

		return self:StopLoopSound()
	elseif IsValid(self.Ragdoll) and isplayer then
		self.Owner:Give(self.ClassName)
		self:Remove()
	else
		self.SafeOwner = o
		return self:PlayLoopSound()
	end
end

local InkTraceLength = 24
local InkTraceDown = -vector_up * InkTraceLength
function SWEP:UpdateInkState() -- Set if player is in ink
	local ang = Angle(0, self.Owner:GetAngles().yaw)
	local c = self:GetNWInt "inkcolor"
	local filter = {self, self.Owner}
	local org = self.Owner:GetPos()
	local center = self.Owner:WorldSpaceCenter()
	local mean = (center + org) / 2
	local fw, right = ang:Forward() * InkTraceLength, ang:Right() * InkTraceLength
	local ink_t = {start = org, endpos = org + InkTraceDown, filter = filter, mask = MASK_SHOT}
	local groundcolor = ss.GetSurfaceColor(util.TraceLine(ink_t)) or -1
	local onink = groundcolor >= 0
	local onourink = groundcolor == c
	
	ink_t.start = center
	ink_t.endpos = mean + fw - right
	local inink = ss.GetSurfaceColor(util.TraceLine(ink_t)) == c
	ink_t.endpos = mean + fw + right
	inink = inink or ss.GetSurfaceColor(util.TraceLine(ink_t)) == c
	ink_t.endpos = center - fw - right
	inink = inink or ss.GetSurfaceColor(util.TraceLine(ink_t)) == c
	ink_t.endpos = center - fw + right
	inink = inink or ss.GetSurfaceColor(util.TraceLine(ink_t)) == c

	self:SetGroundColor(groundcolor)
	self:SetInWallInk(self:Crouching() and inink)
	self:SetInInk(self:Crouching() and (onink and onourink or self:GetInWallInk()))
	self:SetOnEnemyInk(onink and not onourink)

	self:GetOptions()
	self:SetInkColorProxy(self:GetInkColor():ToVector())
end

function SWEP:GetViewModel(index)
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
	return self.Owner:GetViewModel(index)
end

function SWEP:SetWeaponAnim(act, index)
	if not index then self:SendWeaponAnim(act) end
	if index == 0 then self:SendWeaponAnim(act) return end
	if not self:IsFirstTimePredicted() then return end
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
	for i = 1, 2 do
		if index and i ~= index then continue end
		local vm = self.Owner:GetViewModel(i)
		if not IsValid(vm) then continue end
		-- Entity:GetSequenceCount() returns nil on an invalid viewmodel
		if (vm:GetSequenceCount() or 0) < 1 then continue end
		local seq = vm:SelectWeightedSequence(act)
		if seq == -1 then continue end
		vm:SendViewModelMatchingSequence(seq)
		vm:SetPlaybackRate(rate or 1)
	end
end

function SWEP:SharedInitBase()
	self:SetCooldown(CurTime())
	self:ApplySkinAndBodygroups()
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
		"melee",
		"melee2",
		"passive",
		"revolver",
		"rpg",
		"shotgun",
		"smg",
	} do
		self:SetWeaponHoldType(t)
		translate[t] = self.ActivityTranslate
	end

	if ss.sp then
		self.Buttons, self.OldButtons = 0, 0
	end

	self.Translate = translate
	self.Projectile = ss.MakeProjectileStructure()
	self.Projectile.Weapon = self
	ss.ProtectedCall(self.SharedInit, self)
end

-- Predicted hooks
function SWEP:SharedDeployBase()
	self:PlayLoopSound()
	self:SetHolstering(false)
	self:SetThrowing(false)
	self:SetCooldown(CurTime())
	self:StartRecording()
	self:SetKey(0)
	self.LastKeyDown = {}
	self.InklingSpeed = self:GetInklingSpeed()
	self.SquidSpeed = self:GetSquidSpeed()
	self.OnEnemyInkSpeed = ss.OnEnemyInkSpeed
	self.JumpPower = ss.InklingJumpPower
	self.OnEnemyInkJumpPower = ss.OnEnemyInkJumpPower
	self.Owner:SetHealth(self.Owner:Health() * self:GetNWInt "MaxHealth" / self:GetNWInt "BackupMaxHealth")
	if self.Owner:IsPlayer() then
		self.Owner:SetJumpPower(self.JumpPower)
		self.Owner:SetCrouchedWalkSpeed(.5)
	end
	
	local vm = self:GetViewModel()
	if IsValid(vm) then
		local id, duration = vm:LookupSequence "draw"
		if duration > 0 then
			self:AddSchedule(duration, 1, function(self, schedule)
				if not IsValid(vm) then return end
				if vm:GetSequence() ~= id then return end
				self:SetWeaponAnim(ACT_VM_IDLE)
			end)
		end
	end

	ss.ProtectedCall(self.SharedDeploy, self)
	return true
end

function SWEP:SharedHolsterBase()
	self:SetHolstering(true)
	ss.ProtectedCall(self.SharedHolster, self)
	self:StopLoopSound()
	self:EndRecording()
	return true
end

function SWEP:SharedThinkBase()
	local ShouldNoDraw = Either(self:GetNWBool "becomesquid", self:Crouching(), self:GetInInk())
	self.Owner:DrawShadow(not ShouldNoDraw)
	self:DrawShadow(not ShouldNoDraw)
	self:ApplySkinAndBodygroups()
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

function SWEP:SetReloadDelay(delay)
	local reloadtime = delay / ss.GetTimeScale(self.Owner)
	if self.ReloadSchedule:SinceLastCalled() < -reloadtime then return end
	self.ReloadSchedule:SetDelay(reloadtime) -- Stop reloading ink
	self.ReloadSchedule:SetLastCalled(-reloadtime)
end

function SWEP:PrimaryAttack(auto) -- Shoot ink.  bool auto | is a scheduled shot
	if self:GetHolstering() then return end
	if self:CheckCannotStandup() then return end
	if self:GetThrowing() then return end
	if auto and ss.sp and CLIENT then return end
	if not auto and CurTime() < self:GetCooldown() then return end
	if not auto and self.Owner:IsPlayer() and self:GetKey() ~= IN_ATTACK then return end
	local hasink = self:GetInk() > 0
	local able = hasink and not self.CannotStandup
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
	self:SetWeaponAnim(ss.ViewModel.Throwing)
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
	if old == new then return end
	if intoink and self:IsFirstTimePredicted() then
		if self.Owner:IsPlayer() then self.Owner:SetDSP(14) end
		local velocity = math.abs(self:GetOldSpeed())
		local e, f = EffectData(), (velocity - 100) / 600
		local t = util.QuickTrace(self.Owner:GetPos(), -vector_up * 16384, {self, self.Owner})
		e:SetAngles(t.HitNormal:Angle())
		e:SetAttachment(10)
		e:SetColor(self:GetNWInt "inkcolor")
		e:SetEntity(self)
		e:SetFlags((f > .5 and 7 or 3) + (CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0))
		e:SetOrigin(t.HitPos)
		e:SetRadius(Lerp(f, 25, 50))
		e:SetScale(.5)
		util.Effect("SplatoonSWEPsMuzzleSplash", e, true,
		not self.Owner:IsPlayer() and SERVER and ss.mp or nil)
	elseif outofink and self.Owner:IsPlayer() then
		self.Owner:SetDSP(1)
	end
end

function SWEP:ChangeOnEnemyInk(name, old, new)
	if self:GetHolstering() then return end
	if old == new then return end
	local outofink, intoink = old and not new, not old and new
	if intoink then
		self.EnemyInkSound:ChangeVolume(1, .5)
		if self:IsFirstTimePredicted() then
			self:AddSchedule(20 * ss.FrameToSec, 1, function(self, schedule)
				self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
			end)
		end

		if CLIENT then return end
		self:AddSchedule(200 / ss.GetMaxHealth() * ss.FrameToSec, function(self, schedule)
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

function SWEP:SetupDataTables()
	local gain = ss.GetOption "gain"
	self:AddNetworkVar("Bool", "InInk") -- If owner is in ink.
	self:AddNetworkVar("Bool", "InFence") -- If owner is in fence.
	self:AddNetworkVar("Bool", "InWallInk") -- If owner is on wall.
	self:AddNetworkVar("Bool", "OldCrouching") -- If owner was crouching a tick ago.
	self:AddNetworkVar("Bool", "OnEnemyInk") -- If owner is on enemy ink.
	self:AddNetworkVar("Bool", "Holstering") -- The weapon is being holstered.
	self:AddNetworkVar("Bool", "Throwing") -- Is about to use sub weapon.
	self:AddNetworkVar("Entity", "NPCTarget") -- Target entity for NPC.
	self:AddNetworkVar("Float", "Cooldown") -- Cannot crouch, fire, or use sub weapon.
	self:AddNetworkVar("Float", "Ink") -- Ink remainig. 0 to ss.GetMaxInkAmount()
	self:AddNetworkVar("Float", "OldSpeed") -- Old Z-velocity of the player.
	self:AddNetworkVar("Float", "ThrowAnimTime") -- Time to adjust throw anim. speed.
	self:AddNetworkVar("Int", "GroundColor") -- Surface ink color.
	self:AddNetworkVar("Int", "Key") -- A valid key input.
	self:AddNetworkVar("Vector", "InkColorProxy") -- For material proxy.
	self:AddNetworkVar("Vector", "AimVector") -- NPC:GetAimVector() doesn't exist in clientside.
	self:AddNetworkVar("Vector", "ShootPos") -- NPC:GetShootPos() doesn't, either.
	local getaimvector = self.GetAimVector
	local getshootpos = self.GetShootPos
	function self:GetAimVector()
		if not IsValid(self.Owner) then return self:GetForward() end
		if self.Owner:IsPlayer() then return self.Owner:GetAimVector() end
		return getaimvector(self)
	end

	function self:GetShootPos()
		if not IsValid(self.Owner) then return self:GetPos() end
		if self.Owner:IsPlayer() then return self.Owner:GetShootPos() end
		return getshootpos(self)
	end

	self.HealSchedule = self:AddNetworkSchedule(0, function(self, schedule)
		local healink = self:GetNWBool "canhealink" and self:GetInInk() -- Gradually heals the owner
		local timescale = ss.GetTimeScale(self.Owner)
		local delay = 10 / timescale
		if healink then
			delay = delay / 8 / gain "healspeedink"
		else
			delay = delay / gain "healspeedstand"
		end
		
		if schedule:GetDelay() ~= delay then schedule:SetDelay(delay) end
		if not self:GetOnEnemyInk() and (self:GetNWBool "canhealstand" or healink) then
			local health = math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth())
			if self.Owner:Health() ~= health then self.Owner:SetHealth(health) end
		end
	end)

	self.ReloadSchedule = self:AddNetworkSchedule(0, function(self, schedule)
		local reloadamount = math.max(0, schedule:SinceLastCalled()) -- Recharging ink
		local reloadink = self:GetNWBool "canreloadink" and self:GetInInk()
		local timescale = ss.GetTimeScale(self.Owner)
		local mul = ss.GetMaxInkAmount() * timescale
		if reloadink then
			mul = mul / 3 * gain "reloadspeedink" / 100
		else
			mul = mul / 10 * gain "reloadspeedstand" / 100
		end

		if self:GetNWBool "canreloadstand" or reloadink then
			local ink = math.Clamp(self:GetInk() + reloadamount * mul, 0, ss.GetMaxInkAmount())
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
