
function SWEP:ChangePlayermodel(data)
	self.Owner:SetModel(data.Model)
	self.Owner:SetSkin(data.Skin)
	local bodygroups = ""
	local numgroups = self.Owner:GetNumBodyGroups()
	if isnumber(numgroups) then
		for k = 0, self.Owner:GetNumBodyGroups() - 1 do
			local v = data.BodyGroups[k + 1]
			if istable(v) and isnumber(v.num) then v = v.num else v = 0 end
			self.Owner:SetBodygroup(k, v)
			bodygroups = bodygroups .. tostring(v) .. " "
		end
	end
	if bodygroups == "" then bodygroups = "0" end
	
	if data.SetOffsets then
		self.Owner:SetNWInt("splt_isSet", 1)
		self.Owner:SetNWInt("splt_SplatoonOffsets", 2)
		if isfunction(self.Owner.SplatoonOffsets) then
			self.Owner:SplatoonOffsets()
		end
	else
		self.Owner:SetNWInt("splt_isSet", 0)
		self.Owner:SetNWInt("splt_SplatoonOffsets", 1)
		if isfunction(self.Owner.DefaultOffsets) then
			self.Owner:DefaultOffsets()
		end
	end
	self.Owner:SetSubMaterial()
	self.Owner:SetPlayerColor(data.PlayerColor)
	
	self.Owner:ConCommand("cl_playermodel " .. player_manager.TranslateToPlayerModelName(data.Model))
	self.Owner:ConCommand("cl_playerskin " .. tostring(data.Skin))
	self.Owner:ConCommand("cl_playerbodygroups " .. bodygroups)
	self.Owner:ConCommand("cl_playercolor " .. tostring(data.PlayerColor))
	
	if SERVER then
		timer.Simple(0.1, function()
			if IsValid(self) and IsValid(self.Owner) and isfunction(self.Owner.SetupHands) then
				self.Owner:SetupHands()
			end
		end)
	end
end

function SWEP:ChangeHullDuck()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
	if self.PMID ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetHullDuck(SplatoonSWEPs.SquidBoundMins, SplatoonSWEPs.SquidBoundMaxs)
		self.Owner:SetViewOffsetDucked(SplatoonSWEPs.SquidViewOffset)
	end
end

--Squids have a limited movement speed.
local LIMIT_Z_DEG = math.cos(math.rad(165))
local function LimitSpeed(ply, data)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) or not weapon.IsSplatoonWeapon then return end
	
	--Disruptors make Inklings slower
	local maxspeed = ply:GetWalkSpeed() * (weapon.poison and 0.5 or 1)
	local velocity = ply:GetVelocity() --Inkling's current velocity
	local speed2D = velocity.x * velocity.x + velocity.y * velocity.y --Horizontal speed
	local dot = -vector_up:Dot(velocity:GetNormalized()) --Checking if it's falling
	
	--Limits horizontal speed
	if speed2D > maxspeed * maxspeed then
		local newVelocity2D = Vector(velocity.x, velocity.y)
		newVelocity2D = newVelocity2D:GetNormalized() * maxspeed
		velocity.x = newVelocity2D.x
		velocity.y = newVelocity2D.y
	end
	
	--Vertical speed clamp
	if velocity.zs > maxspeed and dot < LIMIT_Z_DEG then
		velocity.z = maxspeed * 0.8
	end
	
	weapon:ChangeHullDuck()
	data:SetVelocity(velocity)
end

local function PreventCrouching(ply, data)
	if not IsFirstTimePredicted() then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) or not weapon.IsSplatoonWeapon then return end
	if data:IsForced() then return end
	
	--MOUSE1+LCtrl makes crouch, LCtrl+MOUSE1 makes primary attack.
	local copy = data:GetButtons() --Since CUserCmd doesn't have KeyPressed(), I try workaround.
	if weapon.PreviousCmd then
		local duck, attack = data:KeyDown(IN_DUCK), data:KeyDown(IN_ATTACK + IN_ATTACK2)
		if duck then
			if bit.band(weapon.PreviousCmd, IN_ATTACK + IN_ATTACK2) == 0 and attack then
				weapon:SetCrouchPriority(false)
			elseif attack and CurTime() < weapon:GetNextCrouchTime() and bit.band(weapon.PreviousCmd, IN_DUCK) == 0 then
				weapon:SetCrouchPriority(true)
			end
		elseif not duck and attack then
			weapon:SetCrouchPriority(false)
		end
	end
	weapon.PreviousCmd = copy
	
	--Prevent crouching after firing.
	if CurTime() < weapon:GetNextCrouchTime() then
		data:RemoveKey(IN_DUCK)
		ply:RemoveFlags(FL_DUCKING)
	end
end
hook.Add("Move", "SplatoonSWEPs: Limit squid's speed", LimitSpeed)
hook.Add("StartCommand", "SplatoonSWEPs: Prevent owner from crouch", PreventCrouching)

--When NPC weapon is picked up by player.
function SWEP:OwnerChanged()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
end

--Predicted Hooks
function SWEP:SharedDeploy()
	self.CanHealStand = SplatoonSWEPs:GetConVarBool "CanHealStand"
	self.CanHealInk = SplatoonSWEPs:GetConVarBool "CanHealInk"
	self.CanReloadStand = SplatoonSWEPs:GetConVarBool "CanReloadStand"
	self.CanReloadInk = SplatoonSWEPs:GetConVarBool "CanReloadInk"
	if isfunction(self.CustomSharedDeploy) then self:CustomSharedDeploy() end
	return true
end

--Begin to use special weapon.
function SWEP:Reload()
	
end

function SWEP:CommonFire(isprimary)
	if self:GetCrouchPriority() then return end
	local Weapon = isprimary and self.Primary or self.Secondary
	self.ReloadSchedule:SetDelay(Weapon.ReloadDelay)
	self:SetNextCrouchTime(CurTime() + Weapon.CrouchCooldown)
	
	local CanFire = isprimary and self.CanPrimaryAttack or self.CanSecondaryAttack
	if not CanFire(self) then return false end --Check fire delay
	if self:GetInk() < Weapon.TakeAmmo then return false end --Check remaining amount of ink
	self:SetNextPrimaryFire(CurTime() + Weapon.Delay)
	self:MuzzleFlash()
	
	if math.random() < Weapon.PercentageRecoilAnimation then
		self.Owner:SetAnimation(PLAYER_ATTACK1)
	end
	
	local rnda = Weapon.Recoil * -1
	local rndb = Weapon.Recoil * math.Rand(-1, 1)
	if self.Owner:IsPlayer() then
		self.Owner:ViewPunch(Angle(rnda,rndb,rnda)) --Apply viewmodel punch
	end
	return true
end

--Shoot ink.
function SWEP:PrimaryAttack()
	local canattack = self:CommonFire(true)
	if isfunction(self.SharedPrimaryAttack) then self:SharedPrimaryAttack(canattack) end
	if SERVER and isfunction(self.ServerPrimaryAttack) then
		self:ServerPrimaryAttack(canattack)
	elseif CLIENT and isfunction(self.ClientPrimaryAttack) then
		self:ClientPrimaryAttack(canattack)
	end
end

--Use sub weapon
function SWEP:SecondaryAttack()
	local canattack = self:CommonFire(false)
	if isfunction(self.SharedSecondaryAttack) then self:SharedSecondaryAttack(canattack) end
	if SERVER and isfunction(self.ServerSecondaryAttack) then
		self:ServerSecondaryAttack(canattack)
	elseif CLIENT and isfunction(self.ClientSecondaryAttack) then
		self:ClientSecondaryAttack(canattack)
	end
end
--End of Predicted Hooks

local ReloadMultiply = 1 / 0.12 --Reloading rate(inkling)
local HealingDelay = 0.1 --Healing rate(inkling)
function SWEP:GetLastSlot(typeof) return self.NetworkSlot[typeof] end
function SWEP:AddNetworkVar(typeof, name)
	self.NetworkSlot[typeof] = self.NetworkSlot[typeof] + 1
	assert(self.NetworkSlot[typeof] < 32, "SplatoonSWEPs: Tried to use too many network vars!")
	self:NetworkVar(typeof, self.NetworkSlot[typeof], name)
	return self.NetworkSlot[typeof]
end

function SWEP:SetupDataTables()
	self.FunctionQueue = {}
	self.NetworkSlot = {
		String = -1, Bool = -1, Float = -1, Int = -1,
		Vector = -1, Angle = -1, Entity = -1,
	}
	self:AddNetworkVar("Bool", "InInk") --Whether or not owner is in ink.
	self:AddNetworkVar("Bool", "OnEnemyInk") --Whether or not owner is on enemy ink.
	self:AddNetworkVar("Bool", "CrouchPriority") --True if crouch input takes a priority.
	self:AddNetworkVar("Float", "Ink") --Ink remainig. 0 ~ SplatoonSWEPs.MaxInkAmount
	self:AddNetworkVar("Vector", "InkColorProxy") --For material proxy.
	self:AddNetworkVar("Float", "NextCrouchTime") --Shooting cooldown.
	self:AddNetworkSchedule(HealingDelay, function(self, schedule) --Gradually heals the owner
		local canheal = self.CanHealInk and self:GetInInk()
		schedule:SetDelay(HealingDelay / (canheal and 8 or 1))
		if self.CanHealStand or canheal then
			self.Owner:SetHealth(math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth()))
		end
	end)
	
	self.ReloadSchedule = self:AddNetworkSchedule(0,
	function(self, schedule) --Recharging ink
		local reloadamount = schedule:SinceLastCalled()
		local canreload = self.CanReloadInk and self:GetInInk()
		local mul = ReloadMultiply * (canreload and 4 or 1)
		if self.CanReloadStand or canreload then
			self:SetInk(math.Clamp(self:GetInk() + reloadamount * mul, 0, SplatoonSWEPs.MaxInkAmount))
		end
		
		schedule:SetDelay(0)
	end)
	
	self:NetworkVarNotify("InInk", function(self, name, old, new)
		local outofink = old and not new
		local intoink = not old and new
		if outofink == intoink then return
		elseif intoink then
			self.Owner:SetCrouchedWalkSpeed(1)
			self:SetPlayerSpeed(SplatoonSWEPs.SquidBaseSpeed)
		elseif self.Owner:OnGround() or self.Owner:GetVelocity():GetNormalized():Dot(vector_up) > 0.9 then
			self.Owner:SetCrouchedWalkSpeed(0.5)
			self:SetPlayerSpeed(SplatoonSWEPs.InklingBaseSpeed)
		else
			self:AddSchedule(self:FrameToSec(30), function(self, schedule)
				if self:GetInInk() or self.Owner:OnGround() then return true end
				self.Owner:SetCrouchedWalkSpeed(0.5)
				self:SetPlayerSpeed(SplatoonSWEPs.InklingBaseSpeed)
				return true
			end)
		end
	end)
	
	self:NetworkVarNotify("OnEnemyInk", function(self, name, old, new)
		local outofink = old and not new
		local intoink = not old and new
		if outofink == intoink then return
		elseif intoink then
			self:SetPlayerSpeed(self.MaxSpeed / 2) --Hard to move
			self.Owner:SetJumpPower(SplatoonSWEPs.OnEnemyInkJumpPower) --Reduce jump power
			self:AddSchedule(self:FrameToSec(50), function(self, schedule)
				if not self:GetOnEnemyInk() then return true end --Can't crouch on enemy ink
				self:SetNextCrouchTime(CurTime() + self:FrameToSec(20))
			end)
			
			if CLIENT then return end
			self:AddSchedule(self:FrameToSec(2), function(self, schedule)
				if not self:GetOnEnemyInk() then return true end --Enemy ink damage
				if self.Owner:Health() > self.Owner:GetMaxHealth() / 2 then
					self.Owner:SetHealth(self.Owner:Health() - 1)
				end
			end)
		else --Timers will be automatically removed
			self:SetPlayerSpeed(self:GetInInk() and SplatoonSWEPs.SquidBaseSpeed or SplatoonSWEPs.InklingBaseSpeed)
			self.Owner:SetJumpPower(SplatoonSWEPs.InklingJumpPower) --Restore
		end
	end)
	
	if isfunction(self.CustomDataTables) then self:CustomDataTables() end
end
